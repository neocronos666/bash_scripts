#!/usr/bin/env bash
clear




set -o nounset
set -o pipefail
# El tablero conserva el control cuando un script secundario devuelve error.

VERSION="0.1.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
BASE_DIR="$SCRIPT_DIR"
GRUB_DEFAULT_FILE="/etc/default/grub"



# Colores compartidos.
# shellcheck source=../../.lib/colores.sh
source "$PROJECT_DIR/.lib/colores.sh" || {
    printf 'Error: no se pudo cargar %s\n' \
        "$PROJECT_DIR/.lib/colores.sh" >&2
    exit 1
}


pausar() {
    echo
    read -rp "Presione ENTER para volver al menú..." _
}

ejecutar_script() {
    local script="$1"
    local ruta="$BASE_DIR/$script"
    local estado

    if [[ ! -f "$ruta" ]]; then
        echo "No se encontró: $script"
    elif [[ ! -x "$ruta" ]]; then
        echo "No es ejecutable: $script"
    else
        "$ruta"
        estado=$?
        if ((estado != 0)); then
            printf '%s terminó con error (código %d).\n' "$script" "$estado"
        fi
    fi
    pausar
}

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

valor_grub() {
    local clave="$1"
    local valor

    valor="$(sed -nE \
        "s/^[[:space:]]*${clave}=(.*)$/\\1/p" \
        "$GRUB_DEFAULT_FILE" 2>/dev/null | tail -n 1)"
    valor="${valor%\"}"
    valor="${valor#\"}"
    valor="${valor%\'}"
    valor="${valor#\'}"
    printf '%s\n' "$valor"
}

selector_grub() {
    local valor

    valor="$(valor_grub GRUB_DEFAULT)"
    if [[ "$valor" == "saved" ]] && command -v grub-editenv >/dev/null; then
        valor="$(grub-editenv list 2>/dev/null |
            sed -n 's/^saved_entry=//p' | head -n 1)"
    fi
    printf '%s\n' "${valor:-0}"
}

listar_entradas_grub() {
    local grub_cfg="$1"

    mapfile -t ENTRADAS_GRUB < <(
        sudo awk -F"'" '
            /^[[:space:]]*submenu / {
                for (i = 1; i <= NF; i++)
                    if ($i ~ /^gnulinux-advanced-/) submenu = $i
            }
            /^[[:space:]]*menuentry / && $0 !~ /recovery mode/ {
                titulo = $2
                id = ""
                for (i = 1; i <= NF; i++)
                    if ($i ~ /^gnulinux-/) id = $i
                pendiente = (id != "")
                next
            }
            pendiente && /\/vmlinuz-/ {
                release = $0
                sub(/^.*\/vmlinuz-/, "", release)
                sub(/[[:space:]].*$/, "", release)
                selector = id
                if (id ~ /-advanced-/ && submenu != "")
                    selector = submenu ">" id
                print release "\t" selector "\t" titulo
                pendiente = 0
            }
        ' "$grub_cfg" | awk -F '\t' '!visto[$1]++' | sort -Vr
    )
}

