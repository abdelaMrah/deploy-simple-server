# Serveur nginx – Rally Logistique

Serveur nginx dans Docker, accessible sur **http://rally-logistique.cloud** (port 80).

## Démarrage

```bash
docker compose up -d
```

## Arrêt

```bash
docker compose down
```

## Contenu web

- Fichiers statiques : dossier `html/`
- Page d’accueil : `html/index.html`

## DNS

Pour que **rally-logistique.cloud** pointe vers ce serveur :

1. Créez un enregistrement **A** (ou **AAAA** pour IPv6) pointant vers l’IP de la machine qui exécute Docker.
2. Optionnel : enregistrement **CNAME** `www` → `rally-logistique.cloud`.

## Vérification

- En local : http://localhost
- Avec le domaine (après configuration DNS) : http://rally-logistique.cloud
