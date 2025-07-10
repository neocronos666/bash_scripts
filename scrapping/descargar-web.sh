#!/bin/bash
#----------------------------------------------------------------------------------
#   USO
# ./descargar_web.sh https://docs.frappe.io/erpnext/user/manual/en/introduction
#   o
# bash descargar_web.sh https://docs.frappe.io/erpnext/user/manual/en/introduction
#
#----------------------------------------------------------------------------------
# Verifica si se pasó una URL
if [ -z "$1" ]; then
    echo -e "\n❌ Uso: $0 <URL>\n"
    exit 1
fi

# Elimina espacios extra en la URL
URL=$(echo "$1" | xargs)

# Nombre de la carpeta de salida
CARPETA_SALIDA="$HOME/Descargas/scrapped/web"

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

#./descargar_web.sh https://docs.frappe.io/erpnext/user/manual/en/introduction
