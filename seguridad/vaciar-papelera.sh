#!/usr/bin/env bash
#
# vaciar_papelera.sh
# Vacía la papelera de reciclaje en Linux Mint (Cinnamon/XFCE/MATE),
# pidiendo confirmación y usando sudo automáticamente si hace falta
# (útil cuando Thunar/Nemo/Caja se niega a borrar por permisos).
#
# Uso: ./vaciar_papelera.sh

set -u

# Colores para los mensajes
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
NC='\033[0m'

echo -e "${AMARILLO}Buscando ubicaciones de la papelera...${NC}"

# 1) Papelera estándar del usuario (XDG Trash spec)
PAPELERAS=("$HOME/.local/share/Trash")

# 2) Papeleras en otros puntos de montaje (discos externos, otras particiones)
#    El estándar XDG crea .Trash-<UID> en la raíz de cada punto de montaje.
UID_ACTUAL="$(id -u)"
for punto in /media/"$USER"/* /run/media/"$USER"/* /mnt/*; do
    [ -d "$punto/.Trash-$UID_ACTUAL" ] && PAPELERAS+=("$punto/.Trash-$UID_ACTUAL")
done

# Filtrar solo las que existen y no están vacías
EXISTENTES=()
for p in "${PAPELERAS[@]}"; do
    if [ -d "$p" ]; then
        EXISTENTES+=("$p")
    fi
done

if [ "${#EXISTENTES[@]}" -eq 0 ]; then
    echo -e "${VERDE}No se encontraron papeleras (o ya están vacías).${NC}"
    exit 0
fi

echo "Se vaciarán las siguientes ubicaciones:"
for p in "${EXISTENTES[@]}"; do
    tam=$(du -sh "$p" 2>/dev/null | cut -f1)
    echo "  - $p (${tam:-desconocido})"
done

read -rp "¿Confirmás que querés eliminar TODO el contenido de forma permanente? [s/N]: " respuesta
case "$respuesta" in
    [sS]|[sS][iI]) ;;
    *) echo "Cancelado."; exit 0 ;;
esac

# Función para vaciar una carpeta de papelera, con reintento vía sudo
vaciar() {
    local dir="$1"
    local files="$dir/files"
    local info="$dir/info"

    # Intento normal (sin privilegios)
    if rm -rf "${files:?}"/* "${files:?}"/.[!.]* 2>/dev/null \
       && rm -rf "${info:?}"/* "${info:?}"/.[!.]* 2>/dev/null; then
        # Puede que no haya errores aunque queden restos con otro dueño;
        # verificamos si aún queda algo.
        if [ -z "$(ls -A "$files" 2>/dev/null)" ] && [ -z "$(ls -A "$info" 2>/dev/null)" ]; then
            echo -e "${VERDE}✔ Vaciado sin privilegios: $dir${NC}"
            return 0
        fi
    fi

    echo -e "${AMARILLO}No se pudo vaciar completamente sin privilegios: $dir${NC}"
    echo "Reintentando con sudo (te va a pedir tu contraseña)..."
    if sudo rm -rf "${files:?}"/* "${files:?}"/.[!.]* "${info:?}"/* "${info:?}"/.[!.]* 2>/dev/null; then
        echo -e "${VERDE}✔ Vaciado con sudo: $dir${NC}"
    else
        echo -e "${ROJO}✘ No se pudo vaciar: $dir${NC}"
        return 1
    fi
}

FALLOS=0
for p in "${EXISTENTES[@]}"; do
    mkdir -p "$p/files" "$p/info" 2>/dev/null
    vaciar "$p" || FALLOS=1
done

if [ "$FALLOS" -eq 0 ]; then
    echo -e "${VERDE}Papelera vaciada correctamente.${NC}"
else
    echo -e "${ROJO}Algunas ubicaciones no se pudieron vaciar del todo. Revisá los mensajes de arriba.${NC}"
fi
