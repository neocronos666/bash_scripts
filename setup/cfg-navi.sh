#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

VERSION="0.1.0"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../.lib/comunes.sh
source "$SCRIPT_DIR/.lib/comunes.sh" || {
    printf 'Error: no se pudo cargar %s\n' "$SCRIPT_DIR/.lib/comunes.sh" >&2
    exit 1
}

NAVI_BIN_DIR="${HOME}/.local/bin"
NAVI_CHEATS_SOURCE="$SCRIPT_DIR/.vendor/navi/cheats"
NAVI_CHEATS_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/navi/cheats"
BASHRC="${BASHRC:-$HOME/.bashrc}"
NAVI_BASHRC_START="# >>> bash_scripts navi >>>"
NAVI_BASHRC_END="# <<< bash_scripts navi <<<"

instalar_navi() {
    local instalador

    asegurar_dependencia "curl" "curl"         "Curl se utiliza para descargar el instalador oficial de Navi." || return 1

    mkdir -p "$NAVI_BIN_DIR"
    instalador="$(mktemp "${TMPDIR:-/tmp}/navi-install.XXXXXX")"

    printf 'Descargando el instalador oficial de Navi...\n'
    if ! curl -fsSL         "https://raw.githubusercontent.com/denisidoro/navi/master/scripts/install"         -o "$instalador"; then
        rm -f "$instalador"
        printf 'Error: no se pudo descargar el instalador de Navi.\n' >&2
        return 1
    fi

    if ! BIN_DIR="$NAVI_BIN_DIR" bash "$instalador"; then
        rm -f "$instalador"
        printf 'Error: la instalación de Navi falló.\n' >&2
        return 1
    fi

    rm -f "$instalador"
}

configurar_path() {
    case ":$PATH:" in
        *":$NAVI_BIN_DIR:"*) ;;
        *) export PATH="$NAVI_BIN_DIR:$PATH" ;;
    esac
}

configurar_cheats() {
    local destino="$NAVI_CHEATS_HOME/bash_scripts"

    mkdir -p "$NAVI_CHEATS_HOME"

    if [[ -L "$destino" ]]; then
        if [[ "$(readlink -f "$destino")" == "$(readlink -f "$NAVI_CHEATS_SOURCE")" ]]; then
            return 0
        fi

        rm -f "$destino"
    elif [[ -e "$destino" ]]; then
        printf 'Error: ya existe %s y no es un enlace simbólico.\n' "$destino" >&2
        printf 'No se modificará ese directorio.\n' >&2
        return 1
    fi

    ln -s "$NAVI_CHEATS_SOURCE" "$destino"
}

configurar_widget() {
    local bloque

    touch "$BASHRC"

    bloque="$(mktemp "${TMPDIR:-/tmp}/navi-bashrc.XXXXXX")"
    cat > "$bloque" <<EOF
$NAVI_BASHRC_START

export PATH="$NAVI_BIN_DIR:\$PATH"
source <(navi widget bash)

$NAVI_BASHRC_END
EOF

    if grep -Fq "$NAVI_BASHRC_START" "$BASHRC"; then
        sed -i "/$NAVI_BASHRC_START/,/$NAVI_BASHRC_END/d" "$BASHRC"
    fi

    printf '\n' >> "$BASHRC"
    cat "$bloque" >> "$BASHRC"
    rm -f "$bloque"
}

mostrar_inicio_rapido() {
    printf '\n'
    printf 'Navi quedó configurado.\n'
    printf '\n'
    printf 'Inicio rápido:\n'
    printf '  Ctrl+G    abrir Navi desde Bash\n'
    printf '  navi      abrir Navi manualmente\n'
    printf '\n'
    printf 'Cheats de bash_scripts:\n'
    printf '  %s\n' "$NAVI_CHEATS_SOURCE"
    printf '\n'
    printf 'Recargá Bash o ejecutá: source ~/.bashrc\n'
}

main() {
    configurar_path

    if ! comando_disponible "fzf"; then
        asegurar_dependencia "fzf" "fzf"             "Navi necesita fzf para su interfaz interactiva." || exit 1
    fi

    if ! comando_disponible "navi"; then
        printf 'Navi no está instalado.\n'
        read -r -p '¿Instalar Navi ahora? [1=Sí/0=No] ' respuesta
        case "$respuesta" in
            1)
                instalar_navi
                configurar_path
                ;;
            *)
                printf 'No se instaló Navi.\n'
                exit 1
                ;;
        esac
    fi

    if ! comando_disponible "navi"; then
        printf 'Error: Navi sigue sin estar disponible en PATH.\n' >&2
        exit 1
    fi

    configurar_cheats
    configurar_widget
    mostrar_inicio_rapido
}

main "$@"
