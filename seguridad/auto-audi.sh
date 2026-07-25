#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

########################################
# CONFIGURACIÓN
########################################

APP_NAME="auto-audi"
VERSION="0.2.0"
UMBRAL_DISCO=90
UMBRAL_PASSWORD_DIAS=365
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$REPO_DIR/.cache/tmp"
SALIDA=""
NOMBRE_INFORME=""
HOME_INFORME="${HOME:-}"
USAR_COLOR=1

########################################
# VARIABLES GLOBALES
########################################

TOTAL_OK=0
TOTAL_INFO=0
TOTAL_ADVERTENCIA=0
TOTAL_ALTO=0
TOTAL_NO_VERIFICADO=0
PERFIL="servidor"
ES_ROOT=0
ARCHIVO_RESULTADOS=""

RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
CYAN=$'\e[36m'
GRAY=$'\e[90m'
NC=$'\e[0m'

########################################
# FUNCIONES DE INTERFAZ
########################################

ui_uso() {
    cat <<EOF
Uso: $APP_NAME [opciones]

Auditoría local de seguridad, pasiva y de solo lectura.

Opciones:
      --sin-color  Desactivar colores en la consola
  -h, --ayuda     Mostrar esta ayuda
  -v, --version   Mostrar la versión

Ejemplos:
  $APP_NAME
  sudo $APP_NAME

Para ampliar la cobertura de archivos protegidos, ejecute con sudo.
Al finalizar podrá decidir si desea guardar el informe.
EOF
}

ui_titulo() {
    printf '\n%s== %s ==%s\n' "$CYAN" "$1" "$NC"
}

ui_resultado() {
    local nivel="$1"
    local titulo="$2"
    local color="$GRAY"

    case "$nivel" in
        CORRECTO) color="$GREEN" ;;
        ALTO) color="$RED" ;;
        ADVERTENCIA) color="$YELLOW" ;;
        INFORMATIVO) color="$CYAN" ;;
    esac

    printf '%s[%s]%s %s\n' "$color" "$nivel" "$NC" "$titulo"
}

ui_error() {
    printf '%sError:%s %s\n' "$RED" "$NC" "$1" >&2
}

########################################
# FUNCIONES AUXILIARES
########################################

limpiar_temporal() {
    if [[ -n "$ARCHIVO_RESULTADOS" && -f "$ARCHIVO_RESULTADOS" ]]; then
        rm -f -- "$ARCHIVO_RESULTADOS"
    fi
}

texto_una_linea() {
    local texto="$1"
    texto="${texto//$'\t'/ }"
    texto="${texto//$'\r'/ }"
    texto="${texto//$'\n'/; }"
    printf '%s' "$texto"
}

registrar_resultado() {
    local nivel="$1"
    local categoria="$2"
    local titulo
    local evidencia
    local recomendacion

    titulo="$(texto_una_linea "$3")"
    evidencia="$(texto_una_linea "$4")"
    recomendacion="$(texto_una_linea "$5")"

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$nivel" "$categoria" "$titulo" "$evidencia" "$recomendacion" \
        >> "$ARCHIVO_RESULTADOS"
    ui_resultado "$nivel" "$titulo"

    case "$nivel" in
        CORRECTO) TOTAL_OK=$((TOTAL_OK + 1)) ;;
        INFORMATIVO) TOTAL_INFO=$((TOTAL_INFO + 1)) ;;
        ADVERTENCIA) TOTAL_ADVERTENCIA=$((TOTAL_ADVERTENCIA + 1)) ;;
        ALTO) TOTAL_ALTO=$((TOTAL_ALTO + 1)) ;;
        NO_VERIFICADO) TOTAL_NO_VERIFICADO=$((TOTAL_NO_VERIFICADO + 1)) ;;
    esac
}

comando_disponible() {
    command -v "$1" >/dev/null 2>&1
}

archivo_legible() {
    [[ -f "$1" && -r "$1" ]]
}

servicio_habilitado() {
    local servicio="$1"
    comando_disponible systemctl || return 1
    timeout 3 systemctl is-enabled "$servicio" 2>/dev/null \
        | grep -Eq '^(enabled|enabled-runtime|static|indirect|generated)$'
}

servicio_activo() {
    comando_disponible systemctl || return 1
    timeout 3 systemctl is-active --quiet "$1" 2>/dev/null
}

obtener_valor_sshd() {
    local clave="$1"
    local valor=""

    if comando_disponible sshd; then
        valor="$(sshd -T 2>/dev/null | awk -v clave="$clave" '$1 == clave {print $2; exit}')" || true
    fi
    if [[ -z "$valor" && -r /etc/ssh/sshd_config ]]; then
        valor="$(awk -v clave="$clave" '
            BEGIN { IGNORECASE=1 }
            /^[[:space:]]*#/ { next }
            tolower($1) == clave { valor=tolower($2) }
            END { print valor }
        ' /etc/ssh/sshd_config)"
    fi
    printf '%s' "$valor"
}

