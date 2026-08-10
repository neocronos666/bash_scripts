#!/usr/bin/env bash

set -u

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/.kernels"
CFG_DIR="$BASE_DIR/.cfgs"

mkdir -p "$KERNEL_DIR" "$CFG_DIR"

validar_nombre() {
    local nombre="$1"

    [[ "$nombre" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || {
        echo "Nombre inválido."
        return 1
    }

    [[ ! -e "$KERNEL_DIR/$nombre" ]] || {
        echo "Ya existe .kernels/$nombre"
        return 1
    }

    [[ ! -e "$CFG_DIR/$nombre" ]] || {
        echo "Ya existe .cfgs/$nombre"
        return 1
    }
}

listar() {
    ARCHIVOS=()
    TIPOS=()

    while IFS= read -r archivo; do
        [[ -n "$archivo" ]] || continue
        ARCHIVOS+=("$archivo")
        TIPOS+=("comprimido")
    done < <(
        find "$KERNEL_DIR" -maxdepth 1 -type f \
            -name 'linux-*.tar.xz' -printf '%f\n' |
        sort -V
    )

    while IFS= read -r directorio; do
        [[ -n "$directorio" ]] || continue
        ARCHIVOS+=("$directorio")
        TIPOS+=("fuente")
    done < <(
        find "$KERNEL_DIR" -mindepth 1 -maxdepth 1 -type d \
            ! -name '.*' -printf '%f\n' |
        sort -V
    )
}

mostrar_lista() {
    echo
    echo "=== Gestionar kernels ==="
    echo

    if ((${#ARCHIVOS[@]} == 0)); then
        echo "No hay comprimidos ni fuentes en:"
        echo "$KERNEL_DIR"
        return 1
    fi

    local i
    for i in "${!ARCHIVOS[@]}"; do
        if [[ "${TIPOS[$i]}" == "comprimido" ]]; then
            printf "%2d) %-45s [comprimido]\n" \
                "$((i + 1))" "${ARCHIVOS[$i]}"
        else
            printf "%2d) %-45s [fuente]\n" \
                "$((i + 1))" "${ARCHIVOS[$i]}"
        fi
    done

    echo
    echo " 0) Salir"
    echo
}

descomprimir() {
    local archivo="$1"
    local version nombre temporal respuesta

    version="${archivo#linux-}"
    version="${version%.tar.xz}"
    nombre="${version}-generic"

    echo
    echo "Seleccionado: $archivo"
    echo
    read -rp "Nombre de la fuente [$nombre]: " respuesta
    [[ -n "$respuesta" ]] && nombre="$respuesta"

    validar_nombre "$nombre" || return

    temporal="$KERNEL_DIR/.extract-$$"
    rm -rf -- "$temporal"
    mkdir -p "$temporal"

    echo
    echo "Descomprimiendo como:"
    echo "  .kernels/$nombre/"

    if ! tar -xJf "$KERNEL_DIR/$archivo" \
        -C "$temporal" --strip-components=1; then
        rm -rf -- "$temporal"
        echo "Error al descomprimir."
        return
    fi

    [[ -f "$temporal/Makefile" ]] || {
        rm -rf -- "$temporal"
        echo "El archivo no parece contener un árbol fuente de Linux."
        return
    }

    mv -- "$temporal" "$KERNEL_DIR/$nombre"
    mkdir -p "$CFG_DIR/$nombre"

    echo "Creado: $nombre"
}

copiar_config_base() {
    local origen="$1"
    local destino="$2"

    mkdir -p "$CFG_DIR/$destino"

    if [[ -f "$CFG_DIR/$origen/.config" ]]; then
        cp -a -- "$CFG_DIR/$origen/.config" \
            "$CFG_DIR/$destino/.config"
    fi
}

copiar_fuente() {
    local origen="$1"
    local destino

    echo
    read -rp "Nombre de la copia: " destino
    validar_nombre "$destino" || return

    echo
    echo "Copiando:"
    echo "  $origen"
    echo "  -> $destino"

    if cp -a -- "$KERNEL_DIR/$origen" "$KERNEL_DIR/$destino"; then
        copiar_config_base "$origen" "$destino"
        echo "Copia terminada."
    else
        rm -rf -- "$KERNEL_DIR/$destino" "$CFG_DIR/$destino"
        echo "Error al copiar."
    fi
}

renombrar_fuente() {
    local origen="$1"
    local destino respuesta

    echo
    read -rp "Nuevo nombre: " destino
    validar_nombre "$destino" || return

    echo
    echo "Se renombrará:"
    echo "  .kernels/$origen"
    echo "  -> .kernels/$destino"

    if [[ -d "$CFG_DIR/$origen" ]]; then
        echo "  .cfgs/$origen"
        echo "  -> .cfgs/$destino"
    fi

    read -rp "¿Continuar? [s/N]: " respuesta
    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return ;;
    esac

    mv -- "$KERNEL_DIR/$origen" "$KERNEL_DIR/$destino"

    if [[ -d "$CFG_DIR/$origen" ]]; then
        mv -- "$CFG_DIR/$origen" "$CFG_DIR/$destino"
    else
        mkdir -p "$CFG_DIR/$destino"
    fi

    echo "Renombrado."
    echo "Si ya estaba compilado, deberá recompilarse con el nuevo nombre."
}

eliminar_fuente() {
    local nombre="$1"
    local respuesta

    echo
    echo "Se eliminará definitivamente:"
    echo "  .kernels/$nombre/"

    if [[ -d "$CFG_DIR/$nombre" ]]; then
        echo "  .cfgs/$nombre/"
    fi

    echo
    read -rp "¿Eliminar? [s/N]: " respuesta
    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return ;;
    esac

    rm -rf -- "$KERNEL_DIR/$nombre" "$CFG_DIR/$nombre"
    echo "Eliminado: $nombre"
}

menu_comprimido() {
    local archivo="$1"
    local opcion

    echo
    echo "Seleccionado: $archivo"
    echo
    echo "1) Descomprimir como nueva fuente"
    echo "0) Volver"
    echo
    read -rp "Opción: " opcion

    case "$opcion" in
        1) descomprimir "$archivo" ;;
        0) ;;
        *) echo "Opción inválida." ;;
    esac
}

menu_fuente() {
    local nombre="$1"
    local opcion

    echo
    echo "Seleccionado: $nombre"
    echo
    echo "1) Copiar"
    echo "2) Renombrar"
    echo "3) Eliminar"
    echo "0) Volver"
    echo
    read -rp "Opción: " opcion

    case "$opcion" in
        1) copiar_fuente "$nombre" ;;
        2) renombrar_fuente "$nombre" ;;
        3) eliminar_fuente "$nombre" ;;
        0) ;;
        *) echo "Opción inválida." ;;
    esac
}

while true; do
    listar

    if ! mostrar_lista; then
        exit 0
    fi

    read -rp "Seleccionar: " opcion

    [[ "$opcion" == "0" ]] && exit 0

    if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] &&
       ((opcion >= 1 && opcion <= ${#ARCHIVOS[@]})); then

        indice=$((opcion - 1))

        if [[ "${TIPOS[$indice]}" == "comprimido" ]]; then
            menu_comprimido "${ARCHIVOS[$indice]}"
        else
            menu_fuente "${ARCHIVOS[$indice]}"
        fi
    else
        echo "Opción inválida."
    fi
done
