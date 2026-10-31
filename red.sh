#!/usr/bin/env bash
# Diagnóstico de red, servicios, Docker, Lynis y tarjetas Ethernet.
# No cambia configuraciones. Lynis puede escribir sus propios logs.
set -o pipefail
VERSION='2.0.0'
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -r "$SCRIPT_DIR/.lib/colores.sh" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/.lib/colores.sh"
else
    RED=$'\033[31m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'
    YELLOW=$'\033[33m'; WHITE=$'\033[97m'; GRAY=$'\033[90m'; NC=$'\033[0m'
fi


for color_name in RED GREEN CYAN YELLOW WHITE GRAY NC; do
    printf -v "$color_name" '%b' "${!color_name}"
done



if [[ -r "$SCRIPT_DIR/.lib/comunes.sh" ]]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/.lib/comunes.sh"
fi
[[ -t 1 && ${TERM:-dumb} != dumb && -z ${NO_COLOR:-} ]] || RED='' GREEN='' CYAN='' YELLOW='' WHITE='' GRAY='' NC=''
command_exists() { command -v "$1" >/dev/null 2>&1; }
width() { local n; n=$(tput cols 2>/dev/null) || n=80; [[ $n =~ ^[0-9]+$ ]] || n=80; ((n<44)) && n=44; printf '%s' "$n"; }
rule() { local n; n=$(width); printf '%s' "$CYAN"; local line; printf -v line '%*s' "$n" ''; printf '%s' "${line// /─}"; printf '%s\n' "$NC"; }
heading() { printf '\n%s%s%s\n' "$WHITE" "$1" "$NC"; rule; }
item() { printf '  %s%-24s%s %s\n' "$CYAN" "$1" "$NC" "${2:-N/D}"; }
notice() { printf '  %s%s%s\n' "$YELLOW" "$*" "$NC"; }
fail() { printf '  %s%s%s\n' "$RED" "$*" "$NC"; }
status() { case "$1" in ok) printf '%sOK%s' "$GREEN" "$NC";; warn) printf '%sATENCIÓN%s' "$YELLOW" "$NC";; *) printf '%sNO DISPONIBLE%s' "$GRAY" "$NC";; esac; }
shorten() { local x=$1 max=${2:-28}; if ((${#x}>max)); then printf '%s…' "${x:0:max-1}"; else printf '%s' "$x"; fi; }
pause() { printf '\n'; read -r -n 1 -s -p 'Presioná una tecla para volver al menú...' _ || :; printf '\n'; }
require_optional() { command_exists "$1" || { notice "Falta '$1': instalalo para completar este apartado."; return 1; }; }

network_report() {
    heading '1 · INFORMACIÓN GENERAL DE RED'
    item Host "$(hostname 2>/dev/null || echo N/D)"
    if command_exists ip; then
        heading 'Interfaces y direcciones'
        local iface state mac ips
        while IFS= read -r iface; do
            [[ -z $iface ]] && continue
            state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo desconocido)
            mac=$(cat "/sys/class/net/$iface/address" 2>/dev/null || echo N/D)
            ips=$(ip -o addr show dev "$iface" 2>/dev/null | awk '$3=="inet" || $3=="inet6" {printf "%s%s", sep,$4;sep=", "}')
            printf '\n  %s%s%s  [%s]\n' "$WHITE" "$iface" "$NC" "$state"
            item 'MAC' "$mac"; item 'Direcciones' "${ips:-Sin dirección}"
        done < <(ls -1 /sys/class/net 2>/dev/null)
        heading 'Rutas predeterminadas'
        ip -4 route show default 2>/dev/null | sed 's/^/  /'
        ip -6 route show default 2>/dev/null | sed 's/^/  /'
    else
        notice 'iproute2 no está instalado.'
    fi
    heading 'DNS'
    if command_exists resolvectl; then
        resolvectl dns 2>/dev/null | sed -n '1,12s/^/  /' || :
    else
        grep -E '^[[:space:]]*nameserver ' /etc/resolv.conf 2>/dev/null | sed 's/^/  /' || :
    fi
    heading 'Conectividad (comprobaciones breves)'
    local gateway
    gateway=$(ip -4 route show default 2>/dev/null | awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}')
    if [[ -n $gateway ]] && command_exists ping; then
        if ping -n -c 1 -W 2 "$gateway" >/dev/null 2>&1; then item Gateway "$(status ok) ($gateway)"; else item Gateway "Sin respuesta ICMP ($gateway)"; fi
    else item Gateway 'No comprobado'; fi
    if command_exists curl; then
        local public
        public=$(curl -4 -fsSL --connect-timeout 2 --max-time 4 https://api.ipify.org 2>/dev/null) || public='No disponible'
        item 'IP pública IPv4' "$public"
        if curl -fsSIL --connect-timeout 2 --max-time 4 https://example.com >/dev/null 2>&1; then item 'HTTPS + DNS' "$(status ok)"; else item 'HTTPS + DNS' 'No se pudo completar (no concluyente)'; fi
    else notice 'curl no instalado: sin comprobación HTTPS/IP pública.'; fi
    if command_exists ping; then
        if ping -n -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then item 'Salida IP (ICMP)' "$(status ok)"; else item 'Salida IP (ICMP)' 'Sin respuesta (no concluyente)'; fi
    fi
}

port_explanation() {
    case "$1" in
        21) echo 'FTP';; 22) echo 'SSH';; 25|465|587) echo 'Correo SMTP';; 53) echo 'DNS';;
        67|68) echo 'DHCP';; 80|8080) echo 'HTTP / web';; 123) echo 'NTP';; 139|445) echo 'SMB / archivos';;
        443|8443) echo 'HTTPS / web';; 631) echo 'CUPS / impresión';; 3306) echo 'MySQL / MariaDB';;
        3389) echo 'Escritorio remoto RDP';; 5432) echo 'PostgreSQL';; 5900) echo 'VNC';;
        6379) echo 'Redis';; 8006) echo 'Proxmox Web';; 8096) echo 'Jellyfin';;
        8000|3000|5000) echo 'Web / desarrollo (habitual)';; 9090) echo 'Panel o métricas (habitual)';;
        *) echo 'Servicio no identificado';;
    esac
}

