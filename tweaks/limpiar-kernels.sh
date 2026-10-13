#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Limpieza de kernels antiguos de Yarara
#
# CONSERVAR:
#   6.8.0-138
#   7.0.0-29   <- kernel activo al crear este script
#   7.0.0-30
#
# Elimina image/modules/modules-extra/headers de versiones viejas.
# ============================================================

KEEP=(
    "6.8.0-138"
    "7.0.0-29"
    "7.0.0-30"
)

REMOVE=(
    "6.8.0-38"
    "6.8.0-52"
    "6.8.0-54"
    "6.8.0-55"
    "6.8.0-56"
    "6.8.0-57"
    "6.8.0-58"
    "6.8.0-59"
    "6.8.0-60"
    "6.8.0-62"
    "6.8.0-63"
    "6.8.0-64"
    "6.8.0-71"
    "6.8.0-78"
    "6.8.0-79"
    "6.8.0-85"
    "6.8.0-87"
    "6.8.0-90"
    "6.8.0-137"
    "7.0.0-28"
)

ACTIVE="$(uname -r)"

echo "========================================"
echo " LIMPIEZA DE KERNELS"
echo "========================================"
echo
echo "Kernel activo: $ACTIVE"
echo

# ------------------------------------------------------------
# Protección del kernel activo
# ------------------------------------------------------------

for version in "${REMOVE[@]}"; do
    if [[ "${ACTIVE}" == "${version}-generic" ]]; then
        echo "ERROR: $version está en la lista de eliminación"
        echo "pero actualmente está ejecutándose."
        echo
        echo "No se modificó nada."
        exit 1
    fi
done

echo "Se conservarán:"
printf '  %s\n' "${KEEP[@]}"

echo
echo "Se eliminarán:"
printf '  %s\n' "${REMOVE[@]}"

echo
read -r -p "¿Continuar? Escribí SI para confirmar: " CONFIRM

if [[ "$CONFIRM" != "SI" ]]; then
    echo "Cancelado."
    exit 0
fi

# ------------------------------------------------------------
# Construir lista SOLO con paquetes realmente instalados
# ------------------------------------------------------------

PACKAGES=()

for version in "${REMOVE[@]}"; do

    candidates=(
        "linux-image-${version}-generic"
        "linux-modules-${version}-generic"
        "linux-modules-extra-${version}-generic"
        "linux-headers-${version}"
        "linux-headers-${version}-generic"
    )

    for pkg in "${candidates[@]}"; do
        if dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null \
            | grep -q '^ii'; then

            PACKAGES+=("$pkg")
        fi
    done
done

if (( ${#PACKAGES[@]} == 0 )); then
    echo
    echo "No se encontraron paquetes antiguos instalados."
    exit 0
fi

echo
echo "Paquetes que APT va a purgar:"
printf '  %s\n' "${PACKAGES[@]}"

echo
echo "----------------------------------------"
echo " Espacio antes"
echo "----------------------------------------"
df -h /

echo
echo "Eliminando paquetes..."
sudo apt-get purge -y "${PACKAGES[@]}"

echo
echo "Ejecutando autoremove..."
sudo apt-get autoremove --purge -y

echo
echo "Limpiando caché de paquetes..."
sudo apt-get clean

echo
echo "Actualizando GRUB..."
sudo update-grub

echo
echo "========================================"
echo " RESULTADO"
echo "========================================"

echo
echo "Kernel activo:"
uname -r

echo
echo "/usr/lib/modules:"
sudo du -sh /usr/lib/modules

echo
echo "Versiones restantes:"
ls -1 /usr/lib/modules

echo
echo "Espacio en disco:"
df -h /

echo
echo "Limpieza terminada."
