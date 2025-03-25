#!/bin/bash

# Verificar si pandoc está instalado
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc no está instalado. Instálalo con: sudo apt install pandoc"
    exit 1
fi

# Preguntar ruta si no se pasa como argumento
if [ -z "$1" ]; then
    read -p "Introduce la ruta donde están los archivos HTML: " html_dir
else
    html_dir="$1"
fi

# Verificar si la carpeta existe
if [ ! -d "$html_dir" ]; then
    echo "Error: La carpeta no existe."
    exit 1
fi

# Buscar archivos HTML y ordenarlos
html_files=$(find "$html_dir" -type f -name "*.html" | sort)

# Verificar si hay archivos HTML
if [ -z "$html_files" ]; then
    echo "Error: No se encontraron archivos HTML en $html_dir"
    exit 1
fi

# Nombre del PDF en la ruta donde se ejecutó el script
output_pdf="$(pwd)/sitio_completo.pdf"

# Convertir HTML a PDF
# pandoc $html_files --verbose -o "$output_pdf"
# pandoc $html_files -o "$output_pdf"
pandoc $html_files --resource-path="$html_dir" -o "$output_pdf"

echo "✅ PDF generado correctamente: $output_pdf"

