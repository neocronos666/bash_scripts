#!/usr/bin/env bash

set -o nounset
set -o pipefail
# El menú trata cada fallo para cancelar con seguridad sin borrar parcialmente.

VERSION="0.1.0"
GRUB_DEFAULT_FILE="/etc/default/grub"

buscar_grub_cfg() {
    local candidato

    for candidato in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
        sudo test -f "$candidato" && {
            printf '%s\n' "$candidato"
            return 0
        }
    done
    return 1
}

selector_grub() {
    local valor

    valor="$(sed -nE 's/^[[:space:]]*GRUB_DEFAULT=(.*)$/\1/p' \
        "$GRUB_DEFAULT_FILE" 2>/dev/null | tail -n 1)"
    valor="${valor%\"}"
    valor="${valor#\"}"
    valor="${valor%\'}"
    valor="${valor#\'}"

    if [[ "$valor" == "saved" ]] && command -v grub-editenv >/dev/null; then
        valor="$(grub-editenv list 2>/dev/null |
            sed -n 's/^saved_entry=//p' | head -n 1)"
    fi

    printf '%s\n' "${valor:-0}"
}

release_predeterminado() {
    local grub_cfg selector selector_final

    grub_cfg="$(buscar_grub_cfg)" || return 1
    selector="$(selector_grub)"
    selector_final="${selector##*>}"

    sudo awk -F"'" -v selector="$selector" -v final="$selector_final" '
        /^[[:space:]]*menuentry / {
            numero++
            coincide = 0
            if (selector == "0" && numero == 1) coincide = 1
            if (index($0, selector) || index($0, final)) coincide = 1
            dentro = coincide
            next
        }
        dentro && /\/vmlinuz-/ {
            release = $0
            sub(/^.*\/vmlinuz-/, "", release)
            sub(/[[:space:]].*$/, "", release)
            print release
            exit
        }
        dentro && /^[[:space:]]*}/ { dentro = 0 }
    ' "$grub_cfg"
}

listar_kernels() {
    mapfile -t KERNELS < <(
        dpkg-query -W -f='${db:Status-Abbrev}\t${binary:Package}\n' \
            'linux-image-[0-9]*' 'linux-image-unsigned-[0-9]*' 2>/dev/null |
            awk -F '\t' '$1 ~ /^ii/ {
                sub(/^linux-image-unsigned-/, "", $2)
                sub(/^linux-image-/, "", $2)
                print $2
            }' |
            sort -Vu
    )
}

origen_kernel() {
    local release="$1"
    local paquete="linux-image-$release"
    local politica

    dpkg-query -W "$paquete" >/dev/null 2>&1 || \
        paquete="linux-image-unsigned-$release"
    politica="$(apt-cache policy "$paquete" 2>/dev/null)"

    if grep -qE 'https?://|/var/lib/apt/lists' <<< "$politica"; then
        printf 'Ubuntu/Mint'
    else
        printf 'local'
    fi
}

mostrar_kernels() {
    local activo="$1"
    local predeterminado="$2"
    local i marcas origen

    echo
    echo "=== Desinstalar kernels instalados ==="
    echo

    if ((${#KERNELS[@]} == 0)); then
        echo "No se encontraron kernels instalados mediante dpkg."
        return 1
    fi

    for i in "${!KERNELS[@]}"; do
        marcas=""
        [[ "${KERNELS[$i]}" == "$activo" ]] && marcas+=" [ACTIVO]"
        [[ -n "$predeterminado" && \
           "${KERNELS[$i]}" == "$predeterminado" ]] && marcas+=" [DEFAULT]"
        origen="$(origen_kernel "${KERNELS[$i]}")"
        printf '%2d) %-30s [%s]%s\n' \
            "$((i + 1))" "${KERNELS[$i]}" "$origen" "$marcas"
    done

    echo " 0) Salir"
    echo
}

paquetes_del_kernel() {
    local release="$1"

    mapfile -t PAQUETES < <(
        dpkg-query -W -f='${db:Status-Abbrev}\t${binary:Package}\n' \
            "linux-image-$release" \
            "linux-image-unsigned-$release" \
            "linux-modules-$release" \
            "linux-modules-extra-$release" \
            "linux-headers-$release" 2>/dev/null |
            awk -F '\t' '$1 ~ /^ii/ {print $2}'
    )
}

desinstalar_kernel() {
    local release="$1"
    local activo="$2"
    local predeterminado="$3"
    local respuesta

    if [[ "$release" == "$activo" ]]; then
        echo "Prohibido eliminar el kernel actualmente activo: $release"
        return 1
    fi

    if [[ -z "$predeterminado" ]]; then
        echo "No se pudo determinar con seguridad el kernel predeterminado."
        echo "Resolvé primero el default desde MAIN.sh; no se eliminará nada."
        return 1
    fi

    if [[ "$release" == "$predeterminado" ]]; then
        echo "El kernel seleccionado es el predeterminado de GRUB."
        echo "Elegí primero otro default desde MAIN.sh."
        return 1
    fi

    if ((${#KERNELS[@]} <= 1)); then
        echo "No se puede eliminar el único kernel arrancable detectado."
        return 1
    fi

    paquetes_del_kernel "$release"
    if ((${#PAQUETES[@]} == 0)); then
        echo "No se encontraron paquetes asociados a $release."
        return 1
    fi

    echo
    echo "Se desinstalarán mediante APT:"
    printf '  %s\n' "${PAQUETES[@]}"
    echo
    read -rp "¿Continuar? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return 0 ;;
    esac

    sudo apt-get remove -- "${PAQUETES[@]}" || return 1
    sudo update-grub || return 1
    echo "Kernel eliminado: $release"
}

main() {
    local activo predeterminado opcion

    for herramienta in dpkg-query apt-cache apt-get update-grub; do
        command -v "$herramienta" >/dev/null 2>&1 || {
            echo "Falta la herramienta: $herramienta"
            return 1
        }
    done

    activo="$(uname -r)"
    predeterminado="$(release_predeterminado || true)"
    listar_kernels
    mostrar_kernels "$activo" "$predeterminado" || return 1

    read -rp "Seleccionar: " opcion
    [[ "$opcion" == "0" ]] && return 0

    if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] &&
       ((opcion <= ${#KERNELS[@]})); then
        desinstalar_kernel \
            "${KERNELS[$((opcion - 1))]}" "$activo" "$predeterminado"
    else
        echo "Opción inválida."
        return 1
    fi
}

main "$@"
