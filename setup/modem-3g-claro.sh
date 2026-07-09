#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
CON_NAME="Claro 3G"
APN="igprs.claro.com.ar"
USER="claro"
PASS="claro"
# Tiempo máximo de espera (segundos)
WAIT_USB=20
WAIT_MM=30

say() { echo -e "[*] $*"; }
ok()  { echo -e "[OK] $*"; }
warn(){ echo -e "[!!] $*" >&2; }
die() { echo -e "[ERR] $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Falta el comando '$1'. Instalalo y reintenta."
}

need_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo -E bash "$0" "$@"
  fi
}

# ---- Dependencias ----
need_root "$@"
say "Verificando dependencias…"
apt-get update -y >/dev/null
apt-get install -y usb-modeswitch usb-modeswitch-data modemmanager network-manager >/dev/null
require_cmd lsusb
require_cmd nmcli
require_cmd mmcli
require_cmd usb_modeswitch

# ---- Detectar Huawei ----
say "Buscando dispositivo Huawei…"
HUAWEI_LINE="$(lsusb | grep -i 'Huawei' || true)"
[[ -z "$HUAWEI_LINE" ]] && die "No se ve ningún dispositivo Huawei en lsusb. Conectá el E3131 y reintentá."
ok "Detectado: $HUAWEI_LINE"

VID="$(echo "$HUAWEI_LINE" | sed -n 's/.*ID \([0-9a-fA-F]\+\):\([0-9a-fA-F]\+\).*/\1/p' | head -n1)"
PID="$(echo "$HUAWEI_LINE" | sed -n 's/.*ID \([0-9a-fA-F]\+\):\([0-9a-fA-F]\+\).*/\2/p' | head -n1)"

say "VID:PID actual = $VID:$PID"

# Algunos PIDs típicos:
# 12d1:1f01 => Modo almacenamiento (CD virtual)
# 12d1:14dc / 12d1:1506 / 12d1:14db => Modos módem/HiLink variados

if [[ "${VID,,}" == "12d1" && "${PID,,}" == "1f01" ]]; then
  say "Está en modo almacenamiento. Intentando cambiar a modo módem (usb_modeswitch)…"
  usb_modeswitch -v 0x12d1 -p 0x1f01 -J >/dev/null 2>&1 || warn "usb_modeswitch devolvió advertencia (puede ser normal)."
  say "Esperando a que reaparezca el dispositivo (hasta ${WAIT_USB}s)…"
  for ((i=0;i<WAIT_USB;i++)); do
    sleep 1
    if lsusb | grep -qi 'Huawei'; then
      NEW_LINE="$(lsusb | grep -i 'Huawei' | head -n1)"
      NEW_VID="$(echo "$NEW_LINE" | sed -n 's/.*ID \([0-9a-fA-F]\+\):\([0-9a-fA-F]\+\).*/\1/p')"
      NEW_PID="$(echo "$NEW_LINE" | sed -n 's/.*ID \([0-9a-fA-F]\+\):\([0-9a-fA-F]\+\).*/\2/p')"
      if [[ "$NEW_PID" != "$PID" ]]; then
        ok "Cambio de modo detectado: ahora $NEW_VID:$NEW_PID"
        break
      fi
    fi
  done
fi

# ---- ¿HiLink (Ethernet USB) o Módem (ModemManager)? ----
# HiLink suele aparecer como interfaz de red (cdc_ether / huawei_cdc_ncm)
say "Comprobando interfaces de red USB tipo HiLink…"
HILINK_IFS="$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="ethernet"{print $1}')"

choose_hilink_if() {
  for dev in $HILINK_IFS; do
    # Filtramos interfaces del kernel 'enx...' que suelen ser los USB-Ethernet
    if [[ "$dev" =~ ^enx ]]; then
      echo "$dev"
      return 0
    fi
  done
  return 1
}

if HIFACE="$(choose_hilink_if)"; then
  say "Parece un E3131 en modo HiLink (interfaz $HIFACE). Intentando conectar por DHCP…"
  nmcli device set "$HIFACE" managed yes || true
  nmcli device connect "$HIFACE" || true
  # Forzamos DHCP si quedara desconectado
  state="$(nmcli -t -f DEVICE,STATE device | awk -F: -v d="$HIFACE" '$1==d{print $2}')"
  if [[ "$state" != "connected" ]]; then
    nmcli connection add type ethernet ifname "$HIFACE" con-name "$CON_NAME-HiLink" autoconnect yes >/dev/null 2>&1 || true
    nmcli connection up "$CON_NAME-HiLink" || true
  fi
  ok "Conexión enviada a NetworkManager. Probando conectividad…"
else
  # ---- Camino ModemManager (PPP/NCM) ----
  say "No se detectó HiLink. Usaremos ModemManager/NM (PPP/NCM)."
  say "Esperando a que ModemManager detecte el módem (hasta ${WAIT_MM}s)…"
  for ((i=0;i<WAIT_MM;i++)); do
    sleep 1
    if mmcli -L | grep -q 'Modem'; then
      ok "Módem detectado por ModemManager:"
      mmcli -L
      break
    fi
    [[ $i -eq $((WAIT_MM-1)) ]] && die "No se detectó el módem a tiempo. Probá reinsertar el E3131 y reejecutar."
  done

  # Crear conexión si no existe
  if ! nmcli -t -f NAME connection show | grep -Fxq "$CON_NAME"; then
    say "Creando conexión '$CON_NAME' (APN: $APN)…"
    nmcli connection add type gsm ifname "*" con-name "$CON_NAME" \
      gsm.apn "$APN" gsm.username "$USER" gsm.password "$PASS" gsm.number "*99#" \
      ipv4.method auto ipv6.method ignore connection.autoconnect yes >/dev/null
    ok "Conexión creada."
  else
    say "Conexión '$CON_NAME' ya existe. Actualizando parámetros básicos…"
    nmcli connection modify "$CON_NAME" gsm.apn "$APN" gsm.username "$USER" gsm.password "$PASS" gsm.number "*99#" ipv4.method auto ipv6.method ignore connection.autoconnect yes
  fi

  say "Levantando conexión '$CON_NAME'…"
  nmcli connection up "$CON_NAME" || warn "NetworkManager tardó en conectar; igual probaremos conectividad."
fi

# ---- Probar conectividad ----
say "Probando conectividad (ping)…"
if ping -c 3 -W 3 8.8.8.8 >/dev/null 2>&1; then
  ok "Conectividad IP OK (8.8.8.8)."
else
  warn "No respondió 8.8.8.8. ¿Hay señal 3G/4G suficiente?"
fi

if ping -c 2 -W 3 google.com >/dev/null 2>&1; then
  ok "Resolución DNS OK (google.com)."
else
  warn "DNS no respondió. Podrías probar: nmcli con show, revisar APN o señal."
fi

ok "Listo. Si quedó conectado, ya tenés Internet por el E3131."

