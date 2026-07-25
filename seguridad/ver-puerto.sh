#!/usr/bin/env bash

PUERTO="${1:-8001}"
[[ "$PUERTO" =~ ^[0-9]+$ ]] || {
    echo "Puerto inválido: $PUERTO" >&2
    exit 2
}

if command -v ss >/dev/null 2>&1; then
    ss -tuln | awk -v puerto=":$PUERTO" '$5 ~ puerto "$"'
else
    netstat -tuln | awk -v puerto=":$PUERTO" '$4 ~ puerto "$"'
fi
