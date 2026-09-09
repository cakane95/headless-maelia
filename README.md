# headless-MAELIA

Plateforme web de simulation multi-agents adossée à **GAMA headless**.

Elle rend un modèle GAMA exploitable sans installer GAMA : le modèle est décrit
dans un catalogue, les données d'entrée sont saisies ou téléversées via le web,
les scénarios sont composés à partir des paramètres du modèle, et les simulations
sont exécutées sur un serveur GAMA piloté par WebSocket.

Le seul modèle embarqué à ce jour est **MAELIA 1.4.29** (INRAE — évaluation
intégrée eau / agriculture / normes), mais rien dans la plateforme ne lui est
spécifique : tout passe par le catalogue.

---

## Les deux domaines fonctionnels

La plateforme couvre deux usages distincts, avec des utilisateurs différents.
Le front les sépare en **deux espaces**, chacun avec son propre layout et sa
barre latérale : `/admin` et `/projets`.

### 1. Administration — gérer les modèles

Back-office. Administrer un modèle, c'est **le décrire** par du CRUD, jamais par du code :

| Objet administré | Ce qu'on décrit |
|---|---|
| **Entrées** | Le catalogue des fichiers attendus par le modèle : nom de fichier, format (CSV orienté colonnes ou transposé, délimiteur), champs et leurs types, valeurs autorisées, caractère obligatoire selon la configuration, et dépendances entre fichiers. |
| **Paramétrage des scénarios** | Le catalogue des paramètres exposés par le launcher GAML : nom GAML, type, valeur par défaut, groupe, valeurs autorisées, conditions de visibilité, paramètres pilotés par le système. |
| **Sorties** | Le catalogue des fichiers et séries produits par le modèle : comment les lire, comment les agréger, comment les restituer. |
| **Banc d'essai** | Le lancement d'une simulation de contrôle sur GAMA headless, avec suivi de la console en direct et inventaire des fichiers produits — pour valider un modèle avant de l'ouvrir aux projets. |

**Le principe directeur : aucune logique propre à un fichier ou à un paramètre
n'est codée en dur.** Ajouter une entrée ou un paramètre, c'est créer une ligne
en base — pas déployer une version. C'est cette contrainte qui permettra
d'accueillir un second modèle que MAELIA sans réécrire la plateforme.

À titre d'ordre de grandeur, MAELIA représente **71 types de fichiers d'entrée**
et **142 paramètres de scénario** extraits de `launcherBase.gaml`.

### 2. Simulation — exploiter un modèle dans un projet

Front-office. Le parcours d'un utilisateur métier :

1. **Créer un projet** sur un territoire et choisir sa configuration de modélisation.
2. **Fournir les données d'entrée** : téléversement (CSV, ZIP, shapefiles) ou saisie
   en ligne, validées contre le catalogue d'entrées.
3. **Modifier avec versionnage** : chaque modification d'un jeu de données produit
   une nouvelle version ; une simulation référence la version exacte qu'elle a
   consommée, pour que tout résultat reste reproductible et traçable.
4. **Composer un scénario** : uniquement les écarts aux valeurs par défaut du modèle,
   validés contre le catalogue de paramètres.
5. **Lancer une simulation** et suivre sa progression en temps réel.
6. **Consulter et exporter les résultats** : séries temporelles, agrégats, artefacts.

La base de données est la source de vérité. Les fichiers d'entrée que GAMA lit
sont **régénérés à la demande** au lancement d'un run (« matérialisation des
includes »), à partir des données versionnées du projet.

---

## Démarrage

Prérequis : Docker et Docker Compose v2. Rien d'autre — ni Java, ni GAMA, ni Python.

```bash
docker compose up -d
```

Premier lancement : environ 4 minutes (construction des images), puis 40 secondes.

Vérifier que tout est joignable :

```bash
curl http://localhost:8000/api/v1/health/dependencies
```

