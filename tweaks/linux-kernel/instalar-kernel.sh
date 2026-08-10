#!/usr/bin/env bash

set -u

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CFG_DIR="$BASE_DIR/.cfgs"

mkdir -p "$CFG_DIR"

listar_compilados() {
    COMPILADOS=()

    while IFS= read -r dir; do
        [[ -n "$dir" ]] || continue

        nombre="$(basename "$dir")"
        release_file="$dir/kernel-release"

        [[ -f "$release_file" ]] || continue
        [[ "$(cat "$release_file")" == "$nombre" ]] || continue

        if find "$dir/packages" -maxdepth 1 -type f \
            -name "linux-image-${nombre}_*.deb" \
            -print -quit 2>/dev/null |
            grep -q .; then
            COMPILADOS+=("$nombre")
        fi
    done < <(
        find "$CFG_DIR" -mindepth 1 -maxdepth 1 -type d \
            ! -name '.*' -print |
        sort -V
    )
}

mostrar_compilados() {
    echo
    echo "=== Instalar kernel ==="
    echo

    if ((${#COMPILADOS[@]} == 0)); then
        echo "No hay kernels compilados listos para instalar."
        return 1
    fi

    local i
    for i in "${!COMPILADOS[@]}"; do
        printf "%2d) %s\n" "$((i + 1))" "${COMPILADOS[$i]}"
    done

    echo
    echo " 0) Salir"
    echo
}

comprobar_espacio_instalacion() {
    local boot_kb root_kb

    boot_kb="$(df -Pk /boot | awk 'NR==2 {print $4}')"
    root_kb="$(df -Pk / | awk 'NR==2 {print $4}')"

    if ((boot_kb < 100 * 1024)); then
        echo "Error: menos de 100 MiB libres en /boot."
        return 1
    fi

    if ((root_kb < 150 * 1024)); then
        echo "Error: menos de 150 MiB libres en /."
        return 1
    fi
}

mostrar_dkms() {
    local release="$1"

    command -v dkms >/dev/null 2>&1 || return

    echo
    echo "DKMS para $release:"

    if ! dkms status 2>/dev/null |
         grep -F ", $release,"; then
        echo "  No hay módulos DKMS registrados para este kernel."
    fi
}

instalar_kernel() {
    local release="$1"
    local perfil="$CFG_DIR/$release"
    local packages="$perfil/packages"
    local image headers actual respuesta

    actual="$(uname -r)"

    image="$(
        find "$packages" -maxdepth 1 -type f \
            -name "linux-image-${release}_*.deb" \
            -print -quit
    )"

    headers="$(
        find "$packages" -maxdepth 1 -type f \
            -name "linux-headers-${release}_*.deb" \
            -print -quit
    )"

    [[ -n "$image" && -f "$image" ]] || {
        echo "Falta el paquete de imagen para $release."
        return
    }

    [[ -n "$headers" && -f "$headers" ]] || {
        echo "Falta el paquete de headers para $release."
        return
    }

    if dpkg-query -W -f='${Status}' "linux-image-$release" 2>/dev/null |
       grep -q '^install ok installed$'; then

        echo
        echo "El kernel $release ya está instalado."
        echo "Kernel activo: $actual"
        echo "La selección predeterminada se gestiona desde MAIN.sh."
        return
    fi

    comprobar_espacio_instalacion || return

    if command -v mokutil >/dev/null 2>&1 &&
       mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
        echo
        echo "Secure Boot está habilitado."
        echo "El kernel compilado localmente puede no arrancar."
        return
    fi

    echo
    echo "Se instalará:"
    echo "  $(basename "$headers")"
    echo "  $(basename "$image")"
    echo
    echo "Los kernels instalados y el predeterminado de GRUB se conservarán."
    echo
    read -rp "¿Instalar? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return ;;
    esac

    echo
    echo "Instalando headers..."
    sudo dpkg -i "$headers" || {
        echo "Falló la instalación de headers."
        return
    }

    echo
    echo "Instalando imagen y módulos..."
    if ! sudo dpkg -i "$image"; then
        echo
        echo "La instalación del paquete devolvió un error."
        echo "Revisá especialmente los hooks DKMS."
        return
    fi

    if [[ ! -f "/boot/initrd.img-$release" ]] &&
       command -v update-initramfs >/dev/null 2>&1; then
        echo "Generando initramfs..."
        sudo update-initramfs -c -k "$release" || return
    fi

    echo "Actualizando GRUB..."
    sudo update-grub || return

    echo
    echo "Instalación terminada."
    echo
    echo "Kernel instalado: $release"
    echo "Kernel activo:    $actual"
    echo "Kernel predeterminado: sin cambios"
    echo
    echo "No se reinició el equipo."
    echo "En el próximo arranque elegí $release manualmente en GRUB."
    echo "Si funciona bien, podés establecerlo como predeterminado"
    echo "desde 7) gestionar GRUB en MAIN.sh."

    mostrar_dkms "$release"
}

listar_compilados
mostrar_compilados || exit 0

read -rp "Seleccionar: " opcion
[[ "$opcion" == "0" ]] && exit 0

if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] &&
   ((opcion >= 1 && opcion <= ${#COMPILADOS[@]})); then
    instalar_kernel "${COMPILADOS[$((opcion - 1))]}"
else
    echo "Opción inválida."
    exit 1
fi
