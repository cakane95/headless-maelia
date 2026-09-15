# Les sorties du modèle

!!! abstract "En bref"
    Ce que MAELIA peut écrire, et sous quelle condition. Pour chaque sortie :
    le drapeau qui la commande, sa valeur par défaut, les fichiers produits,
    leur pas de temps et la garde complète traduite depuis le GAML. À
    consulter pour savoir pourquoi un fichier est là — ou pourquoi il manque.

**Source** : extraction de `headless-maelia-server/app/contexts/catalog/infrastructure/seed/outputs.json` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

--8<-- "_partials/chiffres-modele.md:sorties"

## De quoi dépend un fichier de sortie

Le modèle n'écrit rien par défaut. Chaque famille de résultats est commandée
par un drapeau booléen, lui-même imbriqué dans les gardes des modules dont
elle dépend : la condition réelle est la conjonction de toute la pile.

```mermaid
flowchart LR
    P["Paramètre<br/><small>Assolement_SDC = true</small>"]
    G["Garde<br/><small>executerModeleAgricole == true<br/>&& Assolement_SDC == true</small>"]
    M["Module d'écriture<br/><small>output/resultatsAssolement_SDC.gaml</small>"]
    F["Fichier<br/><small>assolement_SDC.csv<br/>granularité YEAR_END</small>"]
    C["Colonnes<br/><small>profilées à l'ingestion,<br/>puis lisibles en graphique</small>"]
    P -->|surcharge le drapeau| G
    G -->|autorise| M
    M -->|écrit| F
    F -->|expose| C
```

Les fichiers sont écrits sous `<cheminSorties>/<idSimulationAPI>/` quand la
plateforme pilote le run : le dossier est alors déterministe. Le suffixe
`nomDeLaSimulation` étant vide par défaut, les noms des tableaux ci-dessous
sont les noms réels.

## Comment lire les tableaux

| Colonne | Contenu |
|---|---|
| **Sortie** | identifiant au catalogue (`OutputSpec.id`) |
| **Drapeau** | variable de `output/selectionOutput.gaml` qui commande la sortie ; vide = écrite hors aiguillage |
| **Défaut** | valeur du drapeau sans surcharge |
| **Fichier(s)** | noms littéraux écrits par le module |
| **Pas de temps** | granularité déclarée par la variable de chemin du module |
| **Produite si** | garde complète traduite ; `~` signale une traduction incomplète |

Le symbole `~` devant une garde signale `exact: false` : la traduction a dû
abandonner un terme inexprimable dans le langage de conditions. La sortie est
alors annoncée **possible**, jamais certaine. Le texte GAML d'origine est
conservé et reproduit plus bas.

Les granularités possibles :

| Valeur | Pas d'écriture |
|---|---|
| `DAILY` | un enregistrement par jour simulé |
| `YEAR_START` | en début d'année simulée |
| `YEAR_END` | en fin d'année simulée |
| `MONTHLY` | mensuel |
| `FORTNIGHTLY` | bimensuel — par quinzaine |
| `UNKNOWN` | le module ne déclare pas de pas de temps |

## Thème ASSOLEMENT

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `Assolement_espece` | `Assolement_espece` | faux | `assolement_espece.csv` | `YEAR_END` | `executerModeleAgricole == true && Assolement_espece == true` |
| `Assolement_itk` | `Assolement_itk` | faux | `assolement_itk.csv` | `YEAR_END` | `executerModeleAgricole == true && Assolement_itk == true` |
| `Assolement_parcelle` | `Assolement_parcelle` | faux | `assolementParcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && Assolement_parcelle == true` |
| `Assolement_SDC` | `Assolement_SDC` | faux | `assolement_SDC.csv` | `YEAR_END` | `executerModeleAgricole == true && Assolement_SDC == true` |
| `FractionSolNu` | `FractionSolNu` | faux | `fractionSolNuJournalier.csv`<br>`fractionSolNuAnnuel.csv`<br>`solNuIlots.csv` | `DAILY`<br>`YEAR_END`<br>`UNKNOWN` | `executerModeleAgricole == true && FractionSolNu == true` |
| `recolteParcelles` | `recolteParcelles` | faux | `resultatsRecolteParcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && recolteParcelles == true` |

