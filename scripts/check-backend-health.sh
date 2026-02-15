#!/bin/sh
# Diagnostic du healthcheck du backend (rally-backend).
# À lancer depuis la racine du projet : sh scripts/check-backend-health.sh

set -e
cd "$(dirname "$0")/.."

echo "=== 1. Statut du conteneur backend ==="
docker ps -a --filter "name=rally-backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=== 2. Test du healthcheck (GET /api depuis le conteneur) ==="
docker exec rally-backend wget -q --spider "http://localhost:4000/api" 2>&1 && echo "OK (exit 0)" || echo "ÉCHEC (le backend ne renvoie pas 2xx sur GET /api)"

echo ""
echo "=== 3. Dernières lignes des logs backend ==="
docker compose logs --tail 30 backend 2>&1

echo ""
echo "Si le test en 2. échoue, le backend doit répondre 2xx sur GET /api (ou ajouter GET /api/health)."
echo "Voir README : section « Backend unhealthy »."
