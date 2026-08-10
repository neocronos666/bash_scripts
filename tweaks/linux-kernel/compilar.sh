#!/usr/bin/env bash

set -u
set -o pipefail

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$BASE_DIR/.kernels"
CFG_DIR="$BASE_DIR/.cfgs"

mkdir -p "$KERNEL_DIR" "$CFG_DIR"

REQUIRED_PACKAGES=(
    build-essential
    bc
    bison
    flex
    libssl-dev
    libelf-dev
    libdw-dev
    dwarves
    kmod
    rsync
    fakeroot
    dpkg-dev
    debhelper
)

listar_fuentes() {
    mapfile -t FUENTES < <(
        find "$KERNEL_DIR" -mindepth 1 -maxdepth 1 -type d \
            ! -name '.*' -printf '%f\n' |
        sort -V
    )
}

mostrar_fuentes() {
    echo
    echo "=== Compilar kernel ==="
    echo

    if ((${#FUENTES[@]} == 0)); then
        echo "No hay árboles fuente en:"
        echo "$KERNEL_DIR"
        return 1
    fi

    local i
    for i in "${!FUENTES[@]}"; do
        printf "%2d) %s\n" "$((i + 1))" "${FUENTES[$i]}"
    done

    echo
    echo " 0) Salir"
    echo
}

comprobar_dependencias() {
    local faltantes=()
    local paquete
    local respuesta

    command -v dpkg-query >/dev/null 2>&1 || {
        echo "Este script espera un sistema Debian/Ubuntu/Mint."
        return 1
    }

    for paquete in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$paquete" 2>/dev/null |
             grep -q '^install ok installed$'; then
            faltantes+=("$paquete")
        fi
    done

    if ((${#faltantes[@]} == 0)); then
        echo "Dependencias: OK"
        return 0
    fi

    echo
    echo "Faltan dependencias:"
    printf '  %s\n' "${faltantes[@]}"
    echo
    read -rp "¿Instalarlas ahora con apt? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí)
            sudo apt-get install -y "${faltantes[@]}" || return 1
            ;;
        *)
            echo "No se puede compilar sin las dependencias."
            return 1
            ;;
    esac
}

comprobar_espacio() {
    local disponible_kb minimo_kb
    local respuesta

    minimo_kb=$((12 * 1024 * 1024))

    disponible_kb="$(
        df -Pk "$CFG_DIR" |
        awk 'NR==2 {print $4}'
    )"

    echo "Espacio libre para build: $((disponible_kb / 1024 / 1024)) GiB"

    if ((disponible_kb < minimo_kb)); then
        echo
        echo "Aviso: hay menos de 12 GiB libres."
        echo "La documentación del kernel recomienda aproximadamente"
        echo "12 GiB para fuentes y artefactos de una compilación normal."
        echo
        read -rp "¿Intentar compilar igualmente? [s/N]: " respuesta

        case "${respuesta,,}" in
            s|si|sí) ;;
            *) return 1 ;;
        esac
    fi
}

preparar_config() {
    local fuente="$1"
    local perfil="$2"
    local build="$3"
    local nombre="$4"
    local version sufijo config_actual

    version="$(make -s -C "$fuente" kernelversion)" || return 1

    if [[ "$nombre" == "$version" ]]; then
        sufijo=""
    elif [[ "$nombre" == "$version"-* ]]; then
        sufijo="${nombre#$version}"
    else
        echo
        echo "El nombre del directorio debe comenzar con la versión"
        echo "del código fuente."
        echo "Fuente detectada: $version"
        echo "Directorio:       $nombre"
        return 1
    fi

    mkdir -p "$perfil" "$build"

    if [[ -f "$perfil/.config" ]]; then
        echo "Configuración base: .cfgs/$nombre/.config"
        cp -a -- "$perfil/.config" "$build/.config"
    else
        config_actual="/boot/config-$(uname -r)"

        [[ -r "$config_actual" ]] || {
            echo "No se encontró una configuración base:"
            echo "$config_actual"
            return 1
        }

        echo "Configuración base: $config_actual"
        cp -a -- "$config_actual" "$build/.config"
    fi

    "$fuente/scripts/config" \
        --file "$build/.config" \
        --set-str LOCALVERSION "$sufijo"

    "$fuente/scripts/config" \
        --file "$build/.config" \
        --disable LOCALVERSION_AUTO

    # Ajuste para una configuración heredada de Debian/Ubuntu:
    # evita referencias a certificados de la distribución que no existen
    # dentro del árbol upstream.
    "$fuente/scripts/config" \
        --file "$build/.config" \
        --set-str SYSTEM_TRUSTED_KEYS ""

    "$fuente/scripts/config" \
        --file "$build/.config" \
        --set-str SYSTEM_REVOCATION_KEYS ""

    make -C "$fuente" O="$build" olddefconfig || return 1

    cp -a -- "$build/.config" "$perfil/.config"

    KERNEL_RELEASE="$(make -s -C "$fuente" O="$build" kernelrelease)" ||
        return 1

    if [[ "$KERNEL_RELEASE" != "$nombre" ]]; then
        echo
        echo "La identidad calculada del kernel no coincide."
        echo "Directorio:    $nombre"
        echo "Kernelrelease: $KERNEL_RELEASE"
        return 1
    fi

    printf '%s\n' "$KERNEL_RELEASE" > "$perfil/kernel-release"
}

limpiar_paquetes_anteriores() {
    local perfil="$1"

    rm -rf -- "$perfil/packages"
    mkdir -p "$perfil/packages"

    find "$perfil" -maxdepth 1 -type f \
        \( -name '*.deb' -o -name '*.changes' -o -name '*.buildinfo' \) \
        -delete
}

guardar_paquetes() {
    local perfil="$1"
    local packages="$perfil/packages"
    local encontrado=false
    local archivo

    while IFS= read -r -d '' archivo; do
        mv -- "$archivo" "$packages/"
        encontrado=true
    done < <(
        find "$perfil" -maxdepth 1 -type f \
            \( -name '*.deb' -o -name '*.changes' -o -name '*.buildinfo' \) \
            -print0
    )

    $encontrado
}

compilar_fuente() {
    local nombre="$1"
    local fuente="$KERNEL_DIR/$nombre"
    local perfil="$CFG_DIR/$nombre"
    local build="$perfil/.build"
    local log="$perfil/build.log"
    local jobs
    local respuesta

    [[ -f "$fuente/Makefile" ]] || {
        echo "No parece un árbol fuente válido: $nombre"
        return
    }

    echo
    echo "Fuente seleccionada: $nombre"
    echo

    comprobar_dependencias || return
    comprobar_espacio || return

    if command -v mokutil >/dev/null 2>&1 &&
       mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
        echo
        echo "AVISO: Secure Boot está habilitado."
        echo "La compilación puede hacerse, pero un kernel propio"
        echo "puede no arrancar hasta resolver su firma."
        echo
        read -rp "¿Continuar con la compilación? [s/N]: " respuesta
        case "${respuesta,,}" in
            s|si|sí) ;;
            *) return ;;
        esac
    fi

    preparar_config "$fuente" "$perfil" "$build" "$nombre" || return
    limpiar_paquetes_anteriores "$perfil"

    jobs="$(nproc 2>/dev/null || echo 1)"

    echo
    echo "Kernel:  $KERNEL_RELEASE"
    echo "Jobs:    $jobs"
    echo "Build:   .cfgs/$nombre/.build/"
    echo "Log:     .cfgs/$nombre/build.log"
    echo
    read -rp "¿Compilar? [s/N]: " respuesta

    case "${respuesta,,}" in
        s|si|sí) ;;
        *) echo "Cancelado."; return ;;
    esac

    echo
    echo "Compilando y generando paquetes .deb..."
    echo "Se omite el paquete -dbg para ahorrar espacio."
    echo

    if make -C "$fuente" \
        O="$build" \
        -j"$jobs" \
        DPKG_FLAGS="--build-profiles=pkg.linux-upstream.nokerneldbg" \
        bindeb-pkg 2>&1 | tee "$log"; then

        cp -a -- "$build/.config" "$perfil/.config"

        if guardar_paquetes "$perfil"; then
            printf '%s\n' "$KERNEL_RELEASE" > "$perfil/kernel-release"
            date --iso-8601=seconds > "$perfil/compiled-at"

            echo
            echo "Compilación terminada."
            echo
            echo "Paquetes:"
            find "$perfil/packages" -maxdepth 1 -type f \
                -name '*.deb' -printf '  %f\n' |
                sort
        else
            echo
            echo "La compilación terminó, pero no se encontraron paquetes .deb."
        fi
    else
        echo
        echo "La compilación falló."
        echo "Revisá:"
        echo "  $log"
    fi
}

listar_fuentes
mostrar_fuentes || exit 0

read -rp "Seleccionar: " opcion
[[ "$opcion" == "0" ]] && exit 0

if [[ "$opcion" =~ ^[1-9][0-9]*$ ]] &&
   ((opcion >= 1 && opcion <= ${#FUENTES[@]})); then
    compilar_fuente "${FUENTES[$((opcion - 1))]}"
else
    echo "Opción inválida."
    exit 1
fi
