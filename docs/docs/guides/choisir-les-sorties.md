# Choisir ce que l'exécution va produire

!!! abstract "En bref"
    Comment savoir, **avant** de lancer, quels fichiers seront écrits — et quoi
    activer pour obtenir celui qui manque. Pour qui a déjà un scénario et veut
    des sorties exploitables plutôt qu'un dossier vide.

## Le modèle n'écrit rien par défaut

C'est la surprise la plus coûteuse de MAELIA : lancé sans rien régler, il tourne
jusqu'au bout et ne laisse presque rien derrière lui. Chaque sortie est derrière
un **drapeau**, souvent imbriqué dans les conditions des modules dont elle
dépend.

--8<-- "_partials/chiffres-modele.md:sorties"

Deux conséquences pratiques : une exécution qui produit peu de fichiers n'est pas
en panne, et un fichier absent ne s'explique pas en cherchant dans le modèle,
mais en relisant les réglages.

## Le catalogue des sorties

`/admin/catalogue/sorties` recense ce que le modèle **peut** écrire : pour
chaque sortie, son thème, les fichiers qu'elle produit, leur pas de temps et le
drapeau qui la commande. Il est engendré depuis le GAML ; l'administrateur le
corrige à la marge.

Trois indicateurs y méritent une lecture attentive :

- les sorties recensées, et le nombre de fichiers qu'elles produisent — les deux
  ne coïncident pas, une sortie pouvant écrire plusieurs fichiers ;
- les sorties **hors de portée d'un scénario** : leur drapeau n'est pas déclaré
  par le launcher, donc aucun scénario ne peut les activer. Les rendre
  accessibles est une modification du modèle, pas un réglage ;
- la **garde GAML** d'origine, conservée telle quelle à côté de sa traduction :
  une traduction qui abandonne un terme doit rester vérifiable.

## Pendant que vous composez le scénario

L'éditeur de scénario annonce, en direct pendant la saisie, combien de fichiers
la configuration en cours produira. Vous n'attendez pas la fin d'une exécution
pour découvrir que vous n'avez rien demandé.

L'écran ne calcule rien : il interroge le backend, où la condition est écrite une
seule fois.

```bash
curl -X POST http://localhost:8000/api/v1/outputs/expected \
  -H "Content-Type: application/json" \
  -d '{"values": {"sorties_azote": true}}'
```

La réponse donne, pour chaque sortie, l'un de trois verdicts.

| Verdict | Ce qu'il signifie |
|---|---|
| `PRODUCED` | elle sera écrite avec ces réglages |
| `ABSENT` | elle ne le sera pas, et la réponse dit ce qui bloque |
| `UNCERTAIN` | sa condition contient un terme que le langage de conditions ne sait pas trancher |

!!! info "Pourquoi un verdict incertain existe"
    Quelques gardes du modèle portent un appel ou une longueur de liste, que la
    condition du catalogue ne sait pas exprimer. Annoncer l'une ou l'autre
    réponse serait une devinette. L'incertitude est affichée telle quelle,
    plutôt que remplacée par une affirmation fausse.

## Le chemin le plus court vers un fichier

Quand une sortie est `ABSENT`, la réponse ne dit pas seulement « non » : elle
nomme les **paramètres à activer**, et choisit la route la plus courte lorsqu'une
condition offre plusieurs branches.

```json
{
  "id": "engrais_utilises_territoire",
  "label": "Engrais utilises territoire",
  "theme": "AqYield",
  "production": "ABSENT",
  "files": ["resultats_N_engrais_utilises_territoire.csv"],
  "blocking": ["engrais_utilises_territoire"],
  "reason": "à activer : engrais_utilises_territoire"
}
```

Vous portez ces noms dans votre scénario, et le compteur de l'éditeur bouge
aussitôt.

!!! warning "Un drapeau activé ne suffit pas toujours"
    Les conditions sont imbriquées : le drapeau d'une sortie hydrographique n'a
    d'effet que si le module hydrographique tourne. Or le module se règle dans
    la **configuration du projet**, pas dans le scénario. Si activer un drapeau
    ne change rien au compteur, vérifiez le module — voir
    [Créer un projet et le configurer](creer-un-projet.md).

## Après l'exécution, la confrontation

L'écran de résultats reprend la même évaluation et la confronte à ce qui a
réellement été écrit. Il sépare trois constats, et cette séparation est le cœur
du sujet.

| Constat | Où chercher |
|---|---|
| **Produit** | rien à faire |
| **Demandé mais absent** | dans le modèle ou dans les données — pas dans vos réglages |
| **Écrit sans être au catalogue** | une sortie à recenser côté administration |
| **Non demandé** | dans vos réglages, avec le paramètre à activer |

Sans ce croisement, un fichier absent ne se distingue pas d'un fichier jamais
demandé — et l'on cherche dans le modèle une panne qui n'existe pas.

```bash
curl http://localhost:8000/api/v1/runs/<runId>/output-review
```

Le panneau reste **replié quand tout est conforme** : il n'y a alors rien à lire.

## Une bonne pratique de réglage

!!! tip "Demandez peu, puis étendez"
    Chaque sortie activée est du temps d'écriture pendant l'exécution et des
    fichiers à relire ensuite. Commencez par les deux ou trois sorties qui
    portent votre question, vérifiez qu'elles arrivent, puis élargissez. Un
    dossier de sortie qu'on n'ouvre jamais coûte autant qu'un qu'on lit.

## Où les fichiers atterrissent

Dans `gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log/<runId>/`, un
dossier par exécution. Le chemin est **déterministe** : la plateforme impose au
modèle l'identifiant de l'exécution, au lieu de devoir deviner un dossier
horodaté.

!!! warning "Rien n'est écrit avant la fin"
    Le modèle produit ses fichiers en fin de période simulée. Un dossier vide au
    milieu d'une exécution est normal ; une exécution arrêtée en route ne laisse
    donc **rien** — voir
    [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md).

!!! note "Voir aussi"
    - [Composer un scénario](composer-un-scenario.md) — où se posent les
      drapeaux.
    - [Lire et comparer les résultats](lire-les-resultats.md) — ce qu'on fait
      des fichiers une fois là.
    - [Administrer les catalogues](administrer-les-catalogues.md) — corriger ou
      recenser une sortie.
