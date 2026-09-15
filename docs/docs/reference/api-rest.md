# L'API REST

!!! abstract "En bref"
    Toutes les routes exposées par le backend, groupées par contexte métier :
    méthode, chemin, rôle. À consulter pour savoir quel point d'entrée appeler,
    et lequel appartient à l'Administration plutôt qu'à la Simulation. La
    référence interactive est servie par l'API elle-même.

**Source** : extraction de `headless-maelia-server/app/main.py` et `headless-maelia-server/app/contexts/*/api/routes.py` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

## Conventions

| Point | Règle |
|---|---|
| Préfixe | `/api/v1` pour toutes les routes métier ; `/api/v1/admin` pour le banc d'essai |
| Format | JSON, sauf téléversement (`multipart/form-data`) et téléchargement (`application/octet-stream`) |
| Erreurs | RFC 7807 — média `application/problem+json`, corps `{type, title, status, detail}` |
| Identifiants | `project_id`, `dataset_id`, `scenario_id`, `view_id` sont des UUID ; `run_id` est une chaîne |
| Suppression | `204 No Content`, sans corps |
| Création | `201 Created`, la ressource créée dans le corps |
| Documentation vivante | Swagger UI sur `/docs`, schéma OpenAPI sur `/openapi.json` |

Les statuts d'erreur métier :

| Statut | Titre | Quand |
|---|---|---|
| `400` | Requête invalide | règle métier violée (`DomainError`) |
| `404` | Ressource introuvable | `NotFoundError` |
| `409` | État incompatible | `ConflictError` — l'opération ne s'applique pas à cet état |
| `422` | Données invalides | schéma non respecté, ou `ValidationError` ; le corps porte alors `issues` |

## Santé et sonde du moteur

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/health` | Vivacité du processus — utilisée par le `HEALTHCHECK` Docker |
| `GET` | `/api/v1/health/dependencies` | Disponibilité de `postgres`, `redis`, `minio`, `gama-headless` et du volume partagé |
| `GET` | `/api/v1/gama/describe` | Compile le modèle côté GAMA et renvoie ses expériences — sonde de bout en bout, lente au premier appel |

## Catalogue d'entrées — Administration

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/dataspecs` | Toutes les entrées du catalogue ; filtre facultatif `?module=` |
| `GET` | `/api/v1/dataspecs/graph` | Niveaux topologiques des dépendances entre fichiers |
| `POST` | `/api/v1/dataspecs/applicable` | Fichiers attendus pour une configuration de modélisation donnée |
| `GET` | `/api/v1/dataspecs/{spec_id}` | Une entrée du catalogue |
| `PUT` | `/api/v1/admin/dataspecs/{spec_id}` | Écrire une entrée — toute écriture manuelle la bascule en origine `USER` |
| `POST` | `/api/v1/admin/dataspecs/{spec_id}/restore` | Revenir au catalogue de référence et rendre l'entrée au seed |
| `DELETE` | `/api/v1/admin/dataspecs/{spec_id}` | Supprimer une entrée |

## Catalogue de paramètres — Administration

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/parameters` | Tous les paramètres que le launcher expose, ceux imposés compris |
| `GET` | `/api/v1/parameters/groups` | Noms de paramètres par section du launcher, pour l'écran d'édition |
| `GET` | `/api/v1/parameters/{name}` | Un paramètre |
| `POST` | `/api/v1/parameters/activation` | Quels paramètres sont actifs compte tenu des écarts fournis |
| `PUT` | `/api/v1/admin/parameters/{name}` | Écrire un paramètre — bascule en origine `USER` |
| `POST` | `/api/v1/admin/parameters/{name}/restore` | Revenir à ce que le launcher déclare |
| `DELETE` | `/api/v1/admin/parameters/{name}` | Supprimer un paramètre |

## Catalogue de sorties — Administration

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/outputs` | Ce que le modèle peut écrire ; filtres facultatifs `?module=` et `?theme=` |
| `GET` | `/api/v1/outputs/{spec_id}` | Une sortie, avec sa garde et ses fichiers |
| `POST` | `/api/v1/outputs/expected` | Ce qu'un scénario portant ces écarts produirait |
| `PUT` | `/api/v1/admin/outputs/{spec_id}` | Écrire une sortie — bascule en origine `USER` |
| `POST` | `/api/v1/admin/outputs/{spec_id}/restore` | Revenir à ce que le modèle écrit |
| `DELETE` | `/api/v1/admin/outputs/{spec_id}` | Supprimer une sortie |

