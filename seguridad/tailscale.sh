#!/usr/bin/env bash
# bash_scripts · seguridad/tailscale.sh
# Gestor local de Tailscale para Debian, Ubuntu y derivados.
# Paleta provisional: sustituir por las variables de .lib al integrarlo.

set -o pipefail

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
    C_RESET=$'\033[0m'; C_TITLE=$'\033[1;97m'; C_ACCENT=$'\033[36m'
    C_MUTED=$'\033[90m'; C_NUM=$'\033[33m'; C_OK=$'\033[32m'
    C_BAD=$'\033[31m'; C_WARN=$'\033[33m'
else
    C_RESET=''; C_TITLE=''; C_ACCENT=''; C_MUTED=''; C_NUM=''
    C_OK=''; C_BAD=''; C_WARN=''
fi

print_line() { printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$C_ACCENT" "$C_RESET"; }
msg() { printf '  %s%s%s\n' "$2" "$1" "$C_RESET"; }
pause() { printf '\n  %sPresioná Enter para continuar...%s' "$C_MUTED" "$C_RESET"; IFS= read -r _ || true; }
confirm() {
    local answer
    printf '  %s%s [s/N]: %s' "$C_WARN" "$1" "$C_RESET"
    IFS= read -r answer || return 1
    [[ $answer == [sS] || $answer == [sS][iI] ]]
}
run_root() {
    if (( EUID == 0 )); then "$@"; else
        if ! command -v sudo >/dev/null 2>&1; then msg 'Se necesita sudo.' "$C_BAD"; return 1; fi
        sudo "$@"
    fi
}
installed() { command -v tailscale >/dev/null 2>&1; }
service_ok() { command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet tailscaled; }
backend_state() {
    local s
    if ! installed; then printf 'No instalado'; return; fi
    if ! service_ok; then printf 'Servicio detenido'; return; fi
    s=$(tailscale status --json 2>/dev/null) || { printf 'Sin respuesta'; return; }
    # Sin jq: consultar el estado BackendState usando un extractor delimitado.
    # El valor se limita a texto ASCII controlado por el propio daemon.
    if [[ $s =~ \"BackendState\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        case ${BASH_REMATCH[1]} in
            Running) printf 'Conectado' ;;
            Stopped) printf 'Desconectado' ;;
            NeedsLogin) printf 'Requiere login' ;;
            Starting) printf 'Conectando' ;;
            *) printf '%s' "${BASH_REMATCH[1]}" ;;
        esac
    else
        printf 'Desconocido'
    fi
}
header() {
    local status ip
    clear 2>/dev/null || printf '\033[2J\033[H'
    print_line
    printf '  %s◈  GESTOR TAILSCALE%s  %sSeguridad / VPN%s\n' "$C_TITLE" "$C_RESET" "$C_MUTED" "$C_RESET"
    print_line
    status=$(backend_state)
    if [[ $status == Conectado ]]; then
        msg "● VPN: $status" "$C_OK"
    elif [[ $status == Desconectado || $status == 'No instalado' ]]; then
        msg "○ VPN: $status" "$C_WARN"
    else
        msg "○ VPN: $status" "$C_MUTED"
    fi
    if installed && service_ok; then
        ip=$(tailscale ip -4 2>/dev/null | head -n 1)
        [[ -n $ip ]] && msg "IP Tailscale: $ip" "$C_MUTED"
    fi
    print_line
}
item() { printf '  %s%s%s  %s\n' "$C_NUM" "$1" "$C_RESET" "$2"; }
need_installed() { installed && return 0; msg 'Tailscale no está instalado.' "$C_BAD"; return 1; }
ensure_service() {
    service_ok && return 0
    msg 'El servicio tailscaled está detenido.' "$C_WARN"
    if confirm '¿Iniciar el servicio para poder conectar?'; then
        run_root systemctl start tailscaled
    else
        return 1
    fi
}
connect_vpn() {
    need_installed || return
    ensure_service || return
    msg 'Conectando a la tailnet (podría solicitar autenticación)...' "$C_MUTED"
    run_root tailscale up || msg 'No se pudo conectar. Consultá el diagnóstico o los logs.' "$C_BAD"
}
disconnect_vpn() {
    need_installed || return
    if confirm '¿Desconectar este equipo de Tailscale?'; then
        run_root tailscale down || msg 'Error al desconectar.' "$C_BAD"
    fi
}
show_status() {
    need_installed || return
    printf '\n%sEstado de Tailscale%s\n' "$C_ACCENT" "$C_RESET"
    tailscale status || msg 'No se pudo obtener el estado.' "$C_BAD"
    printf '\n%sVersión:%s\n' "$C_MUTED" "$C_RESET"
    tailscale version 2>/dev/null | head -n 2
}
show_devices() {
    need_installed || return
    printf '\n%sEquipos · nombre / IP / sistema / conectividad%s\n' "$C_ACCENT" "$C_RESET"
    # Tailscale muestra conectividad conocida (direct, relay o estado de transferencia).
    # Sin tráfico reciente puede no estar disponible el tipo de enlace.
    tailscale status || msg 'No se pudo obtener la lista de equipos.' "$C_BAD"
    printf '\n%sNota: direct/relay puede requerir tráfico previo. Usá Ping para verificar.%s\n' "$C_MUTED" "$C_RESET"
}
show_logs() {
    if ! command -v journalctl >/dev/null 2>&1; then
        msg 'journalctl no está disponible en este sistema.' "$C_BAD"; return
    fi
    local selection
    while :; do
        header
        msg 'LOGS · Servicio tailscaled' "$C_TITLE"
        item 1 'Últimos 30 registros'
        item 2 'Últimos 100 registros'
        item 3 'Seguimiento en vivo (Ctrl+C para salir)'
        item 0 'Volver'
        printf '\n  %sOpción: %s' "$C_NUM" "$C_RESET"
        IFS= read -r selection || return
        case $selection in
            1|2)
                header
                journalctl --no-pager -u tailscaled -n "$([[ $selection == 1 ]] && printf 30 || printf 100)" ||
                    msg 'No se pudo leer el journal (verificá permisos).' "$C_BAD"
                pause ;;
            3)
                header
                msg 'Seguimiento activo. Presioná Ctrl+C para volver.' "$C_MUTED"
                # En subproceso, Ctrl+C no cierra el gestor principal.
                (trap - INT; journalctl --no-pager -fu tailscaled) || true
                ;;
            0) return ;;
            *) msg 'Opción inválida.' "$C_WARN"; pause ;;
        esac
    done
}
ping_device() {
    need_installed || return
    local target
    msg 'Equipos conocidos:' "$C_ACCENT"
    tailscale status || true
    printf '\n  %sEquipo (nombre MagicDNS o IP Tailscale, vacío para cancelar): %s' "$C_NUM" "$C_RESET"
    IFS= read -r target || return
    [[ -z $target ]] && return
    # Evitar que la entrada se interprete como opción o como varios argumentos.
    if [[ ! $target =~ ^[a-zA-Z0-9._:-]+$ || $target == -* ]]; then
        msg 'Nombre o IP inválidos.' "$C_BAD"; return
    fi
    tailscale ping --c 4 "$target" || msg 'No se pudo completar el ping.' "$C_BAD"
}
netcheck() {
    need_installed || return
    msg 'Diagnóstico de conexión/NAT:' "$C_ACCENT"
    tailscale netcheck || msg 'Falló el diagnóstico.' "$C_BAD"
}
install_ts() {
    local distro codename base prefix tmp key list
    command -v apt-get >/dev/null 2>&1 || { msg 'Solo se admite instalación mediante APT.' "$C_BAD"; return 1; }
    [[ -r /etc/os-release ]] || { msg 'No se puede identificar la distribución.' "$C_BAD"; return 1; }
    # shellcheck disable=SC1091
    . /etc/os-release
    distro=${ID:-}; codename=${VERSION_CODENAME:-}
    case $distro in
        debian|ubuntu) ;;
        linuxmint) distro=ubuntu; codename=${UBUNTU_CODENAME:-} ;;
        *)
            msg "Distribución no soportada automáticamente: $distro" "$C_BAD"
            msg 'Revisá https://pkgs.tailscale.com/stable/ para el repositorio correcto.' "$C_MUTED"
            return 1 ;;
    esac
    if [[ -z $codename ]]; then msg 'No se detectó el codename de la distribución.' "$C_BAD"; return 1; fi
    if ! command -v curl >/dev/null 2>&1; then msg 'Se requiere curl para descargar la clave y el repositorio.' "$C_BAD"; return 1; fi
    if ! confirm "¿Configurar repositorio oficial APT para $distro/$codename e instalar Tailscale?"; then return; fi
    base="https://pkgs.tailscale.com/stable/$distro/$codename"
    tmp=$(mktemp -d) || return 1
    key="$tmp/tailscale.gpg"; list="$tmp/tailscale.list"
    if ! curl -fsSL --connect-timeout 10 --max-time 60 "$base.noarmor.gpg" -o "$key" ||
       ! curl -fsSL --connect-timeout 10 --max-time 60 "$base.tailscale-keyring.list" -o "$list"; then
        msg 'No se pudo descargar el repositorio oficial (o la versión no está soportada).' "$C_BAD"
        rm -rf -- "$tmp"; return 1
    fi
    # Se respeta la lista suministrada por Tailscale; mostrar antes de agregarla.
    printf '\n%sRepositorio que se agregará:%s\n' "$C_ACCENT" "$C_RESET"
    cat -- "$list"
    if ! confirm '¿Aplicar esta configuración APT?'; then rm -rf -- "$tmp"; return; fi
    run_root install -d -m 0755 /usr/share/keyrings /etc/apt/sources.list.d || { rm -rf -- "$tmp"; return 1; }
    run_root install -m 0644 "$key" /usr/share/keyrings/tailscale-archive-keyring.gpg &&
    run_root install -m 0644 "$list" /etc/apt/sources.list.d/tailscale.list &&
    run_root apt-get update &&
    run_root apt-get install tailscale tailscale-archive-keyring &&
    run_root systemctl enable --now tailscaled
    local rc=$?
    rm -rf -- "$tmp"
    if (( rc == 0 )); then msg 'Tailscale instalado. Elegí 1 para conectar.' "$C_OK"
    else msg 'Instalación incompleta. Revisá la salida de APT.' "$C_BAD"; fi
    return "$rc"
}