Attendu : `"status": "ok"` et les cinq sondes `up` (postgres, redis, minio,
gama-headless, shared-volume).

Test de bout en bout — fait compiler le modèle MAELIA par GAMA (~35 s) :

```bash
curl http://localhost:8000/api/v1/gama/describe
```

Puis, pour exécuter une vraie simulation : **Administration → Banc d'essai** sur
http://localhost:5173/admin/banc-essai (ou en direct) :

```bash
curl -X POST http://localhost:8000/api/v1/admin/runs \
  -H "Content-Type: application/json" \
  -d '{"model_id":"launcherTest","parameters":[{"type":"int","name":"nbAnneesSimulation","value":1}]}'
```

Un run d'un an dure environ 75 s et produit 9 fichiers dans
`gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log/<runId>/`.

| Service | URL | Rôle |
|---|---|---|
| frontend | http://localhost:5173 | SPA React (Vite, HMR) |
| api | http://localhost:8000 | REST + WebSocket temps réel |
| — swagger | http://localhost:8000/docs | Documentation d'API |
| docs | http://localhost:8082 | Documentation de la plateforme (mkdocs) |
| minio | http://localhost:9001 | Console de stockage objet (`maelia` / `maelia12345`) |
| gama-headless | ws://localhost:6868 | Serveur GAMA (WebSocket) |
| db | localhost:5432 | PostgreSQL 16 + PostGIS |
| redis | localhost:6379 | File de tâches + pub/sub |

Commandes utiles :

```bash
docker compose logs -f api worker gama-headless
docker compose down            # arrêt, données conservées
docker compose down -v         # arrêt + suppression des données (repart de zéro)
docker compose build --no-cache api
```

---

## Architecture

```
                    ┌────────────┐
   navigateur ─────▶│  frontend  │  React / Vite
                    └─────┬──────┘
                          │ REST + WebSocket
                    ┌─────▼──────┐        ┌───────────┐
                    │    api     │───────▶│   minio   │  fichiers, artefacts
                    │  FastAPI   │        └───────────┘
                    └──┬──────┬──┘        ┌───────────┐
                       │      └──────────▶│    db     │  PostgreSQL + PostGIS
              file ARQ │                  └───────────┘
                 + pub/sub                       ▲
                    ┌──▼──────┐                  │
                    │  redis  │                  │
                    └──┬──────┘                  │
                    ┌──▼──────┐                  │
                    │ worker  │──────────────────┘
                    │  ARQ    │
                    └──┬──────┘
                       │ WebSocket JSON, ouverte toute la durée du run
                    ┌──▼────────────┐
                    │ gama-headless │  GAMA 2025.06.4, -socket 6868
                    └───────────────┘
```

`api` et `worker` partagent **la même image** ; seule la commande diffère.

### L'invariant de chemins

`api`, `worker` et `gama-headless` montent `./gama-models` sur **exactement le
même chemin**, `/usr/lib/gama/workspace/gama-models`.

