#!/bin/bash

DESTINO="$HOME/Descargas"
mkdir -p "$DESTINO"

echo -e "\n¿Qué querés descargar?"
echo "[1] Solo audio (MP3)"
echo "[2] Video con audio (calidad seleccionable)"
read -p "Opción: " OPCION

read -p "Pegá la URL del video: " URL

# Detectar título para nombre base
NOMBRE_BASE=$(yt-dlp --cookies-from-browser chrome --get-title "$URL" | tr -cd '[:alnum:]._-')
NOMBRE_BASE=${NOMBRE_BASE:0:50}

# Mostrar formatos si es video
if [[ "$OPCION" == "2" ]]; then
    echo -e "\n📦 Formatos disponibles:\n"
    yt-dlp --cookies-from-browser chrome -F "$URL"
    echo -e "\nElegí el formato de video+audio (por ejemplo 18 o 135+140):"
    read -p "Formato: " FORMATO

    yt-dlp --cookies-from-browser chrome -f "$FORMATO" -o "$DESTINO/${NOMBRE_BASE}.%(ext)s" "$URL"
    echo -e "\n✅ Video descargado en: $DESTINO"

elif [[ "$OPCION" == "1" ]]; then
    yt-dlp --cookies-from-browser chrome --extract-audio --audio-format mp3 \
        -o "$DESTINO/${NOMBRE_BASE}.mp3" "$URL"
    echo -e "\n✅ MP3 descargado en: $DESTINO"
else
    echo "❌ Opción inválida."
    exit 1
fi

