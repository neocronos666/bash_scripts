#!/bin/bash

comando_disponible() {
    command -v "$1" >/dev/null 2>&1
}

requerir_comando() {
    comando_disponible "$1" && return 0
    printf 'Error: falta el comando requerido: %s\n' "$1" >&2
    return 127
}

instalar_paquete() {
    local paquete="$1"
    local apt_prefix=""

    if [[ "$EUID" -eq 0 ]]; then
        apt_prefix=""
    elif comando_disponible sudo; then
        apt_prefix="sudo"
    else
        printf 'Error: se necesita root o sudo para instalar %s.\n' "$paquete" >&2
        return 126
    fi

    if comando_disponible apt-get; then
        $apt_prefix apt-get update && $apt_prefix apt-get install -y "$paquete"
    elif comando_disponible dnf; then
        $apt_prefix dnf install -y "$paquete"
    elif comando_disponible pacman; then
        $apt_prefix pacman -S --needed --noconfirm "$paquete"
    elif comando_disponible zypper; then
        $apt_prefix zypper --non-interactive install "$paquete"
    else
        printf 'Error: no se encontró un gestor de paquetes compatible para instalar %s.\n' "$paquete" >&2
        return 127
    fi
}

asegurar_dependencia() {
    local comando="$1"
    local paquete="${2:-$1}"
    local descripcion="${3:-$comando}"
    local respuesta

    comando_disponible "$comando" && return 0

    printf '\nFalta la herramienta: %s\n' "$comando"
    printf '%s\n' "$descripcion"
    printf 'Se puede instalar el paquete: %s\n' "$paquete"
    read -r -p '¿Instalar ahora? [1=Sí/0=No] ' respuesta

    case "$respuesta" in
        1)
            instalar_paquete "$paquete" || return $?
            ;;
        *)
            printf 'No se instaló %s.\n' "$comando" >&2
            return 1
            ;;
    esac

    requerir_comando "$comando"
}

confirmacion_texto() {
    local mensaje="$1"
    local esperado="$2"
    local respuesta

    read -r -p "$mensaje (escriba $esperado): " respuesta
    [[ "$respuesta" == "$esperado" ]]
}

crear_temporal() {
    local prefijo="${1:-bash-scripts}"
    mktemp "${TMPDIR:-/tmp}/${prefijo}.XXXXXX"
}

linea(){
echo -e "${YELLOW}"
#printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '━'
printf '━%.0s' $(seq 1 "${COLUMNS:-80}"); echo
echo -e "${NC}"
}

pausa(){

echo
read -r -n1 -s -p $'✳️ Presione una tecla para continuar...\n'

}

confirmacion(){

read -r -p "🔴¿Continuar? [s/N] " RESP

[[ "$RESP" =~ ^[sS]$ ]]

}

# FUNCIÓN DE TABLAS DINÁMICAS (CORRECCIÓN MILIMÉTRICA DE BORDES)
fila_dinamica() {
    local modo="$1"
    shift 

    # Dimensiones exactas para los techos y pisos
    local T_ETI=$ANCHO_ETIQUETA
    local T_VAL=$ANCHO_VALOR

    case "$modo" in
        "techo2")
            echo -e "${YELLOW}┌$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┐${NC}"
            return
            ;;
        "techo4")
            echo -e "${YELLOW}┌$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┬$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┐${NC}"
            return
            ;;
        "techo6")
            echo -e "${YELLOW}┌$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┬$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┬$(printf '─%.0s' $(seq 1 $T_ETI))┬$(printf '─%.0s' $(seq 1 $T_VAL))┐${NC}"
            return
            ;;
        "piso2")
            echo -e "${YELLOW}└$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┘${NC}"
            return
            ;;
        "piso4")
            echo -e "${YELLOW}└$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┴$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┘${NC}"
            return
            ;;
        "piso6")
            echo -e "${YELLOW}└$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┴$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┴$(printf '─%.0s' $(seq 1 $T_ETI))┴$(printf '─%.0s' $(seq 1 $T_VAL))┘${NC}"
            return
            ;;
    esac

    # MODO FILA
    local col_actual=1
    local output="${YELLOW}│" # Empezamos el borde izquierdo pegado, el espacio lo maneja printf

    while [ $# -gt 0 ]; do
        local color="$1"
        local emoji="$2"
        local texto="$3"
        shift 3

        local ancho=$ANCHO_ETIQUETA
        if [ $((col_actual % 2)) -eq 0 ]; then
            ancho=$ANCHO_VALOR
        fi

        local texto_fijado
        if [ -n "$emoji" ]; then
            # CORRECCIÓN: Restamos 2 espacios (1 del emoji visual y 1 del espacio intermedio)
            local ancho_texto=$((ancho - 3))
            texto_fijado=$(printf "%-${ancho_texto}.${ancho_texto}s" "$texto")
            output="${output} ${color}${emoji}${texto_fijado}"
        else
            # Si es el valor de la derecha, agregamos un espacio inicial de cortesía visual
            local ancho_texto=$((ancho - 1))
            texto_fijado=$(printf "%-${ancho_texto}.${ancho_texto}s" "$texto")
            output="${output} ${color}${texto_fijado}"
        fi

        # Control de separadores internos y finales
        if [ $# -gt 0 ]; then
            output="${output}${YELLOW}│"
        else
            output="${output}${YELLOW}│"
        fi

        col_actual=$((col_actual + 1))
    done

    echo -e "$output$NC"
}
