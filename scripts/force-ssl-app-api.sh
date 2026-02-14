#!/bin/sh
# À lancer sur le serveur (dans ~/deploy-simple-server) pour forcer la
# demande de certificats HTTPS pour app et api.
set -e
cd "$(dirname "$0")/.."

echo "=== 1. Vérification des conteneurs backend et app ==="
docker ps -a --filter "name=rally-backend" --filter "name=rally-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== 2. Certificats présents dans le volume (proxy) ==="
docker exec rally-nginx-proxy ls -la /etc/nginx/certs/ 2>/dev/null || echo "Impossible de lister (conteneur proxy arrêté ?)"

echo ""
echo "=== 3. Redémarrage de acme-companion pour rescan ==="
docker compose restart acme

echo ""
echo "=== 4. Attendre 10 s puis afficher les logs acme (Ctrl+C pour quitter) ==="
sleep 10
docker compose logs -f acme 2>&1 | head -200
