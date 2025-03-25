#!/bin/bash
echo ",---------------------------------."
echo "|    Testeo de falta de Ram       |"      
echo "'---------------------------------´"
echo ""
echo "1. Log de Kills del kernel"
grep -i kill /var/log/messages*
echo "--------------------------"
echo ""
echo "2. Log de out of memory del sistema"
grep -i 'out of memory' /var/log/syslog
echo "--------------------------"
echo ""
echo "3. Log de out of memory del kernel"
grep -i 'out of memory' /var/log/kern.log
echo "--------------------------------"
echo ""
echo "4. Mensajes del kernel con out of memory"
dmesg | grep -i 'out of memory'
echo "----------------------------------------"
echo ""
echo "Presione ENTER para salir"
read
