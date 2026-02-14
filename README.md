# Reverse proxy nginx + HTTPS – Rally Logistique

Reverse proxy **nginxproxy/nginx-proxy** avec **acme-companion** pour certificats Let's Encrypt.  
Exposé sur les ports **80** (HTTP) et **443** (HTTPS).

## Prérequis

- Les DNS des domaines ci-dessous doivent pointer vers l’IP du serveur **avant** de lancer (Let's Encrypt vérifie les domaines).
- Structure des dépôts : ce projet (`deploy-simple-server`) doit être au même niveau que les 4 applications, chacune avec son propre `Dockerfile` :
  - **Site** : `../site` → https://rally-logistique.cloud
  - **Backend** : `../logistia-backend` → https://api.rally-logistique.cloud
  - **Frontend** : `../logistia-frontend` → https://app.rally-logistique.cloud
  - **Mail server** : `../mail-server` (interne)

## URLs (HTTPS)

| Service               | URL                                     |
| --------------------- | --------------------------------------- |
| Site web              | https://rally-logistique.cloud          |
| Frontend              | https://app.rally-logistique.cloud      |
| API Backend           | https://api.rally-logistique.cloud      |
| pgAdmin (DB)          | https://db.rally-logistique.cloud       |
| MinIO (S3)            | https://s3.rally-logistique.cloud       |
| RabbitMQ (management) | https://rabbitmq.rally-logistique.cloud |

PostgreSQL et Redis sont **internes** (accessibles uniquement entre conteneurs, pas exposés en public).

## Configuration

Copiez `.env.example` en `.env` et renseignez toutes les variables (mot de passe, secrets, email Let's Encrypt) :

```bash
cp .env.example .env
# Éditer .env
```

## Démarrage

```bash
docker compose up -d
```

- **HTTP** : http://rally-logistique.cloud
- **HTTPS** : https://rally-logistique.cloud

Au premier démarrage, acme-companion demande les certificats ; le site peut être en HTTP uniquement pendant 1 à 2 minutes.

## Arrêt

```bash
docker compose down
```

## Fonctionnement

- **proxy** : nginx-proxy sur 80 et 443, sert les certificats et route le trafic.
- **acme** : acme-companion (Certbot) obtient et renouvelle les certificats Let's Encrypt pour les conteneurs qui ont `LETSENCRYPT_HOST` et `LETSENCRYPT_EMAIL`.
- **site** : site web avec `VIRTUAL_HOST` + `LETSENCRYPT_HOST` pour rally-logistique.cloud.

## Ajouter un service en HTTPS

Sur chaque conteneur à exposer en HTTPS :

```yaml
environment:
  VIRTUAL_HOST: mon-app.rally-logistique.cloud
  LETSENCRYPT_HOST: mon-app.rally-logistique.cloud
  LETSENCRYPT_EMAIL: "${LETSENCRYPT_EMAIL}"
networks:
  - proxy
```

## DNS

Enregistrements **A** (ou **AAAA**) vers l’IP du serveur pour :

- `rally-logistique.cloud`, `www.rally-logistique.cloud`
- `app.rally-logistique.cloud`
- `api.rally-logistique.cloud`
- `db.rally-logistique.cloud`
- `s3.rally-logistique.cloud`
- `rabbitmq.rally-logistique.cloud`

## Dépannage

- **Port 80 déjà utilisé** : un autre conteneur ou processus utilise le port 80.
  - Voir quel conteneur : `docker ps --format "table {{.Names}}\t{{.Ports}}"`
  - Ancien conteneur **rally-nginx** (ancienne config) : `docker stop rally-nginx && docker rm rally-nginx`, puis `docker compose up -d`.
  - Sinon : `docker compose down` dans le projet concerné, ou `docker stop <nom_conteneur>`, puis relancer.
- **app ou api accessibles seulement en HTTP (pas HTTPS)** : les certificats pour ces domaines n’ont peut‑être pas été demandés.
  1. Vérifier que les DNS `app.rally-logistique.cloud` et `api.rally-logistique.cloud` pointent bien vers le serveur.
  2. Forcer une nouvelle demande de certificats : `docker compose restart acme`.
  3. Attendre 1 à 2 minutes puis consulter les logs : `docker compose logs -f acme` (rechercher les lignes contenant « app » ou « api »).
  4. Si le backend démarre lentement, redéployer avec la config actuelle (acme démarre après backend et app) : `docker compose up -d --force-recreate`.
- Certificat non créé : vérifier les logs avec `docker compose logs acme`.
- Vérifier que le port 443 est ouvert (pare-feu) et que le DNS pointe bien vers le serveur.
