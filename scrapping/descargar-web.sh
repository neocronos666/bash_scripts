#!/bin/bash
#----------------------------------------------------------------------------------
#   USO
# ./descargar_web.sh https://docs.frappe.io/erpnext/user/manual/en/introduction
#   o
# bash descargar_web.sh https://docs.frappe.io/erpnext/user/manual/en/introduction
#   o
# ./descargar_web.sh   ← y luego pegar la URL
#----------------------------------------------------------------------------------

# Verifica si se pasó una URL como argumento
if [ -z "$1" ]; then
    echo -e "\n⚠️  No proporcionaste una URL."
    read -p "👉 Pegá la URL a descargar: " URL
else
    URL="$1"
fi

# Elimina espacios extra en la URL
URL=$(echo "$URL" | xargs)

# Nombre de la carpeta de salida
CARPETA_SALIDA="${BASH_SCRIPTS_DOWNLOADS:-$HOME/Descargas/scrapped}/web"

# Mensaje de inicio
echo -e "\n===== 🌐 Descargando el sitio: $URL =====\n"

# Ejecutar wget con las opciones necesarias
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent --wait=1 --max-redirect=10 -e robots=off \
     --directory-prefix="$CARPETA_SALIDA" "$URL"

# Verificar si la descarga fue exitosa
if [ $? -eq 0 ]; then
    echo -e "\n✅ Descarga completada. Revisa la carpeta '$CARPETA_SALIDA'.\n"
else
    echo -e "\n❌ Hubo un error en la descarga.\n"
fi
