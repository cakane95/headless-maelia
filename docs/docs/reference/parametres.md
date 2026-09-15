# Les paramètres de scénario

!!! abstract "En bref"
    Liste exhaustive des variables que `launcherBase.gaml` expose et qu'un
    scénario peut surcharger au `load` de gama-server : nom technique,
    libellé affiché par GAMA, type, valeur par défaut et condition
    d'activation. C'est la seule liste qui fasse foi côté plateforme.

**Source** : extraction de `headless-maelia-server/app/contexts/catalog/infrastructure/seed/parameters.json` — vérifié le 2026-09-15 contre MAELIA 1.4.29.

--8<-- "_partials/chiffres-modele.md:parametres"

## Comment lire les tableaux

| Colonne | Contenu |
|---|---|
| **Nom** | nom technique GAML — c'est lui qu'on passe dans le message JSON envoyé à GAMA |
| **Libellé** | intitulé affiché par l'interface GAMA, repris tel quel du launcher |
| **Type** | `BOOL`, `STRING`, `INT`, `FLOAT`, `LIST` ou `EXPRESSION` |
| **Défaut** | valeur retenue au catalogue |
| **Défaut launcher** | valeur du launcher exécuté, quand elle diverge du défaut du catalogue |
| **Actif si** | condition d'activation (`enabled_if`) ; vide = toujours actif |

!!! info "D'où viennent les défauts du catalogue"
    Les réglages transposables prennent la valeur de `launcherSasseme.gaml` ;
    les valeurs propres à un territoire — identifiants d'exploitations, de
    parcelles, de zones, années — gardent celles de `launcherBase.gaml`. La
    colonne **Défaut launcher** signale les cas où le launcher exécuté déclare
    autre chose : non nulle, la plateforme envoie explicitement cette valeur à
    chaque exécution.

Un paramètre de type `EXPRESSION` porte une expression GAML, non une valeur :
le launcher la calcule au chargement du modèle. Elle est reproduite telle
quelle et n'a pas vocation à être saisie.

## Paramètres imposés par la plateforme

Ces paramètres sont écrits par le worker à chaque exécution. Les surcharger
dans un scénario **n'a aucun effet** : la valeur envoyée à GAMA est celle que
la plateforme calcule.

| Nom | Type | Défaut au catalogue | Ce que la plateforme y met |
|---|---|---|---|
| `executerSurCluster` | BOOL | `false` | toujours faux — l'exécution est locale au conteneur |
| `cheminRacineMaelia` | EXPRESSION | `"mapCheminRacineMaeliaSelonClusterOuPas[executerSurCluster]"` | `MAELIA_ROOT_PATH`, identique dans `api`, `worker` et `gama-headless` |
| `cheminModeleVersDonnees` | EXPRESSION | `"cheminRacineMaelia + \"includes/\""` | la racine des includes recopiés pour ce run |
| `cheminRelatifDuDossierDeSortieDeSimulation` | EXPRESSION | `"cheminRacineMaelia + \"models/main/log\""` | `MAELIA_OUTPUT_ROOT` |
| `idSimulationAPI` | STRING | `""` | l'identifiant du run, ce qui rend le dossier de sortie déterministe |

Un sixième paramètre, `listOTASuivreEnSortie`, n'est pas imposé mais reste
non modifiable : sa valeur par défaut est une expression GAML (`listOT`) que
le catalogue ne sait pas transposer en liste de valeurs saisissables.

## Chemins

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `executerSurCluster` **⚙** | executerSurCluster | BOOL | `false` | — | — |
| `cheminRacineMaelia` **⚙** | cheminRacineMaelia | EXPRESSION | `"mapCheminRacineMaeliaSelonClusterOuPas[executerSurCluster]"` | — | — |
| `cheminModeleVersDonnees` **⚙** | cheminModeleVersDonnees | EXPRESSION | `"cheminRacineMaelia + \"includes/\""` | — | — |
| `cheminRelatifDuDossierDeSortieDeSimulation` **⚙** | cheminSorties | EXPRESSION | `"cheminRacineMaelia + \"models/main/log\""` | — | — |

