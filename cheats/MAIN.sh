#!/usr/bin/env bash
# Bash Scripts · Cheats viewer 0.1.1
set -euo pipefail

VERSION="0.1.1"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Cada línea .cheat tiene la forma TIPO: contenido.
# Los documentos son datos: nunca se evalúan ni se ejecutan.
# Paleta ANSI: se usa solo si la salida es un terminal.
RESET=$'\033[0m'
BOLD=$'\033[1m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
MAGENTA=$'\033[35m'
DIM=$'\033[2m'

usage() {
    printf 'Visor Cheats %s\n\n' "$VERSION"
    printf 'Uso: %s [archivo.cheat]\n' "$0"
    printf 'Tipos: TITLE SECTION TEXT CMD NOTE WARN EXAMPLE RULE BLANK\n'
}

format_file() {
    local archivo="$1" salida="$2" line tipo contenido color prefijo
    : > "$salida"
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && { printf '\n' >> "$salida"; continue; }
        [[ "$line" == \#* ]] && continue
        if [[ "$line" != *:* ]]; then
            printf '%s\n' "$line" >> "$salida"
            continue
        fi
        tipo="${line%%:*}"
        contenido="${line#*:}"
        contenido="${contenido# }"
        color='' prefijo=''
        case "$tipo" in
            TITLE) color="${BOLD}${CYAN}"; prefijo='▰ ' ;;
            SECTION) color="${BOLD}${GREEN}"; prefijo='▸ ' ;;
            CMD) color="$YELLOW"; prefijo='    $ ' ;;
            TEXT) color=''; prefijo='  ' ;;
            NOTE) color="$CYAN"; prefijo='  ℹ ' ;;
            WARN) color="${BOLD}${RED}"; prefijo='  ⚠ ' ;;
            EXAMPLE) color="$MAGENTA"; prefijo='  → ' ;;
            RULE) printf '%s\n' '────────────────────────────────────────────────────' >> "$salida"; continue ;;
            BLANK) printf '\n' >> "$salida"; continue ;;
            *) printf 'Aviso: tipo desconocido «%s» en %s\n' "$tipo" "$archivo" >&2
               printf '%s\n' "$line" >> "$salida"; continue ;;
        esac
        printf '%s%s%s%s\n' "$color" "$prefijo" "$contenido" "$RESET" >> "$salida"
    done < "$archivo"
}

view_file() {
    local archivo="$1" temporal
    [[ -f "$archivo" && -r "$archivo" ]] || { printf 'No se puede leer: %s\n' "$archivo" >&2; return 1; }
    temporal="$(mktemp)"
    # Garantiza limpieza aunque less se cierre con error.
    if ! format_file "$archivo" "$temporal"; then
        rm -f -- "$temporal"
        return 1
    fi
    if [[ ! -t 1 ]]; then
        cat -- "$temporal"
    elif command -v less >/dev/null 2>&1; then
        LESSHISTFILE=- less -R -- "$temporal" || :
    elif command -v more >/dev/null 2>&1; then
        more -- "$temporal" || :
    else
        cat -- "$temporal"
    fi
    rm -f -- "$temporal"
}

main() {
    local archivos=() opcion i
    if (( $# > 0 )); then
        [[ "$1" == --help || "$1" == -h ]] && { usage; return; }
        view_file "$1"
        return
    fi
    while :; do
        mapfile -d '' -t archivos < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*.cheat' -print0 | sort -z)
        clear
        printf '%sCHEATS%s · Documentación de consola v%s\n' "${BOLD}${CYAN}" "$RESET" "$VERSION"
        printf '%s\n' '──────────────────────────────────────'
        if (( ${#archivos[@]} == 0 )); then
            printf '%s\n' 'No se encontraron archivos .cheat.'
        fi
        for i in "${!archivos[@]}"; do
            printf '[%d] %s\n' "$((i+1))" "$(basename -- "${archivos[i]}" .cheat)"
        done
        printf '\n%s\n' '[0] Salir   [?] Ayuda'
        read -r -p 'Selección: ' opcion || return 0
        case "$opcion" in
            0) return 0 ;;
            '?') printf '\n%s\n' 'Dentro del visor: flechas/PgUp/PgDn, / para buscar, n siguiente, q para volver.'
                 read -r -p 'Enter para continuar...' _ || : ;;
            *) if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] && (( 10#$opcion <= ${#archivos[@]} )); then
                   view_file "${archivos[10#$opcion-1]}"
               else
                   printf '%s\n' 'Opción inválida.'
                   read -r -p 'Enter para continuar...' _ || :
               fi ;;
        esac
    done
}
main "$@"
