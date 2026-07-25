#!/usr/bin/env bash
#
# ==========================================================
# wp-scrapper.sh
# ----------------------------------------------------------
# Scrapper de directorios HTTP orientado a instalaciones
# WordPress.
#
# Proyecto : bash_scripts
# Autor    : Neocronos
# Version  : 0.1.0
# ==========================================================

set -o errexit
set -o pipefail
set -o nounset

########################################
# CONFIGURACION
########################################

APP_NAME="wp-scrapper"
VERSION="0.1.0"

USER_AGENT="Mozilla/5.0"
TIMEOUT=10
MAX_RETRIES=3
MAX_DEPTH=10

MAX_LINEAS=30

DESTINO="${BASH_SCRIPTS_DOWNLOADS:-$HOME/Descargas/scrapped}/wp"
CACHE_DIR="$HOME/.cache/wp-scrapper"

COLOR=1

########################################
# CONFIGURACION DE TABLAS
########################################

ANCHO_ETIQUETA=22
ANCHO_VALOR=20

########################################
# LIBRERIAS
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

source "$BASE_DIR/.lib/colores.sh"
source "$BASE_DIR/.lib/comunes.sh"

########################################
# VARIABLES GLOBALES
########################################

URL=""

BUSQUEDA=""
BUSQUEDA_TAMANO=""

CACHE_LISTA=""
CACHE_FILTRADA=""

TMP_ACTUAL=""
VISITADOS=""

RESULTADOS=0
RESULTADOS_FILTRADOS=0

ESTADO=""

########################################
# FUNCIONES DE INTERFAZ
########################################

ui_titulo() {

    clear

#    fila_dinamica techo2
#    fila_dinamica " " \
#        "WP SCRAPPER" \
#        "v$VERSION" \      
#    fila_dinamica piso2
    echo " "
    echo "    🌐 WP SCRAPPER v$VERSION" 
    linea
}

ui_error() {

    printf "\n${RED}%s${NC}\n" "$1"

}

ui_ok() {

    printf "\n${GREEN}%s${NC}\n" "$1"

}

ui_info() {

    printf "\n${CYAN}%s${NC}\n" "$1"

}

########################################
# FUNCIONES DE CACHE
########################################

cache_crear() {

    mkdir -p "$CACHE_DIR"

}