########################################
# PREPARACIÓN
########################################

procesar_argumentos() {
    while (($# > 0)); do
        case "$1" in
            --sin-color)
                USAR_COLOR=0
                shift
                ;;
            -h|--ayuda)
                ui_uso
                exit 0
                ;;
            -v|--version)
                printf '%s %s\n' "$APP_NAME" "$VERSION"
                exit 0
                ;;
            *)
                ui_error "opción desconocida: $1"
                ui_uso >&2
                exit 2
                ;;
        esac
    done
}

preparar_entorno() {
    local fecha
    local home_sudo=""

    if ! comando_disponible timeout; then
        ui_error "falta el comando requerido: timeout (GNU coreutils)."
        exit 1
    fi

    if ((USAR_COLOR == 0)) || [[ ! -t 1 ]] || [[ -n "${NO_COLOR:-}" ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        CYAN=""
        GRAY=""
        NC=""
    fi

    fecha="$(date '+%Y%m%d-%H%M%S')"
    NOMBRE_INFORME="informe-seguridad-$fecha.txt"
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]] \
        && comando_disponible getent; then
        home_sudo="$(getent passwd "$SUDO_USER" | awk -F: '{print $6}')"
        HOME_INFORME="${home_sudo:-$HOME_INFORME}"
    fi

    mkdir -p -- "$TMP_DIR"
    ARCHIVO_RESULTADOS="$(mktemp "$TMP_DIR/auto-audi.XXXXXX")"
    trap limpiar_temporal EXIT HUP INT TERM

    if ((EUID == 0)); then
        ES_ROOT=1
    fi
    if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] \
        || timeout 3 systemctl get-default 2>/dev/null | grep -q '^graphical.target$'; then
        PERFIL="escritorio"
    fi
}

expandir_ruta_usuario() {
    local ruta="$1"

    case "$ruta" in
        "~")
            printf '%s' "$HOME_INFORME"
            ;;
        "~/"*)
            printf '%s/%s' "$HOME_INFORME" "${ruta#"~/"}"
            ;;
        *)
            printf '%s' "$ruta"
            ;;
    esac
}

########################################
# AUDITORÍAS DEL SISTEMA
########################################

auditar_contexto() {
    local os="Linux"
    local virtualizacion="no detectada"

    ui_titulo "Contexto"
    if archivo_legible /etc/os-release; then
        os="$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-Linux}")"
    fi
    if comando_disponible systemd-detect-virt; then
        virtualizacion="$(systemd-detect-virt 2>/dev/null)" || virtualizacion="ninguna"
    fi

    registrar_resultado "INFORMATIVO" "Contexto" \
        "Sistema identificado" \
        "$os; kernel $(uname -r); perfil $PERFIL; virtualización $virtualizacion" \
        "Verifique que el perfil detectado coincide con el uso previsto."

    if ((ES_ROOT == 1)); then
        registrar_resultado "CORRECTO" "Contexto" \
            "Auditoría con privilegios administrativos" \
            "Se pueden leer la mayoría de las configuraciones protegidas." \
            "Mantenga protegido el informe porque puede contener datos sensibles."
    else
        registrar_resultado "ADVERTENCIA" "Contexto" \
            "Cobertura limitada por permisos" \
            "La auditoría se ejecuta como $(id -un), sin privilegios administrativos." \
            "Repita con sudo para comprobar archivos y políticas protegidas."
    fi
}

