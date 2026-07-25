#!/bin/bash

# ==========================================
# Yarara Cleanup - One Shot
# Autor: ChatGPT + Neocronos
# Uso específico para yarara
# ==========================================

set -e

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${CYAN}"
echo "=========================================="
echo "      YARARA CLEANUP - ONE SHOT"
echo "=========================================="
echo -e "${NC}"

echo "Esta operación eliminará Docker y todos sus datos, Bottles,"
echo "paquetes huérfanos, kernels antiguos y varias cachés de usuario."
if [[ "${1:-}" == "--dry-run" ]]; then
    echo
    echo "Modo simulación: no se realizó ningún cambio."
    exit 0
fi
read -r -p "Escriba ELIMINAR para continuar: " RESP
[[ "$RESP" == "ELIMINAR" ]] || exit 0

#############################################
echo -e "${YELLOW}🐳 Eliminando Docker...${NC}"

sudo systemctl stop docker.service 2>/dev/null || true
sudo systemctl stop containerd.service 2>/dev/null || true

docker system prune -a --volumes -f 2>/dev/null || true

sudo apt purge -y \
docker-ce \
docker-ce-cli \
docker-buildx-plugin \
docker-compose \
docker-compose-plugin \
docker.io \
docker-doc \
docker-engine \
containerd \
containerd.io \
runc \
podman-docker 2>/dev/null || true

sudo rm -rf \
/var/lib/docker \
/etc/docker \
/var/lib/containerd \
/var/run/docker.sock
rm -rf "${HOME}/.docker"

echo -e "${GREEN}✔ Docker eliminado${NC}"

#############################################
echo -e "${YELLOW}🍾 Eliminando Bottles...${NC}"

flatpak uninstall -y com.usebottles.bottles 2>/dev/null || true
flatpak uninstall --unused -y

echo -e "${GREEN}✔ Bottles eliminado${NC}"

#############################################
echo -e "${YELLOW}🐹 Eliminando entorno Go...${NC}"

# rm -rf ~/go

echo -e "${GREEN}✔ Go eliminado${NC}"

#############################################
echo -e "${YELLOW}🐍 Limpiando Anaconda...${NC}"

if command -v conda >/dev/null 2>&1; then
    conda clean --all -y
fi

echo -e "${GREEN}✔ Anaconda limpiada${NC}"

#############################################
echo -e "${YELLOW}🧹 Limpiando APT...${NC}"

sudo apt autoremove --purge -y
sudo apt autoclean
sudo apt clean

echo -e "${GREEN}✔ APT limpio${NC}"

#############################################
echo -e "${YELLOW}🗑 Limpiando caché del usuario...${NC}"

rm -rf ~/.cache/thumbnails/*
rm -rf ~/.cache/fontconfig/*
rm -rf ~/.cache/pip/*
rm -rf ~/.cache/mozilla/*
rm -rf ~/.cache/google-chrome/*
rm -rf ~/.cache/chromium/*

echo -e "${GREEN}✔ Cachés limpiadas${NC}"

#############################################
echo -e "${YELLOW}🧹 Eliminando kernels viejos...${NC}"

CURRENT=$(uname -r)

echo "Kernel actual: $CURRENT"

mapfile -t KERNELS < <(
dpkg --list |
awk '/linux-image-[0-9]/{print $2}' |
grep -v "$CURRENT"
)

if [ ${#KERNELS[@]} -gt 0 ]; then
    sudo apt purge -y "${KERNELS[@]}"
fi

sudo apt autoremove --purge -y

echo -e "${GREEN}✔ Kernels antiguos eliminados${NC}"

#############################################
echo -e "${YELLOW}📦 Eliminando paquetes huérfanos...${NC}"

sudo apt autoremove --purge -y

#############################################
echo -e "${GREEN}"
echo "=========================================="
echo "      LIMPIEZA FINALIZADA"
echo "=========================================="
echo -e "${NC}"

df -h /

echo
echo -e "${CYAN}Conviene reiniciar la PC.${NC}"
