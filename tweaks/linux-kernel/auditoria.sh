#!/usr/bin/env bash

# auditoria.sh
# Auditoría previa a instalación/compilación de kernel Linux.
#
# Sólo lectura:
# - No instala paquetes
# - No modifica GRUB
# - No modifica /boot
# - No carga/descarga módulos
clear
set -u

SCRIPT_NAME="$(basename "$0")"

section() {
    printf '\n============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n'
}

subsection() {
    printf '\n--- %s ---\n' "$1"
}

run_if_exists() {
    local command_name="$1"
    shift

    if command -v "$command_name" >/dev/null 2>&1; then
        "$command_name" "$@" 2>&1
    else
        printf '[NO DISPONIBLE] %s\n' "$command_name"
    fi
}

file_if_exists() {
    local file="$1"

    if [[ -r "$file" ]]; then
        cat "$file"
    else
        printf '[NO DISPONIBLE] %s\n' "$file"
    fi
}

echo "Auditoría Linux Kernel"
echo "Host: $(hostname)"
echo "Fecha: $(date --iso-8601=seconds)"
echo "Script: $SCRIPT_NAME"


section "1. SISTEMA"

subsection "Distribución"
file_if_exists /etc/os-release

subsection "Kernel actual"
uname -a

subsection "Arquitectura"
uname -m
getconf LONG_BIT 2>/dev/null || true

subsection "Hostname"
hostnamectl 2>/dev/null || hostname

subsection "Uptime"
uptime


section "2. CPU Y PLATAFORMA"

subsection "CPU"
run_if_exists lscpu

subsection "Información resumida /proc/cpuinfo"
grep -E \
    '^(vendor_id|model name|cpu family|model|stepping|microcode|flags)' \
    /proc/cpuinfo 2>/dev/null |
    head -n 40

subsection "Virtualización"
if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt || true
fi

subsection "DMI / BIOS / UEFI"
if [[ -d /sys/firmware/efi ]]; then
    echo "Arranque actual: UEFI"
else
    echo "Arranque actual: BIOS/Legacy"
fi

for item in \
    sys_vendor \
    product_name \
    product_version \
    board_vendor \
    board_name \
    board_version \
    bios_vendor \
    bios_version \
    bios_date
do
    if [[ -r "/sys/class/dmi/id/$item" ]]; then
        printf '%-20s: %s\n' \
            "$item" \
            "$(cat "/sys/class/dmi/id/$item")"
    fi
done


section "3. HARDWARE"

subsection "PCI"
run_if_exists lspci -nnk

subsection "USB"
run_if_exists lsusb

subsection "Bloques / discos"
run_if_exists lsblk -o \
NAME,PATH,TYPE,SIZE,FSTYPE,FSVER,MOUNTPOINTS,MODEL,SERIAL,TRAN

subsection "Controladores gráficos"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk |
        grep -A4 -Ei \
        'VGA|3D controller|Display controller'
fi

subsection "Red"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk |
        grep -A4 -Ei \
        'Ethernet controller|Network controller'
fi

subsection "Audio"
if command -v lspci >/dev/null 2>&1; then
    lspci -nnk |
        grep -A4 -Ei \
        'Audio device|Multimedia audio'
fi


section "4. KERNEL INSTALADO"

subsection "Versión activa"
uname -r

subsection "Kernels presentes en /boot"
ls -lh /boot 2>/dev/null |
    grep -E \
    'vmlinuz|initrd|System.map|config' ||
    true

subsection "Paquetes kernel instalados"
if command -v dpkg >/dev/null 2>&1; then
    dpkg -l |
        grep -E \
        '^ii[[:space:]]+(linux-image|linux-headers|linux-modules|linux-modules-extra|linux-generic|linux-lowlatency)' ||
        true
fi

subsection "Módulos cargados"
run_if_exists lsmod

subsection "Módulos externos / DKMS"
if command -v dkms >/dev/null 2>&1; then
    dkms status
else
    echo "DKMS no instalado o no disponible."
fi

subsection "Árbol de módulos"
if [[ -d "/lib/modules/$(uname -r)" ]]; then
    du -sh "/lib/modules/$(uname -r)"
    find "/lib/modules/$(uname -r)" \
        -type f \
        -name '*.ko*' |
        wc -l |
        awk '{print "Cantidad de módulos:", $1}'
fi

