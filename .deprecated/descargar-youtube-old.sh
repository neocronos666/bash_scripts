#!/bin/bash
clear
# 🎨 Colores
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"
WHITE="\e[97m"

# 📁 Carpeta destino
DESTINO="$HOME/Descargas/scrapped/yt"
mkdir -p "$DESTINO"

# 📌 Título
clear


echo -e "${RED}"
echo "           ███████████████████████████           "
echo "      ███████████████████████████████████       "
echo "   █████████████████████████████████████████    "
echo " █████████████████████████████████████████████  "
echo "███████████████████████████████████████████████ "
echo "██████████████                         █████████"
echo -e "████████████            ${WHITE}/\\             ${RED}███████████"
echo -e "███████████            ${WHITE}/  \\             ${RED}██████████"
echo -e "██████████            ${WHITE}/____\\           ${RED}█████████"
echo "████████████                         ███████████"
echo " ██████████████████████████████████████████████ "
echo "  ████████████████████████████████████████████  "
echo "    ████████████████████████████████████████    "
echo "      ████████████████████████████████████      "
echo -e "          ${NC}"


echo -e "${CYAN}🎬 Descargador de YouTube con yt-dlp + cookies de Chrome${NC}"
echo -e "${YELLOW}----------------------------------------------------${NC}"

# ❓ Opción
echo -e "${CYAN}¿Qué querés descargar?${NC}"
echo -e "  [0] ❌ Volver"
echo -e "  [1] 🎵 Solo audio (${GREEN}MP3${NC})"
echo -e "  [2] 📹 Video y/o audio (${GREEN}todos los formatos${NC})"
echo -e "  [3] 📹 Descarga facil${NC})"
read -p "   🗿$USER⭕ " OPCION

if [[ "$OPCION" != "1" && "$OPCION" != "2" ]]; then    
    exit 1
fi

# 🔗 URL
read -p "🔗 Pegá la URL del video: " URL

# 🏷️ Nombre base
echo -e "${CYAN}⏳ Detectando título del video...${NC}"
NOMBRE_BASE=$(yt-dlp --cookies-from-browser chrome --get-title "$URL" | tr -cd '[:alnum:]._-')
NOMBRE_BASE=${NOMBRE_BASE:0:50}
echo -e "${GREEN}✔ Nombre base detectado:${NC} $NOMBRE_BASE"

# 🚀 Operación según opción
if [[ "$OPCION" == "3" ]]; then
    echo -e "${CYAN}\n📦 Espere...:\n${NC}"
    yt-dlp --extractor-args "youtube:player_client=android" "$URL"
    DESTINO=pwd

elif [[ "$OPCION" == "2" ]]; then
    echo -e "${CYAN}\n📦 Formatos disponibles:\n${NC}"
    yt-dlp --cookies-from-browser chrome -F "$URL"

    echo -e "${YELLOW}🎯 Elegí el formato de video+audio (ej: 18, 135+140):${NC}"
    read -p "Formato: " FORMATO

    echo -e "${CYAN}⬇ Descargando video en $DESTINO...${NC}"
    yt-dlp --cookies-from-browser chrome -f "$FORMATO" -o "$DESTINO/${NOMBRE_BASE}.%(ext)s" "$URL"

    echo -e "${GREEN}✅ Video descargado correctamente.${NC}"

elif [[ "$OPCION" == "1" ]]; then
    echo -e "${CYAN}⬇ Descargando audio en MP3...${NC}"
    yt-dlp --cookies-from-browser chrome --extract-audio --audio-format mp3 \
        -o "$DESTINO/${NOMBRE_BASE}.mp3" "$URL"

    echo -e "${GREEN}✅ Audio MP3 descargado correctamente.${NC}"
elif [[ "$OPCION" == "0" ]]; then
    exit 1
else
    echo -e "${RED}❌ Opción inválida. Abortando.${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Archivos guardados en:${NC} $DESTINO"

