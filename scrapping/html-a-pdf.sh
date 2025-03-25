#!/bin/bash

# Verificar si pandoc está instalado
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc no está instalado. Instálalo con: sudo apt install pandoc"
    exit 1
fi

# Verificar si se proporcionó un archivo
if [ -z "$1" ]; then
    echo "Uso: html2pdf archivo.html"
    exit 1
fi

# Archivo de entrada
input_file="$1"

# Verificar si el archivo existe
if [ ! -f "$input_file" ]; then
    echo "Error: El archivo no existe."
    exit 1
fi

# Obtener ruta y nombre del archivo sin extensión
dir=$(dirname "$input_file")
filename=$(basename "$input_file" .html)

# Archivo de salida en la misma carpeta
output_file="$dir/$filename.pdf"

# Convertir HTML a PDF
pandoc "$input_file" -o "$output_file"

echo "✅ Conversión exitosa: $output_file"

