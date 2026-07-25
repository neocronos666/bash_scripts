#!/usr/bin/env bash

HOST_OBJETIVO="${1:-127.0.0.1}"
PUERTO="${2:-8001}"
[[ "$PUERTO" =~ ^[0-9]+$ ]] && ((PUERTO >= 1 && PUERTO <= 65535)) || {
    echo "Puerto inválido: $PUERTO" >&2
    exit 2
}

echo "Objetivo: $HOST_OBJETIVO:$PUERTO"
if command -v nc >/dev/null 2>&1; then
    nc -zv -w 5 "$HOST_OBJETIVO" "$PUERTO"
elif command -v nmap >/dev/null 2>&1; then
    nmap -Pn -p "$PUERTO" -- "$HOST_OBJETIVO"
else
    curl --fail --show-error --head --max-time 5 \
        "http://$HOST_OBJETIVO:$PUERTO"
fi
