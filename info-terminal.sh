#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"
clear

    echo -e "🔰              "
    echo -e "${CYAN}_______________ 🖧 ${NC} 🚏 Información sobre la terminal: ${CYAN}🖧 ________________________\n"    
    echo -e "    🔹  ${YELLOW}Nombre de la terminal actual:${NC} $TERM"
    echo -e "    🔹  ${YELLOW}Tipos soportados de terminal:${NC} compgen -A terminal"
    
    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🐚 Información sobre el shell: ${CYAN}🖧 ___________________________\n"    
    echo -e "    🔹 ${YELLOW}Shell actual:${NC} $SHELL"
    echo -e "    🔹 ${YELLOW}Versión del shell:${NC} $BASH_VERSION"
    echo -e "    🔹 ${YELLOW}Lista de shells instalados:${GREEN}"
    cat /etc/shells

    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🎰 Variables de entorno útiles: ${CYAN}🖧 __________________________\n" 
    echo -e "    🔹 ${YELLOW}Usuario actual:${NC} $USER"
    echo -e "    🔹 ${YELLOW}Carpeta HOME:${NC} $HOME"
    echo -e "    🔹 ${YELLOW}Idioma del sistema:${NC} $LANG"
    echo -e "    🔹 ${YELLOW}PATH:\n${NC} $PATH"

    
    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🌌 Información sobre paths: ${CYAN}🖧 ______________________________\n" 
    echo -e "    🔹 ${YELLOW}Directorio actual:${NC} $(pwd)"
    echo -e "    🔹 ${YELLOW}Espacio en disco disponible:${NC} df -h"
    
    echo -e "\n${CYAN}_______________ 🖧 ${NC} :octocat: Otras opciones útiles para la terminal: ${CYAN}🖧 _______________\n" 
    echo -e "    🔹 ${RED}Para ver todas las variables de entorno:${NC}env"
    echo -e "    🔹 ${RED}Historial de comandos:${NC} history"
    echo -e "    🔹 ${RED}Ver vprocesos activos:${NC} ps aux"
    echo -e "    🔹 ${RED}Uso de memoria:${NC} free -h"
    echo -e "    🔹 ${RED}Información del sistema:${NC} uname -a"
    echo -e "    🔹 ${RED}Reiniciar la terminal:${NC} reset"