cache_limpiar() {

    rm -f "$CACHE_DIR"/* 2>/dev/null || true

}

########################################
# FUNCIONES TMP
########################################

tmp_listar() {

    find "$DESTINO" \
        -maxdepth 1 \
        -type f \
        -name "*.t" \
        | sort

}

tmp_existen() {

    local cantidad

    cantidad=$(tmp_listar | wc -l)

    [[ "$cantidad" -gt 0 ]]

}

tmp_reanudar() {
    local -a pendientes=()
    local opcion

    mapfile -t pendientes < <(tmp_listar)
    ((${#pendientes[@]})) || return 0
    for opcion in "${!pendientes[@]}"; do
        printf "%d) %s\n" "$((opcion + 1))" "$(basename "${pendientes[$opcion]}")"
    done
    printf "0) Cancelar\n"
    read -r -p "Descarga a reanudar: " opcion
    [[ "$opcion" =~ ^[0-9]+$ ]] || return 1
    ((opcion > 0 && opcion <= ${#pendientes[@]})) || return 0
    TMP_ACTUAL="${pendientes[$((opcion - 1))]}"
    descarga_ejecutar
    descarga_informe

}

########################################
# FUNCIONES ANALISIS
########################################

scan_analizar() {
    local lista_urls
    CACHE_LISTA="$(mktemp "$CACHE_DIR/lista.XXXXXX")"
    CACHE_FILTRADA="$(mktemp "$CACHE_DIR/filtro.XXXXXX")"
    lista_urls="$(mktemp "$CACHE_DIR/urls.XXXXXX")"
    VISITADOS="$(mktemp "$CACHE_DIR/visitados.XXXXXX")"

    ui_info "Intentando Index Of..."
    if ! scan_index >> "$lista_urls"; then
        ui_info "Intentando sitemap..."
        scan_sitemap >> "$lista_urls" || true
        ui_info "Intentando robots.txt..."
        scan_robots >> "$lista_urls" || true
    fi

    sort -u "$lista_urls" -o "$lista_urls"
    while IFS= read -r enlace; do
        [[ -n "$enlace" ]] && metadata_archivo "$enlace"
    done < "$lista_urls" > "$CACHE_LISTA"
    rm -f "$lista_urls" "$VISITADOS"
    VISITADOS=""

    RESULTADOS=$(wc -l < "$CACHE_LISTA")
    RESULTADOS_FILTRADOS=$RESULTADOS
    cp "$CACHE_LISTA" "$CACHE_FILTRADA"
    ui_ok "$RESULTADOS archivo(s) encontrado(s)."
    ((RESULTADOS > 0)) || {
        ui_error "No se encontraron archivos."
        return 1
    }

}

scan_index() {

    local pagina
    local codigo
    pagina="$(mktemp "$CACHE_DIR/index.XXXXXX")"

    codigo=$(
        curl \
            --silent \
            --location \
            --connect-timeout "$TIMEOUT" \
            --user-agent "$USER_AGENT" \
            --write-out "%{http_code}" \
            --output "$pagina" \
            "$URL"
    )

    [[ "$codigo" != "200" ]] && return 1

    if ! grep -Eqi "Index of|Directory listing for" "$pagina"
    then
        rm -f "$pagina"
        return 1
    fi

    grep -oE 'href="[^"]+"' "$pagina" | sed -E 's/^href="//; s/"$//' \
    | while read -r enlace
    do

        [[ -z "$enlace" ]] && continue

        [[ "$enlace" == "../" ]] && continue

        if [[ "$enlace" =~ /$ ]]
        then

            scan_index_directorio "$(url_resolver "$URL" "$enlace")" 1

        else

            url_resolver "$URL" "$enlace"

        fi

    done

    rm -f "$pagina"

}

scan_index_directorio() {

    local BASE="$1"
    local profundidad="${2:-1}"
    local pagina
    local codigo
    ((profundidad <= MAX_DEPTH)) || return 0
    grep -Fqx "$BASE" "$VISITADOS" 2>/dev/null && return 0
    printf '%s\n' "$BASE" >> "$VISITADOS"
    pagina="$(mktemp "$CACHE_DIR/directorio.XXXXXX")"

    codigo=$(
        curl \
            --silent \
            --location \
            --connect-timeout "$TIMEOUT" \
            --user-agent "$USER_AGENT" \
            --write-out "%{http_code}" \
            --output "$pagina" \
            "$BASE"
    )

    [[ "$codigo" != "200" ]] && return

    grep -oE 'href="[^"]+"' "$pagina" | sed -E 's/^href="//; s/"$//' \
    | while read -r enlace
    do

        [[ "$enlace" == "../" ]] && continue

        if [[ "$enlace" =~ /$ ]]
        then

            scan_index_directorio "$(url_resolver "$BASE" "$enlace")" "$((profundidad + 1))"

        else

            url_resolver "$BASE" "$enlace"

        fi

    done

    rm -f "$pagina"

}

url_resolver() {
    local base="$1"
    local enlace="$2"
    local origen resultado origen_resultado origen_objetivo

    enlace="${enlace%%#*}"
    [[ -n "$enlace" ]] || return 1
    [[ "$enlace" =~ ^(mailto:|javascript:|data:) ]] && return 1
    if [[ "$enlace" =~ ^https?:// ]]; then
        resultado="$enlace"
    else
        origen="${base%%//*}//${base#*//}"
        origen="${origen%%/*}"
        if [[ "$enlace" == /* ]]; then
            resultado="$origen$enlace"
        else
            [[ "$base" == */ ]] || base="${base%/*}/"
            resultado="$base$enlace"
        fi
    fi

    if [[ -n "$URL" ]]; then
        origen_resultado="${resultado%%//*}//${resultado#*//}"
        origen_resultado="${origen_resultado%%/*}"
        origen_objetivo="${URL%%//*}//${URL#*//}"
        origen_objetivo="${origen_objetivo%%/*}"
        [[ "$origen_resultado" == "$origen_objetivo" ]] || return 1
    fi
    printf '%s\n' "$resultado"
}

metadata_archivo() {
    local enlace="$1"
    local nombre tamano

    nombre="$(basename "${enlace%%\?*}")"
    [[ -n "$nombre" && "$nombre" != "/" ]] || nombre="index"
    tamano="$(
        curl --silent --location --head --connect-timeout "$TIMEOUT" \
            --max-time "$TIMEOUT" --user-agent "$USER_AGENT" "$enlace" |
            awk 'BEGIN{IGNORECASE=1} /^content-length:/ {gsub("\r","",$2); n=$2} END{print n}'
    )"
    [[ "$tamano" =~ ^[0-9]+$ ]] || tamano="-"
    printf "%s\t%s\t%s\n" "$nombre" "$tamano" "$enlace"
}

