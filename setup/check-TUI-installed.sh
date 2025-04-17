#!/bin/bash
clear

# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# Función para verificar si un comando existe
check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}[INSTALADO]${NC} $1"
    else
        echo -e "${RED}[NO INSTALADO]${NC} $1"
    fi
}

# Encabezado
echo -e "${CYAN}=============================================="
echo -e " VERIFICACIÓN DE HERRAMIENTAS TUI/CLI "
echo -e "==============================================${NC}\n"

# Disk Managers
echo -e "${YELLOW}🖴 DISK MANAGERS${NC}"
check_tool "ncdu"
check_tool "dua-cli"
check_tool "gdu"
check_tool "godu"
check_tool "duc"
check_tool "cfdisk"
check_tool "pdu"
echo ""

# System Monitors
echo -e "${YELLOW}📊 SYSTEM MONITORS${NC}"
check_tool "htop"
check_tool "gotop"
check_tool "btop"
check_tool "glances"
check_tool "nmon"
check_tool "nvtop"
check_tool "ytop"
check_tool "bpytop"
echo ""

# Web Browsers
echo -e "${YELLOW}🌐 WEB BROWSERS${NC}"
check_tool "lynx"
check_tool "w3m"
check_tool "browsh"
check_tool "links"
echo ""

# Network Tools
echo -e "${YELLOW}📶 NETWORK TOOLS${NC}"
check_tool "nmtui"
check_tool "iftop"
check_tool "nethogs"
check_tool "gping"
check_tool "termshark"
check_tool "goaccess"
echo ""

# Multimedia
echo -e "${YELLOW}🎵 MULTIMEDIA${NC}"
check_tool "cmus"
check_tool "cava"
check_tool "ncspot"
check_tool "mpv"
check_tool "chafa"
echo ""

# Git Clients
echo -e "${YELLOW}💾 GIT CLIENTS${NC}"
check_tool "lazygit"
check_tool "tig"
check_tool "gitui"
check_tool "onefetch"
echo ""

# File Managers
echo -e "${YELLOW}📁 FILE MANAGERS${NC}"
check_tool "ranger"
check_tool "vifm"
check_tool "nnn"
check_tool "lf"
check_tool "mc"
echo ""

# Messaging
echo -e "${YELLOW}💬 MESSAGING${NC}"
check_tool "mutt"
check_tool "neomutt"
check_tool "irssi"
check_tool "weechat"
echo ""

# Resumen
echo -e "${CYAN}=============================================="
echo -e " VERIFICACIÓN COMPLETADA "
echo -e "==============================================${NC}"
echo -e "Usa ${YELLOW}sudo apt install [tool]${NC} o el gestor"
echo -e "de paquetes de tu distro para instalar lo faltante."
echo -e "${CYAN}=============================================="