Un chemin calculé en Python est donc envoyable tel quel à GAMA, sans traduction.
C'est la contrainte la plus importante du `docker-compose.yml` : la casser produit
des erreurs GAMA incompréhensibles (modèle « introuvable » alors qu'il est bien là).
La sonde `shared-volume` de `/api/v1/health/dependencies` vérifie cet invariant à
chaque appel.

### Pourquoi le modèle est monté sous `/usr/lib/gama/workspace/`

GAMA est une application Eclipse : elle exige un *workspace*. En headless, le
script `gama-headless.sh` en fabrique un jetable à chaque lancement, **dans son
répertoire courant** :

```bash
pathWorkspace="./.workspace$(find ./ -maxdepth 1 -name '.workspace*' | wc -l)"
mkdir -p "$pathWorkspace"
java ... -data "$pathWorkspace" $args
rm -fr $pathWorkspace     # jamais atteint en mode -socket : le serveur ne rend pas la main
```

Dans l'image officielle, le répertoire courant est `/opt/gama-platform/headless`,
**à l'intérieur du conteneur** : les `.workspaceN` y naissent et disparaissent avec
le conteneur. En montant les modèles ailleurs, ils ne polluent jamais le dépôt.

> **Piège historique.** La version précédente de la plateforme surchargeait l'image
> avec `WORKDIR /workspace`, où `/workspace` était le bind-mount de l'hôte. Chaque
> démarrage de conteneur créait donc un `.workspaceN` **dans l'arborescence des
> modèles** — 26 dossiers accumulés. Le compteur étant un `wc -l` et non un `max+1`,
> supprimer un dossier au milieu fait que deux instances visent le même workspace.
> D'où la règle : **ne pas surcharger le `WORKDIR` de l'image GAMA.** Le service
> `gama-headless` du compose est volontairement laissé tel quel.

Si un workspace stable devient souhaitable (cache de compilation GAML réutilisé
entre runs), le script accepte `-ws <chemin>`, qui désactive aussi le nettoyage.


### Simulations concurrentes

Plusieurs runs peuvent tourner en même temps. Trois mécanismes le rendent possible,
et deux limites l'encadrent.

**Isolation des sorties.** Le worker impose `idSimulationAPI=<runId>` : l'action
`majChemins` de `main.gaml` écrit alors dans `models/main/log/<runId>`. Chaque run
a son dossier, aucune collision en écriture.

**Isolation des entrées — le point non évident.** MAELIA ne se contente pas de
*lire* ses includes : il en **réécrit** certains pendant le run
(`blocsDonnees.csv`, `blocsDonnees_cor.csv`). Deux runs partageant
`includes/<territoire>` se corrompraient donc mutuellement, sans erreur et avec
des résultats silencieusement faux. Chaque run reçoit pour cette raison une copie
de travail sous `includes/.runs/<runId>/`, sur laquelle `cheminModeleVersDonnees`
est pointé ; elle est supprimée en fin de run. Le socle `includes/<territoire>`
redevient une source en lecture seule (`app/core/includes.py`).

C'est la même brique qui portera la matérialisation du domaine « projet » : socle
+ données versionnées du projet, au lieu d'une simple copie.

**Parallélisme.** `WORKER_MAX_JOBS` (défaut : 3) fixe le nombre de runs menés de
front par un worker. Pour aller au-delà, ajoutez des workers plutôt que d'augmenter
cette valeur :

```bash
docker compose up -d --scale worker=3
```

**Limite n°1 — la mémoire de GAMA.** Toutes les simulations vivent dans la même JVM.
Mesuré sur 3 runs d'un an menés de front : **3,7 Gio** pour `gama-headless`, contre
2,3 Gio au repos avec un modèle chargé — environ **+0,7 Gio par run simultané**.
L'image est livrée avec `-Xmx16G` dans `Gama.ini` : la JVM se croit donc autorisée
à dépasser largement la mémoire réelle de la machine. Sur un hôte à 8 Gio, au-delà
de 3 ou 4 runs simultanés le conteneur est tué par l'OOM killer — et **toutes** les
simulations en cours meurent avec lui. Dimensionnez `WORKER_MAX_JOBS` sur la RAM
disponible, pas sur le nombre de cœurs.

**Limite n°2 — le débit.** 3 runs d'un an en parallèle prennent ~140 s, contre ~76 s
pour un seul : le gain est réel mais sous-linéaire, les simulations se partageant
la même JVM.

---

## Pile technique

| Couche | Choix | Note |
|---|---|---|
| API | FastAPI + Uvicorn (Python 3.12) | async natif — indispensable pour tenir N WebSockets GAMA |
| Tâches de fond | ARQ + Redis | asyncio natif ; remplace RabbitMQ + Spring AMQP |
| Temps réel | WebSocket FastAPI + pub/sub Redis | remplace STOMP |
| Persistance | PostgreSQL 16 + PostGIS, SQLAlchemy 2 async, Alembic | |
| Stockage objet | MinIO | shapefiles, artefacts de sortie |
| Pilotage GAMA | `gama-client` + protocole JSON direct | |
| Frontend | React 19 + Vite | |
| Outillage Python | `uv` | résolution et installation des dépendances |

### Deux contraintes de dépendances à connaître

**1. `--ws wsproto` est obligatoire.** `gama-client` épingle `websockets~=10.3`,
alors que `uvicorn[standard]` exige `websockets>=13` — les deux sont
inconciliables. On installe donc uvicorn *sans* l'extra `standard`, et le
WebSocket **serveur** est assuré par `wsproto` ; `websockets` 10.4 reste présent
pour la connexion **sortante** vers GAMA. Sans le flag, l'auto-détection d'uvicorn
choisit `websockets` 10.4 et l'utilise avec l'API de la 13 — plantage au runtime.

**2. `redis` doit rester en 5.x.** `arq` 0.28 exige `redis[hiredis]>=4.2,<6`.
Monter en redis 6+/8+ rend la résolution impossible.

Ces deux points sont commentés dans
[`headless-maelia-server/pyproject.toml`](headless-maelia-server/pyproject.toml).

---

## Dépannage

Les erreurs ci-dessous ont toutes été rencontrées et corrigées ; elles sont
documentées ici parce qu'elles reviennent dès qu'on modifie la configuration.

**`pull access denied for maelia/backend, repository does not exist`**
Compose voit un tag local (`maelia/backend:local`) absent de Docker Hub et tente
un `pull`. C'est la panne de premier lancement classique. Corrigé par
`pull_policy: build` sur `api`, `worker` et `frontend` dans le compose — ne le
retirez pas. Si l'erreur revient : `docker compose build` puis `docker compose up -d`.

**`failed to resolve source metadata for docker.io/docker/dockerfile:1.7`**
Une directive `# syntax=docker/dockerfile:1.7` en tête de Dockerfile force
BuildKit à télécharger une image de frontend depuis Docker Hub **avant** tout
build : le build échoue si le registre est indisponible ou rate-limité. Les
Dockerfiles n'en ont volontairement pas — le frontend intégré de Docker ≥ 23
gère déjà `RUN --mount=type=cache` et `COPY --from=<image>`.

**`worker démarré en mode dégradé` / `Connection refused` au démarrage**
`gama-headless` met une vingtaine de secondes à ouvrir son socket et n'expose pas
de healthcheck (conteneur volontairement non modifié) ; par ailleurs le
healthcheck `pg_isready` de postgis passe au vert pendant l'initialisation, juste
avant que le serveur ne redémarre. Le worker attend donc ses dépendances jusqu'à
120 s avant d'abandonner. Un message isolé au tout premier démarrage est normal ;
un mode dégradé persistant ne l'est pas — vérifiez alors
`/api/v1/health/dependencies`.

**Un run reste bloqué en `EN_COURS` alors que la console affiche « FIN DE SIMULATION »**
MAELIA exécute `do pause` **avant** de poser `simulationTerminee` : l'expérience
est déjà en pause quand la condition `until:` devient vraie, et GAMA n'émet alors
pas toujours `SimulationEnded`. Le worker surveille donc aussi le marqueur console
(`END_MARKERS` dans `app/core/gama_session.py`). Si un run reste bloqué après un
redémarrage du worker, sa tâche a été tuée : annulez-le depuis le banc d'essai.

**`gama-headless` est tué / tous les runs meurent d'un coup**
Dépassement mémoire de la JVM (cf. « Simulations concurrentes »). Baissez
`WORKER_MAX_JOBS`, ou donnez plus de RAM à Docker.

**L'API reste bloquée sur « Waiting for background tasks to complete »**
Un WebSocket de suivi de run laissé ouvert dans un onglet. La boucle d'abonnement
rend désormais la main chaque seconde (`app/core/runs.py`) et l'api tourne avec
`--timeout-graceful-shutdown 5`.

**GAMA ne trouve pas le modèle**
Vérifiez l'invariant de chemins : les trois services doivent monter `./gama-models`
sur `/usr/lib/gama/workspace/gama-models`. Vérifiez aussi que
`gama-models/<MODELE>/.project` existe — sans ce descripteur Eclipse, GAMA refuse
de charger le modèle.

**Le HMR du frontend ne réagit pas**
Les bind-mounts Docker sous Windows et macOS ne propagent pas les événements
inotify. `vite.config.js` active déjà `usePolling`.

---

## État du projet

Ce dépôt est une **reprise en Python** d'une plateforme précédemment écrite en
Java / Spring Boot. Le socle d'infrastructure est en place et vérifié ; les deux
domaines fonctionnels restent à implémenter.

**Fait et vérifié**

- Orchestration Docker complète, démarrage à froid sans erreur (8 services).
- Invariant de chemins entre `api`, `worker` et `gama-headless`, sondé en continu.
- Sondes de disponibilité : postgres + PostGIS, redis, minio, socket GAMA, volume partagé.
- **Chaîne bout en bout avec GAMA** : compilation du modèle MAELIA, 270 espèces
  et l'expérience remontées (`GET /api/v1/gama/describe`, ~35 s).
- **`launcherTest.gaml`** : duplication de `launcherBase.gaml` adaptée au headless
  (`until: simulationTerminee`, sans bloc `output`), aucun paramètre métier modifié.
- **Exécution complète d'un run par le worker** : `load` → `play` → fin détectée →
  relevé du cycle final → inventaire des sorties. Validé sur un run d'un an
  (76 s, 9 fichiers produits dans `models/main/log/<runId>`).
- Suivi temps réel : le worker publie sur Redis, l'API relaie en WebSocket
  (`/ws/runs/{id}`), le front affiche la console GAMA et la date simulée en direct.
- Front : deux espaces avec layouts et barres latérales distincts ; espace
  administration opérationnel (tableau de bord, modèles, banc d'essai).
- **Simulations concurrentes** : 3 runs d'un an menés de front avec succès,
  includes isolés par run (empreinte du socle inchangée, vérifiée par hachage)
  et 9 fichiers de sortie produits par chacun.

**À faire**

1. Modèle de données et migrations Alembic — l'état des runs est pour l'instant
   dans Redis (`app/core/runs.py`, isolé pour être rebasculé sans toucher au reste).
2. Domaine *administration* : CRUD des catalogues (entrées, paramètres, sorties),
   avec reprise des deux jeux de référence de la version Java (71 types de
   fichiers, 142 paramètres). Le catalogue des modèles est encore codé en dur
   dans `app/api/admin.py`.
3. Domaine *simulation* : projets, téléversement et validation, **versionnage des
   jeux de données**, matérialisation des includes, scénarios.
4. Annulation effective d'un run : `POST /runs/{id}/cancel` change le statut mais
   n'interrompt pas encore la simulation côté GAMA (il faut signaler la tâche
   worker pour qu'elle envoie `stop` sur sa session ouverte).
5. Ingestion des sorties en base et restitution graphique.
6. Authentification et rôles (en dernier).

Point de vigilance pour l'étape 4 : le modèle écrit ses sorties **dans sa propre
arborescence** (`models/main/log/`), car le launcher définit
`cheminRelatifDuDossierDeSortieDeSimulation` relativement à `cheminRacineMaelia`.
Ce chemin est un `parameter` GAML, donc surchargeable au `load`.

## Licence

Le modèle MAELIA (`gama-models/`) est publié par l'INRAE sous **GPL v3** et
conserve sa licence propre.
