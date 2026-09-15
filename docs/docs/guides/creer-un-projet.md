# Créer un projet et le configurer

!!! abstract "En bref"
    Ce qu'on décide à la création d'un projet — et surtout ce qu'on ne décide
    pas —, comment la configuration de modélisation change la liste des fichiers
    réclamés, et comment lire la complétude. Pour qui ouvre un territoire
    d'étude sur la plateforme.

## Ce qu'est un projet

Un projet réunit deux choses : un **territoire**, qui dit où le modèle lit ses
données, et une **configuration de modélisation**, qui dit lesquelles il lit.
Tout le reste — les fichiers, les scénarios, les exécutions, les résultats — lui
appartient et ne sort pas de son périmètre.

Les projets vivent dans l'espace Simulation :

--8<-- "_partials/deux-domaines.md:tableau"

--8<-- "_partials/deux-domaines.md:regle"

Un projet ne décrit donc jamais le modèle. Il l'exploite. Corriger la
description d'un fichier d'entrée ou d'un paramètre relève de
[l'administration des catalogues](administrer-les-catalogues.md).

## La création

Depuis `/simulation`, créez un projet. On vous demande un **nom** et, si vous
voulez, une description — ce que ce projet cherche à étudier. C'est tout.

Vous arrivez sur `/simulation/projets/<id>/initialisation`, qui suit l'ordre du
travail réel : décrire, configurer, charger les données.

!!! info "Pourquoi le territoire n'est pas demandé"
    Un projet neuf part du jeu de référence livré avec le modèle, et vos propres
    fichiers viennent s'y superposer version après version. Choisir un
    territoire à la création demanderait une décision avant d'avoir de quoi la
    prendre — et un territoire sans données ne serait, de toute façon, pas
    exécutable.

Le nom et la description se modifient ensuite depuis l'écran d'initialisation.
Le territoire, lui, ne change pas : c'est le socle sur lequel les données ont
été posées, et le déplacer invaliderait tout ce qui a été chargé.

## La configuration de modélisation

C'est le levier central du projet. Chaque interrupteur active un module du
modèle, et chaque module rend obligatoires **ses** fichiers d'entrée.

| Réglage | Ce qu'il active |
|---|---|
| Modèle agricole | assolements, itinéraires techniques, fertilisation, rendements |
| Modèle hydrographique | bassins versants, débits, prélèvements et restrictions |
| Modèle normatif | règles de gestion et arrêtés de restriction |
| Modèle élevage | troupeaux, pâturage et effluents |
| Îlots hors zone | parcelles situées hors du périmètre d'étude |
| Barrages | retenues et lâchers, en complément du modèle hydrographique |

Trois choix complémentaires n'apparaissent que si le module dont ils dépendent
est actif — les afficher autrement laisserait croire qu'ils changent quelque
chose : la variante du modèle hydrographique, l'origine de l'assolement et le
modèle de croissance des prairies.

Sous le formulaire, une phrase annonce combien de fichiers d'entrée la
configuration en cours attend. Elle se recalcule à chaque interrupteur, **avant**
l'enregistrement : vous voyez le coût d'un module avant de vous y engager.

!!! tip "Activez au plus juste, et tôt"
    Chaque module ajouté est une liste de fichiers à fournir. Commencez par le
    minimum, faites tourner, puis étendez. Activer un module après avoir chargé
    les données ne casse rien — la complétude retombe simplement sous 100 %, et
    l'écran des données vous dit exactement ce qui manque.

Pour mémoire, l'ampleur du catalogue derrière ces interrupteurs :

--8<-- "_partials/chiffres-modele.md:entrees"

## La complétude, précisément

`/simulation/projets/<id>/donnees` affiche une barre d'avancement. Elle ne
compte pas les fichiers présents : elle compte les **entrées obligatoires
satisfaites**, et « satisfaite » a un sens strict.

| État d'une entrée | Compte comme fournie |
|---|---|
| `VALID` — au moins une version publiée et valide | oui |
| `DRAFT` — des lignes en cours d'édition, jamais publiées | non |
| `INVALID` — une version publiée, mais la validation a échoué | non |
| `MISSING` — rien de fourni | non |

Un brouillon n'est pas un fichier : il n'est pas publié, donc l'exécution ne le
lirait pas. Un fichier invalide non plus — le charger produirait un résultat
qu'on ne pourrait pas défendre.

Les fichiers **facultatifs** ne sont jamais comptés. Leur absence ne bloque
rien : le modèle continue sans eux. Ils apparaissent quand même dans la liste
des fichiers attendus, avec leur état.

L'écran affiche aussi le détail par module, ce qui montre d'un coup d'œil quel
module est incomplet, et les données que le projet détient **sans que sa
configuration les réclame** — une archive de territoire en apporte, et les taire
ferait croire à un import manqué.

## Ce que la complétude décide

Le lancement d'une exécution est **refusé** tant qu'une entrée obligatoire
manque. Le refus arrive au moment du lancement, avec la liste des fichiers
fautifs — pas au bout de vingt minutes de simulation.

```json
{
  "type": "about:blank",
  "title": "État incompatible",
  "status": 409,
  "detail": "3 entrée(s) obligatoire(s) manquante(s) : Engrais, Espèces cultivées, Parcelles"
}
```

C'est le seul verrou dur du projet. Tout le reste — paramètres, sorties,
lectures — se corrige après coup.

## Ce qui ne relève pas du projet

La confusion la plus fréquente porte sur la frontière entre configuration et
scénario.

| Décision | Où elle se prend |
|---|---|
| Quels modules tournent | configuration du projet |
| Quels fichiers sont obligatoires | configuration du projet, via les modules |
| Durée simulée, année de départ, seuils, options fines | [scénario](composer-un-scenario.md) |
| Quels fichiers de sortie seront écrits | [scénario](choisir-les-sorties.md), par ses drapeaux |
| Quelle version d'un fichier est lue | [données](importer-des-donnees.md), la dernière valide |

La règle tient en une phrase : la configuration décide de **ce qui est lu**, le
scénario de **comment ça tourne**.

## Supprimer un projet

La suppression emporte les données, les scénarios et l'historique d'exécutions
du projet. Les fichiers de sortie déjà écrits sur le disque, eux, restent dans
`gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log/<runId>/` — la
plateforme ne sait simplement plus à quoi les rattacher.

!!! note "Voir aussi"
    - [Importer et versionner des données](importer-des-donnees.md) — l'étape
      suivante, celle qui remplit la barre.
    - [Votre première simulation, de bout en bout](../demarrer/premiere-simulation.md)
      — le même parcours, en tutoriel guidé.
    - [Composer un scénario](composer-un-scenario.md) — ce qui se règle après
      la configuration.
