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
 *  Parcelles
 *  Author: Maroussia Vavasseur
 *  Description: La parcelle est une partie d'ilot qui va recevoir une culture au cours de l'annee. La parcelle n'est pas une entite georeference (mais son ilot oui).
 * 				 Unites : Dans la parcelle tout est converti en metre  
 * 						  les entrees sont en m3 et les sorties egalement.
 * 						  Cette conversion est donc transparente et est utile pour la croissance des plantes
 */

model parcelle

import "parcelleETP.gaml"
import "../../modeleHydrographique/equipement.gaml"

global{	
	string parcellesShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/dansZone/parcelles.shp';
	list<parcelle> listeParcelles <- []; // soit parcelle simple, soit AqYield
	list<parcelle> listeParcellesUtiles <- []; // soit parcelle simple, soit AqYield = une parcelle utile est une parcelle qui est traitee dans la partie agri (et non hydro car elle aurait en permance des prairies)
	map<map<string, float>, float> mapSurfaceParcellesAtraiteesParHydro <- map<map<string, float>, float>([]); // {<idSol:idPente>: sommeSurface}			
	parcelle parcelleAffichee <- nil;	
	list<string> listNomGestionPrairie;

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action creationParcelles{
		if !file_exists(parcellesShape)	{do raiseError("fichier inexistant: " + parcellesShape);}
		//if !is_shape(parcellesShape)	{do raiseError("le fichier " + parcellesShape + " n'est pas un fichier shape");}	

		switch nomChoixModeleCroissancePlante {
			match Simple {
	        	do constructionParcelles;                       
	    	}
			match AqYield {
	        	do constructionParcellesAqYield;    
	    	}
			match AqYieldNC {
				do constructionParcellesAqYieldNC;
			}
	    	match PlanteETP{
	    		do constructionParcellesETP; 
	    	}            
	    	default {
	        	do constructionParcelles;    
	    	}
		}
	    do writeSurfaceParcelles;	
	}

	/*
	 * *****************************************************************************************
	 * Private
	 */
	action constructionParcelles{
		listeParcelles <- lectureFichierParcelle(cheminEntree:parcellesShape, typeParcelle:parcelle);
	}
			
	/*
	 * *****************************************************************************************
	 * Private
	 * Probleme donnees entree = il y a des culture irriguee sur des parcelles non irriguees
	 */
	list<parcelle> lectureFichierParcelle(string cheminEntree <- "", species<parcelle> typeParcelle <- parcelle, bool creationHorsZone <- false) {	
		list<parcelle> listeSortie <- [];	
		create typeParcelle from: file(cheminEntree) with: [	idParcelle::string(read ( ID_PARCELLE )), 
														rotationReelle::string(read( SEQUENCE)),
														indexDepart::float(read ( INDEX_DEP )),
														surface::float(read ( SURFACE )), // Surface en m2 !
														cultureDeRef::string(read( CULT_REF)),
														gestionPailles::string(read( EXPREST)),
														idIlot::string(read(ID_ILOT)), // JV idIlot désormais lu dans le shp, auparavant inféré à partir de idParcelle, voir Mantis #0002912
														isPaturable::bool(read(IS_PATURAGE)),
														isFauchable::bool(read(IS_FAUCHE)),
														IBIO_parc_LCD::int(read(IBIO_LCD)),
														IBIO_parc_HSN::float(read(IBIO_HSN)),
														IBIO_parc_CONN::float(read(IBIO_CONN)),
														REDUC_ENGR_PLAN_EPANDAGE::float(read(REDUC_ENGR))]
		{
			
			if(! plan_epandage_actif) {
				REDUC_ENGR_PLAN_EPANDAGE <- 0.0;
			} else {
				REDUC_ENGR_PLAN_EPANDAGE <- 1.0;				
			}
			
			// Mode de gestion de la prairie sur cette parcelle
			if (executerModelePaturage) {
				if(isPaturable and isFauchable) {
					gestionPrairie <- ["pature", "fauche"];
				} else if (isPaturable and !isFauchable) {
					gestionPrairie <- ["pature"];				
				} else if (!isPaturable and isFauchable) {
					gestionPrairie <- ["fauche"];				
				} else {
					gestionPrairie <- [];				
				}				
			} else {
				isFauchable <- true;
			}

			
			if(!creationHorsZone){
				ilot_app <- mapIlots at idIlot;
			}else{
				ilot_app <- mapIlotsHorsZone at idIlot;
			}			
			// Suppression des parcelles dont les ilots sont supprimes
			if(ilot_app = nil){
				ask self{
					do die();	
				}	
			// Dans le cas ou on ne veut exexuter quune seule parcelle, cela va aussi supprimer les ilots vides
			}else if(!(idParcelle contains nomParcelleAffichee) and executerUneSeuleParcelle) {
				ask self{
					do die();
				}			
			}else{					
				name <- idParcelle;		
				mapIndiceDepartRotation <- [1::rnd(0), 2::rnd(1), 3::rnd(2), 4::rnd(3),5::rnd(4), 6::rnd(5), 7::rnd(6), 8::rnd(7)];	// JV 090121 uniquement utilisé avec fonctions de croyances			
				if(!executerParcelleVirtuelle){
					idSdcRef <-  string(shape get(ID_SDC));
					if(indexDepart < 0){						// On va parcourir l'idSdcRef pour trouver l'indice de depart
						// s'il n'a pas deja ete affecte par pretraitement
						systemeDeCultureDeReference sdcRefTemp <- (mapSystemesDeCultureDeRef at idSdcRef);
						if(sdcRefTemp != nil) and (nomChoixAssolement = 'FonctionsDeCroyances'){
							list<itk> listTemp <- nil;
							if (ilot_app.materielIlot = nil) {
								listTemp <- sdcRefTemp.mapRotationType at ("NA" +"_" + ilot_app.getNomZonePedo());
							}else{
								listTemp <- sdcRefTemp.mapRotationType at (ilot_app.materielIlot.idMateriel +"_" + ilot_app.getNomZonePedo());
							}

							especeCultivee especeRecherche <- mapEspecesCultiveesParId at cultureDeRef;
							loop i from: 1 to: length(listTemp){
								if ((listTemp[i-1]).especeCultiveeITK = especeRecherche){
									indexDepart <- i; // recupere l indice le plus avancé dans la séquence et correspondant a la culture de ref
								}
							}
							
							if(indexDepart < 0){
								indexDepart <- mapIndiceDepartRotation at length(listTemp);
								if (length(listTemp) > 0){
									write "culture de reference " + cultureDeRef + " n'appartient pas a la rotation "+ listTemp accumulate(each.name);
								}
							}else{
								//Maintenant que l'on connait l'indice de depart on va le modifier pour correspondre avec l'année de reference
								indexDepart <- ((indexDepart +  (anneeDeReferenceRPG - anneeDebutSimulation)) mod length(listTemp));					
								put indexDepart  in: mapIndiceDepartRotation at: length(listTemp); //en attendant davoir implementer 
								// la matrice de precedence
							}
						}
					}else{
						indexDepart <- indexDepart -1;
					}
					
					// RM 030425 cf issue #13 la séquence de gestion des pailles correspondant à l'exportation et à la restitution doit obligaoirement être renseigné lorsque le module NC est activé 
					if (nomChoixModeleCroissancePlante = "AqYieldNC") {
						if (gestionPailles = "") {
							ask myself {do raiseError("Le champ 'EXPREST' de parcelles.shp n'existe pas ou ne contient pas de valeurs. Veuillez le créer et/ou le renseigner.");}
						} else {
							list<string> liste_GestionPailles <- gestionPailles tokenize "_";
							// JV 150825 cf issue #31 ajout possibilité 'rest' et 'exp'
							list<string> valeurs_valides <- ['restitution', 'exportation', 'rest', 'exp'];
							if (liste_GestionPailles contains_any (liste_GestionPailles - valeurs_valides)) {
								ask myself {do raiseError("Le champ 'EXPREST' de parcelles.shp contient une ou plusieurs chaîne(s) de caractères interdite(s) (seules 'restitution' et 'exportation' sont autorisées). Veuillez modifier le champ 'EXPREST'.");}
							}
						}
					}
					
				}else{
					idSdcRef <-  idSdcForce;
					surface <- surfaceHectareForceParcelle;
					rotationReelle <- rotationForceeParcelle;
					gestionPailles <- gestionPaillesForceeParcelle;
					//write "Forcage gestionPailles = " + gestionPailles;
					indexDepart <- 1;
				}	
				surface <- surface * nombreMeterCarreDansUnHectare;			
				do initialisationParcelle();
				add self to: listeSortie;  
			}
			
		}				
		parcelleAffichee <- first(listeSortie where (each.name = nomParcelleAffichee));	
		
		return listeSortie;			 		
	}

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	float getVolumePluieEntree_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + (getPluie()/nombreMillimetreDansUnMetre) * surface; // [m3]
		}
		return resultat;
	}	 
	float getVolumeIrrigationSouhaitee_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + (irrigationSouhaitee/nombreMillimetreDansUnMetre) * surface; // [m3]
		}
		return resultat;
	}	
	float getVolumeIrrigationReelle_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + (irrigationReelle/nombreMillimetreDansUnMetre) * surface; // [m3]
		}
		return resultat;
	}
	float getHauteuIrrigationSouhaitee_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + irrigationSouhaitee; // [mm]
		}
		return resultat;
	}	
	float getHauteurIrrigationReelle_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + irrigationReelle; // [mm]
		}
		return resultat;
	}
	float getSurfaceIrrigationSouhaitee_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + getSurfaceIrrigueeJourCourant(); // [mm]
		}
		return resultat;
	}	
	float getVolumeSortie_Parcelles_ZM{
		float resultat <- 0.0;
		ask(listeParcellesUtiles){
			resultat <- resultat + (quantiteEauDeRuissellement/nombreMillimetreDansUnMetre) * surface + (drain/nombreMillimetreDansUnMetre) * surface; // [m3]
		}
		return resultat;
	}		 
	float getVolumeEntreeParcelle_ZM{	//	volumeEauEntreeParcellesZoneMaelia
		return getVolumePluieEntree_Parcelles_ZM() + getVolumeIrrigationReelle_Parcelles_ZM();
	}				
	action writeSurfaceParcelles {
		// JV 291123 fichier csv surfaceParcelles.csv de structure idParcelle;surface
		string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/surfaceParcelles.csv";
		string aEcr <- "idParcelle;surface [m2];zone_pedo;matIrr\n";
		ask listeParcelles {
			aEcr <- aEcr + idParcelle + ";" + surface + ";" + ilot_app.sol.nom + ";" + ilot_app.materielIlot + "\n";
		}
		save aEcr to: fileName format: "text";
	}	
}

