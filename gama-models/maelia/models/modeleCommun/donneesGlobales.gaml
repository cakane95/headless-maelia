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
 *  DonneesGlobales
 *  Author: Maroussia Vavasseur
 *  Description: Toutes les variables globales ainsi que le potentiel parametres de la simulation sont declares ici.
 */

model donneesGlobales

global{
	string versionMaelia <- "MAELIA_1.4.29_GAMA_2025-06";

	/*
	 * Choix parametres
	 */
	string DecoupageZoneMaelia <- 'ZoneMaelia' const: true; // Modele hydo
	string DecoupageAveyron <- 'Aveyron' const: true; // zone detude
	string Simple <- 'Simple' const: true; // Modele croissance plante / assolement / hydro /irrigation
	string GROUPE_IRRIGATION <- 'GroupeIrrigation' const: true; // Modele irrigation
	string AqYield <- 'AqYield' const: true; // Modele croissance plante
	string AqYieldNC <- 'AqYieldNC' const: true; // Modele croissance plante
	string PlanteETP <- 'PlanteETP' const: true; // Modele croissance plante
	string FonctionsDeCroyances <- 'FonctionsDeCroyances' const: true; // Modele assolement
	string Donnees <- 'Donnees' const: true; // Modele assolement / hydro
	string SWAT <- 'SWAT' const: true; // Modele hydo
	string Complexe <- 'Complexe' const: true;

	/*
	 * ************ Scenario ************ 
	 */	 	 
	//Choisir un scenario met a jour automatiquement les facteurs de changement
	string choixScenario <- 'Scenario 1';

    /*
     * ************ Paramètres activation API ************  // TEST API Renaud 150922
     */    
    string idSimulationAPI <- ""; // id de simulation propagé par l'API
	bool executionViaAPI <- false;
	/*
	 * ************ Facteurs de changement ************
	 * choixDefinitionDuVP : Pas encore defini
	 */	 	
	//Personaliser ses scenarios : Il est possible de choisi ses propres facteurs de changement
	string choixDefinitionDuVP <- 'Definition VP 1'; 
	
	/*
	 * ************ Parametres generaux de la simulation ************
	 * executerModele : Utiliser l'ihm pour les parametres
	 * executerModeleSurUneZH : Si true, cela signifie que la simulation se fera uniquement sur une ZH
	 * nomZHDecoupageZone : Nom de la ZH sur laquelle on execute le modele
	 * idDateDebutSimulation : Indentifiant de la date de debut de simulation sous la forme : JJMMAAAA (dans le cas ou le jour est < 10, on a JMMAAAA)
	 * idDateFinSimulation : Indentifiant de la date de fin de simulation sous la forme : JJMMAAAA (dans le cas ou le jour est < 10, on a JMMAAAA)
	 * afficheDateJournaliere : Dans la console on affiche ou pas la date
	 * afficherDetailInitialisation : Affiche ou non dans la console le detail des differents agents crees en cours.
	 * afficherDetailSimilation : Affiche ou non dans la console les parametres choisi pour la simulation en cours.
	 */	 	
	bool executerModele <- true; 
	string nomDecoupageZonePourLectureFichiers  <- 'ZoneMaelia'; // Aveyron
	bool executerModeleSurUneZH <- false;
	list listNomsZHsDecoupageZone <- ['O098'];  // O060   O098  O037  ['O029', 'O060', 'O064'];    O586
	list listNomsZHsDebitComplement <- ['O001'];
	list<string> listNomsZHsDebitForcee <- [];
	int anneeDebutSimulation <- 2000;
	int jourDebutSimulation <- 1;
	int moisDebutSimulation <- 8;
	int nbAnneesSimulation <- 19;
	bool afficheDateJournaliere <- true;	
	bool afficheDateComplete <- true;
	bool afficherDetailInitialisation <- true;
	bool afficherDetailSimilation <- true;
	string nomScenarioClimatique <- '';	
	bool utiliserMemeDonnesMeteoPartout <- false;
	string idPointMeteoUnique <- "3994";
	bool associerIlotMeteoZH <- false;
	bool verboseMode <- true; // massive writing on standard output
	bool itkParPrecedent <- false;
	bool remplacerItkManquants <- false; // JV 231121 voir SystemeDeCultureDeReference.getITK
	bool option_Finert_calc <- false;
	string initLogWarning <- ""; // chaine recevant le log des warnings de l'initialisation
		
	/*
	 * ************ Parametres des outputs ************
	 * executerEcritureFichiers : Prendre en compte ou non toute la partie output dans la simulation
	 */	
	bool executerEcritureFichiers <- true;
	list<string> listAgriASuivre <-[];
	list<string> listParcellesASuivre <-[];
	list<string> listParcellesPourSortiesAqYield <-[]; // JV 050820 pour output resultatsModeleAqYield.gaml
	string filePrelevement_decoupage_itk <- "" + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +	 "/modeleCommun/communes/communes-trimUG.shp" ;
	string VariableDecoupagePrelevement_decoupage_itk <- "NOM";
	string filePrelevement_decoupagePPA <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +	 '/modeleCommun/communes/communes-trimUG.shp' ;
	string VariableDecoupagePrelevement_decoupagePPA <- "NOM";
	int nb_decimales_sorties <- 10; // JV 080925 nombre de décimales dans les sorties standard issue #34
	
	/*
	 * ************ Parametres du modele agricole ************
	 * executerModeleAgricole : Prendre en compte ou non toute la partie traitement agricole dans la simulation
	 * nomChoixModeleAgricole : Choix de la complexite du modele agricole -> 	
	 * 			'Donnees' 	(l'agriculteur a un comportement basique) ou 
	 * 			'FonctionsDeCroyances' 	(l'agriculeteur a un comportement rationnel base sur la theroie des fonctions de croyances)
	 * nomChoixModeleCroissancePlante : Choix du modele de croissance des plantes ->	
	 * 			'Simple' 	(la croissance se fait par seul changement du kc)
	 * 			'AqYield' 	(prise en compte delements plus complexe, comme letat du sol par exemple)
	 * nomChoixModeleIrrigation : Choix du modele dirrigation ->	
	 * 			'Simple' 	(une fois par tour deau au meme moment pour toutes les parcelles irrigables)
	 * 			'GroupeIrrigation' 	(creation de groupe dirrigation, comportement plus realiste de lirriguant)
	 * isEauDisponibleAgriInfinie : Dans le cas ou les 2 modeles agri et hydro sont actifs et qu'on ne souhaite pas brider la quantite dispo pour l'agri par la quantite dispo sur la ZH
	 * autosaveVisuAgri : autosave pour le display Modele Agricole
	 * executerModeleAgricoleIrrigationUniquement : Prendre en compte uniquement les ilots qui sont de type IRRIGABLE (attribut lu dans le dbf)
	 * executerDisparitionIlots : executer ou non la disparition des ilots
	 * avecIlotsHorsZone : faire la simu avec les ilots hors ZM
	 * executerUnSeulAgriculteur : [DEBUG] Pour exectuter seulement un agriculteur
	 * nomAgriculteurAexecuter : [DEBUG] Choix de lagriculteur a executer	 
	 * executerUneSeuleParcelle : [DEBUG] Pour executer seulement une parcelle (il y aura aussi quun seul ilot et donc quun seul agriculteur
	 * nomParcelleAffichee : [DEBUG] Choix de la parcelle a executer	
	 * listScenarioPrix : liste de fichier de scenario de prix de vente des cultures
	 * scenarioDePrixPrincipal : fichier de prix de vente des cultures utilise dans les cas où il ne faut qu'une valeur 
	 */
	bool reajusterSurfaceParIlot <- true;
	bool executerModeleAgricole <- true;
	bool avecContrainteDeMainOeuvre <- true;
	string nomChoixAssolement <- 'Donnees'; //	Donnees ou FonctionsDeCroyances
	string nomChoixModeleCroissancePlante <- 'AqYield';
	string nomChoixModeleCroissancePrairie;
	string nomChoixModeleIrrigation <- 'GroupeIrrigation';
	bool isEauDisponibleAgriInfinie <- false;	
	bool autosaveVisuAgri <- false;
	bool executerModeleAgricoleIrrigationUniquement <- false; 
	bool executerDisparitionIlots <- false;	
	bool avecIlotsHorsZone <- false;	
	bool executerUnSeulAgriculteur <- false;	
	string idExploitationAexecuter <- "120067";
	bool executerSurEnsembleExploit <- false;	
	list<string> listIdExploitationAexecuter <- [];
	bool executerUneSeuleParcelle <- false; 	
	string nomParcelleAffichee <- '4946098_00'; // parcelle118  '4946098_00_OK' =   parcelleAqYield7468
	bool executerParcelleVirtuelle <- false; 	
	string rotationForceeParcelle <- 'mais';
	string gestionPaillesForceeParcelle <- 'restitution';
	string idSdcForce <- "";
	string typeDeSolForceParcelle <- '';
	float surfaceHectareForceParcelle <- 0.0;
	string typeDeMaterielIrrigationForceParcelle <- "NA";
	bool isIrrigationSimulee <- true;
	bool constructionExploitationElevage <- false;
	bool afficherEffectifElevage <- true;
	bool accelerationTourEauSiRestriction <- true;
	int anneeDeReferenceRPG <- 2012;
	bool gestionPrairiePParSWAT <- false;
	string PRAIRIEP <- "prairiep";
	string PRAIRIET <- "prairiet";
	list<string> listScenarioPrix  <- [''];
	string scenarioDePrixPrincipal <- '';
	bool activerITKalternatif <- true; // JV 300320 mantis 0002510
	bool forcerSemisCI <- true; // JV 300821 si activerITKalternatif=false et forcerSemisCI=true, on force le semis, si activerITKalternatif=false et forcerSemisCI=false: on ne fait rien, si activerITKalternatif=true on ne fait rien (pas d'ITK alternatif pour un CI)
	bool affecterEqIrrSiInexistant <- false; // JV 150520 mantis 0002599 vrai si on souhaite affecter l'équipement le plus proche de l'ilot si celui-ci est irrigable mais que ses équipements n'ont pas pu être créés (car en dehors du sous-territoire si on simule sur un sous-territoire)
	bool plusieursTravauxDuSolParITK <- false; // Détermine si plusieurs OT de fertilisation sont possibles dans un même ITK (à activer dans le launcher) // JV 270721 fusion Renaud_NC
	bool plusieursFertilisationsParITK <- false;// Détermine si plusieurs OT de travail du sol (PREPA) sont possibles dans un même ITK (à activer dans le launcher) // JV 270721 fusion Renaud_NC
	bool plusieursTraitementsPhytoParITK <- false; // Renaud 200323
	string adaptationFertilisation <- '';
	bool executerModelePaturage <- false;
	int corpenProfondeurTemporelle <- -1;
	bool executerModeleElevage <- false;
	bool avecStressClimatique <- false; // Prise en compte du gel et de l'échaudage
	string gestionStocksEngrais <- "territoire"; // territoire / filiere // Renaud 040225
	int ageMinPourRecolte <- 30; // JV 200725 pour les cultures en place plus de 365 jours comme le colza 
	
	/*
	 * ************ Parametres economique ************
	 * 
	 */
	 float inflation <- 1.02 ; // les prix/coûts augmentent de 2% 
	 float profondeurParDefautDesPrelevementEnNappe <- 20.0; //[m]
	
	/*
	 * ************ Parametres du modele hydrographique ************
	 * executerModeleHydrographique : Prendre en compte ou non toute la partie traitement hydrographique dans la simulation
	 * nomChoixModeleHydrographique ->
	 * 			'Simple' 	(le debit journalier est calcule uniquement a laide de la pluie)
	 * 			'SWAT' 		(Le debit est calcule en prenant en compte le clc, type de sol et pente (vitesse ecoulement))
	 * 			'Donnees'	
	 * isPrelevementEtRejetSimules : Executer ou non les processus lies aux prelevements et aux rejets
	 */
	bool executerModeleHydrographique <- false;
	string nomChoixModeleHydrographique <- 'Simple';
	bool isPrelevementEtRejetSimules <- true;	
	bool isCanaux <- false;
	bool isNeige <- false;
	list<string> listeExutoiresZoneMaelia <- ["O098", "O208", "O187"];
	list<string> ID_RESSOURCES_INFINIES <- [];
	list<string> listeRetenuesRechargeHivernale <- []; //liste des retenues a recharger par pompage hivernale
	int jourJulienDebutPompage <- 305; // 01/11 //date de debut de pompage hivernale pour remplir les retenues
	int jourJulienFinPompage <- 151; // 31/05 //date de debut de pompage hivernale pour remplir les retenues
	
	/*
	 * ************ Parametres du modele normatif ************
	 * executerModeleNormatif : Prendre en compte ou non toute la partie norme dans la simulation
	 */
	bool executerModeleNormatif <- false;
	string nomChoixModeleZA <- Complexe;
	bool executerBarrage <- false;
	list<string> listCulturesDerogatoires <- [];
			
	/*
	 * ************ Parametres du test de non regression ************
	 * testRegressionMode : afficher ou non le temps dans la console
	 */			
	bool testRegressionMode <- false;
	
			
/*
 * ************ Constantes ************
 */ 
  	string ASA <- 'ASA' const: true;
 	string SURF <- 'SURF' const: true;
	string NAPP <- 'NAPP' const: true;
	string RET <- 'RET' const: true;
	string CAN <- 'CAN' const: true;
	string AEP <- 'AEP' const: true;
	string IND <- 'IND' const: true;
	string IRR <- 'IRR' const: true;
	string OUGC <- 'OUGC' const: true; //Organisme Unique de Gestion Collective 
	string DECONNECTE <- 'Deconnectees' const: true;
	string CONNECTE <- 'Connectees' const: true;
	string SURNAPPE <- 'SURNAPPE' const: true;
	string TYPEDEDRAIN <- "TYPEDEDRAI" const: true;
	//string DERIVATION <- 'Derivation' const: true;
	string SOUHAITE <- 'SOUHAITE' const: true;
	string REEL <- 'REEL' const: true;
	string BATI <- 'Bati' const: true;
	string AGRICOLE <- 'Agricole' const: true;
	string FORET <- 'Foret' const: true;	
	string SURFACE_EN_EAU <- 'SurfaceEnEau' const: true;
	string RPG <- 'RPG' const: true;
	string SEPARATEUR <- "|" const: true;
	string SEPARATEUR_ET <- "&" const: true;
	string SEMIS <- 'SEMIS' const: true;
	string SEMIS_FORCE <- 'SEMIS_FORCE' const: true;
	string RECOLTE <- 'RECOLTE' const: true;
	string RECOLTE_FORCEE <- 'RECOLTE_FORCEE' const: true;
	string IRRIGATION <- 'IRRIGATION' const: true;
	string TRAVAIL_SOL <- 'TRAVAIL_SOL' const: true;
	string BINAGE_SOL <- 'BINAGE_SOL' const: true;
	string REPRISE_TRAVAIL_SOL <- 'REPRISE_TRAVAIL_SOL' const: true;
	string FERTI <- 'FERTI' const: true;
	string FAUCHE <- 'FAUCHE' const: true;
	string PHYTO <- 'PHYTO' const: true;
	string PATURE <- 'PATURE' const: true;
	
	string PREFIXE_CI <- 'CI';
	
	list<string> listOT <- [IRRIGATION, RECOLTE, RECOLTE_FORCEE,SEMIS,SEMIS_FORCE, BINAGE_SOL, FERTI, PHYTO, REPRISE_TRAVAIL_SOL, TRAVAIL_SOL, FAUCHE,PATURE];//[IRRIGATION, RECOLTE, RECOLTE_FORCEE,SEMIS,SEMIS_FORCE, BINAGE_SOL, FERTI, PHYTO, REPRISE_TRAVAIL_SOL, TRAVAIL_SOL] const: true;
	list<string> listOTASuivreEnSortie <- listOT; // pour les sorties suiviITK_<OT>
	list<string> listOTAMemoriser; // pour la sortie suiviITKParParcelle (et suiviITKParParcelle_humidite)
	
	int ETAT_PAS_IRRIGATION_DEMANDEE <- 0 const: true;		 
	int ETAT_PAS_DEAU <- 1 const: true;		 
	int ETAT_PAS_ASSEZ_DEAU <- 2 const: true;		 
	int ETAT_ASSEZ_DEAU <- 3 const: true;		 
	int ETAT_IRRIGATION_REDUITE_CAR_RESTRICTION <- 4 const: true;		 
	int ETAT_RESTRICTION <- 5 const: true;		 
	int ETAT_IRRIGATION_CONTRE_RESTRICTION <- 6 const: true;
		 
	int espacement3D <- 1; // pour le video 3D 

	// chemin selon exécution sur cluster ou en local JV 100820
	bool executerSurCluster <- false;	
	string cheminRacineMaeliaLocal <- "../../";
	string cheminRacineMaeliaCluster <- "/home/villerdj/work_inra_ea/jean/MAELIA_1.4.14_GAMA_1.8.1/";	
	map<bool,string> mapCheminRacineMaeliaSelonClusterOuPas <- [true::cheminRacineMaeliaCluster, false::cheminRacineMaeliaLocal];	
	string cheminRacineMaelia <- mapCheminRacineMaeliaSelonClusterOuPas[executerSurCluster]; // JV 080420 non constante car surchargé dans le launcher lorsqu'on lance sur le cluster 
	string cheminModeleVersDonnees <- cheminRacineMaelia + 'includes/';
	//string cheminModeleAvecUnSousRepertoireVersDonnees <- cheminRacineMaelia + '../includes/';	

	// Constantes communes a tous les modeles
	float PI <- 3.141592654 const: true;
	float zeroApproche <- 0.000001 const: true;
	int nbHeuresDansPasDeTemps <- 24 const: true;
	list<string> RESSOURCE_NON_RESTREINTES <- [RET, NAPP];
	map<int, rgb> mapCouleurLandCoverParIdClasse <- [1::rgb('red'), 2::rgb('orange'), 3::rgb('green'), 4::rgb('white'), 5::rgb('blue')] const: true;
	list listeIdSthAcomparer <- ['O0384010', 'O0444010', 'O0362510', 'O0502520', 'O0200040', 'O0624010', 'O0592510', 'O1934310', 'O1874010', 'O0984010', 'O1984310', 'O0050010', 'O1900010'] ;
//	map<string,int> mapEtatIrrigationParcelle <- ['pasIrrigationDemandee'::0, 'pasDeau'::1, 'pasAssezDeau'::2, 'assezDeau'::3, 'irrigationReduiteCarRestriction'::4, 'restriction'::5, 'irrigationContreRestriction'::6] const: true;
	map<string, string> NATURE_RESSOURCE_LIEN <- ['eauSurfacique'::SURF, 'nappe'::NAPP, 'retenue'::RET] const: true;
	list<string> ACTEURS_PAR_PRIORITE <- [AEP, IND, CAN, IRR] const: true;

	map<string,float> importancePrelevementParTypeRessource <- map([ASA::0.55, SURF::0.30, NAPP::0.15, RET::0.05]);
	map<int,list<int>> mapCorrespondanceIndicePlageDebit <- [0::[0, 10], 1::[10, 20], 2::[20, 30], 3::[30, 40], 4::[40, 50], 5::[50, 60], 6::[60, 70], 7::[70, 100]] const: true;
	map<int,list<int>> mapCorrespondanceIndicePlageHauteurPluie <- [0::[0, 3], 1::[3, 6], 2::[6, 10], 3::[10, 15], 4::[15, 20], 5::[20, 25], 6::[25, 30], 7::[35, 40]] const: true;
	rgb couleurBleuClaire <- rgb([56,188,255]) const: true;
	rgb couleurVertClaire <- rgb([155,255,56]) const: true;
	rgb couleurOrange <- rgb([255,168,48]) const: true;
	rgb couleurRouge <- rgb([255,26,10]) const: true;
	rgb couleurGrisClaire <- rgb([211,209,214]) const: true;	
	int taillePoints <- 800 const: true;	// 1500
	int taillePointsMax <- 2000 const: true; // 1000    250
	int taillePointsMin <- 500 const: true;  // 500    100
	int tailleTexte <- 1000 const: true;  // 500    100
	string nomTableMeteo <- 'Meteo' const: true;
	int nombreMeterCarreDansUnHectare <- 10000 const: true;
	int nombreMillimetreDansUnMetre <- 1000 const: true;
	int nbMDanskm <- 1000 const: true;
	int nombreCentimetreDansUnMetre <- 100 const: true;
	int nbMmDansCm <- 10 const: true;
	int nbLDansM3 <- 1000 const: true;
	int nbSecondesDansUneJournee <- 86400 const: true;
	
	// Constantes liees au modele agricole
	float quantiteEauMaxDispoAgri <- 1000000000000000.0 const: true; // Si la quatite d'eau max de l'agri n'est pas definie par la ZH, on prend cette quantite max (2 cas : soit le modele hydro est inactif, soit il est actif mais on ne souhaite pas brider la quantite max de l'agri par la quantite presente dans la ZH)
	int memoireAgriculteur <- 5 const: true;
	float rendement_malus <- 20.0 const: true; //malus de rendement dans le cas ou la culture n'a pas ete recolte a temps (en pourcentage)
	float travail_max_jour <- 16.0 ; //quantite de travail max sur un jour pour 1 UMO [h/jour]
	float travail_jour <- 12.0; //quantite de travail en temps normal  pour 1 UMO [h/jour]
	float uth_par_hectare <- 15.0; //nb d'UTH (Heures) par hectare d'exploitation //
	float travailRelatifDesPrairies <- 3.0 const: true; // [-] // 1ha de praire coute X fois de temps de trvail qu'1 ha de grande culture
	float distanceMaxIlotsGroupeIrrigation <- 10000.0 ; // [m]
	float EFFICIENCE_PPA_PARCELLE <- 0.05 const: true; //perte transmission de l'eau
	int nombrePlansOptimauxUtilise <- 16; // de préférence un nombre pair
	 
	// Modele AQYIELD
	int moisDebutCultureHiver <- 7 const: true; // JV 290621 passage de 9 à 7 cf Mantis #0002849
	int moisFinCultureHiver <- 2 const: true;
	int premierJourFein <- 28 const: true; // Modif Renaud 22/05/19
	int premierMoisFein <- 10 const: true;		
	int dernierJourFein <- 12 const: true; // Modif Renaud : fixé au 19/02 initialement, remonté au 15 février pour coller à aqyield
	int dernierMoisFein <- 2 const: true;		
	float NA <- -888.88; // Choix dune valeur jamais prise en compte dans le fichier lu des SDC
	int jourRefCalculLongueurJour <- 21 const: true;
	int moisRefCalculLongueurJour <- 3 const: true;
	float coefLJ <- 1.5 const: true;
	float latitude <- 43.5 const: true;
	float indiceLJ <- (latitude/80)^3 + 0.12;
	
	float coefCulturalEva <- 1.2 const: true; // kc,eva // Rdv Hélène 03/04/18 Référence doc : modif_coefCulturalEva (originellement  initialisé à 1.1 -> voir avec Julie et Malagi quelle valeur garder)
	float coefCeva <- 50.0 const: true; // coef_ceva  = 50 mm
	float coefEvaSurRUs <- 3.0 const: true; //0.4 * etpParcelle const: true; //3/nombreMillimetreDansUnMetre const: true; // Rdv Hélène 03/04/18 Référence doc : modif_coefEvaSurRUs
	float horizonDeTravailProfond <- 30.0; // [cm] W3
	float horizonDeTravailMoyen  <- 12.0; // [cm] W2
	float horizonDeTravailSuperficiel  <- 6.0; // [cm] W1
	map<string,float> MAP_LECTURE_W <- ["W1"::horizonDeTravailSuperficiel, "W2"::horizonDeTravailMoyen, "W3"::horizonDeTravailProfond] const: true;
	
	//float reserveUtileHorizonSurfaceW2 <- 12.0 const: true; // RUSw2 = 12mm
	//float reserveUtileHorizonSurfaceW3 <- 25.0 const: true; // RUSw3 = 25mm
	
	// Constantes module AqYield N
	float seuilDispoN <- 5.0; // Seuill d'apport en eau (précipitations ou irrigation) à partir duquel l'azote peut être minéralisé (mm)
	float CAU const: true <- 1.0; // Coefficient apparent d'utilisation de l'engrais
	
	// Constantes liees au modele normatif
	int premierJourLacherBarrage <- 15 const: true; // 15
	int premierMoisLacherBarrage <- 8 const: true;	// 8
	int premierJourEtiage <- 15 const: true;
	int premierMoisEtiage <- 5 const: true;	
	int premierJourEtiageAEAG <- 1 const: true;
	int premierMoisEtiageAEAG <- 7 const: true;	
	int dernierJourEtiageAEAG <- 31 const: true;
	int dernierMoisEtiageAEAG <- 10 const: true;	
	int premierJourEte <- 1 const: true;
	int premierMoisEte <- 6 const: true;	
	int dernierJourEte <- 31 const: true;
	int dernierMoisEte <- 9 const: true;

	// Constantes liees au modele hydrographique
	float pourcentagePluiePourCoursDeauPrincipal <- 0.7 const: true; // la quanite deau qui arrive dans la ZH 
	float rapportConsomationPrelevementMogire <- 0.35 const: true; // AEP
	float rapportConsomationPrelevementIND <- 0.07 const: true;			
		
		// Modele SWAT
		
	string parametrageHydro <- "plaine"; // sinon "montagne"
	float profondeurEvaporationMax <- 500.0 const: true; // 500 mm	
		// Calibration SWAT	
	// Paramètres à utiliser pour l'analyse de sensbibilité puis pour la calibration
	float esco <- 1.0; //RL 13/08/2013 pour AS et calibration
	float epco <- 0.3; //RL 13/08/2013 pour AS et calibration
	float coefficientSurfaceRuissellementLag <- 4.0; // surLag	
	float retardEntreSortiSolEtEntreeAquifereGlobal <- 31.0; // deltaGw  [jour]
	float coefRevapEauSouterraineGlobal <- 0.01; // betaRev		
	float coefPercolationVersAquifereProfondGlobal <- 0.05; // betaDeep
	float recessionEcoulementEauxSouterrainesGlobal <- 0.01; // alphaGw [h] //unite differente de la documentation theorique
	float seuilEcoulementAquiferePeuProfond <- 0.0 ; // aqShthr,q  [mm]
	float seuilRevapAquiferePeuProfond <- 1500.0 ; // aqShthr,rvp  [mm]   		 
	//const alphaBankGlobal type: float <- 0.08; // alphaBank // RL 14/08/2013 Unused parameter
	float curveNumberGlobal <- 92.0; // CN2 : WATR
	map<string, float> CN <- map([BATI::65.0, AGRICOLE::70.0, FORET::70.0, SURFACE_EN_EAU::0.0]); // JV 230822 ajout SURFACE_EN_EAU cf Mantis #0002933
	float coefficientManningTerrain <- 0.12 ; // nTerrain
	float coefficientManningCoursEauTributaire <- 0.014 ; // nChTri					
	float coefficientManningCoursEauReel <- 0.014 ; // nCh
	float coefMuskingum1 <- 0.75 ; // msk1	
	float coefMuskingum2 <- 0.25 ; // msk2	
	float coefMuskingumX <- 0.2 ; // mskX	
	float LAI_FORET <- 6.0; // In fact, value higher than 3.0 has the same effect [m2/m2]
	float LAI_GRASSLAND <- 2.0; // This value is for grasslands [m2/m2]
	float rendementAquiferePeuProfond <- 0.15; // mu
	
	// Paramètres d'initialisation (si sensible, alors à inclure dans l'analyse d'incertitude)
	float volumeStockeinit <- 10.0 ; // rchstor
	float eauStockeeAquiferePeuProfondInit <- 1000.0; //shallst ; initialise qsSh(i)
	float coefEauCoucheInit <- 1.0;
	
	float coefAjustementEvaporation <- 1.0; // evrch	// Pour ajuster l'évapotranspiration en condition aride
	//float fractionPerteTransmission <- 0.0; // frTlssch //Used in commented code
	
	float swMin <- 0.0001;
	float fractionImpermeable <- 0.3; // frimp(urblu) 
	
					// Neige
	int nbMoyJourPluieSurUneAnnee <- 160;
	float tlaps <- -6.61; // tlaps [C/km] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float plaps <- 623.4 / nbMoyJourPluieSurUneAnnee; // plaps [mm/km] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float sno50cov <- 0.64; // sno50cov(i) //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float snocovmx <- 29.48; // snocovmx(i) //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float timp <- 0.54; // timp(i) //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float temperatureChuteDeNeige <- 1.52; // sftmp(i) [°C] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float temperatureFonteDeNeige <- -0.49; // smtmp(i) [°C] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	//Atention artefact numerique dans les valeurs de paramètres. Cela est du au decalage temporel
	float txFonteDeNeigeMin <- 5.84; // smfmn(i) [mm/°C/jour] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	float txFonteDeNeigeMax <- 3.05; // smfmx(i) [mm/°C/jour] //Valeur issue de la calibration de SWAT see Grusson et al., 20014
	
	float precipitationMin <- 0.01;	
	
	// HERBSIM
	 
	//RL 13/05/20105 parameter values [20 ; 70]
	float MinFTSWForUndisturbedGrowth <- 70.0; //MinFractionOfTranspirableSoilWaterForUndisturbedGrowth
	float MinFTSWForGrowth <- 40.0; //MinFractionOfTranspirableSoilWaterForGrowth
	
	// STICS
	string denit_fTemp_option <- "Stics"; // option for using "Stics" or "SystN" temperature function for denitrification
	
	
	
	/*
	 * ************ Variables globales ************ 
	 */
	int premierJourDeLaPeriodeDetiage <- 0;
	string detailSimulation <- "";
	string nomDeLaSimulation <- ""; // JV 051223 à virer, était utilisé dans les outputs pour personnaliser les noms des fichiers, désormais on personnalise le nom du répertoire avec la variable suivante
	string nomSimulation <- ""; // JV 051223 inséré dans le nom du répertoire de sortie: nomIncludes_nomSimulation_horodatage	
	string timestamp <- ""; // JV 110820 for timestamping the output folder (folder name = log/nomIncludes_timestamp) assigned at the beginning of main
	string cheminRelatifDuDossierDeSortieDeSimulation <- cheminRacineMaelia + "models/main/log";
	string nomFichierReglesDeDecision <- "reglesDeDecisions.csv";
	string nomFichierReglesDeDecisionFerti <- "reglesDeDecisions_fertilisation.csv";
	string nomFichierITKmanquants <- "ITKmanquants.csv";

	/*
	 * ************ Variables debugs ************

	 */
	int idIlotTest <- 1606886;
//	const nomZHAffichee type: string <- 'O098'; //last(listNomsZHsDecoupageZone);	//   'O060'	  codeZoneHydroExutoire
	string nomZHAffichee <- first(listNomsZHsDecoupageZone);	//   'O060'	  codeZoneHydroExutoire
	string nomPtRefAffichee <- "O1900010";	// O0200040  O0592510   O0362510  O0984010
	
	
	float log(float entree){
		return ln(entree) / ln(10);
	}
	
	// JV 110820 update paths depending on the value of executerSurCluter
    action majChemins{
        // Ajout Renaud 01/09/22 pour execution via API
        if (idSimulationAPI = "") {
            //cheminRacineMaelia <- mapCheminRacineMaeliaSelonClusterOuPas[executerSurCluster]; // JV 110820 pour le moment chemin spécifié dans le XML de l'experiemnt pour le cluster
            //cheminModeleVersDonnees <- cheminRacineMaelia + 'includes/';
            string timestamp_withoutColon <- replace(timestamp, ":", "_"); // JV 210920 if there is a ":" in the path it makes Windows crash
            if nomSimulation!="" {
            	cheminRelatifDuDossierDeSortieDeSimulation <- cheminRacineMaelia + "models/main/log/" + nomDecoupageZonePourLectureFichiers + "_" + nomSimulation + "_" + timestamp_withoutColon;            	
            } else {
            	cheminRelatifDuDossierDeSortieDeSimulation <- cheminRacineMaelia + "models/main/log/" + nomDecoupageZonePourLectureFichiers + "_" + timestamp_withoutColon;
            }
        } else {
            cheminRelatifDuDossierDeSortieDeSimulation <- cheminRelatifDuDossierDeSortieDeSimulation + "/" + idSimulationAPI;
        }
    }   
		
	// JV 110820 write into the output folder a simulationParameter.txt file containing the exhaustive list of parameters with their value 
	action writeSimulationParameterFile{
		string s <- "";
		s <- s + "version GAMA\t" + gama.version + "\n";
		s <- s + "version MAELIA\t" + versionMaelia + "\n\n";
		
		/* TODO: check on Win
		s <- s + "machine\t" + command("uname -n");
		s <- s + "OS\t" + command("uname -o");
		s <- s + "version OS\t" + command("uname -v");
		s <- s + "utilisateur\t" + command("whoami") + "\n";
		* 
		*/		
		
		s <- s + "PARAMETRES GENERAUX\n";
		s <- s + 		"executerSurCluster\t" + executerSurCluster + "\n";
		s <- s + 		"nomDecoupageZonePourLectureFichiers\t" + nomDecoupageZonePourLectureFichiers  + "\n";
		s <- s + 		"anneeDebutSimulation\t" + anneeDebutSimulation + "\n";
		s <- s + 		"nbAnneesSimulation\t" + nbAnneesSimulation + "\n";
		s <- s + 		"executerModeleSurUneZH\t" + executerModeleSurUneZH + "\n";
		if(executerModeleSurUneZH){s <- s + 		"\tlistNomsZHsDecoupageZone\t" + listNomsZHsDecoupageZone + "\n";}
		s <- s + 		"executerUnSeulAgriculteur\t" + executerUnSeulAgriculteur + "\n";
		if(executerUnSeulAgriculteur){s <- s + 		"\tidExploitationAexecuter\t" + idExploitationAexecuter + "\n";}
		s <- s + 		"executerUnSeulAgriculteur\t" + executerUnSeulAgriculteur + "\n";
		if(executerSurEnsembleExploit){s <- s + 		"\tlistIdExploitationAexecuter\t" + listIdExploitationAexecuter + "\n";}
		s <- s + 		"executerUneSeuleParcelle\t" + executerUneSeuleParcelle + "\n";
		if(executerUneSeuleParcelle){s <- s + 		"\tnomParcelleAffichee\t" + nomParcelleAffichee + "\n";}
		s <- s +		"nomScenarioClimatique\t" + nomScenarioClimatique + "\n";
		s <- s + 		"utiliserMemeDonnesMeteoPartout\t" + utiliserMemeDonnesMeteoPartout + "\n";
		if(utiliserMemeDonnesMeteoPartout){s <- s + 		"\tidPointMeteoUnique\t" + idPointMeteoUnique + "\n";}
		s <- s + 		"associerIlotMeteoZH\t" + associerIlotMeteoZH + "\n";
		s <- s + 		"verboseMode\t" + verboseMode + "\n";
		
		s <- s + "\nMODULE HYDROLOGIQUE\n";
		s <- s + 		"executerModeleHydrographique\t" + executerModeleHydrographique + "\n";
		if(executerModeleHydrographique){
			s <- s + 		"\tnomChoixModeleHydrographique\t" + nomChoixModeleHydrographique + "\n";
			if(nomChoixModeleHydrographique = 'SWAT'){
				s <- s + 		"\t\tsurLag: coefficientSurfaceRuissellementLag\t" + coefficientSurfaceRuissellementLag + "\n";
				s <- s + 		"\t\tdeltaGw: retardEntreSortiSolEtEntreeAquifereGlobal\t" + retardEntreSortiSolEtEntreeAquifereGlobal + "\n";
				s <- s + 		"\t\tbetaDeep: coefPercolationVersAquifereProfondGlobal\t" + coefPercolationVersAquifereProfondGlobal + "\n";
				s <- s + 		"\t\tnTerrain: coefficientManningTerrain\t" + coefficientManningTerrain + "\n";
			}				
			s <- s + 		"\tisPrelevementEtRejetSimules\t" + isPrelevementEtRejetSimules + "\n";
			if(isPrelevementEtRejetSimules){
				s <- s + 		"\t\taffecterEqIrrSiInexistant\t" + affecterEqIrrSiInexistant + "\n";
			}				
			s <- s + 		"\tnomPtRefAffichee\t" + nomPtRefAffichee + "\n";
			s <- s + 		"\tlistNomsZHsDebitComplement\t" + listNomsZHsDebitComplement + "\n";
			s <- s + 		"\tlisteExutoiresZoneMaelia\t" + listeExutoiresZoneMaelia + "\n";
			s <- s + 		"\tID_RESSOURCES_INFINIES\t" + ID_RESSOURCES_INFINIES + "\n";
		}
			
		s <- s + "\nMODULE AGRICOLE\n";
		s <- s + 		"executerModeleAgricole\t" + executerModeleAgricole + "\n";
		if(executerModeleAgricole){
			s <- s + 		"\tnomChoixAssolement\t" + nomChoixAssolement + "\n";
			s <- s + 		"\tanneeDeReferenceRPG\t" + anneeDeReferenceRPG + "\n";
			s <- s + 		"\tnomChoixModeleCroissancePlante\t" + nomChoixModeleCroissancePlante + "\n";
			s <- s + 		"\tactiverITKalternatif\t" + activerITKalternatif + "\n";
			s <- s + 		"\tnomFichierReglesDeDecision\t" + nomFichierReglesDeDecision + "\n";
			s <- s + 		"\tavecIlotsHorsZone\t" + avecIlotsHorsZone + "\n";
			s <- s + 		"\tavecContrainteDeMainOeuvre\t" + avecContrainteDeMainOeuvre + "\n";
			s <- s + 		"\tisIrrigationSimulee\t" + isIrrigationSimulee + "\n";
			if(isIrrigationSimulee){		
				s <- s + 		"\t\tnomChoixModeleIrrigation\t" + nomChoixModeleIrrigation + "\n";
			}
			s <- s + 		"\tlistScenarioPrix\t" + listScenarioPrix + "\n";
			s <- s + 		"\tscenarioDePrixPrincipal\t" + scenarioDePrixPrincipal + "\n";
			s <- s +		"\tprefixeCouvertIntermediaire\t" + PREFIXE_CI + "\n";
		}
		
		s <- s + "\nMODULE NORMATIF\n";
		s <- s + 		"executerModeleNormatif\t" + executerModeleNormatif + "\n";
		if(executerModeleNormatif){
			s <- s + 		"\taccelerationTourEauSiRestriction\t" + accelerationTourEauSiRestriction + "\n";
			s <- s + 		"\texecuterBarrage\t" + executerBarrage + "\n";
		}
		s <- s + "\nWARNINGS\n";
		s <- s + initLogWarning;
		
		// TODO: check output consistency
		
		string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/simulationParameters.txt";
		save s to: fileName format: 'text' rewrite:true;
		
		/* TODO: check on Win
		// JV 031221 genere signatures MD5 des fichiers includes pour traçabilité: find rep/ -type f -exec md5sum {} \; > md5sum.txt
		string md5command <- "find " + cheminModeleVersDonnees + "/" + nomDecoupageZonePourLectureFichiers + "/ -type f -exec md5sum {} " + "\\" + ";"; // ;//+ cheminRelatifDuDossierDeSortieDeSimulation + "/md5sum.txt";	
		save command(md5command) to: cheminRelatifDuDossierDeSortieDeSimulation + "/md5sum.txt" type: 'text';
		* 
		*/
	}
	
	// affichage d'un warning et ajout dans la chaine initLogWarning
	action raiseWarning(string s){
		write "\t\u2757 WARNING " + s color:#orange;
		initLogWarning <- initLogWarning + "- " + s + "\n";
	}
	
	// affichage d'une erreur et ajout dans la chaine initLogError
	action raiseError(string s){
		write "\t\u274c " + s + "\n\nERREUR LORS DE L'INITIALISATION" color:#red;
		do die;
	}

	// affichage d'un check mark et éventuellemnt d'une string
	action printOk(string s){
		write "\t\u2705 " + s color:#green;		
	}
	
	// JV 100524 patch function to workaround a GAMA bug in 1.9.3 (see https://github.com/gama-platform/gama/issues/166)
	// removes from source elements at indices contained in indicesToRemove
	// used in parcelleAqYieldNC
	list removeAtIndices(list source, list indicesToRemove){
		list res <- [];
		loop i from: 0 to: length(source)-1 {
			if !(indicesToRemove contains int(i)) { // JV 170524 i casted otherwise float
				res <+ source[i];
			}
		}
		//write "res:" + res + " source:" + source + " indicesToRemove" + indicesToRemove;
		assert(length(res)=length(source)-length(indicesToRemove));
		return(res);
	}
	map removeAtIndicesMap(map source, list indicesToRemove){
		map res;
		ask source.keys { 
		//loop i from: 0 to: length(source)-1 {
			if !(indicesToRemove contains self) {
				res[self] <- source[self];
			}
		}
		write "res:" + res + " source:" + source + " indicesToRemove" + indicesToRemove;
		//assert(length(res)=length(source)-length(indicesToRemove));
		return(res);
	}
}
