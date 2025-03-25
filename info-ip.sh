#!/bin/bash

# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

clear
    echo -e "🔰              "
    echo -e "${CYAN}_______________ 🖧 ${NC} Información de Red en Linux ${CYAN}___________\n"

# IP Privada
    IP_PRIVADA=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}👤 IP Privada:${NC} $IP_PRIVADA"

# IP Pública
    IP_PUBLICA=$(curl -s ifconfig.me)
    echo -e "${GREEN}🌍 IP Pública:${NC} $IP_PUBLICA"

# Puerta de Enlace (Router)
    GATEWAY=$(ip route show default | awk '{print $3}' | head -n1)
    echo -e "${GREEN}🚪 Puerta de enlace predeterminada:${NC} $GATEWAY"

# Interfaces de Red Activas
    echo -e "\n${CYAN}📡 Interfaces de Red Activas:${NC}"
    nmcli device status | awk 'NR==1 || /connected/ {print}'

# Conexiones Activas
    echo -e "\n${CYAN}🔆 Conexiones Activas:${NC}"
    nmcli connection show --active

# Redes WiFi Disponibles
    echo -e "\n${CYAN}🗼 Redes WiFi Cercanas:${NC}"
    nmcli dev wifi list | awk 'NR==1 || NR<=10 {print}'

#echo -e "\n${YELLOW}✅ Resumen completo generado.${NC}\n"
    echo -e "${CYAN}____________________________________________________________${YELLOW}\n"
   