## Thème AqYield

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `aqYield_eva_trmax_trr_ITK_ZH` | `aqYield_eva_trmax_trr_ITK_ZH` | faux | `aqYield_eva_trmax_trr_ITK_ZH.csv` | `DAILY` | `executerModeleAgricole == true && aqYield_eva_trmax_trr_ITK_ZH == true` |
| `debugSortie1parcelleAqYield` | `debugSortie1parcelleAqYield` | faux | `modeleAqYield_Journalier.csv` | `DAILY` | `executerModeleAgricole == true && debugSortie1parcelleAqYield == true` |
| `debugSortie1parcelleAqYield_N` | `debugSortie1parcelleAqYield_N` | faux | `modeleAqYield_Journalier.csv` | `DAILY` | `executerModeleAgricole == true && debugSortie1parcelleAqYield_N == true` |
| `engrais_utilises_exploitation` | `engrais_utilises_exploitation` | faux | `resultats_N_engrais_utilises_exploitation.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && engrais_utilises_exploitation == true` |
| `engrais_utilises_territoire` | `engrais_utilises_territoire` | faux | `resultats_N_engrais_utilises_territoire.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && engrais_utilises_territoire == true` |
| `eqCO2_emissions_NC_Parcelles` | `eqCO2_emissions_NC_Parcelles` | faux | `resultats_N_eqCO2_emissions_NC_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && eqCO2_emissions_NC_Parcelles == true` |
| `eqCO2_Nmineral_synthesis_Parcelles` | `eqCO2_Nmineral_synthesis_Parcelles` | faux | `resultats_N_eqCO2_Nmineral_synthesis_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && eqCO2_Nmineral_synthesis_Parcelles == true` |
| `eqCO2_synthesis_Parcelles` | `eqCO2_synthesis_Parcelles` | faux | `resultats_N_eqCO2_synthesis_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && eqCO2_synthesis_Parcelles == true` |
| `inputs_sols` | `inputs_sols` | faux | `inputs_sol_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && inputs_sols == true` |
| `lien_ilots_zoneMeteo` | `lien_ilots_zoneMeteo` | vrai | `id_ilot_zoneMeteo.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && lien_ilots_zoneMeteo == true` |
| `N_Cstock_Parcelles` | `N_Cstock_Parcelles` | faux | `resultats_N_Cstock_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_Cstock_Parcelles == true` |
| `N_exportation_pailles_Parcelles` | `N_exportation_pailles_Parcelles` | faux | `resultats_N_exportation_pailles_Parcelles.csv` | `DAILY` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_exportation_pailles_Parcelles == true` |
| `N_GES_Parcelles` | `N_GES_Parcelles` | faux | `resultats_N_GES_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_GES_Parcelles == true` |
| `N_lixi_Parcelles` | `N_lixi_Parcelles` | faux | `resultats_N_lixi_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_lixi_Parcelles == true` |
| `N_lixi_typeExploitation` | `N_lixi_typeExploitation` | faux | `N_lixi_typeExploitation.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_lixi_typeExploitation == true` |
| `N_N2O_Parcelles` | `N_N2O_Parcelles` | faux | `resultats_N_N2O_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_N2O_Parcelles == true` |
| `N_NH3_Parcelles` | `N_NH3_Parcelles` | faux | `resultats_N_NH3_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_NH3_Parcelles == true` |
| `N_Nmin_som_res_Parcelles` | `N_Nmin_som_res_Parcelles` | faux | `resultats_N_Nmin_som_res_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_Nmin_som_res_Parcelles == true` |
| `N_Nmin_total_Parcelles` | `N_Nmin_total_Parcelles` | faux | `resultats_N_Nmin_total_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_Nmin_total_Parcelles == true` |
| `N_QNfix_Parcelles` | `N_QNfix_Parcelles` | faux | `resultats_N_QNfix_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_QNfix_Parcelles == true` |
| `N_SOC_Parcelles` | `N_SOC_Parcelles` | faux | `resultats_N_SOC_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_SOC_Parcelles == true` |
| `N_total_eqC02_typeExploitation` | `N_total_eqC02_typeExploitation` | faux | `N_total_eqC02_typeExploitation.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_total_eqC02_typeExploitation == true` |
| `N_varArbreRegression_nApportProduits_Parcelles` | `N_varArbreRegression_nApportProduits_Parcelles` | faux | `resultats_N_nApportProduits_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_varArbreRegression_nApportProduits_Parcelles == true` |
| `N_varArbreRegression_nSemisCultures_Parcelles` | `N_varArbreRegression_nSemisCultures_Parcelles` | faux | `resultats_N_nSemisCultures_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_varArbreRegression_nSemisCultures_Parcelles == true` |
| `N_varArbreRegression_quantitesProduits_Parcelles` | `N_varArbreRegression_quantitesProduits_Parcelles` | faux | `resultats_N_quantitesProduits_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && N_varArbreRegression_quantitesProduits_Parcelles == true` |
| `prixFerti_Parcelles` | `prixFerti_Parcelles` | faux | `resultats_prixFerti_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && prixFerti_Parcelles == true` |
| `RUEdesSOLs` | `RUEdesSOLs` | faux | `RUEdesSOLS.csv` | `YEAR_END` | `executerModeleAgricole == true && RUEdesSOLs == true` |
| `suiviOTParParcelle_humidite` | `suiviOTParParcelle_humidite` | faux | `suiviOTParParcelle_humidite.csv` | `DAILY` | `executerModeleAgricole == true && suiviOTParParcelle_humidite == true` |
| `tpsWFerti_Parcelles` | `tpsWFerti_Parcelles` | faux | `resultats_tpsWFerti_Parcelles.csv` | `YEAR_END` | `executerModeleAgricole == true && sortiesAqYieldNC == true && tpsWFerti_Parcelles == true` |
| `variablesAqYieldSurParcellesSpecifiees` | `variablesAqYieldSurParcellesSpecifiees` | faux | `modeleAqYield_Journalier.csv`<br>`modeleAqYield_Annuel.csv` | `DAILY`<br>`YEAR_END` | `executerModeleAgricole == true && variablesAqYieldSurParcellesSpecifiees == true` |
| `variablesAqYieldSurParcellesSpecifiees_light` | `variablesAqYieldSurParcellesSpecifiees_light` | faux | `modeleAqYield_light_journalier.csv` | `DAILY` | `executerModeleAgricole == true && variablesAqYieldSurParcellesSpecifiees_light == true` |

## Thème BILAN HYDRIQUE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `debitBVe` | `debitBVe` | faux | `debitBVe.csv` | `DAILY` | `executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT' && debitBVe == true` |
| `DrainIlot` | `DrainIlot` | faux | `DrainIlot.csv` | `DAILY` | `executerModeleAgricole == true && DrainIlot == true` |
| `DrainIlot_ITK_ZH` | `DrainIlot_ITK_ZH` | faux | `DrainIlot_ITK_ZH.csv` | `DAILY` | `executerModeleAgricole == true && DrainIlot_ITK_ZH == true` |
| `DrainIlot_mois` | `DrainIlot_mois` | faux | `DrainIlotMensuel.csv` | `MONTHLY` | `executerModeleAgricole == true && DrainIlot_mois == true` |
| `DrainIlot_quinzaine` | `DrainIlot_quinzaine` | faux | `DrainIlotBimensuel.csv` | `FORTNIGHTLY` | `executerModeleAgricole == true && DrainIlot_quinzaine == true` |
| `DrainIlotDetail` | `DrainIlotDetail` | faux | `DrainIlotDetail.csv` | `DAILY` | `executerModeleAgricole == true && DrainIlotDetail == true` |
| `DrainIlotDetail_mois` | `DrainIlotDetail_mois` | faux | `DrainIlotDetailMensuel.csv` | `MONTHLY` | `executerModeleAgricole == true && DrainIlotDetail_mois == true` |
| `DrainIlotDetail_quinzaine` | `DrainIlotDetail_quinzaine` | faux | `DrainIlotDetailBimensuel.csv` | `FORTNIGHTLY` | `executerModeleAgricole == true && DrainIlotDetail_quinzaine == true` |
| `FluxSWAT_BVe` | `FluxSWAT_BVe` | faux | `resAS.csv`<br>`resAS_m3.csv` | `DAILY` | `executerModeleHydrographique == true && FluxSWAT_BVe == true` |
| `hauteurNappes` | `hauteurNappes` | faux | `hauteurDeNappe.csv` | `DAILY` | `executerModeleHydrographique == true && hauteurNappes == true` |
| `RechargeRetenues` | `RechargeRetenues` | faux | `recharge_retenues.csv` | `YEAR_END` | `executerModeleHydrographique == true && RechargeRetenues == true` |
| `RetenuesVolumeActuelJour` | `RetenuesVolumeActuelJour` | faux | `prelevementsReelsRetenues.csv`<br>`volumeActuelRetenues.csv` | `DAILY` | `executerModeleHydrographique == true && RetenuesVolumeActuelJour == true` |
| `SWAT_PhaseRoutage` | `SWAT_PhaseRoutage` | faux | `validationSWAT_PhaseRoutage_ZH.csv` | `DAILY` | `executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT' && SWAT_PhaseRoutage == true` |

## Thème BILAN NC

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `suivi_ajout_pools_residus` | `suivi_ajout_pools_residus` | faux | `suivi_ajout_pools_residus.csv` | `YEAR_END` | `nomChoixModeleCroissancePlante == 'AqYieldNC' && suivi_ajout_pools_residus == true \|\| nomChoixModeleCroissancePlante == 'HerbSimNC' && suivi_ajout_pools_residus == true` |

## Thème BIODIVERSITE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `sorties_iBio` | `sorties_iBio` | faux | `resultats_iBIO.csv` | `YEAR_END` | `sorties_iBio == true` |

## Thème CALIBRATION

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `sortieCalibration` | `sortieCalibration` | faux | `debit_.csv` | `DAILY` | `executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT' && sortieCalibration == true` |

## Thème CLIMAT

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `GetClimatParZH` | `GetClimatParZH` | faux | `climatParZH.csv` | `DAILY` | `executerModeleHydrographique == true && GetClimatParZH == true` |

## Thème DIVERS

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `demoChambreAlsace` | `demoChambreAlsace` | faux | `demoChambreAlsace.csv`<br>`demoChambreAlsace_rdt.csv` | `DAILY`<br>`YEAR_END` | `demoChambreAlsace == true` |
| `sorties_azote` | `sorties_azote` | faux | `sorties_CN.csv` | `YEAR_END` | `nomChoixModeleCroissancePlante == 'AqYieldNC' && sorties_azote == true` |
| `sorties_barrages` | `sorties_barrages` | faux | `sorties_barrages.csv` | `DAILY` | `sorties_barrages == true && executerModeleNormatif == true` |
| `sorties_carboneGES` | `sorties_carboneGES` | faux | `sorties_GES.csv` | `YEAR_END` | `nomChoixModeleCroissancePlante == 'AqYieldNC' && sorties_carboneGES == true` |
| `sorties_eau` | `sorties_eau` | vrai | `sorties_eau.csv` | `YEAR_END` | `sorties_eau == true && nomChoixModeleCroissancePlante == 'AqYield' \|\| sorties_eau == true && nomChoixModeleCroissancePlante == 'AqYieldNC'` |
| `sorties_retenues` | `sorties_retenues` | faux | `sorties_retenues.csv` | `DAILY` | `sorties_retenues == true && executerModeleHydrographique == true` |

