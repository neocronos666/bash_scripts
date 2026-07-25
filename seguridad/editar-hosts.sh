#!/usr/bin/env bash

set -o errexit

EDITOR_BIN="${EDITOR:-nano}"
command -v "$EDITOR_BIN" >/dev/null 2>&1 || {
    printf 'Error: no se encontró el editor %s.\n' "$EDITOR_BIN" >&2
    exit 1
}

sudo "$EDITOR_BIN" /etc/hosts