**⚙** = imposé par la plateforme.

## Général

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `anneeDebutSimulation` | anneeDebutSimulation | INT | `2019` | — | — |
| `nbAnneesSimulation` | nbAnneesSimulation | INT | `7` | `3` | — |
| `nomSimulation` | nomSimulation | STRING | `""` | — | — |
| `nomDecoupageZonePourLectureFichiers` | nomDecoupageZonePourLectureFichiers | STRING | `"terrainTest"` | — | — |
| `executerModeleSurUneZH` | simulationSurZH | BOOL | `false` | — | — |
| `listNomsZHsDecoupageZone` | idZHASimuler | LIST | `[""]` | — | `executerModeleSurUneZH == true` |
| `executerUnSeulAgriculteur` | simulationSurExploitation | BOOL | `false` | — | — |
| `idExploitationAexecuter` | idExploitationASimuler | STRING | `"mineral_beauce_29"` | — | `executerUnSeulAgriculteur == true` |
| `executerSurEnsembleExploit` | simulationSurEnsembleExploitations | BOOL | `false` | — | — |
| `listIdExploitationAexecuter` | idExploitationsASimuler | LIST | `["expl_13", "expl_15"]` | — | `executerSurEnsembleExploit == true` |
| `executerUneSeuleParcelle` | simulationSurParcelle | BOOL | `false` | — | — |
| `nomParcelleAffichee` | idParcelleASimuler | STRING | `"beauce_48_1"` | — | `executerUneSeuleParcelle == true` |
| `nomScenarioClimatique` | nomScenarioClimatique | STRING | `""` | `"rcp8.5"` | — |
| `utiliserMemeDonnesMeteoPartout` | utiliserMemeMeteoPartout | BOOL | `false` | — | — |
| `idPointMeteoUnique` | idPointMeteoUnique | STRING | `"3994"` | — | `utiliserMemeDonnesMeteoPartout == true` |
| `idSimulationAPI` **⚙** | idSimulationAPI | STRING | `""` | — | — |
| `verboseMode` | modeVerbeux | BOOL | `true` | `false` | — |

**⚙** = imposé par la plateforme.

## Modèle hydrographique

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `executerModeleHydrographique` | executerModeleHydrographique | BOOL | `false` | — | — |
| `nomChoixModeleHydrographique` | nomChoixModeleHydrographique | STRING | `"SWAT"` | — | `executerModeleHydrographique == true` |
| `coefficientSurfaceRuissellementLag` | surLag: coefficientSurfaceRuissellementLag | FLOAT | `4.0` | — | — |
| `retardEntreSortiSolEtEntreeAquifereGlobal` | deltaGw: retardEntreSortiSolEtEntreeAquifereGlobal | FLOAT | `31.0` | — | — |
| `coefPercolationVersAquifereProfondGlobal` | betaDeep: coefPercolationVersAquifereProfondGlobal | FLOAT | `1.0` | — | — |
| `coefficientManningTerrain` | nTerrain: coefficientManningTerrain | FLOAT | `0.12` | — | — |
| `isPrelevementEtRejetSimules` | isPrelevementEtRejetSimules | BOOL | `true` | — | — |
| `affecterEqIrrSiInexistant` | affecterEqIrrSiInexistant | BOOL | `true` | — | `isPrelevementEtRejetSimules == true` |
| `nomPtRefAffichee` | nomPtRefAffichee | STRING | `"O5882510"` | — | — |
| `listNomsZHsDebitComplement` | listNomsZHsDebitComplement | LIST | `["549"]` | — | — |
| `listeExutoiresZoneMaelia` | listeExutoiresZoneMaelia | LIST | `["110", "208"]` | — | — |
| `ID_RESSOURCES_INFINIES` | ID_RESSOURCES_INFINIES | LIST | `["SURF_EAU0000000025689668"]` | — | — |

