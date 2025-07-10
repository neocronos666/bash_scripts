#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
PURPLE="\e[35m"
BLUE="\e[34m"
NC="\e[0m"
clear


#-----------------FUNCIONES--------------------------------
# Función para obtener información de RAM con sudo
get_ram_info() {
    # Verificar si ya tenemos permisos sudo
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${YELLOW}🔐 Se requieren privilegios sudo para leer información detallada de RAM${NC}"
        if sudo -n true 2>/dev/null; then
            echo -e "${GREEN}✔ Sudo disponible${NC}"
        else
            sudo echo -e "${GREEN}✔ Permisos obtenidos${NC}" >/dev/null
        fi
    fi

    # Obtener información completa de RAM
    local ram_info=$(sudo dmidecode -t memory 2>/dev/null)
    
    # Si falla dmidecode
    if [ -z "$ram_info" ]; then
        echo -e "${RED}❌ No se pudo obtener información de la RAM${NC}"
        echo -e "  ${YELLOW}Posibles soluciones:${NC}"
        echo -e "  1. Ejecutar el script como root"
        echo -e "  2. Instalar dmidecode: ${GREEN}sudo apt install dmidecode${NC}"
        return 1
    fi

    echo "$ram_info"
}

# Mostrar información de RAM mejorada
show_ram_info() {
    echo -e "\n${CYAN}_______________ 🏴 Información Detallada de RAM _____________${NC}"
    
    local ram_info=$(get_ram_info)
    local current_slot=""
    local slot_count=0

    # Procesar cada bloque de memoria
    echo "$ram_info" | awk 'BEGIN { RS = "Memory Device"; FS = "\n" } NR > 1 { print $0 }' | while read -r block; do
        # Extraer información clave
        slot=$(echo "$block" | grep -m1 "Locator:" | cut -d: -f2 | xargs)
        size=$(echo "$block" | grep -m1 "Size:" | cut -d: -f2 | xargs)
        type=$(echo "$block" | grep -m1 "Type:" | cut -d: -f2 | xargs)
        speed=$(echo "$block" | grep -m1 "Speed:" | cut -d: -f2 | xargs)
        manufacturer=$(echo "$block" | grep -m1 "Manufacturer:" | cut -d: -f2 | xargs)
        part_number=$(echo "$block" | grep -m1 "Part Number:" | cut -d: -f2 | xargs)
        voltage=$(echo "$block" | grep -m1 "Configured Voltage:" | cut -d: -f2 | xargs)
        
        # Extraer información de timings
        timings=$(echo "$block" | grep -A1 "Configured Memory Timings" | tail -n1 | xargs)
        
        # Solo mostrar si es un módulo instalado
        if [ "$size" != "No Module Installed" ] && [ -n "$size" ]; then
            slot_count=$((slot_count+1))
            
            echo -e "\n${PURPLE}💾 Módulo RAM ${slot_count} [${YELLOW}${slot}${PURPLE}]${NC}"
            echo -e "  ${BLUE}┌───────────────────────────────────────${NC}"
            echo -e "  ${YELLOW}│ Tamaño:${NC}       ${size}"
            echo -e "  ${YELLOW}│ Tipo:${NC}         ${type}"
            echo -e "  ${YELLOW}│ Velocidad:${NC}    ${speed}"
            [ -n "$voltage" ] && echo -e "  ${YELLOW}│ Voltaje:${NC}      ${voltage}"
            [ -n "$timings" ] && echo -e "  ${YELLOW}│ Timings:${NC}      ${timings}"
            echo -e "  ${BLUE}├─────────────── Fabricante ─────────────${NC}"
            echo -e "  ${YELLOW}│ Marca:${NC}        ${manufacturer}"
            echo -e "  ${YELLOW}│ N° Parte:${NC}     ${part_number}"
            echo -e "  ${BLUE}└───────────────────────────────────────${NC}"
        fi
    done

    # Resumen general
    local total_ram=$(free -h | grep "Mem:" | awk '{print $2}')
    local used_ram=$(free -h | grep "Mem:" | awk '{print $3}')
    
    echo -e "\n${GREEN}🔍 Resumen General:${NC}"
    echo -e "  ${CYAN}Total RAM instalada:${NC} ${total_ram}"
    echo -e "  ${CYAN}RAM en uso:${NC}        ${used_ram}"
    echo -e "  ${CYAN}Módulos detectados:${NC} ${slot_count}"
}


#-----------------CODIGO-----------------------------------



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
#Driver
DRIVER=$(lspci -k | grep -EA3 'VGA|3D|Display')
echo -e "${YELLOW}Driver Info:${NC} $DRIVER\n"

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


show_ram_info


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

echo -e "${CYAN}_______________ 🌡️  Monitor de Hardware 🌡️ _______________${NC}"
echo -e "${BLUE}════════════════ Temperaturas y Ventiladores ════════════════${NC}\n"

if command -v sensors &>/dev/null; then
    # Obtener información de sensores
    sensors_output=$(sensors)
    
    # Mostrar información de chips/drivers primero
    echo -e "${PURPLE}🔍 Chips de sensores detectados:${NC}"
    echo "$sensors_output" | grep -E "^[^ ]" | grep -v ":" | \
    awk -v cyan=$CYAN -v nc=$NC '{printf " 🔹 %s%s%s\n", cyan, $0, nc}'
    
    # Procesar temperaturas
    echo -e "\n${YELLOW}🚨 Temperaturas por Componente:${NC}"
    echo "$sensors_output" | grep -E "Core|Package|CPU|GPU|temp[0-9]+" | \
    awk -v red=$RED -v green=$GREEN -v yellow=$YELLOW -v nc=$NC '{
        # Extraer componente y temperatura
        component = $1
        if ($0 ~ /[0-9]+°[CF]/) {
            temp = $0
            gsub(/[^0-9.]/, "", temp)
            temp = temp+0
            
            # Color según temperatura
            if (temp > 80) color = red
            else if (temp > 60) color = yellow
            else color = green
            
            # Mejorar nombres de componentes
            if (component ~ /Core/) component = "CPU " component
            else if (component ~ /Package/) component = "CPU " component
            else if (component ~ /temp/) {
                gsub(/temp/, "Sensor ", component)
                component = component " (" $1 ")"
            }
            
            # Formatear salida
            gsub(/([0-9]+°[CF])/, color "&" nc)
            printf " 🔸 %-15s: %s\n", component, $0
        }
    }'
    
    # Procesar ventiladores
    echo -e "\n${PURPLE}🌀 Ventiladores:${NC}"
    echo "$sensors_output" | grep -i "fan" | \
    awk -v cyan=$CYAN -v nc=$NC '{
        if ($3 ~ /RPM/) {
            printf " 🔹 %-15s: %s %s %s\n", $1, cyan $2, $3, nc
        } else {
            printf " 🔹 %-15s: %s\n", $1, cyan $2, nc
        }
    }'
    
    # Mensaje si no hay ventiladores
    fan_count=$(echo "$sensors_output" | grep -ci "fan")
    if [ "$fan_count" -eq 0 ]; then
        echo -e " ${RED}⚠️ No se detectaron ventiladores con sensores${NC}"
    fi
else
    echo -e "${RED}❌ Error: El comando 'sensors' no está instalado.${NC}"
    echo -e "Por favor instala lm-sensors: ${GREEN}sudo apt install lm-sensors${NC}"
fi

echo -e "\n${BLUE}══════════════════════════════════════════════════════════${NC}"
