#!/usr/bin/env bash

set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
    echo "No se pudo detectar la distribución." >&2
    exit 1
fi
. /etc/os-release

case "${ID:-}" in
    ubuntu|debian) ;;
    *)
        echo "Este instalador solo soporta Debian y Ubuntu." >&2
        exit 1
        ;;
esac

CODENAME="${VERSION_CODENAME:-}"
[[ -n "$CODENAME" ]] || {
    echo "No se pudo detectar VERSION_CODENAME." >&2
    exit 1
}

echo "Se instalará Docker Engine desde el repositorio oficial para $ID $CODENAME."
read -r -p "Escriba INSTALAR para continuar: " RESP
[[ "$RESP" == "INSTALAR" ]] || exit 0

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

ARQUITECTURA="$(dpkg --print-architecture)"
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/%s %s stable\n' \
    "$ARQUITECTURA" "$ID" "$CODENAME" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

echo
echo "Docker se instaló. El grupo docker otorga privilegios equivalentes a root."
read -r -p "¿Agregar ${USER:-el usuario actual} al grupo docker? [s/N]: " RESP
if [[ "$RESP" =~ ^[sS]$ ]]; then
    sudo groupadd -f docker
    sudo usermod -aG docker "${USER:?No se pudo determinar el usuario}"
    echo "Cierre y vuelva a iniciar sesión para aplicar el grupo."
fi

sudo docker run --rm hello-world
docker --version
docker compose version