## Modèle agricole

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `executerModeleAgricole` | executerModeleAgricole | BOOL | `true` | — | — |
| `nomChoixAssolement` | nomChoixAssolement | STRING | `"Donnees"` | — | — |
| `anneeDeReferenceRPG` | anneeDeReferenceRPG | INT | `2014` | — | — |
| `activerITKalternatif` | activerITKAlternatif | BOOL | `false` | — | — |
| `forcerSemisCI` | forcerSemisCI | BOOL | `false` | — | — |
| `avecContrainteDeMainOeuvre` | avecContrainteDeMainOeuvre | BOOL | `false` | `true` | — |
| `plusieursTravauxDuSolParITK` | plusieursTravauxDuSolParITK | BOOL | `true` | — | — |
| `plusieursFertilisationsParITK` | plusieursFertilisationsParITK | BOOL | `true` | — | — |
| `plusieursTraitementsPhytoParITK` | plusieursTraitementsPhytoParITK | BOOL | `true` | — | — |
| `adaptationFertilisation` | Adaptation de la fertilisation | STRING | `"reliquat"` | `""` | — |
| `corpenProfondeurTemporelle` | Profondeur temporelle du bilan CORPEN | INT | `3` | — | — |
| `gestionStocksEngrais` | Niveau scalaire de gestion des stocks d engrais | STRING | `"territoire"` | — | — |
| `avecIlotsHorsZone` | avecIlotsHorsZone | BOOL | `false` | — | — |
| `nomChoixModeleCroissancePlante` | nomChoixModeleCroissancePlante | STRING | `"AqYield"` | `"AqYieldNC"` | — |
| `nomChoixModeleCroissancePrairie` | nomChoixModeleCroissancePrairie | STRING | `"HerbSimNC"` | — | — |
| `denit_fTemp_option` | Choix fonction temp dénit | STRING | `"Stics"` | — | — |
| `isIrrigationSimulee` | isIrrigationSimulee | BOOL | `true` | — | — |
| `nomChoixModeleIrrigation` | nomChoixModeleIrrigation | STRING | `"Simple"` | — | `isIrrigationSimulee == true` |
| `listScenarioPrix` | liste des scénarios de prix de vente des cultures | LIST | `[""]` | — | — |
| `scenarioDePrixPrincipal` | nom du scenario de prix principal | STRING | `""` | — | — |
| `PREFIXE_CI` | préfixe culture couvert intermédiaire | STRING | `"ci"` | — | — |
| `remplacerItkManquants` | remplacement ITK manquants | BOOL | `true` | `false` | — |
| `associerIlotMeteoZH` | associerIlotMeteoZH | BOOL | `false` | — | — |
| `option_Finert_calc` | fraction SOM inerte fonction du %MO | BOOL | `false` | — | — |
| `avecStressClimatique` | Gel et échaudage | BOOL | `false` | — | — |
| `executerParcelleVirtuelle` | executerParcelleVirtuelle | BOOL | `false` | — | — |
| `rotationForceeParcelle` | rotationForceeParcelle | STRING | `"colza-precPauvre_CP-precRiche_feverole_CP-precRiche"` | — | `executerParcelleVirtuelle == true` |
| `gestionPaillesForceeParcelle` | gestionPaillesForceeParcelle | STRING | `""` | — | `executerParcelleVirtuelle == true` |
| `idSdcForce` | [PARAM] idSdcForce | STRING | `"all"` | — | `executerParcelleVirtuelle == true` |
| `typeDeSolForceParcelle` | [PARAM] typeDeSolForceParcelle | STRING | `"luvisols plateaux inferieurs"` | — | `executerParcelleVirtuelle == true` |
| `surfaceHectareForceParcelle` | [PARAM] surfaceHectareForceParcelle | FLOAT | `10.0` | — | `executerParcelleVirtuelle == true` |
| `executerModeleElevage` | executerModeleElevage | BOOL | `false` | — | — |

## Modèle normatif

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `executerModeleNormatif` | executerModeleNormatif | BOOL | `false` | — | — |
| `executerBarrage` | executerBarrage | BOOL | `false` | — | — |
| `accelerationTourEauSiRestriction` | accelerationTourEauSiRestriction | BOOL | `false` | — | — |

