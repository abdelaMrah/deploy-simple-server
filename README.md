# Reverse proxy nginx – Rally Logistique

Reverse proxy avec **nginxproxy/nginx-proxy** exposé sur le port **80**.  
Routage automatique selon le nom d’hôte (VIRTUAL_HOST).

## Démarrage

```bash
docker compose up -d
```

Accès : **http://rally-logistique.cloud** (après configuration DNS).

## Arrêt

```bash
docker compose down
```

## Fonctionnement

- **proxy** : conteneur nginx-proxy, exposé sur le port 80, lit le socket Docker pour découvrir les conteneurs à proxifier.
- **web** : application exemple (nginx + `html/`) avec `VIRTUAL_HOST=rally-logistique.cloud`.

Tout conteneur sur le réseau `proxy` avec une variable d’environnement **VIRTUAL_HOST** sera automatiquement pris en charge par le reverse proxy.

## Ajouter un autre service

Dans le même `docker-compose.yml` (ou un autre compose sur le même réseau) :

```yaml
services:
  mon-app:
    image: mon-image
    environment:
      VIRTUAL_HOST: sous-domaine.rally-logistique.cloud
    networks:
      - proxy
```

Puis attacher le réseau au compose du proxy :

```yaml
networks:
  proxy:
    external: true
```

Ou lancer les deux stacks avec le même réseau partagé.

## DNS

- Enregistrement **A** pour `rally-logistique.cloud` (et éventuellement `www`) vers l’IP du serveur.