ports_report() {
    heading '2 · PUERTOS EN ESCUCHA Y SERVICIOS'
    require_optional ss || return
    notice 'Escucha local ≠ puerto accesible desde Internet.'
    printf '\n  %-5s %-27s %-7s %s\n' PROTO DIRECCIÓN PUERTO DESCRIPCIÓN
    rule
    local proto address port process n=0 line desc suffix
    while IFS='|' read -r proto address process; do
        [[ -z $address ]] && continue
        suffix=${address##*:}; port=${suffix//[^0-9]/}
        [[ -z $port ]] && port='?'
        desc=$(port_explanation "$port")
        if [[ -n $process ]]; then desc="$desc · $process"; fi
        printf '  %-5s %-27s %-7s %s\n' "$proto" "$(shorten "$address" 27)" "$port" "$(shorten "$desc" 46)"
        ((n+=1))
    done < <(ss -H -tulnp 2>/dev/null | awk '{proto=$1; addr=$5; p=$0; if (match(p,/users:\(\(/)) {p=substr(p,RSTART); sub(/^[^"]*"/,"",p); sub(/".*/,"",p)} else p=""; print proto "|" addr "|" p}')
    item 'Entradas encontradas' "$n"
    notice 'Los procesos pueden no mostrarse sin privilegios suficientes.'
}

docker_report() {
    heading '3 · CONTENEDORES DOCKER'
    require_optional docker || return
    local output
    if ! output=$(docker ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}|{{.Ports}}' 2>&1); then
        fail 'No se pudo consultar Docker (daemon detenido o permisos insuficientes).'
        printf '  %s\n' "$(shorten "$output" 130)"
        return
    fi
    local name state img ports n=0
    while IFS='|' read -r name state img ports; do
        [[ -z $name ]] && continue
        ((n+=1)); printf '\n  %s[%s]%s %s%s%s\n' "$CYAN" "$n" "$NC" "$WHITE" "$name" "$NC"
        item Estado "$state"
        item Imagen "$(shorten "$img" $(( $(width)-31 )))"
        item Puertos "${ports:-Ninguno publicado}"
    done <<< "$output"
    ((n>0)) || notice 'No hay contenedores.'
    heading 'Redes Docker'
    docker network ls --format '  {{.Name}} · {{.Driver}}' 2>/dev/null || notice 'Sin acceso a redes Docker.'
    heading 'Volúmenes Docker'
    local volumes count
    volumes=$(docker volume ls -q 2>/dev/null) || volumes=''
    count=$(printf '%s\n' "$volumes" | grep -c . || :)
    item Total "${count:-0}"
    [[ -n $volumes ]] && printf '%s\n' "$volumes" | while IFS= read -r name; do printf '  %s\n' "$(shorten "$name" $(( $(width)-6 )))"; done
}

lynis_report() {
    heading '4 · AUDITORÍA DE SEGURIDAD (LYNIS)'
    require_optional lynis || { notice 'Debian/Mint/Proxmox: sudo apt install lynis'; return; }
    notice 'Lynis puede generar archivos de log y datos de auditoría.'
    notice 'La auditoría no aplica correcciones, pero puede tardar varios minutos.'

   local ans

    if [[ ${REPORT_MODE:-0} != 1 ]]; then
        read -r -p '¿Ejecutar auditoría? [1=Sí, 0=Cancelar]: ' ans || return
        [[ $ans == 1 ]] || return
    fi

    if (( EUID != 0 )); then
        if [[ ${REPORT_MODE:-0} == 1 ]]; then
            notice 'Auditoría automática sin sudo: resultados posiblemente parciales.'
            lynis audit system --quick
        else
            notice 'La auditoría sin root puede resultar incompleta.'
            read -r -p '¿Usar sudo para Lynis? [1=Sí, 0=Sin sudo]: ' ans || return

            if [[ $ans == 1 ]]; then
                if ! command_exists sudo; then
                    fail 'sudo no disponible.'
                    return
                fi
                sudo lynis audit system --quick
            else
                lynis audit system --quick
            fi
        fi
    else
        lynis audit system --quick
    fi    


    local rc=$?
    ((rc==0)) || notice "Lynis terminó con código $rc. Verificá su salida."
    local dat
    for dat in /var/log/lynis-report.dat /var/log/lynis.log; do
        if [[ -r $dat ]]; then
            if [[ $dat == *.dat ]]; then
                heading 'Resumen del informe Lynis'
                grep -E '^(hardening_index|warnings\[|suggestions\[)' "$dat" 2>/dev/null | tail -n 18 | cut -c1-150 | sed 's/^/  /' || :
            fi
            item 'Informe' "$dat"
        fi
    done
}

# Solamente dispositivos Ethernet físicos o enlazados a buses de hardware.
physical_interfaces() {
    local p x typ
    for p in /sys/class/net/*; do
        [[ -e $p ]] || continue
        x=${p##*/}
        [[ $x == lo || ! -e $p/device ]] && continue
        typ=$(cat "$p/type" 2>/dev/null || :)
        [[ $typ == 1 ]] || continue
        printf '%s\n' "$x"
    done
}

