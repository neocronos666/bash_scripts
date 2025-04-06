#!/bin/bash

# Script para herramientas de auditoría de seguridad en redes

while true; do
    echo "==============================="
    echo "     Menú de Auditoría de Red   "
    echo "==============================="
    echo "1. Escaneo de puertos con netstat"
    echo "2. Escaneo de puertos con ss"
    echo "3. Escaneo de red con nmap"
    echo "4. Comprobar conexiones activas con lsof"
    echo "5. Analizar tráfico de red con tcpdump"
    echo "0. Salir"
    echo "==============================="
    echo -n "Seleccione una opción: "
    read opcion

    case $opcion in
        1)
            echo "Ejecutando netstat para mostrar puertos abiertos..."
            sudo netstat -tuln
            ;;
        2)
            echo "Ejecutando ss para mostrar conexiones activas..."
            sudo ss -tuln
            ;;
        3)
            echo "Ejecutando nmap para un escaneo de red..."
            echo -n "Ingrese la IP o dirección que desea escanear: "
            read ip
            sudo nmap -sT $ip
            ;;
        4)
            echo "Ejecutando lsof para verificar conexiones activas..."
            sudo lsof -i
            ;;
        5)
            clear
            echo "Interfases"
            ip a
            echo "Ejecutando tcpdump para capturar tráfico de red..."
            echo -n "Ingrese la interfaz de red (ejemplo: eth0): "
            read interfaz
            sudo tcpdump -i $interfaz
            ;;
        0)
            echo "Saliendo del programa. ¡Hasta pronto!"
            break
            ;;
        *)
            echo "Opción no válida. Por favor, intente nuevamente."
            ;;
    esac
    echo "Presione Enter para continuar..."
    read
done

