# Glossaire

!!! abstract "En bref"
    Le vocabulaire de la plateforme et celui du modèle, avec pour chaque terme
    le nom qu'il porte dans le code. À consulter quand un mot de l'interface ou
    d'une page de référence n'a pas le sens qu'on lui donnerait ailleurs.

**Source** : extraction de `headless-maelia-server/app/contexts/*/domain/` et des trois catalogues de `.../catalog/infrastructure/seed/` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

## Les deux domaines

Le vocabulaire se partage en deux. **Administration** *décrit* un modèle :
entrées, paramètres, sorties. **Simulation** l'*exploite* sur un territoire.
Administration produit les schémas que Simulation consomme, et la flèche ne
s'inverse jamais.

| Terme | Domaine | Dans le code |
|---|---|---|
| Catalogue, spec, paramètre, sortie, drapeau, garde | Administration | `contexts/catalog/` |
| Projet, territoire, jeu de données, version, épingle, scénario, écart, run, résultat | Simulation | `contexts/project/`, `dataset/`, `scenario/`, `run/`, `result/` |

## Termes de la plateforme

`Catalogue`

:   L'ensemble de ce que la plateforme sait d'un modèle : ses fichiers
    d'entrée, ses paramètres, ses sorties. Il est **engendré depuis le GAML**,
    pas écrit à la main, et se recharge au démarrage de l'API. Trois catalogues
    distincts : `dataspecs.json`, `parameters.json`, `outputs.json`.

`Spec`

:   Une entrée du catalogue : la *description* d'une chose, jamais la chose.
    Une `DataSpec` décrit un **type** de fichier d'entrée — son chemin, son
    délimiteur, ses champs, sa condition d'applicabilité — mais ne contient
    aucune donnée. De même, une `ParameterSpec` décrit un paramètre et une
    `OutputSpec` une famille de sorties. Le fichier réel d'un projet est un
    *jeu de données*, pas une spec.

`Origine` (`SEED` / `USER`)

:   D'où vient une spec. `SEED` : telle que le catalogue de référence la livre.
    `USER` : un administrateur l'a modifiée par l'API d'administration ; elle
    n'est alors plus écrasée par le rechargement du seed. La route `restore`
    la rend au seed.

`Projet`

:   Un territoire d'étude et les données qui le décrivent. Porte une
    *configuration de modélisation* — quels modules du modèle tournent — dont
    découlent les fichiers attendus.

`Territoire`

:   Le découpage géographique sur lequel une simulation porte, et le nom du
    répertoire où le modèle va chercher ses entrées. Côté GAML, c'est la valeur
    du paramètre `nomDecoupageZonePourLectureFichiers` ; tout chemin d'entrée
    est relatif à `<cheminModeleVersDonnees><territoire>/`.

    !!! warning "Les territoires livrés ne sont pas du matériel de projet"
        Les jeux rangés sous `gama-models/.../includes/` servent à exercer GAMA
        depuis le banc d'essai. Les données d'un projet viennent de ses propres
        téléversements. `terrainTest` est le jeu de référence : le seul dont on
        ait la preuve qu'il mène un run à terme.

`Jeu de données`

:   Ce qu'un projet fournit pour une spec d'entrée donnée : une suite de
    **versions**. Le jeu est l'identité durable, la version est le contenu
    figé.

`Version`

:   Un état publié et **immuable** d'un jeu de données. Les octets d'origine
    sont conservés tels quels ; la projection en lignes qu'en donne l'API est
    reconstructible depuis eux. C'est ce qui permet de rejouer un run à
    l'identique.

`Brouillon`

:   Les lignes en cours d'édition d'un jeu de données, avant publication.
    Amorcé à partir de la version courante quand il est vide. Publier le fige
    en une nouvelle version.

`Épingle`

:   Dans un scénario, le choix explicite d'une version précise d'un jeu de
    données (`dataset_pins`, `{identifiant de jeu : identifiant de version}`).
    Ce qui n'est pas épinglé suit la **dernière version valide** de son jeu :
    le scénario reste utilisable à mesure que les données sont corrigées.
    Épingler n'est utile que pour ce qui doit ne pas bouger.

`Scénario`

:   Ce qui rend un run différent : un ensemble d'**écarts** et un ensemble
    d'**épingles**. Un scénario ne stocke jamais les valeurs complètes — cela
    figerait les défauts du launcher au moment de sa création, et une montée de
    version du modèle conserverait silencieusement des valeurs périmées.

`Écart`

:   Une valeur de paramètre qui s'écarte du défaut du launcher
    (`parameter_values`). Un scénario ne porte que ses écarts. Ils se
    remplacent **en bloc** : une fusion rendrait impossible le retrait d'une
    surcharge, or renvoyer le jeu complet est la seule façon de dire « ce
    paramètre revient à son défaut ».

`Run`

:   Le contexte qui porte une exécution : ses réglages, son état, ses journaux,
    ses fichiers de sortie. Le domaine s'appelle *Simulation* ; ce qui
    s'exécute s'appelle un `run`. Un run travaille sur une **copie** de ses
    includes, parce que MAELIA réécrit ses fichiers d'entrée pendant
    l'exécution.

`Banc d'essai`

:   Les routes `/api/v1/admin/runs` : lancer un launcher livré avec le modèle,
    sans passer par un projet, pour vérifier que la chaîne complète fonctionne.

`Lecture` (*output view*)

:   Une manière enregistrée de regarder un fichier de sortie — abscisse,
    mesures, séparation en séries, filtres. Enregistrée sur le projet, elle
    s'applique à n'importe lequel de ses runs.

