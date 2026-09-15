# Composer un scénario

!!! abstract "En bref"
    Comment obtenir une exécution différente sans toucher aux données : un
    scénario n'enregistre que les **écarts** aux valeurs par défaut du modèle.
    Pour qui veut faire varier une durée, un seuil ou une option et comparer
    ensuite.

## Ce qu'un scénario contient

Rien d'autre que des écarts. Un scénario qui ne change qu'une valeur ne stocke
qu'une valeur ; les autres restent celles que le modèle déclare.

--8<-- "_partials/chiffres-modele.md:parametres"

!!! info "Pourquoi seulement les écarts"
    Enregistrer l'ensemble des valeurs figerait les défauts du modèle au jour de
    la création du scénario. Une montée de version du modèle laisserait alors
    traîner des valeurs périmées, sans que rien ne le signale. Reposer un
    paramètre sur sa valeur par défaut **retire** l'écart au lieu d'en
    enregistrer un.

Les scénarios d'un projet vivent sur `/simulation/projets/<id>/scenarios` ;
l'édition a sa propre page, `/simulation/projets/<id>/scenarios/<scenarioId>` —
quelques centaines de paramètres ne tiennent pas dans une modale.

## L'éditeur

Les paramètres sont groupés par section du launcher, et les sections sont
repliées. Une recherche ouvre celles qui répondent. Chaque paramètre affiche sa
valeur par défaut et un bouton pour y revenir.

Le contrôle proposé vient du **type déclaré au catalogue**, du plus contraint au
plus libre :

| Ce que dit le catalogue | Ce que vous manipulez |
|---|---|
| booléen | un interrupteur |
| liste de valeurs autorisées | une liste déroulante |
| valeurs lues dans un fichier du projet | un sélecteur ouvert sur **vos** données |
| liste sans source déclarée | des étiquettes libres |
| le reste | une saisie texte ou numérique |

Rien n'est câblé sur un nom de paramètre : ajouter un paramètre au catalogue
suffit à le rendre éditable, sans déploiement.

## Les valeurs lues dans vos données

Certains paramètres désignent un objet du territoire — une exploitation, une
parcelle. Leurs valeurs acceptables ne sont pas écrites dans le modèle : elles
sont lues dans **les données de ce projet-là**, à la version courante du fichier
concerné.

Trois absences, trois messages, parce qu'elles appellent trois gestes
différents :

| Situation | Ce qui s'affiche |
|---|---|
| Le paramètre n'a pas de source déclarée | le champ est libre |
| Le fichier n'est pas encore chargé dans le projet | le nom du fichier à fournir |
| Le fichier est là, la colonne absente ou vide | le nom de la colonne |

Dans les trois cas le champ **reste saisissable**. Une liste vide se lirait comme
« aucun choix possible », ce qui serait faux.

!!! tip "Les valeurs se chargent à l'ouverture du sélecteur"
    Pas au rendu du formulaire. Aller chercher des centaines d'identifiants pour
    un champ que personne ne touchera coûterait une requête par paramètre et par
    ouverture de section.

## Un paramètre peut en commander un autre

Un paramètre grisé n'est pas cassé : un autre le commande, et il n'a aucun effet
tant que celui-ci est éteint. Désigner une exploitation ne veut rien dire tant
que l'exécution porte sur toutes les exploitations.

**La règle est évaluée par le backend, jamais par le front.** L'interface
affiche l'état et sa raison ; elle ne refait pas le calcul. Deux évaluateurs,
ce serait deux réponses le jour où la condition change de forme.

!!! info "Un écart sur un paramètre éteint n'est pas refusé"
    Vous pouvez préparer une valeur avant d'activer le levier qui la commande.
    Elle est simplement sans effet, et l'écran le dit — plutôt que de vous
    laisser chercher pourquoi la simulation ne change pas.

## Les refus, et ce qu'ils veulent dire

L'enregistrement valide chaque écart contre le catalogue. Un refus nomme sa
raison, et cette raison est actionnable :

| Refus | Ce qu'il faut comprendre |
|---|---|
| Paramètre inconnu du launcher | il serait ignoré par GAMA : ce n'est pas une variable exposée |
| Paramètre système | la plateforme impose sa valeur à chaque exécution ; la fixer n'aurait aucun effet |
| Mauvais type | la valeur ne correspond pas au type déclaré |
| Paramètre non modifiable | sa valeur par défaut est une expression, pas une constante |

!!! warning "Un booléen n'est pas un entier"
    `true` là où un entier est attendu serait silencieusement compris comme `1`
    par Python. La validation le refuse explicitement : une durée de simulation
    d'une « vraie » année n'est pas une durée.

## Ce qu'un scénario enverra à GAMA

Avant de lancer, vous pouvez lire exactement ce qui partira au chargement du
modèle :

```bash
curl http://localhost:8000/api/v1/scenarios/<scenarioId>/gama-parameters
```

```json
[
  {"type": "int", "name": "nbAnneesSimulation", "value": 1}
]
```

Ce que vous n'y voyez pas garde la valeur du modèle. La liste peut contenir un
peu plus que vos écarts : quand la valeur retenue au catalogue diverge de celle
que déclare le launcher exécuté, la plateforme envoie explicitement la sienne
pour lever l'ambiguïté.

## Dupliquer plutôt que recommencer

Le geste le plus courant est de repartir d'un scénario existant pour ne changer
qu'une valeur — c'est ainsi qu'on obtient deux exécutions comparables. La liste
des scénarios permet de dupliquer ; la copie s'ouvre immédiatement à l'édition.

Supprimer un scénario ne touche pas aux exécutions déjà lancées : elles gardent
leurs paramètres et leurs résultats, puisque tout a été figé au lancement.

## Ce qu'un scénario ne fait pas

| Vous voulez | Ce n'est pas un scénario |
|---|---|
| Changer les données lues | publiez une nouvelle version du fichier — voir [Importer et versionner des données](importer-des-donnees.md) |
| Activer un module du modèle | c'est la configuration du projet — voir [Créer un projet](creer-un-projet.md) |
| Corriger le libellé ou le type d'un paramètre | c'est le catalogue — voir [Administrer les catalogues](administrer-les-catalogues.md) |

Un scénario parle de paramètres. Il peut porter des épingles de versions de
données — le mécanisme existe et la résolution s'en sert — mais l'interface ne
les expose pas : un fichier suit la dernière version valide, et faire varier des
données se fait en versionnant.

!!! tip "Nommez le scénario par ce qu'il change"
    « Une année », « Sans contrainte de main-d'œuvre », « Fertilisation au
    reliquat ». Trois mois plus tard, la liste des scénarios est la seule chose
    qui explique pourquoi deux courbes diffèrent.

!!! note "Voir aussi"
    - [Choisir ce que l'exécution va produire](choisir-les-sorties.md) — les
      paramètres qui décident des fichiers de sortie.
    - [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md) — ce
      que le lancement fige.
    - [Lire et comparer les résultats](lire-les-resultats.md) — superposer deux
      scénarios sur un même graphique.
