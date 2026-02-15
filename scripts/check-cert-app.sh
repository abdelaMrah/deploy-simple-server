#!/bin/sh
# Affiche le certificat TLS réellement servi pour app.rally-logistique.cloud.
# À lancer depuis le serveur ou une machine où le DNS pointe vers le serveur.
# Utile pour diagnostiquer l'erreur Chrome « unusual and incorrect credentials » / HSTS.

HOST="${1:-app.rally-logistique.cloud}"
PORT="${2:-443}"

echo "=== Certificat servi pour ${HOST}:${PORT} ==="
echo ""
printf "Subject (domaine attendu: %s): " "$HOST"
echo | openssl s_client -connect "${HOST}:${PORT}" -servername "$HOST" 2>/dev/null | openssl x509 -noout -subject 2>/dev/null || echo "Échec (connexion ou openssl)"
echo ""
printf "Issuer: "
echo | openssl s_client -connect "${HOST}:${PORT}" -servername "$HOST" 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null || echo "—"
echo ""
printf "Validité: "
echo | openssl s_client -connect "${HOST}:${PORT}" -servername "$HOST" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "—"
echo ""
echo "Si Subject ne contient pas « CN = ${HOST} » (ou équivalent), le mauvais certificat est servi."
echo "Voir README section « Chrome : unusual and incorrect credentials » pour la marche à suivre."
