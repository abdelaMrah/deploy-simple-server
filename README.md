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
- **app + /api** : le domaine `app.rally-logistique.cloud` sert le frontend sur `/` et proxifie `/api` vers le backend (config dans `nginx/vhost.d/`). Le frontend utilise `baseURL: "/api"`, donc les appels API passent par le même domaine.  
  Si vous changez `APP_VIRTUAL_HOST`, renommez le fichier dans `nginx/vhost.d/` en `<votre_domaine>_location_override`.

### Consommer l’API en HTTPS depuis le frontend

L’API n’est **pas** exposée sur un port HTTPS dédié (443 est utilisé par nginx-proxy pour tous les domaines). Elle est accessible en HTTPS de deux façons :

1. **Même origine (recommandé)** : depuis l’app à `https://app.rally-logistique.cloud`, le frontend appelle `baseURL: "/api"`. Les requêtes partent en **HTTPS** vers `https://app.rally-logistique.cloud/api`, puis nginx-proxy transmet en HTTP au backend. Aucune configuration supplémentaire côté frontend.
2. **Sous-domaine API** : `https://api.rally-logistique.cloud` (port 443). Utile pour des clients externes ou des appels directs.

Le backend ne doit **pas** être exposé sur le port 4000 de l’hôte pour la prod ; l’accès se fait uniquement via le proxy (80/443). Les fichiers dans `nginx/vhost.d/*_location_override` (app et api) assurent le proxy et les en-têtes `X-Forwarded-Proto`.

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
- `api.rally-logistique.cloud` (si vous changez `API_VIRTUAL_HOST`, renommez `nginx/vhost.d/api.rally-logistique.cloud_location_override` en `<votre_domaine>_location_override`)
- `db.rally-logistique.cloud`
- `s3.rally-logistique.cloud`
- `rabbitmq.rally-logistique.cloud`

## Dépannage

- **Port 80 déjà utilisé** : un autre conteneur ou processus utilise le port 80.
  - Voir quel conteneur : `docker ps --format "table {{.Names}}\t{{.Ports}}"`
  - Ancien conteneur **rally-nginx** (ancienne config) : `docker stop rally-nginx && docker rm rally-nginx`, puis `docker compose up -d`.
  - Sinon : `docker compose down` dans le projet concerné, ou `docker stop <nom_conteneur>`, puis relancer.
- **Chrome : « This website sent back unusual and incorrect credentials » / HSTS** : le navigateur refuse la connexion car le **certificat TLS servi pour ce domaine ne correspond pas** (certificat par défaut, autre domaine, ou certificat manquant). À faire **sur le serveur** ou depuis une machine où le DNS pointe vers le serveur :
  1. Vérifier quel certificat est servi : `sh scripts/check-cert-app.sh` (voir ci‑dessous).
  2. Si le sujet du certificat n'est pas `app.rally-logistique.cloud`, les certificats Let's Encrypt pour ce domaine n'ont pas été délivrés ou ne sont pas utilisés. Suivre les étapes du paragraphe « app ou api accessibles seulement en HTTP » (DNS, présence des fichiers dans `/etc/nginx/certs/`, redémarrage de `acme`).
  3. Redémarrer le proxy pour recharger les certificats : `docker compose restart proxy acme`, attendre 2–3 minutes puis réessayer dans le navigateur.
  4. En dernier recours, supprimer les certificats du volume et laisser acme les recréer (attention : coupure HTTPS temporaire) :  
     `docker compose down` puis sur l'hôte :  
     `docker volume inspect deploy-simple-server_certs --format '{{ .Mountpoint }}'` (adapter le préfixe du projet), puis supprimer les fichiers `app.rally-logistique.cloud.*` dans ce répertoire. Ensuite `docker compose up -d` et attendre la délivrance des nouveaux certificats.
- **app ou api accessibles seulement en HTTP (pas HTTPS)** : les certificats Let's Encrypt pour ces domaines n’ont pas été délivrés.
  1. **DNS** : sur le serveur, vérifier la résolution :
     ```bash
     dig +short app.rally-logistique.cloud
     dig +short api.rally-logistique.cloud
     ```
     Les deux doivent renvoyer l’IP du serveur.
  2. **Certificats déjà présents ?** :
     ```bash
     docker exec rally-nginx-proxy ls -la /etc/nginx/certs/
     ```
     Si des fichiers `app.rally-logistique.cloud.*` ou `api.rally-logistique.cloud.*` sont absents, acme-companion ne les a pas encore créés.
  3. **Forcer une nouvelle demande** : `docker compose restart acme`, attendre 2 à 3 minutes, puis :
     ```bash
     docker compose logs acme 2>&1 | grep -E "app\.rally|api\.rally|error|Error|failed"
     ```
  4. **Script de diagnostic** (sur le serveur) : `sh scripts/force-ssl-app-api.sh` pour lister les certs, redémarrer acme et afficher les logs.
  5. **Pare-feu** : les ports 80 et 443 doivent être ouverts depuis Internet (Let's Encrypt utilise le port 80 pour la validation HTTP-01).
  6. Si le frontend écoute sur un port autre que 80 (ex. 3000), ajouter dans le service `app` : `VIRTUAL_PORT: "3000"`.
- Certificat non créé : vérifier les logs avec `docker compose logs acme`.
- Vérifier que le port 443 est ouvert (pare-feu) et que le DNS pointe bien vers le serveur.

**Script `scripts/check-cert-app.sh`** : affiche le certificat TLS réellement servi pour `app.rally-logistique.cloud` (subject, issuer, dates). Permet de confirmer si le mauvais certificat est servi. Usage : `sh scripts/check-cert-app.sh` ou `sh scripts/check-cert-app.sh api.rally-logistique.cloud` pour l’API.
