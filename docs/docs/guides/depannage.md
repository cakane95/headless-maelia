# Dépannage

!!! abstract "En bref"
    Les pannes qui ont réellement été rencontrées, leur cause et le geste qui les
    règle. Classées par ce que vous observez, pas par le composant fautif. Pour
    qui a quelque chose de cassé et veut repartir.

## Le réflexe, avant tout diagnostic

--8<-- "_partials/services.md:sondes"

Chaque sonde rapporte son `detail`. Trois lectures :

- `postgres` affiche la révision de migration appliquée. `migrations=not applied`
  explique à lui seul une plateforme vide de catalogues ;
- `shared-volume` vérifie que le modèle est lisible, que le projet GAMA est
  valide et que l'écriture fonctionne ;
- `gama-headless` ne dit que « le socket est ouvert ». Pour savoir si GAMA sait
  compiler le modèle, il faut l'appel de compilation.

## Le démarrage refuse de partir

**`pull access denied for maelia/backend, repository does not exist`**

Compose voit un tag local absent de Docker Hub et tente un `pull`. C'est la panne
de premier lancement classique. Le compose porte `pull_policy: build` sur `api`,
`worker` et `frontend` pour l'éviter — ne le retirez pas.

```bash
docker compose build
docker compose up -d
```

**`failed to resolve source metadata for docker.io/docker/dockerfile:1.7`**

Une directive `# syntax=` en tête de Dockerfile force BuildKit à télécharger une
image de frontend **avant** tout build, et le build échoue si le registre est
indisponible ou limité. Les Dockerfiles du dépôt n'en ont volontairement aucune.
Si vous en ajoutez une, vous rachetez cette panne.

**`worker démarré en mode dégradé` ou `Connection refused` au démarrage**

`gama-headless` met une vingtaine de secondes à ouvrir son socket et n'expose pas
de sonde de santé. Par ailleurs la sonde de PostgreSQL passe au vert pendant
l'initialisation, juste avant que le serveur ne redémarre. Le worker attend donc
ses dépendances un long moment avant d'abandonner.

Un message isolé au tout premier démarrage est normal. Un mode dégradé persistant
ne l'est pas : vérifiez la sonde de dépendances.

## L'interface est vide de catalogues

Aucun type de fichier, aucun paramètre, aucune sortie : les tables n'existaient
pas au démarrage de l'API, le chargement du jeu de référence a échoué et n'a
été qu'un avertissement dans les journaux.

```bash
docker compose exec api alembic upgrade head
docker compose restart api
docker compose logs --tail 20 api
```

Le journal doit alors annoncer le chargement du catalogue. Voir
[Administrer les catalogues](administrer-les-catalogues.md).

## GAMA ne trouve pas le modèle

Deux causes, toutes deux vérifiables en une minute.

**L'invariant de chemins est cassé.** `api`, `worker` et `gama-headless` doivent
monter `./gama-models` sur exactement `/usr/lib/gama/workspace/gama-models`. Un
chemin calculé en Python doit être un chemin valide côté GAMA ; s'ils divergent,
GAMA annonce un modèle introuvable alors qu'il est bien là.

**Le descripteur Eclipse manque.** Sans `.project` à la racine du modèle, GAMA
refuse de le charger. GAMA est une application Eclipse, et un dossier de fichiers
GAML n'est pas un projet.

```bash
ls gama-models/MAELIA_1.4.29_GAMA_2025-06/.project
```

!!! danger "Ne modifiez pas le service `gama-headless` du compose"
    Son répertoire de travail interne évite que GAMA crée ses workspaces jetables
    dans le dépôt. Une version précédente de la plateforme le surchargeait, et
    des dizaines de dossiers `.workspaceN` s'accumulaient dans l'arborescence des
    modèles — avec, à la clé, deux instances visant le même workspace.

## Une exécution reste bloquée

**La console affiche « FIN DE SIMULATION », l'état reste en cours.**

