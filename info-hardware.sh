#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"
clear



# Información del CPU
 echo " 🔰             "
echo -e "${CYAN}_______________ 🔥 ${NC} Información del CPU ${CYAN}_____________\n"
#CORRER lscpu PARA SABER LOS NOMBRES DE LAS VARIABLES
CPU_INFO=$(lscpu) #
echo -e "${YELLOW}  🔹Arquitectura:${NC} $(echo "$CPU_INFO" | grep 'modo(s) de operación de las CPUs' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Marca:${NC} $(echo "$CPU_INFO" | grep 'ID de fabricante' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Modelo:${NC} $(echo "$CPU_INFO" | grep 'Nombre del modelo' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Núcleos:${NC} $(echo "$CPU_INFO" | grep 'Núcleo(s) por «socket»' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Hilos por Núcleo:${NC} $(echo "$CPU_INFO" | grep 'Hilo(s) de procesamiento por núcleo' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Frecuencia:${NC} $(echo "$CPU_INFO" | grep 'CPU MHz máx.:' | awk -F: '{print $2}' | sed 's/^ *//') MHz"
echo -e "${YELLOW}  🔹Caché L1:${NC} $(echo "$CPU_INFO" | grep 'L1d' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Caché L2:${NC} $(echo "$CPU_INFO" | grep 'L2' | awk -F: '{print $2}' | sed 's/^ *//')"
echo -e "${YELLOW}  🔹Virtualizacion:${NC} $(echo "$CPU_INFO" | grep 'Virtualización:' | awk -F: '{print $2}' | sed 's/^ *//')"


# Información de la GPU
echo -e "${CYAN}_______________ 🎮 ${NC} Información de la GPU ${CYAN}_____________\n"
#if lspci | grep -i 'vga\|3d\|display' &>/dev/null; then
#    GPU_INFO=$(lspci | grep -i 'vga\|3d\|display')
#    echo -e "${YELLOW}Modelo:${NC} $GPU_INFO"
#else
#    echo -e "${RED}No se detectó una GPU dedicada.${NC}"
#fi
# Modelo del chip
CHIP=$(lspci | grep -i 'vga\|3d\|display' | awk -F: '{print $2}')
echo -e "${YELLOW}Modelo del chip:${NC} $CHIP"

# Detalles con lshw
#VRAM=$(sudo lshw -C display | grep -i 'producto' | awk '{print $2}')
#echo -e "${YELLOW}VRAM:${NC} $VRAM"

# OpenGL Renderer
RENDERER=$(glxinfo | grep -i 'OpenGL renderer' | awk -F: '{print $2}')
echo -e "${YELLOW}Renderer:${NC} $RENDERER"

# Tipo de GPU
if [[ $CHIP =~ "Integrated" ]]; then
    echo -e "${YELLOW}Tipo:${NC} APU (Integrada)"
else
    echo -e "${YELLOW}Tipo:${NC} Dedicada"
fi

# Información de la RAM
echo -e "${CYAN}_______________ 🏴 ${NC} Información de la Memoria RAM ${CYAN}_____________\n"
sudo dmidecode -t memory | grep -E 'Size|Speed|Manufacturer|Serial Number|Configured Clock Speed' | sed 's/^\t//' | while read -r line; do
    sudo echo -e "  🔹 ${YELLOW}$(echo "$line" | cut -d: -f1):${NC} $(echo "$line" | cut -d: -f2)"    
done

sudo dmidecode -t memory | awk '/Memory Device/,/Locator/' | while read -r line; do
    # Procesar bloques de información
    if echo "$line" | grep -E 'Size|Speed|Manufacturer|Serial Number|Configured Clock Speed|Locator|Data Width|Total Width|Type' &>/dev/null; then #ACAAAAAAAAAAAAAAAAAA
        # Formatear las líneas clave
        key=$(echo "$line" | cut -d: -f1 | sed 's/^[ \t]*//')
        value=$(echo "$line" | cut -d: -f2 | sed 's/^[ \t]*//')

        # Mostrar en colores
        echo -e " 🔹 ${YELLOW}$key:${NC} $value"
    fi
done




echo -e "${RED} ╓───────────────────────────╖"
echo -e " ║ ${YELLOW}Uso Actual:${NC} $(free -h | grep Mem | awk '{print $3" / "$2}')  ${RED}║"
echo -e " ╙───────────────────────────╜"

# Información de discos
echo -e "${CYAN}_______________ 💾 ${NC} Información de Almacenamiento ${CYAN}_____________\n"
dsks=$(lsblk -d -o NAME,MODEL,SIZE,ROTA)
IFS=$'\n'
echo -e "${YELLOW}◉ Discos detectados:${NC}"
for dsk in $dsks; do
    echo -e "${GREEN}$dsk"
done

echo -e "${YELLOW}◔ Uso de particiones:${NC}"
#df -h | awk '{print $1" "$2" "$3" "$4" "$5" "$6}'
if command -v lsblk &>/dev/null; then
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | column -t
else
    echo -e "${RED}   🔹 No se pudo obtener información de los discos."
fi

# Información de sensores
echo -e "${CYAN}_______________ 🌡️ ${NC} Temperaturas y Ventiladores ${CYAN}_____________\n"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP_CPU=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo -e "${YELLOW}Temperatura CPU:${NC} $(($TEMP_CPU/1000))°C"
else
    echo -e "${RED}No se pudo obtener la temperatura del CPU.${NC}"
fi

if [ -d /sys/class/hwmon ]; then
    echo -e "${YELLOW}Velocidades de ventiladores:${NC}"
    for fan in /sys/class/hwmon/hwmon*/fan*_input; do
        echo -e "   - $(cat $fan) RPM"
    done
else
    echo -e "${RED}No se detectaron ventiladores monitoreables.${NC}"
fi


echo -e "${CYAN}_______________ 🖥️ Información del CPU 🖥️ _______________
${NC}"
if command -v lscpu &>/dev/null; then
    CPU_INFO=$(lscpu | grep -E "Model name|Socket|Thread|MHz|L3")
    echo -e "$CPU_INFO" | awk -F: '{printf "   🔹 %s: %s\n", $1, $2}'
else
    echo -e "   🔹 Información de CPU no disponible."
fi

echo -e "${CYAN}_______________ 🎮 Información de GPU 🎮 _______________
${NC}"
if command -v lspci &>/dev/null; then
    GPU_INFO=$(lspci | grep -i "vga")
    if [ -z "$GPU_INFO" ]; then
        echo -e "   🔹 No se detectó GPU dedicada."
    else
        echo -e "   🔹 GPU detectada: $GPU_INFO"
    fi
else
    echo -e "   🔹 No se pudo obtener información de GPU."
fi

echo -e "${CYAN}_______________ 💾 Información de RAM 💾 _______________
${NC}"
if command -v dmidecode &>/dev/null && [ $(id -u) -eq 0 ]; then
    sudo dmidecode -t memory | grep -E "Size|Speed|Manufacturer|Part Number" | awk -F: '{printf "   🔹 %s: %s\n", $1, $2}'
else
    echo -e "   🔹 Ejecutar como root para ver detalles de la RAM."
fi

echo -e "${CYAN}_______________ 💽 Información de Discos 💽 _______________
${NC}"


echo -e "${CYAN}_______________ 🌡️ Temperatura y Ventiladores 🌡️ _______________
${NC}"
if command -v sensors &>/dev/null; then
    sensors | grep -E "Core|fan" | awk '{printf "   🔹 %s %s %s\n", $1, $2, $3}'
else
    echo -e "   🔹 No se pudo obtener información de temperatura y ventiladores."
fi

