#!/bin/bash

# Definir colores
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

# Archivo a mostrar
README_FILE="/home/neocronos/Documentos/bash_scripts/README.md"

#README_FILE="${BASE_DIR}/README.md"
#BASE_DIR=$(grep '^BASE_DIR=' ayuda | cut -d'=' -f2)
#README_FILE="${BASE_DIR}/README.md"

# BASE_DIR=$(grep '^BASE_DIR=' ayuda | sed 's/^BASE_DIR=//' | sed 's/"//g')

#BASE_DIR=$(awk -F= '/^BASE_DIR=/ {print $2}' ayuda)
#FULL_PATH="${BASE_DIR}/README.md"


# Verificar si el archivo existe
if [[ ! -f "$README_FILE" ]]; then
    echo -e "${RED}Error: No se encontró el archivo $README_FILE${RESET}"
    exit 1
fi
clear
# Leer y colorear el archivo línea por línea
while IFS= read -r line; do
    if [[ "$line" =~ ^#\ (.*) ]]; then
        echo -e "${RED}${BASH_REMATCH[1]}${RESET}"  # Título principal
    elif [[ "$line" =~ ^##\ (.*) ]]; then
        echo -e "${GREEN}${BASH_REMATCH[1]}${RESET}"  # Subtítulo
    elif [[ "$line" =~ ^###\ (.*) ]]; then
        echo -e "${YELLOW}${BASH_REMATCH[1]}${RESET}"  # Subsubtítulo
    elif [[ "$line" =~ ^-\ (.*) ]]; then
        echo -e "${CYAN}● ${BASH_REMATCH[1]}${RESET}"  # Viñetas con círculo
    elif [[ "$line" =~ ^[0-9]+\.\ (.*) ]]; then
        num=$(echo "$line" | grep -o '^[0-9]\+')  # Extraer el número
        rest=$(echo "$line" | sed 's/^[0-9]\+\. //')  # Extraer el texto restante
        echo -e "${BLUE}🔵 $num ${rest}${RESET}"  # Enumeraciones con números redondeados
    elif [[ "$line" =~ ^\`\`\` ]]; then
        echo -e "${MAGENTA}${line}${RESET}"  # Código
    else
        echo "$line"
    fi
done < "$README_FILE"



