# Reverse proxy nginx + HTTPS – Rally Logistique

Reverse proxy **nginxproxy/nginx-proxy** avec **acme-companion** pour certificats Let's Encrypt.  
Exposé sur les ports **80** (HTTP) et **443** (HTTPS).

## Prérequis

- Les DNS de **rally-logistique.cloud** et **www.rally-logistique.cloud** doivent pointer vers l’IP du serveur **avant** de lancer (Let's Encrypt vérifie le domaine).

## Configuration

Créez un fichier **`.env`** à la racine du projet avec l’email utilisé pour Let's Encrypt (obligatoire) :

```env
LETSENCRYPT_EMAIL=ton-email@exemple.com
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
- **web** : application exemple avec `VIRTUAL_HOST` + `LETSENCRYPT_HOST` pour rally-logistique.cloud.

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

- Enregistrements **A** (ou **AAAA**) pour `rally-logistique.cloud` et `www.rally-logistique.cloud` vers l’IP du serveur.

## Dépannage

- Certificat non créé : vérifier les logs avec `docker compose logs acme`.
- Vérifier que le port 443 est ouvert (pare-feu) et que le DNS pointe bien vers le serveur.
