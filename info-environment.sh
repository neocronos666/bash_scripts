#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"
clear

    echo -e "🔰              "
    echo -e "${CYAN}_______________ 🖧 ${NC} 📌 RESUMEN DEL SISTEMA 🖧 ${CYAN}______________________________${NC} \n"
    # Detectar la distribución de Linux
    if command -v lsb_release &>/dev/null; then
        echo -e "${YELLOW} 🔹 Distro:${NC} $(lsb_release -d | cut -f2)"
    elif [ -f /etc/os-release ]; then
        echo -e "${YELLOW} 🔹 Distro:${NC} $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"
    else
        echo -e "${YELLOW} 🔹 Distro:${NC} Desconocida"
    fi

    echo -e "${YELLOW} 🔹 Kernel:${NC} $(uname -r)"
    echo -e "${YELLOW} 🔹 Shell:${NC} $SHELL"
    

    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🖥️ DISCOS Y PARTICIONES 🖧 ${CYAN}_____________________________${GREEN} \n"
    lsblk --tree


    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🐍 VERSIONES DE PYTHON & ANACONDA 🖧 ${CYAN}___________________${NC} \n"
        if command -v python3 &>/dev/null; then
            echo -e "${YELLOW}  🔹 Python 3:${NC} $(python3 --version)"
        fi
        if command -v python &>/dev/null; then
            echo -e "${YELLOW}  🔹 Python 2:${NC} $(python --version 2>&1)"
        fi
        if command -v conda &>/dev/null; then
            echo -e "${YELLOW}  🔹 Anaconda:${NC} $(conda --version)"
        fi

    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🛠️ ENTORNOS VIRTUALES (Python & Conda) 🖧 ${CYAN}______________${NC} \n"

        # Entornos virtuales de Python (venv)
        venvs=()
        if [ -d "$HOME/.virtualenvs" ]; then
            while IFS= read -r -d '' env_dir; do
                venvs+=("$env_dir")
            done < <(find "$HOME/.virtualenvs" -mindepth 1 -maxdepth 1 -type d -print0)
        fi

        # Buscar entornos en el home y proyectos
        while IFS= read -r -d '' env_dir; do
            [[ -f "$env_dir/bin/activate" ]] && venvs+=("$env_dir")
        done < <(
            find "$HOME" -type d \( -name env -o -name venv \) -print0 2>/dev/null
        )

        if [ ${#venvs[@]} -gt 0 ]; then
            echo -e "${YELLOW} 🔹 Entornos virtuales Python encontrados:${NC}"
            for venv in "${venvs[@]}"; do
                echo "   - $venv"
            done
            echo -e "${RED}📝 Para activar: source <ruta>/bin/activate${NC}"
        else
            echo -e "${YELLOW} 🔹 No se encontraron entornos virtuales de Python."
        fi

        # Entornos virtuales de Conda
        if command -v conda &>/dev/null; then
            echo -e " 🔹 Entornos Conda:${NC}"
            conda env list
            echo -e "${RED}📝 Para activar: conda activate <env>${NC}"
        fi
    echo -e "\n${CYAN}_______________ 🖧 ${NC} 🖥️ SERVIDORES Y BASES DE DATOS 🖧 ${CYAN}______________________${GREEN} \n"
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
            if command -v "$server" &>/dev/null; then
                echo " 🔹 $server está instalado."
            fi
        done
    echo -e "\n${CYAN}_______________ 🖧 ${NC} 📂 UBICACIÓN DE ARCHIVOS CLAVE 🖧 ${CYAN}_______________________${NC} \n"

        echo -e "${YELLOW} 🔹 Python global: ${NC}$(which python3)"
        echo -e "${YELLOW} 🔹 Anaconda: ${NC}$(which conda)"
        echo -e "${YELLOW} 🔹 Servidores web: ${NC}/etc/nginx, /etc/apache2"
        echo -e "${YELLOW} 🔹 Bases de datos: ${NC}/var/lib/mysql, /var/lib/postgresql"






