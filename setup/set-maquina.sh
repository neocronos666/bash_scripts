#!/usr/bin/env bash
# bash_scripts - Instalador de perfil Bash remoto
set -euo pipefail

# Editar libremente las etiquetas mostradas en el selector.
TIPO_1='Tipo 1'  # Azul
TIPO_2='Tipo 2'  # Cian
TIPO_3='Tipo 3'  # Magenta
TIPO_4='Tipo 4'  # Amarillo
TIPO_5='Tipo 5'  # Verde

if [[ ! -t 0 || ! -t 1 ]]; then
  printf 'Este instalador requiere una terminal interactiva.\n' >&2
  exit 1
fi
command -v ssh >/dev/null || { printf 'No se encuentra ssh.\n' >&2; exit 1; }
printf '\n  BASH SCRIPTS / CONFIGURACIÓN REMOTA\n  ─────────────────────────────────────\n\n'
read -r -p 'IP o alias SSH (admite usuario@host): ' TARGET
[[ -n $TARGET && $TARGET != -* && $TARGET != *[[:space:]]* ]] || { printf 'Destino inválido.\n' >&2; exit 1; }

printf '\n  Color de host e IP de destino:\n'
printf '  1) Azul     — %s\n' "$TIPO_1"
printf '  2) Cian     — %s\n' "$TIPO_2"
printf '  3) Magenta  — %s\n' "$TIPO_3"
printf '  4) Amarillo — %s\n' "$TIPO_4"
printf '  5) Verde    — %s\n\n' "$TIPO_5"
read -r -p 'Seleccionar color [1-5]: ' COLOR
[[ $COLOR =~ ^[1-5]$ ]] || { printf 'Color inválido.\n' >&2; exit 1; }

printf '\nConectando a %s...\n' "$TARGET"
# La primera sesión verifica conectividad y detecta el usuario efectivo.
# BatchMode evita pedir contraseñas repetidas; SSH sigue pudiendo pedir clave una vez por conexión.
if ! ssh -o ConnectTimeout=10 -o RequestTTY=no -- "$TARGET" 'test "$(basename "$SHELL")" = bash && command -v bash >/dev/null' </dev/null; then
  printf 'No se pudo conectar o el shell predeterminado no es Bash.\n' >&2
  exit 1
fi

EXISTS=$(ssh -o ConnectTimeout=10 -o RequestTTY=no -- "$TARGET" 'test -e "$HOME/.config/bash_scripts/remote-prompt.sh" && printf yes || printf no' </dev/null)
if [[ $EXISTS == yes ]]; then
  read -r -p 'Ya existe un perfil remoto. ¿Sobrescribir/reparar? [s/N]: ' ANSWER
  [[ $ANSWER == [sS] || $ANSWER == [sS][iI] ]] || { printf 'Cancelado.\n'; exit 0; }
fi

# Enviamos el instalador remoto como código fijo por stdin, sin interpolar datos locales.
# COLOR se envía como argumento posicional validado.
ssh -o ConnectTimeout=10 -o RequestTTY=no -- "$TARGET" "bash -s -- '$COLOR'" <<'REMOTE_INSTALL'
set -euo pipefail
COLOR=${1:?}
DIR="$HOME/.config/bash_scripts"
BASHRC="$HOME/.bashrc"
umask 077
mkdir -p "$DIR"
[[ -f $BASHRC ]] || touch "$BASHRC"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=$(mktemp "$HOME/.bashrc.bash_scripts.${STAMP}.XXXXXX.bak")
cp -p "$BASHRC" "$BACKUP"

cat > "$DIR/remote-shell.conf" <<CONF
# Generado por bash_scripts
BS_HOST_COLOR=$COLOR
CONF

cat > "$DIR/remote-prompt.sh" <<'PROMPT'
# bash_scripts - Prompt remoto; se carga sólo en Bash interactivo.
[[ $- == *i* ]] || return 0
[[ -r $HOME/.config/bash_scripts/remote-shell.conf ]] && source "$HOME/.config/bash_scripts/remote-shell.conf"

