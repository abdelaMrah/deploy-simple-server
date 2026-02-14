#!/bin/sh
# Affiche quel conteneur Docker utilise le port 80
echo "Conteneurs utilisant le port 80 ou 443 :"
docker ps --filter "publish=80" --filter "publish=443" --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
echo ""
echo "Tous les conteneurs avec des ports mappés :"
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | head -20
