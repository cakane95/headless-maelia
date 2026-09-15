# Installer et démarrer

!!! abstract "En bref"
    Comment obtenir une plateforme qui répond, sur une machine où GAMA n'est pas
    installé et ne le sera jamais. Vous partez d'un dépôt cloné, vous arrivez à
    une sonde verte et à une interface ouverte dans votre navigateur. Comptez un
    quart d'heure la première fois, une minute les suivantes.

## Ce qu'il faut avoir

Docker et Docker Compose v2. **Rien d'autre** — ni Java, ni GAMA, ni Python, ni
Node. Tout ce que la plateforme exécute vit dans des conteneurs, y compris le
moteur de simulation.

Vérifiez que Compose v2 répond :

```bash
docker compose version
```

Prévoyez de la place et de la mémoire : les images pèsent quelques giga-octets,
et le conteneur GAMA occupe à lui seul plus de 2 Gio dès qu'un modèle est
chargé. Une machine à 8 Gio de RAM suffit pour travailler ; en dessous, les
simulations concurrentes deviennent le premier point de rupture.

## Le démarrage

Depuis la racine du dépôt :

```bash
docker compose up -d
```

Le premier lancement construit les images du backend et du frontend et
télécharge celles de GAMA, PostGIS, Redis, MinIO et MkDocs. Comptez **quelques
minutes**. Les démarrages suivants sont de l'ordre de la minute : les images
sont déjà là, seuls les conteneurs redémarrent.

Suivez la construction si elle vous semble longue :

```bash
docker compose logs -f api worker gama-headless
```

## La base de données

Les tables ne se créent pas toutes seules. Sur une base neuve — premier
lancement, ou après un `docker compose down -v` — appliquez les migrations, puis
redémarrez l'API :

```bash
docker compose exec api alembic upgrade head
docker compose restart api
```

Le redémarrage n'est pas décoratif : les trois catalogues du modèle — entrées,
paramètres, sorties — sont chargés **au démarrage de l'API**. Tant que les
tables n'existaient pas, ce chargement a échoué en silence et la plateforme
n'a aucune idée de ce que MAELIA attend.

!!! info "Le chargement des catalogues est non destructif"
    Il est rejouable à volonté. Une fiche que vous avez corrigée à la main
    n'est jamais écrasée : elle porte une origine `USER` qui la met hors de
    portée du jeu de référence. Voir
    [Administrer les catalogues](../guides/administrer-les-catalogues.md).

## La vérification

C'est la seule preuve qui compte à ce stade.

--8<-- "_partials/services.md:sondes"

Une sonde `down` désigne son coupable dans son `detail` : le message dit ce qui
manque, pas seulement que quelque chose manque. Deux lectures utiles dans la
réponse :

- `postgres` affiche `migrations=<révision>`. S'il dit `migrations=not applied`,
  reprenez la section précédente.
- `shared-volume` ne vérifie pas qu'un disque est monté, mais que le modèle est
  **lisible au chemin partagé**, que le projet GAMA y est valide et que
  l'écriture fonctionne. C'est l'invariant sur lequel tout repose : `api`,
  `worker` et `gama-headless` voient les modèles au même chemin, si bien qu'un
  chemin calculé en Python est un chemin valide côté GAMA.

## Les services et leurs adresses

--8<-- "_partials/services.md:urls"

Entrez par le frontend. L'interface se sépare en deux espaces, et c'est la
distinction la plus structurante de la plateforme :

--8<-- "_partials/deux-domaines.md:tableau"

--8<-- "_partials/deux-domaines.md:regle"

## La chaîne jusqu'à GAMA

La sonde précédente dit que le socket GAMA est ouvert. Elle ne dit pas que GAMA
sait compiler le modèle. Cet appel-là le prouve :

```bash
curl http://localhost:8000/api/v1/gama/describe
```

Il fait compiler l'intégralité du GAML par GAMA et renvoie les espèces et
l'expérience trouvées. **Il est lent** — comptez une trentaine de secondes la
première fois — et c'est normal : c'est une compilation complète, pas un ping.
S'il répond, la chaîne est entière, du navigateur jusqu'au moteur.

!!! tip "Un 504 n'est pas forcément une panne"
    Si l'appel expire, GAMA finit souvent sa compilation quand même. Relancez
    l'appel : le deuxième répond plus vite.

## Les commandes du quotidien

```bash
docker compose ps                      # qui tourne, et depuis quand
docker compose logs -f api worker      # suivre l'API et le worker
docker compose restart worker          # après toute modification du worker
docker compose down                    # arrêter, données conservées
docker compose down -v                 # arrêter et tout effacer (base, MinIO)
docker compose build --no-cache api    # reconstruire une image de zéro
```

!!! warning "Le worker ne recharge pas à chaud"
    L'API et le frontend rechargent à chaud. **Le worker, non** : il est lancé
    sans `--reload`. Toute modification du code qu'il exécute demande un
    `docker compose restart worker`, faute de quoi vous déboguez une version du
    code qui n'est plus sur le disque.

!!! danger "`down -v` efface les données, pas seulement les conteneurs"
    Le drapeau `-v` supprime les volumes : projets, versions de données,
    scénarios et historique d'exécutions disparaissent ensemble. C'est la bonne
    commande pour repartir de zéro, jamais pour « redémarrer proprement ». Pour
    cela, `docker compose restart` suffit.

## Ce qui reste sur le disque

Deux répertoires se remplissent au fil des exécutions, tous deux ignorés par
git :

- `gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log/<runId>/` — les
  fichiers de sortie de chaque exécution, un dossier par exécution.
- `gama-models/MAELIA_1.4.29_GAMA_2025-06/includes/.runs/<runId>/` — la copie de
  travail des entrées d'une exécution, supprimée à la fin.

Les supprimer à la main est sans danger tant qu'aucun run ne tourne. Vous y
perdez les résultats consultables des exécutions concernées.

## La suite

La plateforme répond. Elle ne fait encore rien d'utile : aucun projet, aucune
donnée, aucun résultat. Le tutoriel suivant vous mène d'ici à un graphique, en
une trentaine de minutes dont la moitié d'attente.

!!! note "Voir aussi"
    - [Votre première simulation, de bout en bout](premiere-simulation.md) — la
      suite immédiate.
    - [Dépannage](../guides/depannage.md) — si une sonde reste rouge.
    - [Lancer et suivre une exécution](../guides/lancer-et-suivre-une-execution.md)
      — le dimensionnement mémoire, une fois que plusieurs runs tournent.
