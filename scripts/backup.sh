
#!/usr/bin/env bash
set -euo pipefail
STAMP=$(date +%F_%H-%M-%S)
tar -czf n8n_backup_${STAMP}.tar.gz ./data ./db ./redis .env docker-compose.yml
echo "Backup created: n8n_backup_${STAMP}.tar.gz"
