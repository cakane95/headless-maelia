# Écarts entre le code et la documentation source

!!! abstract "En bref"
    Recensement des divergences entre le GAML livré et la documentation fournie
    avec le modèle — organigrammes et schéma de données de l'INRAE. Chaque
    écart indique qui fait foi et ce qu'il faudrait corriger. À consulter avant
    de « corriger » un nom de fichier qui paraît fautif.

**Source** : confrontation de `gama-models/MAELIA_1.4.29_GAMA_2025-06/models/**/*.gaml` avec `docs/docs/assets/organigrammes/` et `docs/docs/assets/sources/maelia-schema-donnees.xlsx` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

--8<-- "_partials/avertissement-code-fait-autorite.md:autorite"

--8<-- "_partials/avertissement-code-fait-autorite.md:version"

## Les sources confrontées

| Source | Ce qu'on en tire | Fiabilité |
|---|---|---|
| Code GAML (`models/**/*.gaml`) | chemins lus, fichiers écrits, paramètres exposés | **autorité** |
| Organigrammes INRAE (`assets/organigrammes/`) | arborescence attendue des entrées | bonne, quelques coquilles |
| Schéma de données (`assets/sources/maelia-schema-donnees.xlsx`) | champs de chaque type de donnée | **faible**, voir plus bas |
| Jeux livrés (`includes/terrainTest`, `includes_sasseme`) | ce qui existe réellement sur le disque | factuelle |

## Organigrammes — coquilles à corriger dans la documentation

Les organigrammes sont globalement fidèles : la grande majorité des fichiers
représentés correspond exactement au code. Les écarts relevés sont tous du côté
de la documentation.

| Sur l'organigramme | Dans le code (fait foi) | Nature de l'écart |
|---|---|---|
| `coutourZH.shp` | `contourZH.shp` | coquille — un `n` manquant |
| `ilotsHZ.shp` | `ilots_HZ.shp` | tiret bas manquant |
| `parcellesHZ.shp` | `parcelles_HZ.shp` | tiret bas manquant |
| `tronconsParZH.shp` | *(inexistant)* | fichier représenté mais jamais lu ; seul `tronconsPrincipauxParZH.shp` l'est |

!!! info "Faux positifs écartés"
    `debitEntre.csv` et `debitEntreObs.csv` semblent absents du code : leurs
    lectures littérales sont **commentées** dans `zoneHydrographique.gaml`, mais
    le modèle les lit bien par composition
    (`pathToFichiersDebitEntre + nomFichierDebitEntre`). De même, l'entrée
    représentée comme « N x NomCanal.csv » correspond à une lecture par canal :
    `'/modeleHydrographique/canaux/' + listDonneesDetaillee at j`.

??? example "Organigramme INRAE d'ensemble"

    ![Organigramme INRAE d'ensemble : les quatre modules du modèle MAELIA et l'arborescence des données d'entrée qu'ils attendent](../assets/organigrammes/organigramme-general.png)

## Fichiers lus par le code, absents des organigrammes

Les organigrammes datent d'avant plusieurs modules. Ces entrées existent dans le
code, sont au catalogue, et n'apparaissent nulle part dans les schémas fournis.

| Domaine | Identifiants au catalogue |
|---|---|
| Élevage | `agri.agriculteurs.batiments`, `agri.agriculteurs.lotsAnimaux`, `agri.agriculteurs.contratsLivraison` |
| Exploitations | `agri.agriculteurs.exploitations`, `agri.agriculteurs.explSurf` |
| Fertilisation | `agri.Engrais.Engrais`, `agri.engrais.stocskEngraisParExploitation` |
| Cultures | `agri.culture.especesHerbSim`, `agri.culture.reglesDeDecisions_fertilisation`, `agri.culture.correspondance_especesMAELIA_especesIBIO` |
| Assolement | `agri.blocs`, `agri.blocsCorriges` |
| Hydrographie | `hydro.troncons.noeudsExutoireZH`, `hydro.mnt.majortribdskratie`, `hydro.mnt.BGA_PNG`, `hydro.hru.hru_0.25` |
| Processus | `hydro.clc.disparitionIlots` |

!!! warning "Trois entrées annoncées par la documentation antérieure n'existent pas au catalogue"
    `Engrais/digestat_liquide.csv`, `lacs/hydrographieSurfacique.shp` et les
    descriptions de cheptels bovin lait / viande étaient annoncées comme
    lues par le code dans
    [la documentation antérieure](../archive/donnees-et-parametres.md). Le
    catalogue engendré depuis le GAML ne les porte pas. Tant que l'extraction
    ne les retrouve pas, elles ne sont pas des entrées du modèle : c'est
    l'annonce qui était fautive, pas le catalogue.

## Coquilles du code à conserver telles quelles

Ces noms sont fautifs en français mais ce sont les noms **réels** attendus par le
modèle. Les « corriger » ferait échouer la lecture.

| Nom réel | Ce qu'on serait tenté d'écrire | Où |
|---|---|---|
| `stocskEngraisParExploitation.csv` | *stocks*EngraisParExploitation.csv | `modeleAgricole/engrais/` |
| `profilesAgriculteurs.csv` | *profils*Agriculteurs.csv | `modeleAgricole/agriculteurs/` |
| `corresponsanceIlotZoneMeteo.csv` | *correspondance*IlotZoneMeteo.csv | sortie du modèle commun |
| `DebistSTH` | *Debits*STH | drapeau de sortie |
| `N_total_eqC02_typeExploitation` | eq*CO2* | drapeau de sortie |
| `RUEdesSOLs` / `RUEdesSOLS.csv` | casse homogène | drapeau et nom de fichier divergent entre eux |

