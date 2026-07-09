#!/bin/bash

clear

# 🎨 Colores definidos por el usuario
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
WHITE="\e[97m"
NC="\e[0m"  # Reset

# Array de colores para alternar por columna
COLORS=("$RED" "$GREEN" "$CYAN" "$YELLOW" "$WHITE")

# Ayuda
function ayuda {
    echo -e "${WHITE}Uso:${NC}"
    echo "  $0                    # Modo interactivo"
    echo "  $0 archivo.csv        # Usa ',' como separador"
    echo "  $0 archivo.csv ';'    # Usa separador personalizado"
    exit 1
}

# Leer parámetros
if [ $# -eq 0 ]; then
    read -p "Ruta del archivo CSV: " archivo
    read -p "Separador (default ','): " sep
    sep="${sep:-,}"
elif [ $# -eq 1 ]; then
    archivo="$1"
    sep=","
elif [ $# -eq 2 ]; then
    archivo="$1"
    sep="$2"
else
    ayuda
fi

# Verificar archivo
if [ ! -f "$archivo" ]; then
    echo -e "${RED}❌ El archivo no existe: $archivo${NC}"
    exit 1
fi

# Leer encabezado y determinar columnas
IFS= read -r encabezado < "$archivo"
IFS="$sep" read -ra header_cols <<< "$encabezado"
num_cols=${#header_cols[@]}

# Mostrar encabezado coloreado
for i in "${!header_cols[@]}"; do
    color="${COLORS[$((i % ${#COLORS[@]}))]}"
    printf "%b%-20s%b" "$color" "${header_cols[i]}" "$NC"
done
echo

# Leer y mostrar el resto del archivo
tail -n +2 "$archivo" | while IFS="$sep" read -ra row; do
    for i in "${!row[@]}"; do
        color="${COLORS[$((i % ${#COLORS[@]}))]}"
        printf "%b%-20s%b" "$color" "${row[i]}" "$NC"
    done
    echo
done

