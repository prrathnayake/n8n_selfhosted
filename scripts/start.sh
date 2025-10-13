
#!/usr/bin/env bash
set -euo pipefail
docker compose pull
docker compose up -d
echo "n8n is starting on port ${N8N_PORT:-5678}"
