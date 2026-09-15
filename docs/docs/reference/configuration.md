# Configuration et services

!!! abstract "En bref"
    Les variables d'environnement lues par le backend, avec leur valeur par
    défaut et celle qu'injecte Compose ; les services, leurs ports et leurs
    volumes. À consulter pour changer un réglage, diagnostiquer un service qui
    ne répond pas, ou comprendre pourquoi un chemin doit rester identique
    partout.

**Source** : extraction de `headless-maelia-server/app/shared/config.py` et `docker-compose.yml` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

## Les services

--8<-- "_partials/services.md:urls"

Deux services n'exposent pas de port et n'apparaissent pas dans ce tableau :
`minio-init`, qui crée le bucket au démarrage puis sort, et `worker`, qui ne
reçoit rien d'autre que sa file ARQ.

## Vérifier que tout répond

--8<-- "_partials/services.md:sondes"

Une sonde rend compte, elle ne propage jamais : un contrôle `down` n'empêche pas
les autres de répondre, et la réponse dit lequel a échoué et pourquoi.

| Contrôle | Ce qu'il vérifie |
|---|---|
| `postgres` | connexion, version, présence de PostGIS et révision Alembic appliquée |
| `redis` | `PING` |
| `minio` | existence du bucket configuré |
| `gama-headless` | socket du serveur GAMA |
| `shared-volume` | le volume monté au même chemin dans `api`, `worker` et `gama-headless` |

## Variables d'environnement du backend

Lues par Pydantic Settings, depuis l'environnement ou un fichier `.env`. Les
clés inconnues sont ignorées.

### Rôle et journalisation

| Variable | Défaut | Injecté par Compose | Rôle |
|---|---|---|---|
| `APP_ROLE` | `api` | `api` / `worker` | Même image, deux commandes : distingue le processus qui sert l'API de celui qui consomme la file |
| `LOG_LEVEL` | `INFO` | `INFO` | Niveau de journalisation |
| `CORS_ORIGINS` | `http://localhost:5173` | `http://localhost:5173,http://localhost:8081` | Origines autorisées, séparées par des virgules |

### GAMA headless

| Variable | Défaut | Rôle |
|---|---|---|
| `GAMA_HOST` | `gama-headless` | Hôte du serveur GAMA |
| `GAMA_PORT` | `6868` | Port WebSocket du serveur GAMA |
| `GAMA_COMMAND_TIMEOUT` | `300` | Secondes accordées à une commande GAMA — compilation comprise |
| `GAMA_RUN_TIMEOUT` | `10800` | Secondes accordées à une simulation entière |

### Chemins MAELIA

| Variable | Défaut | Rôle |
|---|---|---|
| `GAMA_MODELS_ROOT` | `/usr/lib/gama/workspace/gama-models` | Racine partagée entre les trois conteneurs |
| `MAELIA_PROJECT_DIR` | `<racine>/MAELIA_1.4.29_GAMA_2025-06` | Répertoire du modèle |
| `MAELIA_ROOT_PATH` | `<projet>/` | Valeur envoyée comme `cheminRacineMaelia` — **le slash final est significatif côté GAML** |
| `MAELIA_MODEL_PATH` | `<projet>/models/main/launcherBase.gaml` | Launcher chargé par défaut |
| `MAELIA_EXPERIMENT_NAME` | `simulationBase` | Expérience GAML exécutée |
| `MAELIA_DEFAULT_TERRITORY` | `terrainTest` | Territoire recopié quand le run n'en impose pas d'autre |
| `MAELIA_OUTPUT_ROOT` | `<projet>/models/main/log` | Racine des sorties écrites par GAMA |

!!! danger "L'invariant de chemins"
    `api`, `worker` et `gama-headless` montent tous `./gama-models` sur
    **exactement** `/usr/lib/gama/workspace/gama-models`. Un chemin calculé en
    Python est donc un chemin valide côté GAML, sans aucune traduction. Changer
    ce point de montage dans un seul des trois services casse silencieusement
    l'exécution : GAMA cherchera un fichier là où personne ne l'a écrit.

### Infrastructure

| Variable | Défaut | Rôle |
|---|---|---|
| `DATABASE_URL` | `postgresql+asyncpg://maelia:maelia@db:5432/maelia` | DSN asynchrone ; Alembic en dérive un DSN `psycopg` synchrone |
| `REDIS_URL` | `redis://redis:6379/0` | File ARQ et pub/sub temps réel |
| `MINIO_ENDPOINT` | `minio:9000` | Stockage objet — hôte et port de l'API S3 |
| `MINIO_ACCESS_KEY` | `maelia` | Identifiant MinIO |
| `MINIO_SECRET_KEY` | `maelia12345` | Secret MinIO |
| `MINIO_BUCKET` | `maelia` | Bucket des téléversements et des artefacts |
| `MINIO_SECURE` | `false` | TLS vers MinIO |
| `WORKER_MAX_JOBS` | `2` | Simulations menées de front par un worker — Compose l'élève à `3` |