auditar_actualizaciones() {
    local actualizaciones=""
    local cantidad=0
    local consulta_correcta=1

    ui_titulo "Actualizaciones"
    if comando_disponible apt-get; then
        if ! actualizaciones="$(timeout 20 apt-get -s upgrade 2>/dev/null \
            | awk '/^Inst / {print $2}' | sort -u)"; then
            consulta_correcta=0
        fi
    elif comando_disponible dnf; then
        if ! actualizaciones="$(timeout 20 dnf -q check-update 2>/dev/null \
            | awk 'NF >= 3 && $1 !~ /^(Last|Obsoleting)/ {print $1}')"; then
            # dnf usa 100 para indicar que hay actualizaciones.
            [[ -n "$actualizaciones" ]] || consulta_correcta=0
        fi
    elif comando_disponible yum; then
        if ! actualizaciones="$(timeout 20 yum -q check-update 2>/dev/null \
            | awk 'NF >= 3 {print $1}')"; then
            [[ -n "$actualizaciones" ]] || consulta_correcta=0
        fi
    elif comando_disponible zypper; then
        if ! actualizaciones="$(timeout 20 zypper --non-interactive list-updates 2>/dev/null \
            | awk -F'|' '/^v/ {gsub(/ /, "", $3); print $3}')"; then
            consulta_correcta=0
        fi
    elif comando_disponible pacman; then
        if comando_disponible checkupdates; then
            local estado_checkupdates=0
            if actualizaciones="$(timeout 20 checkupdates 2>/dev/null | awk '{print $1}')"; then
                :
            else
                estado_checkupdates=$?
                # checkupdates usa 2 cuando no hay actualizaciones.
                ((estado_checkupdates == 2)) || consulta_correcta=0
            fi
        else
            registrar_resultado "NO_VERIFICADO" "Actualizaciones" \
                "Actualizaciones pendientes no comprobadas" \
                "pacman está presente, pero falta checkupdates." \
                "Instale pacman-contrib o compruebe las actualizaciones manualmente."
            return
        fi
    else
        registrar_resultado "NO_VERIFICADO" "Actualizaciones" \
            "Gestor de paquetes no reconocido" \
            "No se encontró apt-get, dnf, yum, zypper ni pacman." \
            "Compruebe manualmente los parches de seguridad."
        return
    fi

    if ((consulta_correcta == 0)); then
        registrar_resultado "NO_VERIFICADO" "Actualizaciones" \
            "Actualizaciones pendientes no comprobadas" \
            "El gestor de paquetes falló o superó el límite de 20 segundos." \
            "Compruebe la conectividad, los bloqueos del gestor y los repositorios."
    elif [[ -n "$actualizaciones" ]]; then
        cantidad="$(printf '%s\n' "$actualizaciones" | wc -l)"
        registrar_resultado "ADVERTENCIA" "Actualizaciones" \
            "Hay paquetes pendientes de actualización" \
            "$cantidad paquete(s); primeros: $(printf '%s\n' "$actualizaciones" | head -n 8 | paste -sd ', ' -)" \
            "Revise y aplique los parches, priorizando los avisos de seguridad."
    else
        registrar_resultado "CORRECTO" "Actualizaciones" \
            "No se detectaron actualizaciones pendientes" \
            "La caché local del gestor de paquetes no muestra paquetes actualizables." \
            "Mantenga habilitadas las actualizaciones periódicas."
    fi

    if servicio_habilitado unattended-upgrades.service \
        || servicio_habilitado dnf-automatic.timer \
        || servicio_habilitado yum-cron.service \
        || servicio_habilitado packagekit-background.timer; then
        registrar_resultado "CORRECTO" "Actualizaciones" \
            "Actualizaciones automáticas configuradas" \
            "Se detectó un servicio de actualización automática habilitado." \
            "Revise periódicamente sus registros y política."
    else
        registrar_resultado "ADVERTENCIA" "Actualizaciones" \
            "No se detectaron actualizaciones automáticas" \
            "No hay un servicio habitual de actualización automática habilitado." \
            "Configure actualizaciones de seguridad automáticas o un proceso equivalente."
    fi
}

auditar_firewall() {
    local estado=""

    ui_titulo "Firewall"
    if comando_disponible ufw; then
        estado="$(ufw status 2>/dev/null | head -n 1)" || true
        if [[ "$estado" == *"Status: active"* || "$estado" == *"Estado: activo"* ]]; then
            registrar_resultado "CORRECTO" "Red" "Firewall UFW activo" "$estado" \
                "Revise que las reglas permitan solo los servicios necesarios."
        elif [[ -n "$estado" ]]; then
            registrar_resultado "ALTO" "Red" "Firewall UFW inactivo o no verificable" \
                "$estado" \
                "Active el firewall y defina una política de entrada restrictiva."
        else
            registrar_resultado "NO_VERIFICADO" "Red" "Estado de UFW no comprobado" \
                "La consulta no devolvió un estado; pueden faltar privilegios." \
                "Repita con sudo y compruebe que el firewall esté activo."
        fi
    elif comando_disponible firewall-cmd; then
        if firewall-cmd --state 2>/dev/null | grep -q '^running$'; then
            registrar_resultado "CORRECTO" "Red" "Firewall firewalld activo" \
                "firewall-cmd informa running." \
                "Revise zonas, interfaces y servicios permitidos."
        else
            registrar_resultado "ALTO" "Red" "Firewalld no está activo" \
                "firewall-cmd no informa running." \
                "Active firewalld o configure otro firewall."
        fi
    elif comando_disponible nft; then
        estado="$(nft list ruleset 2>/dev/null)" || true
        if [[ "$estado" == *"hook input"* ]]; then
            registrar_resultado "CORRECTO" "Red" "Reglas nftables detectadas" \
                "Existe al menos una cadena asociada al hook de entrada." \
                "Compruebe que su política y reglas sean restrictivas."
        else
            registrar_resultado "ALTO" "Red" "No se detectó filtrado de entrada con nftables" \
                "El ruleset visible no contiene una cadena con hook input." \
                "Configure un firewall con política de entrada acorde al equipo."
        fi
    elif comando_disponible iptables; then
        estado="$(iptables -S INPUT 2>/dev/null)" || true
        if [[ "$estado" == *"-P INPUT DROP"* || "$estado" == *"-P INPUT REJECT"* ]]; then
            registrar_resultado "CORRECTO" "Red" "Política de entrada restrictiva" \
                "$(printf '%s' "$estado" | head -n 1)" \
                "Revise excepciones y reglas periódicamente."
        else
            registrar_resultado "ADVERTENCIA" "Red" "Firewall iptables sin política restrictiva visible" \
                "${estado:-No fue posible leer la cadena INPUT.}" \
                "Compruebe las reglas con privilegios administrativos."
        fi
    else
        registrar_resultado "NO_VERIFICADO" "Red" "Firewall no comprobado" \
            "No se encontraron herramientas compatibles." \
            "Verifique manualmente el filtrado de red del sistema."
    fi
}

