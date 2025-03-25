#!/bin/bash

# Ruta donde están los directorios originales
RUTA_CORRECTA="/media/neocronos/neocronos/"

# Directorios especiales que quieres reparar
DIRECTORIOS=("Backup" "Imágenes" "Música" "Descargas" "Videos" "Público" "Plantillas" "Drivers" "Recursos" "Retroarch")

for dir in "${DIRECTORIOS[@]}"; do
    # Verifica si el enlace está roto
    if [ ! -e "$HOME/$dir" ]; then
        echo "Eliminando enlace roto para $dir"
        rm "$HOME/$dir"
        
        # Crea el enlace simbólico nuevamente
        echo "Creando nuevo enlace para $dir"
        ln -s "$RUTA_CORRECTA/$dir" "$HOME/$dir"
    else
        echo "El enlace para $dir está funcionando correctamente."
    fi
done

echo "Reparación de enlaces completa."

