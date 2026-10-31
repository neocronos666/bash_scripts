#!/bin/bash
clear

# ─────────────── COLORES ────────────────
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# ─────────────── FUNCIONES DE MENÚ ────────────────

mostrar_menu() {
    clear
    echo -e "${CYAN}"
    echo -e "    ╭──────────────────────────────────────────────────────╮"
    echo -e "    │       🧠 ${NC}AUTOAUDITORÍA DE RED Y DOCKER${CYAN}               │"  
    echo -e "    ╰──╥───────────────────────────────────────────────────╯"
    echo -e "       ║ ${GREEN}Usuario:${NC} $USER ${CYAN}"
    echo -e "       ╙──────────────────────────────────────────────────╾${NC}"   
    echo ""
    echo -e "     ${YELLOW}[1]${NC} Información de Red"
    echo -e "     ${YELLOW}[2]${NC} Puertos abiertos y servicios"
    echo -e "     ${YELLOW}[3]${NC} Contenedores Docker"
    echo -e "     ${YELLOW}[4]${NC} Seguridad básica del sistema"
    echo -e "     ${YELLOW}[0]${NC} Salir"
    echo ""
}

info_red() {
    clear
    echo -e "${CYAN}📡 Información de Red:${NC}"
    ip addr show
    echo ""
    echo -e "${YELLOW}🌐 IP Pública:${NC}"
    curl -s ifconfig.me
    echo ""
    echo -e "${YELLOW}🧪 Ping a Google DNS:${NC}"
    ping -c 3 8.8.8.8
    read -p "⏳ Presiona Enter para volver al menú..."
}

puertos_abiertos() {
    clear
    echo -e "${CYAN}🔓 Puertos abiertos y servicios:${NC}"
    ss -tuln
    echo ""
    echo -e "${YELLOW}📌 Procesos escuchando:${NC}"
    lsof -i -P -n | grep LISTEN
    read -p "⏳ Presiona Enter para volver al menú..."
}

info_docker() {
    clear
    echo -e "${CYAN}🐳 Información de Docker:${NC}"
    docker ps -a
    echo ""
    echo -e "${YELLOW}📦 Redes Docker:${NC}"
    docker network ls
    echo ""
    echo -e "${YELLOW}🧰 Volúmenes Docker:${NC}"
    docker volume ls
    read -p "⏳ Presiona Enter para volver al menú..."
}

seguridad_basica() {
    clear
    echo -e "${CYAN}🛡️ Verificación de seguridad básica:${NC}"
    echo -e "${YELLOW}🧑 Usuarios con sudo:${NC}"
    getent group sudo
    echo ""
    echo -e "${YELLOW}🛠️ Servicios activos:${NC}"
    systemctl list-units --type=service --state=running | head -n 20
    echo ""
    echo -e "${YELLOW}📁 Archivos .env encontrados:${NC}"
    find / -name ".env" 2>/dev/null | head -n 10    
    read -p "⏳ Presiona Enter para volver al menú..."
}

# ─────────────── LOOP PRINCIPAL ────────────────

while true; do
    mostrar_menu
    read -p "   ⭕ " opcion    
    case $opcion in
        1) info_red ;;
        2) puertos_abiertos ;;
        3) info_docker ;;
        4) seguridad_basica ;;
        0) exit 0 ;;
        *)clear ;;
    esac
done

