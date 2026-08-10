#!/usr/bin/env bash

set -u
set -o pipefail

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/.kernels"
CFG_DIR="$BASE_DIR/.cfgs"
mkdir -p "$KERNEL_DIR" "$CFG_DIR"

listar() {
    mapfile -t FUENTES < <(
        find "$KERNEL_DIR" -mindepth 1 -maxdepth 1 -type d \
            ! -name '.*' -printf '%f\n' | sort -V
    )
}

mostrar() {
    echo
    echo "=== Configurar kernel ==="
    echo
    ((${#FUENTES[@]})) || {
        echo "No hay fuentes en $KERNEL_DIR"
        return 1
    }
    local i
    for i in "${!FUENTES[@]}"; do
        printf "%2d) %s\n" "$((i + 1))" "${FUENTES[$i]}"
    done
    echo " 0) Salir"
    echo
}

analizar_nombre() {
    local nombre="$1" fuente="$2" resto tmp

    VERSION="$(make -s -C "$fuente" kernelversion 2>/dev/null)" || return 1

    if [[ "$nombre" != "$VERSION"-* ]]; then
        echo "Nombre inválido. Debe ser: VERSION-BASE-HARDWARE[-PERFIL...]"
        echo "Ejemplo: ${VERSION}-generic-any-ultralight"
        return 1
    fi

    resto="${nombre#"$VERSION"-}"
    [[ "$resto" == *-* ]] || {
        echo "Falta HARDWARE. Para hardware general usá 'any'."
        return 1
    }

    BASE="${resto%%-*}"
    tmp="${resto#*-}"
    HARDWARE="${tmp%%-*}"
    [[ "$tmp" == *-* ]] && PERFIL="${tmp#*-}" || PERFIL=""
}

elegir_base() {
    local perfil_dir="$1"
    local padre_hw="$CFG_DIR/${VERSION}-${BASE}-${HARDWARE}/.config"
    local padre_any="$CFG_DIR/${VERSION}-${BASE}-any/.config"
    local actual="/boot/config-$(uname -r)"

    NECESITA_HARDWARE=false

    if [[ -f "$perfil_dir/.config" ]]; then
        CONFIG_ORIGEN="$perfil_dir/.config"
    elif [[ -n "$PERFIL" && -f "$padre_hw" ]]; then
        CONFIG_ORIGEN="$padre_hw"
    elif [[ "$HARDWARE" != any && -f "$padre_any" ]]; then
        CONFIG_ORIGEN="$padre_any"
        NECESITA_HARDWARE=true
    elif [[ "$HARDWARE" != any ]]; then
        echo "Primero configure ${VERSION}-${BASE}-any"
        return 1
    elif [[ -r "$actual" ]]; then
        CONFIG_ORIGEN="$actual"
    else
        echo "No se encontró una configuración base."
        return 1
    fi
}

comprobar_herramientas() {
    local herramienta
    local -a faltantes=()

    for herramienta in make gcc flex bison; do
        command -v "$herramienta" >/dev/null 2>&1 || \
            faltantes+=("$herramienta")
    done

    ((${#faltantes[@]} == 0)) && return 0

    printf 'Faltan herramientas necesarias para configurar Kconfig: %s\n' \
        "${faltantes[*]}"
    return 1
}

cfg_on() {
    "$FUENTE/scripts/config" --file "$WORK/.config" --enable "$1"
}

cfg_off() {
    "$FUENTE/scripts/config" --file "$WORK/.config" --disable "$1"
}

preparar() {
    local sufijo
    rm -rf -- "$WORK"
    mkdir -p "$WORK" "$PERFIL_DIR"

    cp -a -- "$CONFIG_ORIGEN" "$WORK/.config"
    cp -a -- "$CONFIG_ORIGEN" "$PERFIL_DIR/config-base"

    sufijo="${NOMBRE#"$VERSION"}"
    "$FUENTE/scripts/config" --file "$WORK/.config" \
        --set-str LOCALVERSION "$sufijo"
    cfg_off LOCALVERSION_AUTO

    # Evita referencias a certificados de Ubuntu/Debian que no existen
    # dentro del árbol upstream.
    "$FUENTE/scripts/config" --file "$WORK/.config" \
        --set-str SYSTEM_TRUSTED_KEYS ""
    "$FUENTE/scripts/config" --file "$WORK/.config" \
        --set-str SYSTEM_REVOCATION_KEYS ""

    make -C "$FUENTE" O="$WORK" olddefconfig
}

hardware() {
    local -a estados

    $NECESITA_HARDWARE || {
        echo "Hardware: heredado de la configuración base."
        return 0
    }

    case "$HARDWARE" in
        any)
            echo "Hardware: any (sin recorte específico)."
            ;;
        yarara)
            echo "Hardware: yarara (localmodconfig)."
            echo "Se guardará la lista de módulos cargados en lsmod.txt."
            lsmod > "$PERFIL_DIR/lsmod.txt" || return 1
            yes "" | make -C "$FUENTE" O="$WORK" \
                LSMOD="$PERFIL_DIR/lsmod.txt" localmodconfig
            estados=("${PIPESTATUS[@]}")
            if ((estados[1] != 0)); then
                echo "localmodconfig falló con código ${estados[1]}."
                return "${estados[1]}"
            fi
            ;;
        *)
            echo "Hardware '$HARDWARE': sin reglas automáticas."
            echo "Se conserva la base; podés usar menuconfig al final."
            ;;
    esac
}

ultralight() {
    echo "Perfil: ultralight"
    cfg_off DEBUG_INFO
    cfg_off DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
    cfg_off DEBUG_INFO_DWARF4
    cfg_off DEBUG_INFO_DWARF5
    cfg_on DEBUG_INFO_NONE
    make -C "$FUENTE" O="$WORK" olddefconfig
}

ultrasecure() {
    echo "Perfil: ultrasecure"
    local x
    local opciones=(
        SECURITY SECURITY_YAMA HARDENED_USERCOPY FORTIFY_SOURCE
        STACKPROTECTOR STACKPROTECTOR_STRONG RANDOMIZE_BASE VMAP_STACK
        INIT_ON_ALLOC_DEFAULT_ON INIT_ON_FREE_DEFAULT_ON
        SLAB_FREELIST_RANDOM SLAB_FREELIST_HARDENED
        STRICT_KERNEL_RWX STRICT_MODULE_RWX
    )
    for x in "${opciones[@]}"; do cfg_on "$x"; done
    make -C "$FUENTE" O="$WORK" olddefconfig
}

perfiles() {
    [[ -n "$PERFIL" ]] || {
        echo "Perfil: ninguno."
        return 0
    }

    local -a lista
    local p
    IFS='-' read -r -a lista <<< "$PERFIL"

    for p in "${lista[@]}"; do
        case "$p" in
            ultralight) ultralight || return 1 ;;
            ultrasecure) ultrasecure || return 1 ;;
            *) echo "Perfil '$p': sin reglas automáticas." ;;
        esac
    done
}

