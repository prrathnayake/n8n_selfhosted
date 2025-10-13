
#!/usr/bin/env bash
set -euo pipefail
docker rm -f website >/dev/null 2>&1 || true
docker run -d --name website -p 8090:80 nginx
docker exec website sh -c 'echo "<h1>NetworkChuck Coffee</h1>" > /usr/share/nginx/html/index.html'
echo "Demo site running at http://$(hostname -I | awk "{print $1}"):8090"
