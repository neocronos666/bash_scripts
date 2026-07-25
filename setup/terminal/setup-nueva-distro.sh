#!/usr/bin/env bash

set -euo pipefail

[[ -r /etc/os-release ]] || {
    echo "No se pudo detectar la distribución." >&2
    exit 1
}
. /etc/os-release
case "${ID:-}" in
    ubuntu|debian|linuxmint) ;;
    *)
        echo "Este instalador solo soporta sistemas basados en Debian." >&2
        exit 1
        ;;
esac

PAQUETES=(
    build-essential
    bzip2
    cpio
    ffmpeg
    git
    gzip
    libffi-dev
    libssl-dev
    p7zip-full
    python3
    python3-dev
    python3-pip
    python3-venv
    tar
    unzip
    yt-dlp
)

printf 'Se instalarán %d paquetes mediante APT.\n' "${#PAQUETES[@]}"
printf '  %s\n' "${PAQUETES[@]}"
echo "Anaconda y VS Code no se descargan automáticamente: requieren elegir versión"
echo "y verificar el artefacto desde sus sitios oficiales."
read -r -p "Escriba INSTALAR para continuar: " RESP
[[ "$RESP" == "INSTALAR" ]] || exit 0

sudo apt-get update
sudo apt-get install -y "${PAQUETES[@]}"

VENV="${BASH_SCRIPTS_VENV:-$HOME/.local/share/bash-scripts/venv}"
python3 -m venv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install \
    browser-cookie3 matplotlib numpy pandas scikit-learn scipy seaborn

printf 'Entorno Python creado en %s\n' "$VENV"