## Sorties

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `executerEcritureFichiers` | executerEcritureFichiers | BOOL | `true` | — | — |
| `nb_decimales_sorties` | nb décimales sorties | INT | `2` | — | — |
| `sorties_eau` | sorties eau | BOOL | `true` | — | — |
| `sorties_azote` | sorties azote | BOOL | `false` | `true` | — |
| `sorties_carboneGES` | sorties carbone et GES | BOOL | `false` | `true` | — |
| `sorties_retenues` | sorties retenues | BOOL | `false` | — | — |
| `sorties_barrages` | sorties barrages | BOOL | `false` | — | — |
| `listAgriASuivre` | listAgriASuivre | LIST | *voir ci-dessous* | — | — |
| `listParcellesASuivre` | listParcellesASuivre | LIST | `["082-5653275_00", "082-5661385_00", "082-5658658_03"]` | — | — |

## Sorties — assolement

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `Assolement_SDC` | Sortie Assolement_SDC | BOOL | `false` | — | — |
| `Assolement_itk` | Sortie Assolement_itk | BOOL | `false` | — | — |
| `Assolement_espece` | Sortie Assolement_espece | BOOL | `false` | — | — |
| `ECO_espece` | Sortie ECO_espece | BOOL | `false` | — | — |
| `ECO_itk` | Sortie ECO_itk | BOOL | `false` | — | — |
| `ECO_exploitationType` | Sortie ECO_exploitationType | BOOL | `false` | — | — |
| `ECO_exploitationDetail` | Sortie ECO_exploitationDetail | BOOL | `false` | — | — |
| `ECO_SDCRef` | Sortie ECO_SDCRef | BOOL | `false` | — | — |
| `ECO_coutIrrigationIlot` | Sortie ECO_coutIrrigationIlot | BOOL | `false` | — | — |
| `variablesAqYieldSurParcellesSpecifiees` | Sortie AqYield parcelles | BOOL | `false` | — | — |
| `variablesAqYieldSurParcellesSpecifiees_light` | Sortie AqYield parcelles light | BOOL | `false` | — | — |
| `listParcellesPourSortiesAqYield` | Liste parcelles sorties AqYield | LIST | `["082-5650603_00"]` | — | — |
| `aqYield_eva_trmax_trr_ITK_ZH` | Sortie eva, trmax, trreelle ITK ZH | BOOL | `false` | — | — |
| `debug_fusion_AqYieldNC` | debug_fusion_AqYieldNC | BOOL | `false` | — | — |
| `sortiesAqYieldNC` | Sorties AqYield NC | BOOL | `true` | `false` | — |
| `N_lixi_typeExploitation` | Sortie N_lixi_typeExploitation | BOOL | `false` | — | — |
| `N_total_eqC02_typeExploitation` | Sortie N_total_eqC02_typeExploitation | BOOL | `false` | — | — |
| `N_Cstock_Parcelles` | Sortie N_Cstock_Parcelles | BOOL | `true` | `false` | — |
| `engrais_utilises_territoire` | Sortie engrais_utilises_territoire | BOOL | `false` | — | — |
| `engrais_utilises_exploitation` | Sortie engrais_utilises_exploitation | BOOL | `true` | — | — |
| `eqCO2_emissions_NC_Parcelles` | Sortie eqCO2_emissions_NC_Parcelles | BOOL | `false` | — | — |
| `N_N2O_Parcelles` | Sortie N_N2O_Parcelles | BOOL | `false` | — | — |
| `N_NH3_Parcelles` | Sortie N_NH3_Parcelles | BOOL | `false` | — | — |
| `N_Nmin_som_res_Parcelles` | Sortie N_Nmin_som_res_Parcelles | BOOL | `false` | — | — |
| `N_Nmin_total_Parcelles` | Sortie N_Nmin_total | BOOL | `false` | — | — |
| `N_QNfix_Parcelles` | Sortie N_QNfix_Parcelles | BOOL | `false` | — | — |
| `tpsWFerti_Parcelles` | Sortie tpsWFerti_Parcelles | BOOL | `false` | — | — |
| `prixFerti_Parcelles` | Sortie prixFerti_Parcelles | BOOL | `false` | — | — |
| `recolteParcelles` | Sortie recolteParcelles | BOOL | `false` | — | — |
| `eqCO2_synthesis_Parcelles` | Sortie eqCO2_synthesis_Parcelles | BOOL | `false` | — | — |
| `N_GES_Parcelles` | Sortie N_GES_Parcelles | BOOL | `false` | — | — |
| `N_lixi_Parcelles` | Sortie N_lixi_Parcelles | BOOL | `false` | — | — |
| `suivi_journalier_1parc_HerbSimNC` | Sortie journalière HerbSimNC | BOOL | `false` | — | — |

