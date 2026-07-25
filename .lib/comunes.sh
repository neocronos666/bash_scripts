#!/bin/bash

comando_disponible() {
    command -v "$1" >/dev/null 2>&1
}

requerir_comando() {
    comando_disponible "$1" && return 0
    printf 'Error: falta el comando requerido: %s\n' "$1" >&2
    return 127
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