scan_sitemap() {

    local BASE
    local MAPA

    BASE="${URL%%//*}//${URL#*//}"
    BASE="${BASE%%/*}"

    for MAPA in \
        sitemap.xml \
        wp-sitemap.xml
    do

        curl \
            --silent \
            --location \
            --connect-timeout "$TIMEOUT" \
            --user-agent "$USER_AGENT" \
            "$BASE/$MAPA" \
        | grep -oE 'https?://[^<]+' \
        | grep "^$URL" || true

    done

}

scan_robots() {

    local BASE

    BASE="${URL%%//*}//${URL#*//}"
    BASE="${BASE%%/*}"

    curl \
        --silent \
        --location \
        --connect-timeout "$TIMEOUT" \
        --user-agent "$USER_AGENT" \
        "$BASE/robots.txt" \
    | grep -oE 'https?://[^ ]+' \
    | grep "^$URL" || true

}
########################################
# FUNCIONES FILTRO
########################################

filter_aplicar() {

    cp "$CACHE_LISTA" "$CACHE_FILTRADA"

    ####################################
    # FILTRO DE TEXTO
    ####################################

    if [[ -n "$BUSQUEDA" ]]
    then
        filter_texto
    fi

    ####################################
    # FILTRO DE TAMAÑO
    ####################################

    if [[ -n "$BUSQUEDA_TAMANO" ]]
    then
        filter_tamano
    fi

    RESULTADOS_FILTRADOS=$(wc -l < "$CACHE_FILTRADA")

}

########################################

filter_texto() {

    local patron="$BUSQUEDA"

    if [[ "$patron" =~ ^re: ]]
    then

        patron="${patron#re:}"

        grep -Ei "$patron" \
            "$CACHE_FILTRADA" \
            > "${CACHE_FILTRADA}.tmp" || true

    else

        patron=$(printf "%s" "$patron" \
            | sed 's/\./\\./g' \
            | sed 's/\*/.*/g' \
            | sed 's/\?/./g')

        grep -Ei "$patron" \
            "$CACHE_FILTRADA" \
            > "${CACHE_FILTRADA}.tmp" || true

    fi

    mv \
        "${CACHE_FILTRADA}.tmp" \
        "$CACHE_FILTRADA"

}

########################################

size_to_bytes() {

    local valor

    valor="${1^^}"

    case "$valor" in

        *K)

            echo $(( ${valor%K} * 1024 ))
            ;;

        *M)

            echo $(( ${valor%M} * 1024 * 1024 ))
            ;;

        *G)

            echo $(( ${valor%G} * 1024 * 1024 * 1024 ))
            ;;

        *)

            echo "$valor"
            ;;

    esac

}

########################################

filter_tamano() {

    local expresion="$BUSQUEDA_TAMANO"

    local operador
    local minimo
    local maximo

    ####################################
    # ENTRE A-B
    ####################################

    if [[ "$expresion" =~ ^(.+)-(.+)$ ]]
    then

        minimo=$(size_to_bytes "${BASH_REMATCH[1]}")
        maximo=$(size_to_bytes "${BASH_REMATCH[2]}")

        while IFS=$'\t' read -r nombre tamano url
        do

            [[ "$tamano" == "-" ]] && continue

            if (( tamano >= minimo && tamano <= maximo ))
            then
                printf "%s\t%s\t%s\n" \
                    "$nombre" \
                    "$tamano" \
                    "$url"
            fi

        done < "$CACHE_FILTRADA" \
            > "${CACHE_FILTRADA}.tmp"

    ####################################
    # > >= < <=
    ####################################

    elif [[ "$expresion" =~ ^([<>]=?)(.+)$ ]]
    then

        operador="${BASH_REMATCH[1]}"
        minimo=$(size_to_bytes "${BASH_REMATCH[2]}")

        while IFS=$'\t' read -r nombre tamano url
        do

            [[ "$tamano" == "-" ]] && continue

            case "$operador" in

                ">")

                    (( tamano > minimo )) &&
                    printf "%s\t%s\t%s\n" \
                        "$nombre" "$tamano" "$url"
                    ;;

                ">=")

                    (( tamano >= minimo )) &&
                    printf "%s\t%s\t%s\n" \
                        "$nombre" "$tamano" "$url"
                    ;;

                "<")

                    (( tamano < minimo )) &&
                    printf "%s\t%s\t%s\n" \
                        "$nombre" "$tamano" "$url"
                    ;;

                "<=")

                    (( tamano <= minimo )) &&
                    printf "%s\t%s\t%s\n" \
                        "$nombre" "$tamano" "$url"
                    ;;

            esac

        done < "$CACHE_FILTRADA" \
            > "${CACHE_FILTRADA}.tmp"

    ####################################
    # IGUAL
    ####################################

    else

        minimo=$(size_to_bytes "$expresion")

        while IFS=$'\t' read -r nombre tamano url
        do

            [[ "$tamano" == "-" ]] && continue

            (( tamano == minimo )) &&
            printf "%s\t%s\t%s\n" \
                "$nombre" \
                "$tamano" \
                "$url"

        done < "$CACHE_FILTRADA" \
            > "${CACHE_FILTRADA}.tmp"

    fi

    mv \
        "${CACHE_FILTRADA}.tmp" \
        "$CACHE_FILTRADA"

}

