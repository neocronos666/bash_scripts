#!/bin/bash

cabecera(){

#linea
ANCHO_ETIQUETA=15
ANCHO_VALOR=20

# echo -e "${YELLOW} 🏠 Host..... ${CYAN}$(hostname)"
# echo -e "${YELLOW} 👤 Usuario.. ${CYAN}$USER"
# echo -e "${YELLOW} ❄️  Kernel... ${CYAN}$(uname -r)"
# echo -e "${YELLOW} 🔢 IP....... ${CYAN}$(hostname -I | awk '{print $1}')"

# --- TABLA DE ADMINISTRACIÓN DE SISTEMAS (3 Filas x 6 Columnas) ---

# Comando rápido para obtener uso de CPU en %
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-32]*\%\) id.*/\1/" | awk '{print 100 - $1"%"}')

# Comando rápido para obtener RAM disponible de forma limpia
RAM_FREE=$(free -h | awk '/^Mem:/ {print $4 "/" $2}')

# Comando rápido para obtener el espacio usado en el disco raíz
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5 " de " $2}')

# Comando rápido para extraer la IP pública (Liviano, timeout de 2 segundos)
IP_PUB=$(curl -s --max-time 2 ifconfig.me || echo "Offline")

# Comando rápido para ver si UFW (Firewall) está activo de forma simple
STATUS_UFW=$(sudo ufw status 2>/dev/null | awk 'NR==1 {print $2}' || echo "N/A")

# 1. Dibujamos el techo de la tabla completa (6 columnas)
fila_dinamica "techo6"

# 2. FILA 1: Identidad del Sistema
fila_dinamica "fila" \
    "$YELLOW" "🏠" "Host"     "$CYAN" "" "$(hostname)" \
    "$YELLOW" "👤" "Usuario"  "$CYAN" "" "$USER" \
    "$YELLOW" "❄️ " "Kernel"   "$CYAN" "" "$(uname -r)"

# 3. FILA 2: Red y Seguridad
fila_dinamica "fila" \
    "$YELLOW" "🔢" "IP Local"  "$CYAN" "" "$(hostname -I | awk '{print $1}')" \
    "$YELLOW" "🌐 " "IP Pública" "$CYAN" "" "$IP_PUB" \
    "$YELLOW" "🛡️ " "Firewall"  "$CYAN" "" "$STATUS_UFW"

# 4. FILA 3: Estado del Hardware / Recursos
fila_dinamica "fila" \
    "$YELLOW" "⚡" "Uso CPU"   "$CYAN" "" "$CPU_USAGE" \
    "$YELLOW" "🧠" "Memoria"   "$CYAN" "" "$RAM_FREE" \
    "$YELLOW" "💾" "Disco /"   "$CYAN" "" "$DISK_USAGE"

# 5. Dibujamos el piso final de la tabla (6 columnas)
fila_dinamica "piso6"



if [[ -n "$SSH_CONNECTION" ]]
then
    echo -e "${RED}Conexion:  🏢SSH${YELLOW}"
else
    echo -e "${GREEN}Conexion:  🏡Local${YELLOW}"
fi

#linea

}
