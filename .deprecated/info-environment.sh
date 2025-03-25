#!/bin/bash
clear
echo "========================================"
echo "📌 RESUMEN DEL SISTEMA"
echo "========================================"

# Detectar la distribución de Linux
if command -v lsb_release &>/dev/null; then
    echo "🔹 Distro: $(lsb_release -d | cut -f2)"
elif [ -f /etc/os-release ]; then
    echo "🔹 Distro: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
else
    echo "🔹 Distro: Desconocida"
fi

echo "🔹 Kernel: $(uname -r)"
echo "🔹 Shell: $SHELL"

echo "----------------------------------------"
echo "🖥️  DISCOS"
echo "----------------------------------------"
lsblk
echo "----------------------------------------"
echo "🐍 VERSIONES DE PYTHON & ANACONDA"
echo "----------------------------------------"
if command -v python3 &>/dev/null; then
    echo "🔹 Python 3: $(python3 --version)"
fi
if command -v python &>/dev/null; then
    echo "🔹 Python 2: $(python --version 2>&1)"
fi
if command -v conda &>/dev/null; then
    echo "🔹 Anaconda: $(conda --version)"
fi

echo "----------------------------------------"
echo "🛠️ ENTORNOS VIRTUALES (Python & Conda)"
echo "----------------------------------------"

# Entornos virtuales de Python (venv)
venvs=()
if [ -d "$HOME/.virtualenvs" ]; then
    venvs+=($(ls "$HOME/.virtualenvs"))
fi

# Buscar entornos en el home y proyectos
find $HOME -type d -name "env" -o -name "venv" 2>/dev/null | while read env_dir; do
    if [ -f "$env_dir/bin/activate" ]; then
        venvs+=("$env_dir")
    fi
done

if [ ${#venvs[@]} -gt 0 ]; then
    echo "🔹 Entornos virtuales Python encontrados:"
    for venv in "${venvs[@]}"; do
        echo "   - $venv"
    done
    echo "📝 Para activar: source <ruta>/bin/activate"
else
    echo "🔹 No se encontraron entornos virtuales de Python."
fi

# Entornos virtuales de Conda
if command -v conda &>/dev/null; then
    echo "🔹 Entornos Conda:"
    conda env list
    echo "📝 Para activar: conda activate <env>"
fi

echo "----------------------------------------"
echo "🖥️ SERVIDORES Y BASES DE DATOS"
echo "----------------------------------------"
# Buscar servidores instalados
declare -A servers=(
    ["nginx"]="sudo systemctl status nginx"
    ["apache"]="sudo systemctl status apache2"
    ["mysql"]="sudo systemctl status mysql"
    ["postgresql"]="sudo systemctl status postgresql"
    ["mongodb"]="sudo systemctl status mongod"
    ["redis"]="sudo systemctl status redis"
)

for server in "${!servers[@]}"; do
    if command -v $server &>/dev/null; then
        echo "🔹 $server está instalado."
    fi
done

echo "----------------------------------------"
echo "📂 UBICACIÓN DE ARCHIVOS CLAVE"
echo "----------------------------------------"
echo "🔹 Python global: $(which python3)"
echo "🔹 Anaconda: $(which conda)"
echo "🔹 Servidores web: /etc/nginx, /etc/apache2"
echo "🔹 Bases de datos: /var/lib/mysql, /var/lib/postgresql"




echo "========================================"
echo "✅ Resumen generado con éxito"
echo "========================================"


