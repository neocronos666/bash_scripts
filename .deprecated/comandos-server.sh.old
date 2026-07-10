#!/bin/bash

# Colores para una salida más elegante
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
NC="\e[0m"

# Función para mostrar el menú
show_menu() {
    clear
    echo -e "🔰              "
    echo -e "${CYAN}    _______________ 🖧 ${NC} 100 Comandos Utiles para el Servidor 🖳${CYAN}___________\n"     
    echo -e "         ${YELLOW}[1]${RED} apt update ${NC} - ${GREEN}Actualizar lista de paquetes"
    echo -e "         ${YELLOW}[2]${RED} apt upgrade ${NC} - ${GREEN}Actualizar todos los paquetes"
    echo -e "         ${YELLOW}[3]${RED} apt install apache2 ${NC} - ${GREEN}Instalar servidor web Apache"
    echo -e "         ${YELLOW}[4]${RED} apt install nginx ${NC} - ${GREEN}Instalar servidor web Nginx"
    echo -e "         ${YELLOW}[5]${RED} apt install mysql-server ${NC} - ${GREEN}Instalar MySQL"
    echo -e "         ${YELLOW}[6]${RED} apt install postgresql ${NC} - ${GREEN}Instalar PostgreSQL"
    echo -e "         ${YELLOW}[7]${RED} apt install php libapache2-mod-php ${NC} - ${GREEN}Instalar PHP"
    echo -e "         ${YELLOW}[8]${RED} ufw enable ${NC} - ${GREEN}Configurar el firewall con UFW"
    echo -e "         ${YELLOW}[9]${RED} ufw status ${NC} - ${GREEN}Ver el estado del firewall"
    echo -e "         ${YELLOW}[10]${RED} ufw allow ssh ${NC} - ${GREEN}Permitir tráfico SSH"
    echo -e "         ${YELLOW}[11]${RED} ufw allow http ${NC} - ${GREEN}Permitir tráfico HTTP"
    echo -e "         ${YELLOW}[12]${RED} ufw allow https ${NC} - ${GREEN}Permitir tráfico HTTPS"
    echo -e "         ${YELLOW}[13]${RED} systemctl restart apache2 ${NC} - ${GREEN}Reiniciar servidor Apache"
    echo -e "         ${YELLOW}[14]${RED} systemctl restart nginx ${NC} - ${GREEN}Reiniciar servidor Nginx"
    echo -e "         ${YELLOW}[15]${RED} systemctl restart mysql ${NC} - ${GREEN}Reiniciar servidor MySQL"
    echo -e "         ${YELLOW}[16]${RED} systemctl restart postgresql ${NC} - ${GREEN}Reiniciar servidor PostgreSQL"
    echo -e "         ${YELLOW}[17]${RED} df -h ${NC} - ${GREEN}Ver el uso de disco"
    echo -e "         ${YELLOW}[18]${RED} top ${NC} - ${GREEN}Ver procesos activos"
    echo -e "         ${YELLOW}[19]${RED} ps aux --sort=-%mem | head ${NC} - ${GREEN}Ver los 10 procesos que más consumen memoria"
    echo -e "         ${YELLOW}[20]${RED} ps aux --sort=-%cpu | head ${NC} - ${GREEN}Ver los 10 procesos que más consumen CPU"
    echo -e "         ${YELLOW}[21]${RED} free -h ${NC} - ${GREEN}Ver el uso de memoria RAM"
    echo -e "         ${YELLOW}[22]${RED} uptime ${NC} - ${GREEN}Ver tiempo de actividad del sistema"
    echo -e "         ${YELLOW}[23]${RED} whoami ${NC} - ${GREEN}Ver el usuario actual"
    echo -e "         ${YELLOW}[24]${RED} hostname -I ${NC} - ${GREEN}Ver la dirección IP del equipo"
    echo -e "         ${YELLOW}[25]${RED} ip a ${NC} - ${GREEN}Ver información detallada de red"
    echo -e "         ${YELLOW}[26]${RED} netstat -tulnp ${NC} - ${GREEN}Ver puertos abiertos y servicios en ejecución"
    echo -e "         ${YELLOW}[27]${RED} ss -tulnp ${NC} - ${GREEN}Alternativa moderna a netstat para ver puertos abiertos"
    echo -e "         ${YELLOW}[28]${RED} ping -c 4 google.com ${NC} - ${GREEN}Comprobar conectividad a Internet"
    echo -e "         ${YELLOW}[29]${RED} traceroute google.com ${NC} - ${GREEN}Ver la ruta que sigue un paquete hasta Google"
    echo -e "         ${YELLOW}[30]${RED} curl -I https://google.com ${NC} - ${GREEN}Ver encabezados de respuesta HTTP"
    echo -e "         ${YELLOW}[31]${RED} wget https://example.com/file.zip ${NC} - ${GREEN}Descargar un archivo con wget"
    echo -e "         ${YELLOW}[32]${RED} curl -O https://example.com/file.zip ${NC} - ${GREEN}Descargar un archivo con curl"
    echo -e "         ${YELLOW}[33]${RED} ls -lh ${NC} - ${GREEN}Listar archivos con tamaños legibles"
    echo -e "         ${YELLOW}[34]${RED} du -sh * ${NC} - ${GREEN}Ver el tamaño de los directorios y archivos"
    echo -e "         ${YELLOW}[35]${RED} find / -name archivo.txt ${NC} - ${GREEN}Buscar un archivo en todo el sistema"
    echo -e "         ${YELLOW}[36]${RED} grep 'cadena' archivo.txt ${NC} - ${GREEN}Buscar una cadena dentro de un archivo"
    echo -e "         ${YELLOW}[37]${RED} sed -i 's/viejo/nuevo/g' archivo.txt ${NC} - ${GREEN}Reemplazar texto en un archivo"
    echo -e "         ${YELLOW}[38]${RED} awk '{print \$1}' archivo.txt ${NC} - ${GREEN}Extraer la primera columna de un archivo"
    echo -e "         ${YELLOW}[39]${RED} chmod +x script.sh ${NC} - ${GREEN}Hacer ejecutable un script"
    echo -e "         ${YELLOW}[40]${RED} chown usuario:grupo archivo.txt ${NC} - ${GREEN}Cambiar el propietario de un archivo"
    echo -e "         ${YELLOW}[41]${RED} df -h ${NC} - ${GREEN}Ver el espacio en disco disponible"
    echo -e "         ${YELLOW}[42]${RED} mount ${NC} - ${GREEN}Ver dispositivos montados"
    echo -e "         ${YELLOW}[43]${RED} umount /mnt/usb ${NC} - ${GREEN}Desmontar un dispositivo"
    echo -e "         ${YELLOW}[44]${RED} fdisk -l ${NC} - ${GREEN}Listar discos y particiones"
    echo -e "         ${YELLOW}[45]${RED} mkfs.ext4 /dev/sdb1 ${NC} - ${GREEN}Formatear una partición en ext4"
    echo -e "         ${YELLOW}[46]${RED} e2fsck -f /dev/sdb1 ${NC} - ${GREEN}Revisar y reparar un sistema de archivos ext4"
    echo -e "         ${YELLOW}[47]${RED} blkid ${NC} - ${GREEN}Ver UUIDs de las particiones"
    echo -e "         ${YELLOW}[48]${RED} lsblk ${NC} - ${GREEN}Mostrar estructura de particiones de los discos"
    echo -e "         ${YELLOW}[49]${RED} top ${NC} - ${GREEN}Ver procesos en ejecución en tiempo real"
    echo -e "         ${YELLOW}[50]${RED} htop ${NC} - ${GREEN}Alternativa mejorada a top (requiere instalación)"
    echo -e "         ${YELLOW}[51]${RED} ps aux ${NC} - ${GREEN}Listar todos los procesos en ejecución"
    echo -e "         ${YELLOW}[52]${RED} kill -9 PID ${NC} - ${GREEN}Forzar la detención de un proceso por su PID"
    echo -e "         ${YELLOW}[53]${RED} pkill nombre_proceso ${NC} - ${GREEN}Matar un proceso por su nombre"
    echo -e "         ${YELLOW}[54]${RED} nice -n 10 comando ${NC} - ${GREEN}Ejecutar un comando con baja prioridad"
    echo -e "         ${YELLOW}[55]${RED} renice 10 -p PID ${NC} - ${GREEN}Cambiar la prioridad de un proceso en ejecución"
    echo -e "         ${YELLOW}[56]${RED} crontab -e ${NC} - ${GREEN}Editar tareas programadas (cron jobs)"
    echo -e "         ${YELLOW}[57]${RED} crontab -l ${NC} - ${GREEN}Listar tareas programadas del usuario"
    echo -e "         ${YELLOW}[58]${RED} systemctl start servicio ${NC} - ${GREEN}Iniciar un servicio en systemd"
    echo -e "         ${YELLOW}[59]${RED} systemctl stop servicio ${NC} - ${GREEN}Detener un servicio en systemd"
    echo -e "         ${YELLOW}[60]${RED} systemctl status servicio ${NC} - ${GREEN}Ver estado de un servicio en systemd"
    echo -e "         ${YELLOW}[61]${RED} systemctl restart servicio ${NC} - ${GREEN}Reiniciar un servicio en systemd"
    echo -e "         ${YELLOW}[62]${RED} systemctl enable servicio ${NC} - ${GREEN}Habilitar un servicio para que inicie en el arranque"
    echo -e "         ${YELLOW}[63]${RED} systemctl disable servicio ${NC} - ${GREEN}Deshabilitar un servicio del arranque"
    echo -e "         ${YELLOW}[64]${RED} journalctl -xe ${NC} - ${GREEN}Ver registros detallados de systemd"
    echo -e "         ${YELLOW}[65]${RED} dmesg | tail ${NC} - ${GREEN}Ver los últimos mensajes del kernel"
    echo -e "         ${YELLOW}[66]${RED} uname -r ${NC} - ${GREEN}Mostrar la versión del kernel"
    echo -e "         ${YELLOW}[67]${RED} hostnamectl ${NC} - ${GREEN}Ver información del sistema y el hostname"
    echo -e "         ${YELLOW}[68]${RED} timedatectl ${NC} - ${GREEN}Ver y ajustar la fecha y hora del sistema"
    echo -e "         ${YELLOW}[69]${RED} hwinfo --short ${NC} - ${GREEN}Ver información de hardware (requiere instalación)"
    echo -e "         ${YELLOW}[70]${RED} lscpu ${NC} - ${GREEN}Ver información detallada del CPU"
    echo -e "         ${YELLOW}[71]${RED} lsusb ${NC} - ${GREEN}Listar dispositivos USB conectados"
    echo -e "         ${YELLOW}[72]${RED} lspci ${NC} - ${GREEN}Listar dispositivos PCI"
    echo -e "         ${YELLOW}[73]${RED} free -h ${NC} - ${GREEN}Ver memoria RAM disponible"
    echo -e "         ${YELLOW}[74]${RED} vmstat 1 10 ${NC} - ${GREEN}Monitorear uso de CPU y memoria en tiempo real"
    echo -e "         ${YELLOW}[75]${RED} iostat ${NC} - ${GREEN}Ver estadísticas de entrada/salida (requiere instalación)"
    echo -e "         ${YELLOW}[76]${RED} sar -u 1 5 ${NC} - ${GREEN}Monitorear uso de CPU en intervalos de 1 segundo"
    echo -e "         ${YELLOW}[77]${RED} ip a ${NC} - ${GREEN}Ver direcciones IP y adaptadores de red"
    echo -e "         ${YELLOW}[78]${RED} ip r ${NC} - ${GREEN}Ver tabla de rutas de red"
    echo -e "         ${YELLOW}[79]${RED} ss -tulnp ${NC} - ${GREEN}Ver puertos abiertos y procesos asociados"
    echo -e "         ${YELLOW}[80]${RED} netstat -tulnp ${NC} - ${GREEN}Ver conexiones de red activas (requiere instalación)"
    echo -e "         ${YELLOW}[81]${RED} ping -c 4 google.com ${NC} - ${GREEN}Enviar 4 paquetes de ping a Google"
    echo -e "         ${YELLOW}[82]${RED} traceroute google.com ${NC} - ${GREEN}Ver la ruta de los paquetes hasta Google (requiere instalación)"
    echo -e "         ${YELLOW}[83]${RED} dig google.com ${NC} - ${GREEN}Obtener información DNS de un dominio (requiere instalación)"
    echo -e "         ${YELLOW}[84]${RED} nslookup google.com ${NC} - ${GREEN}Consultar registros DNS de un dominio"
    echo -e "         ${YELLOW}[85]${RED} wget URL ${NC} - ${GREEN}Descargar un archivo desde una URL"
    echo -e "         ${YELLOW}[86]${RED} curl -O URL ${NC} - ${GREEN}Descargar un archivo desde una URL con curl"
    echo -e "         ${YELLOW}[87]${RED} scp archivo usuario@servidor:/ruta ${NC} - ${GREEN}Copiar un archivo a un servidor remoto con SCP"
    echo -e "         ${YELLOW}[88]${RED} rsync -avz origen destino ${NC} - ${GREEN}Sincronizar archivos de manera eficiente con rsync"
    echo -e "         ${YELLOW}[89]${RED} ssh usuario@servidor ${NC} - ${GREEN}Conectar a un servidor remoto vía SSH"
    echo -e "         ${YELLOW}[90]${RED} ssh-keygen -t rsa ${NC} - ${GREEN}Generar claves SSH para autenticación"
    echo -e "         ${YELLOW}[91]${RED} ssh-copy-id usuario@servidor ${NC} - ${GREEN}Copiar clave pública SSH a un servidor remoto"
    echo -e "         ${YELLOW}[92]${RED} whoami ${NC} - ${GREEN}Mostrar el usuario actual"
    echo -e "         ${YELLOW}[93]${RED} uptime ${NC} - ${GREEN}Mostrar el tiempo que lleva encendido el sistema"
    echo -e "         ${YELLOW}[94]${RED} history ${NC} - ${GREEN}Mostrar historial de comandos ejecutados"
    echo -e "         ${YELLOW}[95]${RED} alias ll='ls -lah' ${NC} - ${GREEN}Crear un alias para un comando"
    echo -e "         ${YELLOW}[96]${RED} unalias ll ${NC} - ${GREEN}Eliminar un alias creado"
    echo -e "         ${YELLOW}[97]${RED} chmod +x script.sh ${NC} - ${GREEN}Dar permisos de ejecución a un script"
    echo -e "         ${YELLOW}[98]${RED} chown usuario:grupo archivo ${NC} - ${GREEN}Cambiar el propietario de un archivo"
    echo -e "         ${YELLOW}[99]${RED} usermod -aG grupo usuario ${NC} - ${GREEN}Agregar un usuario a un grupo"
    echo -e "         ${YELLOW}[100]${RED} passwd ${NC} - ${GREEN}Cambiar la contraseña del usuario actual"

    echo -e "\n         ${YELLOW}[0] ⮹ Volver\n"
    echo -e "${CYAN}    ____________________________________________________________________\n${YELLOW}"

    read -p "⭕ Selecciona una opción: " opt
    run_command $opt
}