## Thème ECONOMIE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `BilanExploitation` | `BilanExploitation` | faux | `bilanExploitation.csv` | `YEAR_END` | `executerModeleAgricole == true && BilanExploitation == true` |
| `ECO_coutIrrigationIlot` | `ECO_coutIrrigationIlot` | faux | `eco_coutIrrigationIlot.csv` | `YEAR_END` | `executerModeleAgricole == true && ECO_coutIrrigationIlot == true` |
| `ECO_espece` | `ECO_espece` | faux | `eco_espece.csv` | `YEAR_END` | `executerModeleAgricole == true && ECO_espece == true` |
| `ECO_exploitationDetail` | `ECO_exploitationDetail` | faux | `eco_exploitationDetail.csv` | `YEAR_END` | `executerModeleAgricole == true && ECO_exploitationDetail == true` |
| `ECO_exploitationType` | `ECO_exploitationType` | faux | `eco_exploitationType.csv` | `YEAR_END` | `executerModeleAgricole == true && ECO_exploitationType == true` |
| `ECO_itk` | `ECO_itk` | faux | `eco_itk.csv` | `YEAR_END` | `executerModeleAgricole == true && ECO_itk == true` |
| `ECO_SDCRef` | `ECO_SDCRef` | faux | `eco_SDC.csv` | `YEAR_END` | `executerModeleAgricole == true && nomChoixAssolement == 'Donnees' && ECO_SDCRef == true \|\| executerModeleAgricole == true && ECO_SDCRef == true` |
| `RDT_espece` | `RDT_espece` | faux | `rendements_espece.csv` | `YEAR_END` | `executerModeleAgricole == true && RDT_espece == true` |
| `RDT_exploitation_espece` | `RDT_exploitation_espece` | faux | `rendements_exploitation_espece.csv` | `YEAR_END` | `executerModeleAgricole == true && RDT_exploitation_espece == true` |
| `RDT_itk` | `RDT_itk` | faux | `rendements_itk.csv` | `YEAR_END` | `executerModeleAgricole == true && RDT_itk == true` |
| `RDT_parcelle_espece` | `RDT_parcelle_espece` | faux | `rendements_parcelle_espece.csv` | `YEAR_END` | `executerModeleAgricole == true && RDT_parcelle_espece == true` |
| `RDT_sol_itk` | `RDT_sol_itk` | faux | `rendements_sol_itk.csv` | `YEAR_END` | `executerModeleAgricole == true && RDT_sol_itk == true` |
| `suiviMemoireAgri` | `suiviMemoireAgri` | faux | `suiviMemoireAgri.csv` | `YEAR_END` | `executerModeleAgricole == true && suiviMemoireAgri == true` |

## Thème GESTION BARRAGE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `GestionnaireDeBarrage` | `GestionnaireDeBarrage` | faux | `Barrage_Journalier.csv`<br>`Barrage_Annuel.csv` | `DAILY`<br>`YEAR_END` | `executerBarrage == true && executerModeleNormatif == true && GestionnaireDeBarrage == true` |

## Thème HORS AIGUILLAGE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `corresponsanceIlotZoneMeteo` | — | vrai | `corresponsanceIlotZoneMeteo.csv` | `UNKNOWN` | *écrite à chaque exécution* |
| `debugBilanRoutage` | — | vrai | `debugBilanRoutage.csv` | `UNKNOWN` | `executerModeleHydrographique == true` |
| `debugBilanSol` | — | vrai | `debugBilanSol.csv` | `UNKNOWN` | `executerModeleHydrographique == true` |
| `debugCouchesSolParHRU` | — | vrai | `debugCouchesSolParHRU.csv` | `UNKNOWN` | ~ `executerModeleHydrographique == true` |
| `debugParHRU` | — | vrai | `debugParHRU.csv` | `UNKNOWN` | ~ `executerModeleHydrographique == true` |
| `debugParHRU_ZH192` | — | vrai | `debugParHRU_ZH192.csv` | `UNKNOWN` | ~ `executerModeleHydrographique == true` |
| `missingITK` | — | vrai | `missingITK.csv` | `UNKNOWN` | ~ `remplacerItkManquants == true && executerModeleAgricole == true` |
| `simulationDuration` | — | vrai | `simulationDuration.txt` | `UNKNOWN` | *écrite à chaque exécution* |
| `simulationParameters` | — | vrai | `simulationParameters.txt` | `UNKNOWN` | *écrite à chaque exécution* |
| `surfaceParcelles` | — | vrai | `surfaceParcelles.csv` | `UNKNOWN` | `executerModeleAgricole == true` |

## Thème HYDROLOGIE

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `DebistSTH` | `DebistSTH` | faux | `DebistSTH.csv` | `DAILY` | `executerModeleHydrographique == true && DebistSTH == true` |
| `Debit` | `Debit` | faux | `debit.csv` | `DAILY` | `executerModeleHydrographique == true && Debit == true` |

## Thème HerbSimNC

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `suivi_journalier_1parc_HerbSimNC` | `suivi_journalier_1parc_HerbSimNC` | faux | `validationHerbSimNC.csv` | `DAILY` | `executerModeleAgricole == true && suivi_journalier_1parc_HerbSimNC == true` |

## Thème ITK

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `suiviOT` | `suiviOT` | vrai | `suiviITK_.csv` | `YEAR_END` | `executerModeleAgricole == true && suiviOT == true` |
| `suiviOTParParcelle` | `suiviOTParParcelle` | vrai | `suiviOTParParcelle.csv` | `YEAR_END` | `executerModeleAgricole == true && suiviOTParParcelle == true` |
| `suiviOTParParcelleTemps` | `suiviOTParParcelleTemps` | faux | `suiviOTParParcelleTemps.csv` | `DAILY` | `executerModeleAgricole == true && suiviOTParParcelleTemps == true` |
| `suiviSemisRecolteParParcelle` | `suiviSemisRecolteParParcelle` | faux | `suiviSemisRecolteParParcelle.csv` | `YEAR_END` | `executerModeleAgricole == true && suiviSemisRecolteParParcelle == true` |

## Thème NORMATIF

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `Restrictions` | `Restrictions` | faux | `Restrictions_Annuel.csv`<br>`Restrictions_Journalier.csv` | `YEAR_END`<br>`DAILY` | `executerModeleHydrographique == true && executerModeleNormatif == true && Restrictions == true` |
| `UtilisationQuota` | `UtilisationQuota` | faux | `utilisationQuota_.csv`<br>`utilisationQuotaParAgri.csv` | `YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && executerModeleNormatif == true && UtilisationQuota == true && isEauDisponibleAgriInfinie != true` |

## Thème PRELEVEMENT

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `DetailsGroupeIrrigation` | `DetailsGroupeIrrigation` | faux | `groupesIrrigation.csv` | `YEAR_START` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && DetailsGroupeIrrigation == true` |
| `irrigationDebug` | `irrigationDebug` | faux | `irrigation_groupes.csv` | `YEAR_START` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && irrigationDebug == true` |
| `IrrigationParAgri` | `IrrigationParAgri` | faux | `IrrParAgri.csv` | `DAILY` | `IrrigationParAgri == true` |
| `IrrigationParcelle` | `IrrigationParcelle` | faux | `irrigation_parcelle.csv` | `DAILY` | `executerModeleAgricole == true && IrrigationParcelle == true` |
| `prelevementParPPA` | `prelevementParPPA` | faux | `prelevements_Journalier_IRR_AS.csv` | `DAILY` | `prelevementParPPA == true` |

