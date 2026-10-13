#!/bin/bash

# Detectar el gestor de ventanas
WM=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

echo "Gestor de ventanas detectado: $WM"

# Reiniciar según el entorno
case "$WM" in
    xfce)
        echo "Reiniciando Xfwm4..."
        xfwm4 --replace &
        ;;
    cinnamon)
        echo "Reiniciando Cinnamon..."
        killall cinnamon && cinnamon --replace &
        ;;
    kde)
        echo "Reiniciando KWin..."
        kwin_x11 --replace &
        ;;
    gnome)
        echo "Reiniciando Mutter..."
        gnome-shell --replace &
        ;;
    *)
        echo "Gestor de ventanas no reconocido o no soportado."
        exit 1
        ;;
esac

echo "Proceso completado."