auditar_puertos() {
    local escuchas=""
    local publicos=""
    local cantidad=0

    ui_titulo "Puertos y servicios"
    if comando_disponible ss; then
        escuchas="$(ss -H -lntu 2>/dev/null)" || true
    elif comando_disponible netstat; then
        escuchas="$(netstat -lntu 2>/dev/null | tail -n +3)" || true
    else
        registrar_resultado "NO_VERIFICADO" "Red" "Puertos de escucha no comprobados" \
            "No se encontró ss ni netstat." \
            "Instale iproute2 o compruebe los sockets manualmente."
        return
    fi

    publicos="$(printf '%s\n' "$escuchas" | awk '
        NF && $0 !~ /127\.0\.0\.1:|\[?::1\]?:/ { print }
    ')" || true
    if [[ -n "$publicos" ]]; then
        cantidad="$(printf '%s\n' "$publicos" | wc -l)"
        registrar_resultado "ADVERTENCIA" "Red" \
            "Servicios escuchando en interfaces no locales" \
            "$cantidad socket(s); $(printf '%s\n' "$publicos" | head -n 8 | tr '\n' '; ')" \
            "Confirme que cada puerto sea necesario y esté protegido por el firewall."
    else
        registrar_resultado "CORRECTO" "Red" \
            "No se detectaron servicios expuestos" \
            "Los sockets TCP/UDP visibles están ligados a interfaces locales o no existen." \
            "Repita la revisión después de instalar nuevos servicios."
    fi

    if comando_disponible systemctl; then
        local fallidos
        fallidos="$(timeout 3 systemctl --failed --no-legend --plain 2>/dev/null \
            | awk 'NF {print $1}' | head -n 10 | paste -sd ', ' -)" || true
        if [[ -n "$fallidos" ]]; then
            registrar_resultado "ADVERTENCIA" "Servicios" "Hay unidades systemd fallidas" \
                "$fallidos" \
                "Investigue los registros de cada unidad y descarte fallos relacionados con seguridad."
        else
            registrar_resultado "CORRECTO" "Servicios" "No hay unidades systemd fallidas" \
                "systemctl no informó unidades fallidas." \
                "Continúe supervisando los servicios."
        fi
    fi
}

########################################
# AUDITORÍAS DE ACCESO
########################################

auditar_ssh() {
    local activo=0
    local valor=""

    ui_titulo "Acceso remoto"
    if servicio_activo ssh.service || servicio_activo sshd.service \
        || pgrep -x sshd >/dev/null 2>&1; then
        activo=1
    fi
    if ((activo == 0)); then
        registrar_resultado "CORRECTO" "SSH" "Servidor SSH no activo" \
            "No se detectó un servicio ssh/sshd activo." \
            "Si activa SSH, restrinja autenticación, usuarios y acceso de red."
        return
    fi

    registrar_resultado "INFORMATIVO" "SSH" "Servidor SSH activo" \
        "Se detectó sshd en ejecución." \
        "Exponga el servicio únicamente cuando sea necesario."

    valor="$(obtener_valor_sshd permitrootlogin)"
    case "$valor" in
        no)
            registrar_resultado "CORRECTO" "SSH" "Inicio directo de root desactivado" \
                "PermitRootLogin no" "Mantenga esta directiva." ;;
        prohibit-password|without-password)
            registrar_resultado "ADVERTENCIA" "SSH" "Root puede acceder mediante clave" \
                "PermitRootLogin $valor" \
                "Considere PermitRootLogin no y use una cuenta administrativa nominal." ;;
        yes)
            registrar_resultado "ALTO" "SSH" "Inicio remoto de root permitido" \
                "PermitRootLogin yes" "Defina PermitRootLogin no." ;;
        *)
            registrar_resultado "NO_VERIFICADO" "SSH" "Política de acceso root no verificada" \
                "No fue posible obtener PermitRootLogin." \
                "Revise la configuración efectiva con sshd -T." ;;
    esac

    valor="$(obtener_valor_sshd passwordauthentication)"
    case "$valor" in
        no)
            registrar_resultado "CORRECTO" "SSH" "Contraseñas SSH desactivadas" \
                "PasswordAuthentication no" "Proteja las claves privadas y use frases de paso." ;;
        yes)
            registrar_resultado "ADVERTENCIA" "SSH" "SSH permite contraseñas" \
                "PasswordAuthentication yes" \
                "Prefiera claves y desactive contraseñas tras comprobar el acceso alternativo." ;;
        *)
            registrar_resultado "NO_VERIFICADO" "SSH" "Autenticación SSH no verificada" \
                "No fue posible obtener PasswordAuthentication." \
                "Revise la configuración efectiva con sshd -T." ;;
    esac

    valor="$(obtener_valor_sshd permitemptypasswords)"
    if [[ "$valor" == "yes" ]]; then
        registrar_resultado "ALTO" "SSH" "SSH permite contraseñas vacías" \
            "PermitEmptyPasswords yes" "Defina PermitEmptyPasswords no inmediatamente."
    elif [[ "$valor" == "no" ]]; then
        registrar_resultado "CORRECTO" "SSH" "SSH rechaza contraseñas vacías" \
            "PermitEmptyPasswords no" "Mantenga esta directiva."
    fi
}