## Bilan nc

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `suivi_ajout_pools_residus` | Sortie Ajout_Pools_Residus | BOOL | `true` | — | — |

## Sorties — bilan hydrique

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `DrainIlot` | Sortie DrainIlot | BOOL | `false` | — | — |
| `DrainIlot_mois` | Sortie DrainIlot mensuel | BOOL | `false` | — | — |
| `DrainIlot_quinzaine` | Sortie DrainIlot bimensuel | BOOL | `false` | — | — |
| `DrainIlotDetail` | Sortie DrainIlotDetail | BOOL | `false` | — | — |
| `DrainIlotDetail_mois` | Sortie DrainIlotDetail mensuel | BOOL | `false` | — | — |
| `DrainIlotDetail_quinzaine` | Sortie DrainIlotDetail bimensuel | BOOL | `false` | — | — |
| `IrrigationParAgri` | Irrigation par Agri | BOOL | `false` | — | — |
| `travailParAgri_Irrigation` | Travail Irrigation par agri | BOOL | `false` | — | — |
| `DetailsGroupeIrrigation` | Travail Irrigation | BOOL | `false` | — | — |
| `irrigationDebug` | Irrigation debug | BOOL | `false` | — | — |
| `IrrigationParcelle` | Irrigation par parcelle | BOOL | `false` | — | — |

## Sorties — économie

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `RDT_itk` | Sortie RDT_itk | BOOL | `false` | — | — |
| `RDT_sol_itk` | Sortie RDT_sol_itk | BOOL | `false` | — | — |
| `RDT_espece` | Sortie RDT_espece | BOOL | `false` | — | — |
| `RDT_parcelle_espece` | Sortie RDT_parcelle_espece | BOOL | `false` | — | — |

## Sorties — biodiversité

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `sorties_iBio` | Sortie i-Bio | BOOL | `false` | — | — |

## Sorties — hydrologie

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `DebistSTH` | Sortie debit aux points STH selectione | BOOL | `false` | — | — |
| `Debit` | Sortie debit pour tous les points STH | BOOL | `false` | — | — |

## Sorties — prélèvements

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `Prelevements` | Sortie Prelevements Territoire | BOOL | `false` | — | — |
| `PrelevementsZH` | Sortie Prelevements par ZH | BOOL | `false` | — | — |
| `PrelevementsZA` | Sortie Prelevements par ZA | BOOL | `false` | — | — |
| `Prelevements_sol_itk` | Sortie Prelevements par Sol x ITK | BOOL | `false` | — | — |
| `Prelevements_sol_espece` | Sortie Prelevements par Sol x Espece | BOOL | `false` | — | — |
| `Prelevements_espece` | Sortie Prelevements par Espece | BOOL | `false` | — | — |
| `Prelevements_za_espece` | Sortie Prelevements par ZA x Espece | BOOL | `false` | — | — |
| `Prelevements_za_sol_espece` | Sortie Prelevements par ZA x Sol x Espece | BOOL | `false` | — | — |
| `Prelevements_decoupage_itk` | Sortie Prelevements par ITK x Decoupage ilot | BOOL | `false` | — | — |
| `Prelevements_decoupage_typePPA` | Sortie Prelevements par ITK x Decoupage PPA | BOOL | `false` | — | — |

