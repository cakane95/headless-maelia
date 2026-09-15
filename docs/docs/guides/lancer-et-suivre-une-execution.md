# Lancer et suivre une exécution

!!! abstract "En bref"
    Comment lancer une simulation, lire sa progression sans se fier au mauvais
    indicateur, l'arrêter, et combien en mener de front sans faire tomber GAMA.
    Pour qui a un projet complet et un scénario prêt.

## Le lancement

Depuis `/simulation/projets/<id>/simulations`, lancez une simulation en
choisissant un scénario. Rien d'autre ne vous est demandé : les paramètres et
les versions de données sont déjà portés par le scénario, et le lancement ne
rouvre pas ces décisions.

```bash
curl -X POST http://localhost:8000/api/v1/projects/<projectId>/runs \
  -H "Content-Type: application/json" \
  -d '{"scenario_id": "<scenarioId>", "label": "Une année"}'
```

Vous arrivez sur l'écran de suivi,
`/simulation/projets/<id>/simulations/<runId>`.

## Ce que le lancement fige

Deux choses, et seulement ici :

- **les paramètres**, résolus depuis les écarts du scénario ;
- **la version de chaque jeu de données du projet**, pas seulement de ceux qui
  auraient été épinglés.

Publier une version plus récente ensuite ne change rien à ce que cette exécution
a consommé. C'est ce qui rend un résultat reproductible et défendable.

Le **territoire vient du projet**, jamais du launcher : un projet impose son
territoire à chacune de ses exécutions.

## Le refus au lancement

Si une entrée obligatoire manque, le lancement est refusé en `409`, et le
message **nomme les fichiers** :

```json
{
  "type": "about:blank",
  "title": "État incompatible",
  "status": 409,
  "detail": "2 entrée(s) obligatoire(s) manquante(s) : Engrais, Parcelles"
}
```

Mieux vaut l'apprendre ici qu'au bout de vingt minutes de simulation. Complétez
depuis `/simulation/projets/<id>/donnees` — voir
[Importer et versionner des données](importer-des-donnees.md).

## Les états

| État | Ce qui se passe |
|---|---|
| `PENDING` | l'exécution est en file, le worker ne l'a pas encore dépilée |
| `RUNNING` | les entrées sont matérialisées, GAMA a chargé le modèle et simule |
| `FINISHED` | la fin a été détectée, les sorties sont inventoriées |
| `FAILED` | erreur GAMA, ou délai dépassé — la raison est dans l'état du run |
| `CANCELLED` | vous avez demandé l'arrêt |

## Lire la progression

L'écran de suivi affiche la console GAMA en direct : le worker publie, l'API
relaie par WebSocket `/ws/runs/<runId>`. Plusieurs onglets peuvent suivre la
même exécution, et l'API peut redémarrer sans l'interrompre.

!!! warning "La progression se lit sur la date simulée"
    Le modèle ne trace aucun numéro de cycle exploitable. Le seul indicateur
    fiable est la **ligne de date journalière** de la console, de la forme
    `-----------------Lu 01/08/2019 (j 213) (0) -----------------`. Le nombre
    entre parenthèses est le jour de l'année, pas un pourcentage d'avancement.

Trois moments se distinguent nettement dans la console :

1. le chargement et la compilation du modèle par GAMA — silencieux et long ;
2. l'initialisation, qui se termine par `FIN INITIALISATION` ;
3. la simulation proprement dite, une ligne de date par jour simulé.

Une console muette pendant l'initialisation est normale. Muette pendant de
longues minutes après `FIN INITIALISATION`, elle ne l'est pas.

!!! danger "Une initialisation ratée n'émet aucun événement"
    Le modèle peut s'arrêter pendant son initialisation sans que GAMA signale
    quoi que ce soit : l'exécution resterait `RUNNING` indéfiniment. Le worker
    surveille pour cette raison le marqueur console d'erreur d'initialisation et
    fait échouer l'exécution. Si vous voyez un run rester `RUNNING` sans aucune
    ligne de date, c'est là qu'il faut regarder — voir [Dépannage](depannage.md).

