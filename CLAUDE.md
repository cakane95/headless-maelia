# Directives — headless-MAELIA

Plateforme web de simulation multi-agents sur **GAMA headless**. Backend Python
(FastAPI + ARQ), frontend React, modèle MAELIA 1.4.29 (INRAE).

## Documents de référence

Les lire avant d'écrire du code — ils font autorité sur ce fichier en cas de détail.

| Document | Quand |
|---|---|
| `docs/docs/architecture/backend.md` | pourquoi le backend est découpé ainsi |
| `docs/docs/architecture/backend-bonnes-pratiques.md` | **comment** écrire le code backend |
| `docs/docs/architecture/frontend.md` | structure et conventions du front |
| `docs/docs/reference/donnees-et-parametres.md` | inventaire MAELIA : entrées, sorties, paramètres |
| `README.md` | démarrage, dépannage, état du projet |

## Les deux domaines

**Administration** (`catalog`, `model`) *décrit* un modèle — entrées, paramètres,
sorties. **Simulation** (`project`, `dataset`, `scenario`, `run`, `result`)
l'*exploite* sur un territoire.

Administration produit les schémas que Simulation consomme. **La flèche ne
s'inverse jamais.** Le domaine s'appelle *Simulation* ; le contexte qui porte une
exécution s'appelle *`run`*.

## Commandes

```bash
docker compose up -d                      # démarrer (8 services)
docker compose logs -f api worker         # suivre
docker compose restart worker             # après modif du worker (pas de --reload)
curl localhost:8000/api/v1/health/dependencies   # doit répondre "status": "ok"
```

L'`api` et le `frontend` rechargent à chaud ; le **worker non** — le redémarrer
après toute modification de `app/worker/` ou `app/contexts/`.

## Contraintes à ne pas enfreindre

1. **Ne pas modifier le service `gama-headless`** du `docker-compose.yml`. Son
   `WORKDIR` interne évite que GAMA crée ses `.workspaceN` dans le dépôt.
2. **`--ws wsproto` est obligatoire** au lancement d'uvicorn. `gama-client` épingle
   `websockets~=10.3` ; sans le flag, uvicorn 0.52 utilise cette version avec l'API
   de la 13 et plante.
3. **`redis` reste en 5.x** — `arq` 0.28 exige `redis[hiredis]>=4.2,<6`.
4. **Pas de directive `# syntax=` dans les Dockerfiles** : elle force un
   téléchargement depuis Docker Hub avant tout build.
5. **`pull_policy: build`** sur `api`, `worker`, `frontend` — sans quoi Compose
   tente de *pull* un tag local inexistant au premier démarrage.
6. **`includes/` n'est pas du matériel de projet.** Les jeux livrés sous
   `gama-models/.../includes/` sont là pour **exercer GAMA depuis le banc
   d'essai**. Ils ne sont pas des territoires à proposer à la création d'un
   projet : les données d'un projet viennent de ses propres téléversements.
7. **Invariant de chemins** : `api`, `worker` et `gama-headless` montent
   `./gama-models` sur `/usr/lib/gama/workspace/gama-models`. Un chemin calculé en
   Python est un chemin valide côté GAML.
8. **Un run travaille sur une copie de ses includes.** MAELIA réécrit ses fichiers
   d'entrée pendant l'exécution ; deux runs partageant un répertoire se corrompent
   silencieusement.
9. **Aucune boucle d'attente non bornée.** Elle doit rendre la main
   périodiquement et rester annulable.

## Règles de code — backend

- **Règle de dépendance** : `api`/`worker` → `application` → `domain` ←
  `infrastructure`. Le `domain` n'importe **jamais** FastAPI, SQLAlchemy, Redis
  ni websockets.
- **Découper par contexte métier**, pas par couche technique.
- **Rien de MAELIA en dur** : nom de fichier, de paramètre, de colonne — tout vient
  du catalogue. 82 types de fichiers, 148 paramètres : le code par fichier est
  une impasse.
- **Ports = `typing.Protocol`**, créés seulement pour isoler une dépendance externe
  ou permettre une substitution réelle. Jamais par symétrie.
- **Domaine en `@dataclass(frozen=True)`**, bords en Pydantic, persistance en
  SQLAlchemy (suffixe `Row`). Ne pas confondre les trois.
- **Dépendances des cas d'usage = paramètres**, pas des imports concrets.
- **E/S bloquante** (fichiers, `shutil`, MinIO) : `await asyncio.to_thread(...)`.
- **Erreurs** : `DomainError` → RFC 7807. `except Exception` nu interdit sauf
  best-effort documenté **et** journalisé.
- **Journaux** : toute ligne d'un run porte `run_id` (et `project_id` si connu).
- **Code en anglais** : identifiants, commentaires, docstrings. Exceptions : les
  messages affichés à l'utilisateur restent en français, et les identifiants GAML
  gardent leur orthographe (`nbAnneesSimulation`).

## Règles de code — frontend

- **Aucun `fetch` ni `WebSocket` hors de `src/api.js`.**
- Les **trois états** — chargement, erreur, données — sont toujours gérés.
- Tout `useEffect` qui ouvre un minuteur ou un socket **nettoie**.
- **Aucune règle métier dans le front** : la validation fait autorité côté backend.
- **Un formulaire est dans une modale ou sur sa propre page**, jamais posé au
  milieu d'un écran de liste : court (quelques champs) → modale ouverte par un
  bouton ; long (listes, épinglages, grille) → page dédiée avec lien de retour.
- Un composant n'est promu dans `components/` qu'au **deuxième** usage.
- Couleurs et espacements via les **variables CSS**, jamais en dur.

## Vérification

- Une règle métier se teste **sans Docker**. Si un test réclame une base, la règle
  est au mauvais endroit.
- Le seul test qui prouve que la plateforme fonctionne est un **run MAELIA réel**.
  La version Java avait tout le reste au vert sans jamais l'avoir passé.
- Après une modification du pipeline d'exécution : lancer un run d'un an
  (~75 s, 9 fichiers de sortie) et vérifier qu'il atteint `FINISHED`.

## Calibrage

La version Java précédente comptait ~180 fichiers pour 9 contextes et n'a jamais
réussi un run de bout en bout : la cérémonie avait absorbé le budget de la
validation. On garde les principes, on calibre la cérémonie.

**Une abstraction doit rendre un service aujourd'hui.** Isoler une dépendance
instable, permettre un test sans infrastructure, empêcher un cycle : ce sont des
services. « C'est plus propre » n'en est pas un.

## Pièges connus du modèle MAELIA

| Piège | Conséquence |
|---|---|
| `do pause` précède `simulationTerminee` | `SimulationEnded` peut ne pas être émis — surveiller aussi le marqueur console |
| Aucun « cycle N » tracé | la progression se lit sur la ligne de date journalière |
| `idSimulationAPI` | rend le dossier de sortie déterministe (`models/main/log/<runId>`) |
| `.project` requis | sans ce descripteur Eclipse, GAMA refuse de charger le modèle |
| ~+0,7 Gio par run simultané | dimensionner `WORKER_MAX_JOBS` sur la RAM, pas sur les cœurs |
| Sorties écrites dans l'arbre du modèle | `models/main/log/` est ignoré par git |
| `nomScenarioClimatique` non vide → météo **simulée** | `includes_sasseme` ne livre que l'observée : laisser ce paramètre vide sur ce jeu |
| Une initialisation ratée n'émet aucun événement | le run resterait EN COURS sans fin — le marqueur console `ERREUR LORS DE L'INITIALISATION` le fait échouer |
