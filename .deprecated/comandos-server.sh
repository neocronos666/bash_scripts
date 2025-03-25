#!/bin/bash

# Título y decoración ASCII
clear
echo ".==========================================================.."
echo "|                                                          ||"
echo "|       *** HERRAMIENTA DE GESTION DE SERVIDOR ***         ||"
echo "|                                                          ||"
echo "|__________________________________________________________||"
echo "|               100 Comando utiles para linux              ||"
echo "|__________________________________________________________||"
echo "|               *** Selecciones un comando: ***            ||"
echo "|__________________________________________________________|"

# Función para mostrar el menú
show_menu() {
    echo ""
    echo "  0) Salir"
    echo "  1) Actualizar lista de paquetes (apt update)"
    echo "  2) Actualizar todos los paquetes (apt upgrade)"
    echo "  3) Instalar servidor web Apache (apt install apache2)"
    echo "  4) Instalar servidor web Nginx (apt install nginx)"
    echo "  5) Instalar MySQL (apt install mysql-server)"
    echo "  6) Instalar PostgreSQL (apt install postgresql)"
    echo "  7) Instalar PHP (apt install php libapache2-mod-php)"
    echo "  8) Configurar el firewall con UFW (ufw enable)"
    echo "  9) Ver el estado del firewall (ufw status)"
    echo " 10) Permitir tráfico SSH (ufw allow ssh)"
    echo " 11) Permitir tráfico HTTP (ufw allow http)"
    echo " 12) Permitir tráfico HTTPS (ufw allow https)"
    echo " 13) Reiniciar servidor Apache (systemctl restart apache2)"
    echo " 14) Reiniciar servidor Nginx (systemctl restart nginx)"
    echo " 15) Reiniciar servidor MySQL (systemctl restart mysql)"
    echo " 16) Reiniciar servidor PostgreSQL (systemctl restart postgresql)"
    echo " 17) Ver el uso de disco (df -h)"
    echo " 18) Ver procesos activos (top)"
    echo " 19) Ver los 10 procesos que más consumen memoria (ps aux --sort=-%mem | head)"
    echo " 20) Ver los 10 procesos que más consumen CPU (ps aux --sort=-%cpu | head)"
    echo " 21) Limpiar caché de apt (apt clean)"
    echo " 22) Limpiar paquetes huérfanos (apt autoremove)"
    echo " 23) Ver la IP pública del servidor (curl ifconfig.me)"
    echo " 24) Ver la IP privada del servidor (hostname -I)"
    echo " 25) Monitorear el uso de memoria (free -h)"
    echo " 26) Ver información del sistema (uname -a)"
    echo " 27) Ver información de la CPU (lscpu)"
    echo " 28) Ver información de la memoria (cat /proc/meminfo)"
    echo " 29) Ver información del disco (lsblk)"
    echo " 30) Ver información de la tarjeta de red (lspci | grep -i network)"
    echo " 31) Ver interfaces de red (ip a)"
    echo " 32) Configurar IP estática (nano /etc/netplan/01-netcfg.yaml)"
    echo " 33) Reiniciar servicio de red (systemctl restart networking)"
    echo " 34) Ver registros del sistema (journalctl -xe)"
    echo " 35) Ver registros de Apache (tail -f /var/log/apache2/error.log)"
    echo " 36) Ver registros de Nginx (tail -f /var/log/nginx/error.log)"
    echo " 37) Ver registros de MySQL (tail -f /var/log/mysql/error.log)"
    echo " 38) Ver registros de PostgreSQL (tail -f /var/log/postgresql/postgresql-*.log)"
    echo " 39) Ver espacio ocupado por directorio (du -sh /ruta/del/directorio)"
    echo " 40) Buscar archivos grandes (find / -type f -size +100M)"
    echo " 41) Ver detalles del kernel (uname -r)"
    echo " 42) Ver detalles del hardware (lshw)"
    echo " 43) Montar una unidad (mount /dev/sdX /mnt)"
    echo " 44) Desmontar una unidad (umount /mnt)"
    echo " 45) Configurar montajes automáticos (nano /etc/fstab)"
    echo " 46) Crear un usuario (adduser nombre_usuario)"
    echo " 47) Eliminar un usuario (deluser nombre_usuario)"
    echo " 48) Cambiar contraseña de usuario (passwd nombre_usuario)"
    echo " 49) Añadir usuario a grupo sudo (usermod -aG sudo nombre_usuario)"
    echo " 50) Ver grupos del sistema (cat /etc/group)"
    echo " 51) Ver usuarios del sistema (cat /etc/passwd)"
    echo " 52) Comprobar espacio libre en inodos (df -i)"
    echo " 53) Monitorizar tráfico de red (iftop)"
    echo " 54) Monitorizar el estado de los sockets (ss -s)"
    echo " 55) Ver conexiones de red activas (netstat -tulnp)"
    echo " 56) Instalar Docker (apt install docker.io)"
    echo " 57) Iniciar Docker (systemctl start docker)"
    echo " 58) Habilitar Docker al inicio (systemctl enable docker)"
    echo " 59) Ver contenedores Docker activos (docker ps)"
    echo " 60) Ver todos los contenedores Docker (docker ps -a)"
    echo " 61) Parar un contenedor Docker (docker stop nombre_contenedor)"
    echo " 62) Eliminar un contenedor Docker (docker rm nombre_contenedor)"
    echo " 63) Instalar Python (apt install python3)"
    echo " 64) Instalar pip para Python (apt install python3-pip)"
    echo " 65) Instalar Jupyter Notebook (pip3 install jupyter)"
    echo " 66) Crear un entorno virtual en Python (python3 -m venv nombre_entorno)"
    echo " 67) Activar entorno virtual (source nombre_entorno/bin/activate)"
    echo " 68) Desactivar entorno virtual (deactivate)"
    echo " 69) Instalar Node.js (apt install nodejs)"
    echo " 70) Instalar npm (apt install npm)"
    echo " 71) Verificar versión de Node.js (node -v)"
    echo " 72) Verificar versión de npm (npm -v)"
    echo " 73) Crear un archivo HTML de ejemplo"                
    echo " 74) Crear un archivo PHP de ejemplo (echo '<?php phpinfo(); ?>' > /var/www/html/info.php)"
    echo " 75) Reiniciar sistema (reboot)"
    echo " 76) Apagar sistema (shutdown now)"
    echo " 77) Configurar tareas programadas con crontab (crontab -e)"
    echo " 78) Verificar tareas programadas con crontab (crontab -l)"
    echo " 79) Ver logs del cron (tail -f /var/log/syslog | grep cron)"
    echo " 80) Instalar Git (apt install git)"
    echo " 81) Configurar nombre de usuario en Git (git config --global user.name 'nombre')"
    echo " 82) Configurar email en Git (git config --global user.email 'correo@ejemplo.com')"
    echo " 83) Clonar un repositorio Git (git clone url_del_repositorio)"
    echo " 84) Ver estado de un repositorio Git (git status)"
    echo " 85) Ver historial de commits en Git (git log)"
    echo " 86) Crear una rama en Git (git checkout -b nombre_rama)"
    echo " 87) Cambiar de rama en Git (git checkout nombre_rama)"
    echo " 88) Fusionar ramas en Git (git merge nombre_rama)"
    echo " 89) Instalar OpenSSH (apt install openssh-server)"
    echo " 90) Iniciar servicio SSH (systemctl start ssh)"
    echo " 91) Habilitar SSH en el arranque (systemctl enable ssh)"
    echo " 92) Ver logs de SSH (journalctl -u ssh)"
    echo " 93) Instalar Fail2Ban (apt install fail2ban)"
    echo " 94) Iniciar Fail2Ban (systemctl start fail2ban)"
    echo " 95) Habilitar Fail2Ban en el arranque (systemctl enable fail2ban)"
    echo " 96) Verificar estado de Fail2Ban (fail2ban-client status)"
    echo " 97) Instalar Certbot para HTTPS (apt install certbot python3-certbot-apache)"
    echo " 98) Generar certificado SSL con Certbot (certbot --apache)"
    echo " 99) Verificar renovación automática de Certbot (certbot renew --dry-run)"
    echo "100) Listar conexiones establecidas (ss -tnlp)"

    echo " __________________________________________________________"    
    echo "|                                                          |"
    echo "| Seleccione un comando (0-100):                           |"   
    read opt
    echo "|________________________-FIN-_____________________________|"
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
    echo "|________________________-FIN-______________________________|"
}

# Bucle infinito para mostrar el menú hasta que el usuario elija salir
while true; do        
    show_menu
done

