#!/usr/bin/env bash
clear
set -u

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/.kernels"

listar_kernels() {
    mapfile -t KERNELS < <(
        find "$KERNEL_DIR" -maxdepth 1 -type f -name 'linux-*.tar.xz' -printf '%f\n' 2>/dev/null |
        sed -E 's/^linux-//; s/\.tar\.xz$//' |
        sort -V
    )
}

mostrar_lista() {
    echo
    echo "=== Kernels descargados ==="
    echo

    if ((${#KERNELS[@]} == 0)); then
        echo "No hay kernels descargados en:"
        echo "$KERNEL_DIR"
        echo
        return 1
    fi

    local i
    for i in "${!KERNELS[@]}"; do
        printf "%2d) linux-%s\n" "$((i + 1))" "${KERNELS[$i]}"
    done

    echo
    echo "*  = seleccionar todos"
    echo "0  = salir después de limpiar"
    echo
    return 0
}

seleccionar() {
    local entrada="$1"
    local -a tokens=()
    local -A vistos=()
    local token
    local seleccionar_todos=false

    SALIR_DESPUES=false
    SELECCION=()

    read -r -a tokens <<< "$entrada"

    for token in "${tokens[@]}"; do
        case "$token" in
            0)
                SALIR_DESPUES=true
                ;;
            '*')
                seleccionar_todos=true
                ;;
            *)
                if [[ "$token" =~ ^[1-9][0-9]*$ ]]; then
                    if (( token >= 1 && token <= ${#KERNELS[@]} )); then
                        vistos["$token"]=1
                    else
                        echo "Aviso: índice inexistente ignorado: $token"
                    fi
                else
                    echo "Aviso: valor inválido ignorado: $token"
                fi
                ;;
        esac
    done

    if $seleccionar_todos; then
        local i
        for i in "${!KERNELS[@]}"; do
            SELECCION+=("$((i + 1))")
        done
        return
    fi

    local idx
    for idx in "${!vistos[@]}"; do
        SELECCION+=("$idx")
    done

    if ((${#SELECCION[@]} > 0)); then
        IFS=$'\n' SELECCION=($(sort -n <<< "${SELECCION[*]}"))
        unset IFS
    fi
}

confirmar_y_borrar() {
    if ((${#SELECCION[@]} == 0)); then
        echo
        echo "No hay kernels seleccionados para borrar."
        return
    fi

    echo
    echo "Se eliminarán:"
    echo

    local idx version
    for idx in "${SELECCION[@]}"; do
        version="${KERNELS[$((idx - 1))]}"
        printf "%2d) linux-%s\n" "$idx" "$version"
    done

    echo
    read -rp "¿Continuar? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí|y|yes)
            ;;
        *)
            echo "Limpieza cancelada."
            return
            ;;
    esac

    echo

    for idx in "${SELECCION[@]}"; do
        version="${KERNELS[$((idx - 1))]}"

        rm -f -- \
            "$KERNEL_DIR/linux-$version.tar.xz" \
            "$KERNEL_DIR/linux-$version.tar.sign"

        echo "Eliminado: linux-$version"
    done

    echo
    echo "Limpieza terminada."
}

mkdir -p "$KERNEL_DIR"

while true; do
    listar_kernels

    if ! mostrar_lista; then
        exit 0
    fi

    read -rp "Seleccionar: " entrada

    seleccionar "$entrada"

    confirmar_y_borrar

    if $SALIR_DESPUES; then
        exit 0
    fi
done
