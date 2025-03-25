#!/bin/bash

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo "========================================"
    echo "= Seleccione un comando para ejecutar: ="
    echo "========================================________________________________"
    echo "|1. neofetch - Mostrar información del sistema."
    echo "|2. htop - Monitor de procesos interactivo."
    echo "|3. sensors - Mostrar la temperatura de los sensores de hardware."
    echo "|4. df - Mostrar el uso del espacio en disco."
    echo "|5. du - Mostrar el uso del espacio en disco por archivos y directorios."
    echo "|6. free - Mostrar la cantidad de memoria libre y usada."
    echo "|7. uptime - Mostrar cuánto tiempo ha estado funcionando el sistema."
    echo "|8. uname - Mostrar información del sistema operativo y kernel."
    echo "|9. ps - Mostrar procesos en ejecución."
    echo "|10. kill - Terminar un proceso especificado por su PID."
    echo "|11. top - Monitorizar procesos en tiempo real."
    echo "|12. lsblk - Mostrar información sobre dispositivos de bloques."
    echo "|13. dmesg - Mostrar mensajes del sistema y del kernel."
    echo "|14. crontab - Configurar tareas automáticas."
    echo "|15. alias - Crear atajos para comandos."
    echo "|16. history - Mostrar el historial de comandos."
    echo "|17. whoami - Mostrar el nombre del usuario actual."
    echo "|18. locate - Buscar archivos rápidamente."
    echo "|19. grep - Buscar cadenas de texto en archivos."
    echo "|20. xkill - Cerrar forzosamente una ventana."
    echo "0. Salir.________________________________________________________________"
}

# Función para pedir parámetros y ejecutar el comando
ejecutar_comando() {
    case $1 in
        1) neofetch ;;
        2) htop ;;
        3) sensors ;;
        4) df -h ;;
        5) echo "Ingrese el directorio para analizar: "; read dir; du -sh "$dir" ;;
        6) free -h ;;
        7) uptime ;;
        8) uname -a ;;
        9) ps aux ;;
        10) echo "Ingrese el PID del proceso a terminar: "; read pid; kill "$pid" ;;
        11) top ;;
        12) lsblk -f ;;
        13) dmesg | less ;;
        14) crontab -e ;;
        15) echo "Ingrese el alias (ej. ll='ls -lah'): "; read alias_cmd; alias $alias_cmd ;;
        16) history ;;
        17) whoami ;;
        18) echo "Ingrese el nombre del archivo a buscar: "; read file_name; locate "$file_name" ;;
        19) echo "Ingrese la cadena a buscar: "; read text; echo "Ingrese el archivo donde buscar: "; read file; grep "$text" "$file" ;;
        20) xkill ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida. Inténtelo de nuevo." ;;
    esac
}

# Ciclo principal del script
while true; do
    mostrar_menu
    echo -n "Seleccione una opción (0-20): "
    read opcion
    ejecutar_comando $opcion
    echo "Presione Enter para continuar..."
    read
done

