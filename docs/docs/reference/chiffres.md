# Les chiffres du modèle

!!! abstract "En bref"
    Tous les décomptes du modèle MAELIA, et eux seuls, vivent ici. Cette page
    est l'**hôte** des fragments que les autres pages incluent : un chiffre
    n'existe qu'à un seul endroit, et se recompte par une commande. À consulter
    pour citer une quantité, ou pour vérifier qu'elle est encore juste.

**Source** : extraction de `headless-maelia-server/app/contexts/catalog/infrastructure/seed/dataspecs.json`, `parameters.json` et `outputs.json` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

--8<-- "_partials/avertissement-code-fait-autorite.md:version"

## Vue d'ensemble

--8<-- "_partials/chiffres-modele.md:tout"

Aucun de ces noms n'est écrit dans le code de la plateforme. Les trois
catalogues sont engendrés depuis le GAML du modèle, puis chargés au démarrage
de l'API ; une montée de version du modèle les régénère.

## Entrées

--8<-- "_partials/chiffres-modele.md:entrees"

Le détail ligne à ligne est dans [Les fichiers d'entrée](fichiers-entree.md).

| Ce qui est compté | Définition exacte |
|---|---|
| Types de fichiers d'entrée | entrées de `dataspecs.json` — un **type** de fichier, pas un fichier livré : une entrée à motif comme la série météo annuelle en représente autant que d'années |
| dont module *X* | entrées dont le champ `module` vaut `modeleAgricole`, `modeleHydrographique`, `modeleCommun` ou `modeleNormatif` |
| Obligatoires quelle que soit la configuration | entrées dont `required` vaut vrai — sans considérer `required_if`, qui dit seulement si le fichier est *attendu* |

## Paramètres

--8<-- "_partials/chiffres-modele.md:parametres"

Le détail ligne à ligne est dans [Les paramètres de scénario](parametres.md).

| Ce qui est compté | Définition exacte |
|---|---|
| Paramètres exposés par le launcher | entrées de `parameters.json` — la liste des variables surchargeables au `load` de gama-server |
| Modifiables dans un scénario | entrées dont `editable` vaut vrai |
| Imposés par la plateforme | entrées non modifiables : celles dont `system` vaut vrai, plus celle dont le défaut est une expression GAML que le catalogue ne sait pas transposer |
| Sections du launcher | valeurs distinctes du champ `group` |

## Sorties

--8<-- "_partials/chiffres-modele.md:sorties"

Le détail ligne à ligne est dans [Les sorties du modèle](sorties.md).

| Ce qui est compté | Définition exacte |
|---|---|
| Sorties au catalogue | entrées de `outputs.json` — une **famille** de résultats, qui peut écrire plusieurs fichiers |
| Fichiers qu'elles produisent | somme des longueurs du champ `files` ; le même nom de fichier peut être écrit par deux sorties distinctes |
| Pilotées par un drapeau | entrées dont `flag` est renseigné |
| Écrites hors aiguillage | entrées dont `flag` est nul : écrites au fil du code, sans passer par `output/ecritureResultats.gaml` |
| Drapeaux déclarés par le modèle | variables booléennes de `output/selectionOutput.gaml` — toutes ne sont pas aiguillées |
| Drapeaux actifs par défaut | drapeaux dont `default` vaut vrai |
| Drapeaux hors de portée d'un scénario | drapeaux du catalogue de sorties absents du catalogue de paramètres : inatteignables au `load` |
| Gardes non entièrement traduisibles | entrées dont `exact` vaut faux |
| Thèmes de regroupement | valeurs distinctes du champ `theme` |

!!! warning "Sorties et fichiers ne se comptent pas pareil"
    Une sortie est une famille, un fichier est un nom sur le disque. Deux
    sorties peuvent écrire le même fichier sous des gardes différentes — c'est
    le cas de `modeleAqYield_Journalier.csv`. Additionner les deux colonnes n'a
    donc pas de sens.

## Où vivent ces chiffres

Les fragments sont dans `docs/_partials/`. Ils sont inclus par l'extension
`pymdownx.snippets`, avec `check_paths: true` : si un fragment disparaît, la
construction échoue au lieu de publier un trou.

| Fragment | Ancres | Inclus par |
|---|---|---|
| `_partials/chiffres-modele.md` | `tout`, `entrees`, `parametres`, `sorties` | cette page, `fichiers-entree.md`, `parametres.md`, `sorties.md`, l'accueil |
| `_partials/services.md` | `urls`, `sondes` | [Configuration et services](configuration.md), l'accueil |
| `_partials/avertissement-code-fait-autorite.md` | `autorite`, `version` | cette page, `fichiers-entree.md`, `ecarts-code-documentation.md` |

La syntaxe d'inclusion, seule sur sa ligne :

```markdown
;--8<-- "_partials/chiffres-modele.md:sorties"
```

!!! danger "Ne jamais recopier un chiffre dans une phrase"
    Un décompte inscrit en dur dans la prose survit à la régénération du
    catalogue et devient faux sans que rien ne le signale. C'est la panne qui a
    rendu la documentation antérieure inutilisable. Un chiffre du modèle ne
    s'écrit que dans `_partials/chiffres-modele.md`, jamais dans un titre de
    section ni au milieu d'une phrase.

## Comment les recompter

Les trois catalogues sont des fichiers JSON : tout se recompte sans démarrer la
plateforme, depuis la racine du dépôt.

```bash
python - <<'PY'
import json, pathlib, collections
seed = pathlib.Path("headless-maelia-server/app/contexts/catalog/infrastructure/seed")
d = json.loads((seed / "dataspecs.json").read_text(encoding="utf-8"))
p = json.loads((seed / "parameters.json").read_text(encoding="utf-8"))
o = json.loads((seed / "outputs.json").read_text(encoding="utf-8"))

print("entrées            ", len(d), collections.Counter(x["module"] for x in d))
print("  obligatoires     ", sum(1 for x in d if x["required"]))
print("paramètres         ", len(p))
print("  modifiables      ", sum(1 for x in p if x["editable"]))
print("  sections         ", len({x["group"] for x in p}))
print("sorties            ", len(o))
print("  fichiers         ", sum(len(x["files"]) for x in o))
print("  avec drapeau     ", sum(1 for x in o if x["flag"]))
print("  hors aiguillage  ", sum(1 for x in o if not x["flag"]))
print("  actives d'office ", sum(1 for x in o if x["flag"] and x["default"]))
print("  gardes inexactes ", sum(1 for x in o if not x["exact"]))
print("  thèmes           ", len({x["theme"] for x in o}))
names = {x["name"] for x in p}
print("  hors de portée   ", len({x["flag"] for x in o if x["flag"] and x["flag"] not in names}))
PY
```

Deux chiffres ne se lisent pas dans les seeds et se comptent dans le modèle
lui-même — ils portent sur ce que le GAML **déclare**, pas sur ce que
l'extraction a retenu :

```bash
cd gama-models/MAELIA_1.4.29_GAMA_2025-06/models
grep -cE '^\s*bool\s+\w+' output/selectionOutput.gaml   # drapeaux déclarés
ls output/*.gaml | wc -l                                # modules de sortie
```

!!! tip "Quand recompter"
    Après toute régénération des seeds, et à chaque montée de version du modèle.
    Un écart entre le fragment et la sortie du script signifie que le fragment
    est périmé : c'est lui qu'on corrige, jamais l'inverse.

## Ce que la version Java annonçait

La plateforme Java qui a précédé celle-ci annonçait un catalogue plus petit :
son périmètre ignorait les modules élevage et fertilisation, et regroupait
certaines familles de fichiers. Les chiffres de cette page les remplacent,
étant tirés du code de la version 1.4.29 livrée. Le détail de cet héritage est
dans [la documentation antérieure](../archive/donnees-et-parametres.md).

!!! note "Voir aussi"

    - [Les fichiers d'entrée](fichiers-entree.md)
    - [Les paramètres de scénario](parametres.md)
    - [Les sorties du modèle](sorties.md)
    - [Glossaire](glossaire.md)