main() {
    local choice
    if ! [[ -t 0 ]]; then printf 'Este gestor necesita una terminal interactiva.\n' >&2; return 1; fi
    if ! installed; then
        header
        msg 'Tailscale no está instalado.' "$C_WARN"
        if confirm '¿Querés instalarlo mediante APT?'; then install_ts; pause; fi
    fi
    while :; do
        header
        item 1 'Conectar VPN'
        item 2 'Desconectar VPN'
        item 3 'Estado local de Tailscale'
        item 4 'Equipos de la tailnet (detalle)'
        item 5 'Logs del servicio'
        item 6 'Ping a un equipo'
        item 7 'Diagnóstico de red (netcheck)'
        if ! installed; then item 8 'Instalar Tailscale mediante APT'; fi
        printf '%s\n' "${C_ACCENT}──────────────────────────────────────────────────${C_RESET}"
        item 0 'Volver'
        printf '\n  %sOpción [0-8]: %s' "$C_NUM" "$C_RESET"
        IFS= read -r choice || break
        case $choice in
            1) header; connect_vpn; pause ;;
            2) header; disconnect_vpn; pause ;;
            3) header; show_status; pause ;;
            4) header; show_devices; pause ;;
            5) show_logs ;;
            6) header; ping_device; pause ;;
            7) header; netcheck; pause ;;
            8) if ! installed; then header; install_ts; pause; else msg 'Opción inválida.' "$C_WARN"; pause; fi ;;
            0) break ;;
            *) msg 'Opción inválida.' "$C_WARN"; pause ;;
        esac
    done
}
main "$@"
