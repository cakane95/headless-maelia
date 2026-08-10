/***************************************************************************
 * MAELIA - http://maelia-platform.inra.fr/
 *    Copyright (C) 2014-2015 
 *    INRA - UMR 1248 AGIR ;
 *    UniversitÈ Toulouse 1 Capitole - IRIT 
 *    CNRS - UMR 5563 GET
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program (Maelia/Licence_gpl_v3.txt).  If not, see 
 * <http://www.gnu.org/licenses/>.
***************************************************************************/
/**
 *  launcherBase
 *  Author: Jean Villerd
 *  Description: Launcher incluant l'ensemble des paramètres ajustables (version 1.3.0 et supérieures)
 */

model launcherBase

import "../modeleCommun/contourZoneMaelia.gaml"

global {
	geometry shape <- envelope(file(contourZMShape));

	init{
		do initGlobal;
	}  
	reflex reflexe_global{
		do schedulerGlobal;
	}	
}

experiment simulationBase type: gui benchmark:false {

 /* ---------------------------------- CHEMINS SELON EXECUTION EN LOCAL OU SUR CLUSTER ------------------------------------------------------------------
  * 	ne modifier que le booléen executerSurCluster, pas les chemins
  * 	si exécution sur cluster, spécifier les chemins en dur dans le XML du ExperimentPlan dans le répertoire headless, en attendant une solution plus propre...
  * 	laisser ces paramètres en haut du launcher
  */		
	parameter 'executerSurCluster: ' var: executerSurCluster <- false;
	parameter 'cheminRacineMaelia' var: cheminRacineMaelia <- mapCheminRacineMaeliaSelonClusterOuPas[executerSurCluster];
	parameter 'cheminModeleVersDonnees' var: cheminModeleVersDonnees <- cheminRacineMaelia + "includes/";
	parameter 'cheminSorties' var: cheminRelatifDuDossierDeSortieDeSimulation <- cheminRacineMaelia + "models/main/log";

 /* ---------------------------------- PARAMETRES GENERAUX ------------------------------------------------------------------*/
 	// année de début de simulation
	parameter 'anneeDebutSimulation : ' 		var: anneeDebutSimulation 		<- 2019;
	// nombre d'années de simulation
	parameter 'nbAnneesSimulation : ' 			var: nbAnneesSimulation 		<- 3;
	
	// identifiant simulation, permet de personnaliser le nom du répertoire de sortie (<nomDecoupageZonePourLectureFichiers>_<nomSimulation>_horodatage)
	parameter 'nomSimulation : ' 				var: nomSimulation 				<- "";

	// nom territoire (un répertoire du même nom doit se trouver dans includes/)
	parameter 'nomDecoupageZonePourLectureFichiers : ' 	var: nomDecoupageZonePourLectureFichiers 	<- 'terrainTest';
	
	// simulation sur un sous-ensemble de ZH (Zones Hydrographiques)
	parameter 'simulationSurZH : '		 		var: executerModeleSurUneZH 	<- false;
	// si oui liste des id de ZH à simuler (exemple ["549","3420"])
	parameter 'idZHASimuler : '				 	var: listNomsZHsDecoupageZone 	<- [""];

	// simulation sur une seule exploitation
	parameter 'simulationSurExploitation : ' 	var: executerUnSeulAgriculteur 	<- false;
	// si oui id de l'exploitation à simuler
	parameter 'idExploitationASimuler : ' 		var: idExploitationAexecuter 	<- "mineral_beauce_29";

	// simulation sur un ensemble d'exploitations (JV 131222 a fusionner avec une seule exploit)
	parameter 'simulationSurEnsembleExploitations : ' 	var: executerSurEnsembleExploit 	<- false;
	// si oui liste d'id d'exploitations à simuler
	parameter 'idExploitationsASimuler : ' 		var: listIdExploitationAexecuter 	<- ["expl_13","expl_15"];

	// simulation sur une seule parcelle	
	parameter 'simulationSurParcelle : '	 	var: executerUneSeuleParcelle 	<- false;
	// si oui id de la parcelle à simuler	
	parameter 'idParcelleASimuler : ' 			var: nomParcelleAffichee 		<- 'beauce_48_1';
	
	// nom du scénario climatique pour les données météo projetées qui doivent se trouver dans /modeleCommun/simulee/nomScenarioClimatique
	parameter 'nomScenarioClimatique :'			var: nomScenarioClimatique		<- "rcp8.5";
	// utiliser les mêmes données météo partout ?
	parameter 'utiliserMemeMeteoPartout : '		var: utiliserMemeDonnesMeteoPartout 	<- false;
	// si oui id du point de météo unique
	parameter 'idPointMeteoUnique :'			var: idPointMeteoUnique					<- "3994";
	
    // Paramètres pour ID de simu dans l'API -- Ajout Renaud 01/09/22 pour execution via API  // TEST API Renaud 150922
    parameter 'idSimulationAPI'                    var: idSimulationAPI <- "";
    
    // mode verbeux: affichage d'informations complémentaires sur la console (débogage)
	parameter 'modeVerbeux :'					var: verboseMode						<- false;
	
	
	// Paramètres pour ID de simu dans l'API -- Ajout Renaud 01/09/22 pour execution via API
//	parameter 'executionViaAPI' 				var: executionViaAPI <- true;
//	parameter 'idSimulationAPI'					var: idSimulationAPI <- "default";
	 /* ---------------------------------- PARAMETRES MODELE HYDROLOGIQUE ------------------------------------------------------------------*/

 	// exécuter un modèle hydrologique ?
	parameter 'executerModeleHydrographique : ' 		var: executerModeleHydrographique 			<- false;
	// si oui nom du modèle hydrologique à exécuter (Simple ou SWAT)
	parameter 'nomChoixModeleHydrographique : ' 		var: nomChoixModeleHydrographique 			<- 'SWAT'; // Simple  SWAT
	
		// si SWAT: paramètres de calibration, ci-dessous valeurs de la calibration de janvier 2020 sur bassin de la Leyre, jeu optimal 2_2_4_2  
		parameter 'surLag: coefficientSurfaceRuissellementLag'			var: coefficientSurfaceRuissellementLag			<- 4.0;
		parameter 'deltaGw: retardEntreSortiSolEtEntreeAquifereGlobal'	var: retardEntreSortiSolEtEntreeAquifereGlobal	<- 31.0;
		parameter 'betaDeep: coefPercolationVersAquifereProfondGlobal'	var: coefPercolationVersAquifereProfondGlobal	<- 1.0;
		parameter 'nTerrain: coefficientManningTerrain'					var: coefficientManningTerrain					<- 0.12;
		
	// simulation des prélèvements et des rejets ?
	parameter 'isPrelevementEtRejetSimules : ' 			var: isPrelevementEtRejetSimules 			<- true;
	// si oui, faut-il affecter un équipement de prélèvement à un îlot irrigué qui n'en a pas (cas où on simule sur un sous-ensemble de ZH dont l'îlot fait partie mais pas l'équipement) 
	parameter 'affecterEqIrrSiInexistant :'				var: affecterEqIrrSiInexistant				<- true;
	
	// id du point de référence dont on affiche le débit (pas utilisé dans le code, seulement dans certains launchers avec graphiques -> à virer)	
	parameter 'nomPtRefAffichee : ' 					var: nomPtRefAffichee 						<- "O5882510";
		
	// liste de ZH dont le débit est complémenté -> existe aussi listNomsZHsDebitForcee on l'ajoute ? voit pas trop la différence (cf zoneHydrographique.initialisationDebitsEntresZonesHydrographiques)
	parameter 'listNomsZHsDebitComplement : ' 			var: listNomsZHsDebitComplement 			<- ["549"]; 

	// liste des ZH éxutoires (pour hierarchisation des ZH dans zoneHydrographique.creationMapArbreZHEtNiveau) -> dépend de l'include !!
	parameter 'listeExutoiresZoneMaelia : ' 			var: listeExutoiresZoneMaelia 				<- ["110","208"];

	// id des ressources en eau infinies: leur volume est forcé à quantiteEauMaxDispoAgri dans ressourceEnEau.miseAZero -> dépend de l'include !!
	parameter 'ID_RESSOURCES_INFINIES : ' 				var: ID_RESSOURCES_INFINIES 				<- ["SURF_EAU0000000025689668"];


 /* ---------------------------------- PARAMETRES MODELE AGRICOLE ------------------------------------------------------------------*/

	// exécuter un modèle agricole
	parameter 'executerModeleAgricole : ' 				var: executerModeleAgricole 				<- true;

	// choix du modèle d'assolement (Donnees ou FonctionsDeCroyances)
	parameter 'nomChoixAssolement : ' 					var: nomChoixAssolement 					<- 'Donnees';
	// si assolement par données, année de référence RPG
	parameter 'anneeDeReferenceRPG'						var: anneeDeReferenceRPG					<- 2014; //2014; //2012;	

	// recherche d'un ITK alternatif en cas d'impossibilité de semer (ou bien forçage du semis) 
	parameter 'activerITKAlternatif :'					var: activerITKalternatif					<- false;

	// faut-il forcer le semis d'un CI (automatiquement à faux si ITK activerITKalternatif à vrai)
	parameter 'forcerSemisCI :'							var: forcerSemisCI							<- false;

	// prise en compte des contraintes de main d'oeuvre
	parameter 'avecContrainteDeMainOeuvre : '          	var: avecContrainteDeMainOeuvre      		<- true;	

	// présence d'ITK avec plusieurs opérations de travail du sol ou de fertilisation dans l'année 
	parameter 'plusieursTravauxDuSolParITK : '			var: plusieursTravauxDuSolParITK			<- true;
	parameter 'plusieursFertilisationsParITK : '		var: plusieursFertilisationsParITK			<- true;
	parameter 'plusieursTraitementsPhytoParITK : '		var: plusieursTraitementsPhytoParITK		<- true;

	// Adaptation de la fertilisation par rapport à la minéralisation
	parameter 'Adaptation de la fertilisation'			var: adaptationFertilisation				<- ""; //  "corpen" ou "" (adaptationFertilisation Renaud 160922)
	parameter 'Profondeur temporelle du bilan CORPEN'			var: corpenProfondeurTemporelle				<- 3; 

	// Niveau de gestion des stocks d'engrais (exploitation / territoire / filiere)
	parameter 'Niveau scalaire de gestion des stocks d engrais'	var: gestionStocksEngrais 			<- "territoire"; //territoire exploitation

	// prise en compte des îlots hors zone
	parameter 'avecIlotsHorsZone : ' 					var: avecIlotsHorsZone 						<- false;

	// choix du modèle de croissance de plante (Simple ou AqYield ou AqYieldNC)
	parameter 'nomChoixModeleCroissancePlante : ' 		var: nomChoixModeleCroissancePlante 		<- 'AqYieldNC';

	// choix du modèle de croissance de prairie (AqYield ou HerbSim)
	// AqYield: jour de récolte spécifié dans fichier règles de décisions
	// HerbSim: jour de récolte inféré (première OT de l'ITK suivant)
	parameter 'nomChoixModeleCroissancePrairie : '		var: nomChoixModeleCroissancePrairie		<- 'HerbSimNC';
	parameter 'Choix fonction temp dénit : ' 			var: denit_fTemp_option					<- "Stics";   // "Stics" or "SystN" 
		
	// simulation de l'irrigation
	parameter 'isIrrigationSimulee : ' 					var: isIrrigationSimulee 					<- true;		
	// si oui: choix du modèle d'irrigation (Simple, GroupeIrrigation) attention: modèle Simple obligatoire si exécuté sur une seule parcelle
	parameter 'nomChoixModeleIrrigation : ' 			var: nomChoixModeleIrrigation 				<- 'Simple';

	// à chaque scénario XX doit correspondre un fichier /modeleAgricole/marcheAgricole/prixVentesXX.csv
	parameter 'liste des scénarios de prix de vente des cultures' var: listScenarioPrix 			<- ['']; //['SC1','SC2','SC3','SC4','SC5'];
	parameter 'nom du scenario de prix principal' 		var: scenarioDePrixPrincipal 				<- ''; //'SC3';

	// préfixe permettant d'identifier les cultures utilisées comme couverts intermédiaires
	parameter 'préfixe culture couvert intermédiaire'	var: PREFIXE_CI								<- 'ci';
	
	// remplacement des ITK manquants par des ITK similaires ?
	parameter 'remplacement ITK manquants'				var: remplacerItkManquants					<- false;

	// associer à l'îlot une zone météo moyenne agrégée à l'échelle de la ZH ?
	// si oui: l'îlot est associé à une zone météo agrégée à l'échelle de la ZH
	// si non: l'îlot est associé à la zone météo non agrégée dont il intercepte la plus grande surface
	parameter 'associerIlotMeteoZH :'					var: associerIlotMeteoZH					<- false;

	
	// paramètres sol
	parameter 'fraction SOM inerte fonction du %MO '	var: option_Finert_calc					<- false; //Si true : détermination du Finert en fonction du % de MO du sol, équation Hugues Clivot 26/11/2024) ; Si false :  variable forcée (voir typeDeSol.gaml dans les 2 cas)
	
	// stress climatique (gel, échaudage)
	parameter 'Gel et échaudage'						var: avecStressClimatique				<- false;
	
	// paramétrage d'une parcelle virtuelle
    parameter 'executerParcelleVirtuelle : ' 			var: executerParcelleVirtuelle 				<- false;
    parameter 'rotationForceeParcelle : '				var: rotationForceeParcelle                 <- 'colza-precPauvre_CP-precRiche_feverole_CP-precRiche'; // séquence article = 'colza-precPauvre_CP-precRiche_feverole_CP-precRiche' // Seq pour figure N min / N lix = colza-precPauvre_CP-precRiche_ciCruciCourt_maisDP_CP-precMais_ciCruciCourt_feverole_CP-precRiche_orgeh-precPauvre_colza-precPauvre_CP-precRiche
	parameter 'gestionPaillesForceeParcelle : '			var: gestionPaillesForceeParcelle			<- ''; // Si tout est restitué, possibilité de laisser vide
    parameter '[PARAM] idSdcForce : '                   var: idSdcForce                             <- 'all';
    parameter '[PARAM] typeDeSolForceParcelle : '       var: typeDeSolForceParcelle                 <- 'luvisols plateaux inferieurs'; // rendosols, calcosols et colluviosols  | luvisols plateaux inferieurs | sols heterogenes de pente
    parameter '[PARAM] surfaceHectareForceParcelle : '  var: surfaceHectareForceParcelle            <- 10.0;

	parameter 'executerModeleElevage : '				var: executerModeleElevage					<- false;

 /* ---------------------------------- PARAMETRES MODELE FILIERE ------------------------------------------------------------------*/
    
 	
 /* ---------------------------------- PARAMETRES MODELE NORMATIF ------------------------------------------------------------------*/

	// exécuter le modèle normatif
	parameter 'executerModeleNormatif : ' 				var: executerModeleNormatif 				<- false;

	// simulation des barrages
	parameter 'executerBarrage : ' 						var: executerBarrage 						<- false;	
	
	// accéleration du tour d'eau en cas de restriction
	parameter 'accelerationTourEauSiRestriction'		var: accelerationTourEauSiRestriction		<- false;


 /* ---------------------------------- SORTIES ------------------------------------------------------------------*/
	
	// écrire les fichiers de sortie ?	
	parameter 'executerEcritureFichiers : ' 			var: executerEcritureFichiers 				<- true;

	// nombre de décimales pour les nombres réels
	parameter "nb décimales sorties"						var: nb_decimales_sorties				<- 2;
	
	// sorties eau (nécessite AqYield ou AqYieldNC)
	parameter "sorties eau"								var: sorties_eau							<- true;

	// sorties azote et carbone/GES (nécessite AqYieldNC)
	parameter "sorties azote"							var: sorties_azote							<- true;
	parameter "sorties carbone et GES"					var: sorties_carboneGES						<- true;
	
	parameter "sorties retenues"						var: sorties_retenues						<- false;
	parameter "sorties barrages"						var: sorties_barrages						<- false;
	
	// liste des agriculteurs et des parcelles à suivre pour les sorties concernées	
	parameter 'listAgriASuivre : ' 						var: listAgriASuivre 						<- ['344877','345341','346156','346838','345630','345225','346823','347327','345857','344736','343392','345120','344376','344467','343607','344483','345756','344630','345039','344464','345772','345459','346630','343768','343023','347505','343772','343677','344156','345099','347320','345234','342842','347130','190567','345215','346058','346472','346646','347312','343329','343505','343770','346680','343729','342973','343409','346530','345611','343321','344675','346673','343610','344226','345593','343078','344442','345259','345343','344095','343658','343086','347174','347533','347180','345041','344491','346591','346048','190428','346878','345509','343805','343020','346374','346136','343700','345530','343968','343910','343180','345363','345314','346991','343243','343251','344590','344399','344329','343200','346195','345121','344061','345539','345355','344611','344517','342987','344342','346790','345851','344532','346040','345458','346867','346683','346239','346222','346879','347183','343774','343500','346055','343057','347498','345586','345206','345937','343193','346872','346318','345297','346763','347472','347248','347617','346504','343149','344938','347019','345284','346783','343638','343368','345952','346440','344201','347155','344023','345211','347441','344963','345592','347120','347249','346881','347325','346387','345720','345262','346199','345283','345351','346215','343966','345652','345714','346045','346619','346919','347507','346276','346807','346252','343137'] ;
	parameter 'listParcellesASuivre : ' 				var: listParcellesASuivre 					<- ['082-5653275_00','082-5661385_00', '082-5658658_03'];
	
	/* ---------------------------------- ASSOLEMENT ---------------------------------------------------------------- */
	parameter 'Sortie Assolement_SDC : '			var: Assolement_SDC 				<- false;
	parameter 'Sortie Assolement_itk : '			var: Assolement_itk 				<- false;
	parameter 'Sortie Assolement_espece : '			var: Assolement_espece 				<- false;
	parameter 'Sortie ECO_espece : '				var: ECO_espece						<- false;
	parameter 'Sortie ECO_itk : '					var: ECO_itk 						<- false;
	parameter 'Sortie ECO_exploitationType : '		var: ECO_exploitationType 			<- false;
	parameter 'Sortie ECO_exploitationDetail : '	var: ECO_exploitationDetail 		<- false;
	parameter 'Sortie ECO_SDCRef : '				var: ECO_SDCRef 					<- false;
	parameter 'Sortie ECO_coutIrrigationIlot : '	var: ECO_coutIrrigationIlot 					<- false;
	parameter 'Sortie AqYield parcelles' 			var: variablesAqYieldSurParcellesSpecifiees <- false;
	parameter 'Sortie AqYield parcelles light' 		var: variablesAqYieldSurParcellesSpecifiees_light <- false;
	parameter 'Liste parcelles sorties AqYield' 	var: listParcellesPourSortiesAqYield <- ['082-5650603_00'];
	parameter 'Sortie eva, trmax, trreelle ITK ZH'	var: aqYield_eva_trmax_trr_ITK_ZH	<- false;
	parameter 'debug_fusion_AqYieldNC'				var: debug_fusion_AqYieldNC			<- false;
	parameter 'Sorties AqYield NC'					var: sortiesAqYieldNC <- false;
	parameter 'Sortie N_lixi_typeExploitation '		var: N_lixi_typeExploitation <- false;
	parameter 'Sortie N_total_eqC02_typeExploitation'	var: N_total_eqC02_typeExploitation <- false;
	parameter 'Sortie N_Cstock_Parcelles'			var: N_Cstock_Parcelles <- false;
	parameter 'Sortie engrais_utilises_territoire'	var: engrais_utilises_territoire <- false;
	parameter 'Sortie engrais_utilises_exploitation'	var: engrais_utilises_exploitation <- true;
	parameter 'Sortie eqCO2_emissions_NC_Parcelles'	var: eqCO2_emissions_NC_Parcelles <- false;
	parameter 'Sortie N_N2O_Parcelles'				var: N_N2O_Parcelles <- false;
	parameter 'Sortie N_NH3_Parcelles'				var: N_NH3_Parcelles <- false;
	parameter 'Sortie N_Nmin_som_res_Parcelles'		var: N_Nmin_som_res_Parcelles <- false;
	parameter 'Sortie N_Nmin_total'					var: N_Nmin_total_Parcelles <- false;
	parameter 'Sortie N_QNfix_Parcelles'			var: N_QNfix_Parcelles <- false;
	parameter 'Sortie tpsWFerti_Parcelles'			var: tpsWFerti_Parcelles <- false;
	parameter 'Sortie prixFerti_Parcelles'			var: prixFerti_Parcelles <- false;
	parameter 'Sortie recolteParcelles'				var: recolteParcelles <- false;
	parameter 'Sortie eqCO2_synthesis_Parcelles'	var: eqCO2_synthesis_Parcelles <- false;
	parameter 'Sortie N_GES_Parcelles'				var: N_GES_Parcelles <- false;
	parameter 'Sortie N_lixi_Parcelles'				var: N_lixi_Parcelles <- false;
	
	parameter 'Sortie journalière HerbSimNC'		var: suivi_journalier_1parc_HerbSimNC <- false;
	
	/* ---------------------------------- BILAN NC ------------------------------------------------------------ */
	parameter 'Sortie Ajout_Pools_Residus'			var: suivi_ajout_pools_residus <- true; // NR sortie pool
	
	/* ---------------------------------- BILAN HYDRIQUE ------------------------------------------------------------ */
	parameter 'Sortie DrainIlot : '					var: DrainIlot 						<- false;
	parameter 'Sortie DrainIlot mensuel: '			var: DrainIlot_mois					<- false;
	parameter 'Sortie DrainIlot bimensuel: '		var: DrainIlot_quinzaine			<- false;
	parameter 'Sortie DrainIlotDetail : '			var: DrainIlotDetail 				<- false;		
	parameter 'Sortie DrainIlotDetail mensuel: '	var: DrainIlotDetail_mois			<- false;		
	parameter 'Sortie DrainIlotDetail bimensuel: '	var: DrainIlotDetail_quinzaine		<- false;		
	parameter 'Irrigation par Agri: '              	var: IrrigationParAgri              <- false;
	parameter 'Travail Irrigation par agri: '       var: travailParAgri_Irrigation      <- false;
    parameter 'Travail Irrigation : '               var: DetailsGroupeIrrigation        <- false;
    parameter 'Irrigation debug'					var: irrigationDebug				<- false;
	parameter 'Irrigation par parcelle : '		 	var: IrrigationParcelle			 	<- false;
	
	/* ---------------------------------- ECONOMIE ------------------------------------------------------------------ */
	parameter 'Sortie RDT_itk : '					var: RDT_itk 						<- false;
	parameter 'Sortie RDT_sol_itk : '				var: RDT_sol_itk 					<- false;
	parameter 'Sortie RDT_espece : '				var: RDT_espece 					<- false;
	parameter 'Sortie RDT_parcelle_espece : '		var: RDT_parcelle_espece 					<- false;

	/* ---------------------------------- BIODIVERSITE ------------------------------------------------------------------ */
	parameter 'Sortie i-Bio : '					var: sorties_iBio 						<- false;

	/* ---------------------------------- HYDROLOGIE ---------------------------------------------------------------- */
	parameter 'Sortie debit aux points STH selectione : '	var: DebistSTH 				<- false;
	parameter 'Sortie debit pour tous les points STH : '	var: Debit 					<- false;
	//
	/* ---------------------------------- PRELEVEMENTS -------------------------------------------------------------- */
	parameter 'Sortie Prelevements Territoire : '				var: Prelevements 					<- false;
	parameter 'Sortie Prelevements par ZH : '					var: PrelevementsZH 				<- false;
	parameter 'Sortie Prelevements par ZA : '					var: PrelevementsZA 				<- false;
	parameter 'Sortie Prelevements par Sol x ITK : '			var: Prelevements_sol_itk 			<- false;
	parameter 'Sortie Prelevements par Sol x Espece : '			var: Prelevements_sol_espece 		<- false;
	parameter 'Sortie Prelevements par Espece : '				var: Prelevements_espece 			<- false;
	parameter 'Sortie Prelevements par ZA x Espece : '			var: Prelevements_za_espece 		<- false;
	parameter 'Sortie Prelevements par ZA x Sol x Espece : '	var: Prelevements_za_sol_espece 	<- false;
	parameter 'Sortie Prelevements par ITK x Decoupage ilot : '	var: Prelevements_decoupage_itk 	<- false;
	parameter 'Sortie Prelevements par ITK x Decoupage PPA : '	var: Prelevements_decoupage_typePPA <- false;
	parameter 'Sortie Prelevements pour alimenter les canaux : 'var: Canaux 						<- false;
		
	/* ---------------------------------- NORMATIF ------------------------------------------------------------------ */	
	parameter 'Sortie Niveau de restriction par ZA : '			var: Restrictions 					<- false;
	parameter 'Sortie GestionnaireDeBarrage : '					var: GestionnaireDeBarrage 					<- false;
		
	/* ---------------------------------- OPÉRATIONS TECHNIQUES ----------------------------------------------------- */
	parameter 'Sortie debugSortie1parcelleAqYield : '					var: debugSortie1parcelleAqYield 		<- false;
	parameter 'Suivi de la realisation des operations techniques : '	var: suiviOT							<- false;
	parameter 'Suivi détaillé des OT par parcelle : '					var: suiviOTParParcelle					<- true;
	parameter 'Suivi detaille des OT par parcelle avec duree : '		var: suiviOTParParcelleTemps			<- false;
	parameter 'Suivi des OT semis, irrigation, récolte + humidité : '	var: suiviOTParParcelle_humidite		<- false;
	// listOT pour inclure toutes les OT, attention plus d'OT -> plus lent
	parameter 'liste des OT a suivre en sortie' 						var: listOTASuivreEnSortie 				<- listOT; //["IRRIGATION", "RECOLTE", "SEMIS", "FAUCHE"];

	parameter "Plan épandage "											var: plan_epandage_actif				<- false;

	float seed <- 354.1;
	
	output {   

		/* exemple carte
		display map type: java2D {	     //  autosave: true
			species contourZoneMaelia aspect: basic; 
	   		//species typeDeSol aspect: reserveUtileAffichage;  
	   		//species ilot aspect: basic2; 
	    	//species ilot aspect: cultureAspect;
	    	species parcelleAqYield aspect: cultureAspect;
	    	//species parcelleAqYield aspect: coefficientCulturalCulturePrincpaleAspect;  
	      	species agriculteurDonneesEntrees aspect: imageAspect;  
	    	//species lotAnimaux aspect: imageAspect;
	    	//text 'date' value: dateCour.getNomDetail() size: 0.08 position: { 23500 , 38000 } color: rgb ( 'black' );
	    	//text 'cycle' value: 'cycle : ' + int(time) size: 0.04 position: { 28000 , 40000 } color: rgb ( 'black' );	    		    	
	    }
		*/

		// exemples graphiques 
	      display Meteo type: java2D refresh: every(1#cycle) {     
		chart name: "Précipitation" size: {0.5,0.5} position: {0,0} type: series background: rgb('white') {
		            data 'Précipitations' value: mean(list(zoneMeteo) collect each.pluie) style: line color: rgb('blue');
		            //data 'temperature' value: mean(list(zoneMeteo) collect each.tMoy) style: line color: rgb('green');                    
		}
		
		chart name: "temperature moy" size: {0.5,0.5} position: {0,0.5} type: series background: rgb('white') {       
		            data 'temperature' value: mean(list(zoneMeteo) collect each.tMoy) style: line color: rgb('green');                                       
		      }
		      
		
		chart name: "temperature max" size: {0.5,0.5} position: {0.5,0} type: series background: rgb('white') {             
		            data 'temperature' value: mean(list(zoneMeteo) collect each.tMax) style: line color: rgb('red');                                   
		      }
		      
		chart name: "temperature min" size: {0.5,0.5} position: {0.5,0.5} type: series background: rgb('white') {           
		            data 'temperature' value: mean(list(zoneMeteo) collect each.tMin) style: line color: rgb('blue');                            
		      }                 
		}
		
		display map type: java2D {	     //  autosave: true
			species contourZoneMaelia aspect: basic; 
	   		//species typeDeSol aspect: reserveUtileAffichage;  
	   		//species ilot aspect: basic2; 
	    	species ilot aspect: cultureAspect; 
	    	//species parcelleAqYield aspect: coefficientCulturalCulturePrincpaleAspect; 
	    	species lotAnimaux aspect: imageAspect; 
	      	species agriculteurDonneesEntrees aspect: imageAspect;  
	    	//text 'date' value: dateCour.getNomDetail() size: 0.08 position: { 23500 , 38000 } color: rgb ( 'black' );
	    	//text 'cycle' value: 'cycle : ' + int(time) size: 0.04 position: { 28000 , 40000 } color: rgb ( 'black' );	    		    	
	    }
     
	}
}


	

