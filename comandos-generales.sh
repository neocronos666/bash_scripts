#!/bin/bash
# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# Función para mostrar el menú
mostrar_menu() {
    clear
    #TITULO
    echo -e "🔰              "
    echo -e "${CYAN}    _______________ 🖳 ${NC} Comandos Utiles ${CYAN}_________________\n"
    echo -e "         ${YELLOW}[1]${RED} neofetch ${NC} - ${GREEN}Mostrar información del sistema"
    echo -e "         ${YELLOW}[2]${RED} htop ${NC} - ${GREEN}Monitor de procesos interactivo"
    echo -e "         ${YELLOW}[3]${RED} sensors ${NC} - ${GREEN}Mostrar la temperatura de los sensores de hardware"
    echo -e "         ${YELLOW}[4]${RED} df ${NC} - ${GREEN}Mostrar el uso del espacio en disco"
    echo -e "         ${YELLOW}[5]${RED} du ${NC} - ${GREEN}Mostrar el uso del espacio en disco por archivos y directorios"
    echo -e "         ${YELLOW}[6]${RED} free ${NC} - ${GREEN}Mostrar la cantidad de memoria libre y usada"
    echo -e "         ${YELLOW}[7]${RED} uptime ${NC} - ${GREEN}Mostrar cuánto tiempo ha estado funcionando el sistema"
    echo -e "         ${YELLOW}[8]${RED} uname ${NC} - ${GREEN}Mostrar información del sistema operativo y kernel"
    echo -e "         ${YELLOW}[9]${RED} ps ${NC} - ${GREEN}Mostrar procesos en ejecución"
    echo -e "         ${YELLOW}[10]${RED} kill [PID] ${NC} - ${GREEN}Terminar un proceso especificado por su PID"
    echo -e "         ${YELLOW}[11]${RED} top ${NC} - ${GREEN}Monitorizar procesos en tiempo real"
    echo -e "         ${YELLOW}[12]${RED} lsblk ${NC} - ${GREEN}Mostrar información sobre discos y particiones"
    echo -e "         ${YELLOW}[13]${RED} dmesg ${NC} - ${GREEN}Mostrar mensajes del sistema y del kernel"
    echo -e "         ${YELLOW}[14]${RED} crontab -e ${NC} - ${GREEN}Configurar tareas automáticas"
    echo -e "         ${YELLOW}[15]${RED} alias ${NC} - ${GREEN}Crear atajos para comandos"
    echo -e "         ${YELLOW}[16]${RED} history ${NC} - ${GREEN}Mostrar el historial de comandos"
    echo -e "         ${YELLOW}[17]${RED} whoami ${NC} - ${GREEN}Mostrar el nombre del usuario actual"
    echo -e "         ${YELLOW}[18]${RED} locate [archivo] ${NC} - ${GREEN}Buscar archivos rápidamente"
    echo -e "         ${YELLOW}[19]${RED} grep [patrón] [archivo] ${NC} - ${GREEN}Buscar cadenas de texto en archivos"
    echo -e "         ${YELLOW}[20]${RED} xkill ${NC} - ${GREEN}Cerrar forzosamente una ventana"
    echo -e "         ${YELLOW}[0]${RED} Salir ${NC} - ${GREEN}Terminar la ejecución del script"
    echo -e "\n    ${YELLOW}[0] ⮹ Volver\n"
    echo -e "${CYAN}    ________________________________________________________${YELLOW}\n"
}

# Función para pedir parámetros y ejecutar el comando
ejecutar_comando() {
    case $1 in
        1) neofetch ;;
        2) htop ;;
        3) sensors ;;
        4) df -h ;;
        5) echo "📂 Ingrese el directorio para analizar: "; read dir; du -sh "$dir" ;;
        6) free -h ;;
        7) uptime ;;
        8) uname -a ;;
        9) ps aux ;;
        10) echo "📈Ingrese el PID del proceso a terminar: "; read pid; kill "$pid" ;;
        11) top ;;
        12) lsblk -f ;;
        13) dmesg | less ;;
        14) crontab -e ;;
        15) echo "👤Ingrese el alias (ej. ll='ls -lah'): "; read alias_cmd; alias $alias_cmd ;;
        16) history ;;
        17) whoami ;;
        18) echo "📄Ingrese el nombre del archivo a buscar: "; read file_name; locate "$file_name" ;;
        19) echo "📄Ingrese la cadena a buscar: "; read text; echo "Ingrese el archivo donde buscar: "; read file; grep "$text" "$file" ;;
        20) xkill ;;
        0) exit 0 ;;
        *) echo "Opción no válida. Inténtelo de nuevo." ;;
    esac
}

# Ciclo principal del script
while true; do
    mostrar_menu
    echo -n "⭕ Selecciona una opción:  "
    read opcion
    ejecutar_comando $opcion
    echo "⏳ (continuar)"
    read
done

