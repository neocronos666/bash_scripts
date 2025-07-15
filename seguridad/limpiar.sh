#!/bin/bash

# Colores
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

echo -e "${CYAN}🔧 Iniciando limpieza de sistema Linux Mint...${NC}"

# Mostrar espacio antes
echo -e "${YELLOW}📦 Espacio libre antes:${NC}"
df -h /

# Actualizar listas de paquetes
echo -e "${CYAN}🔄 Actualizando listas de paquetes...${NC}"
sudo apt update

# Eliminar paquetes innecesarios
echo -e "${CYAN}🧼 Limpiando paquetes huérfanos y no utilizados...${NC}"
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

# Limpiar cachés de usuario (Navegadores, thumbnails, etc.)
echo -e "${CYAN}🗑️ Limpiando cachés del usuario...${NC}"
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.cache/mozilla/*
rm -rf ~/.cache/google-chrome/*
rm -rf ~/.cache/vivaldi/*
rm -rf ~/.cache/mintupdate/*
rm -rf ~/.cache/mesa_shader_cache/*

# Vaciar papelera
echo -e "${CYAN}🗃️ Vaciando papelera...${NC}"
rm -rf ~/.local/share/Trash/files/*
rm -rf ~/.local/share/Trash/info/*

# Limpiar logs antiguos
echo -e "${CYAN}📜 Limpiando logs antiguos...${NC}"
sudo journalctl --vacuum-time=7d

# Mostrar espacio después
echo -e "${YELLOW}📦 Espacio libre después:${NC}"
df -h /

echo -e "${GREEN}✅ Limpieza finalizada.${NC}"