auditar_cuentas() {
    local cuentas_uid0
    local cuentas_vacias=""
    local interactivos

    ui_titulo "Cuentas"
    cuentas_uid0="$(awk -F: '$3 == 0 {print $1}' /etc/passwd | paste -sd ', ' -)"
    if [[ "$cuentas_uid0" == "root" ]]; then
        registrar_resultado "CORRECTO" "Cuentas" "Solo root tiene UID 0" \
            "Cuenta con UID 0: root." \
            "Revise periódicamente las cuentas privilegiadas."
    else
        registrar_resultado "ALTO" "Cuentas" "Múltiples cuentas con UID 0" \
            "$cuentas_uid0" \
            "Elimine privilegios UID 0 no justificados y use sudo."
    fi

    if archivo_legible /etc/shadow; then
        cuentas_vacias="$(awk -F: '$2 == "" {print $1}' /etc/shadow | paste -sd ', ' -)"
        if [[ -n "$cuentas_vacias" ]]; then
            registrar_resultado "ALTO" "Cuentas" "Cuentas con contraseña vacía" \
                "$cuentas_vacias" \
                "Bloquee estas cuentas o asigne credenciales seguras."
        else
            registrar_resultado "CORRECTO" "Cuentas" "No hay contraseñas vacías" \
                "No se encontraron campos de contraseña vacíos en /etc/shadow." \
                "Mantenga una política de autenticación robusta."
        fi
    else
        registrar_resultado "NO_VERIFICADO" "Cuentas" "Contraseñas vacías no comprobadas" \
            "/etc/shadow no es legible." \
            "Repita la auditoría con privilegios administrativos."
    fi

    interactivos="$(awk -F: '
        $7 !~ /(nologin|false|sync|shutdown|halt)$/ && $3 >= 1000 {print $1}
    ' /etc/passwd | paste -sd ', ' -)"
    registrar_resultado "INFORMATIVO" "Cuentas" "Cuentas de usuario interactivas" \
        "${interactivos:-No se detectaron cuentas con UID >= 1000.}" \
        "Deshabilite o elimine las cuentas que ya no sean necesarias."

    if archivo_legible /etc/login.defs; then
        local max_dias
        max_dias="$(awk '$1 == "PASS_MAX_DAYS" {print $2; exit}' /etc/login.defs)"
        if [[ "$max_dias" =~ ^[0-9]+$ ]] && ((max_dias <= UMBRAL_PASSWORD_DIAS)); then
            registrar_resultado "CORRECTO" "Cuentas" "Caducidad máxima de contraseña definida" \
                "PASS_MAX_DAYS=$max_dias" \
                "Combine esta política con MFA cuando esté disponible."
        else
            registrar_resultado "ADVERTENCIA" "Cuentas" "Caducidad de contraseña débil o indefinida" \
                "PASS_MAX_DAYS=${max_dias:-sin definir}" \
                "Defina una política acorde al riesgo y aplíquela a las cuentas existentes."
        fi
    fi
}

########################################
# AUDITORÍAS DE PROTECCIÓN LOCAL
########################################