########################################

mostrar_resultados() {

    printf "\n"

    printf "%-45s %-12s %s\n" \
        "NOMBRE" \
        "TAMAÑO" \
        "URL"

    printf "%-45s %-12s %s\n" \
        "---------------------------------------------" \
        "------------" \
        "-----------------------------------------------------"

    head -n "$MAX_LINEAS" "$CACHE_FILTRADA" \
    | while IFS=$'\t' read -r nombre tamano url
    do

        printf "%-45s %-12s %s\n" \
            "$nombre" \
            "$tamano" \
            "$url"

    done

    printf "\n"

    printf "Mostrando %d de %d resultado(s).\n" \
        "$(
            if (( RESULTADOS_FILTRADOS < MAX_LINEAS ))
            then
                echo "$RESULTADOS_FILTRADOS"
            else
                echo "$MAX_LINEAS"
            fi
        )" \
        "$RESULTADOS_FILTRADOS"

}
########################################
# FUNCIONES DESCARGA
########################################

descarga_preparar() {

    local nombre

    nombre=$(
        printf "%s" "$URL" \
        | sed 's#^https\?://##' \
        | sed 's#/$##' \
        | tr '/' '-'
    )

    TMP_ACTUAL="$DESTINO/${nombre}.t"

    mkdir -p "$DESTINO/$nombre"

    cp "$CACHE_FILTRADA" "$TMP_ACTUAL"

}

########################################

nombre_destino() {

    local archivo="$1"

    local base
    local ext
    local destino

    local n=1

    base="${archivo%.*}"
    ext="${archivo##*.}"

    destino="$archivo"

    while [[ -f "$destino" ]]
    do

        printf -v destino "%s-%03d.%s" \
            "$base" \
            "$n" \
            "$ext"

        ((n += 1))

    done

    printf "%s" "$destino"

}

########################################

quitar_tmp() {

    local url="$1"

    awk -F '\t' -v objetivo="$url" '$3 != objetivo' \
        "$TMP_ACTUAL" > "${TMP_ACTUAL}.tmp"

    mv \
        "${TMP_ACTUAL}.tmp" \
        "$TMP_ACTUAL"

    if [[ ! -s "$TMP_ACTUAL" ]]
    then
        rm -f "$TMP_ACTUAL"
    fi

}

########################################

descargar_archivo() {

    local url="$1"

    local destino
    local archivo

    local intento

    archivo="$(basename "$url")"

    destino="$DESTINO/$(
        basename "${TMP_ACTUAL%.t}"
    )"

    archivo=$(nombre_destino "$destino/$archivo")

    for ((intento=1; intento<=MAX_RETRIES; intento++))
    do

        if wget \
            --quiet \
            --timeout="$TIMEOUT" \
            --user-agent="$USER_AGENT" \
            --show-progress \
            -O "$archivo" \
            "$url"
        then

            quitar_tmp "$url"

            return 0

        fi

    done

    return 1

}

########################################

descarga_ejecutar() {

    local hubo_error=0

    local total
    local actual=0

    total=$(wc -l < "$TMP_ACTUAL")

    while true
    do

        hubo_error=0

        while IFS=$'\t' read -r nombre tamano url
        do

            ((actual += 1))

            printf "\n"

            printf "[%d/%d]\n" \
                "$actual" \
                "$total"

            printf "%s\n\n" \
                "$nombre"

            if ! descargar_archivo "$url"
            then

                hubo_error=1

                ui_error "No se pudo descargar."

            fi

        done < "$TMP_ACTUAL"

        if ((hubo_error==0))
        then
            break
        fi

        printf "\n"

        read -rp \
            "Hubo errores. ¿Reintentar descargas pendientes? [S/n]: " \
            RESP

        case "${RESP,,}" in

            ""|"s"|"si"|"sí")

                actual=0
                total=$(wc -l < "$TMP_ACTUAL")

                continue
                ;;

            *)

                break
                ;;

        esac

    done

}

########################################

