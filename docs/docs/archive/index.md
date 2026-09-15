---
search:
  exclude: true
---

# Archive — documentation antérieure

!!! danger "Ces pages ne font plus autorité"
    Elles sont conservées pour mémoire : elles portent le raisonnement qui a
    conduit à l'état actuel, et quelques passages n'ont pas encore trouvé leur
    place ailleurs. Mais elles contiennent des **affirmations fausses** —
    chiffres périmés, chemins disparus, types qui n'ont jamais existé dans le
    code Python. Elles sont exclues de la recherche du site pour cette raison.

    En cas de désaccord entre une page d'archive et le reste de ce site, **le
    reste du site gagne**. En cas de désaccord entre le site et le code, **le
    code gagne**.

## Pourquoi cette documentation a été refaite

Les huit pages ci-dessous ont été écrites au fil des fonctionnalités, jamais
conçues comme un ensemble. Le diagnostic qui a déclenché la refonte :

| Symptôme | Constat |
|---|---|
| Redites | « Les deux domaines » était exposé quatre fois, « anti-patterns et check-list de revue » quatre fois, « état du projet » trois fois |
| Chiffres faux | L'accueil annonçait un nombre de sorties que le catalogue contredisait ; le décompte des drapeaux actifs par défaut était inexact |
| Page décrivant du code inexistant | `modele-domaine-donnees-entree.md` documente `contentKind`, `ArtifactBundle`, `StoredObject` — aucun de ces types n'existe dans le code Python. C'est le design de la version Java abandonnée |
| Numérotation cassée | `frontend.md` avait des sections « 6 bis », « 6 ter », « 6 quater » : insérer une section coûtait une renumérotation, donc personne ne renumérotait |
| Aucun diagramme côté frontend | 851 lignes décrivant deux espaces de routes, un pipeline de chargement et un module de graphiques, sans un schéma |
| Trous | Aucune page d'installation, d'utilisation, de dépannage, de référence d'API ni de glossaire |

La page d'accueil archivée l'admettait elle-même, dans un encadré intitulé
« Sections en construction ».

## Où est passé chaque document

| Page archivée | Remplacée par |
|---|---|
| [Accueil](accueil.md) | [la page d'accueil](../index.md) |
| [Architecture backend](backend.md) | section **Comprendre** (le pourquoi) et **Architecture** (le comment) |
| [Backend — bonnes pratiques](backend-bonnes-pratiques.md) | section **Contribuer** |
| [Backend — les domaines](backend-domaines.md) | section **Architecture**, une page par contexte |
| [Architecture frontend](frontend.md) | section **Architecture** |
| [Frontend — bonnes pratiques](frontend-bonnes-pratiques.md) | section **Contribuer** |
| [Modèle de domaine — données d'entrée](modele-domaine-donnees-entree.md) | **abandonnée** : voir ci-dessous |
| [Données, sorties et paramètres](donnees-et-parametres.md) | section **Référence** |

## Le cas du modèle de domaine des données d'entrée

Cette page mérite un avertissement à part. Elle décrit un modèle de contenu
générique — un discriminant `contentKind`, des `ArtifactBundle`, des
`StoredObject` avec rôles, des types scellés et des `switch` exhaustifs. Rien
de tout cela n'existe dans `headless-maelia-server/` : une recherche sur ces
noms ne renvoie rien.

C'est le vestige du design de la version Java, qui n'a jamais été implémenté.
Il reste ici parce que **l'idée** d'un discriminant générique reste défendable
et pourrait revenir un jour ; elle est reprise, explicitement étiquetée comme
non implémentée, dans le journal des décisions.

Deux choses de cette page restent vraies et ont été reprises ailleurs :

- un shapefile ne se sépare jamais de ses fichiers frères (`.shp`, `.shx`,
  `.dbf`, `.prj`) ;
- un contenu binaire et un contenu tabulaire ne se stockent pas de la même
  manière.

!!! quote "Leçon retenue"
    Documenter une intention comme si elle était implémentée est le défaut le
    plus coûteux d'une documentation : il ne se voit pas à la lecture, et il se
    découvre en écrivant du code contre une description fausse. La règle de
    citation de la nouvelle documentation — toute affirmation porte un chemin
    de fichier — existe pour rendre cette faute difficile.