auditar_permisos() {
    local archivo
    local modo
    local propietarios
    local suid=""

    ui_titulo "Archivos y permisos"
    for archivo in /etc/passwd /etc/group /etc/shadow /etc/gshadow; do
        if [[ ! -e "$archivo" ]]; then
            registrar_resultado "NO_VERIFICADO" "Permisos" "Archivo crítico ausente" \
                "$archivo no existe." "Compruebe la integridad del sistema."
            continue
        fi
        modo="$(stat -c '%a' "$archivo" 2>/dev/null)" || modo=""
        if [[ "$archivo" == "/etc/shadow" || "$archivo" == "/etc/gshadow" ]]; then
            if [[ "$modo" =~ ^[0-7]?[0-7][0-4]0$ ]]; then
                registrar_resultado "CORRECTO" "Permisos" "Permisos restrictivos en $archivo" \
                    "Modo $modo." "Mantenga restringida su lectura."
            else
                registrar_resultado "ALTO" "Permisos" "Permisos inseguros en $archivo" \
                    "Modo ${modo:-desconocido}." "Quite permisos para otros usuarios."
            fi
        elif [[ "$modo" =~ ^[0-7]?[0-7][0-5][0-5]$ ]]; then
            registrar_resultado "CORRECTO" "Permisos" "Permisos esperados en $archivo" \
                "Modo $modo." "Mantenga el archivo sin permiso de escritura para grupo u otros."
        else
            registrar_resultado "ALTO" "Permisos" "Archivo crítico modificable indebidamente" \
                "$archivo tiene modo ${modo:-desconocido}." \
                "Restrinja la escritura a root."
        fi
    done

    propietarios="$(find /etc /usr/bin /usr/sbin -xdev -type f \
        \( -perm -0002 -o -nouser -o -nogroup \) -print 2>/dev/null \
        | head -n 20)" || true
    if [[ -n "$propietarios" ]]; then
        registrar_resultado "ALTO" "Permisos" \
            "Archivos sensibles con permisos o propietarios anómalos" \
            "$(printf '%s\n' "$propietarios" | paste -sd ', ' -)" \
            "Revise archivos escribibles por cualquiera y archivos sin propietario."
    else
        registrar_resultado "CORRECTO" "Permisos" \
            "Sin anomalías básicas en rutas sensibles" \
            "No se detectaron archivos escribibles por cualquiera ni sin propietario en /etc, /usr/bin y /usr/sbin." \
            "Amplíe periódicamente la revisión a otros sistemas de archivos."
    fi

    suid="$(find /usr/bin /usr/sbin /bin /sbin -xdev -type f \
        \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null | sort \
        | head -n 30)" || true
    registrar_resultado "INFORMATIVO" "Permisos" "Binarios SUID/SGID detectados" \
        "${suid:-No se detectaron binarios SUID/SGID en rutas estándar.}" \
        "Compare esta lista con la línea base de paquetes instalados."
}

auditar_kernel() {
    local clave
    local esperado
    local valor
    local nivel
    local descripcion

    ui_titulo "Kernel"
    while IFS='|' read -r clave esperado descripcion; do
        [[ -n "$clave" ]] || continue
        if [[ ! -r "/proc/sys/${clave//./\/}" ]]; then
            registrar_resultado "NO_VERIFICADO" "Kernel" "$descripcion" \
                "$clave no está disponible." \
                "Compruebe si el control aplica a este kernel."
            continue
        fi
        valor="$(sysctl -n "$clave" 2>/dev/null)" || valor=""
        nivel="ADVERTENCIA"
        if [[ "$valor" == "$esperado" ]]; then
            nivel="CORRECTO"
        fi
        registrar_resultado "$nivel" "Kernel" "$descripcion" \
            "$clave=${valor:-desconocido}; recomendado=$esperado" \
            "Defina el valor de forma persistente tras validar compatibilidad."
    done <<'EOF'
kernel.randomize_va_space|2|ASLR completo
kernel.kptr_restrict|2|Restricción de punteros del kernel
kernel.dmesg_restrict|1|Restricción de acceso a dmesg
fs.protected_hardlinks|1|Protección de enlaces duros
fs.protected_symlinks|1|Protección de enlaces simbólicos
net.ipv4.conf.all.accept_redirects|0|Rechazo de redirecciones ICMP IPv4
net.ipv4.conf.default.accept_redirects|0|Rechazo predeterminado de redirecciones IPv4
net.ipv4.conf.all.send_redirects|0|Desactivación del envío de redirecciones IPv4
EOF
}