# Función para ejecutar el comando seleccionado
run_command() {
    case $1 in
        0) exit 0 ;;
        1) apt update ;;
        2) apt upgrade -y ;;
        3) apt install apache2 -y ;;
        4) apt install nginx -y ;;
        5) apt install mysql-server -y ;;
        6) apt install postgresql -y ;;
        7) apt install php libapache2-mod-php -y ;;
        8) ufw enable ;;
        9) ufw status ;;
        10) ufw allow ssh ;;
        11) ufw allow http ;;
        12) ufw allow https ;;
        13) systemctl restart apache2 ;;
        14) systemctl restart nginx ;;
        15) systemctl restart mysql ;;
        16) systemctl restart postgresql ;;
        17) df -h ;;
        18) top ;;
        19) ps aux --sort=-%mem | head ;;
        20) ps aux --sort=-%cpu | head ;;
        21) apt clean ;;
        22) apt autoremove -y ;;
        23) curl ifconfig.me ;;
        24) hostname -I ;;
        25) free -h ;;
        26) uname -a ;;
        27) lscpu ;;
        28) cat /proc/meminfo ;;
        29) lsblk ;;
        30) lspci | grep -i network ;;
        31) ip a ;;
        32) nano /etc/netplan/01-netcfg.yaml ;;
        33) systemctl restart networking ;;
        34) journalctl -xe ;;
        35) tail -f /var/log/apache2/error.log ;;
        36) tail -f /var/log/nginx/error.log ;;
        37) tail -f /var/log/mysql/error.log ;;
        38) tail -f /var/log/postgresql/postgresql-*.log ;;
        39) du -sh /ruta/del/directorio ;;
        40) find / -type f -size +100M ;;
        41) uname -r ;;
        42) lshw ;;
        43) mount /dev/sdX /mnt ;;
        44) umount /mnt ;;
        45) nano /etc/fstab ;;
        46) adduser nombre_usuario ;;
        47) deluser nombre_usuario ;;
        48) passwd nombre_usuario ;;
        49) usermod -aG sudo nombre_usuario ;;
        50) cat /etc/group ;;
        51) cat /etc/passwd ;;
        52) df -i ;;
        53) iftop ;;
        54) ss -s ;;
        55) netstat -tulnp ;;
        56) apt install docker.io -y ;;
        57) systemctl start docker ;;
        58) systemctl enable docker ;;
        59) docker ps ;;
        60) docker ps -a ;;
        61) docker stop nombre_contenedor ;;
        62) docker rm nombre_contenedor ;;
        63) apt install python3 -y ;;
        64) apt install python3-pip -y ;;
        65) pip3 install jupyter ;;
        66) python3 -m venv nombre_entorno ;;
        67) source nombre_entorno/bin/activate ;;
        68) deactivate ;;
        69) apt install nodejs -y ;;
        70) apt install npm -y ;;
        71) node -v ;;
        72) npm -v ;;
        73) echo '<!DOCTYPE html><html><body><h1>Hola Mundo</h1></body></html>' > /var/www/html/index.html ;;
        74) echo '<?php phpinfo(); ?>' > /var/www/html/info.php ;;
        75) reboot ;;
        76) shutdown now ;;
        77) crontab -e ;;
        78) crontab -l ;;
        79) tail -f /var/log/syslog | grep cron ;;
        80) apt install git -y ;;
        81) git config --global user.name 'nombre' ;;
        82) git config --global user.email 'correo@ejemplo.com' ;;
        83) git clone url_del_repositorio ;;
        84) git status ;;
        85) git log ;;
        86) git checkout -b nombre_rama ;;
        87) git checkout nombre_rama ;;
        88) git merge nombre_rama ;;
        89) apt install openssh-server -y ;;
        90) systemctl start ssh ;;
        91) systemctl enable ssh ;;
        92) journalctl -u ssh ;;
        93) apt install fail2ban -y ;;
        94) systemctl start fail2ban ;;
        95) systemctl enable fail2ban ;;
        96) fail2ban-client status ;;
        97) apt install certbot python3-certbot-apache -y ;;
        98) certbot --apache ;;
        99) certbot renew --dry-run ;;
        100) ss -tnlp ;;
        *) echo "Opción no válida. Inténtelo de nuevo." ;;
    esac
    # echo "|________________________-FIN-______________________________|"
}

# Bucle infinito para mostrar el menú hasta que el usuario elija salir
while true; do        
    show_menu
done

