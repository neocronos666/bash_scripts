#!/bin/bash

# Colores para salida
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# Preguntar por el archivo si no se pasa como argumento
if [ -z "$1" ]; then
    echo -e "${CYAN}📂 Ingresá la ruta al archivo de firmware a analizar:${NC}"
    read -r FIRMWARE
else
    FIRMWARE="$1"
fi

# Validar existencia
if [ ! -f "$FIRMWARE" ]; then
    echo -e "${RED}❌ El archivo \"$FIRMWARE\" no existe.${NC}"
    exit 1
fi

echo -e "${CYAN}📦 Analizando firmware: $FIRMWARE${NC}"

# Modo 1: Análisis básico
echo -e "${YELLOW}🔍 Análisis básico...${NC}"
binwalk "$FIRMWARE"

# Modo 2: Extracción simple
echo -e "${YELLOW}📂 Extracción de archivos (modo -e)...${NC}"
binwalk -e "$FIRMWARE"

# Modo 3: Extracción profunda y recursiva
echo -e "${YELLOW}🔁 Extracción profunda (modo -Me)...${NC}"
binwalk -Me "$FIRMWARE"

# Modo 4: Strings legibles
echo -e "${YELLOW}🔡 Buscando cadenas ASCII...${NC}"
strings "$FIRMWARE" > "${FIRMWARE}_strings.txt"
echo -e "→ Guardado en ${FIRMWARE}_strings.txt"

# Modo 5: Firma específica squashfs
echo -e "${YELLOW}🔎 Buscando firmas squashfs...${NC}"
binwalk -R 'hsqs' "$FIRMWARE"

# Modo 6: Guardar log general
echo -e "${YELLOW}📝 Guardando log completo...${NC}"
binwalk "$FIRMWARE" > "${FIRMWARE}_binwalk.log"
echo -e "→ Log en ${FIRMWARE}_binwalk.log"

echo -e "${GREEN}✅ Análisis completado.${NC}"