menuconfig() {
    make -C "$FUENTE" O="$WORK" menuconfig || {
        echo "menuconfig falló. En Mint suele requerir libncurses-dev."
        return 1
    }
    make -C "$FUENTE" O="$WORK" olddefconfig
}

guardar() {
    local release
    release="$(make -s -C "$FUENTE" O="$WORK" kernelrelease)" || return 1

    if [[ "$release" != "$NOMBRE" ]]; then
        echo "Identidad incorrecta: esperado '$NOMBRE', obtenido '$release'."
        return 1
    fi

    [[ -f "$PERFIL_DIR/.config" ]] && \
        cp -a -- "$PERFIL_DIR/.config" "$PERFIL_DIR/.config.bak"

    cp -a -- "$WORK/.config" "$PERFIL_DIR/.config"
    printf '%s\n' "$release" > "$PERFIL_DIR/kernel-release"
    printf '%s\n' "$CONFIG_ORIGEN" > "$PERFIL_DIR/config-origin"
    date --iso-8601=seconds > "$PERFIL_DIR/configured-at"

    if [[ -x "$FUENTE/scripts/diffconfig" ]]; then
        "$FUENTE/scripts/diffconfig" \
            "$PERFIL_DIR/config-base" "$PERFIL_DIR/.config" \
            > "$PERFIL_DIR/config.diff" 2>/dev/null || true
    fi

    echo
    echo "Guardado: .cfgs/$NOMBRE/.config"
    echo "Listo para compilar.sh"
}

configurar() {
    NOMBRE="$1"
    FUENTE="$KERNEL_DIR/$NOMBRE"
    PERFIL_DIR="$CFG_DIR/$NOMBRE"
    WORK="$PERFIL_DIR/.configure"

    [[ -f "$FUENTE/Makefile" && -x "$FUENTE/scripts/config" ]] || {
        echo "El directorio no parece un árbol fuente válido."
        return
    }

    analizar_nombre "$NOMBRE" "$FUENTE" || return
    comprobar_herramientas || return 1

    echo
    echo "Versión : $VERSION"
    echo "Base    : $BASE"
    echo "Hardware: $HARDWARE"
    echo "Perfil  : ${PERFIL:-ninguno}"
    echo

    elegir_base "$PERFIL_DIR" || return
    echo "Config base: $CONFIG_ORIGEN"

    preparar || return
    hardware || return
    perfiles || return

    echo
    echo "1) Guardar configuración automática"
    echo "2) Abrir menuconfig y guardar"
    echo "0) Cancelar"
    echo
    read -rp "Opción: " op

    case "$op" in
        1) guardar ;;
        2) menuconfig && guardar ;;
        0) echo "Cancelado." ;;
        *) echo "Opción inválida." ;;
    esac
}

listar
mostrar || exit 0
read -rp "Seleccionar: " op
[[ "$op" == 0 ]] && exit 0

if [[ "$op" =~ ^[1-9][0-9]*$ ]] && ((op <= ${#FUENTES[@]})); then
    configurar "${FUENTES[$((op - 1))]}"
else
    echo "Opción inválida."
    exit 1
fi
