#!/bin/bash

linea(){

#printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '━'
printf '━%.0s' $(seq 1 "${COLUMNS:-80}"); echo

}

pausa(){

echo
read -n1 -rsp $'✳ Presione una tecla para continuar...\n'

}

confirmacion(){

read -rp "¿Continuar? [s/N] " RESP

[[ "$RESP" =~ ^[sS]$ ]]

}
