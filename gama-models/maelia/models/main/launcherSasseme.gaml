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

model launchersasseme

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

experiment simulationBase type: gui {

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
	parameter 'anneeDebutSimulation : ' 		var: anneeDebutSimulation 		<- 2018; //update
	// nombre d'années de simulation
	parameter 'nbAnneesSimulation : ' 			var: nbAnneesSimulation 		<- 2; //update
	
	// identifiant simulation, permet de personnaliser le nom du répertoire de sortie (<nomDecoupageZonePourLectureFichiers>_<nomSimulation>_horodatage)
	parameter 'nomSimulation : ' 				var: nomSimulation 				<- "";

	// nom territoire (un répertoire du même nom doit se trouver dans includes/)
	parameter 'nomDecoupageZonePourLectureFichiers : ' 	var: nomDecoupageZonePourLectureFichiers 	<- 'includes_sasseme'; //update
	
	// simulation sur un sous-ensemble de ZH (Zones Hydrographiques)
	parameter 'simulationSurZH : '		 		var: executerModeleSurUneZH 	<- false;
	// si oui liste des id de ZH à simuler (exemple ["549","3420"])
	parameter 'idZHASimuler : '				 	var: listNomsZHsDecoupageZone 	<- ["SSM1"]; //["549","3420"];  //["2402","2265","193","192","575","115","114","183","1681","1680","4280","4653","4422","4295","2045","2044","3451","3450","2040","2043","2039","2407","2398","1600","574"];

	// simulation sur une seule exploitation
	parameter 'simulationSurExploitation : ' 	var: executerUnSeulAgriculteur 	<- false; //update
	// si oui id de l'exploitation à simuler
	parameter 'idExploitationASimuler : ' 		var: idExploitationAexecuter 	<- "SSM1-0001";

	// simulation sur un ensemble d'exploitations (JV 131222 a fusionner avec une seule exploit)
	parameter 'simulationSurEnsembleExploitations : ' 	var: executerSurEnsembleExploit 	<- false; //update
	// si oui liste d'id d'exploitations à simuler
	parameter 'idExploitationsASimuler : ' 		var: listIdExploitationAexecuter 	<- ["SSM1-0001","SSM1-0002"];

	// simulation sur une seule parcelle	
	parameter 'simulationSurParcelle : '	 	var: executerUneSeuleParcelle 	<- true;
	// si oui id de la parcelle à simuler	
	parameter 'idParcelleASimuler : ' 			var: nomParcelleAffichee 		<- '19_001'; //update
	
	// nom du scénario climatique pour les données météo projetées qui doivent se trouver dans /modeleCommun/simulee/nomScenarioClimatique
	parameter 'nomScenarioClimatique :'			var: nomScenarioClimatique		<- "";
	// utiliser les mêmes données météo partout ?
	parameter 'utiliserMemeMeteoPartout : '		var: utiliserMemeDonnesMeteoPartout 	<- false;
	// si oui id du point de météo unique
	parameter 'idPointMeteoUnique :'			var: idPointMeteoUnique					<- "3994";
	
    // Paramètres pour ID de simu dans l'API -- Ajout Renaud 01/09/22 pour execution via API  // TEST API Renaud 150922
    parameter 'idSimulationAPI'                    var: idSimulationAPI <- "";
    
    // mode verbeux: affichage d'informations complémentaires sur la console (débogage)
	parameter 'modeVerbeux :'					var: verboseMode						<- true; //update
	
	
 /* ---------------------------------- PARAMETRES MODELE HYDROLOGIQUE ------------------------------------------------------------------*/

 	// exécuter un modèle hydrologique ?
	parameter 'executerModeleHydrographique : ' 		var: executerModeleHydrographique 			<- false; //update
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
	parameter 'forcerSemisCI :'							var: forcerSemisCI							<-false;

	// prise en compte des contraintes de main d'oeuvre
	parameter 'avecContrainteDeMainOeuvre : '          	var: avecContrainteDeMainOeuvre      		<- false;	

	// présence d'ITK avec plusieurs opérations de travail du sol ou de fertilisation dans l'année 
	parameter 'plusieursTravauxDuSolParITK : '			var: plusieursTravauxDuSolParITK			<- false;
	parameter 'plusieursFertilisationsParITK : '		var: plusieursFertilisationsParITK			<- false;
	parameter 'plusieursTraitementsPhytoParITK : '		var: plusieursTraitementsPhytoParITK		<- false;

	// Adaptation de la fertilisation par rapport à la minéralisation
	parameter 'Adaptation de la fertilisation'			var: adaptationFertilisation				<- "reliquat"; // simple (adaptationFertilisation Renaud 160922)

	// prise en compte des îlots hors zone
	parameter 'avecIlotsHorsZone : ' 					var: avecIlotsHorsZone 						<- false;

	// choix du modèle de croissance de plante (Simple ou AqYield ou AqYieldNC)
	parameter 'nomChoixModeleCroissancePlante : ' 		var: nomChoixModeleCroissancePlante 		<- 'AqYieldNC';//update

	// choix du modèle de croissance de prairie (AqYield ou HerbSim)
	// AqYield: jour de récolte spécifié dans fichier règles de décisions
	// HerbSim: jour de récolte inféré (première OT de l'ITK suivant)
	parameter 'nomChoixModeleCroissancePrairie : '		var: nomChoixModeleCroissancePrairie		<- 'AqYield';
		
	// simulation de l'irrigation
	parameter 'isIrrigationSimulee : ' 					var: isIrrigationSimulee 					<- true;		
	// si oui: choix du modèle d'irrigation (Simple, GroupeIrrigation) attention: modèle Simple obligatoire si exécuté sur une seule parcelle
	parameter 'nomChoixModeleIrrigation : ' 			var: nomChoixModeleIrrigation 				<- 'Simple';

	// à chaque scénario XX doit correspondre un fichier /modeleAgricole/marcheAgricole/prixVentesXX.csv
	parameter 'liste des scénarios de prix de vente des cultures' var: listScenarioPrix 			<- ['SC1']; //['SC1','SC2','SC3','SC4','SC5'];
	parameter 'nom du scenario de prix principal' 		var: scenarioDePrixPrincipal 				<- 'SC1'; //'SC3';

	// préfixe permettant d'identifier les cultures utilisées comme couverts intermédiaires
	parameter 'préfixe culture couvert intermédiaire'	var: PREFIXE_CI								<- 'ci-';
	
	// remplacement des ITK manquants par des ITK similaires ?
	parameter 'remplacement ITK manquants'				var: remplacerItkManquants					<- false;

	// associer à l'îlot une zone météo moyenne agrégée à l'échelle de la ZH ?
	// si oui: l'îlot est associé à une zone météo agrégée à l'échelle de la ZH
	// si non: l'îlot est associé à la zone météo non agrégée dont il intercepte la plus grande surface
	parameter 'associerIlotMeteoZH :'					var: associerIlotMeteoZH					<- false;

	
	parameter 'Séquence(s) à optimiser agricole : '		var: sequences_a_optimiser					<- "";

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
	parameter 'executerBarrage : ' 						var: executerBarrage 						<- true;	
	
	// accéleration du tour d'eau en cas de restriction
	parameter 'accelerationTourEauSiRestriction'		var: accelerationTourEauSiRestriction		<- false;


 /* ---------------------------------- SORTIES ------------------------------------------------------------------*/
	
	// écrire les fichiers de sortie ?	
	parameter 'executerEcritureFichiers : ' 			var: executerEcritureFichiers 				<- true; //update
	
	// sorties eau (nécessite AqYield ou AqYieldNC)
	parameter "sorties eau"								var: sorties_eau							<- true;

	// sorties azote et carbone/GES (nécessite AqYieldNC)
	parameter "sorties azote"							var: sorties_azote							<- true; //update
	parameter "sorties carbone et GES"					var: sorties_carboneGES						<- true; //update
	
	parameter "sorties retenues"						var: sorties_retenues						<- false;
	parameter "sorties barrages"						var: sorties_barrages						<- false;
	
	// liste des agriculteurs et des parcelles à suivre pour les sorties concernées	
	parameter 'listAgriASuivre : ' 						var: listAgriASuivre 						<-[];  //['344877','345341','346156','346838','345630','345225','346823','347327','345857','344736','343392','345120','344376','344467','343607','344483','345756','344630','345039','344464','345772','345459','346630','343768','343023','347505','343772','343677','344156','345099','347320','345234','342842','347130','190567','345215','346058','346472','346646','347312','343329','343505','343770','346680','343729','342973','343409','346530','345611','343321','344675','346673','343610','344226','345593','343078','344442','345259','345343','344095','343658','343086','347174','347533','347180','345041','344491','346591','346048','190428','346878','345509','343805','343020','346374','346136','343700','345530','343968','343910','343180','345363','345314','346991','343243','343251','344590','344399','344329','343200','346195','345121','344061','345539','345355','344611','344517','342987','344342','346790','345851','344532','346040','345458','346867','346683','346239','346222','346879','347183','343774','343500','346055','343057','347498','345586','345206','345937','343193','346872','346318','345297','346763','347472','347248','347617','346504','343149','344938','347019','345284','346783','343638','343368','345952','346440','344201','347155','344023','345211','347441','344963','345592','347120','347249','346881','347325','346387','345720','345262','346199','345283','345351','346215','343966','345652','345714','346045','346619','346919','347507','346276','346807','346252','343137'] ;
	parameter 'listParcellesASuivre : ' 				var: listParcellesASuivre 					<- ['21_001'];//update
	
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
	parameter 'Liste parcelles sorties AqYield' 	var: listParcellesPourSortiesAqYield <- ['20_001']; //update
	parameter 'Sortie eva, trmax, trreelle ITK ZH'	var: aqYield_eva_trmax_trr_ITK_ZH	<- false;
	parameter 'debug_fusion_AqYieldNC'				var: debug_fusion_AqYieldNC			<- false;
	parameter 'Sorties AqYield NC'					var: sortiesAqYieldNC <-true; //updare
	parameter 'Sortie N_lixi_typeExploitation '		var: N_lixi_typeExploitation <- false;
	parameter 'Sortie N_total_eqC02_typeExploitation'	var: N_total_eqC02_typeExploitation <- false;
	parameter 'Sortie N_Cstock_Parcelles'			var: N_Cstock_Parcelles <- true;//update
	parameter 'Sortie engrais_utilises_territoire'	var: engrais_utilises_territoire <- false;
	parameter 'Sortie eqCO2_emissions_NC_Parcelles'	var: eqCO2_emissions_NC_Parcelles <- false;
	parameter 'Sortie N_N2O_Parcelles'				var: N_N2O_Parcelles <- false;
	parameter 'Sortie N_NH3_Parcelles'				var: N_NH3_Parcelles <- false;
	parameter 'Sortie N_Nmin_som_res_Parcelles'		var: N_Nmin_som_res_Parcelles <- false;
	parameter 'Sortie N_QNfix_Parcelles'			var: N_QNfix_Parcelles <- false;
	parameter 'Sortie tpsWFerti_Parcelles'			var: tpsWFerti_Parcelles <- false;
	parameter 'Sortie prixFerti_Parcelles'			var: prixFerti_Parcelles <- false;
	parameter 'Sortie recolteParcelles'				var: recolteParcelles <- false;
	parameter 'Sortie eqCO2_synthesis_Parcelles'	var: eqCO2_synthesis_Parcelles <- false;
	parameter 'Sortie N_GES_Parcelles'				var: N_GES_Parcelles <- true; //update
	parameter 'Sortie N_lixi_Parcelles'				var: N_lixi_Parcelles <- true; //update
	
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
	parameter 'Suivi détaillé des OT par parcelle : '					var: suiviOTParParcelle					<- true; //update
	parameter 'Suivi detaille des OT par parcelle avec duree : '		var: suiviOTParParcelleTemps			<- false;
	parameter 'Suivi des OT semis, irrigation, récolte + humidité : '	var: suiviOTParParcelle_humidite		<- false;
	// listOT pour inclure toutes les OT, attention plus d'OT -> plus lent
	parameter 'liste des OT a suivre en sortie' 						var: listOTASuivreEnSortie 				<- listOT; //["IRRIGATION", "RECOLTE", "SEMIS", "FAUCHE"];
	
	parameter "Plan épandage "											var: plan_epandage_actif				<- false;

	float seed <- 354.1;

	
	output {   

	display Culture autosave: false type: java2D {  			
			// Impact de l'eau du sol sur la culture
		chart name: 'Eau dans le sol' size: {0.5, 0.25} position: {0.0, 0.0} type: series background: rgb('white') {
				//data 'kc' value: parcelleAqYieldNC(first(listeParcelles)).getKc() style: line color: rgb('blue');
				//data 'kc à floraison' value: parcelleAqYield(first(listeParcelles)).getKc_flo() style: line color: rgb('red');
				data 'Hm'      value: parcelleAqYieldNC(first(listeParcelles)).Hm style: line color: rgb('blue');
			}
		chart name: 'Stress hydrique' size: {0.5, 0.25} position: {0.0, 0.25} type: series background: rgb('white') {
				//data 'kc' value: parcelleAqYieldNC(first(listeParcelles)).getKc() style: line color: rgb('blue');
				//data 'kc à floraison' value: parcelleAqYield(first(listeParcelles)).getKc_flo() style: line color: rgb('red');
				data 'Stress hydrique (déficit de transpi.)' value: mean(list(cultureAqYieldNC) collect each.indiceSatifactionHydrique) style: line color: rgb('blue');
			}
			

		// 	Evolution de l'état de nutrition N de la culture
			chart name: "QNdemande" size: {0.5,0.5} position: {0, 0.5} type: series background: rgb('white') {
              data 'QN' value: first(list(cultureAqYieldNC) collect each.sommeTranspirationR) style: line color: rgb('blue');
}
            
            chart name: "Azote perdu" size: {0.5,0.5} position: {0.5,0.0} type: series background: rgb('white') {
                       data 'Nlosses (kg N/ha)'      value: parcelleAqYieldNC(first(listeParcelles)).Nlosses style: line color: rgb('red');
                       
                       
            }
            
            // SOC et GES
            chart name: "SOC %" size: {0.5,0.25} position: {0.5,0.5} type: series background: rgb('white') {
                       data 'SOC_perc (%)'      value: parcelleAqYieldNC(first(listeParcelles)).SOC_perc style: line color: rgb('brown');
            }
            
            chart name: "Emissions GES" size: {0.5,0.25} position: {0.5,0.75} type: series background: rgb('white') {
                       data 'bilan net de GES (kgeqCO2/ha)'      value: parcelleAqYieldNC(first(listeParcelles)).sorties_bilan_net_GES style: line color: rgb('brown');
            }

	}
	
	}
}


	