_bs_ip_short() {
  case $1 in
    192.168.0.*) REPLY="⊛${1#192.168.0.}" ;;
    192.168.*) REPLY="⊛${1#192.168.}" ;;
    *) REPLY=$1 ;;
  esac
}
_bs_prompt() {
  local exit_code=$? hostc userc orig dest userpart hostpart reset normal white sep cwd
  case ${BS_HOST_COLOR:-1} in
    1) hostc=34;; 2) hostc=36;; 3) hostc=35;; 4) hostc=33;; 5) hostc=32;;
    *) hostc=34;;
  esac
  if (( EUID == 0 )); then userc=31; else userc=32; fi
  orig='?'; dest='?'
  if [[ -n ${SSH_CONNECTION:-} ]]; then
    read -r orig _ dest _ <<< "$SSH_CONNECTION"
  elif [[ -n ${SSH_CLIENT:-} ]]; then
    read -r orig _ _ <<< "$SSH_CLIENT"
    dest=${SSH_CONNECTION_DEST:-?}
  fi
  _bs_ip_short "$orig"; orig=$REPLY
  _bs_ip_short "$dest"; dest=$REPLY
  # \[...\] marca secuencias no imprimibles para que Readline calcule bien el cursor.
  userpart="\[\e[${userc}m\]\\u\[\e[0m\]"
  hostpart="\[\e[${hostc}m\]\\h\[\e[0m\]"
  local address="\[\e[${userc}m\]${orig}\[\e[0m\] ↗ \[\e[${hostc}m\]${dest}\[\e[0m\]"
  local mark='❯' markcolor=32
  if (( EUID == 0 )); then mark='#'; markcolor=31
  elif (( exit_code != 0 )); then markcolor=31
  fi
  PS1="${userpart}@${hostpart} [${address}] \[\e[90m\]────────\[\e[0m\] \\w\n\[\e[${markcolor}m\]${mark}\[\e[0m\] "
}

# No se instala ningún hook externo. El prompt se arma sin ejecutar herramientas del sistema.
# Si había un PROMPT_COMMAND preexistente, lo conservamos después del nuestro.
if [[ ${PROMPT_COMMAND-} != *_bs_prompt* ]]; then
  if declare -p PROMPT_COMMAND 2>/dev/null | grep -q 'declare -a'; then
    PROMPT_COMMAND=(_bs_prompt "${PROMPT_COMMAND[@]}")
  elif [[ -n ${PROMPT_COMMAND:-} ]]; then
    PROMPT_COMMAND="_bs_prompt; $PROMPT_COMMAND"
  else
    PROMPT_COMMAND=_bs_prompt
  fi
fi
PROMPT

cat > "$DIR/remote-welcome.sh" <<'WELCOME'
# bash_scripts - Bienvenida remota. Una vez por sesión Bash interactiva.
[[ $- == *i* ]] || return 0
[[ ${BS_REMOTE_WELCOME_SHOWN:-} == 1 ]] && return 0
export BS_REMOTE_WELCOME_SHOWN=1

