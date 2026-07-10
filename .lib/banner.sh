#!/bin/bash

cabecera(){

linea

echo -e "${YELLOW} 🏠 Host..... ${CYAN}$(hostname)"
echo -e "${YELLOW} 👤 Usuario.. ${CYAN}$USER"
echo -e "${YELLOW} ❄️  Kernel... ${CYAN}$(uname -r)"
echo -e "${YELLOW} 🔢 IP....... ${CYAN}$(hostname -I | awk '{print $1}')"

if [[ -n "$SSH_CONNECTION" ]]
then
    echo -e "${RED} 🏢SSH${YELLOW}"
else
    echo -e "${GREEN} 🏡Local${YELLOW}"
fi

linea

}
