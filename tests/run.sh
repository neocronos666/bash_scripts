#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fallos=0

ok() { printf 'ok - %s\n' "$1"; }
no_ok() { printf 'not ok - %s\n' "$1" >&2; fallos=$((fallos + 1)); }

probar_sintaxis() {
    local archivo
    while IFS= read -r -d '' archivo; do
        if bash -n "$archivo"; then
            ok "sintaxis ${archivo#"$ROOT"/}"
        else
            no_ok "sintaxis ${archivo#"$ROOT"/}"
        fi
    done < <(
        find "$ROOT" -path "$ROOT/.git" -prune -o \
            -path "$ROOT/.deprecated" -prune -o \
            -type f \( -name '*.sh' -o -name 'ayuda' \) -print0
    )
}

probar_regresiones() {
    if grep -Rq '\$user' "$ROOT" --include='*.sh' \
        --exclude='run.sh' --exclude-dir='.deprecated'; then
        no_ok 'no hay variable $user accidental'
    else
        ok 'no hay variable $user accidental'
    fi

    if grep -q 'nano etc/hosts' "$ROOT/seguridad/editar-hosts.sh"; then
        no_ok 'editar-hosts usa /etc/hosts'
    else
        ok 'editar-hosts usa /etc/hosts'
    fi

    if grep -q '^RecR$' "$ROOT/tweaks/limpiar_anaconda.sh"; then
        no_ok 'limpiar_anaconda no ejecuta basura residual'
    else
        ok 'limpiar_anaconda no ejecuta basura residual'
    fi
}

probar_wp_scrapper() {
    if HOME="${TMPDIR:-/tmp}" bash -c '
        source "$1/scrapping/wp-scrapper.sh"
        resultado=$(url_resolver "https://ejemplo.test/base/" "archivo.zip")
        [[ "$resultado" == "https://ejemplo.test/base/archivo.zip" ]]
        [[ "$(size_to_bytes 2M)" -eq 2097152 ]]
    ' _ "$ROOT"; then
        ok 'funciones básicas de wp-scrapper'
    else
        no_ok 'funciones básicas de wp-scrapper'
    fi
}

probar_shellcheck() {
    command -v shellcheck >/dev/null 2>&1 || {
        printf 'skip - shellcheck no está instalado\n'
        return
    }
    mapfile -d '' -t archivos < <(
        find "$ROOT" -path "$ROOT/.git" -prune -o \
            -path "$ROOT/.deprecated" -prune -o \
            -type f -name '*.sh' -print0
    )
    shellcheck --severity=error -x "${archivos[@]}" &&
        ok shellcheck || no_ok shellcheck
}

probar_sintaxis
probar_regresiones
probar_wp_scrapper
probar_shellcheck

((fallos == 0))