!!! warning "Dimensionner sur la mémoire, pas sur les cœurs"
    Chaque run simultané tient une session GAMA ouverte et une copie de ses
    includes. La vraie limite est la mémoire de `gama-headless`, que chaque run
    supplémentaire fait croître nettement. Un `WORKER_MAX_JOBS` trop haut ne
    rend pas la plateforme plus rapide : il la fait tomber.

### Frontend

Le frontend ne lit pas `config.py` ; ses variables sont injectées par Vite au
moment de la construction.

| Variable | Valeur dans Compose | Rôle |
|---|---|---|
| `VITE_API_URL` | `http://localhost:8000` | Base des appels REST |
| `VITE_WS_URL` | `ws://localhost:8000` | Base du WebSocket de suivi |

## Ports publiés

| Port hôte | Service | Vers | Ce qu'on y trouve |
|---|---|---|---|
| `5173` | `frontend` | `5173` | Interface, en rechargement à chaud |
| `8000` | `api` | `8000` | REST, WebSocket, Swagger UI |
| `8082` | `docs` | `8080` | Cette documentation |
| `6868` | `gama-headless` | `6868` | Serveur GAMA, piloté en WebSocket |
| `5432` | `db` | `5432` | PostgreSQL 16 + PostGIS |
| `6379` | `redis` | `6379` | Redis 7 |
| `9000` | `minio` | `9000` | API S3 |
| `9001` | `minio` | `9001` | Console MinIO |

## Volumes

### Volumes nommés

| Volume | Service | Contenu |
|---|---|---|
| `db-data` | `db` | Données PostgreSQL |
| `redis-data` | `redis` | Persistance AOF de Redis |
| `minio-data` | `minio` | Objets stockés |

### Montages depuis le dépôt

| Source | Cible | Services | Rôle |
|---|---|---|---|
| `./gama-models` | `/usr/lib/gama/workspace/gama-models` | `api`, `worker`, `gama-headless` | Le modèle et ses includes — l'invariant de chemins |
| `./headless-maelia-server` | `/app` | `api`, `worker` | Code du backend, pour le rechargement à chaud |
| `./headless-maelia-front` | `/app` | `frontend` | Code du frontend |
| `./docs` | `/docs` | `docs` | `mkdocs.yml` et le contenu Markdown |

## Images et commandes

| Service | Image | Commande |
|---|---|---|
| `gama-headless` | `gamaplatform/gama:2025.06.4` | `-socket 6868` |
| `db` | `postgis/postgis:16-3.4` | par défaut |
| `redis` | `redis:7-alpine` | `redis-server --appendonly yes` |
| `minio` | `minio/minio:latest` | `server /data --console-address ":9001"` |
| `minio-init` | `minio/mc:latest` | crée le bucket puis sort |
| `api` | `maelia/backend:local` (cible `dev`) | `uvicorn app.main:app --ws wsproto --reload` |
| `worker` | `maelia/backend:local` (cible `dev`) | `arq app.worker.settings.WorkerSettings` |
| `frontend` | `maelia/frontend:local` (cible `dev`) | serveur de développement Vite |
| `docs` | `squidfunk/mkdocs-material:9.7.0` | `serve --dev-addr=0.0.0.0:8080` |

## Contraintes à ne pas enfreindre

| Contrainte | Pourquoi |
|---|---|
| Ne pas modifier le service `gama-headless` | Son `WORKDIR` interne empêche GAMA de créer ses `.workspaceN` dans le dépôt |
| `--ws wsproto` obligatoire au lancement d'uvicorn | `gama-client` épingle `websockets~=10.3` ; sans le drapeau, uvicorn choisit cette version avec l'API d'une plus récente et plante |
| `redis` reste en 5.x côté Python | `arq` 0.28 exige `redis[hiredis]>=4.2,<6` |
| Pas de directive `# syntax=` dans les Dockerfiles | Elle force un téléchargement depuis Docker Hub avant tout build |
| `pull_policy: build` sur `api`, `worker`, `frontend` | Sans quoi Compose tente de *pull* un tag local inexistant au premier démarrage |

!!! warning "Le worker ne recharge pas à chaud"
    `api` et `frontend` rechargent à chaud ; le worker, non. Après toute
    modification de `app/worker/` ou `app/contexts/`, il faut le redémarrer :

    ```bash
    docker compose restart worker
    ```

## Commandes courantes

```bash
docker compose up -d                              # démarrer la plateforme
docker compose logs -f api worker                 # suivre le backend
docker compose logs -f gama-headless              # suivre le moteur
docker compose restart worker                     # après modification du worker
curl http://localhost:8000/api/v1/health/dependencies
```

!!! note "Voir aussi"

    - [L'API REST](api-rest.md) — ce que sert le service `api`
    - [Les chiffres du modèle](chiffres.md) — où vivent les fragments inclus ici
    - [Glossaire](glossaire.md)
