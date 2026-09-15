# Administrer les catalogues

!!! abstract "En bref"
    Comment corriger une entrée, un paramètre ou une sortie mal décrits, et
    comment revenir en arrière. Pour l'administrateur de la plateforme — pas
    pour l'utilisateur d'un projet, dont rien ici ne relève.

## Ce que décrivent les trois catalogues

--8<-- "_partials/chiffres-modele.md:tout"

| Catalogue | Route | Ce qu'il décide |
|---|---|---|
| Entrées | `/admin/catalogue/entrees` | ce qu'un projet doit fournir, et comment chaque fichier est lu |
| Paramètres | `/admin/catalogue/parametres` | ce qu'un scénario peut régler, et comment |
| Sorties | `/admin/catalogue/sorties` | ce que le modèle peut écrire, et sous quelle condition |

--8<-- "_partials/deux-domaines.md:regle"

!!! danger "Modifier un catalogue engage toute la plateforme"
    Ces fiches ne décrivent pas une vue : elles décident de ce que la validation
    accepte, de ce qu'un lancement exige et de ce qu'un scénario peut envoyer à
    GAMA. Une entrée déclarée obligatoire à tort bloque le lancement de tous les
    projets concernés.

## Le jeu de référence et vos corrections

Les trois catalogues sont **engendrés depuis le GAML du modèle** et rechargés au
démarrage de l'API. Ce chargement est idempotent et non destructif.

Chaque fiche porte une origine :

| Origine | Ce qu'elle implique |
|---|---|
| `SEED` | fiche du jeu de référence ; le rechargement la remet à jour |
| `USER` | fiche modifiée à la main ; le rechargement **ne la touche plus** |

Toute écriture manuelle bascule la fiche en `USER`. C'est ce qui protège vos
corrections d'un redémarrage — et ce qui les empêche de bénéficier d'une
correction du générateur.

!!! tip "Rétablir la référence"
    Un bouton **Rétablir la référence** apparaît sur une fiche `USER`. Il
    restaure ce que dit le jeu de référence et **rend la fiche au `SEED`** : elle
    suivra de nouveau les montées de version. C'est le geste à préférer quand
    votre correction a été intégrée au générateur.

Une fiche de référence ne se supprime pas ; seule une fiche `USER` — donc créée
ou modifiée à la main — peut l'être.

## Corriger une entrée

`/admin/catalogue/entrees/<specId>`. Le formulaire couvre quatre sujets, dans
l'ordre où les questions se posent.

| Bloc | Ce qu'on y décide |
|---|---|
| Identité | libellé, module, nature du fichier |
| Emplacement | répertoire relatif au territoire, et **nom exact** ou **motif** pour une famille |
| Lecture | orientation, séparateur, en-tête, colonnes méta d'un fichier transposé |
| Applicabilité | condition d'obligation, dépendances vers d'autres fichiers |
| Champs | nom, type, unité, obligation, valeurs autorisées, référence à un autre fichier |

Deux points valent un avertissement.

!!! warning "Le nom de fichier est ce qui apparie un import"
    Un fichier importé est reconnu par son nom. Changer ce nom dans la fiche ne
    renomme rien : cela change ce que la plateforme cherchera à l'import
    suivant. Les versions déjà stockées ne bougent pas.

!!! warning "Laisser le nom vide fait une famille"
    Un type d'entrée sans nom exact mais avec un motif décrit une **famille** :
    une série climatique, un jeu de prix par scénario. Chaque fichier reçu
    devient alors une instance distincte. Le passage d'un fichier unique à une
    famille change la façon dont les données déjà chargées sont retrouvées.

## Corriger un paramètre

`/admin/catalogue/parametres/<nom>`. Ici, l'essentiel est ce qui **ne se modifie
pas**.

| Non modifiable | Pourquoi |
|---|---|
| Le nom | c'est celui que le launcher déclare, et celui qui voyage dans le chargement du modèle |
| La valeur déclarée par le launcher | c'est un fait du modèle, pas un réglage |
| Le caractère système | un paramètre imposé par la plateforme le reste ; ce n'est pas une décision d'administration |

Ce qui se modifie : le libellé et la section — comment le paramètre se présente
dans l'éditeur de scénario —, son type, sa valeur par défaut, ses valeurs
autorisées, la condition qui l'active, et le champ de données où lire ses
valeurs acceptables.

!!! info "Une variable absente du launcher n'existe pas"
    Le launcher fait autorité : une variable qu'il ne déclare pas ne peut pas
    être surchargée au chargement du modèle, donc ne peut pas faire partie d'un
    scénario. L'ajouter au catalogue ne la rendrait pas plus efficace — elle
    serait envoyée et ignorée.

Supprimer un paramètre ne le retire pas des scénarios qui le fixent : ils
gardent leur valeur, désormais sans effet.

## Corriger une sortie

`/admin/catalogue/sorties/<specId>`. Le formulaire porte l'identité, les
fichiers produits avec leur pas de temps, et la condition de production :
l'interrupteur qui la commande, et l'expression complète quand la condition est
composée.

!!! warning "La garde du modèle n'est pas modifiable"
    Le texte de la condition GAML est conservé tel quel à côté de sa traduction.
    C'est la pièce qui permet de vérifier la traduction ; la réécrire ferait
    disparaître la seule trace de l'écart. Si la traduction est fausse, corrigez
    la condition traduite — et la garde continuera de vous contredire tant que le
    désaccord dure.

Le catalogue signale enfin les sorties **hors de portée d'un scénario** : leur
interrupteur n'est pas déclaré par le launcher. Aucune correction de fiche ne les
rendra accessibles — c'est une modification du modèle.

## Valider avant d'ouvrir aux projets

`/admin/banc-essai` exécute un launcher sur GAMA headless, sans projet ni données
de projet, avec suivi en direct et inventaire des fichiers produits. C'est le
geste de vérification après une modification de catalogue qui touche à ce que le
modèle lit ou écrit.

```bash
curl -X POST http://localhost:8000/api/v1/admin/runs \
  -H "Content-Type: application/json" \
  -d '{"model_id": "launcherTest", "parameters": [{"type": "int", "name": "nbAnneesSimulation", "value": 1}]}'
```

!!! tip "Un catalogue juste ne se prouve que par une exécution"
    Une fiche peut être cohérente, bien typée, et fausse. La seule preuve qu'elle
    décrit le modèle est un run qui va au bout et produit ses fichiers. Voir
    [Lancer et suivre une exécution](lancer-et-suivre-une-execution.md).

## Les routes d'écriture

Les lectures sont ouvertes — le domaine Simulation en dépend. Les écritures sont
sous le préfixe d'administration :

| Catalogue | Écrire | Rétablir | Supprimer |
|---|---|---|---|
| Entrées | `PUT /api/v1/admin/dataspecs/{specId}` | `POST .../restore` | `DELETE .../{specId}` |
| Paramètres | `PUT /api/v1/admin/parameters/{nom}` | `POST .../restore` | `DELETE .../{nom}` |
| Sorties | `PUT /api/v1/admin/outputs/{specId}` | `POST .../restore` | `DELETE .../{specId}` |

La référence interactive complète est exposée par l'API sur
<http://localhost:8000/docs>.

!!! note "Voir aussi"
    - [Choisir ce que l'exécution va produire](choisir-les-sorties.md) — le
      catalogue des sorties vu depuis l'utilisateur.
    - [Composer un scénario](composer-un-scenario.md) — ce que le catalogue des
      paramètres rend possible.
    - [Dépannage](depannage.md) — quand un catalogue n'est pas chargé du tout.