Le modèle met l'expérience en pause **avant** de poser son indicateur de fin :
GAMA n'émet alors pas toujours son événement de fin. Le worker surveille pour
cette raison le marqueur console. Si un run reste bloqué après un redémarrage du
worker, c'est que sa tâche a été tuée : arrêtez-le depuis son écran de suivi ou
depuis la liste des exécutions.

**Aucune ligne de date n'apparaît, jamais.**

L'initialisation a échoué. Une initialisation ratée n'émet **aucun événement** :
sans garde-fou, l'exécution resterait en cours indéfiniment. Le worker fait
échouer le run sur le marqueur console d'erreur d'initialisation. Lisez la
console : la cause y est, généralement une donnée d'entrée que le modèle refuse.

**La console avance, mais très lentement.**

Regardez la charge de `gama-headless`. Plusieurs exécutions simultanées se
partagent la même JVM et le débit est sous-linéaire.

```bash
docker stats --no-stream
```

## `gama-headless` est tué, toutes les exécutions meurent d'un coup

Dépassement mémoire de la JVM. Toutes les simulations vivent dans le même
conteneur : quand l'OOM killer le tue, elles meurent ensemble.

Baissez `WORKER_MAX_JOBS`, ou donnez plus de mémoire à Docker. Le
dimensionnement se fait sur la RAM disponible, jamais sur le nombre de cœurs —
voir [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md).

## Le lancement est refusé en 409

Deux refus distincts, deux gestes différents :

| Message | Geste |
|---|---|
| *n entrée(s) obligatoire(s) manquante(s)* | complétez les données du projet : le message nomme les fichiers |
| *run déjà FINISHED / FAILED / CANCELLED* | vous avez demandé l'arrêt d'une exécution terminée ; il n'y a rien à interrompre |

## Une exécution n'a produit aucun fichier

Trois causes, dans l'ordre de fréquence :

1. **Rien n'était demandé.** Le modèle n'écrit rien par défaut : chaque sortie est
   derrière un drapeau. Voir
   [Choisir ce que l'exécution va produire](choisir-les-sorties.md).
2. **L'exécution a été arrêtée.** Le modèle écrit en fin de période simulée ; un
   arrêt en route ne laisse rien, quelle que soit la durée déjà simulée.
3. **L'exécution a échoué.** L'état du run porte la raison.

L'écran de résultats distingue précisément ces cas : ce qui était demandé et
absent, et ce qui n'était pas demandé.

## L'API reste bloquée à l'arrêt

Message *Waiting for background tasks to complete* : un WebSocket de suivi
d'exécution est resté ouvert dans un onglet. La boucle d'abonnement rend
désormais la main périodiquement et l'API tourne avec un délai d'arrêt gracieux
court. Fermez l'onglet, ou attendez quelques secondes.

## Le rechargement à chaud ne réagit pas

**Le frontend.** Les montages Docker sous Windows et macOS ne propagent pas les
événements de système de fichiers. La configuration de Vite active déjà la
scrutation périodique ; si rien ne bouge, redémarrez le conteneur.

**Le worker.** Il n'a pas de rechargement à chaud, et c'est délibéré. Toute
modification du code qu'il exécute demande :

```bash
docker compose restart worker
```

C'est la cause première des « corrections qui ne changent rien ».

## Repartir de zéro

```bash
docker compose down -v
docker compose up -d
docker compose exec api alembic upgrade head
docker compose restart api
```

!!! danger "Cette séquence efface les données"
    Projets, versions de données, scénarios et historique d'exécutions
    disparaissent ensemble. Les dossiers de sortie déjà écrits sur le disque
    restent, mais plus rien ne sait à quoi les rattacher. À ne faire que pour
    repartir réellement de zéro.

!!! note "Voir aussi"
    - [Installer et démarrer](../demarrer/installation.md) — la séquence de
      démarrage et les sondes.
    - [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md) — les
      états, l'arrêt, la mémoire.
    - [Administrer les catalogues](administrer-les-catalogues.md) — quand une
      fiche décrit mal le modèle.