_bs_welcome() {
  local hcolor=34 usercolor=32 os='Linux' kernel arch h user ipfrom='?' ipto='?'
  local uptime_txt mem='N/D' swap='N/D' load='N/D' disk='N/D' sessions='N/D'
  case ${BS_HOST_COLOR:-1} in
    1) hcolor=34;; 2) hcolor=36;; 3) hcolor=35;; 4) hcolor=33;; 5) hcolor=32;;
  esac
  (( EUID == 0 )) && usercolor=31
  [[ -r /etc/os-release ]] && { . /etc/os-release; os=${PRETTY_NAME:-Linux}; }
  h=${HOSTNAME:-$(hostname)}
  user=${USER:-$(id -un)}
  kernel=$(uname -r)
  arch=$(uname -m)
  if [[ -n ${SSH_CONNECTION:-} ]]; then
    read -r ipfrom _ ipto _ <<< "$SSH_CONNECTION"
  fi
  if [[ -r /proc/uptime ]]; then
    read -r uptime_raw _ < /proc/uptime
    uptime_days=$(( ${uptime_raw%.*} / 86400 ))
    uptime_hours=$(( (${uptime_raw%.*} % 86400) / 3600 ))
    uptime_txt="${uptime_days}d ${uptime_hours}h"
  else uptime_txt='N/D'; fi
  if [[ -r /proc/meminfo ]]; then
    local total=0 available=0 swaptotal=0 swapfree=0 key value unit
    while read -r key value unit; do
      case $key in
        MemTotal:) total=$value;; MemAvailable:) available=$value;;
        SwapTotal:) swaptotal=$value;; SwapFree:) swapfree=$value;;
      esac
    done < /proc/meminfo
    (( total > 0 )) && mem="$(( (total-available)/1024 )) / $(( total/1024 )) MiB"
    (( swaptotal > 0 )) && swap="$(( (swaptotal-swapfree)/1024 )) / $(( swaptotal/1024 )) MiB" || swap='Sin swap'
  fi
  [[ -r /proc/loadavg ]] && { read -r a b c _ < /proc/loadavg; load="$a · $b · $c"; }
  if command -v df >/dev/null 2>&1; then
    disk=$(df -hP / 2>/dev/null | awk 'NR==2 {printf "%s usado, %s libre (%s)", $3,$4,$5}')
    [[ -n $disk ]] || disk='N/D'
  fi
  if command -v who >/dev/null 2>&1; then
    sessions=$(who | wc -l)
  fi
  printf '\n\033[%sm  BASH SCRIPTS  /  REMOTE SHELL\033[0m\n' "$hcolor"
  printf '  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '  \033[%sm%s\033[0m  •  %s\n' "$hcolor" "$h" "$os"
  printf '  Sistema     Kernel: %s  |  Arquitectura: %s\n' "$kernel" "$arch"
  printf '  Usuario     \033[%sm%s\033[0m\n' "$usercolor" "$user"
  printf '  Conexión    \033[%sm%s\033[0m ↗ \033[%sm%s\033[0m\n' "$usercolor" "$ipfrom" "$hcolor" "$ipto"
  printf '  Actividad   Uptime: %s  |  Carga: %s\n' "$uptime_txt" "$load"
  printf '  Memoria     RAM: %s  |  Swap: %s\n' "$mem" "$swap"
  printf '  Disco /     %s\n' "$disk"
  printf '  Sesiones    %s\n' "$sessions"
  printf '  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
}
_bs_welcome
unset -f _bs_welcome
WELCOME

# Limpiar un bloque administrado anterior, si lo hay, sin afectar el resto del archivo.
# La sustitución se hace en un temporal para no dejar un .bashrc incompleto.
TMP=$(mktemp "${BASHRC}.tmp.XXXXXXXX")
trap 'rm -f "$TMP"' EXIT
awk '
  /^# >>> bash_scripts remote-shell >>>$/ { inside=1; next }
  /^# <<< bash_scripts remote-shell <<<$/{ inside=0; next }
  !inside { print }
' "$BASHRC" > "$TMP"
cat >> "$TMP" <<'INTEGRATION'

# >>> bash_scripts remote-shell >>>
if [[ $- == *i* ]] && [[ -n ${BASH_VERSION:-} ]]; then
  source "$HOME/.config/bash_scripts/remote-shell.conf"
  source "$HOME/.config/bash_scripts/remote-prompt.sh"
  source "$HOME/.config/bash_scripts/remote-welcome.sh"
fi
# <<< bash_scripts remote-shell <<<
INTEGRATION
chmod --reference="$BASHRC" "$TMP"
cat "$TMP" > "$BASHRC"
rm -f "$TMP"
trap - EXIT
printf 'Instalación realizada. Respaldo: %s\n' "$BACKUP"
printf 'Abrí una nueva sesión SSH para ver el perfil.\n'
REMOTE_INSTALL
printf '\nOperación terminada.\n'