## La fin

Quand la console affiche `*********** FIN DE SIMULATION ***********`, le worker
relève le cycle final et inventorie
`gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log/<runId>/`. Un run d'un an
sur le jeu de référence dure **deux à trois minutes** et y dépose **neuf
fichiers**.

!!! warning "La fin ne se détecte pas seulement par l'événement de GAMA"
    Le modèle met l'expérience en pause **avant** de poser son indicateur de fin.
    GAMA n'émet alors pas toujours son événement de fin de simulation. Le worker
    surveille donc aussi le marqueur console — sans quoi une exécution terminée
    resterait affichée comme en cours.

## Arrêter une exécution

Un bouton **Arrêter** est présent sur l'écran de suivi et dans les listes
d'exécutions, tant que l'état est `PENDING` ou `RUNNING`.

```bash
curl -X POST http://localhost:8000/api/v1/admin/runs/<runId>/cancel
```

L'arrêt n'est pas instantané, mais il prend une seconde ou deux : l'état bascule,
le worker voit le signal **entre deux messages de GAMA**, envoie `stop` sur sa
session ouverte, puis rend la main. La mémoire de la JVM est réellement libérée —
c'est le point important.

!!! warning "Un arrêt ne laisse rien"
    Le modèle n'écrit ses fichiers qu'en fin de période simulée. Une exécution
    arrêtée en route ne produit **aucune sortie**, quelle que soit la durée déjà
    simulée. Arrêter pour « garder ce qui a été fait » ne fonctionne pas.

Une exécution déjà `FINISHED`, `FAILED` ou `CANCELLED` refuse l'arrêt en `409` :
il n'y a plus rien à interrompre.

## Plusieurs exécutions de front

C'est possible, et c'est encadré par deux limites.

`WORKER_MAX_JOBS` fixe le nombre d'exécutions menées de front par un worker. Pour
aller au-delà, ajoutez des workers plutôt que d'augmenter cette valeur :

```bash
docker compose up -d --scale worker=3
```

!!! danger "Dimensionnez sur la RAM, pas sur les cœurs"
    Toutes les simulations vivent dans la **même JVM**. Chaque exécution
    simultanée y ajoute de l'ordre de 0,7 Gio, sur une base déjà supérieure à
    2 Gio au repos avec un modèle chargé. L'image autorise la JVM à dépasser
    largement la mémoire réelle de la machine : sur un hôte à 8 Gio, au-delà de
    trois ou quatre exécutions simultanées, le conteneur est tué par l'OOM
    killer — et **toutes** les simulations en cours meurent avec lui.

La seconde limite est le débit : le gain est réel mais sous-linéaire, les
simulations se partageant la même JVM. Trois exécutions de front prennent
sensiblement moins que trois exécutions à la suite, mais nettement plus qu'une
seule.

Deux mécanismes rendent cette concurrence sûre. Le dossier de sortie est
**déterministe**, un par exécution. Et chaque exécution travaille sur une
**copie** de ses entrées : le modèle réécrit certains de ses fichiers d'entrée
pendant qu'il tourne, si bien que deux exécutions partageant un répertoire se
corrompraient silencieusement.

## Le banc d'essai

`/admin/banc-essai` lance un launcher **sans projet ni données de projet**, sur
le jeu que le launcher déclare. Il sert à valider un modèle avant de l'ouvrir aux
projets : même écran de suivi, même console, même inventaire des sorties — mais
pas d'écran de résultats, faute de projet auquel rattacher les lectures.

!!! note "Voir aussi"
    - [Choisir ce que l'exécution va produire](choisir-les-sorties.md) — à lire
      avant de lancer, pas après.
    - [Lire et comparer les résultats](lire-les-resultats.md) — la suite d'une
      exécution terminée.
    - [Dépannage](depannage.md) — un run bloqué, un GAMA tué, un modèle
      introuvable.