subsection "Módulos no pertenecientes al árbol estándar"
if command -v modinfo >/dev/null 2>&1; then
    while read -r module _; do
        filename="$(modinfo -F filename "$module" 2>/dev/null || true)"

        case "$filename" in
            /lib/modules/*/updates/*|\
            /lib/modules/*/extra/*|\
            /lib/modules/*/weak-updates/*)
                printf '%-30s %s\n' "$module" "$filename"
                ;;
        esac
    done < <(lsmod | tail -n +2)
fi


section "5. CONFIGURACIÓN DEL KERNEL"

subsection "Config del kernel activo"

CURRENT_CONFIG="/boot/config-$(uname -r)"

if [[ -r "$CURRENT_CONFIG" ]]; then
    echo "Archivo: $CURRENT_CONFIG"
    echo
    grep -E \
        '^CONFIG_(MODULES|MODVERSIONS|SMP|PREEMPT|PREEMPT_DYNAMIC|HZ_|X86_64|EFI|EFI_STUB|ACPI|KVM|BPF|VMLINUX|DEBUG_INFO|LOCALVERSION|IKCONFIG|IKCONFIG_PROC|SECURITY|LOCK_DOWN_KERNEL|MODULE_SIG|MODULE_SIG_FORCE|MODULE_COMPRESS|ZSTD|XZ)=' \
        "$CURRENT_CONFIG" ||
        true
else
    echo "No encontrado: $CURRENT_CONFIG"
fi


section "6. BOOT / GRUB / SECURE BOOT"

subsection "Modo de arranque"
if [[ -d /sys/firmware/efi ]]; then
    echo "UEFI"
else
    echo "BIOS / Legacy"
fi

subsection "Secure Boot"
if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>&1 || true
else
    echo "mokutil no disponible."
fi

subsection "EFI"
if [[ -d /sys/firmware/efi/efivars ]]; then
    echo "EFI variables disponibles."
fi

subsection "GRUB defaults"
file_if_exists /etc/default/grub

subsection "Entradas GRUB detectadas"

GRUB_CFG=""

for candidate in \
    /boot/grub/grub.cfg \
    /boot/grub2/grub.cfg
do
    if [[ -r "$candidate" ]]; then
        GRUB_CFG="$candidate"
        break
    fi
done

if [[ -n "$GRUB_CFG" ]]; then
    echo "Archivo: $GRUB_CFG"

    grep -E \
        "^[[:space:]]*(menuentry|submenu)[[:space:]]" \
        "$GRUB_CFG" ||
        true
else
    echo "No se encontró grub.cfg."
fi

subsection "Entradas EFI"
if command -v efibootmgr >/dev/null 2>&1; then
    efibootmgr -v
else
    echo "efibootmgr no disponible."
fi


section "7. INITRAMFS"

subsection "Initramfs del kernel actual"

INITRD="/boot/initrd.img-$(uname -r)"

if [[ -r "$INITRD" ]]; then
    ls -lh "$INITRD"

    if command -v lsinitramfs >/dev/null 2>&1; then
        echo
        echo "Módulos relevantes presentes en initramfs:"

        lsinitramfs "$INITRD" |
            grep -E \
            '(/kernel/|firmware/)' |
            head -n 150
    fi
else
    echo "No encontrado: $INITRD"
fi


section "8. FIRMWARE"

subsection "Paquetes firmware"

if command -v dpkg >/dev/null 2>&1; then
    dpkg -l |
        grep -Ei \
        '^ii.*(linux-firmware|firmware-|microcode)' ||
        true
fi

subsection "Microcode"
dmesg 2>/dev/null |
    grep -i microcode |
    head -n 30 ||
    true


section "9. COMPILACIÓN"

subsection "Compilador"
run_if_exists gcc --version

subsection "Clang"
run_if_exists clang --version

subsection "Make"
run_if_exists make --version

subsection "Binutils"
run_if_exists ld --version

subsection "Bison"
run_if_exists bison --version

subsection "Flex"
run_if_exists flex --version

subsection "Perl"
run_if_exists perl --version

subsection "Python"
run_if_exists python3 --version

subsection "pkg-config"
run_if_exists pkg-config --version

subsection "Herramientas Debian"
for cmd in \
    dpkg-buildpackage \
    fakeroot \
    make-kpkg \
    ccache
do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf '%-20s OK: %s\n' "$cmd" "$(command -v "$cmd")"
    else
        printf '%-20s NO\n' "$cmd"
    fi
done


section "10. RECURSOS PARA COMPILACIÓN"

subsection "Memoria"
run_if_exists free -h

subsection "CPU disponibles"
if command -v nproc >/dev/null 2>&1; then
    echo "nproc: $(nproc)"
fi

subsection "Espacio libre"
run_if_exists df -hT /

if [[ -d /boot ]]; then
    run_if_exists df -hT /boot
fi

subsection "Swap"
run_if_exists swapon --show


section "11. ERRORES DEL KERNEL ACTUAL"

subsection "Errores y warnings del boot"

if command -v journalctl >/dev/null 2>&1; then
    journalctl \
        -k \
        -b \
        -p warning..alert \
        --no-pager 2>/dev/null |
        tail -n 200
else
    dmesg --level=warn,err,crit,alert,emerg 2>/dev/null |
        tail -n 200 ||
        true
fi


section "12. RESUMEN"

echo "Host                 : $(hostname)"
echo "Distribución         : $(
    . /etc/os-release
    echo "${PRETTY_NAME:-desconocida}"
)"
echo "Kernel actual        : $(uname -r)"
echo "Arquitectura         : $(uname -m)"

if [[ -d /sys/firmware/efi ]]; then
    echo "Boot                 : UEFI"
else
    echo "Boot                 : BIOS/Legacy"
fi

if command -v mokutil >/dev/null 2>&1; then
    echo -n "Secure Boot          : "
    mokutil --sb-state 2>/dev/null || true
fi

echo
echo "Auditoría finalizada."
