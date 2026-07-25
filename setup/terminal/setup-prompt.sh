#!/bin/bash

set -e

FONT_NAME="JetBrainsMono Nerd Font Mono"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
FONT_SHA256="${JETBRAINS_MONO_SHA256:-}"

echo "==> Verificando fuente..."

if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then

    echo "==> Instalando JetBrainsMono Nerd Font..."

    if [[ -z "$FONT_SHA256" ]]; then
        echo "Falta JETBRAINS_MONO_SHA256."
        echo "Obtenga el checksum de la versión indicada, verifíquelo en la fuente"
        echo "oficial y vuelva a ejecutar:"
        echo "  JETBRAINS_MONO_SHA256=<sha256> $0"
        exit 1
    fi

    TMP=$(mktemp -d)
    trap 'rm -rf -- "$TMP"' EXIT

    wget -q \
        -O "$TMP/JetBrainsMono.zip" \
        "$FONT_URL"

    printf '%s  %s\n' "$FONT_SHA256" "$TMP/JetBrainsMono.zip" |
        sha256sum --check --status

    mkdir -p "$FONT_DIR"

    unzip -qo \
        "$TMP/JetBrainsMono.zip" \
        -d "$FONT_DIR"

    fc-cache -fv >/dev/null

    rm -rf -- "$TMP"
    trap - EXIT

    echo "Fuente instalada."

else
    echo "Fuente ya instalada."
fi

mkdir -p ~/.config/neocronos

cat > ~/.config/neocronos/prompt.conf <<EOF
FONT_NAME=$FONT_NAME
EOF

echo "==> Instalando prompt..."

touch ~/.bashrc

sed -i \
'/# >>> neocronos prompt >>>/,/# <<< neocronos prompt <<</d' \
~/.bashrc

cat >> ~/.bashrc <<'EOF'

# >>> neocronos prompt >>>

export NEOCRONOS_FONT="JetBrainsMono Nerd Font Mono"

__nc_cmd_start=$SECONDS
__nc_last_elapsed=0


__nc_preexec() {

    case "$BASH_COMMAND" in
        __nc_*|PROMPT_COMMAND*|history*)
            return
        ;;
    esac

    __nc_cmd_start=$SECONDS
}


__nc_precmd() {

    __nc_last_elapsed=$((SECONDS-__nc_cmd_start))
}


if [[ -z "$(trap -p DEBUG)" ]]; then
    trap '__nc_preexec' DEBUG
fi


__nc_git() {

    git rev-parse --is-inside-work-tree \
        &>/dev/null || return

    git branch --show-current 2>/dev/null
}


__nc_conda() {

    [[ -z "$CONDA_DEFAULT_ENV" ]] && return
    [[ "$CONDA_DEFAULT_ENV" == "base" ]] && return

    echo "$CONDA_DEFAULT_ENV"
}


__nc_elapsed() {

    local delta=$__nc_last_elapsed

    printf '%02d:%02d:%02d' \
        $((delta/3600)) \
        $((delta%3600/60)) \
        $((delta%60))
}


__nc_prompt() {

    __nc_precmd

    local cols=${COLUMNS:-$(tput cols)}

    local reset="\[\e[0m\]"
    local green="\[\e[32m\]"
    local red="\[\e[31m\]"
    local cyan="\[\e[36m\]"
    local blue="\[\e[34m\]"
    local magenta="\[\e[35m\]"
    local yellow="\[\e[33m\]"
    local gray="\[\e[90m\]"

    local user_color="$green"
    local host_color="$cyan"

    [[ $EUID -eq 0 ]] && user_color="$red"

    [[ -n "$SSH_CONNECTION" ]] && \
        host_color="$magenta"



    local git
    local conda
    local elapsed

    git=$(__nc_git)
    conda=$(__nc_conda)
    elapsed=$(__nc_elapsed)
    
    local ip

    ip=$(ip route get 1.1.1.1 2>/dev/null \
    | awk '{print $7; exit}')

    [[ -z "$ip" ]] && ip="sin-red"

    local host="${HOSTNAME:-$(hostname)}"
    local pwd_display="${PWD/#$HOME/\~}"


    ###################################
    # LINEA 1: ┌────────── ⏱ HH:MM:SS
    ###################################

    local line1_plain="┌"
    local fill_size

    if [[ -n "$elapsed" ]]; then

        local right="⏱ ${elapsed}"

        fill_size=$((cols - 1 - ${#right} - 1))

    else

        fill_size=$((cols - 1))
    fi

    (( fill_size < 1 )) && fill_size=1

    local fill

    printf -v fill '%*s' "$fill_size" ''
    fill=${fill// /─}

    local line1="${gray}┌${fill}"

    if [[ -n "$elapsed" ]]; then
        line1+=" ⏱ ${elapsed}"
    fi

    line1+="${reset}"


    ###################################
    # LINEA 2: │ usuario@host ─ ruta
    ###################################

    local line2="${gray}│${reset} ${user_color}󰀄 \u${host_color}@${host}${reset} ${gray}─${reset} ${blue}󰉋 ${pwd_display}${reset}"


    ###################################
    # LINEA 3: │ git conda
    ###################################

    local line3="${gray}│${reset}"
    line3+=" ${cyan}󰩟 ${ip}${reset}"

    [[ -n "$git" ]] && \
        line3+=" ${green}󰘬 ${git}${reset}"

    [[ -n "$conda" ]] && \
        line3+=" ${magenta}󰌠 ${conda}${reset}"


    ###################################
    # LINEA 4: └─❯
    ###################################

    local prompt="${gray}└─${reset}❯ "

    PS1="${line1}\n${line2}\n${line3}\n${prompt}"
}


case ";${PROMPT_COMMAND:-};" in
    *";__nc_prompt;"*) ;;
    *) PROMPT_COMMAND="__nc_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

# <<< neocronos prompt <<<

EOF


echo
echo "Prompt instalado."
#echo "Recargando shell..."
sleep 1
clear

exec bash