auditar_almacenamiento() {
    local uso
    local montajes

    ui_titulo "Almacenamiento"
    uso="$(df -P / | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')"
    if [[ "$uso" =~ ^[0-9]+$ ]] && ((uso >= UMBRAL_DISCO)); then
        registrar_resultado "ADVERTENCIA" "Almacenamiento" "Poco espacio libre en la raíz" \
            "Uso de /: $uso%." \
            "Libere espacio para evitar fallos de registros y actualizaciones."
    else
        registrar_resultado "CORRECTO" "Almacenamiento" "Espacio disponible en la raíz" \
            "Uso de /: ${uso:-desconocido}%." \
            "Mantenga alertas de capacidad."
    fi

    montajes="$(findmnt -rn -o TARGET,OPTIONS 2>/dev/null \
        | awk '$1 ~ /^\/(tmp|var\/tmp|dev\/shm)$/ {print}')" || true
    if [[ -n "$montajes" ]]; then
        local inseguros=""
        inseguros="$(printf '%s\n' "$montajes" \
            | awk '$0 !~ /(^|,)nosuid(,|$)/ || $0 !~ /(^|,)nodev(,|$)/ {print}')" || true
        if [[ -n "$inseguros" ]]; then
            registrar_resultado "ADVERTENCIA" "Almacenamiento" \
                "Montajes temporales sin todas las restricciones" \
                "$inseguros" \
                "Evalúe nodev, nosuid y, cuando sea viable, noexec."
        else
            registrar_resultado "CORRECTO" "Almacenamiento" \
                "Montajes temporales restringidos" \
                "$montajes" \
                "Mantenga las opciones restrictivas."
        fi
    else
        registrar_resultado "INFORMATIVO" "Almacenamiento" \
            "Directorios temporales no montados por separado" \
            "/tmp, /var/tmp y /dev/shm no aparecen como montajes independientes visibles." \
            "En servidores expuestos, evalúe montajes separados con opciones restrictivas."
    fi
}

auditar_registros() {
    ui_titulo "Registros y defensa"
    if servicio_activo systemd-journald.service \
        || servicio_activo rsyslog.service \
        || servicio_activo syslog-ng.service; then
        registrar_resultado "CORRECTO" "Registros" "Servicio de registros activo" \
            "Se detectó journald, rsyslog o syslog-ng activo." \
            "Configure retención, rotación y envío remoto según el riesgo."
    else
        registrar_resultado "ALTO" "Registros" "No se detectó un servicio de registros activo" \
            "Los servicios habituales no aparecen activos." \
            "Habilite un sistema de registro y revise por qué está detenido."
    fi

    if servicio_activo auditd.service; then
        registrar_resultado "CORRECTO" "Registros" "Auditoría del sistema activa" \
            "auditd está activo." "Revise las reglas y alertas de auditd."
    else
        registrar_resultado "ADVERTENCIA" "Registros" "auditd no está activo" \
            "No se detectó auditd en ejecución." \
            "En servidores y equipos sensibles, configure auditoría de eventos."
    fi

    if servicio_activo fail2ban.service; then
        registrar_resultado "CORRECTO" "Defensa" "Fail2ban activo" \
            "fail2ban está en ejecución." \
            "Compruebe las cárceles activas y sus registros."
    elif servicio_activo ssh.service || servicio_activo sshd.service; then
        registrar_resultado "ADVERTENCIA" "Defensa" "SSH activo sin Fail2ban detectado" \
            "No se detectó fail2ban activo." \
            "Evalúe protección contra fuerza bruta o controles equivalentes."
    else
        registrar_resultado "INFORMATIVO" "Defensa" "Fail2ban no detectado" \
            "No está activo y tampoco se detectó SSH activo." \
            "Evalúe su necesidad si publica otros servicios autenticados."
    fi
}

auditar_escritorio() {
    local bloqueo=""

    [[ "$PERFIL" == "escritorio" ]] || return
    ui_titulo "Escritorio"
    if comando_disponible gsettings; then
        bloqueo="$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)" || true
        if [[ "$bloqueo" == "true" ]]; then
            registrar_resultado "CORRECTO" "Escritorio" "Bloqueo de pantalla habilitado" \
                "GNOME informa lock-enabled=true." \
                "Configure además un tiempo de inactividad razonable."
        elif [[ "$bloqueo" == "false" ]]; then
            registrar_resultado "ADVERTENCIA" "Escritorio" "Bloqueo de pantalla deshabilitado" \
                "GNOME informa lock-enabled=false." \
                "Active el bloqueo automático de pantalla."
        else
            registrar_resultado "NO_VERIFICADO" "Escritorio" "Bloqueo de pantalla no comprobado" \
                "No fue posible consultar una sesión GNOME." \
                "Revise el bloqueo automático en el entorno gráfico usado."
        fi
    else
        registrar_resultado "NO_VERIFICADO" "Escritorio" "Bloqueo de pantalla no comprobado" \
            "No se encontró gsettings." \
            "Revise el bloqueo automático en el entorno gráfico usado."
    fi
}

########################################
# INFORME
########################################

