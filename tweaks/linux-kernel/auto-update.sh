#!/usr/bin/env bash

set -o nounset
set -o pipefail
# El menú trata cada fallo para poder informar y volver sin cerrar abruptamente.

VERSION="0.1.0"

comprobar_entorno() {
    local herramienta
    local -a faltantes=()

    for herramienta in apt-get dpkg-query update-grub uname; do
        command -v "$herramienta" >/dev/null 2>&1 || \
            faltantes+=("$herramienta")
    done

    if ((${#faltantes[@]})); then
        printf 'Faltan herramientas: %s\n' "${faltantes[*]}"
        return 1
    fi

    [[ "$(uname -m)" == "x86_64" ]] || {
        echo "Este flujo automático está preparado para x86_64."
        return 1
    }

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [[ "${UBUNTU_CODENAME:-}" != "noble" && \
              "${VERSION_CODENAME:-}" != "noble" ]]; then
            echo "Aviso: no se detectó una base Ubuntu Noble."
            echo "Se usarán igualmente los repositorios APT configurados."
        fi
    fi
}

paquete_disponible() {
    [[ -n "${PAQUETES_APT[$1]+disponible}" ]]
}

cargar_paquetes_apt() {
    local paquete
    local -a indices

    mapfile -t indices < <(
        find /var/lib/apt/lists -maxdepth 1 -type f \
            -name '*_ubuntu_dists_noble*_main_binary-amd64_Packages' \
            -print 2>/dev/null
    )

    ((${#indices[@]})) || {
        echo "No se encontraron índices APT de Ubuntu Noble/Linux Mint."
        echo "Actualice el índice de paquetes con apt antes de continuar."
        return 1
    }

    declare -gA PAQUETES_APT=()
    while IFS= read -r paquete; do
        [[ -n "$paquete" ]] && PAQUETES_APT["$paquete"]=1
    done < <(
        grep -h '^Package: linux-' "${indices[@]}" |
            sed 's/^Package: //'
    )
}

listar_versiones() {
    local release
    local -a candidatas

    mapfile -t candidatas < <(
        printf '%s\n' "${!PAQUETES_APT[@]}" |
            sed -nE 's/^linux-image-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+-generic)$/\1/p' |
            sort -Vu |
            tail -n 10 |
            sort -Vr
    )

    VERSIONES=()
    for release in "${candidatas[@]}"; do
        paquete_disponible "linux-image-$release" && VERSIONES+=("$release")
    done
}

armar_paquetes() {
    local release="$1"
    local abi="${release%-generic}"
    local version_kernel="${release%%-*}"
    local serie_hwe
    local paquete

    serie_hwe="${version_kernel%.*}"
    local -a candidatos=(
        "linux-headers-$abi"
        "linux-hwe-$serie_hwe-headers-$abi"
        "linux-headers-$release"
        "linux-modules-$release"
        "linux-modules-extra-$release"
        "linux-image-$release"
    )

    PAQUETES=()
    for paquete in "${candidatos[@]}"; do
        paquete_disponible "$paquete" && PAQUETES+=("$paquete")
    done

    for paquete in \
        "linux-image-$release" \
        "linux-modules-$release" \
        "linux-headers-$release"
    do
        if [[ ! " ${PAQUETES[*]} " =~ [[:space:]]${paquete}[[:space:]] ]]; then
            echo "Falta un paquete necesario en APT: $paquete"
            return 1
        fi
    done
}

mostrar_versiones() {
    local activo="$1"
    local i estado

    echo
    echo "=== Actualización automática ==="
    echo
    echo "Kernel activo: $activo"
    echo "Origen: repositorios Ubuntu/Mint configurados en APT"
    echo "Soporte: paquetes de la distribución (no Mainline)"
    echo

    if ((${#VERSIONES[@]} == 0)); then
        echo "No se encontraron kernels generic precompilados disponibles."
        return 1
    fi

    for i in "${!VERSIONES[@]}"; do
        estado=""
        dpkg-query -W -f='${Status}' \
            "linux-image-${VERSIONES[$i]}" 2>/dev/null |
            grep -q '^install ok installed$' && estado=" [INSTALADO]"
        printf '%2d) %s%s\n' "$((i + 1))" "${VERSIONES[$i]}" "$estado"
    done

    echo " 0) Salir"
    echo
}

instalar_version() {
    local release="$1"
    local activo respuesta

    activo="$(uname -r)"
    armar_paquetes "$release" || return 1

    echo
    echo "Se instalarán desde los repositorios configurados:"
    printf '  %s\n' "${PAQUETES[@]}"
    echo "APT mostrará y resolverá cualquier dependencia adicional."
    echo
    echo "No se eliminarán kernels ni se cambiará GRUB_DEFAULT."
    read -rp "¿Continuar? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return 0 ;;
    esac

    sudo apt-get install -- "${PAQUETES[@]}" || return 1

    if command -v update-initramfs >/dev/null 2>&1; then
        if [[ -f "/boot/initrd.img-$release" ]]; then
            sudo update-initramfs -u -k "$release" || return 1
        else
            sudo update-initramfs -c -k "$release" || return 1
        fi
    fi

    sudo update-grub || return 1

    echo
    echo "Kernel instalado: $release"
    echo "Kernel activo: $activo"
    echo "Kernel predeterminado: sin cambios"
    echo
    echo "Reinicie y pruebe el nuevo kernel manualmente desde GRUB."
}

main() {
    local activo opcion

    comprobar_entorno || return 1
    activo="$(uname -r)"
    echo "Consultando el índice local de APT..."
    cargar_paquetes_apt || return 1
    listar_versiones
    mostrar_versiones "$activo" || return 1

    read -rp "Seleccionar: " opcion
    [[ "$opcion" == "0" ]] && return 0

    if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] &&
       ((opcion <= ${#VERSIONES[@]})); then
        instalar_version "${VERSIONES[$((opcion - 1))]}"
    else
        echo "Opción inválida."
        return 1
    fi
}

main "$@"
