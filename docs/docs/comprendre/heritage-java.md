# Ce que la version Java a enseigné

!!! abstract "En bref"
    Ce dépôt est une reprise en Python d'une plateforme écrite en Java. La
    version précédente avait de bonnes idées, beaucoup de code, et n'a jamais
    mené une simulation MAELIA de bout en bout. Cette page dit ce qu'on en garde
    et ce qu'on refuse de refaire.

!!! question "Le problème"
    Une architecture propre ne coûte rien sur le papier et beaucoup en pratique.
    Chaque port, chaque couche, chaque représentation supplémentaire consomme du
    budget. Quand ce budget est consommé avant la première exécution réelle, il
    reste une structure irréprochable qui n'a jamais rien produit — et personne
    ne sait laquelle de ses hypothèses était fausse.

## Ce que la version Java avait vu juste

Deux idées structurantes viennent d'elle, et sont reprises telles quelles.

**Le découpage par contexte métier**, plutôt que par couche technique. Tout ce
qui concerne les jeux de données vit dans un même répertoire ; ajouter une
fonctionnalité doit toucher un seul endroit. Les dossiers organisés par couche
grossissent sans borne et forcent à sauter entre trois répertoires pour suivre
un changement.

**Le pilotage par catalogue.** Rien du modèle n'est codé en dur : les entrées,
les paramètres et les sorties sont des données. C'est la règle qui permettra
d'accueillir un second modèle, et elle est plus exigeante aujourd'hui qu'elle ne
l'était alors — voir [rien-n-est-code-en-dur.md](rien-n-est-code-en-dur.md).

Le principe de dépendance vers l'intérieur reste lui aussi en vigueur : le
domaine n'importe ni le cadre web, ni l'ORM, ni le client du moteur.

## Ce qu'elle n'a jamais fait

Elle n'a jamais exécuté une simulation MAELIA de bout en bout. Le socle
d'infrastructure, les contrats, les tests d'adaptateurs : tout pouvait être au
vert sans que la seule chose que la plateforme existe pour faire ait été
vérifiée une fois.

Le chiffre qui accompagne ce constat est celui du volume — de l'ordre de cent
quatre-vingts fichiers pour neuf contextes — mais le volume n'est pas la leçon.
La leçon est l'ordre des dépenses : la cérémonie a été payée d'abord, la
validation ensuite, et il n'est rien resté pour la seconde.

## Les symptômes, vus après coup

| Symptôme | Ce qu'il signalait |
|---|---|
| Un port par entité | des interfaces créées par symétrie, sans substitution réelle derrière |
| Trois classes pour transporter quelques champs | un domaine créé là où aucune règle métier n'existait |
| Une couche de mappers | un coût de lecture permanent pour éviter d'écrire deux fonctions |
| Des abstractions « au cas où » | un second moteur de simulation abstrait avant d'en avoir un second |
| Un socle technique fourre-tout | des règles métier réfugiées là où personne ne les cherche |

Aucun de ces points n'est une faute de goût. Chacun est un report : du temps pris
à la validation et rendu à la structure.

## La règle d'arbitrage retenue

!!! tip "Une abstraction doit rendre un service aujourd'hui"
    Isoler une dépendance instable, permettre un test sans infrastructure,
    empêcher un cycle : ce sont des services, et ils se nomment. « C'est plus
    propre » n'en est pas un.

La règle se décline en gestes simples. Un port existe pour isoler une dépendance
externe ou pour permettre une substitution réelle, jamais par symétrie. Un
contexte sans règle métier n'a pas de domaine vide : on en introduira un le jour
où une règle apparaîtra. Le passage d'une représentation à l'autre tient dans
deux fonctions explicites par contexte, lisibles et déboguables.

Ce n'est pas un renoncement à l'architecture : c'est le refus de la payer
d'avance.

## Ce qui prouve désormais que la plateforme marche

Deux exigences remplacent la confiance dans la structure.

**Une règle métier se teste sans conteneur.** Si un test de règle réclame une
base de données, la règle est au mauvais endroit — et c'est un signal
d'architecture, pas un inconfort de test.

**Le seul test qui prouve quelque chose est une exécution MAELIA réelle.** Après
toute modification du pipeline d'exécution, on lance une simulation courte et on
vérifie qu'elle atteint son état terminal avec ses fichiers de sortie. C'est
précisément le test que la version Java n'a jamais passé, tout en ayant tout le
reste au vert.

## L'héritage du catalogue

La version Java avait produit deux jeux de référence, repris comme point de
départ. L'extraction depuis le code de la version livrée en donne davantage : le
catalogue précédent ignorait des modules entiers — élevage, fertilisation — et
regroupait certaines familles de fichiers.

--8<-- "_partials/chiffres-modele.md:tout"

L'écart n'est pas une erreur de comptage isolée : c'est la différence entre un
inventaire saisi à la main et un inventaire engendré depuis la source qui
s'exécute. Le second se régénère à chaque montée de version ; le premier
vieillit en silence.

## Une dernière leçon, sur la documentation

Le même travers a touché la documentation de la version précédente. Une page
décrivait un modèle de contenu générique — discriminants, types scellés,
enveloppes d'artefacts — dont rien n'a jamais existé dans le code. Elle se lisait
comme une description, et elle était une intention.

!!! warning "Documenter une intention comme un fait est le défaut le plus coûteux"
    Il ne se voit pas à la lecture. Il se découvre en écrivant du code contre une
    description fausse. C'est la raison pour laquelle chaque affirmation de cette
    section porte un chemin de fichier : une affirmation sans source est une
    affirmation qu'on ne peut pas réfuter.

La page en question est conservée, explicitement marquée comme non implémentée
(`docs/docs/archive/modele-domaine-donnees-entree.md`) — l'idée qu'elle porte
reste défendable, mais elle ne décrit pas ce dépôt.

!!! note "Voir aussi"
    - [Rien de MAELIA n'est écrit dans le code](rien-n-est-code-en-dur.md)
    - [Administration et Simulation](les-deux-domaines.md)
    - [Documentation antérieure, et pourquoi elle a été refaite](../archive/index.md)