kernel_predeterminado() {
    local selector="$1"
    local entrada release id titulo
    local selector_final="${selector##*>}"

    for entrada in "${ENTRADAS_GRUB[@]:-}"; do
        IFS=$'\t' read -r release id titulo <<< "$entrada"
        if [[ "$id" == "$selector" || "${id##*>}" == "$selector_final" ]]; then
            printf '%s\n' "$release"
            return 0
        fi
    done

    [[ "$selector" == "0" && ${#ENTRADAS_GRUB[@]} -gt 0 ]] && {
        IFS=$'\t' read -r release id titulo <<< "${ENTRADAS_GRUB[0]}"
        printf '%s\n' "$release"
        return 0
    }

    printf '%s\n' "$selector"
}

establecer_variable_grub() {
    local clave="$1"
    local valor="$2"
    local actual temporal backup

    actual="$(valor_grub "$clave")"
    [[ "$actual" == "$valor" ]] && {
        echo "$clave ya tiene el valor solicitado."
        return 0
    }

    [[ -r "$GRUB_DEFAULT_FILE" ]] || {
        echo "No se puede leer $GRUB_DEFAULT_FILE"
        return 1
    }

    temporal="$(mktemp)" || return 1
    if ! awk -v clave="$clave" -v linea="$clave=$valor" '
        BEGIN { cambiado = 0 }
        $0 ~ "^[[:space:]]*" clave "=" && !cambiado {
            print linea
            cambiado = 1
            next
        }
        { print }
        END { if (!cambiado) print linea }
    ' "$GRUB_DEFAULT_FILE" > "$temporal"; then
        rm -f -- "$temporal"
        return 1
    fi

    backup="${GRUB_DEFAULT_FILE}.bak-kernel-$(date +%Y%m%d-%H%M%S)"
    sudo cp -a -- "$GRUB_DEFAULT_FILE" "$backup" || {
        rm -f -- "$temporal"
        return 1
    }
    sudo install -m 0644 -- "$temporal" "$GRUB_DEFAULT_FILE" || {
        rm -f -- "$temporal"
        return 1
    }
    rm -f -- "$temporal"
    echo "Backup de GRUB: $backup"
}

regenerar_grub() {
    command -v update-grub >/dev/null 2>&1 || {
        echo "No se encontró update-grub."
        return 1
    }
    sudo update-grub
}

elegir_kernel_grub() {
    local i opcion entrada release selector titulo respuesta

    if ((${#ENTRADAS_GRUB[@]} == 0)); then
        echo "No se detectaron kernels arrancables en GRUB."
        return 1
    fi

    echo
    for i in "${!ENTRADAS_GRUB[@]}"; do
        IFS=$'\t' read -r release selector titulo <<< "${ENTRADAS_GRUB[$i]}"
        printf '%2d) %s\n' "$((i + 1))" "$release"
    done
    echo " 0) Cancelar"
    read -rp "Seleccionar: " opcion
    [[ "$opcion" == "0" ]] && return 0

    if [[ ! "$opcion" =~ ^[1-9][0-9]*$ ]] ||
       ((opcion > ${#ENTRADAS_GRUB[@]})); then
        echo "Opción inválida."
        return 1
    fi

    entrada="${ENTRADAS_GRUB[$((opcion - 1))]}"
    IFS=$'\t' read -r release selector titulo <<< "$entrada"
    echo "Nuevo kernel predeterminado: $release"
    read -rp "1=Confirmar, 0=Cancelar: " respuesta
    [[ "$respuesta" == "1" ]] || {
        echo "Cancelado."
        return 0
    }

    establecer_variable_grub GRUB_DEFAULT saved || return 1
    regenerar_grub || return 1
    command -v grub-set-default >/dev/null 2>&1 || {
        echo "No se encontró grub-set-default."
        return 1
    }
    sudo grub-set-default "$selector" || return 1
    echo "Kernel predeterminado: $release"
}

configurar_timeout() {
    local valor

    read -rp "Nuevo GRUB_TIMEOUT (0-300 segundos): " valor
    if [[ ! "$valor" =~ ^[0-9]+$ ]] || ((valor > 300)); then
        echo "El tiempo debe ser un entero entre 0 y 300."
        return 1
    fi
    establecer_variable_grub GRUB_TIMEOUT "$valor" && regenerar_grub
}

configurar_estilo() {
    local opcion estilo

    echo "1) Mostrar menú"
    echo "2) Ocultar menú"
    echo "0) Cancelar"
    read -rp "Opción: " opcion
    case "$opcion" in
        1) estilo=menu ;;
        2) estilo=hidden ;;
        0) return 0 ;;
        *) echo "Opción inválida."; return 1 ;;
    esac
    establecer_variable_grub GRUB_TIMEOUT_STYLE "$estilo" && regenerar_grub
}

configurar_os_prober() {
    local opcion valor

    echo "1) Detectar otros sistemas (recomendado para Windows)"
    echo "2) Desactivar detección de otros sistemas"
    echo "0) Cancelar"
    read -rp "Opción: " opcion
    case "$opcion" in
        1) valor=false ;;
        2) valor=true ;;
        0) return 0 ;;
        *) echo "Opción inválida."; return 1 ;;
    esac
    establecer_variable_grub GRUB_DISABLE_OS_PROBER "$valor" && regenerar_grub
}

menu_grub() {
    local grub_cfg selector predeterminado opcion

    while true; do
        clear 2>/dev/null || true
        grub_cfg="$(buscar_grub_cfg || true)"
        ENTRADAS_GRUB=()
        [[ -n "$grub_cfg" ]] && listar_entradas_grub "$grub_cfg"
        selector="$(selector_grub)"
        predeterminado="$(kernel_predeterminado "$selector")"

        echo "=== GRUB ==="
        echo
        echo "Kernel activo:         $(uname -r)"
        echo "Kernel predeterminado: ${predeterminado:-no detectado}"
        echo
        echo "1) Elegir kernel predeterminado"
        echo "2) Configurar tiempo de espera"
        echo "3) Mostrar/ocultar menú"
        echo "4) Configurar detección de otros sistemas"
        echo "5) Regenerar GRUB"
        echo "0) Volver"
        echo
        read -rp "Opción: " opcion

        case "$opcion" in
            1) elegir_kernel_grub; pausar ;;
            2) configurar_timeout; pausar ;;
            3) configurar_estilo; pausar ;;
            4) configurar_os_prober; pausar ;;
            5) regenerar_grub; pausar ;;
            0) return 0 ;;
            *) echo "Opción inválida."; pausar ;;
        esac
    done
}