seleccionar_salida() {
    local opcion
    local ruta
    local directorio

    while true; do
        printf '\n%s\n' "¿Desea guardar el informe?"
        printf '%s\n' "1) Sí" "0) No" "?) Ayuda"
        read -rp "Opción: " opcion || opcion="0"

        case "$opcion" in
            1)
                while true; do
                    read -rp "Directorio [~] (*=Volver, 0=No guardar): " ruta \
                        || ruta="0"
                    case "$ruta" in
                        "")
                            ruta="~"
                            ;;
                        0)
                            return 1
                            ;;
                        \*)
                            break
                            ;;
                        \?)
                            printf '%s\n' \
                                "Ingrese solamente el directorio de destino." \
                                "ENTER utiliza ~ y conserva el nombre: $NOMBRE_INFORME"
                            continue
                            ;;
                    esac

                    directorio="$(expandir_ruta_usuario "$ruta")"
                    if [[ ! -d "$directorio" ]]; then
                        ui_error "el directorio no existe: $directorio"
                        continue
                    fi
                    if [[ ! -w "$directorio" ]]; then
                        ui_error "no se puede escribir en: $directorio"
                        continue
                    fi

                    SALIDA="${directorio%/}/$NOMBRE_INFORME"
                    if [[ -e "$SALIDA" ]]; then
                        ui_error "el informe ya existe y no se sobrescribirá: $SALIDA"
                        continue
                    fi
                    return 0
                done
                ;;
            0)
                return 1
                ;;
            \?)
                printf '%s\n' \
                    "El informe contiene el resumen, las evidencias y las recomendaciones." \
                    "Si elige no guardarlo, no se creará ningún archivo de informe."
                ;;
            *)
                ui_error "opción inválida. Use 1, 0 o ?."
                ;;
        esac
    done
}

generar_informe() {
    local nivel
    local categoria
    local titulo
    local evidencia
    local recomendacion
    local total
    local fecha

    total=$((TOTAL_OK + TOTAL_INFO + TOTAL_ADVERTENCIA + TOTAL_ALTO + TOTAL_NO_VERIFICADO))
    fecha="$(date --iso-8601=seconds)"

    {
        printf '%s\n' "INFORME DE AUDITORÍA LOCAL DE SEGURIDAD"
        printf '%s\n' "======================================"
        printf 'Herramienta: %s %s\n' "$APP_NAME" "$VERSION"
        printf 'Fecha: %s\n' "$fecha"
        printf 'Equipo: %s\n' "$(hostname)"
        printf 'Perfil detectado: %s\n' "$PERFIL"
        printf 'Usuario: %s (UID %s)\n' "$(id -un)" "$EUID"
        printf '\n%s\n' "RESUMEN"
        printf '%s\n' "-------"
        printf 'Riesgo alto:       %d\n' "$TOTAL_ALTO"
        printf 'Advertencias:      %d\n' "$TOTAL_ADVERTENCIA"
        printf 'Correctos:         %d\n' "$TOTAL_OK"
        printf 'Informativos:      %d\n' "$TOTAL_INFO"
        printf 'No verificados:    %d\n' "$TOTAL_NO_VERIFICADO"
        printf 'Pruebas totales:   %d\n' "$total"
        printf '\n%s\n' "HALLAZGOS"
        printf '%s\n' "---------"

        while IFS=$'\t' read -r nivel categoria titulo evidencia recomendacion; do
            printf '\n[%s] %s — %s\n' "$nivel" "$categoria" "$titulo"
            printf 'Evidencia: %s\n' "$evidencia"
            printf 'Recomendación: %s\n' "$recomendacion"
        done < "$ARCHIVO_RESULTADOS"

        printf '\n%s\n' "ALCANCE Y LIMITACIONES"
        printf '%s\n' "----------------------"
        printf '%s\n' \
            "- Auditoría pasiva: no explota vulnerabilidades ni modifica configuraciones." \
            "- Los resultados son indicadores y requieren revisión profesional." \
            "- La ausencia de un hallazgo no demuestra que el equipo sea seguro." \
            "- Las comprobaciones dependen de herramientas, permisos y configuración visibles." \
            "- El informe puede revelar usuarios, servicios y configuración; protéjalo."
    } > "$SALIDA"
}

########################################
# MAIN
########################################

main() {
    procesar_argumentos "$@"
    preparar_entorno

    printf '%s %s — auditoría local de solo lectura\n' "$APP_NAME" "$VERSION"
    printf 'Perfil detectado: %s\n' "$PERFIL"

    auditar_contexto
    auditar_actualizaciones
    auditar_firewall
    auditar_puertos
    auditar_ssh
    auditar_cuentas
    auditar_permisos
    auditar_kernel
    auditar_almacenamiento
    auditar_registros
    auditar_escritorio

    printf '\nResumen: %d alto, %d advertencias, %d correctos, %d no verificados.\n' \
        "$TOTAL_ALTO" "$TOTAL_ADVERTENCIA" "$TOTAL_OK" "$TOTAL_NO_VERIFICADO"
    if seleccionar_salida; then
        generar_informe
        printf 'Informe guardado en: %s\n' "$SALIDA"
    else
        printf '%s\n' "Informe no guardado."
    fi

    if ((TOTAL_ALTO > 0)); then
        exit 2
    elif ((TOTAL_ADVERTENCIA > 0)); then
        exit 1
    fi
}

main "$@"
