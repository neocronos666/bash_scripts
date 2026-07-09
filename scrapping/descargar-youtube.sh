#!/bin/bash

clear

#######################################
# COLORES
#######################################

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
WHITE="\e[97m"
NC="\e[0m"

#######################################
# DIRECTORIOS
#######################################

DESTINO="$HOME/Descargas/scrapped/yt"

VIDEO_DIR="$DESTINO"
AUDIO_DIR="$DESTINO"
PLAYLIST_DIR="$DESTINO/playlists"

CACHE_DIR="$HOME/.cache/yt-dlp"

ARCHIVE="$CACHE_DIR/archive.txt"

mkdir -p "$VIDEO_DIR"
mkdir -p "$PLAYLIST_DIR"
mkdir -p "$CACHE_DIR"

#######################################
# YT-DLP
#######################################

#YT="yt-dlp \
#--cookies-from-browser chrome \
#--extractor-args youtube:player_client=android \
#--download-archive \"$ARCHIVE\""
YT_DLP=(
    yt-dlp    
    --extractor-args "youtube:player_client=android"
    --download-archive "$ARCHIVE"
)
#######################################
# BANNER
#######################################

banner(){

echo -e "${RED}"
echo "           ███████████████████████████           "
echo "      ███████████████████████████████████       "
echo "   █████████████████████████████████████████    "
echo " █████████████████████████████████████████████  "
echo "███████████████████████████████████████████████ "
echo "██████████████                         █████████"
echo -e "████████████            ${WHITE}/\\\\             ${RED}███████████"
echo -e "███████████            ${WHITE}/  \\\\             ${RED}██████████"
echo -e "██████████            ${WHITE}/____\\\\           ${RED}█████████"
echo "████████████                         ███████████"
echo " ██████████████████████████████████████████████ "
echo "  ████████████████████████████████████████████  "
echo "    ████████████████████████████████████████    "
echo "      ████████████████████████████████████      "
echo -e "${NC}"

echo -e "${CYAN}🎬 Descargador de YouTube${NC}"
echo
}

#######################################
# DEPENDENCIAS
#######################################

check_dep(){

for cmd in yt-dlp ffmpeg
do
    if ! command -v "$cmd" >/dev/null 2>&1
    then
        echo -e "${RED}Falta instalar ${cmd}.${NC}"
        exit 1
    fi
done

}

#######################################
# PEDIR URL
#######################################

pedir_url(){

echo
read -rp "🔗 Pegá la URL: " URL

[[ -z "$URL" ]] && exit 1

}
#######################################
# ACTUALIZAR
#######################################

actualizar(){
echo Actualizando...
python3 -m pip install -U yt-dlp
echo
read -rp "✳️ continuar..."
}

#######################################
# HISTORIAL
#######################################

ver_historial(){

clear

banner

if [[ -f "$ARCHIVE" ]]
then
    cat "$ARCHIVE"
else
    echo
    echo "Todavía no existe historial."
fi

echo
read -rp "✳️ continuar..."

}

#######################################
# REPORTE
#######################################

reporte(){

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Descarga finalizada.${NC}"
echo
echo "$1"
echo
echo "Destino:"
echo "$2"
echo -e "${GREEN}========================================${NC}"

echo
read -rp "✳️ volver..."

}

#######################################
# MENU
#######################################

menu(){

echo "0) Salir"
echo "1) Descargar VIDEO"
echo "2) Descargar AUDIO MP3"
echo "3) Descargar PLAYLIST VIDEO"
echo "4) Descargar PLAYLIST AUDIO"
echo "5) Ver historial"
echo "6) Actualizar yt-dlp"

echo
read -rp "🗿 $USER ⭕ " OPCION

}
#######################################
# DESCARGAR VIDEO
#######################################

descargar_video(){

pedir_url

echo
echo -e "${CYAN}Descargando video...${NC}"
echo

"${YT_DLP[@]}" \
-f "bv*+ba/b" \
--merge-output-format mp4 \
--no-playlist \
-o "$VIDEO_DIR/%(title)s.%(ext)s" \
"$URL"

reporte "VIDEO" "$VIDEO_DIR"

}

#######################################
# DESCARGAR AUDIO
#######################################

descargar_audio(){

pedir_url

echo
echo -e "${CYAN}Extrayendo audio MP3...${NC}"
echo

"${YT_DLP[@]}" \
--extract-audio \
--audio-format mp3 \
--no-playlist \
-o "$AUDIO_DIR/%(title)s.%(ext)s" \
"$URL"

reporte "AUDIO MP3" "$AUDIO_DIR"

}

#######################################
# PLAYLIST VIDEO
#######################################

descargar_playlist_video(){

pedir_url

PLAYLIST=$(
"${YT_DLP[@]}" \
--flat-playlist \
--print "%(playlist)s" \
"$URL" | head -n1
)

PLAYLIST=${PLAYLIST//\//-}
PLAYLIST=${PLAYLIST//:/-}

[[ -z "$PLAYLIST" ]] && PLAYLIST="Playlist"

DESTINO_PLAYLIST="$PLAYLIST_DIR/$PLAYLIST"

mkdir -p "$DESTINO_PLAYLIST"

echo
echo -e "${CYAN}Descargando playlist...${NC}"
echo

"${YT_DLP[@]}" \
-f "bv*+ba/b" \
--merge-output-format mp4 \
--yes-playlist \
-o "$DESTINO_PLAYLIST/%(playlist_index)03d - %(title)s.%(ext)s" \
"$URL"

reporte "PLAYLIST VIDEO" "$DESTINO_PLAYLIST"

}

#######################################
# PLAYLIST AUDIO
#######################################

descargar_playlist_audio(){

pedir_url

PLAYLIST=$(
"${YT_DLP[@]}" \
--flat-playlist \
--print "%(playlist)s" \
"$URL" | head -n1
)

PLAYLIST=${PLAYLIST//\//-}
PLAYLIST=${PLAYLIST//:/-}

[[ -z "$PLAYLIST" ]] && PLAYLIST="Playlist"

DESTINO_PLAYLIST="$PLAYLIST_DIR/$PLAYLIST"

mkdir -p "$DESTINO_PLAYLIST"

echo
echo -e "${CYAN}Descargando playlist...${NC}"
echo

"${YT_DLP[@]}" \
--extract-audio \
--audio-format mp3 \
--yes-playlist \
-o "$DESTINO_PLAYLIST/%(playlist_index)03d - %(title)s.%(ext)s" \
"$URL"

reporte "PLAYLIST AUDIO" "$DESTINO_PLAYLIST"

}
#######################################
# MAIN
#######################################

check_dep

while true
do

clear

banner

menu

case "$OPCION" in

0)

exit 0

;;

1)

descargar_video

;;

2)

descargar_audio

;;

3)

descargar_playlist_video

;;

4)

descargar_playlist_audio

;;

5)

ver_historial

;;
6)

actualizar

;;


*)

echo
echo -e "${RED}♿ Opción inválida.${NC}"
sleep 1

;;

esac

done