## Projets — Simulation

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/territories` | Territoires livrés avec le modèle, lus sur le volume partagé |
| `GET` | `/api/v1/default-configuration` | Réglages de modélisation d'un projet neuf — ceux de `launcherBase.gaml` |
| `GET` | `/api/v1/projects` | Lister les projets |
| `POST` | `/api/v1/projects` | Créer un projet |
| `GET` | `/api/v1/projects/{project_id}` | Un projet |
| `PUT` | `/api/v1/projects/{project_id}` | Renommer, redécrire |
| `PUT` | `/api/v1/projects/{project_id}/modeling-configuration` | Changer les modules activés et les choix de modélisation |
| `DELETE` | `/api/v1/projects/{project_id}` | Supprimer un projet |
| `GET` | `/api/v1/projects/{project_id}/completion` | Fichiers attendus par la configuration, croisés avec les données fournies |

## Jeux de données — Simulation

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/projects/{project_id}/datasets` | Jeux de données du projet |
| `POST` | `/api/v1/projects/{project_id}/datasets/{data_spec_id}/versions` | Créer une version à partir de fichiers téléversés |
| `POST` | `/api/v1/projects/{project_id}/datasets/import-archive` | Initialiser un projet depuis un ZIP de fichiers d'entrée |
| `POST` | `/api/v1/projects/{project_id}/datasets/resolve` | Figer l'ensemble des versions qu'un run utiliserait |
| `GET` | `/api/v1/datasets/{dataset_id}` | Un jeu de données et ses versions |
| `GET` | `/api/v1/datasets/{dataset_id}/versions/{number}/records` | Projection en lignes d'une version |
| `GET` | `/api/v1/datasets/{dataset_id}/versions/{number}/issues` | Anomalies relevées à la validation |
| `GET` | `/api/v1/datasets/{dataset_id}/versions/{number}/files/{file_name}` | Les octets exacts de la version publiée |
| `GET` | `/api/v1/datasets/{dataset_id}/draft` | Lignes en cours d'édition |
| `PUT` | `/api/v1/datasets/{dataset_id}/draft` | Écrire le brouillon |
| `POST` | `/api/v1/datasets/{dataset_id}/draft/publish` | Figer le brouillon en version immuable |

!!! info "Une version publiée ne se réécrit pas"
    `records` est une projection reconstructible depuis le blob ; `files` rend
    les octets d'origine, jamais un ré-encodage. C'est ce qui permet de rejouer
    un run à l'identique.

## Scénarios — Simulation

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/projects/{project_id}/scenarios` | Scénarios du projet |
| `POST` | `/api/v1/projects/{project_id}/scenarios` | Créer un scénario |
| `GET` | `/api/v1/projects/{project_id}/parameters/{name}/options` | Valeurs que ce projet autorise pour un paramètre, lues dans ses propres données |
| `GET` | `/api/v1/scenarios/{scenario_id}` | Un scénario |
| `PUT` | `/api/v1/scenarios/{scenario_id}` | Remplacer les écarts et les épingles |
| `DELETE` | `/api/v1/scenarios/{scenario_id}` | Supprimer un scénario |
| `GET` | `/api/v1/scenarios/{scenario_id}/gama-parameters` | La charge utile que ce scénario enverrait au `load` |

!!! warning "Les écarts se remplacent en bloc"
    `PUT /api/v1/scenarios/{scenario_id}` remplace l'ensemble des écarts. Une
    fusion rendrait impossible le retrait d'une surcharge : envoyer le jeu
    complet est la seule façon de dire « ce paramètre revient à son défaut ».

## Exécutions — Simulation

| Méthode | Chemin | Rôle |
|---|---|---|
| `POST` | `/api/v1/projects/{project_id}/runs` | Lancer un run sur un projet, éventuellement à travers un scénario |
| `GET` | `/api/v1/projects/{project_id}/runs` | Runs du projet ; `?limit=` (défaut 50) |

## Banc d'essai — Administration

Le banc d'essai lance un launcher livré avec le modèle, sans passer par un
projet. Il sert à vérifier que la chaîne complète fonctionne.

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/admin/models` | Launchers exposés au banc d'essai |
| `POST` | `/api/v1/admin/runs` | Lancer une exécution de contrôle |
| `GET` | `/api/v1/admin/runs` | Runs récents ; `?limit=` (défaut 50) |
| `GET` | `/api/v1/admin/runs/{run_id}` | État d'un run |
| `POST` | `/api/v1/admin/runs/{run_id}/cancel` | Demander l'arrêt d'une exécution |