## Sorties — normatif

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `Restrictions` | Sortie Niveau de restriction par ZA | BOOL | `false` | — | — |
| `GestionnaireDeBarrage` | Sortie GestionnaireDeBarrage | BOOL | `false` | — | — |

## Sorties — opérations techniques

| Nom | Libellé | Type | Défaut | Défaut launcher | Actif si |
|---|---|---|---|---|---|
| `debugSortie1parcelleAqYield` | Sortie debugSortie1parcelleAqYield | BOOL | `true` | `false` | — |
| `suiviOT` | Suivi de la realisation des operations techniques | BOOL | `false` | — | — |
| `suiviOTParParcelle` | Suivi détaillé des OT par parcelle | BOOL | `true` | — | — |
| `suiviOTParParcelleTemps` | Suivi detaille des OT par parcelle avec duree | BOOL | `false` | — | — |
| `suiviOTParParcelle_humidite` | Suivi des OT semis, irrigation, récolte + humidité | BOOL | `false` | — | — |
| `listOTASuivreEnSortie` | liste des OT a suivre en sortie | EXPRESSION | `"listOT"` | — | — |
| `plan_epandage_actif` | Plan épandage | BOOL | `false` | — | — |

## Valeurs par défaut trop longues pour un tableau

`listAgriASuivre` :

```json
["344877", "345341", "346156", "346838", "345630", "345225", "346823", "347327", "345857", "344736", "343392", "345120", "344376", "344467", "343607", "344483", "345756", "344630", "345039", "344464", "345772", "345459", "346630", "343768", "343023", "347505", "343772", "343677", "344156", "345099", "347320", "345234", "342842", "347130", "190567", "345215", "346058", "346472", "346646", "347312", "343329", "343505", "343770", "346680", "343729", "342973", "343409", "346530", "345611", "343321", "344675", "346673", "343610", "344226", "345593", "343078", "344442", "345259", "345343", "344095", "343658", "343086", "347174", "347533", "347180", "345041", "344491", "346591", "346048", "190428", "346878", "345509", "343805", "343020", "346374", "346136", "343700", "345530", "343968", "343910", "343180", "345363", "345314", "346991", "343243", "343251", "344590", "344399", "344329", "343200", "346195", "345121", "344061", "345539", "345355", "344611", "344517", "342987", "344342", "346790", "345851", "344532", "346040", "345458", "346867", "346683", "346239", "346222", "346879", "347183", "343774", "343500", "346055", "343057", "347498", "345586", "345206", "345937", "343193", "346872", "346318", "345297", "346763", "347472", "347248", "347617", "346504", "343149", "344938", "347019", "345284", "346783", "343638", "343368", "345952", "346440", "344201", "347155", "344023", "345211", "347441", "344963", "345592", "347120", "347249", "346881", "347325", "346387", "345720", "345262", "346199", "345283", "345351", "346215", "343966", "345652", "345714", "346045", "346619", "346919", "347507", "346276", "346807", "346252", "343137"]
```

## Valeurs prises dans les données du projet

`options_from` vaut `<identifiant de fichier>#<champ>` : les valeurs
acceptables ne sont pas une énumération figée, elles vivent dans les données
du projet. La plateforme propose alors les identifiants réellement présents,
au lieu de laisser saisir une valeur que seule l'exécution démentirait. Un
champ vide après le `#` désigne les fichiers eux-mêmes, pas une colonne.

