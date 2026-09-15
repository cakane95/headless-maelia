# Lire et comparer les résultats

!!! abstract "En bref"
    Comment passer d'un CSV produit par le modèle à un graphique, puis à une
    lecture enregistrée qu'on rejoue sur l'exécution suivante, et comment
    superposer deux exécutions. Pour qui a un run terminé et une question à lui
    poser.

## Où l'on entre

Par l'exécution, pas par le projet. Il n'y a pas de rubrique « Résultats » dans
la barre latérale : des résultats sont ceux d'**une** exécution, et on les ouvre
depuis elle — depuis l'écran de suivi d'un run terminé, ou depuis l'historique
des exécutions.

La route est
`/simulation/projets/<id>/simulations/<runId>/resultats`. L'écran n'a donc pas à
vous demander de quelle exécution il s'agit, et toute la place va au graphique.

## Ce que le modèle laisse derrière lui

Un dossier de fichiers, pas des indicateurs. MAELIA écrit des tables larges —
une ligne par parcelle et par période, plusieurs dizaines de colonnes dont la
plupart numériques.

La plateforme ne connaît **aucun nom de colonne MAELIA**. Elle ouvre le fichier,
dit ce que chaque colonne permet de faire, et en déduit des graphiques. C'est ce
qui permet à une nouvelle sortie d'être exploitable sans déploiement.

Chaque fichier est classé selon ce qu'on peut en faire :

| Nature | Ce que l'écran propose |
|---|---|
| `TABLE` | profil des colonnes, lectures proposées, graphique, aperçu des lignes |
| `TEXT` | lecture du contenu |
| `BINARY` | téléchargement |

## Le rôle d'une colonne

C'est la clé de tout le reste.

| Rôle | Reconnu à | Sert à |
|---|---|---|
| temporel | son **nom** (`annee`, `jourDebut`, `date`…) | ordonner l'axe |
| mesure | une forte majorité de valeurs numériques | être agrégée |
| dimension | le reste | filtrer, répartir en séries |

Le test du nom passe **avant** le test numérique : une colonne d'années ne
contient que des entiers et serait autrement moyennée comme une mesure. Et le
seuil de reconnaissance numérique n'est pas de cent pour cent, parce que le
modèle laisse des cellules vides quand une opération ne s'applique pas à la
ligne.

L'unité est extraite de l'en-tête, seul endroit où elle soit jamais écrite. Elle
sert ensuite à un refus utile : **deux mesures ne sont proposées sur un même axe
que si elles partagent leur unité**, faute de quoi l'échelle de l'une écrase
l'autre et la lecture est fausse.

## Les lectures proposées

À l'ouverture d'un fichier, la plateforme propose quelques graphiques déduits de
la forme du tableau. Ce sont des points de départ, pas des recommandations : leur
justification est affichée, et vous ajustez ensuite.

Les réglages s'ouvrent **sous** le tracé : on voit l'effet de chaque changement
sans remonter. Quatre leviers, et un seul et même mécanisme derrière eux :

| Levier | Ce qu'il change |
|---|---|
| Axe | la colonne portée en abscisse |
| Mesures | ce qui est tracé, une ou plusieurs de même unité |
| Répartition | la colonne qui sépare les séries |
| Agrégat | somme, moyenne, minimum, maximum, comptage |
| Filtres | les valeurs retenues d'une dimension |

Le type de tracé — courbe, barres, barres empilées, aire, nuage de points —
appartient à l'affichage. Le calcul, lui, est fait au backend : le front ne
calcule ni moyenne ni somme, il ne saurait pas le faire sans télécharger toutes
les lignes.

```bash
curl -X POST http://localhost:8000/api/v1/runs/<runId>/outputs/sorties_eau.csv/series \
  -H "Content-Type: application/json" \
  -d '{"x": "jourDebut", "measures": ["irrigation[mm]"], "series_by": "couvert", "aggregate": "MEAN"}'
```

## Emporter le résultat

Deux sorties distinctes, à ne pas confondre :

- **Exporter** depuis la barre du graphique produit le CSV **des points tracés** :
  ce que vous voyez, agrégé et filtré. C'est ce qu'on met dans un rapport.
- Le **téléchargement du fichier** rend les octets bruts écrits par le modèle,
  sans transformation.

```bash
curl -o sorties_eau.csv \
  http://localhost:8000/api/v1/runs/<runId>/outputs/sorties_eau.csv/download
```

## Les lectures enregistrées

Une configuration de graphique se reconstruit à la main — une fois. Reconstruire
les sept figures d'un rapport à chaque exécution, non.

Une lecture enregistrée porte son fichier, son type de tracé et sa requête, et
**appartient au projet**, pas à l'exécution sur laquelle elle a été bâtie. C'est
ce qui permet de redessiner la même figure sur la simulation suivante : vous
ouvrez les résultats d'un autre run, vous cliquez la lecture, le tracé revient.

!!! tip "Enregistrer deux fois sous le même nom met à jour"
    La lecture n'est pas dupliquée. Deux pastilles portant le même nom ne
    seraient pas une fonctionnalité.

Appliquer une lecture peut **changer de fichier** : elle porte le sien. À
l'inverse, changer de fichier à la main quitte la lecture en cours — elle ne
décrit pas les colonnes de celui-là.

## Comparer des exécutions

C'est la lecture qui donne son sens au gel des versions de données : sans elle,
la reproductibilité d'un scénario resterait une propriété invérifiable.

Depuis la barre de l'écran de résultats, ajoutez d'autres exécutions **terminées
du même projet** : la même requête est rejouée sur chacune et les séries se
superposent, préfixées par le libellé de leur exécution.

```bash
curl -X POST http://localhost:8000/api/v1/projects/<projectId>/output-comparison \
  -H "Content-Type: application/json" \
  -d '{"file_name": "sorties_eau.csv", "run_ids": ["<runA>", "<runB>"],
       "query": {"x": "annee", "measures": ["irrigation[mm]"], "aggregate": "SUM"}}'
```

Une exécution qui n'a pas produit le fichier est **ignorée, pas fatale** : un run
en échec a toute sa place dans une comparaison.

!!! warning "Comparer deux runs qui ne diffèrent pas d'un seul écart n'apprend rien"
    La méthode est de dupliquer un scénario, de changer **une** valeur, et de
    comparer. Deux scénarios composés indépendamment produiront deux courbes
    différentes sans qu'on puisse dire pourquoi — voir
    [Composer un scénario](composer-un-scenario.md).

## Quand un fichier manque

L'écran sépare trois constats, et cette séparation évite de chercher au mauvais
endroit : ce qui a été produit, ce qui était demandé mais absent — la cause est
alors dans le modèle ou dans les données — et ce qui n'était pas demandé, avec
le paramètre qui l'obtiendrait. Le panneau reste replié quand tout est conforme.

Le détail de ce mécanisme est dans
[Choisir ce que l'exécution va produire](choisir-les-sorties.md).

!!! info "Une exécution sans aucun fichier n'est pas forcément un échec"
    Une exécution arrêtée en route ne produit rien : le modèle n'écrit qu'en fin
    de période simulée. Vérifiez d'abord l'état du run.

!!! note "Voir aussi"
    - [Choisir ce que l'exécution va produire](choisir-les-sorties.md) — pour
      que le fichier voulu soit là la prochaine fois.
    - [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md) — où
      les fichiers atterrissent.
    - [Votre première simulation, de bout en bout](../demarrer/premiere-simulation.md)
      — le parcours complet, si vous n'avez pas encore de run terminé.