mostrar_menu() {

    clear 2>/dev/null || true

    # Banner
    echo -e "${CYAN}┌───────────────────────────────────────────────────────╾${NC}"
    echo -e "${CYAN}│${WHITE}   👾 ${WHITE}Kernel activo:${NC} ${GREEN}$(uname -r)${NC} 👾                      ${CYAN}${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────╾${NC}"
    #echo    
    
    #echo -e " ${WHITE}Kernel activo:${NC} ${GREEN}$(uname -r)${NC}"
    #echo

    # Flujo principal
    echo -e "                    ${CYAN}[${YELLOW}0${CYAN}]${WHITE}VOLVER ${NC}"
    echo -e "                       ${CYAN}│${NC}"
    echo -e "             ${CYAN}┌─────────┴─────────┐${NC}"    
    echo -e "      ${GREEN}✳️  AUTOMÁTICO${NC}         ${RED}✴️  MANUAL${NC}"    
    echo -e "      ${CYAN}[${YELLOW}1${CYAN}]${NC} ${GREEN}auto-update${NC}     ${CYAN}[${YELLOW}2${CYAN}]${NC} ${RED}descargar-kernel${NC}"
    echo -e "             ${CYAN}│                   ↓${NC}"
    echo -e "             ${CYAN}│${NC}        ${CYAN}    [${YELLOW}3${CYAN}]${NC} ${RED}gestionar-kernels${NC}"
    echo -e "             ${CYAN}│                   ↓${NC}"
    echo -e "             ${CYAN}│${NC}        ${CYAN}    [${YELLOW}4${CYAN}]${NC} ${RED}configurar${NC}"
    echo -e "             ${CYAN}↓                   ↓${NC}"
    echo -e "             ${CYAN}│${NC}        ${CYAN}    [${YELLOW}5${CYAN}]${NC} ${RED}compilar${NC}"
    echo -e "             ${CYAN}│                   ↓${NC}"
    echo -e "             ${CYAN}│${NC}        ${CYAN}    [${YELLOW}6${CYAN}]${NC} ${RED}instalar-kernel${NC}"   
    echo -e "             ${CYAN}└─────────┬─────────┘${NC}"
    echo -e "                       ${CYAN}↓${NC}"
    echo -e "                   ${CYAN}[${YELLOW}7${CYAN}]${NC} ${WHITE}GRUB${NC}"
    echo

    # Mantenimiento
    echo -e "                ${WHITE}MANTENIMIENTO${NC}"
    #echo
    echo -e "         ${CYAN}[${YELLOW} 8${CYAN}]${NC} ${WHITE}limpiar descargas/fuentes${NC}"
    echo -e "         ${CYAN}[${YELLOW} 9${CYAN}]${NC} ${WHITE}desinstalar kernels${NC}"
    echo -e "         ${CYAN}[${YELLOW}10${CYAN}]${NC} ${WHITE}auditoría${NC}"
    echo

    # echo -e "                         ${CYAN}[${YELLOW}0${CYAN}]${NC} ${WHITE}SALIR${NC}"
    # echo
}

main() {
    local opcion

    while true; do
        mostrar_menu
        read -r -p "   🗿${USER:-usuario}⭕ " opcion
        case "$opcion" in
            1) ejecutar_script auto-update.sh ;;
            2) ejecutar_script descargar-kernel.sh ;;
            3) ejecutar_script gestionar-kernels.sh ;;
            4) ejecutar_script configurar.sh ;;
            5) ejecutar_script compilar.sh ;;
            6) ejecutar_script instalar-kernel.sh ;;
            7) menu_grub ;;
            8) ejecutar_script limpiar.sh ;;
            9) ejecutar_script desinstalar-kernel.sh ;;
            10) ejecutar_script auditoria.sh ;;
            0) return 0 ;;
            *) echo "Opción inválida."; pausar ;;
        esac
    done
}

main "$@"