!!! danger "Ne jamais normaliser un identifiant du modèle"
    Un nom de fichier, de paramètre ou de colonne n'est pas une chaîne de texte
    à embellir : c'est une clé. Le catalogue les reprend tels quels, avec leurs
    fautes, et le code de la plateforme n'en écrit aucun en dur.

## Schéma de données Excel — inutilisable comme référence de nommage

Le classeur `MAELIA_Schema_Donnees.xlsx` ne peut pas servir de référence pour
nommer les champs. Il a été produit par extraction du site du modèle, et
l'extraction a partiellement échoué.

[Télécharger le schéma de données INRAE (`.xlsx`)](../assets/sources/maelia-schema-donnees.xlsx)

| Constat | Détail |
|---|---|
| Erreurs de collecte | des cellules contiennent `HTTPConnectionPool(host='maelia-platform.inra.fr'…): Read timed out` — les requêtes d'extraction ont échoué et le message a été enregistré à la place du contenu |
| Champs décrits positionnellement | des feuilles ne donnent que `Colonne 0`, `Colonne 1`, `Colonne 2 à N` : aucun nom à comparer |
| Feuille vide | `Feuil1` |
| Feuilles sans correspondance | décrivent des types de données qui n'existent pas dans les jeux livrés |
| Feuilles appariables | une minorité, dont très peu à recouvrement complet |

Sur les feuilles exploitables, les divergences relevées :

| Feuille | Écart avec les données réelles |
|---|---|
| `donnees-ilot` | la documentation nomme `PAE_ID_EXP` ce que les données appellent `ID_EXPL` ; plusieurs champs réels ne sont pas documentés (`AREA_HA`, `PENTE_MOY`, `PRAIRIE`, `EQU_0..3`…) |
| `donnees-sol` | la documentation décrit dix horizons (`ARG1` à `ARG10`) ; les données livrées en comptent quatre (`ARG1` à `ARG4`) |
| `donnees-parcelle` | recouvrement complet des champs documentés, mais plusieurs champs réels non documentés (`ID_ILOT`, `ID_EXPL`, `EXPREST`…) |

**Conséquence retenue.** Le catalogue d'entrées est construit à partir du code et
des **en-têtes réels** des fichiers livrés. Le classeur ne sert que de source
d'aide à la description : libellés lisibles, unités. C'est pourquoi la section
« Champs relevés » de [Les fichiers d'entrée](fichiers-entree.md) porte les noms
des jeux livrés et non ceux du tableur.

## Accents mal décodés dans les descriptions de sorties

Certaines descriptions du catalogue de sorties portent des accents mal décodés
(`Ã©` pour `é`, `â‚¬` pour `€`, `â€¦` pour `…`). Le défaut vient des commentaires
du GAML, écrits en Latin-1 et relus en UTF-8 lors de l'extraction.

| Où | Effet |
|---|---|
| `outputs.json`, champ `description` | quelques descriptions portent des séquences illisibles |
| API `/api/v1/outputs` | les renvoie telles quelles |
| [Les sorties du modèle](sorties.md) | les reproduit telles quelles, pour rester fidèle à ce que renvoie l'API |

Corriger ce défaut suppose de reprendre l'encodage à l'extraction du GAML, donc
de régénérer le catalogue — pas de retoucher la documentation, qui ne ferait
alors plus correspondre au contenu réel du catalogue.

## Écarts internes au modèle, à ne pas corriger non plus

Ces incohérences sont dans le GAML lui-même. Elles n'appellent pas de correction
de la documentation : elles appellent de la prudence.

| Constat | Conséquence |
|---|---|
| Certains drapeaux de `output/selectionOutput.gaml` ne sont pas déclarés par `launcherBase.gaml` | la sortie qu'ils commandent est inatteignable depuis un scénario — voir [Les sorties du modèle](sorties.md) |
| Certaines gardes contiennent un terme inexprimable dans le langage de conditions | la sortie est annoncée *possible*, jamais certaine (`exact: false`) ; `guard_source` conserve le texte d'origine |
| `contratsLivraison.csv` est déclaré mais jamais repris | code mort : la variable existe, aucune lecture ne s'ensuit |
| `nbAgentsPerDay.csv` a une variable de chemin, mais son `save` est commenté dans `main.gaml` | le fichier n'est jamais écrit ; il ne figure pas au catalogue |
| `do pause` précède `simulationTerminee` | l'événement `SimulationEnded` peut ne pas être émis — la plateforme surveille aussi un marqueur console |
| Une initialisation ratée n'émet aucun événement | sans le marqueur console `ERREUR LORS DE L'INITIALISATION`, un run resterait en cours sans fin |

## Comment un écart se règle

| Situation | Qui corrige |
|---|---|
| La documentation INRAE diverge du GAML | la documentation INRAE — le catalogue suit le code |
| Le catalogue diverge du GAML | le générateur de catalogue, puis régénération des seeds |
| Cette documentation diverge du catalogue | cette documentation |
| Le GAML est fautif | rien ici : c'est une remontée à l'équipe du modèle |

!!! note "Voir aussi"

    - [Les fichiers d'entrée](fichiers-entree.md) — l'inventaire que ces écarts qualifient
    - [Les sorties du modèle](sorties.md) — gardes inexactes et drapeaux hors de portée
    - [Les chiffres du modèle](chiffres.md) — ce que la version antérieure annonçait
    - [Documentation antérieure](../archive/donnees-et-parametres.md)
