# Importer et versionner des données

!!! abstract "En bref"
    Comment alimenter un projet — archive complète, fichier isolé, saisie en
    ligne — et ce que devient un fichier une fois entré : une version figée,
    horodatée, que les exécutions citent nommément. Pour qui doit rendre un
    territoire exécutable.

## Les trois portes d'entrée

| Geste | Route | Quand |
|---|---|---|
| Importer une archive | `/simulation/projets/<id>/import` | initialiser un projet, ou charger un lot |
| Téléverser un fichier | `/simulation/projets/<id>/donnees/<datasetId>` | remplacer une entrée par un nouveau fichier |
| Éditer en grille | `/simulation/projets/<id>/donnees/<datasetId>/edition` | corriger quelques valeurs sans repasser par un tableur |

Les deux premières produisent une version à partir d'octets reçus. La troisième
produit une version à la **publication** du brouillon, et à ce moment seulement.

## L'import d'une archive

Déposez un ZIP. Chaque fichier est apparié au catalogue **par son nom**, importé,
puis validé. Vous recevez un compte rendu ligne par ligne.

Quatre choses à savoir, toutes visibles dans le compte rendu :

- **L'arborescence de l'archive ne vous contraint pas.** Zippez comme vous
  voulez : seul le nom des feuilles compte pour l'appariement.
- **Un shapefile voyage complet.** `.shp`, `.shx`, `.dbf` et `.prj` sont
  regroupés et deviennent une seule version — les demander un par un serait un
  piège.
- **Un échec n'interrompt pas les autres.** Le compte rendu nomme l'entrée
  fautive et poursuit ; on corrige ensuite, sans tout recharger.
- **Un fichier déjà présent devient une nouvelle version.** L'ancienne est
  conservée, et les exécutions qui la citaient continuent de la citer.

Le compte rendu distingue quatre issues : importé, invalide, ignoré — le
catalogue ne connaît pas ce nom de fichier —, et en erreur. Un territoire
complet transporte toujours quelques fichiers ignorés ; c'est normal, le
catalogue ne décrit pas tout ce qui traîne dans un jeu de données.

!!! danger "Le chemin dans l'archive porte du sens"
    Un territoire contient `meteo/observee/2019.csv` **et**
    `meteo/simulee/rcp8.5/2019.csv` : même nom de feuille, fichiers différents.
    L'arborescence sert précisément à les départager, et le sous-dossier est
    porté dans la clé d'instance. Aplatir l'archive à la main avant de la zipper
    ferait atterrir plusieurs séries climatiques dans la même — et l'exécution
    réclamerait ensuite une météo introuvable.

## Une famille de fichiers, une seule entrée de catalogue

Tous les types d'entrée n'ont pas un fichier unique : une série climatique en
compte un par année, les prix un par scénario. Le catalogue les décrit par un
**motif** plutôt que par un nom, et chaque fichier reçu devient un jeu de
données distinct, porteur d'une **clé d'instance** — c'est elle qui les
distingue, la description et la validation restant communes.

Dans l'écran des données, une famille affiche le **nombre** de fichiers reçus et
ouvre sa propre liste, `/simulation/projets/<id>/donnees/famille/<specId>`,
d'où l'on entre dans chacun.

## Le cycle de vie d'une version

Une version naît, est validée, puis ne change plus.

| Champ | Ce qu'il dit |
|---|---|
| Numéro | l'ordre de publication, à partir de 1 |
| Source | `UPLOAD` (octets reçus) ou `EDIT` (brouillon publié) |
| État | `VALID`, `INVALID`, ou `DRAFT` tant que rien n'est publié |
| Libellé et message | ce que vous avez écrit en publiant |
| Fichiers | leur nom, leur taille, leur empreinte |

!!! warning "Les octets ne sont jamais régénérés après publication"
    Une version téléversée conserve les octets reçus tels quels. Une version
    éditée est sérialisée **une seule fois**, à la publication, puis gelée. Ce
    qu'une exécution donne à lire à GAMA est une copie d'octets, jamais une
    reconstruction — c'est ce qui écarte toute dérive d'encodage, de
    délimiteur ou d'ordre de colonnes entre ce qui a été validé et ce qui est lu.

Le téléchargement d'une version rend **exactement** ces octets, sans
ré-encodage : c'est la pièce à conviction d'un résultat.

## La validation

Elle s'exécute à chaque création de version, contre la fiche du catalogue :
champs attendus, types, valeurs autorisées, références vers d'autres fichiers.
Elle produit des anomalies de deux gravités.

| Gravité | Effet |
|---|---|
| `ERROR` | la version est `INVALID` — elle ne sera lue par aucune exécution |
| `WARNING` | la version reste `VALID`, l'anomalie est signalée |

Une version invalide n'est pas supprimée : elle reste dans l'historique, avec
ses anomalies consultables ligne par ligne. Vous corrigez et publiez une version
suivante.

!!! tip "Corriger sans quitter la plateforme"
    Pour deux ou trois cellules fautives, l'édition en grille est plus rapide
    qu'un aller-retour par un tableur — et surtout plus sûre : un tableur
    réécrit volontiers les séparateurs décimaux et l'encodage d'un CSV.

## Quelle version une exécution lit-elle

Par défaut, **la dernière version valide** de chaque jeu de données. Une version
publiée qui échoue à la validation ne devient donc jamais la référence
silencieuse de tous les scénarios.

Au lancement, la plateforme **fige la version de chaque jeu de données du
projet**, pas seulement de ceux qui auraient été épinglés. Publier une version
plus récente ensuite ne change rien à ce qu'a consommé l'exécution : c'est ce qui
rend un résultat défendable des mois plus tard.

Un scénario peut épingler des versions précises, et la résolution s'en sert
quand elles existent. L'interface ne les expose pas : faire varier des données
se fait en publiant une version, pas en créant un scénario. Voir
[Composer un scénario](composer-un-scenario.md).

## Ce que voit GAMA

Le modèle ne lit pas vos versions directement. À chaque exécution, le worker
fabrique une **copie de travail** dans
`gama-models/MAELIA_1.4.29_GAMA_2025-06/includes/.runs/<runId>/` : le socle du
territoire d'abord, les octets des versions résolues par-dessus. Le modèle lit
là, et cette copie est supprimée à la fin.

!!! danger "Pourquoi cette copie n'est pas une précaution de style"
    MAELIA ne se contente pas de lire ses entrées : il en **réécrit** certaines
    pendant l'exécution. Deux exécutions qui partageraient un même répertoire se
    corrompraient mutuellement — sans erreur, sans message, avec des résultats
    silencieusement faux. Le socle du territoire, lui, reste en lecture seule.

## Les gestes courants

```bash
# Ce que le projet détient, avec l'état de chaque entrée
curl http://localhost:8000/api/v1/projects/<projectId>/completion

# L'historique des versions d'un jeu de données
curl http://localhost:8000/api/v1/datasets/<datasetId>

# Les anomalies d'une version précise
curl http://localhost:8000/api/v1/datasets/<datasetId>/versions/2/issues

# Les octets exacts d'un fichier publié
curl -O http://localhost:8000/api/v1/datasets/<datasetId>/versions/2/files/exploitations.csv
```

!!! note "Voir aussi"
    - [Créer un projet et le configurer](creer-un-projet.md) — ce qui décide de
      la liste des fichiers attendus.
    - [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md) — ce
      qui se fige au lancement.
    - [Dépannage](depannage.md) — un import qui refuse, une entrée qui reste
      manquante.
