#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT_DIR/data"

N8N_DATA_UID="${N8N_DATA_UID:-${NODE_UID:-1000}}"
N8N_DATA_GID="${N8N_DATA_GID:-${NODE_GID:-1000}}"

if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root so it can adjust ownership of bind-mounted directories." >&2
  echo "Re-run with sudo, for example: sudo N8N_DATA_UID=$N8N_DATA_UID N8N_DATA_GID=$N8N_DATA_GID $0" >&2
  exit 1
fi

mkdir -p "$DATA_DIR"

chown -R "$N8N_DATA_UID":"$N8N_DATA_GID" "$DATA_DIR"
chmod -R ug+rwX "$DATA_DIR"

echo "Successfully set ownership of $DATA_DIR to ${N8N_DATA_UID}:${N8N_DATA_GID}."