## Thème PRELEVEMENTS

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `Canaux` | `Canaux` | faux | `Canaux_Journalier.csv`<br>`Canaux_Annuel.csv` | `DAILY`<br>`YEAR_END` | ~ `executerModeleHydrographique == true && isPrelevementEtRejetSimules == true && isCanaux == true && Canaux == true` |
| `Prelevements` | `Prelevements` | faux | `prelevements_Journalier_IRR.csv`<br>`prelevements_Annuel_IRR.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements == true` |
| `Prelevements_decoupage_itk` | `Prelevements_decoupage_itk` | faux | `resultatsPrelevementsJournalier_decoupage_itk.csv`<br>`resultatsPrelevements_decoupage_itk.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_decoupage_itk == true` |
| `Prelevements_decoupage_typePPA` | `Prelevements_decoupage_typePPA` | faux | `resultatsPrelevementsJournalier_decoupage_PPA.csv`<br>`resultatsPrelevements_decoupage_PPA.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_decoupage_typePPA == true` |
| `Prelevements_espece` | `Prelevements_espece` | faux | `resultatsPrelevementsJournalier_espece.csv`<br>`resultatsPrelevements_espece.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_espece == true` |
| `Prelevements_sol_espece` | `Prelevements_sol_espece` | faux | `resultatsPrelevementsJournalier_sol_espece.csv`<br>`resultatsPrelevements_sol_espece.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_sol_espece == true` |
| `Prelevements_sol_itk` | `Prelevements_sol_itk` | faux | `resultatsPrelevementsJournalier_sol_itk.csv`<br>`resultatsPrelevements_sol_itk.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_sol_itk == true` |
| `Prelevements_za_espece` | `Prelevements_za_espece` | faux | `resultatsPrelevementsJournalier_za_espece.csv`<br>`resultatsPrelevements_za_espece.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_za_espece == true` |
| `Prelevements_za_sol_espece` | `Prelevements_za_sol_espece` | faux | `resultatsPrelevementsJournalier_za_sol_espece.csv`<br>`resultatsPrelevements_za_sol_espece.csv` | `DAILY`<br>`YEAR_END` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && Prelevements_za_sol_espece == true` |
| `PrelevementsZA` | `PrelevementsZA` | faux | `ZA_resultatsPrelevements.csv`<br>`ZA_resultatsPrelevementsJournalier.csv` | `YEAR_END`<br>`DAILY` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && PrelevementsZA == true` |
| `PrelevementsZH` | `PrelevementsZH` | faux | `ZH_resultatsPrelevements_.csv`<br>`ZH_resultatsPrelevementsJournalier_.csv` | `YEAR_END`<br>`DAILY` | `isPrelevementEtRejetSimules == true && executerModeleAgricole == true && PrelevementsZH == true` |

## Thème TRAVAIL

| Sortie | Drapeau | Défaut | Fichier(s) | Pas de temps | Produite si |
|---|---|---|---|---|---|
| `travailParAgri` | `travailParAgri` | faux | `Travail_Annuel.csv`<br>`Agri_heuresEffectueesActivite.csv` | `YEAR_END`<br>`DAILY` | `travailParAgri == true` |
| `travailParAgri_Binage` | `travailParAgri_Binage` | faux | `Agri_heuresBinage.csv` | `DAILY` | `travailParAgri_Binage == true` |
| `travailParAgri_Ferti` | `travailParAgri_Ferti` | faux | `Agri_heuresFerti.csv` | `DAILY` | `travailParAgri_Ferti == true` |
| `travailParAgri_Irrigation` | `travailParAgri_Irrigation` | faux | `Agri_heuresIrrigation.csv` | `DAILY` | `travailParAgri_Irrigation == true` |
| `travailParAgri_Labour` | `travailParAgri_Labour` | faux | `Agri_heuresLabour.csv` | `DAILY` | `travailParAgri_Labour == true` |
| `travailParAgri_Phyto` | `travailParAgri_Phyto` | faux | `Agri_heuresPhyto.csv` | `DAILY` | `travailParAgri_Phyto == true` |
| `travailParAgri_Recolte` | `travailParAgri_Recolte` | faux | `Agri_heuresRecolte.csv` | `DAILY` | `travailParAgri_Recolte == true` |
| `travailParAgri_RepriseLabour` | `travailParAgri_RepriseLabour` | faux | `Agri_heuresRepriseLabour.csv` | `DAILY` | `travailParAgri_RepriseLabour == true` |
| `travailParAgri_Semis` | `travailParAgri_Semis` | faux | `Agri_heuresSemis.csv` | `DAILY` | `travailParAgri_Semis == true` |
| `travailParEspece` | `travailParEspece` | faux | `travail_espece.csv` | `YEAR_END` | `travailParEspece == true` |
| `travailParITK` | `travailParITK` | faux | `travail_itk.csv` | `YEAR_END` | `travailParITK == true` |
| `travailParTypeExploitation` | `travailParTypeExploitation` | faux | `Travail_TypeExploit_Annuel.csv`<br>`Agri_heuresEffectueesParTypeExploit.csv` | `YEAR_END`<br>`DAILY` | `travailParTypeExploitation == true` |

## Module d'écriture de chaque sortie

Le fichier GAML qui compose le nom et écrit les lignes. C'est là qu'il faut
aller pour savoir ce que contient une colonne.