descarga_informe() {

    printf "\n"

    fila_dinamica techo2

    fila_dinamica "|" \
        "Descarga finalizada" \
        ""

    fila_dinamica piso2

    if [[ -f "$TMP_ACTUAL" ]]
    then

        printf "\n"

        printf "Pendientes : %s\n" \
            "$(wc -l < "$TMP_ACTUAL")"

    else

        printf "\n"

        printf "Pendientes : 0\n"

    fi

    printf "\n"

    read -rp \
        "Pulse ENTER para continuar..." _

}


########################################
# FUNCIONES GENERALES
########################################

pedir_url() {

    while true
    do
        printf "\n"
        read -rp "URL (0=Salir): " URL

        case "$URL" in
            0)
                exit 0
                ;;
            "")
                continue
                ;;
            \?)
                ui_info "Ayuda aún no implementada."
                ;;
            *)
                if [[ "$URL" =~ ^https?://[^[:space:]]+$ ]]; then
                    return
                fi
                ui_error "La URL debe comenzar con http:// o https://."
                ;;
        esac
    done

}

reiniciar() {

    [[ -n "$CACHE_LISTA" ]] && rm -f -- "$CACHE_LISTA"
    [[ -n "$CACHE_FILTRADA" ]] && rm -f -- "$CACHE_FILTRADA"
    URL=""

    BUSQUEDA=""
    BUSQUEDA_TAMANO=""

    CACHE_LISTA=""
    CACHE_FILTRADA=""

    RESULTADOS=0
    RESULTADOS_FILTRADOS=0

}
########################################
# MAIN
########################################

main() {

    command -v curl >/dev/null 2>&1 || {
        ui_error "Falta curl."
        return 127
    }
    command -v wget >/dev/null 2>&1 || {
        ui_error "Falta wget."
        return 127
    }
    mkdir -p "$DESTINO"
    cache_crear

    ####################################
    # COMPROBACION DE DESCARGAS PENDIENTES
    ####################################

    if tmp_existen
    then

        ui_titulo

        ui_info "Se encontraron las siguientes descargas pendientes."

        printf "\n"

        tmp_listar | while read -r archivo
        do
            printf "  • %s\n" "$(basename "$archivo")"
        done

        printf "\n"

#        read -rp "¿Desea reanudarlas? [S/n]: " RESPUESTA

#        case "${RESPUESTA,,}" in

#            ""|"s"|"si"|"sí")

#                tmp_reanudar
#                ;;

#        esac
       
        echo "1) Reanudar"
        echo "2) Ignorar"
        echo "0) Salir"
        read -r -p "Opción: " RESPUESTA
        case "$RESPUESTA" in

            1)
                tmp_reanudar
                ;;

            2)
                ;;

            0)
                exit 0
                ;;

            \?)
                ui_info "Ayuda aún no implementada."
                ;;

        esac

    fi

    ####################################
    # BUCLE PRINCIPAL
    ####################################

    while true
    do

        reiniciar

        ui_titulo

        pedir_url

        [[ -z "$URL" ]] && continue

        ui_info "Analizando..."

        if ! scan_analizar; then
            pausa
            continue
        fi

        ################################
        # BUCLE DE FILTRADO
        ################################

        while true
        do

            printf "\n"

            printf "Busqueda anterior : %s\n" \
                "${BUSQUEDA:-<ninguna>}"

            printf "Tamaño anterior   : %s\n" \
                "${BUSQUEDA_TAMANO:-<cualquiera>}"

            printf "Resultados        : %s\n" \
                "$RESULTADOS_FILTRADOS"

            printf "\n"

            printf "Texto (glob o re:): "
            read -r BUSQUEDA

            printf "\n"

            printf "Tamaño (ENTER=cualquiera): "
            read -r BUSQUEDA_TAMANO

            printf "\n"

            filter_aplicar

            mostrar_resultados

            printf "\n"

            echo
            echo "Acciones"
            echo "--------"
            echo "1) Descargar"
            echo "2) Refinar filtros"
            echo "*) Nueva URL"
            echo "0) Salir"
            echo "? ) Ayuda"
            echo

            printf "\n"

            read -rp "🗿${USER:-usuario}⭕> " OPCION

            case "$OPCION" in

                1)

                    descarga_preparar
                    descarga_ejecutar
                    descarga_informe

                    break
                    ;;

                2)

                    continue
                    ;;

                \*)

                    break
                    ;;

                0)

                    exit 0
                    ;;

                \?)

                    ui_info "Ayuda aún no implementada."
                    pausa
                    ;;

                *)

                    ui_error "Opción inválida."
                    pausa
                    ;;

            esac
        done

    done

}

########################################
# INICIO
########################################

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi

exit 0
