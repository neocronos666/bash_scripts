#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.lib/colores.sh"
source "$SCRIPT_DIR/.lib/comunes.sh"
source "$SCRIPT_DIR/.lib/banner.sh"

VERSION="0.1"
#### FUNCIONES ####
mostrar_estado() {

    clear

    #cabecera

    echo
    echo -e "${CYAN} ########### Estado general########### ${NC}"

    linea

    echo -e "${GREEN}Hostname:${NC}"
    hostnamectl --static

    echo
    echo -e "${GREEN}Sistema:${NC}"
    grep PRETTY_NAME /etc/os-release | cut -d '"' -f2

    echo
    echo -e "${GREEN}Kernel:${NC}"
    uname -r

    echo
    echo -e "${GREEN}Uptime:${NC}"
    uptime -p

    echo
    echo -e "${GREEN}CPU:${NC}"
    lscpu | grep "Model name" | cut -d ':' -f2

    echo
    echo -e "${GREEN}RAM:${NC}"
    free -h

    echo
    echo -e "${GREEN}Disco:${NC}"
    df -h /

    echo
    echo -e "${GREEN}IP Local:${NC}"
    hostname -I

    echo
    echo -e "${GREEN}IP Pública:${NC}"
    curl -s ifconfig.me
    echo
  
    echo 
    echo -e "${GREEN}Docker:${NC}"

    if command -v docker >/dev/null
    then
        docker ps --format "table {{.Names}}\t{{.Status}}"
    else
        echo "No instalado."
    fi

    echo
    echo -e "${GREEN}Proxmox:${NC}"

    if command -v pveversion >/dev/null
    then
        echo "Instalado"

        qm list 2>/dev/null
        pct list 2>/dev/null
    else
        echo "No instalado."
    fi
    linea
    echo -e "${GREEN}########### Servicios fallidos: ###########${NC}"

    if systemctl --failed --no-legend | grep . >/dev/null
    then
        systemctl --failed --no-pager
    else
        echo "Ninguno."
    fi

    
    linea
    #pausa

    

}

mostrar_discos(){
    clear
    echo
    echo -e "${CYAN} ########### 🍕 Particiones ########### ${NC}"
    echo
    blkid
#    echo -e "${YELLOW}"
    linea
    
    echo
    echo -e "${CYAN} ########### 💽 Discos ########### ${NC}"
    echo
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL | column -t
#    echo -e "${YELLOW}"
    linea

    echo
    echo -e "${CYAN} ########### 📊 Espacio Libre ########### ${NC}"
    echo
    df -h
#    echo -e "${YELLOW}"
    linea    
    echo
    echo -e "${CYAN} ########### 📑 Puntos de montaje ########### ${NC}"
    echo
    mount | grep "^/dev"
#    echo -e "${YELLOW}"
    linea        
}

mostrar_servicios(){
    clear
    echo
    echo -e "${CYAN} ########### 🏃Servicios Corriendo ########### ${NC}"
    echo
    systemctl list-units \
    --type=service \
    --state=running
    linea
    echo    
    echo -e "${CYAN} ########### 🙅Servicios Fallidos ########### ${NC}"
    echo
    systemctl --failed

}

mostrar_docker(){
    clear
    echo
    echo -e "${CYAN} ########### 🐳 Docker ########### ${NC}"
    echo
    docker ps -a \
    --format \
    'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

    echo

    docker ps -a

    echo

    docker images

    echo

    docker compose ls 2>/dev/null
}

mostrar_red(){
    clear
    echo
    echo -e "${CYAN} ########### 🌎 RED ########### ${NC}"
    echo
    ip a

    echo

    ip r

    echo

    arp -a

    echo

    hostname -I

    echo

    curl -s ifconfig.me
}

mostrar_proxmox(){
    clear
    echo
    echo -e "${CYAN} ########### 🎪 PROXMOX ########### ${NC}"
    echo

    if command -v pveversion >/dev/null
    then

    pveversion

    echo

    qm list

    echo

    pct list

    fi
}

