#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.lib/colores.sh"
source "$SCRIPT_DIR/.lib/comunes.sh"
source "$SCRIPT_DIR/.lib/banner.sh"

VERSION="0.1"
#### FUNCIONES ####
mostrar_estado(){
echo "test"
}

mostrar_discos(){
echo "test"
}

mostrar_servicios(){
echo "test"
}

mostrar_docker(){
echo "test"
}

mostrar_red(){
echo "test"
}

mostrar_proxmox(){
echo "test"
}

buscar_journal(){
echo "test"
}

permisos_rapidos(){
echo "test"
}

montajes(){
echo "test"
}

apagar_maquina(){
echo "test"
}
###### MENU ######
menu(){

echo
echo "1) Estado general"
echo "2) Discos y volúmenes"
echo "3) Servicios"
echo "4) Docker"
echo "5) Red"
echo "6) Proxmox"
echo "7) Journal"
echo "8) Permisos rápidos"
echo "9) Montajes"
echo "10) Apagar máquina"

echo
echo "0) Volver"

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

done
