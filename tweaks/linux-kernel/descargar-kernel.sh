#!/usr/bin/env bash
clear
set -u

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/.kernels"
RELEASES_JSON="https://www.kernel.org/releases.json"

mkdir -p "$KERNEL_DIR"

die() {
    echo "Error: $*" >&2
    return 1
}

vdir() {
    local major="${1%%.*}"
    [[ "$major" =~ ^[0-9]+$ ]] && printf 'v%s.x' "$major"
}

descargar() {
    local version="$1"
    local dir base archive sign

    dir="$(vdir "$version")" || return 1
    base="https://cdn.kernel.org/pub/linux/kernel/$dir"
    archive="linux-$version.tar.xz"
    sign="linux-$version.tar.sign"

    echo
    echo "Kernel:  $version"
    echo "Destino: $KERNEL_DIR"
    echo

    curl -fsI "$base/$archive" >/dev/null ||
        return $(die "No existe $version en kernel.org"; echo $?)

    if [[ ! -f "$KERNEL_DIR/$archive" ]]; then
        curl -fL --progress-bar \
            "$base/$archive" \
            -o "$KERNEL_DIR/$archive.part" || {
                rm -f "$KERNEL_DIR/$archive.part"
                return 1
            }
        mv "$KERNEL_DIR/$archive.part" "$KERNEL_DIR/$archive"
    else
        echo "Ya existe: $archive"
    fi

    if curl -fsI "$base/$sign" >/dev/null; then
        [[ -f "$KERNEL_DIR/$sign" ]] ||
            curl -fL --progress-bar \
                "$base/$sign" \
                -o "$KERNEL_DIR/$sign"

        verificar "$KERNEL_DIR/$archive" "$KERNEL_DIR/$sign"
    else
        echo "Aviso: no se encontró firma PGP."
    fi

    echo
    echo "Guardado: $KERNEL_DIR/$archive"
}

verificar() {
    local archive="$1"
    local sign="$2"

    command -v gpg >/dev/null 2>&1 || {
        echo "Aviso: gpg no disponible; no se verifica la firma."
        return 0
    }

    command -v xz >/dev/null 2>&1 || {
        echo "Aviso: xz no disponible; no se verifica la firma."
        return 0
    }

    local tmp
    tmp="$(mktemp -d)"
    chmod 700 "$tmp"

    echo "Verificando firma PGP..."

    GNUPGHOME="$tmp" gpg --batch --quiet --locate-keys \
        torvalds@kernel.org \
        gregkh@kernel.org \
        sashal@kernel.org >/dev/null 2>&1 || true

    if xz -cd "$archive" |
        GNUPGHOME="$tmp" gpg \
            --batch \
            --trust-model always \
            --verify "$sign" -; then
        echo "Firma válida."
    else
        echo "AVISO: la firma no pudo validarse."
    fi

    rm -rf "$tmp"
}

stable() {
    local latest dir

    latest="$(
        curl -fsSL "$RELEASES_JSON" |
        python3 -c '
import json,sys
print(json.load(sys.stdin)["latest_stable"]["version"])
'
    )" || return 1

    dir="$(vdir "$latest")"

    curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/$dir/" |
        grep -oE 'linux-[0-9]+\.[0-9]+(\.[0-9]+)?\.tar\.xz' |
        sed -E 's/^linux-//;s/\.tar\.xz$//' |
        sort -Vu |
        tail -n 9 |
        sort -Vr
}

longterm() {
    curl -fsSL "$RELEASES_JSON" |
    python3 -c '
import json,sys

r = [
    x["version"]
    for x in json.load(sys.stdin)["releases"]
    if x.get("moniker") == "longterm" and not x.get("iseol")
]

r.sort(key=lambda v: tuple(map(int, v.split("."))), reverse=True)
print("\n".join(r[:9]))
'
}

elegir_lista() {
    local titulo="$1"
    shift
    local versiones=("$@")

    ((${#versiones[@]})) || {
        echo "No se encontraron versiones."
        return
    }

    echo
    echo "$titulo"
    echo

    local i
    for i in "${!versiones[@]}"; do
        printf "%d) %s\n" "$((i + 1))" "${versiones[$i]}"
    done

    echo "0) Volver"
    echo
    read -rp "Elegir: " opcion

    [[ "$opcion" == 0 ]] && return

    if [[ "$opcion" =~ ^[1-9]$ ]] &&
       ((opcion <= ${#versiones[@]})); then
        descargar "${versiones[$((opcion - 1))]}"
    else
        echo "Opción inválida."
    fi
}

while true; do
    echo
    echo "=== Descargar kernel ==="
    echo
    echo "[s] Stable"
    echo "[l] Longterm"
    echo "[v] Versión específica"
    echo "[0] Salir"
    echo
    read -rp "Opción: " opcion

    case "${opcion,,}" in
        s)
            mapfile -t lista < <(stable)
            elegir_lista "Últimos kernels stable:" "${lista[@]}"
            ;;
        l)
            mapfile -t lista < <(longterm)
            elegir_lista "Kernels longterm activos:" "${lista[@]}"
            ;;
        v)
            read -rp "Versión (ej. 7.1.7): " version
            if [[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                descargar "$version"
            else
                echo "Versión inválida."
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Opción inválida."
            ;;
    esac
done
