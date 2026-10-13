#!/bin/bash

# Ruta donde están los directorios originales
RUTA_CORRECTA="${DIRECTORIOS_ORIGEN:-${1:-}}"
if [[ -z "$RUTA_CORRECTA" || ! -d "$RUTA_CORRECTA" ]]; then
    echo "Uso: DIRECTORIOS_ORIGEN=/ruta $0" >&2
    echo "   o: $0 /ruta" >&2
    exit 1
fi

# Directorios especiales que quieres reparar
DIRECTORIOS=("Backup" "Imágenes" "Música" "Descargas" "Videos" "Público" "Plantillas" "Drivers" "Recursos" "Retroarch")

for dir in "${DIRECTORIOS[@]}"; do
    # Verifica si el enlace está roto
    if [[ -L "$HOME/$dir" && ! -e "$HOME/$dir" ]]; then
        echo "Eliminando enlace roto para $dir"
        rm -- "$HOME/$dir"
        
        # Crea el enlace simbólico nuevamente
        if [[ -e "$RUTA_CORRECTA/$dir" ]]; then
            echo "Creando nuevo enlace para $dir"
            ln -s -- "$RUTA_CORRECTA/$dir" "$HOME/$dir"
        else
            echo "No existe el destino $RUTA_CORRECTA/$dir; se omite."
        fi
    elif [[ ! -e "$HOME/$dir" ]]; then
        echo "$HOME/$dir no existe y no es un enlace roto; se omite."
    else
        echo "El enlace para $dir está funcionando correctamente."
    fi
done

echo "Reparación de enlaces completa."