| Paramètre | options_from | Fichier source | Champ |
|---|---|---|---|
| `idExploitationAexecuter` | `agri.agriculteurs.exploitations#ID_EXPL` | `agri.agriculteurs.exploitations` | `ID_EXPL` |
| `listIdExploitationAexecuter` | `agri.agriculteurs.exploitations#ID_EXPL` | `agri.agriculteurs.exploitations` | `ID_EXPL` |
| `nomParcelleAffichee` | `agri.ilots.dansZone.parcelles#ID_PARCELL` | `agri.ilots.dansZone.parcelles` | `ID_PARCELL` |
| `listScenarioPrix` | `agri.marcheAgricole.prixVentes#` | `agri.marcheAgricole.prixVentes` | *les fichiers eux-mêmes* |
| `scenarioDePrixPrincipal` | `agri.marcheAgricole.prixVentes#` | `agri.marcheAgricole.prixVentes` | *les fichiers eux-mêmes* |
| `idSdcForce` | `agri.ilots.dansZone.parcelles#ID_SDC` | `agri.ilots.dansZone.parcelles` | `ID_SDC` |
| `listParcellesASuivre` | `agri.ilots.dansZone.parcelles#ID_PARCELL` | `agri.ilots.dansZone.parcelles` | `ID_PARCELL` |
| `listParcellesPourSortiesAqYield` | `agri.ilots.dansZone.parcelles#ID_PARCELL` | `agri.ilots.dansZone.parcelles` | `ID_PARCELL` |

La route qui les résout est
`GET /api/v1/projects/{project_id}/parameters/{name}/options` — voir
[L'API REST](api-rest.md).

## Activation conditionnelle

Un paramètre grisé n'est pas un paramètre absent : il attend qu'un autre
réglage l'ouvre. Le langage est celui décrit dans
[Les fichiers d'entrée](fichiers-entree.md) — `param == valeur` / `!=`, liés
par `&&` et `||`, `&&` liant plus fort, sans parenthèses.

| Paramètre | Actif si | Levier |
|---|---|---|
| `listNomsZHsDecoupageZone` | `executerModeleSurUneZH == true` | `executerModeleSurUneZH` |
| `idExploitationAexecuter` | `executerUnSeulAgriculteur == true` | `executerUnSeulAgriculteur` |
| `listIdExploitationAexecuter` | `executerSurEnsembleExploit == true` | `executerSurEnsembleExploit` |
| `nomParcelleAffichee` | `executerUneSeuleParcelle == true` | `executerUneSeuleParcelle` |
| `idPointMeteoUnique` | `utiliserMemeDonnesMeteoPartout == true` | `utiliserMemeDonnesMeteoPartout` |
| `nomChoixModeleHydrographique` | `executerModeleHydrographique == true` | `executerModeleHydrographique` |
| `affecterEqIrrSiInexistant` | `isPrelevementEtRejetSimules == true` | `isPrelevementEtRejetSimules` |
| `nomChoixModeleIrrigation` | `isIrrigationSimulee == true` | `isIrrigationSimulee` |
| `rotationForceeParcelle` | `executerParcelleVirtuelle == true` | `executerParcelleVirtuelle` |
| `gestionPaillesForceeParcelle` | `executerParcelleVirtuelle == true` | `executerParcelleVirtuelle` |
| `idSdcForce` | `executerParcelleVirtuelle == true` | `executerParcelleVirtuelle` |
| `typeDeSolForceParcelle` | `executerParcelleVirtuelle == true` | `executerParcelleVirtuelle` |
| `surfaceHectareForceParcelle` | `executerParcelleVirtuelle == true` | `executerParcelleVirtuelle` |

## Types de paramètres

| Type | Ce qu'il porte |
|---|---|
| `BOOL` | vrai ou faux — la forme de la grande majorité des drapeaux de sortie |
| `STRING` | chaîne libre, ou identifiant à choisir dans les données du projet |
| `INT` | entier |
| `FLOAT` | réel |
| `LIST` | liste de chaînes |
| `EXPRESSION` | expression GAML évaluée par le launcher, non saisissable |

!!! note "Voir aussi"

    - [Les sorties du modèle](sorties.md) — ce que les drapeaux commandent
    - [Les fichiers d'entrée](fichiers-entree.md) — ce que les activations rendent obligatoire
    - [L'API REST](api-rest.md) — les routes qui lisent et écrivent ces paramètres
    - [Glossaire](glossaire.md)