stat_value() {
    local iface=$1 key=$2 f="/sys/class/net/$1/statistics/$2"
    if [[ -r $f ]]; then cat "$f" 2>/dev/null; else echo '-'; fi
}

# Captura estadísticas para todas las tarjetas, de modo que el muestreo dure 10 s en total.
nic_snapshot() {
    local iface key val
    for iface in "$@"; do
        for key in rx_packets tx_packets rx_errors tx_errors rx_dropped tx_dropped rx_crc_errors rx_frame_errors tx_carrier_errors; do
            val=$(stat_value "$iface" "$key")
            printf '%s|%s|%s\n' "$iface" "$key" "$val"
        done
    done
}

nic_details() {
    local iface=$1 drv speed duplex carrier mac bus pci
    heading "NIC · $iface"
    mac=$(cat "/sys/class/net/$iface/address" 2>/dev/null || echo N/D)
    carrier=$(cat "/sys/class/net/$iface/carrier" 2>/dev/null || echo N/D)
    item MAC "$mac"
    item Enlace "$([[ $carrier == 1 ]] && echo Activo || echo 'Inactivo / desconocido')"
    bus=$(readlink -f "/sys/class/net/$iface/device" 2>/dev/null || echo N/D)
    item 'Ruta hardware' "$(shorten "$bus" $(( $(width)-31 )))"
    if command_exists ethtool; then
        local raw
        raw=$(ethtool "$iface" 2>/dev/null || :)
        speed=$(awk -F': ' '/^[[:space:]]*Speed:/ {print $2}' <<< "$raw")
        duplex=$(awk -F': ' '/^[[:space:]]*Duplex:/ {print $2}' <<< "$raw")
        item Velocidad "${speed:-N/D}"
        item Dúplex "${duplex:-N/D}"
        item Autonegociación "$(awk -F': ' '/Auto-negotiation:/ {print $2}' <<< "$raw")"
        item 'Enlace detectado' "$(awk -F': ' '/Link detected:/ {print $2}' <<< "$raw")"
        local info
        info=$(ethtool -i "$iface" 2>/dev/null || :)
        drv=$(awk -F': ' '/^driver:/ {print $2}' <<< "$info")
        item Driver "${drv:-N/D}"
        item Firmware "$(awk -F': ' '/^firmware-version:/ {print $2}' <<< "$info")"
        item 'Versión driver' "$(awk -F': ' '/^version:/ {print $2}' <<< "$info")"
        printf '\n  %sCapacidades y negociación:%s\n' "$CYAN" "$NC"
        awk '/^[[:space:]]*(Supported link modes:|Advertised link modes:|Link partner advertised link modes:|Supported ports:)/ {show=1; print "  " $0; next} show && /^[[:space:]]+[0-9]+base/ {print "  " $0; next} {show=0}' <<< "$raw" | head -n 22
        if [[ $carrier == 1 && $speed == 100Mb/s ]] && grep -Eq '1000baseT|2500baseT|5000baseT|10000baseT' <<< "$raw"; then
            notice 'Enlace a 100 Mb/s con capacidad superior anunciada/admitida.'
            notice 'Revisar cable (4 pares), puerto remoto y negociación; no confirma daño físico.'
        fi
    else
        notice 'Instalá ethtool para información de negociación, firmware y driver.'
    fi
    if command_exists lspci && [[ $bus == *pci* ]]; then
        pci=${bus##*/}
        lspci -s "$pci" -nn 2>/dev/null | sed 's/^/  Hardware: /'
    elif command_exists lsusb && [[ $bus == *usb* ]]; then
        notice 'NIC USB: identificable mediante lsusb.'
    fi
    printf '\n  %sContadores acumulados:%s\n' "$CYAN" "$NC"
    local k
    for k in rx_errors tx_errors rx_dropped tx_dropped rx_crc_errors rx_frame_errors tx_carrier_errors; do
        item "$k" "$(stat_value "$iface" "$k")"
    done
    if command_exists ethtool; then
        printf '\n  %sEstadísticas extendidas relevantes del driver:%s\n' "$CYAN" "$NC"
        ethtool -S "$iface" 2>/dev/null | grep -Ei 'crc|fcs|align|carrier|reset|timeout|link_down|rx.*error|tx.*error' | head -n 15 | cut -c1-135 | sed 's/^/  /' || :
    fi
}

nic_report() {
    heading '5 · DIAGNÓSTICO EXTENDIDO DE ETHERNET'
    local -a interfaces=()
    local iface key first second start end delta errors=0 elapsed=10 a b
    local -A before=() after=()
    mapfile -t interfaces < <(physical_interfaces)
    if ((${#interfaces[@]}==0)); then notice 'No se detectaron tarjetas Ethernet físicas accesibles.'; return; fi
    item 'NIC físicas detectadas' "${#interfaces[@]}"
    for iface in "${interfaces[@]}"; do nic_details "$iface"; done
    heading 'Muestreo pasivo de contadores (10 segundos)'
    notice 'No se transmite tráfico de prueba ni se modifica ninguna interfaz.'
    while IFS='|' read -r iface key a; do before["$iface|$key"]=$a; done < <(nic_snapshot "${interfaces[@]}")
    sleep "$elapsed"
    while IFS='|' read -r iface key b; do after["$iface|$key"]=$b; done < <(nic_snapshot "${interfaces[@]}")
    for iface in "${interfaces[@]}"; do
        printf '\n  %s%s%s\n' "$WHITE" "$iface" "$NC"
        errors=0
        for key in rx_packets tx_packets rx_errors tx_errors rx_dropped tx_dropped rx_crc_errors rx_frame_errors tx_carrier_errors; do
            first=${before["$iface|$key"]:--}; second=${after["$iface|$key"]:--}
            if [[ $first =~ ^[0-9]+$ && $second =~ ^[0-9]+$ ]] && ((second>=first)); then
                delta=$((second-first))
                if [[ $key != rx_packets && $key != tx_packets && $delta -gt 0 ]]; then ((errors+=delta)); fi
                item "$key" "+$delta"
            else
                item "$key" 'N/D o contador reiniciado'
            fi
        done
        if ((errors>0)); then
            notice 'Se detectaron incrementos en contadores de errores/descartes.'
            notice 'Podrían deberse a cableado, puerto remoto, interferencias o NIC.'
        else
            notice 'Sin incremento de errores en este intervalo (no certifica hardware sano).'
        fi
    done
    heading 'Eventos recientes del kernel'
    if command_exists journalctl; then
        local events pattern
        pattern=$(printf '%s|' "${interfaces[@]}"); pattern=${pattern%|}
        events=$(journalctl -k --since '2 hours ago' --no-pager -o short-iso 2>/dev/null | grep -Ei "($pattern|link (up|down)|carrier|firmware|netdev watchdog|tx timeout|pcie.*error)" | tail -n 18) || events=''
        if [[ -n $events ]]; then printf '%s\n' "$events" | cut -c1-145 | sed 's/^/  /'; else notice 'Sin eventos relevantes accesibles en las últimas 2 horas.'; fi
    else notice 'journalctl no disponible.'; fi
    notice 'Diagnóstico orientativo: comparar con otro cable y puerto gigabit conocidos como buenos.'
}

########################################
# REPORTE COMPLETO
########################################

reporte_ejecutar_seccion() {
    local numero="$1"
    local titulo="$2"
    local funcion="$3"
    local archivo="$4"
    local rc

    printf '\n[%s/5] %s ... ' "$numero" "$titulo"

    # Ejecutar en subshell para no alterar los
    # colores ni las variables del menú principal.
    (
        RED='' GREEN='' CYAN=''
        YELLOW='' WHITE='' GRAY='' NC=''

        REPORT_MODE=1

        printf '\n'
        printf '==================================================\n'
        printf ' SECCIÓN %s: %s\n' "$numero" "$titulo"
        printf '==================================================\n'

        "$funcion"
    ) >> "$archivo" 2>&1

    rc=$?

    if ((rc == 0)); then
        printf '%sOK%s\n' "$GREEN" "$NC"
    else
        printf '%sERROR (%s)%s\n' "$RED" "$rc" "$NC"
        printf 'ERROR en sección %s (código %s)\n' \
            "$numero" "$rc" >> "$archivo"
    fi

    return 0
}


reporte_completo() {
    local archivo fecha inicio fin duracion

    fecha=$(date '+%d-%m-%Y_%H%M%S')
    archivo="$HOME/red___${fecha}.txt"

    inicio=$(date +%s)

    heading '6 · REPORTE COMPLETO DEL SISTEMA'

    item Equipo "$(hostname)"
    item Archivo "$archivo"

    printf '\n'
    notice 'Generando las cinco secciones del diagnóstico.'
    notice 'El muestreo Ethernet requiere 10 segundos.'
    notice 'Lynis puede demorar varios minutos.'
    printf '\n'

    # Reporte privado: puede contener IP, MAC
    # y detalles de seguridad del sistema.
    if ! (umask 077; : > "$archivo"); then
        fail 'No se pudo crear el archivo.'
        return 1
    fi

    {
        printf 'REPORTE COMPLETO DE RED Y SISTEMA\n'
        printf '========================================\n'
        printf 'Equipo: %s\n' "$(hostname)"
        printf 'Usuario: %s\n' "$USER"
        printf 'Fecha: %s\n' "$(date '+%d/%m/%Y %H:%M:%S')"
        printf 'Versión: %s\n' "$VERSION"
        printf '========================================\n'
    } >> "$archivo"

    reporte_ejecutar_seccion \
        1 'Información general de red' \
        network_report "$archivo"

    reporte_ejecutar_seccion \
        2 'Puertos abiertos y servicios' \
        ports_report "$archivo"

    reporte_ejecutar_seccion \
        3 'Contenedores Docker' \
        docker_report "$archivo"

    reporte_ejecutar_seccion \
        4 'Auditoría de seguridad Lynis (puede tardar, entreténgase un rato y no toque nada)' \
        lynis_report "$archivo"

    reporte_ejecutar_seccion \
        5 'Diagnóstico de placas Ethernet' \
        nic_report "$archivo"

    fin=$(date +%s)
    duracion=$((fin - inicio))

    {
        printf '\n'
        printf '========================================\n'
        printf 'FIN DEL REPORTE\n'
        printf 'Duración: %s segundos\n' "$duracion"
        printf '========================================\n'
    } >> "$archivo"

    printf '\n'
    rule

    printf '%sREPORTE FINALIZADO%s\n' "$GREEN" "$NC"

    item 'Archivo' "$archivo"
    item 'Duración' "${duracion} segundos"
    item 'Tamaño' "$(du -h "$archivo" | cut -f1)"

    printf '\n'
    notice 'Podés consultar el informe con:'
    printf '  less "%s"\n' "$archivo"
}

help_screen() {
    heading 'AYUDA'
    printf '%s\n' \
      '  1  IP, DNS, rutas y conectividad.' \
      '  2  Puertos TCP/UDP en escucha con descripción habitual.' \
      '  3  Contenedores, redes y volúmenes Docker.' \
      '  4  Auditoría Lynis (puede generar logs propios).' \
      '  5  Hardware NIC, negociación, errores y muestreo pasivo.' \
      '  6  Generar un reporte completo en ~/red___FECHA_HORA.txt.' \
      '  No aplica correcciones ni cambia parámetros de red.'
}


menu() {
    if [[ -t 1 ]]; then clear; fi
    printf '\n'
    heading "RED · DIAGNÓSTICO DE SISTEMA v$VERSION"
    item Equipo "$(hostname 2>/dev/null || echo N/D)"
    printf '\n'
    printf '  %s1%s  Información general de red\n' "$YELLOW" "$NC"
    printf '  %s2%s  Puertos abiertos y servicios\n' "$YELLOW" "$NC"
    printf '  %s3%s  Contenedores Docker\n' "$YELLOW" "$NC"
    printf '  %s4%s  Auditoría de seguridad · Lynis\n' "$YELLOW" "$NC"
    printf '  %s5%s  Diagnóstico de placas Ethernet\n' "$YELLOW" "$NC"
    printf '  %s6%s  Imprimir reporte completo\n' "$YELLOW" "$NC"
    printf '\n  ?  Ayuda\n  0  Salir\n\n'
}
main() {
    local choice
    while :; do
        menu
        read -r -p 'Opción: ' choice || { printf '\n'; break; }
        case "$choice" in
            1) network_report; pause;;
            2) ports_report; pause;;
            3) docker_report; pause;;
            4) lynis_report; pause;;
            5) nic_report; pause;;
            6) reporte_completo; pause;;
            '?') help_screen; pause;;
            0) break;;
            *) notice 'Opción inválida.'; pause;;
        esac
    done
}
main "$@"