!!! info "L'arrêt n'est pas instantané"
    `cancel` passe l'état à `CANCELLED` dans Redis. C'est le signal que le
    worker guette entre deux messages de GAMA : il envoie alors `stop` sur sa
    session ouverte. L'arrêt prend le temps d'un aller-retour — quelques
    secondes — mais il libère réellement la JVM.

## Résultats — Simulation

| Méthode | Chemin | Rôle |
|---|---|---|
| `GET` | `/api/v1/runs/{run_id}/outputs` | Fichiers écrits par le run : nom, taille, nature |
| `GET` | `/api/v1/runs/{run_id}/outputs/{name}/profile` | Colonnes d'un fichier et lectures qu'elles permettent |
| `GET` | `/api/v1/runs/{run_id}/outputs/{name}/preview` | Premières lignes ; `?limit=` entre 1 et 500 (défaut 50) |
| `GET` | `/api/v1/runs/{run_id}/outputs/{name}/text` | Contenu brut d'un fichier texte |
| `GET` | `/api/v1/runs/{run_id}/outputs/{name}/download` | Téléchargement du fichier |
| `POST` | `/api/v1/runs/{run_id}/outputs/{name}/series` | Une série agrégée, prête à tracer |
| `GET` | `/api/v1/runs/{run_id}/output-review` | Pourquoi tel fichier est là, et pourquoi tel autre manque |
| `POST` | `/api/v1/projects/{project_id}/output-comparison` | La même lecture sur plusieurs runs du projet |
| `GET` | `/api/v1/projects/{project_id}/output-views` | Lectures enregistrées pour ce projet |
| `POST` | `/api/v1/projects/{project_id}/output-views` | Enregistrer une lecture — deux fois sous le même nom met à jour |
| `DELETE` | `/api/v1/output-views/{view_id}` | Supprimer une lecture enregistrée |

Le corps d'une demande de série :

| Champ | Type | Rôle |
|---|---|---|
| `x` | chaîne | colonne portée en abscisse |
| `measures` | liste de chaînes | colonnes numériques à agréger — au moins une |
| `series_by` | chaîne ou nul | colonne qui sépare les courbes |
| `aggregate` | `SUM`, `MEAN`, `MIN`, `MAX`, `COUNT` | agrégation appliquée (défaut `MEAN`) |
| `filters` | objet | valeurs retenues par colonne |
| `limit` | entier | nombre de points, entre 1 et 5000 (défaut 500) |

La réponse de `output-review` :

| Champ | Contenu |
|---|---|
| `produced` | fichiers effectivement écrits |
| `missing` | demandés par le scénario, absents du run — le problème est dans le modèle ou les données, pas dans les réglages |
| `undeclared` | écrits sans que le catalogue les connaisse : une sortie à recenser |
| `available` | non demandés, avec le levier qui les obtiendrait |

## Suivi temps réel

| Protocole | Chemin | Rôle |
|---|---|---|
| WebSocket | `/ws/runs/{run_id}` | Suivi vivant d'un run |

À la connexion, le socket envoie d'abord un message `{"kind": "snapshot", "run": …}`
avec l'état courant, puis relaie les événements publiés par le worker sur Redis.
Un run inconnu ferme la connexion avec le code `4404`. Ce découplage permet à
plusieurs clients de suivre le même run, et à l'API de redémarrer sans
interrompre la simulation.

!!! note "Voir aussi"

    - [Configuration et services](configuration.md) — où l'API écoute, et avec quelles variables
    - [Les paramètres de scénario](parametres.md) — ce que manipulent les routes de scénario
    - [Les sorties du modèle](sorties.md) — ce que `output-review` confronte
    - [Glossaire](glossaire.md)