| Sortie | Module GAML |
|---|---|
| `aqYield_eva_trmax_trr_ITK_ZH` | `output/resultatsModeleAqYield_ITK_ZH.gaml` |
| `Assolement_espece` | `output/resultatsAssolement_espece.gaml` |
| `Assolement_itk` | `output/resultatsAssolement_itk.gaml` |
| `Assolement_parcelle` | `output/resultatsAssolementParcelles.gaml` |
| `Assolement_SDC` | `output/resultatsAssolement_SDC.gaml` |
| `BilanExploitation` | `output/resultatsBilanExploitation.gaml` |
| `Canaux` | `output/resultatsCanaux.gaml` |
| `corresponsanceIlotZoneMeteo` | `modeleCommun/zoneMeteoMoyenne.gaml` |
| `DebistSTH` | `output/resultatsDebistSTH.gaml` |
| `Debit` | `output/resultatsAS_debit.gaml` |
| `debitBVe` | `output/resultatsDebitBVe.gaml` |
| `debugBilanRoutage` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` |
| `debugBilanSol` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` |
| `debugCouchesSolParHRU` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` |
| `debugParHRU` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` |
| `debugParHRU_ZH192` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` |
| `debugSortie1parcelleAqYield` | `output/resultatsAveyronUneParcelle_AqYield.gaml` |
| `debugSortie1parcelleAqYield_N` | `output/resultatsAveyronUneParcelle_AqYield_N.gaml` |
| `demoChambreAlsace` | `output/resultatsDemoChambreAlsace.gaml` |
| `DetailsGroupeIrrigation` | `output/resultatsDetailsGroupeIrrigation.gaml` |
| `DrainIlot` | `output/resultatsDrainIlot.gaml` |
| `DrainIlot_ITK_ZH` | `output/resultatsDrainIlot_ITK_ZH.gaml` |
| `DrainIlot_mois` | `output/resultatsDrainIlotMensuel.gaml` |
| `DrainIlot_quinzaine` | `output/resultatsDrainIlotBimensuel.gaml` |
| `DrainIlotDetail` | `output/resultatsDrainIlotDetail.gaml` |
| `DrainIlotDetail_mois` | `output/resultatsDrainIlotDetailMensuel.gaml` |
| `DrainIlotDetail_quinzaine` | `output/resultatsDrainIlotDetailBimensuel.gaml` |
| `ECO_coutIrrigationIlot` | `output/resultatsECO_coutIrrigationIlot.gaml` |
| `ECO_espece` | `output/resultatsECO_espece.gaml` |
| `ECO_exploitationDetail` | `output/resultatsECO_exploitationDetail.gaml` |
| `ECO_exploitationType` | `output/resultatsECO_exploitationTypes.gaml` |
| `ECO_itk` | `output/resultatsECO_itk.gaml` |
| `ECO_SDCRef` | `output/resultatsECO_SDCRef_Donnee.gaml` |
| `engrais_utilises_exploitation` | `output/resultats_N_engrais_utilises_exploitation.gaml` |
| `engrais_utilises_territoire` | `output/resultats_N_engrais_utilises_territoire.gaml` |
| `eqCO2_emissions_NC_Parcelles` | `output/resultats_N_eqCO2_emissions_NC_Parcelles.gaml` |
| `eqCO2_Nmineral_synthesis_Parcelles` | `output/resultats_N_eqCO2_Nmineral_synthesis.gaml` |
| `eqCO2_synthesis_Parcelles` | `output/resultats_N_eqCO2_synthesis_Parcelles.gaml` |
| `FluxSWAT_BVe` | `output/resultatsAS.gaml` |
| `FractionSolNu` | `output/resultatsFractionSolNu.gaml` |
| `GestionnaireDeBarrage` | `output/resultatsGestionnaireDeBarrage.gaml` |
| `GetClimatParZH` | `output/getClimatParZH.gaml` |
| `hauteurNappes` | `output/resultatsHauteurNappes.gaml` |
| `inputs_sols` | `output/inputs_sol_Parcelles.gaml` |
| `irrigationDebug` | `output/resultatsIrrigation_debug.gaml` |
| `IrrigationParAgri` | `output/resultats_IrrParAgri.gaml` |
| `IrrigationParcelle` | `output/resultatsIrrigation_parcelle.gaml` |
| `lien_ilots_zoneMeteo` | `output/inputs_ilot_zoneMeteo.gaml` |
| `missingITK` | `modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml` |
| `N_Cstock_Parcelles` | `output/resultats_N_Cstock_Parcelles.gaml` |
| `N_exportation_pailles_Parcelles` | `output/resultats_N_exportation_pailles.gaml` |
| `N_GES_Parcelles` | `output/resultats_N_GES_Parcelles.gaml` |
| `N_lixi_Parcelles` | `output/resultats_N_lixi_Parcelles.gaml` |
| `N_lixi_typeExploitation` | `output/resultats_N_lixi_typeExploitation.gaml` |
| `N_N2O_Parcelles` | `output/resultats_N_N2O_Parcelles.gaml` |
| `N_NH3_Parcelles` | `output/resultats_N_NH3_Parcelles.gaml` |
| `N_Nmin_som_res_Parcelles` | `output/resultats_N_Nmin_som_res_Parcelles.gaml` |
| `N_Nmin_total_Parcelles` | `output/resultats_N_Nmin_total_Parcelles.gaml` |
| `N_QNfix_Parcelles` | `output/resultats_N_QNfix_Parcelles.gaml` |
| `N_SOC_Parcelles` | `output/resultats_N_SOC_Parcelles.gaml` |
| `N_total_eqC02_typeExploitation` | `output/resultats_N_total_eqC02_typeExploitation.gaml` |
| `N_varArbreRegression_nApportProduits_Parcelles` | `output/resultats_N_nApportProduits_Parcelles.gaml` |
| `N_varArbreRegression_nSemisCultures_Parcelles` | `output/resultats_N_nSemisCultures_Parcelles.gaml` |
| `N_varArbreRegression_quantitesProduits_Parcelles` | `output/resultats_N_quantitesProduits_Parcelles.gaml` |
| `prelevementParPPA` | `output/resultatsPrelevements_AS.gaml` |
| `Prelevements` | `output/resultatsPrelevements.gaml` |
| `Prelevements_decoupage_itk` | `output/resultatsPrelevements_decoupage_itk.gaml` |
| `Prelevements_decoupage_typePPA` | `output/resultatsPrelevements_decoupage_typePPA.gaml` |
| `Prelevements_espece` | `output/resultatsPrelevements_espece.gaml` |
| `Prelevements_sol_espece` | `output/resultatsPrelevements_sol_espece.gaml` |
| `Prelevements_sol_itk` | `output/resultatsPrelevements_sol_itk.gaml` |
| `Prelevements_za_espece` | `output/resultatsPrelevements_ZA_espece.gaml` |
| `Prelevements_za_sol_espece` | `output/resultatsPrelevements_ZA_sol_espece.gaml` |
| `PrelevementsZA` | `output/ZA_resultatsPrelevements.gaml` |
| `PrelevementsZH` | `output/ZH_resultatsPrelevements.gaml` |
| `prixFerti_Parcelles` | `output/resultats_prixFerti_Parcelles.gaml` |
| `RDT_espece` | `output/resultatsRDT_espece.gaml` |
| `RDT_exploitation_espece` | `output/resultatsRDT_exploitation_espece.gaml` |
| `RDT_itk` | `output/resultatsRDT_itk.gaml` |
| `RDT_parcelle_espece` | `output/resultatsRDT_parcelle_espece.gaml` |
| `RDT_sol_itk` | `output/resultatsRDT_sol_itk.gaml` |
| `RechargeRetenues` | `output/resultatsRechargeRetenues.gaml` |
| `recolteParcelles` | `output/resultatsRecolteParcelles.gaml` |
| `Restrictions` | `output/resultatsRestrictions.gaml` |
| `RetenuesVolumeActuelJour` | `output/resultatsRetenuesPrelevementReelsJour.gaml` |
| `RUEdesSOLs` | `output/resultatsRUEdesSOLS.gaml` |
| `simulationDuration` | `main/main.gaml` |
| `simulationParameters` | `main/main.gaml` |
| `sortieCalibration` | `output/resultatsDebitPourCalibration.gaml` |
| `sorties_azote` | `output/sortiesAzote.gaml` |
| `sorties_barrages` | `output/sortiesBarrages.gaml` |
| `sorties_carboneGES` | `output/sortiesCarboneGES.gaml` |
| `sorties_eau` | `output/sortiesEau.gaml` |
| `sorties_iBio` | `output/resultats_iBIO.gaml` |
| `sorties_retenues` | `output/sortiesRetenues.gaml` |
| `suivi_ajout_pools_residus` | `output/resultatsSuivi_ajout_pools_residus.gaml` |
| `suivi_journalier_1parc_HerbSimNC` | `output/resultatsValidationHerbSimNC.gaml` |
| `suiviMemoireAgri` | `output/resultatsSuiviMemoireAgri.gaml` |
| `suiviOT` | `output/resultatsSuiviITK.gaml` |
| `suiviOTParParcelle` | `output/resultatsSuiviITKParParcelle.gaml` |
| `suiviOTParParcelle_humidite` | `output/resultatsSuiviITKParParcelle_humidite.gaml` |
| `suiviOTParParcelleTemps` | `output/resultatsSuiviITKParParcelleTemps.gaml` |
| `suiviSemisRecolteParParcelle` | `output/resultatsSuiviSemisRecolteParParcelle.gaml` |
| `surfaceParcelles` | `modeleAgricole/Parcelles/parcelle.gaml` |
| `SWAT_PhaseRoutage` | `output/resultatsSwatPhaseRoutageZH.gaml` |
| `tpsWFerti_Parcelles` | `output/resultats_tpsWFerti_Parcelles.gaml` |
| `travailParAgri` | `output/resultatsTravail.gaml` |
| `travailParAgri_Binage` | `output/resultatsTravail_Binage.gaml` |
| `travailParAgri_Ferti` | `output/resultatsTravail_Ferti.gaml` |
| `travailParAgri_Irrigation` | `output/resultatsTravail_Irrigation.gaml` |
| `travailParAgri_Labour` | `output/resultatsTravail_Labour.gaml` |
| `travailParAgri_Phyto` | `output/resultatsTravail_Phyto.gaml` |
| `travailParAgri_Recolte` | `output/resultatsTravail_Recolte.gaml` |
| `travailParAgri_RepriseLabour` | `output/resultatsTravail_RepriseLabour.gaml` |
| `travailParAgri_Semis` | `output/resultatsTravail_Semis.gaml` |
| `travailParEspece` | `output/resultatsTravail_espece.gaml` |
| `travailParITK` | `output/resultatsTravail_itk.gaml` |
| `travailParTypeExploitation` | `output/resultatsTravailParTypeExploitation.gaml` |
| `UtilisationQuota` | `output/resultatsUtilisationQuota.gaml` |
| `variablesAqYieldSurParcellesSpecifiees` | `output/resultatsModeleAqYield.gaml` |
| `variablesAqYieldSurParcellesSpecifiees_light` | `output/resultatsModeleAqYield_light.gaml` |

## Ce que décrit chaque sortie

Descriptions reprises des commentaires du GAML, telles que le catalogue les
porte. Les crochets en tête indiquent les clés de la table produite.

!!! info "Accents mal décodés"
    Certaines descriptions portent des accents mal décodés (`Ã©`, `â¬`)
    hérités des commentaires du GAML. Ils sont reproduits tels quels, parce
    que c'est ce que renvoie l'API : les corriger ici ferait diverger la
    documentation du catalogue. Le défaut est recensé dans
    [Écarts entre le code et la documentation source](ecarts-code-documentation.md).

| Sortie | Description |
|---|---|
| `Assolement_espece` | [annee][espece] Surface (ha) et nombre de parcelles par espece cultivee |
| `Assolement_itk` | [annee][itk] Surface (ha) et nombre de parcelles par ITK. Peut contenir des information de debogage, tel que les information sur les recoltes forcees et semis non realises |
| `Assolement_parcelle` | [annee][espece] et nombre de parcelles par espece cultivee |
| `Assolement_SDC` | [annee][SDC] Surface (ha) et nombre de parcelles par systeme de culture (ITK x rotation x sol x â¦) |
| `BilanExploitation` | marges semi-nette exploitation (â¬) et marges semi-nette exploitation (â¬/ha) de l'exploitation |
| `Canaux` | [jour et annee][canal] Debit preleve pour alimenter les canaux (volume souhaite et volume reellement preleve) |
| `corresponsanceIlotZoneMeteo` | Écrite directement par le modèle, sans drapeau dédié. |
| `DebistSTH` | [jour][stations de mesures de debit] Debits simule, mesure, DOE, QA, Qi, QAR et DCR aux differents points de reference (dont points DOE) renseignes en entree et a comparer (listeIdSthAcomparer) |
| `Debit` | Partiellement redondant avec DebistSTH |
| `debitBVe` | [jour][BVe] debit sortant (mm) |
| `debugBilanRoutage` | Écrite directement par le modèle, sans drapeau dédié. |
| `debugBilanSol` | Écrite directement par le modèle, sans drapeau dédié. |
| `debugCouchesSolParHRU` | Écrite directement par le modèle, sans drapeau dédié. |
| `debugParHRU` | Écrite directement par le modèle, sans drapeau dédié. |
| `debugParHRU_ZH192` | Écrite directement par le modèle, sans drapeau dédié. |
| `DetailsGroupeIrrigation` | [annee][Exploitation x materiel irrigation x zone administrative] Ecrit a chaque debut d'annee la structure des groupes d'irrigation prevues : Information pour chaque agri x type de materiel d'irrigation x zone adminsitrative, de la taille du tour d'eau (frequence de retour prevu), l'ID groupe irrigation tel que defini dans la table d'ITK, la surface totale du groupe d'irrigation et le nombre de parcelles |
| `DrainIlot` | [jour][territoire] bilan hydrique journalier (mm) des ilots geres par le modele de cultures (drain, ruissellement, ETR) |
| `DrainIlot_ITK_ZH` | Bilan hydrique : DrainIlot_ITK_ZH ; [jour][Bve x ITK] Moyenne ponderee des surfaces du bilan hydrique journalier (drain, ruissellement, pluie, Irrigation, surface, humiditeSol) par ITK et par Bve |
| `DrainIlotDetail` | Bilan hydrique : DrainIlot ; [jour][ilot RPG] Drain journalier moyen (mm) par ilot ATTENTION : fichier lourd en sortie |
| `ECO_coutIrrigationIlot` | [annee][Ilot] cout de l'irrigation sur l'ilot pour les surfaces irriguÃ©es (â¬/ha) |
| `ECO_espece` | [annee][espece et Territoire] Marge brute et marge semi-nette (â¬/ha) par culture |
| `ECO_exploitationDetail` | [annee][exploitation x ITK] Marge brute et marge nette (â¬/ha) par ITK par exploitation a suivre (liste fournie en entree). La liste des exploitations a suivre est precisee dans la variable listAgriASuivre |
| `ECO_exploitationType` | [annee][exploitations types] Marge brute et marge semi-nette (â¬/ha) par type d'exploitations. Un fichier de type d'exploitations est a renseigner en entree et a placer dans modeleAgricole/agriculteurs/exploitations.csv. Il est structure de maniere simple : 1 ligne d'entete. Puis ID exploitation , ID_Type_Exploitation |
| `ECO_itk` | [annee][ITK et Territoire] Marge brute et marge semi-nette (â¬/ha) par ITK |
| `ECO_SDCRef` | [annee][SDCref x type materiel irrigation x type de sol] Moyenne ponderee des surfaces des marges brutes et marges nettes (â¬/ha) pour la sequence de culture de reference pour un type de sol et un type de materiel d'irrigation |
| `FluxSWAT_BVe` | ATTENTION : fichier lourd en sortie |
| `FractionSolNu` | [annee ou jour][Territoire] fraction de la surfaces des parcelles utiles en sol nus et fraction annuelle de recoltes forcees |
| `GestionnaireDeBarrage` | [annee][barrage] Volume destocke (m3) et nombre de jour ou le destockage etait insuffisant et impossible (deficit), par ouvrage |
| `GetClimatParZH` | Climat : climatParZH ; [jour][Bve] Surface (km2), Tmoy (Â°C), Tmoy du mais (mode de calcul Arvalis)(Â°C), ETP(mm) et Precipitations (mm) |
| `hauteurNappes` | [jour][BVe] Hauteur de nappes (mm) par BVe Attention la fonction d'estimation des hauteurs de nappes par SWAT est empiriquement base sur le flux d'eau souterrain |
| `irrigationDebug` | Irrigation debug JV 220321 |
| `IrrigationParAgri` | [jour][Agri] Irrigation par Agri (m3) |
| `IrrigationParcelle` | Irrigation par parcelle: [jour][exploitation][parcelle][culture][min temp][max temp][pluie][irrigation] (irrigation en mm/m2) |
| `missingITK` | Écrite directement par le modèle, sans drapeau dédié. |
| `prelevementParPPA` | [jour][PPA] Irrigation par ppa (m3) |
| `Prelevements` | [jour et annee][territoire] volume souhaite et volume reellement preleve [m3] . Pour la sortie journaliere on distingue le volume ressources et le volume parcelle (la difference = perte + evaporation) |
| `Prelevements_decoupage_itk` | variable a considerer dans le shape : VariableDecoupagePrelevement_decoupage_itk |
| `Prelevements_decoupage_typePPA` | variable a considerer dans le shape : VariableDecoupagePrelevement_decoupagePPA |
| `Prelevements_espece` | [jour et annee][espece] volume souhaite et volume reellement apporte a la parcelle [m3] par especee |
| `Prelevements_sol_espece` | [jour et annee][sol x espece x materiel irrigation] volume souhaite et volume reellement apporte a la parcelle [m3] par types de sol, culture et materiel d'irrigation |
| `Prelevements_sol_itk` | [jour et annee][sol x ITK x materiel irrigation] volume souhaite et volume reellement apporte a la parcelle [m3] par types de sol, ITK et materiel d'irrigation |
| `Prelevements_za_espece` | [jour et annee][espece x zone administrative] volume souhaite et volume reellement apporte a la parcelle [m3] par espece cultivee et par zone adminstrative (du point de prelevement en cours) |
| `Prelevements_za_sol_espece` | [jour et annee] [espece x zone administrative x type de sol] volume souhaite et volume reellement apporte a la parcelle [m3] par espece cultivee, par type de sol et par zone adminstrative (du point de prelevement en cours) |
| `PrelevementsZA` | [jour et annee][zone administrative x nature de ressource (RET, SURF, NAPP)] volume souhaite et volume reellement preleve dans la ressource [m3] par zone administrative et type de ressource (SURF, NAPP, RET) |
| `PrelevementsZH` | [jour et annee][Bve x nature de ressource (RET, SURF, NAPP)] volume souhaite et volume reellement preleve dans la ressource [m3] par Bve et type de ressource (SURF, NAPP, RET) |
| `RDT_espece` | [annee][espece] Rendements (q/ha) par espece cultivee |
| `RDT_exploitation_espece` | [annee][exploitation x espece] Rendements (q/ha) par espece cultivee et par exploitation |
| `RDT_itk` | [annee][ITK] Rendements (q/ha) par ITK |
| `RDT_parcelle_espece` | [surface [ha]] |
| `RDT_sol_itk` | [annee][type de sol x ITK] Rendements (q/ha) et surface associee par ITK et par type de sol |
| `RechargeRetenues` | La premiere section du fichier rappelle l'identifiant, le volume(m3) et la surface (m2) |
| `recolteParcelles` | Assolement ; recolteParcelles // Permet de dÃ©terminer pour quaque annÃ©e et pour chaque parcelle l'espece rÃ©coltÃ©e leur rendement (attention, les couverts ne sont pas pris en compte) |
| `Restrictions` | [jour et annee][zone administrative] Niveaux de restrictions par zone administatives pour chaque jour ou cumul annuel |
| `RUEdesSOLs` | [annee][sol x BVe x itk x SDCref x materiel Irrigation] Fournit par annee l'information du rendement des volumes et de la plage d'irrigation, du drainage Sortie crÃ©e pour le projet RUEdesSOLs |
| `simulationDuration` | Écrite directement par le modèle, sans drapeau dédié. |
| `simulationParameters` | Écrite directement par le modèle, sans drapeau dédié. |
| `sortieCalibration` | dÃ©bit simulÃ©: [jour][DOE][debit] |
| `suiviMemoireAgri` | tempsTravaux |
| `suiviOT` | [jour][parcelle x OT] Cumul des surfaces ou du nombre de parcelles ayant subit une operation technique pour un ITK pour le jour julien donnee Attention fichier probablement lourd a creer pour un territoire entier La liste des OT a suivre est definie dans listOTASuivreEnSortie Valeur par dÃ©faut : ["IRRIGATION", "RECOLTE", "SEMIS", "BINAGE_SOL", "FERTI", "PHYTO", "REPRISE_TRAVAIL_SOL", "TRAVAIL_SOL"] |
| `surfaceParcelles` | Écrite directement par le modèle, sans drapeau dédié. |
| `SWAT_PhaseRoutage` | Evaporation (mm) |
| `travailParAgri` | [jour et anne][Type d'Agri] temps de travail par agri (h) par jour ou par an et nombre de jour travaille (i.e. avec au moins une tÃ¢che sur la journee) par agri par an |
| `travailParAgri_Binage` | [jour][Agri] temps de travail par agri (h) par jour pour le binage |
| `travailParAgri_Ferti` | [jour][Agri] temps de travail par agri (h) par jour pour la fertilisation |
| `travailParAgri_Irrigation` | [jour][Agri] temps de travail par agri (h) par jour pour l'irrigation |
| `travailParAgri_Labour` | [jour][Agri] temps de travail par agri (h) par jour pour le labour |
| `travailParAgri_Phyto` | [jour][Agri] temps de travail par agri (h) par jour pour les traitements phyto |
| `travailParAgri_Recolte` | [jour][Agri] temps de travail par agri (h) par jour pour la recolte |
| `travailParAgri_RepriseLabour` | [jour][Agri] temps de travail par agri (h) par jour pour la reprise de labour |
| `travailParAgri_Semis` | [jour][Agri] temps de travail par agri (h) par jour pour le semis |
| `travailParEspece` | [annee][espece] temps de travail par espece (h/ha) par an |
| `travailParITK` | [annee][ITK] temps de travail par ITK (h/ha) par an |
| `travailParTypeExploitation` | [jour et annee][Type d'exploitation] temps de travail, nombre moyen de jour travaille nombre moyen de jour a plus de 80% du temps de travail disponible, par type d'exploitations (h) , par jour ou par an et nombre de jour travaille (i.e. avec au moins une tÃ¢che sur la journee) par agri par an |
| `UtilisationQuota` | [annee][ppa] Quota utilise (m3) et quota attribue par PPA, par an |

Les sorties absentes de ce tableau ne portent pas de commentaire descriptif
dans le GAML ; leur nom de fichier et leur module sont alors la seule
indication de contenu.

## Gardes non entièrement traduisibles

Ces gardes contiennent un terme que le langage de conditions ne sait pas
exprimer : une longueur de liste, un état interne, une date codée en dur. Le
terme est écarté de `produced_if`, la sortie est marquée `exact: false`, et
la plateforme l'annonce **possible** au lieu de certaine. Le texte GAML
d'origine est conservé dans `guard_source` : une traduction qui abandonne un
terme doit rester vérifiable.

| Sortie | Garde retenue | Texte GAML d'origine |
|---|---|---|
| `Canaux` | `executerModeleHydrographique == true && isPrelevementEtRejetSimules == true && isCanaux == true && Canaux == true` | `((executerModeleHydrographique)) and ((isPrelevementEtRejetSimules and isCanaux and length(listeCanaux) > 0)) and ((Canaux))` |
| `debugCouchesSolParHRU` | `executerModeleHydrographique == true` | `((name="3451")) and ((((dateCour.annee=2006) and (dateCour.mois=10)) or ((dateCour.annee=2005) and (dateCour.mois=9)) or ((dateCour.annee=2003) and (dateCour.mois=2)) or ((dateCour.annee=2002) and (dateCour.mois=4)) or ((dateCour.annee=2001) and (dateCour.mois=7)) or ((dateCour.annee=2003) and (dateCour.mois=12)) or ((dateCour.annee=2006) and (dateCour.mois=4 or dateCour.mois=5))))` |
| `debugParHRU` | `executerModeleHydrographique == true` | `((name="3451")) and ((((dateCour.annee=2006) and (dateCour.mois=10)) or ((dateCour.annee=2005) and (dateCour.mois=9)) or ((dateCour.annee=2003) and (dateCour.mois=2)) or ((dateCour.annee=2002) and (dateCour.mois=4)) or ((dateCour.annee=2001) and (dateCour.mois=7)) or ((dateCour.annee=2003) and (dateCour.mois=12)) or ((dateCour.annee=2006) and (dateCour.mois=4 or dateCour.mois=5))))` |
| `debugParHRU_ZH192` | `executerModeleHydrographique == true` | `((name="192")) and (((dateCour.annee=2003) and (dateCour.mois=8)))` |
| `missingITK` | `remplacerItkManquants == true && executerModeleAgricole == true` | `((itkRes = nil)) and (remplacerItkManquants) and (!file_exists(cheminFic))` |

## Sorties écrites hors aiguillage

Ces fichiers sont écrits directement au fil du code, sans passer par
`output/ecritureResultats.gaml`. Aucun drapeau ne les commande : on leur
attribue la garde **sûre** de leur arborescence — un fichier écrit depuis
`modeleHydrographique/` n'existe que si ce module tourne. Une garde vide
signifie que le fichier est écrit à chaque exécution.

| Sortie | Fichier | Écrit par | Produite si |
|---|---|---|---|
| `corresponsanceIlotZoneMeteo` | `corresponsanceIlotZoneMeteo.csv` | `modeleCommun/zoneMeteoMoyenne.gaml` | *écrite à chaque exécution* |
| `debugBilanRoutage` | `debugBilanRoutage.csv` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` | `executerModeleHydrographique == true` |
| `debugBilanSol` | `debugBilanSol.csv` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` | `executerModeleHydrographique == true` |
| `debugCouchesSolParHRU` | `debugCouchesSolParHRU.csv` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` | ~ `executerModeleHydrographique == true` |
| `debugParHRU` | `debugParHRU.csv` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` | ~ `executerModeleHydrographique == true` |
| `debugParHRU_ZH192` | `debugParHRU_ZH192.csv` | `modeleHydrographique/zoneHydrographiqueSWAT.gaml` | ~ `executerModeleHydrographique == true` |
| `missingITK` | `missingITK.csv` | `modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml` | ~ `remplacerItkManquants == true && executerModeleAgricole == true` |
| `simulationDuration` | `simulationDuration.txt` | `main/main.gaml` | *écrite à chaque exécution* |
| `simulationParameters` | `simulationParameters.txt` | `main/main.gaml` | *écrite à chaque exécution* |
| `surfaceParcelles` | `surfaceParcelles.csv` | `modeleAgricole/Parcelles/parcelle.gaml` | `executerModeleAgricole == true` |

## Drapeaux hors de portée d'un scénario

Ces drapeaux sont déclarés par `output/selectionOutput.gaml` mais **pas par**
`launcherBase.gaml`. Ils ne peuvent donc pas être surchargés au `load` : la
sortie qu'ils commandent est inatteignable, quoi que fasse l'utilisateur. Les
rendre accessibles demande d'ajouter une ligne `parameter … var: …` au
launcher — c'est une modification du **modèle**, pas du catalogue. L'écran
`/admin/catalogue/sorties` les signale « hors de portée ».

| Drapeau | Sortie(s) concernée(s) |
|---|---|
| `Assolement_parcelle` | `Assolement_parcelle` |
| `BilanExploitation` | `BilanExploitation` |
| `Canaux` | `Canaux` |
| `DrainIlot_ITK_ZH` | `DrainIlot_ITK_ZH` |
| `FluxSWAT_BVe` | `FluxSWAT_BVe` |
| `FractionSolNu` | `FractionSolNu` |
| `GetClimatParZH` | `GetClimatParZH` |
| `N_SOC_Parcelles` | `N_SOC_Parcelles` |
| `N_exportation_pailles_Parcelles` | `N_exportation_pailles_Parcelles` |
| `N_varArbreRegression_nApportProduits_Parcelles` | `N_varArbreRegression_nApportProduits_Parcelles` |
| `N_varArbreRegression_nSemisCultures_Parcelles` | `N_varArbreRegression_nSemisCultures_Parcelles` |
| `N_varArbreRegression_quantitesProduits_Parcelles` | `N_varArbreRegression_quantitesProduits_Parcelles` |
| `RDT_exploitation_espece` | `RDT_exploitation_espece` |
| `RUEdesSOLs` | `RUEdesSOLs` |
| `RechargeRetenues` | `RechargeRetenues` |
| `RetenuesVolumeActuelJour` | `RetenuesVolumeActuelJour` |
| `SWAT_PhaseRoutage` | `SWAT_PhaseRoutage` |
| `UtilisationQuota` | `UtilisationQuota` |
| `debitBVe` | `debitBVe` |
| `debugSortie1parcelleAqYield_N` | `debugSortie1parcelleAqYield_N` |
| `demoChambreAlsace` | `demoChambreAlsace` |
| `eqCO2_Nmineral_synthesis_Parcelles` | `eqCO2_Nmineral_synthesis_Parcelles` |
| `hauteurNappes` | `hauteurNappes` |
| `inputs_sols` | `inputs_sols` |
| `lien_ilots_zoneMeteo` | `lien_ilots_zoneMeteo` |
| `prelevementParPPA` | `prelevementParPPA` |
| `sortieCalibration` | `sortieCalibration` |
| `suiviMemoireAgri` | `suiviMemoireAgri` |
| `suiviSemisRecolteParParcelle` | `suiviSemisRecolteParParcelle` |
| `travailParAgri` | `travailParAgri` |
| `travailParAgri_Binage` | `travailParAgri_Binage` |
| `travailParAgri_Ferti` | `travailParAgri_Ferti` |
| `travailParAgri_Labour` | `travailParAgri_Labour` |
| `travailParAgri_Phyto` | `travailParAgri_Phyto` |
| `travailParAgri_Recolte` | `travailParAgri_Recolte` |
| `travailParAgri_RepriseLabour` | `travailParAgri_RepriseLabour` |
| `travailParAgri_Semis` | `travailParAgri_Semis` |
| `travailParEspece` | `travailParEspece` |
| `travailParITK` | `travailParITK` |
| `travailParTypeExploitation` | `travailParTypeExploitation` |

## Drapeaux levés d'office

Les seuls drapeaux que `output/selectionOutput.gaml` déclare à *vrai*. La
colonne **Exposé au launcher** dit si un scénario peut les rabaisser : un
drapeau absent du launcher est levé sans recours.

| Drapeau | Sortie | Fichier(s) | Exposé au launcher | Produite si |
|---|---|---|---|---|
| `lien_ilots_zoneMeteo` | `lien_ilots_zoneMeteo` | `id_ilot_zoneMeteo.csv` | non — hors de portée | `executerModeleAgricole == true && sortiesAqYieldNC == true && lien_ilots_zoneMeteo == true` |
| `sorties_eau` | `sorties_eau` | `sorties_eau.csv` | oui | `sorties_eau == true && nomChoixModeleCroissancePlante == 'AqYield' \|\| sorties_eau == true && nomChoixModeleCroissancePlante == 'AqYieldNC'` |
| `suiviOT` | `suiviOT` | `suiviITK_.csv` | oui | `executerModeleAgricole == true && suiviOT == true` |
| `suiviOTParParcelle` | `suiviOTParParcelle` | `suiviOTParParcelle.csv` | oui | `executerModeleAgricole == true && suiviOTParParcelle == true` |

Lever un drapeau ne suffit pas à obtenir le fichier : le reste de la garde
doit tenir. Et lorsque le launcher déclare l'inverse de
`selectionOutput.gaml`, c'est le launcher qui s'applique — voir la section
suivante.

## Quand le drapeau et le launcher ne disent pas la même chose

Deux endroits déclarent la valeur d'un drapeau : `output/selectionOutput.gaml`,
qui le définit, et `launcherBase.gaml`, qui l'expose. Pour ces drapeaux, les
deux ne s'accordent pas. **C'est le launcher qui l'emporte** : sa déclaration
est évaluée au `load`, après celle de `selectionOutput.gaml`. La colonne
*Défaut* des tableaux ci-dessus porte la valeur du catalogue de sorties ; la
valeur réellement appliquée à une exécution sans surcharge est celle du
catalogue de paramètres.

| Drapeau | Défaut au catalogue de sorties | Défaut au catalogue de paramètres | Défaut du launcher exécuté |
|---|---|---|---|
| `debugSortie1parcelleAqYield` | faux | vrai | `false` |
| `engrais_utilises_exploitation` | faux | vrai | — |
| `N_Cstock_Parcelles` | faux | vrai | `false` |
| `suivi_ajout_pools_residus` | faux | vrai | — |
| `suiviOT` | vrai | faux | — |

!!! note "Voir aussi"

    - [Les paramètres de scénario](parametres.md) — les drapeaux, côté launcher
    - [L'API REST](api-rest.md) — `POST /api/v1/outputs/expected` et `GET /api/v1/runs/{run_id}/output-review`
    - [Les chiffres du modèle](chiffres.md)
    - [Glossaire](glossaire.md)
