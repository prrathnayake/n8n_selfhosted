#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to import workflows" >&2
  exit 1
fi

COMPOSE_CMD="docker compose"
if ! docker compose version >/dev/null 2>&1; then
  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
  else
    echo "docker compose or docker-compose is required" >&2
    exit 1
  fi
fi

cd "$(dirname "$0")/.."

IMPORT_DIR="$(pwd)/data/import"
mkdir -p "$IMPORT_DIR"
rm -f "$IMPORT_DIR"/*.json 2>/dev/null || true

shopt -s nullglob
workflow_exports=(workflows/*.json)
shopt -u nullglob

if (( ${#workflow_exports[@]} == 0 )); then
  echo "No workflow exports were found in the workflows directory." >&2
  exit 1
fi

cp "${workflow_exports[@]}" "$IMPORT_DIR"/

$COMPOSE_CMD ps >/dev/null 2>&1

STACK_STATUS="$($COMPOSE_CMD ps --services --status=running 2>/dev/null | grep '^n8n$' || true)"
if [[ -z "$STACK_STATUS" ]]; then
  echo "n8n service is not running. Start the stack before importing." >&2
  exit 1
fi

$COMPOSE_CMD exec -T n8n bash -lc '
set -euo pipefail
IMPORT_PATH="$HOME/.n8n/import"
for workflow in "$IMPORT_PATH"/*.json; do
  [[ -f "$workflow" ]] || continue
  echo "Importing $(basename "$workflow")"
  n8n import:workflow --input "$workflow" --separate --force >/dev/null
  echo "Imported $(basename "$workflow")"
done
'

echo "All workflows imported. Review credentials in the n8n UI before running them."