species parcelle {
	string idParcelle <- '';
	string idIlot <- ""; // JV 140622 nécessaire à l'initialisation cf Mantis #0002912 
	ilot ilot_app <- nil;
	culture cultureParcelle <- nil;	
	string idSdcRef <- "";
	string cultureDeRef <- ""; //culture de reference lu en entree de MAELIA : culture de 2012
	systemeDeCulture systemeDeCultureParcelle <- nil;
	string rotationReelle <- ''; // Rotation lu
	string gestionPailles <- ''; // Mode de gestion des pailles/cannes associé à la rotation (voir sequences_exportation_restitution.r)
	map<int,especeCultivee> mapRotationDonneesEntrees <- map([]); // annee::cultureReelle -> utilie uniquement pour les output (indicateur)
	map<int,especeCultivee> mapRotationSimulee <- map([]); // annee::cultureSimulee		
	float surface  <- 0.0; // exprime en m2 !!!		
	bool isParcelleHorsZone <- false;
	bool isParcelleUtile <- false;
	map<int,int> mapIndiceDepartRotation <- map<int,int>([]); // prend un nombre aleatoire selon la taille de la rotation du sdc (fait dans la parcelle pour ne pas generer un nb aleatoire a chaque nouveau SDC)
	map<itk, list<float>> derniereProduction;
	list<itk> itkRecolteSurAnnee <- [];
	list<float> rdtRecolteSurAnnee <- [];		 
	int etatIrrigationParcelle <- 0; // variable pouvant prendre 5 valeur differntes selon quelle est irriguee en totalite ou encore contre restriction
	map<int,float> rendementParJoursRecoltes <- map<int,float>([]); // idJourRecolte::rendement
	int idJourDerniereRecolte <- 0; // idJourRecolte::rendement
	
	map<string, map<int,itk>> memoireOTsurParcelle <- map([]); // <OT , <date, itk>>   
	map<string, map<int,float>> memoireOTsurParcelleTemps <- map([]); // <OT , <date, float>> temps de travail par OT (h)   
	map<string, map<int, map<string,string>>> memoireOTsurParcelleComplements <- map([]); // <OT,<date,<string,string>>> ex:<"RECOLTE",<123,<"rendement","222.3">>>   auparavant: <OT , <date, string>> compléments par OT (ex: rendement pour RECOLTE)   
	
	map<int,float> memoireSurfaceIrriguee <- map<int,float>([]);
	
	map<string,int> memoirePoolResSurParcelle <- map<string,int>([]); // <nom_produit,date> // NR pool 021024
	
	
	// Irrigation complexe
	list<groupeIrrigationCulture> listeGroupeIrrigationCulture <- [];
	int nbIrrig <- 0; //  nombre d'irrigations realises sans arret de l'irrigation (si 2 groupes d'irrigation alors on en compte 2 par jour)
	// Croissance plante
	float irrigationReelle <- 0.0; // [mm]	
	float irrigationSouhaitee <- 0.0; // [mm]
	float cumulCoutIrrigationSurUnITK <- 0.0; //[€]
	float chargesFixes <- 0.0; //[€]
	float pluieEtIrrigation <- 0.0; // [mm]		elle va regrouper l'eau d'irrigation, de pluie
	float quantiteEauDeRuissellement <- 0.0; // mise a jour tous les jours [mm]
	float drain <- 0.0; // drain  [mm]
	// Croissance culture simple
	float reserveFacilementUtilisable <- 0.0; // en [mm]    mise a jour tous les 10 jours
	float ES <- 0.0;
	bool isTravailSolJourCourant <- false; // binage ou travail du sol avant semis
	bool isTravailSolEffectue <- false; 
	list<strategieTravailSolMultiples> OTTravailSolMultiplesEffectuee;
	list<strategiePhytoMultiples> OTPhytoMultiplesEffectuee;
	list<strategieFaucheMultiples> OTFaucheMultiplesEffectuee;
	bool isBinagesSolEffectue <- false; 
	bool isRepriseTravailSolEffectue <- false;
	map<int,bool> isPhytoDeLaPeriodeEffectue <- map<int,bool>([]);
	map<int,bool> isFertiDeLaPeriodeEffectue <- map<int,bool>([]);
	float tempsDeTravail <- 0.0;
	bloc bloc_app <-nil;
	bool recolteForcee <- false ;
	bool semis_prevu_non_realise <- false;
	bool itkAlternatifAchercher <- false;
	bool itkAlternatif <- false;
	bool isSowingAllowed <- true; // permet de gerer l'enchainement des cultures et d eviter des enchainement trop rapide de cultures // JV 300320 à virer suite à mantis 0002510
	itk itkAnnePrec <- nil;
	itk itkIrrigue <- nil;
	int jourProchaineRecolteGel <- 0; // JV 090920 jour récole si ITK=gel: dans un an (ITK suivant=gel) ou veille 1ere OT sinon (cf Mantis #0002670)
	
	// Sortie Journalière HerbSimNC
	float Chum <- 0.0;
	
	// Prairie
	int jourProchaineRecoltePrairie <- 0; // RM 170823 Pareil que pour le gel ci-dessus mais pour les prairies
	bool recoltePrairieAnneeOK <- false;
	bool isPrairiePermanente <- false;
	
	// Module élevage
	bool isPaturable <- false;
	bool isFauchable <- true;
	int tpsReposParcelle <- 0;
	lotAnimaux lotAnimauxCourant;
	list<string> gestionPrairie;
	
	// Temporaire Renaud 020524
	int cpt_fauche;	
	reflex cpt_delai_fauche {
		cpt_fauche <- cpt_fauche + 1;
		// write "cpt_fauche = " + cpt_fauche;
	}
	
	//pour sorties
	float coutIrrigationSurAnnee <- 0.0; //cumul des charges op et fixes d'irrigation
	
	// debug
	int critereSemiOk_Tmin <- 0;
	int critereSemiOk_HumiditeSol <- 0;
	int critereSemiOk_Pluie <- 0;
	
	int critereRecolteOk_echV<- 0;
	int critereRecolteOk_HumiditeSol <- 0;
	int critereRecolteOk_Pluie <- 0;
	
	int indexDepart <- 0;
	string dateDernierSemi <- "";
	
	float prof_w_sol <- 0.0; // TODO Supprimer  --> Ajout Renaud 30/05/18 (cf strategieOT.gaml)
	
	// Gestion des opérations multiples
	strategieTravailSolMultiples travailDuSolMultipleCourant;
	strategiePhytoMultiples phytoMultipleCourant;
	strategieFaucheMultiples faucheMultipleCourant;
	
	// Variables pour enregistrement des caractéristiques de certaines OT (semis et ferti) (surtout pour des sorties NC)
	map<string,int> nSemisCultures;
	map<string,int> nApportProduits;
	map<string,float> quantitesProduits;
	
	float REDUC_ENGR_PLAN_EPANDAGE;
	
	// Variables pour enregistrement (a supprimer ??) -> cf. resultatsRDT_exploitation_espece
	string derniere_culture_recoltee <- "";
	string culture_recoltee_dans_lannee <- "";
	float dernier_rendement <- 0.0;
	string dateSemiDerniereCultureRecoltee <- "";
	
	
	/* JV 130422 variables pour les nouveaux outputs
	 * 1 élément de liste par couvert pendant l'année
	 */ 
	list<int> sorties_jDebutCouvert;
	list<int> sorties_jFinCouvert;
	list<especeCultivee> sorties_especeCouvert;
	list<itk> sorties_itkCouvert;
	bool desactivationMAJsorties <- false; // pour désactiver la MAJ automatique des sorties via comportementJournalier les jours de récolte
	
	// Module biodiversité (cf resultats_iBIO.gaml) --> variables calculées en entrée
	int IBIO_parc_LCD; // Nombre de type d'habitats différents -- calculé en prétraitements
	float IBIO_parc_HSN; // Part de surface d'habitats semi-naturels (%) -- calculé en prétraitements
	float IBIO_parc_CONN; // Agencement des habitats semi-naturels (%) -- calculé en prétraitements
	
	int diversite_cultures; // Nombre de cultures (espèces) dans un rayon de 1 km autour de la parcelle -- calculé dynamiquement
	int diversite_rotation; // Nombre de cultures (espèces) dans la rotation de la parcelle -- calculé à l'initialisation (TODO 170124 update dynamique à ajouter plus tard)
	int nb_traitements_insecticides <- 0; // Nombre de traitements insecticides -- calculé dynamiquement
	int nb_traitements_autres <- 0; // Nombre de traitements autres -- calculé dynamiquement
	int nb_traitements_monocot <- 0; // Nombre de traitements anti-monocotyledon -- calculé dynamiquement
	int nb_traitements_dicot <- 0; // Nombre de traitements anti-dicotyledon total -- calculé dynamiquement
	int nb_traitements_total <- 0; // Nombre de traitements pesticides total -- calculé dynamiquement
	string herbicide_timing <- "No herbicide";
	float intensite_travailSol <- 0.0; // Pas de travail = "direct_sowing", "non_inversion_tillage", "ploughing" -- calculé dynamiquement // Voir StrategieOT.gaml
	float iBio_QNapport_min <- 0.0; // Unités de N minéral apportées
	int n_coupes_fauches <- 0;
	
	string ibio_microorganisms;
	string ibio_vegetation;
	string ibio_invertebrates;
	string ibio_vertebrates;
	string ibio_biodiversity;
	
	
	list<parcelle> parcelles_1km; // Liste des parcelles situées dans un buffer de 1 km de la parcelle présente
	
	geometry buffer_1km_parcelle <- self.shape + 1000;
	
	action update_parcelles_1km {
		parcelles_1km <- listeParcelles collect each where (each.shape intersects buffer_1km_parcelle);
	}
	
	 // Compteur de jours avant lesquels on ne pourra pas mettre d'animaux sur le parcelle // A mettre autre part ??
	 reflex cpt_tpsReposParcelle {
	 	if (tpsReposParcelle > 0) {
	 		tpsReposParcelle <- tpsReposParcelle - 1;
	 	}
	 }
	
	/*
	 * *****************************************************************************************
	 * Initialisation
	 */
	action initialisationParcelle {
		// Si un Sdc est def, alors la parcelle est simulee
		if(itkParPrecedent or ((mapSystemesDeCultureDeRef at idSdcRef) != nil) and (!gestionPrairiePParSWAT or idSdcRef !=PRAIRIEP)){
			isParcelleUtile <- true;
			ilot_app.listeParcelles << self;
			listeParcellesUtiles << self;
			//mapIndiceDepartRotation <- [1::rnd(0), 2::rnd(1), 3::rnd(2), 4::rnd(3)]; // taille rotation :: indice de depart dans la rotation	//Si choix assolement par fonction croyance : on place lindice de depart alealoirement
		// Si la rotation lue est nulle (cela ne doit pas arriver pour le modele agri AQYIELD, alors on ne traitera pas la parcelle dans lagri, mais dans lhydro)
		}else{
			if((mapSystemesDeCultureDeRef at idSdcRef) = nil) and !(idSdcRef =PRAIRIEP and gestionPrairiePParSWAT){
				write "Le systeme de culture "+ idSdcRef + " est inconnu. Par defaut, les parcelles "+
					      "seront considerees comme non utiles et gerees par SWAT";
			}
			
					      
			name <- idParcelle + '_NOK';
			add self to: ilot_app.listeParcellesHydro;
			// je rajoute dans la map la surface de la parcelle qui sera traitee dans la partie hydro
			if(ilot_app.sol != nil){					
				map<string, float> mapClef <- map<string, float>([]);	
				put ilot_app.penteAssociee at: (ilot_app.sol.idTypeDeSOl) in: mapClef;	// la map est unique car lid du type de sol lest
				float sommeSurface <- 0.0;
				if( mapSurfaceParcellesAtraiteesParHydro at mapClef != nil){
					 sommeSurface <- mapSurfaceParcellesAtraiteesParHydro at mapClef;
				}
				sommeSurface <- surface + sommeSurface;					
				put sommeSurface at: mapClef in: mapSurfaceParcellesAtraiteesParHydro;													
			}				
		}
		
		do initDerniereProd(); 				
		do initialisationDonneesSol();		
		do initMemoireDateOT();	
		do initMemoirePoolRes(); // NR pool
		do initSortiesParcelle();
		
		// Test est-ce que la parcelle est une prairie permanente ?
		if (nomChoixModeleCroissancePrairie = "HerbSim" or nomChoixModeleCroissancePrairie = "HerbSimNC") {
			list<string> cultures_rotation <- remove_duplicates(rotationReelle tokenize "_");
			
			if (length(cultures_rotation) = 1 and cultures_rotation contains_any listeNomsEspecesHerbSim) {
				isPrairiePermanente <- true;
			}
		}
		
		if (nomChoixModeleCroissancePlante = "AqYieldNC") {
			//do initVarArbreRegression;
		}
		
	}

	/*
	 * *****************************************************************************************
	 */	
	action initVarArbreRegression {

		list<string> especesPossibles <- especeCultivee collect each.idEspeceCultivee;
		list<string> engraisPossibles <- Engrais collect each.nomEngrais;
		
		loop esp over: especesPossibles {
			nSemisCultures <+ esp::0;
		}
		loop eng over: engraisPossibles {
			nApportProduits <+ eng::0;
			quantitesProduits <+ eng::0.0;
		}
		
		
	}
			
	/*
	 * *****************************************************************************************
	 */		
	action initialisationDonneesSol {
		// La parcelle a besoin de connaitre quelques attributs du type de sol de l'ilot.	
		reserveFacilementUtilisable <- ilot_app.sol.reserveFacilementUtilisableMaximum;			
	}
	
	/*
	 * *****************************************************************************************
	 */
	 action initMemoireDateOT {
		loop OT over: listOT{
			// JV 140121 stocke uniquement si utile
			if (listOTAMemoriser contains OT) or (listOTASuivreEnSortie contains OT) { 							
				put map<int, itk>([]) at: OT in: memoireOTsurParcelle;
				put map<int, float>([]) at: OT in: memoireOTsurParcelleTemps;
				put map<int, map<string,string>>([]) at: OT in: memoireOTsurParcelleComplements;
			}
		}
		memoireSurfaceIrriguee <- map<int,float>([]);	
	}
	/*
	 * *****************************************************************************************
	 */
	 action initMemoirePoolRes {
	 	memoirePoolResSurParcelle <- map<string,int>([]); // Remise à zéro de la mémoire pour l'initialisation ou la nouvelle année civile // NR pool
	 }
	 
	/*
	 * *****************************************************************************************
	 */
	action initDerniereProd {
		loop itkC over: listeITKs {
			list<float> listProd <- [];
			
		    // TODO: BEN
		    //especeCultivee espCultivITK <- itkC.especeCultiveeITK;
		    //float moyenne <- espCultivITK.rendementMoyen;
		    //float ecartType <- (espCultivITK.rendementOptimal - espCultivITK.rendementMin) / 2.0;
		    //listProd <- memoireAgriculteur list_with((surface / nombreMeterCarreDansUnHectare) * TGauss([moyenne,ecartType]));
		    // FIN BEN
		
		    // NEW OLD Verion
		    especeCultivee espCultivITK <- itkC.especeCultiveeITK;
		    float moyenne <- (espCultivITK).rendementMoyen;
		    float ecartType <- (espCultivITK.rendementOptimal - espCultivITK.rendementMin) / 2.0;				
		    loop times: memoireAgriculteur  {
		      listProd << (surface / nombreMeterCarreDansUnHectare) * TGauss([moyenne,ecartType]);
		    }
		    // FIN OLD
		    
		    // OLD Verion
		    //loop times: memoireAgriculteur  {
		    //	float moyenne <- 0.0;
		    //	float ecartType <- 0.0;
		    //	moyenne <- (itkC.especeCultiveeITK).rendementMoyen;
		    //	ecartType <- ((itkC.especeCultiveeITK).rendementOptimal - (itkC.especeCultiveeITK).rendementMin) / 2.0;	
		    //	listProd << (surface / nombreMeterCarreDansUnHectare) * TGauss([moyenne,ecartType]);
		    //}
		    // FIN OLD			

			put listProd in: derniereProduction at: itkC;
		}
	}


	/*
	 * *****************************************************************************************
	 * Appellee depuis ilot
	 */			
	action remiseAzeroParcelle{
		irrigationSouhaitee <- 0.0;
		irrigationReelle <- 0.0;
		
		
		// Remise a zero les variables daffichage
		etatIrrigationParcelle <- ETAT_PAS_IRRIGATION_DEMANDEE;
		
	}
	
	action maj_journ_NC {
		// Action pour mise à jour NC
	}
	
	action affectationCoutIrrigation{
		if (irrigationReelle > zeroApproche) and (isPrelevementEtRejetSimules) and executerModeleHydrographique{
			float coutEau <- 0.0;
			/*
			 * Equations d'arvalis en partie issue de la calculette irrigation
			 * Contact : MARSAC Sylvain <s.marsac@arvalisinstitutduvegetal.fr>
			 */				 
			if(ilot_app.ppaCourant.isASA){
				if((leMarcheAgricole.ASAPrixEau at ilot_app.ppaCourant.idASA) != nil){
						coutEau <- (leMarcheAgricole.ASAPrixEau at ilot_app.ppaCourant.idASA)* (surface/nombreMeterCarreDansUnHectare) ;
					}else{ //Cas Collectif non existant
						coutEau <- (leMarcheAgricole.ASAPrixEau at "NA")* (surface/nombreMeterCarreDansUnHectare) ;
				}
			}else{
				coutEau <- (leMarcheAgricole.prixEau at ilot_app.ppaCourant.natureRessourcePrelevee) +
						   (leMarcheAgricole.redevanceEau at ilot_app.ppaCourant.natureRessourcePrelevee);
			}
			//irrigationReelle [mm] * surface [m2] / 1000 -> [m3] 
			cumulCoutIrrigationSurUnITK <- cumulCoutIrrigationSurUnITK +
										irrigationReelle * (1+EFFICIENCE_PPA_PARCELLE) * //Pour tenir compte des pertes
										surface /1000 * coutEau;
		}
	}
	
	action comportementAnnuel{
		itkIrrigue <- nil;
		isSowingAllowed <- true;
		recolteForcee <- false;
		itkAnnePrec <- getITKAnnee();
		itkRecolteSurAnnee <- [];
		rdtRecolteSurAnnee <- [];
		nbIrrig <- 0;
		//On vide la memoire des OT ayant eu lieu sur la parcelle
		do initMemoireDateOT();
		do initMemoirePoolRes(); // on vide la mémoire des pools de résidus sur la parcelle
		coutIrrigationSurAnnee <- 0.0;
		culture_recoltee_dans_lannee <- "";
		
		// Mise à jour annuelle des temps de retour des PRO
		if (nomChoixModeleCroissancePlante = 'AqYieldNC') {
			loop pro_courant over: parcelleAqYieldNC(self).temps_retour_courant.keys {
				parcelleAqYieldNC(self).temps_retour_courant[pro_courant] <- parcelleAqYieldNC(self).temps_retour_courant[pro_courant] - 1; // On soustrait une année à chaque temps de retour
				if (parcelleAqYieldNC(self).temps_retour_courant[pro_courant] = 0) { // Si le nouveau temps de retour est de 0 on enlève le pro de la liste des temps de retour de la parcelle
					write "Suppression de " + pro_courant;
					parcelleAqYieldNC(self).temps_retour_courant[] >- pro_courant;
				}
				write idParcelle + " -- nom = " + pro_courant + " -- temps de retour = " + parcelleAqYieldNC(self).temps_retour_courant[pro_courant];
			}
		}
		
		// JV 140422 RAZ variables de sorties
		do remiseAZeroSortiesParcelle();
		// RM 240823 Remise à 0 des OT si parcelle en prairiep
		if (cultureParcelle != nil) {
			if (cultureParcelle.espece.idEspeceCultivee = "prairiep") {
				do remiseAZeroITKprairiep;
			}
		}
		
		// RM 251023 Autorisation de récolte de prairie si on passe le 1er janvier
		//write 'remise à zéro parcelle';
		// NR utilité? -> plutot déterminer de la faisabilité de l'activité de récolte dans strategieRecolte....
		recoltePrairieAnneeOK <- true;

	}

	/*
	 * *****************************************************************************************
	 * Methode appellee des lors que la parcelle recoit de l'eau dirrigation (peut etre appelee plusieurs fois)
	 */			
	action hauteurEauIrrigationARajouter{
		arg quantiteEauARajouter type: float default: 0.0; // en mm
		
		irrigationSouhaitee <- irrigationSouhaitee + quantiteEauARajouter;
		irrigationReelle <- irrigationSouhaitee; 
		// Dans le cas ou il ny a pas swat, on considere que lirrigation souhaitee est tj = a la reelle, mais dans le cas ou il y a swat, alors on va recalculer lirrigation reelle								
		if(executerModeleHydrographique and isPrelevementEtRejetSimules){
			irrigationReelle <- 0.0;
		}	
	}
	/*
	 * *****************************************************************************************
	 */			
	action calculEauEntreeReelleSurParcelle{	 
		pluieEtIrrigation <- getPluie() + irrigationReelle; // [mm]	
		
		// Mise a jour des variables pour laffichage
		// Si il y a une culture irrigable sur la parcelle courante
		if (cultureParcelle != nil and cultureParcelle.isIrrigable()){
			 // ATTENTION : ne peut pas y avoir une irrigation souhaitee si il y a restriction le jour courant sur la parcelle car lagri prend en compte en amont le niv de restriction pour faire sa demande deau
			// Si on veut irriguer au pas de temps courant
			if(irrigationSouhaitee > zeroApproche and !ilot_app.isEnRestrictionJourCourant()){
				// Il ny a pas assez deau pour irriguer
				if(irrigationReelle <= zeroApproche){
					etatIrrigationParcelle <- ETAT_PAS_DEAU;
				}
				// Il ny a pas assez deau pour tout irriguer
				else if(irrigationReelle > zeroApproche and irrigationReelle < (irrigationSouhaitee - zeroApproche)){
					etatIrrigationParcelle <- ETAT_PAS_ASSEZ_DEAU;							
				}
				// On peut irriguer correctement
				else if(irrigationReelle >= (irrigationSouhaitee - zeroApproche) and irrigationReelle < (irrigationSouhaitee + zeroApproche)){ // Ne doit pas etre de bcp sup a lirrigation souhaitee : cest just au cas ou il y aurait un pb dans les arrondis
					etatIrrigationParcelle <- ETAT_ASSEZ_DEAU;		
				}																						
			}else{
				if(ilot_app.isEnRestrictionJourCourant()){
					// La culture est en restriction, et elle nest donc pas irriguee (il est possible quelle ne le soit pas car il ny a plus deau)
					if(irrigationReelle <= zeroApproche){
						etatIrrigationParcelle <- ETAT_RESTRICTION;
					}
					// Malgre la restriction, la culture est irriguee (car stress hydrique)
					else if(irrigationReelle > zeroApproche){
						etatIrrigationParcelle <- ETAT_IRRIGATION_CONTRE_RESTRICTION;
					}						
				}
			}				
		}
	}

	/*
	 * *****************************************************************************************
	 * C'est l'eau totale qui ressort en surface apres la croissance de la plante
	 */
	float calculQuantiteEauDeRuissellement{					
		if (cultureParcelle != nil){ /// and cultureParcelle.isIrrigable()){		
			//0. Croissance de la plante
			ask cultureParcelle{
				ask monModelDeCulture{
					do croissanceCulture();	
				}
			}

			// 1. Demande ou apport au sol
			ES <- (pluieEtIrrigation) - cultureSimple(cultureParcelle.monModelDeCulture).etm; // [mm]
			
			//2. Bilan sol = reserveFacilementUtilisable
		 	reserveFacilementUtilisable <- reserveFacilementUtilisable + ES; // [mm]
		 	if(reserveFacilementUtilisable < 0.0){
		 		reserveFacilementUtilisable <- 0.0;
		 	}
		 	// Verification du RFU : si il est trop rempli (plus que lafuMax) alors il y a ruissellement			
			quantiteEauDeRuissellement <- 0.0;
			if (reserveFacilementUtilisable > ilot_app.sol.reserveFacilementUtilisableMaximum){
				quantiteEauDeRuissellement <- (reserveFacilementUtilisable - ilot_app.sol.reserveFacilementUtilisableMaximum);
				reserveFacilementUtilisable <- ilot_app.sol.reserveFacilementUtilisableMaximum;
			}			 	
		}else{
			quantiteEauDeRuissellement <- pluieEtIrrigation;
		}

		return quantiteEauDeRuissellement; // [mm]
	}

	/*
	 * *****************************************************************************************
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEvapoTranspiration{ return 0.0; }

	/*
	 * *****************************************************************************************
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEcoulementEauSouterraine{ return 0.0; }

	/*
	 * Appelee depuis l'ilot, dans la methode ruissellementVersZH
	 * Elle met a jour des variables utiles pour le calcul du rendement
	 */
	action majPourCalculRendement{
		// Une fois la valeur du ruissellement calculee on peut calculer le rendement de la culture
	 	if(cultureParcelle != nil){
	 		ask (cultureParcelle.monModelDeCulture){
	 			do majPourCalculRendement();
	 		}
	 	}
	}		
	
	/*
	 * Appellee depuis la strat de recolte juste avant la suppression de la culture: donc on peut encore acceder aux valeurs de celles-ci
	 */
	float calculRendement {
		float res <- -2.0;
		if(cultureParcelle != nil){
			ask (cultureParcelle.monModelDeCulture){
				res <- calculRendement();
			}
		}else{
			res <- 0.0;
		}		
		return res;
	}
	
	
	// JV 121221 CA=surface*prix*rendement potentiel
	float getEsperanceChiffreAffaires(agriculteur agri){
		float esperanceCA <- 0.0;

		// JV 121221 uniquement si marche agricole defini
		if leMarcheAgricole!=nil {
			especeCultivee maCulture <- getITKAnnee().especeCultiveeITK;
			float prixCulture <- leMarcheAgricole.prix_recoltes[maCulture];
			esperanceCA <- surface/nombreMeterCarreDansUnHectare * prixCulture * maCulture.rendementOptimal;
		}
		
		return esperanceCA;
	}
	
	float getEsperanceProfit(agriculteur agri){
		float esperanceProfit <- 0.0;
		 
		// JV 100821 uniquement si marche agricole defini
		if leMarcheAgricole!=nil {
			itk it <- self.getITKAnnee();
			float chargesOpLoc <- leMarcheAgricole.chargesOperationelles at it; //[€/ha]
			float prime <- (leMarcheAgricole.prime_par_departement at ilot_app.agriculteurAssocie.sonExploitation.id_departement) at it.especeCultiveeITK ; //[€/ha]
			ask (agri.listMemoire) where ((each.itkAssocie = it) and (each.blocMemoire = self.bloc_app)){
				esperanceProfit <- esperanceProfit + 
				get2ERendementsObserves5ans()*get2EPrixObserves3ans()  //[€/ha]
				- chargesOpLoc - get2EChargesDePassage3ans() + prime ; //[€/ha]
			}
		}
		return esperanceProfit;
	}

	/*
	 * *****************************************************************************************
	 *  ACCESSEURS : 
	 */	
	bool isEnStressHydrique{	// Appellee dans strategie dirrigation
		if (cultureParcelle != nil and cultureParcelle.isIrrigable()){		
			ask (cultureParcelle as cultureIrrigable){
				return isEnStressHydrique();
			}
		}else{
			return false;
		}			
	}
	float getSurfaceIrrigueeJourCourant{
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			if(cultureParcelle.isIrrigable()){
				resultat <- cultureIrrigable(cultureParcelle).getSurfaceIrrigueeJourCourant();
			}				
		}
		return resultat;
	}
	bool isParcelleIrrigable {
		return ilot_app.isIrrigable;	
	}
	float getVolumeIrrigueReel{
		return (irrigationReelle / nombreMillimetreDansUnMetre) * surface;
	}
	float getVolumePluie{
		return (getPluie() / nombreMillimetreDansUnMetre) * surface;
	}
	float getPluie{
		if (isNeige){
			return ilot_app.bandeAltiAssocie.precipitations;
		}else{
			return ilot_app.meteo.pluie ;
		}
	}
	float getTmoy{
		if (isNeige){
			return ilot_app.bandeAltiAssocie.temperatureMoy;
		}else{
			return ilot_app.meteo.tMoy ;
		}
	}
	float getTmax{
		if (isNeige){
			return ilot_app.bandeAltiAssocie.temperatureMax;
		}else{
			return ilot_app.meteo.tMax ;
		}
	}
	float getTmin{
		if (isNeige){
			return ilot_app.bandeAltiAssocie.temperatureMin;
		}else{
			return ilot_app.meteo.tMin ;
		}
	}
	
	int getNdaysBeforeSignifRain(int length_period) {
		list<float> future_rainfalls <- ilot_app.meteo.liste_pluies_futur(length_period);
		float next_signif_rain <- future_rainfalls first_with (each  >= 3);
		int nDays <- future_rainfalls index_of (next_signif_rain) + 1;
		
		return nDays;
	}
	
	float getEchelleVegetation{ // echV
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.echV;
		}
		return resultat;
	}
	
	bool getIsMaturiteOk {
		bool resultat <- false;
			
		if (cultureParcelle != nil and (!cultureParcelle.monModelDeCulture.espece.isCouvert and species(cultureParcelle.monModelDeCulture)= cultureAqYieldNC or species(cultureParcelle.monModelDeCulture)= cultureAqYield)){
			float degJMat <- cultureParcelle.monModelDeCulture.espece.degresJourMaturiteCult;
			float degJsomme <- cultureAqYield(cultureParcelle.monModelDeCulture).sommeDegresJourCulture;
			if (degJsomme >= degJMat) {
				resultat <- true;
			}
		} else {
			resultat <- true; // On ne regarde pas la maturité pour récolter autre chose que des cultureAqYield (ex : prairie)
		}
		return resultat;
	}
	
	float getHumiditeSol{ // %
		return (reserveFacilementUtilisable / ilot_app.sol.reserveFacilementUtilisableMaximum);
	}
	float getHumiditeSolRacine{
		return getHumiditeSol();
	}
	action setRUs(float donnee){}					
	
	float getKc{// kc
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureSimple(cultureParcelle.monModelDeCulture).kc;
		}
		return resultat;
	}		 
	float getRendementDerniereCulture{ // rendement
		return (rendementParJoursRecoltes at idJourDerniereRecolte);
	}
	int getCompteurAnnee{ // Appelee dans les plans dassoelemnt des fonctions de croyance, ou il est possible que le systemeDeCultureParcelle soit nulle 
		if(systemeDeCultureParcelle != nil){
			return systemeDeCultureParcelle.compteurAnnee;
		}else{
			return 1;
		}
	}
	itk getITKAnnee{
		if(systemeDeCultureParcelle != nil){
			return systemeDeCultureParcelle.getITKanneeCourante();
		}else{
			return nil;
		}
	}
	itk getITKPlanned{
		return systemeDeCultureParcelle.rotation[systemeDeCultureParcelle.indiceItkCourant];
		/*
		ask systemeDeCultureParcelle{
			return (rotation at indiceItkCourant);
		}
		*/
	}
	itk getITKDeSaisonSuivante(bool isCultureRechercheHivernale){
		return systemeDeCultureParcelle.getITKDeSaisonSuivante(isCultureRechercheHivernale);
	}
	action setITKAlternatif(itk itkDeRemplacement){
		ask systemeDeCultureParcelle{
			do setITKAlternatif(itkDeRemplacement);
		}
		itkAlternatif <- true;
		/* JV disabeled 18032020
		//Determination de la possibilite de semer cette annee 
		if (!itkDeRemplacement.isCultureHiver){
			isSowingAllowed <- false;
		}		
		*/
	}	
	/*
	 * *****************************************************************************************
	 * DEBUT GROUPE IRRIGATION
	 */			 		 		
	float getVolumeIrrigation(string type){		// [m3]	
		if(type = REEL){
			return irrigationReelle*surface / nombreMillimetreDansUnMetre;
		}else if(type = SOUHAITE){
			return irrigationSouhaitee*surface / nombreMillimetreDansUnMetre;
		}			
	}	
	float getSurfaceTotaleGroupesIrr{
		float somme <- 0.0;
		ask listeGroupeIrrigationCulture{
			somme <- somme + surface;
		}			
		return somme;
	}
	float getSurfaceTotalePouvantEtreIrriguee{
		float somme <- 0.0;
		if(nomChoixModeleIrrigation = Simple){ // TODO : supprimer // ??? Pourquoi vouloir le supprimer ? // pas code mort
			if(cultureIrrigable(cultureParcelle).dernierTourEau = 0){
				somme <- surface;
			}
		}else{
			ask listeGroupeIrrigationCulture{
				somme <- somme + getSurfaceIrrigableJourCourant();
			}				
		}				
		return somme;
	}		
	action applicationRetardIrrigation(int nbJoursRetard, int idGroupe){
		if(nomChoixModeleIrrigation = Simple){
			cultureIrrigable(cultureParcelle).dernierTourEau <- cultureIrrigable(cultureParcelle).dernierTourEau + nbJoursRetard;
		}else{
			ask getGroupe(idGroupe){
				do ajoutRetardIrrigation(nbJoursRetard);
			}				
		}				
	}
	float getSurfacePouvantEtreIrriguee(int idGroupe){
		if(idGroupe = nil){
			return getSurfaceTotalePouvantEtreIrriguee();
		}if(idGroupe < 1){
			return getSurfaceTotalePouvantEtreIrriguee();
		}else{
			return getGroupe(idGroupe).getSurfaceIrrigableJourCourant();
		}
	}
	groupeIrrigationCulture getGroupe(int idGroupe){
		groupeIrrigationCulture gp <- first(listeGroupeIrrigationCulture where (each.indiceGroupe = idGroupe));			
		return gp;
	}
	/*
	 * *****************************************************************************************
	 * FIN GROUPE IRRIGATION
	 */		
	// donne l'indication sur si la parcelle va avoir cette annee une culture irriguee ou non
	bool isIrrigueeAnneeCourante{
		if(getITKAnnee() != nil){
			if(getITKAnnee().isIrriguee()){	
				return true;
			}			
		}
		return false;
	}
	strategieOT getStrategie(string strategie){
		if(getITKAnnee() != nil){
			switch strategie {
	        	match SEMIS {
	        		return getITKAnnee().strategieSemisITK;                 
	            }
	        	match RECOLTE {
	               return getITKAnnee().strategieRecolteITK;       
	            } 
	            match IRRIGATION {
	            	return getITKAnnee().strategieIrrigationITK;       
	            } 
	            match TRAVAIL_SOL { // Gestion travaux du sol multiple Renaud 18/03/2020
					if !(plusieursTravauxDuSolParITK) {
						return getITKAnnee().strategieTravailSolITK;
					} else {
						if getITKAnnee().strategieTravailSolITK!=nil {return getITKAnnee().strategieTravailSolITK.getProchaineOT(self);} else {return nil;} // JV 150424 depuis 1.9.3 ne peut pas appeler getProchaineOT si strategieTravailSolITK est nil  
					}
	            } 
	            match BINAGE_SOL {
	            	return getITKAnnee().strategieBinageSolITK;       
	            }
	            match REPRISE_TRAVAIL_SOL {
	            	return getITKAnnee().strategieRepriseTravailSolITK;       
	            }
	            match FERTI {
	            	if !(plusieursFertilisationsParITK) { // Gestion des apports de fertilisation Renaud 24/03/2020
	            		return getITKAnnee().strategieFertiITK;
	            	} else {
	            		if (parcelleAqYieldNC(self).alternative_selectionnee != nil) {
	            			return parcelleAqYieldNC(self).alternative_selectionnee.getprochainApport(parcelleAqYieldNC(self));
	            		}
	            	}
            	}
	            match PHYTO {
					if !(plusieursTraitementsPhytoParITK) {
						return getITKAnnee().strategiePhytoITK;
					} else {
						if getITKAnnee().strategiePhytoITK!=nil {return getITKAnnee().strategiePhytoITK.getProchaineOT(self);} else {return nil;} // JV 150424 idem
					}
	            }
	            match FAUCHE {
					if getITKAnnee().strategieFaucheITK!=nil {return getITKAnnee().strategieFaucheITK.getProchaineOT(self);} else {return nil;} // JV 150424 idem
	            }
	        }				
		}else{
			return nil;
		}
	}
	
	
	// JV 260321 utilisé dans construction groupes d'irrigation: on doit savoir si au moins ITK prévu cette année est irrigué pour savoir si la parcelle doit appartenir à un groupe d'irrigation ou non
	/* 	renvoie la liste des ITK prévus cette année (i.e. au moins semés cette année: on parcourt les dates de récolte plutôt que les dates de semis pour ne pas avoir de pb selon qu'on démarre par culture hiver/printemps)
	 * 	debutRecoltePrec = 0
		ITKcour = ITK_au_premier_janvier
		tant que ITKcour.debutRecolte > debutRecoltePrec{
			listeITKAnnee.ajoute(ITKcour)
			debutRecoltePrec = ITKcour.debutRecolte
			ITKcour = ITK suivant dans la rotation
		}			
		// dernier ITK non selectionne: non récolté cette année mais on regarde s'il est semé ou pas cette année	
		// -> si semé on le prend quand même
		si ITKcour.debutSemis > debutRecoltePrec
			listeITKAnnee.ajoute(ITKcour)
  	*/
	list<itk> getItkPrevusCetteAnnee{
		
		list<itk> listeItkPrevusCetteAnnee <- [];
		int debutRecoltePrec <- 0;
		itk itkCourant <- getITKAnnee();		
				
		loop while: itkCourant.strategieRecolteITK.getJourJulienDebutMin(0) > debutRecoltePrec{			
			listeItkPrevusCetteAnnee << itkCourant;
			debutRecoltePrec <- itkCourant.strategieRecolteITK.getJourJulienDebutMin(0);
			itkCourant <- systemeDeCultureParcelle.getITKanneeSuivante(); // getITKanneeSuivante = ITK suivant dans la rotation -> à renommer			
		}	
		
		// dernier ITK non selectionne: non récolté cette année mais on regarde s'il est semé ou pas cette année	
		// -> si semé on le prend quand même
		if itkCourant.strategieSemisITK.getJourJulienDebutMin(0) > debutRecoltePrec{	
			listeItkPrevusCetteAnnee << itkCourant;
		}
		
		return listeItkPrevusCetteAnnee;
	}
	
	list<itk> getItkIrriguesPrevusCetteAnnee{
		return getItkPrevusCetteAnnee() where each.isIrriguee();
	}
	
	bool auMoinsUnItkIrrigueCetteAnnee{				
		return length(getItkIrriguesPrevusCetteAnnee())>0;
	}		
	
	/*
	 * *****************************************************************************************
	 * Accesseur couleur
	 */
	rgb getCouleurIsIrrigable{
		return ilot_app.getCouleurIsIrrigable();
	}	
	rgb getCouleurIsParcelleUtile{
		if(!isParcelleUtile){
			return rgb('red');							
		}else{
			return rgb('green');	
		}
	}
	rgb getCouleurEsEnRestriction{
		if(ilot_app.isEnRestrictionJourCourant()){
			return rgb('red');							
		}else{
			return rgb('green');	
		}
	}
	rgb getCouleurEsEnStressHydrique{			
		if(isEnStressHydrique()){
			return rgb('red');							
		}else{
			return rgb('green');	
		}
	}		
	rgb getCouleurNiveauRestriction{			
		if(ilot_app.getNbJoursRestriction() = 0){
			return rgb('white');							
		}else{
			return rgb(paletteCouleursNbJourRestriction at ilot_app.getNbJoursRestriction());
		}
	}	
	rgb getCouleurCulture{
		if(cultureParcelle != nil and !dead(cultureParcelle)){
			return (cultureParcelle.espece).couleur;
		}
	}
	rgb getCouleurIbio {
		if(ibio_biodiversity = "Very low"){return rgb(79,25,56);}
		else if (ibio_biodiversity = "Low") {return rgb(234,153,153);}
		else if (ibio_biodiversity = "Medium") {return rgb(234,230,101);}
		else if (ibio_biodiversity = "High") {return rgb(140,198,63);}
		else if (ibio_biodiversity = "Very high") {return rgb(153,0,0);}
	}
	rgb getCouleurCoefCultural{
		if(cultureParcelle != nil and !dead(cultureParcelle)){
			return cultureParcelle.monModelDeCulture.couleurCoefficientCultural;
		}
	}
	rgb getCouleurIsIrriguee{
		if(isIrrigueeAnneeCourante()){
			return couleurBleuClaire;
		}else{
			return couleurVertClaire;
		}
	}		
	rgb getCouleurEtatIrrigation{
		// En fonction de letat dirrigation de la parcelle (pas irriguee en entier car pas assez deau, ou car restriction...)
		if(etatIrrigationParcelle = ETAT_PAS_IRRIGATION_DEMANDEE){
			return rgb('white');
		}else if(etatIrrigationParcelle = ETAT_PAS_DEAU){
			return couleurOrange;
		}else if(etatIrrigationParcelle = ETAT_PAS_ASSEZ_DEAU){
			return paletteCouleursCoefficientCultural at (int(irrigationReelle / irrigationSouhaitee * 10)); // Compris entre [0,1] * 10 => [0,10] + 2 => [2,12]							
		}else if(etatIrrigationParcelle = ETAT_ASSEZ_DEAU){
			return couleurVertClaire;
		}else if(etatIrrigationParcelle = ETAT_RESTRICTION){
			return rgb('lightGray');
		}else if(etatIrrigationParcelle = ETAT_IRRIGATION_CONTRE_RESTRICTION){
			return couleurRouge;
		}else{
			return rgb("black");
		}
	}
	rgb getCouleurRFU{			
		return rgb('white');
	}
	bool isAffichage{
		if(cultureParcelle != nil and !dead(cultureParcelle)){								
			if((cultureParcelle).isIrrigable()){
				return true;						
			}					
		}
		return false;
	}		
	string getMessageAffiche{
		if(name = nomParcelleAffichee and getITKAnnee() != nil){
			return (name + 'Culture = ' + (getITKAnnee().especeCultiveeITK).idEspeceCultivee + '/ Sol = ' + ilot_app.getNomZonePedo());
		}	
		return "";
	}
	
	float addRevapparcelle(float eau){
		float eauNonTransmissible <-0.0;
		if ((eau + reserveFacilementUtilisable) >ilot_app.sol.reserveFacilementUtilisableMaximum){
			eauNonTransmissible <- eau + reserveFacilementUtilisable - reserveFacilementUtilisable;
			reserveFacilementUtilisable <- ilot_app.sol.reserveFacilementUtilisableMaximum;
		}else{
			reserveFacilementUtilisable <- reserveFacilementUtilisable +eau;
		}
		return eauNonTransmissible;
	}

	// JV 280618 redefini dans ParcelleAqYield, interet sans AqYield ?
	float getHumiditeHorizonTotal{
		return 0.0;
	}
	
	agriculteur getAgriculteur{
		return ilot_app.agriculteurAssocie;
	}
	
	// JV 130422 MAJ des variables de sortie, redéfinie dans parcelleAqYield
	action comportementJournalier{}
	
	// JV 130422 MAJ des variables de sortie, appelé le 31 décembre pour finaliser la dernière période de couvert	
	action comportementFinAnnuel{
		int indiceCouvertCourant <- length(sorties_jDebutCouvert)-1;
		sorties_jFinCouvert[indiceCouvertCourant] <- dateCour.nbJoursEcoulesDansAnnee; // 365 ou 366
	}	
	
	// JV 130422 initialisation périodes couverts début simulation (sol nu)
	action initSortiesParcelle {
		
		sorties_jDebutCouvert <- [dateCour.calculNbJourEcouleDansAnnee(jourDebutSimulation, moisDebutSimulation)]; // car à l'initialisation, [dateCour.nbJoursEcoulesDansAnnee] (date de début de simulation) n'est pas initialisée
		sorties_jFinCouvert <- [0]; // 0 car valeur pas encore connue (sera renseignée le jour du premier semis)
		sorties_especeCouvert <- [nil]; // sol nu
		sorties_itkCouvert <- [nil]; // sol nu
		
		// init variables eau uniquement si AqYield ou AqYieldNC
		if (nomChoixModeleCroissancePlante = AqYield) or (nomChoixModeleCroissancePlante = AqYieldNC) {
			ask parcelleAqYield(self) {
				sorties_evaporation <- [0.0];
				sorties_transpiration <- [0.0];
				sorties_percolation <- [0.0];
				sorties_capilarite <- [0.0];
				sorties_ruisselement <- [0.0]; // MD 30082023
				sorties_Hr_debut <- [Hr]; // on prend le Hr du premier jour de simulation
				sorties_Hm_debut <- [Hm]; // on prend le Hm du premier jour de simulation
				sorties_Hr_fin <- [0.0];
				sorties_Hm_fin <- [0.0];
				sorties_Hr_1janv <- [-1.0]; // à -1 car la simulation ne commence pas un 1er janvier donc on ne connaît pas la valeur réelle au 1er janvier
				sorties_Hm_1janv <- [-1.0]; // idem
				sorties_satisfactionHydrique <- [0.0];
				sorties_pluie <- [0.0];
				sorties_irrigation <- [0.0];
				sorties_sommeDegresJourCulture <- [0.0];				
			}
		} // init variables N uniquement si AqYieldNC
		if nomChoixModeleCroissancePlante = AqYieldNC {
			ask parcelleAqYieldNC(self) {
				// sorties N
				sorties_N_lixivie <- [0.0];
				sorties_N_volatilise_NH3 <- [0.0];
				sorties_N_mineralise_net_PRO <- [0.0];
				sorties_N_mineralise_net_SOM <- [0.0];
				sorties_N_mineralise_net_residus <- [0.0];
				sorties_N_acquis_couvert <- [0.0];
				sorties_N_mineral_debut <- [QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p]; // on prend les valeurs du premier jour de simulation
				sorties_N_mineral_fin <- [0.0];				
				sorties_emissions_N2O_directes <- [0.0];
				sorties_emissions_N2 <- [0.0];
				sorties_satisfactionAzote_cult <- [0.0];
				sorties_satisfactionAzote_ci <- [0.0];
				sorties_N_fixe_legumineuses <- [0.0];
				// sorties C et GES
				sorties_emissions_N2O_denit <- [0.0];
				sorties_emissions_N2O_nit <- [0.0];
				sorties_emissions_N2O_N_volat <- [0.0];
				sorties_emissions_N2O_N_lixiv <- [0.0];
				sorties_emissions_ferti <- [0.0];
				sorties_bilan_net_GES <- [0.0];
				sorties_tx_Corg_Arg <- [0.0];		
				sorties_delta_Corg <- [0.0];		
				sorties_tx_MO_fin <- [0.0];										
			}
		}	
					
	}

	// JV 130422 RAZ périodes couverts: appelée le 1er janvier par parcelle.comportementAnnuel
	action remiseAZeroSortiesParcelle {
		
		sorties_jDebutCouvert <- [1]; // 1ere periode de l'année commence jour 1
		sorties_jFinCouvert <- [0]; // 0 car valeur pas encore connue (sera renseignée le jour de la récolte si couvert courant est une culture, jour du semis suivant si couvert courant est un sol nu	

		especeCultivee dernierCouvert <- last(sorties_especeCouvert); // dernier couvert en place le 31 decembre
		sorties_especeCouvert <- [dernierCouvert]; // la nouvelle année commence avec le dernier couvert  

		itk dernierITK <- last(sorties_itkCouvert); // dernier itk en cours au 31 decembre
		sorties_itkCouvert <- [dernierITK];

		// RAZ variables eau uniquement si AqYield ou AqYieldNC
		if (nomChoixModeleCroissancePlante = AqYield or nomChoixModeleCroissancePlante = AqYieldNC) {
			ask parcelleAqYield(self) {
				do remiseAZeroSortiesEau();
			}
		}	
		if nomChoixModeleCroissancePlante = AqYieldNC {
			ask parcelleAqYieldNC(self) {
				do remiseAZeroSortiesAzote();
				do remiseAZeroSortiesCarboneGES();
			}
		}	
	}
	
	// JV 130422 MAJ des variables de sortie lors d'un changement de couvert (semis [sol nu -> culture] ou récolte [culture -> sol nu]) appelée dans strategieSemis.miseEnOeuvreActivite et strategieRecolte.miseEnOeuvreActivite
	action changementCouvertSortiesParcelle(string ot) {
		// on cloture le couvert précédent (si SEMIS: couvert prec=sol nu, si RECOLTE, couvert prec=culture)
		// si SEMIS: le jour courant fait partie du nouveau couvert (la culture): jour fin du couvert précédent = j-1 
		// si RECOLTE: le jour courant fait partie du couvert précédent (la culture): jour fin du couvert précédent = j
		// si SEMIS: on ne fait rien pour le couvert précédent, les variables pour le nouveau couvert seront MAJ en fin de journée par via parcelle.comportementJournalier
		// si RECOLTE: il faut explicitement appeler la MAJ des variables pour les intégrer au couvert précédent, et désactiver l'appel à MAJ dans comportementJournalier pour le jour courant
		int indiceCouvertCourant <- length(sorties_jDebutCouvert)-1;
		if ot=RECOLTE 	{sorties_jFinCouvert[indiceCouvertCourant] <- dateCour.nbJoursEcoulesDansAnnee; desactivationMAJsorties <- true;}
		if ot=SEMIS		{sorties_jFinCouvert[indiceCouvertCourant] <- dateCour.nbJoursEcoulesDansAnnee-1;}
		if ot=RECOLTE and ((nomChoixModeleCroissancePlante = AqYield) or (nomChoixModeleCroissancePlante = AqYieldNC)) {
			ask parcelleAqYield(self) {
				do majSortiesEau; // si RECOLTE les variables comptent pour le couvert précédent (la culture)
				/*
				sorties_Hr_fin <+ Hr; // si RECOLTE on renseigne Hr/Hm_fin du couvert précédent 
				sorties_Hm_fin <+ Hm;	
				*/
			}
		}				
		if ot=RECOLTE and nomChoixModeleCroissancePlante = AqYieldNC {
			ask parcelleAqYieldNC(self) {
				do majSortiesAzote;  // si RECOLTE les variables comptent pour le couvert précédent (la culture)
				do majSortiesCarboneGES;				
				//sorties_N_mineral_fin <+ QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p;
				//sorties_stock_Corg_fin <+ delta_Chum_sortie;
				//sorties_tx_MO_fin <+ OM_perc;
			}
		}
		
		// on démarre un nouveau couvert: si RECOLTE: jour début = j+1, si SEMIS, jour début = j
		if ot=RECOLTE 	{sorties_jDebutCouvert <+ dateCour.nbJoursEcoulesDansAnnee+1;}
		if ot=SEMIS 	{sorties_jDebutCouvert <+ dateCour.nbJoursEcoulesDansAnnee;}
		sorties_jFinCouvert <+ 0; // sera renseigné le jour de la récolte ou du semis
		
		// init variables eau nouveau couvert		
		switch ot {
			match SEMIS {
				sorties_itkCouvert <+ getITKAnnee();
				sorties_especeCouvert <+ getITKAnnee().especeCultiveeITK;	
			}
			match RECOLTE { // sol nu après récolte
				sorties_itkCouvert <+ nil;
				sorties_especeCouvert <+ nil;
			} 
			default {}
		} 
		
		if (nomChoixModeleCroissancePlante = AqYield) or (nomChoixModeleCroissancePlante = AqYieldNC) {
			ask parcelleAqYield(self) {
				sorties_evaporation <+ 0.0; // on ne prend pas l'évaporation du jour car on l'a comptée pour le couvert précédent
				sorties_transpiration <+ 0.0;
				sorties_percolation <+ 0.0;
				sorties_capilarite <+ 0.0;
				sorties_ruisselement <+ 0.0; // MD 30082023
				sorties_Hr_debut <+ Hr;
				sorties_Hm_debut <+ Hm;						
				sorties_Hr_fin <+ 0.0;
				sorties_Hm_fin <+ 0.0;						
				float tmp <- last(sorties_Hr_1janv); // on reprend le hr 1er janv du couvert en cours
				sorties_Hr_1janv <+ tmp;
				tmp <- last(sorties_Hm_1janv); // on reprend le hm 1er janv du couvert en cours
				sorties_Hm_1janv <+ tmp;
				sorties_satisfactionHydrique <+ 0.0;
				sorties_pluie <+ 0.0;
				sorties_irrigation <+ 0.0;
				sorties_sommeDegresJourCulture <+ 0.0;
			}
		}
		if nomChoixModeleCroissancePlante = AqYieldNC {
			ask parcelleAqYieldNC(self) {
				// sorties N
				sorties_N_lixivie <+ 0.0;
				sorties_N_volatilise_NH3 <+ 0.0;
				sorties_N_mineralise_net_PRO <+ 0.0;
				sorties_N_mineralise_net_SOM <+ 0.0;
				sorties_N_mineralise_net_residus <+ 0.0;
				sorties_N_acquis_couvert <+ 0.0;
				sorties_N_mineral_debut <+ QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p; // on prend les valeurs du premier jour du couvert
				sorties_emissions_N2O_directes <+ 0.0;
				sorties_emissions_N2 <+ 0.0;
				sorties_satisfactionAzote_cult <+ 0.0;
				sorties_satisfactionAzote_ci <+ 0.0;
				sorties_N_fixe_legumineuses <+ 0.0;
				sorties_N_mineral_fin <+ 0.0;
				// sorties C et GES
				sorties_emissions_N2O_denit <+ 0.0;
				sorties_emissions_N2O_nit <+ 0.0;
				sorties_emissions_N2O_N_volat <+ 0.0;
				sorties_emissions_N2O_N_lixiv <+ 0.0;
				sorties_emissions_ferti <+ 0.0;
				sorties_bilan_net_GES <+ 0.0;
				sorties_tx_Corg_Arg <+ 0.0;
				sorties_delta_Corg <+ 0.0;		
				sorties_tx_MO_fin <+ 0.0;				
			}
		}
		
	}
	
	// Remise à zéro de toute l'itk prairiep : celui-ci n'est jamais récolté, il faut remettre les OT à 0 chaque année (01/01) pour quelles se répètent
	action remiseAZeroITKprairiep {
		critereRecolteOk_echV <- 0 ;
		critereRecolteOk_HumiditeSol <- 0 ;
		critereRecolteOk_Pluie <- 0 ;
		
		isTravailSolEffectue <- false;
		OTTravailSolMultiplesEffectuee <- nil;
		OTPhytoMultiplesEffectuee <- nil;
		OTFaucheMultiplesEffectuee <- nil;
		isBinagesSolEffectue <- false; 
		isPhytoDeLaPeriodeEffectue <- map<int,bool>([]);	
		isFertiDeLaPeriodeEffectue <- map<int,bool>([]);
	}		
	
	// JV 200725 appelée dans strategieRecolte.isActivitePossible et dans agriculteur.activiteRecolteForcee
	bool isConditionAgeOk {
		return (cultureParcelle.age_culture > ageMinPourRecolte);
	}
	

	/*
	 * *****************************************************************************************
	 * Display
	 */					
	aspect basic{
		draw shape color: rgb([255,153,51]) wireframe: false border: rgb([255,153,51]);
	}
	aspect ibio {
		draw shape color: getCouleurIbio() wireframe: false border: getCouleurIbio();
	}
	
	aspect videoAspect{
		if(dateCour.jour != 1 and dateCour.mois != 1){
			draw shape color: getCouleurCulture() wireframe: false border: getCouleurCulture();
		}    		
	}
	aspect cultureAspect{
		if(cultureParcelle != nil and !dead(cultureParcelle)){			
			if(name = nomParcelleAffichee and getITKAnnee() != nil){
				draw shape color: rgb('red') wireframe: false border: rgb('red');
				draw getMessageAffiche() at: location color: rgb('black') size: tailleTexte;
			}else{
				draw shape color: getCouleurCulture() wireframe: false border: getCouleurCulture();
			}
		}   		
	}
	aspect coefficientCulturalCulturePrincpaleAspect{
		if(cultureParcelle != nil and !dead(cultureParcelle)){	
			if(name = nomParcelleAffichee and getITKAnnee() != nil){
				draw shape color: rgb('red') wireframe: false border: rgb('red');
				draw getMessageAffiche() at: location color: rgb('black') size: tailleTexte;
			}else{
				draw shape color: getCouleurCoefCultural() wireframe: false border: getCouleurCoefCultural();
			}
		}
	}
 	aspect rfuParcelleAspect{
		draw shape color: getCouleurRFU() wireframe: false border: getCouleurRFU();
	}
	aspect ilotIrrigableAspect{
		if(name = nomParcelleAffichee and getITKAnnee() != nil){
			draw shape color: rgb('red') wireframe: false border: rgb('red');
			draw getMessageAffiche() at: location color: rgb('black') size: tailleTexte;
		}else{
			draw shape color: getCouleurIsIrrigable() wireframe: false border: getCouleurIsIrrigable();
		}
	}
	aspect ilotIrrigueAspect{
		draw shape color: getCouleurIsIrriguee() wireframe: false border: getCouleurIsIrriguee();
 	}
  	aspect parcellePrincipaleEnRestricton{
		if(isAffichage()){
			draw shape color: getCouleurEsEnRestriction() wireframe: false border: getCouleurEsEnRestriction();
		}
	}  
 	aspect parcellePrincipaleEnFonctionDuNiveauDeRestriction{
		if(isAffichage()){
			draw shape color: getCouleurNiveauRestriction() wireframe: false border: getCouleurNiveauRestriction();
		}
	}   	
 	aspect etatIrrigationParcelle{
		if(isAffichage()){
			draw shape color: getCouleurEtatIrrigation() wireframe: false border: getCouleurEtatIrrigation();   		
		}
	} 
	aspect ilotEnStressHydrique{
		if(isAffichage()){
			draw shape color: getCouleurEsEnStressHydrique() wireframe: false border: getCouleurEsEnStressHydrique();
		}
	}
	aspect IsParcelleUtileAspect{
		draw shape color: getCouleurIsParcelleUtile() wireframe: false border: getCouleurIsParcelleUtile();
	} 		
	string toString{
		bool isCultIrr <- false;
		if(cultureParcelle != nil and !dead(cultureParcelle)){
			isCultIrr <- cultureParcelle.isIrrigable();
		}			
		return idParcelle +   ' / ITK = ' + getITKAnnee().idITK + 
						//' / SdCRef = ' + systemeDeCultureParcelle.sdcRefAssocie.idSdc  + 
						' / Culture = ' + cultureParcelle.espece.idEspeceCultivee + 
						' / IsCultIrr = ' + isCultIrr + 
						' / isParcelleIrrigable = ' + isParcelleIrrigable();
						//' / isIrrigueeAnneeCourante = ' + isIrrigueeAnneeCourante();
	}
}

