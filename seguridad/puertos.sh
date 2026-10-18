#!/usr/bin/env bash
# bash_scripts | puertos.sh
# Auditoría interactiva TCP para localhost y LAN. Requiere Nmap.
# Sin argumentos, sin instalación automática, sin privilegios especiales.
clear
set -o pipefail

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RESET=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
    CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
else
    RESET=''; BOLD=''; DIM=''; CYAN=''; GREEN=''; YELLOW=''; RED=''
fi

ANCHO=78
TMP=''
limpiar() { [[ -z "$TMP" ]] || rm -f -- "$TMP"; TMP=''; }
trap limpiar EXIT
trap 'printf "\n%sAuditoría interrumpida.%s\n" "$YELLOW" "$RESET"; exit 130' INT

linea() { printf '%s\n' '──────────────────────────────────────────────────────────────────────────────'; }
pausa() { printf '\n'; read -r -p 'Presioná Enter para continuar...' _ || :; }
error() { printf '%sError:%s %s\n' "$RED" "$RESET" "$1" >&2; }

if ! command -v nmap >/dev/null 2>&1; then
    error 'Nmap no está instalado. Instalalo con el gestor de paquetes de tu distribución.'
    exit 1
fi
if ! command -v awk >/dev/null 2>&1 || ! command -v mktemp >/dev/null 2>&1; then
    error 'Se necesitan awk y mktemp para presentar los resultados.'
    exit 1
fi

encabezado() {
    printf '\n%s%s  bash_scripts / puertos.sh%s\n' "$BOLD" "$CYAN" "$RESET"
    linea
    printf '  Auditoría TCP interactiva · localhost / LAN\n'
    linea
}

mostrar_resultados() {
    local host="$1" modo="$2" inicio="$3" salida="$4"
    local cantidad
    cantidad=$(awk '$1 ~ /^[0-9]+\/tcp$/ && $2 == "open" {n++} END {print n+0}' "$salida")

    printf '\n%s%s RESULTADO DE LA AUDITORÍA %s\n' "$BOLD" "$CYAN" "$RESET"
    linea
    printf '  Objetivo:   %s\n' "$host"
    printf '  Alcance:    %s\n' "$modo"
    printf '  Inicio:     %s\n' "$inicio"
    printf '  Puertos TCP abiertos: %s%s%s\n' "$GREEN" "$cantidad" "$RESET"
    linea

    if (( cantidad == 0 )); then
        printf '%s  No se detectaron puertos TCP abiertos en el alcance seleccionado.%s\n' "$YELLOW" "$RESET"
    else
        printf '%s%-10s %-11s %-17s %-14s %s%s\n' "$BOLD" 'PUERTO' 'ESTADO' 'SERVICIO' 'MOTIVO' 'PRODUCTO / VERSIÓN' "$RESET"
        linea
        awk -v green="$GREEN" -v reset="$RESET" '
            $1 ~ /^[0-9]+\/tcp$/ && $2 == "open" {
                puerto=$1; estado=$2; servicio=$3; motivo=$4
                version=""
                for (i=5; i<=NF; i++) version=version (i==5 ? "" : " ") $i
                if (version=="") version="No identificada"
                printf "%-10s %s%-11s%s %-17s %-14s %s\n", puerto, green, estado, reset, servicio, motivo, version
            }
        ' "$salida"
    fi
    linea
    printf '%s  Nota:%s servicios y versiones son estimaciones de Nmap (-sV).\n' "$DIM" "$RESET"
    printf '%s  Se ocultan fingerprints, puertos cerrados y filtrados.%s\n' "$DIM" "$RESET"
}

while :; do
    encabezado
    printf '  1) Nueva auditoría\n  0) Salir\n'
    linea
    read -r -p 'Opción [0-1]: ' opcion || { printf '\n'; exit 0; }
    case "$opcion" in
        0) printf 'Hasta luego.\n'; exit 0 ;;
        1) ;;
        *) printf '%sOpción inválida.%s\n' "$YELLOW" "$RESET"; continue ;;
    esac

    printf '\n%sObjetivo%s\n' "$BOLD" "$RESET"
    read -r -p 'Host/IP [Enter = 127.0.0.1]: ' host || exit 0
    host=${host:-127.0.0.1}
    if [[ "$host" == -* || "$host" =~ [[:space:]] || "$host" == *'/'* || "$host" == *':'* ]]; then
        error 'Ingresá una IP IPv4 o nombre DNS único, sin espacios ni opciones.'
        pausa; continue
    fi

    printf '\n%sAlcance de la auditoría%s\n' "$BOLD" "$RESET"
    printf '  1) Puertos más comunes (top 1000 TCP de Nmap)\n'
    printf '  2) Todos los puertos TCP (1-65535)\n'
    printf '  3) Un puerto específico\n'
    printf '  0) Volver al menú\n'
    read -r -p 'Opción [0-3]: ' alcance || exit 0
    case "$alcance" in
        0) continue ;;
        1) modo='1000 puertos TCP más frecuentes'; puertos=(-sT --top-ports 1000) ;;
        2) modo='Todos los puertos TCP (1-65535)'; puertos=(-sT -p-) ;;
        3)
            read -r -p 'Puerto TCP [1-65535]: ' puerto || exit 0
            if [[ ! "$puerto" =~ ^[0-9]{1,5}$ ]] || (( 10#$puerto < 1 || 10#$puerto > 65535 )); then
                error 'Puerto inválido (1-65535).'; pausa; continue
            fi
            puerto=$((10#$puerto))
            modo="Puerto TCP $puerto"
            puertos=(-sT -p "$puerto") ;;
        *) printf '%sOpción inválida.%s\n' "$YELLOW" "$RESET"; pausa; continue ;;
    esac

    printf '\n%sResumen%s\n' "$BOLD" "$RESET"
    linea
    printf '  Objetivo:      %s\n  Alcance:       %s\n' "$host" "$modo"
    printf '  Detección:     TCP connect + identificación de servicios (-sV)\n'
    printf '  Visualización: sólo abiertos; servicio, motivo y versión estimada\n'
    linea
    printf '  1) Iniciar\n  0) Cancelar\n'
    read -r -p 'Opción [0-1]: ' confirmar || exit 0
    [[ "$confirmar" == 1 ]] || continue

    TMP=$(mktemp) || { error 'No se pudo crear archivo temporal.'; exit 1; }
    inicio=$(date '+%Y-%m-%d %H:%M:%S')
    printf '\n%sEscaneando %s...%s\n' "$CYAN" "$host" "$RESET"
    printf 'La detección de versiones puede demorar. Ctrl+C interrumpe la auditoría.\n'

    # La salida completa se conserva sólo en un archivo temporal para filtrarla.
    # --reason agrega el motivo; -Pn evita depender del ping; --open oculta cerrados.
    # Nmap puede imprimir fingerprints extensos si no reconoce algún servicio:
    # NO volcamos su salida cruda; mostramos sólo filas de la tabla de puertos.
    if nmap "${puertos[@]}" -sV --reason --open -Pn -T3 -oN "$TMP" -- "$host" >/dev/null; then
        mostrar_resultados "$host" "$modo" "$inicio" "$TMP"
        printf '\n%sAuditoría finalizada.%s\n' "$GREEN" "$RESET"
    else
        error 'Nmap no pudo completar el escaneo.'
        awk '/^Nmap scan report|^Failed|^WARNING|^QUITTING/ {print "  " $0}' "$TMP"
    fi
    limpiar
    pausa
done