buscar_journal(){
    clear
    echo
    echo -e "${CYAN} ########### 📃 JOURNAL ########### ${NC}"
    echo
    read -rp "[ 👓 Buscar]: " BUSCAR

    journalctl -xe \
    | grep -i "$BUSCAR"
}

permisos_rapidos(){

    while true
    do

    clear

    cabecera

    echo
    echo "1) chmod +x"
    echo "2) chown"
    echo "3) Crear usuario"
    echo "4) Agregar usuario a sudo"
    echo
    echo "0) Volver"
    echo

    read -rp "⭕ Opción: " OP

    case "$OP" in

    1)

    read -rp "Archivo: " ARCHIVO

    chmod +x "$ARCHIVO"

    ;;

    2)

    read -rp "Archivo: " ARCHIVO
    read -rp "Usuario:Grupo: " OWNER

    sudo chown "$OWNER" "$ARCHIVO"

    ;;

    3)

    read -rp "Nombre usuario: " NUEVO

    sudo adduser "$NUEVO"

    ;;

    4)

    read -rp "Usuario: " NUEVO

    sudo usermod -aG sudo "$NUEVO"

    ;;

    0)

    return

    ;;

    *)

    ;;

    esac

    pausa

    done
}




montajes(){
    while true
    do

    clear

    cabecera

    echo
    echo "1) Ver discos"
    echo "2) Ver montajes"
    echo "3) Montar"
    echo "4) Desmontar"
    echo
    echo "0) Volver"

    echo

    read -rp "⭕ Opción: " OP

    case "$OP" in

    1)

    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL

    ;;

    2)

    mount | grep "^/dev"

    ;;

    3)

    read -rp "Dispositivo: " DEV
    read -rp "Punto montaje: " DEST

    sudo mount "$DEV" "$DEST"

    ;;

    4)

    read -rp "Punto montaje o dispositivo: " DEV

    sudo umount "$DEV"

    ;;

    0)

    return

    ;;

    *)

    ;;

    esac

    pausa

    done

}


apagar_maquina(){
    clear

    #cabecera

    echo
    linea
    linea
    echo -e "${RED}"
    echo "⚠ ##### APAGAR MAQUINA #####"
    echo -e "${NC}"
    linea
    linea
    echo
    read -rp "¿Seguro? [s/N] " RESP

    [[ ! "$RESP" =~ ^[sS]$ ]] && return

    echo
    read -rp "Sos medio boludo y se supone que un server no se apaga, asi que escribí APAGAR para confirmar: " RESP2

    [[ "$RESP2" != "APAGAR" ]] && return

    sudo shutdown now

}

###### MENU ######
menu(){

echo
echo -e "${YELLOW}    [1] ${GREEN}Estado general"
echo -e "${YELLOW}    [2] ${GREEN}Discos y volúmenes"
echo -e "${YELLOW}    [3] ${GREEN}Servicios"
echo -e "${YELLOW}    [4] ${GREEN}Docker"
echo -e "${YELLOW}    [5] ${GREEN}Red"
echo -e "${YELLOW}    [6] ${GREEN}Proxmox"
echo -e "${YELLOW}    [7] ${GREEN}Journal"
echo -e "${YELLOW}    [8] ${GREEN}Permisos rápidos"
echo -e "${YELLOW}    [9] ${GREEN}Montajes"
echo -e "${YELLOW}    [10] ${GREEN}Apagar máquina"

echo
echo -e "${YELLOW}      [0] ${GREEN}Volver${YELLOW}"

echo

read -rp "⭕ Opción: " OPCION

}

#### MAIN ####
while true
do

clear

cabecera

menu

case "$OPCION" in

1) mostrar_estado ;;
2) mostrar_discos ;;
3) mostrar_servicios ;;
4) mostrar_docker ;;
5) mostrar_red ;;
6) mostrar_proxmox ;;
7) buscar_journal ;;
8) permisos_rapidos ;;
9) montajes ;;
10) apagar_maquina ;;

0) exit 0 ;;

*) ;;
esac
pausa
done