`Sonde`

:   Un contrôle de disponibilité d'une dépendance. Une sonde **rend compte,
    elle ne propage jamais** : un contrôle en échec n'empêche pas les autres de
    répondre.

## Termes du modèle

`Launcher`

:   Le fichier GAML qui expose les variables surchargeables au `load` de
    gama-server. `launcherBase.gaml` est le référentiel : la liste des
    paramètres du catalogue en est l'extraction exacte. Un réglage qui n'y
    figure pas ne peut pas être surchargé.

`Module`

:   L'une des quatre grandes parties du modèle : `modeleAgricole`,
    `modeleCommun`, `modeleHydrographique`, `modeleNormatif`. Le module
    détermine à la fois l'arborescence des entrées et le paramètre
    d'activation qui les rend applicables.

`Drapeau`

:   Une variable booléenne de `output/selectionOutput.gaml` qui commande une
    famille de sorties. Le modèle n'écrit presque rien par défaut : sans
    drapeau levé, le module d'écriture n'est pas appelé.

`Aiguillage`

:   `output/ecritureResultats.gaml`, qui teste les drapeaux et appelle les
    modules d'écriture. Une sortie *hors aiguillage* est écrite directement au
    fil du code, sans drapeau.

`Garde`

:   La condition complète sous laquelle une sortie est écrite. Ce n'est pas le
    seul drapeau : celui-ci est imbriqué dans les gardes des modules dont la
    sortie dépend, et la garde est la conjonction de toute la pile. Traduite
    dans le champ `produced_if`.

`Langage de conditions`

:   Le langage minimal dans lequel s'écrivent `required_if` (entrées),
    `enabled_if` (paramètres) et `produced_if` (sorties) : des comparaisons
    `param == valeur` ou `param != valeur`, liées par `&&` et `||`. **`&&` lie
    plus fort que `||`**, et il n'y a **pas de parenthèses** — l'expression est
    en forme normale disjonctive. Elle tient donc sur une ligne et se lit dans
    une cellule de tableau. Le catalogue est de la donnée, jamais du script :
    aucun code arbitraire n'y est évalué.

`exact`

:   Sur une sortie, dit si la traduction de la garde GAML est complète.
    `exact: false` signifie que la traduction a dû **abandonner un terme
    inexprimable** — une longueur de liste, un état interne, une date codée en
    dur. La sortie est alors annoncée *possible*, jamais certaine, et
    `guard_source` conserve le texte GAML d'origine : une traduction qui
    abandonne un terme doit rester vérifiable.

`guard_source`

:   Le texte GAML brut de la garde, conservé tel quel à côté de sa traduction.

`Granularité`

:   Le **pas de temps auquel un fichier de résultat est écrit** : `DAILY`,
    `YEAR_START`, `YEAR_END`, `MONTHLY`, `FORTNIGHTLY`, ou `UNKNOWN` quand le
    module n'en déclare pas. Elle se lit dans la variable de chemin que le
    module de sortie renseigne (`nomFichierJournalier`, `nomFichierFinAnnuel`…)
    — le modèle ne l'énonce nulle part ailleurs. C'est une propriété du
    **fichier**, pas de la sortie : une même sortie peut écrire un fichier
    journalier et un fichier annuel.

`Orientation`

:   Le sens de lecture d'un fichier tabulaire d'entrée. `FIELDS_AS_COLUMNS` est
    la disposition ordinaire : un champ par colonne, une entité par ligne.
    `FIELDS_AS_ROWS` est transposé : les noms de champs occupent la première
    colonne, chaque colonne suivante décrit une entité.

`options_from`

:   Sur un paramètre, la déclaration `<identifiant de fichier>#<champ>` : les
    valeurs acceptables ne forment pas une énumération figée, elles **vivent
    dans les données du projet**. La plateforme propose alors les identifiants
    réellement présents, au lieu de laisser saisir une valeur que seule
    l'exécution démentirait. Un champ vide après le `#` désigne les fichiers
    eux-mêmes.

`launcher_default`

:   Sur un paramètre, ce que déclare le **launcher exécuté** quand il diverge du
    défaut retenu au catalogue. Non nulle, la plateforme envoie explicitement
    cette valeur à chaque exécution.

`system`

:   Sur un paramètre, dit qu'il est **imposé par la plateforme** : le worker
    l'écrit à chaque exécution. Le surcharger dans un scénario n'a aucun effet.

`Hors de portée`

:   Une sortie dont le drapeau est déclaré par `selectionOutput.gaml` mais pas
    par `launcherBase.gaml` : il ne peut donc pas être surchargé au `load`, et
    la sortie est inatteignable quoi que fasse l'utilisateur. La rendre
    accessible demande une modification du **modèle**, pas du catalogue.

`includes`

:   Le répertoire du modèle où vivent les données d'entrée, un sous-répertoire
    par territoire. Ce n'est pas du matériel de projet.

`headless`

:   Le mode d'exécution de GAMA sans interface graphique, piloté par un socket
    WebSocket. C'est ce qui permet de faire tourner MAELIA sur un serveur.

`idSimulationAPI`

:   Le paramètre GAML par lequel la plateforme impose l'identifiant du run.
    Il rend le dossier de sortie **déterministe** : `models/main/log/<runId>`,
    au lieu d'un nom composé d'un horodatage.

!!! note "Voir aussi"

    - [Les fichiers d'entrée](fichiers-entree.md)
    - [Les paramètres de scénario](parametres.md)
    - [Les sorties du modèle](sorties.md)
    - [L'API REST](api-rest.md)
