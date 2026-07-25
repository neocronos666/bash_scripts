#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"
clear

ejecutar_comando() {
    local paquete="$1"
    sudo apt purge -- "$paquete"
    sudo apt autoremove
    sudo apt clean
}

    clear
    echo -e "🔰              "
    echo -e "${CYAN}    ╭───────────────────────────────────────────────────────╮"
    echo -e "${CYAN}    │        🖳 ${NC} Desinstalar y Limpiar     ${CYAN}                  │"  
    echo -e "${CYAN}    ╰──╥────────────────────────────────────────────────────╯"
    echo -e "${CYAN}       ║          ${YELLOW}[0] ${RED}⮿${NC} Volver"
    echo -e "${CYAN}       ╙───────────────────────────────────────────────╾\n\n${GREEN}"        
#    echo -e "${GREEN}          ⛶ Cual es el paquete a desinstalar?" 
    read -r -p "⛶ Qué paquete desinstalar?  " opcion
if [[ "$opcion" == "0" ]]; then    
    exit 0
else
    printf 'Se desinstalará el paquete: %s\n' "$opcion"
    read -r -p "Escriba ELIMINAR para confirmar: " confirmar
    [[ "$confirmar" == "ELIMINAR" ]] || exit 0
    ejecutar_comando "$opcion"
fi    
