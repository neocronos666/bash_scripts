#!/bin/bash

set -e

echo "==> Configurando shell..."

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

touch ~/.bashrc

#
# Eliminar configuraciones anteriores
#

sed -i \
'/# >>> neocronos aliases >>>/,/# <<< neocronos aliases <<</d' \
~/.bashrc

sed -i \
'/# >>> neocronos banner >>>/,/# <<< neocronos banner <<</d' \
~/.bashrc

cat >> ~/.bashrc <<'EOF'

# >>> neocronos aliases >>>

#
# Listados
#

alias ls='ls -lh --group-directories-first --color=auto'
alias lsa='ls -lah --group-directories-first --color=auto'

#
# Navegación
#

alias cd1='cd ..'
alias cd2='cd ../..'
alias cd3='cd ../../..'

#
# Git
#

alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate --all'

#
# Sistema
#

alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt remove'

# <<< neocronos aliases <<<


# >>> neocronos banner >>>

__nc_shell_banner() {

    local reset="\e[0m"

    local blue="\e[34m"
    local cyan="\e[36m"
    local green="\e[32m"
    local yellow="\e[33m"
    local magenta="\e[35m"
    local gray="\e[90m"

    local host
    local ip
    local wifi
    local ssh

    host=$(hostname)

    ip=$(
        ip route get 1.1.1.1 2>/dev/null \
        | awk '{print $7; exit}'
    )

    [[ -z "$ip" ]] && ip="sin red"

    wifi=$(iwgetid -r 2>/dev/null)

    [[ -z "$wifi" ]] && wifi="desconectado"

    if [[ -n "$SSH_CLIENT" ]]; then

        ssh=$(echo "$SSH_CLIENT" | awk '{print $1}')

    else

        ssh="local"

    fi


    echo -e ""

    echo -e "${gray}┌──────────────────────────────────────────┐${reset}"
    echo -e "${gray}│${reset} ${green}󰀄 ${USER}@${host}${reset}"

    echo -e "${gray}│${reset} ${cyan}󰩟 LAN :${reset} ${ip}"

    echo -e "${gray}│${reset} ${blue} WIFI:${reset} ${wifi}"

    echo -e "${gray}│${reset} ${magenta}󰍹 SSH :${reset} ${ssh}"

    echo -e "${gray}├──────────────────────────────────────────┤${reset}"

    echo -e "${gray}│${reset} ${yellow}󰘬 Git${reset}"
    echo -e "${gray}│${reset}    ${green}gs${reset}       git status"
    echo -e "${gray}│${reset}    ${green}gl${reset}       historial gráfico"

    echo -e "${gray}│${reset}"

    echo -e "${gray}│${reset} ${blue}󰉋 Navegación${reset}"
    echo -e "${gray}│${reset}    ${green}cd1${reset}      subir 1 nivel"
    echo -e "${gray}│${reset}    ${green}cd2${reset}      subir 2 niveles"
    echo -e "${gray}│${reset}    ${green}cd3${reset}      subir 3 niveles"

    echo -e "${gray}│${reset}"

    echo -e "${gray}│${reset} ${magenta}󰇚 Sistema${reset}"
    echo -e "${gray}│${reset}    ${green}update${reset}  actualizar paquetes"
    echo -e "${gray}│${reset}    ${green}install${reset} instalar paquete"
    echo -e "${gray}│${reset}    ${green}remove${reset}  eliminar paquete"

    echo -e "${gray}└──────────────────────────────────────────┘${reset}"
    echo
}

__nc_shell_banner

# <<< neocronos banner <<<

EOF


echo
echo "Shell configurada."

read -rp "¿Ejecutar setup-prompt.sh? [s/N]: " RESP

case "$RESP" in

    s|S|si|SI)

        if [[ -f "$SCRIPT_DIR/setup-prompt.sh" ]]; then

            bash "$SCRIPT_DIR/setup-prompt.sh"

        else

            echo
            echo "No se encontró setup-prompt.sh"

        fi
    ;;

esac


echo
echo "Recargando shell..."
sleep 1

exec bash
