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
 *  Agriculteurs
 *  Author: Maroussia Vavasseur
 *  Description: L'agriculteur est le seul acteur du modele agricole. Il va pouvoir avoir un comportement rationel (cf. agriculteurComplexe)
 * 				 ou bien un comportement basee uniquement sur des donnees d'entrees (cf. agruculteurSimple).
 */

model agriculteur

import "../../modeleHydrographique/zoneHydrographique.gaml"
import "../situationAction.gaml"

global{	
	string imageAgriculteur <- '../../images/agriculteur6.png' ;
	list<agriculteur> listeAgriculteurs <- [];
	string fichierBiaisPerceptionAgri <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/perceptionAgriculteurs.csv';
	

	/*
	 * Publique
	 */
	action constructionAgriculteur{
		switch nomChoixAssolement {
        	match 'Donnees' {
                do constructionAgriculteursDonneesEntrees();                       
            }
        	match 'FonctionsDeCroyances' {
                do constructionAgriculteursFonctionsDeCroyances();    
            }            
            default {
                do constructionAgriculteursFonctionsDeCroyances();    
            }
        }
	}

	
	/*
	 * *****************************************************************************************
	 * Private
	 * Creation de l'agriculteur associe a l'exploitation
	 */
	action creationAgriculteurs(species<agriculteur> typeAgri <- agriculteur){

		loop exploitationCourante over: (exploitation as list){
			create typeAgri returns: nvAgri{
				sonExploitation <- exploitationCourante;	
				name <- exploitationCourante.name;					
				do initialisationAgriculteur();				
				listeAgriculteurs << self;
			}
		}
		do initialisationBaisPerception();	
	}
	
	
	     	action initialisationBaisPerception{
	     		if (file_exists(fichierBiaisPerceptionAgri)){ 
					matrix matrixBiaisPerception <- matrix(csv_file(fichierBiaisPerceptionAgri,";",true));
					//matrix matrixBiaisPerception <- matrix(file(fichierBiaisPerceptionAgri));
					int nbLignes <- length(matrixBiaisPerception column_at 0);
					loop i from: 0 to: (nbLignes -1){ //boucle sur les agriculteurs
						list<string> ligne <- (matrixBiaisPerception row_at i) as list<string>;
						ask (listeAgriculteurs where (each.idAgriculteur = ligne[0])){
							nbJoursDeDecalageActivite <- int(ligne[1]);
							biaisPerceptionVegetation <- float(ligne[2]);
							biaisPerceptionEau <- float(ligne[3]);
						}
					}
				}
	     	}
	
	
	/*
	 * Publique
	 */
	int getNbParcellesIrriguees_ZM{
		let nbParcellesTemp type: int <- 0;
		let listeParcelle type: list value: [];
		ask(listeAgriculteurs){
			set nbParcellesTemp value: nbParcellesTemp + nbParcellesIrriguees;
			ask listeGroupesIrrigation{
				listeParcelle <- listeParcelle + (parcellesIrrigable.keys);				
			}
		}		
		set listeParcelle value: remove_duplicates(listeParcelle);	
		
//		write '[AGRI/calculNbParcellesIrriguees] nb = ' + length(listeParcelle);
//		write '[AGRI/calculNbParcellesIrriguees] nbParcellesTemp = ' + nbParcellesTemp;
		
		return length(listeParcelle);
	}
	float getSurfaceIrriguee_ZM{
		float surfaceIrrigueeZoneMaelia <- 0.0;
		ask(listeAgriculteurs where (each.nbParcellesIrriguees > 0)){
			surfaceIrrigueeZoneMaelia <- surfaceIrrigueeZoneMaelia + surfaceIrriguee;
		}
		return surfaceIrrigueeZoneMaelia;
	}
	
	
}

species agriculteur {
	string idAgriculteur <- "";
	exploitation sonExploitation <- nil;    	
	list<planAssolement> listePlans  <- []; // juste un plan dans le cas du choix dassoelemnt par donnees dentree sans fonction de croyance)
	list<parcelle> listeParcelles <- [];	
	commune communeSiege <- nil; // Utile pour la definition du VP
	parcelle derniereParcelleTraitee <- nil; // pour positionner lagri
	float capital <- 0.0;
	float eau_disponible <- quantiteEauMaxDispoAgri;//[m3]
	float eau_quotaExploitation <- eau_disponible;    
	float heuresRestantesActivite <- 0.0; //heures à reporter sur le jour suivant
	float heuresEffectueesActivite <- 0.0;		
	//Les huit variables suivantes ont pour but de permettre de distinguer en sorties
	// les temps de travaux par tâche
	float heuresLabour <- 0.0;
	float heuresRepriseLabour <- 0.0;
	float heuresSemis <- 0.0;
	float heuresSemisForce <- 0.0;
	float heuresIrrigation <- 0.0;
	float heuresBinage <- 0.0;
	float heuresRecolte <- 0.0;
	float heuresRecolteForcee <- 0.0;
	float heuresPhyto <- 0.0;
	float heuresFerti <- 0.0;
	float heuresFauche <- 0.0;	
	float nb_heures_travails_min <- 0.0;
	float nb_heures_travails_max <- 0.0;
	int nbParcellesIrriguees <- 0;
	float surfaceIrriguee <- 0.0;	// chaque annee la surface irriguee change
	string profile <- "";
	list<groupeIrrigation> listeGroupesIrrigation <- [];			
	map<especeCultivee,float> mapRendementMoyenParCulture <- map<especeCultivee,float>([]); // cultureAnneeAvantRecolte::{rendementMoyen}   utilisee dans parcelle hors zone pour leur calcul rendement, mise a jour dans la stratiegieRecolte
	bool isWorkingHourTemporarlyChanged <- false; //boolean used to know if we need to reset normal and maximum working hours
	// TODO : a supprimer (ne pas faire par annee)
	map<int,int> mapVerbalisationsLieesRestriction <- map<int,int>([]); // annee::nbVerbalisationEn1an
	map<int,int> mapVerbalisationsLieesRespectVP <- map<int,int>([]); // annee::niveauDeVerbalisation (selon la quantite utilisee en plus du VP)
	bool premierChoixAssolementAnnee <- true;
	int nbJoursDeDecalageActivite <- 0;
	float biaisPerceptionEau <- 1.0; //biais de perception de la teneur en eau du sol et des precipitations
	float biaisPerceptionVegetation <- 1.0;
	
	list<parcelle> listeParcellesEnRecolteForcee <- []; // JV 010420 liste des parcelles en récolte forcée (remplie dans strategieRecolte.isActivitePossible et lue dans agriculteur.choixActivite)
	list<parcelle> listeParcellesEnSemisForce <- []; // JV 010420 liste des parcelles en semis forcé (remplie dans strategieSemis.isActivitePossible et lue dans agriculteur.choixActivite)
	list<bloc> listBloc<-[];
	list<memoire> listMemoire <-[];
	
	// Mémoire pour application de la méthode corpen (adaptation de la fertilisation) Renaud 250625
	map<int, map<string, map<string, list<float>>>>  rendements_sol_culture; // Annee::sol::culture::[rendement1, rendement2, ...]
	map<int, map<string, map<string, list<float>>>>  Nmin_sol_culture; // Annee::sol::culture::[NminCumul1, NminCumul2, ...]
	
	// Affichage
	int taillePointAgriculteur <- 1000;
  	rgb couleurAgriculteur <- rgb(rnd(1,240), rnd(1,240), rnd(1,240));
  
	// output ITKParParcelleTemps
	string outputITKParParcelleTemps <- "";

	// Optimisation du module agri
	list<parcelle> parcelles_a_optimiser;
	list<parcelle> parcelles_non_optimisees;
	list<parcelle> parcelles_contenant_gel;
	/*
	 *  *****************************************************************************************
	 */	
	action comportementAnnuel{
		do miseAzeroAnnuelle();			
		//do miseAJourVariables(); // JV 150420  variables irrigation désormais incrémentées dans strategieSemis.miseEnOeuvreActivite et décrémentées dans strategieRecolte.miseEnOeuvreActivite		
		if(nomChoixModeleIrrigation = GROUPE_IRRIGATION and isIrrigationSimulee){			
			do creationGroupesIrrigation();
		}
	
	}			
	/*
	 *  *****************************************************************************************
	 */			
		action comportementJournalier{
			do choixActivite();	
			
			// JV 020321 instruction maïs ensilage le 01/08 mantis #0002773
			if dateCour.mois=8 and dateCour.jour=1 and dateCour.annee > anneeDebutSimulation {
				//do affectationMaisEnsilage(); JV 180821 supprime pour fusion
			}
			
			// MAJ stock engrais par exploitation Renaud 050225
			if gestionStocksEngrais = 'exploitation' {
				ask sonExploitation {
					do majStockEngraisExploitation;
				}
			}
			
		}
 
 		/*
	 *  *****************************************************************************************
	 */	    	    	
	action initialisationAgriculteur{
		idAgriculteur <- sonExploitation.id;
		location <- one_of(sonExploitation.listeIlots).location;	
		listeParcelles <- (sonExploitation.listeIlots) accumulate (each.listeParcelles) + (sonExploitation.listeIlotsHorsZone) accumulate (each.listeParcelles);			
		ask sonExploitation.listeIlots + sonExploitation.listeIlotsHorsZone{
			agriculteurAssocie <- myself;
		}
		nb_heures_travails_min <- travail_jour * sonExploitation.umo;
		nb_heures_travails_max <- travail_max_jour * sonExploitation.umo;    		
		
		// TODO : FAIRE EN PRETRAITEMENT
		do affectationCommuneSiege();
 	}
 	
  	
	/*
	 *  *****************************************************************************************
	 *  Reflex effectue juste avant l'evolution des cours du marche agricole
	 */			
	 	action choixAssolement{}
		action affectationMaisEnsilage{} // JV 020321 mantis #0002773
		action getAssolement1parcelle(parcelle parc){}
		
 
 		/*
	 * TODO : a faire en pretraitement !!!
	 */
	action affectationCommuneSiege{
		map<commune,float> mapSurfIlotsParCommune <- map<commune,float>([]);			
		ask sonExploitation.listeIlots{
			// Commune associee
				if(!empty(commune)){
					commune communeAssociee <- first(commune where (each.shape intersects shape.location));
					if(communeAssociee = nil){
						// Ben
						// communeAssociee <- commune closest_to self;
						communeAssociee <- commune with_min_of(each distance_to self);
					}	
					if(communeAssociee != nil){
						float surf <- mapSurfIlotsParCommune at communeAssociee;
						put (surf + shape.area) at: communeAssociee in: mapSurfIlotsParCommune;
					}
				}				
 			}
    		float surfMax <- 0.0;
    		loop communeTemp over: mapSurfIlotsParCommune.keys{
    			if((mapSurfIlotsParCommune at communeTemp) > surfMax){
    				communeSiege <- communeTemp;
    			}
    		}
 		}
  
  		/*
	 *  *****************************************************************************************
	 * Chaque jour (appelee par le main)
	 */	    	    	
	action miseAJourEauDisponible{
		ask listeParcelles {
			if(irrigationReelle > 0.0){ //Attention irrigationReelle en mm 
				float eauConsomme <- irrigationReelle/nombreMillimetreDansUnMetre * surface;
				myself.eau_disponible <- myself.eau_disponible - eauConsomme;
				if(executerModeleNormatif){
					ask ilot_app.ppaCourant{
    					do setQuota(dateCour.nbJoursEcoulesDansAnnee,
    						getQuota(dateCour.nbJoursEcoulesDansAnnee) -eauConsomme *(1+EFFICIENCE_PPA_PARCELLE));
    				}
				}
			}
		}
	}
 
	action miseAzeroAnnuelle{
		mapRendementMoyenParCulture <- map<especeCultivee,float>([]);
		//nbParcellesIrriguees <- 0;   JV 150420: plus de remise à 0, désormais incrémenté dans strategieSemis et décrémenté dans strategieRecolte, cf mantis 0002510
		//surfaceIrriguee <- 0.0;
					
		ask listeGroupesIrrigation{
			do die();
		}
		listeGroupesIrrigation <- [];
		ask(listeParcelles){
			ask listeGroupeIrrigationCulture{
				do die();
			}
			listeGroupeIrrigationCulture <- [];
		}
		
		//sauvegarde des prix et charges annuels JV 100821: si marche defini		
		if leMarcheAgricole!=nil {
			loop it over: (itk as list){
				ask (listMemoire) where (each.itkAssocie = it){
					do setPrixObserve(leMarcheAgricole.prix_recoltes at it.especeCultiveeITK);
					do setPrimeObserve((leMarcheAgricole.prime_par_departement at myself.sonExploitation.id_departement) at it.especeCultiveeITK);
					listeVariabiliteProfitDejaCalcule <- false;
				}
			}		
		}
		premierChoixAssolementAnnee <- true;
	}
	
	/*
	 *  *****************************************************************************************
	 * Chaque annee
	 */	    	    	
	action miseAJourVariables{
		ask listeParcelles {			
			if(getITKAnnee() != nil){
				if(isIrrigueeAnneeCourante()){	
					if(isParcelleIrrigable()){						
						myself.surfaceIrriguee <- myself.surfaceIrriguee + surface;
						myself.nbParcellesIrriguees <- myself.nbParcellesIrriguees + 1;		
					}else{
						write '[AGRI/miseAJourVariables] PB parcelle ne peut pas etre irriguee car non irrigable ' + self.toString();
					}									
				}
			}	
		}		
	}
	
	/*
	 *  *****************************************************************************************
	 */			
	action choixActivite {
		float nb_heures_travails <- 0.0;

		// Choix strategie alternative de fertilisation 15j avant le premier apport de l'alternative préférée de l'agriculteur
		if (plusieursFertilisationsParITK) {
			//list<parcelle> p <- []; JV 150424 passage 1.9.3			
			loop p over: listeParcelles where (each.getITKAnnee() != nil){
				ask (parcelleAqYieldNC(p)){
//					write '-ITKFERTi- culture ---> ' + p.getITKAnnee().especeCultiveeITK.idEspeceCultivee + ' isCouvert = ' + p.getITKAnnee().especeCultiveeITK.isCouvert;
//					write "-ITKFERTi contientStrategiesFerti ---> " + getITKAnnee().contientStrategiesFerti;
					if (alternative_selectionnee = nil and getITKAnnee().contientStrategiesFerti = true) {
						strategieFertiAlternative alternativePreferee <- first(getITKAnnee().strategieFertiITK.mesStrategiesFertiAlternative where (each.ordre_alternative = 1));
						if (alternativePreferee != nil) {
							//write "aternative préférée ---> " + alternativePreferee ;
							int dateChoix <- alternativePreferee.jourChoixStrategie;
							int dateActuelle <- int(dateCour.calculNbJourEcouleDansAnnee(dateCour.jour, dateCour.mois));//
//							write "-ITKFERTi- date alternativePreferee --> " + dateChoix + " | date courante  = " + dateActuelle;

							// Si on est au premier cycle de la simu OU si la date actuelle est la date de choix OU si la date actuelle est un peu supérieure à la date de choix (30 jours de battement) --> on sélectionne
							if ((cycle = 1 and dateActuelle > dateChoix and dateCour.annee = anneeDebutITKcourant) or (dateActuelle = dateChoix) or (dateActuelle > dateChoix and dateActuelle - dateChoix < 80)) {//parcelleAqYieldNC(parc).anneeDebutITKcourant <- dateCour.annee; // or (dateActuelle < dateChoix and dateCour.annee > anneeDebutITKcourant)
								//write "-ITKFERTi- Sélection d'une alternative de fertilisation pour la parcelle --> " + self;
								do selection_alternative_ferti;
							}
						}
					}
				}
			}
		}

		// Gestion du report de travail d'un jour sur l'autre
		// Ce cas se produit dans le cas d'une opération sur une parcelle prenant plus que le temps 
		// par jour autorisé (exemple : parcelle de 4 ha et irrigation coûtant 2H/ha et seulement 6H max par jour disponible							
		if(heuresRestantesActivite > 0){ //s'il y a des heures a reporter
			isWorkingHourTemporarlyChanged <- true;
			if(heuresRestantesActivite >= nb_heures_travails_max){ //s'il restait plus d'un jour de travail
				heuresRestantesActivite <- heuresRestantesActivite - nb_heures_travails_max;
				heuresEffectueesActivite <- nb_heures_travails_max;
				nb_heures_travails_min <- 0.0;
				nb_heures_travails_max <- 0.0;
			} 
			else{ //s'il reste juste quelques heures, on les déduit du potentiel de travail 
				// JV 301123 on les comptait 2 fois: on les retirait du potentiel de travail et on démarrait avec ces heures déjà comptées ! J'ai laissé seulement le fait qu'on les compte comme déjà fait avant de commencer
				//nb_heures_travails_max <- nb_heures_travails_max - heuresRestantesActivite;
				//nb_heures_travails_min <- nb_heures_travails_min - heuresRestantesActivite;
				nb_heures_travails <- heuresRestantesActivite;
				heuresRestantesActivite <- 0.0;
			}
		}
		
		if(nb_heures_travails_max > 0){
			// Etape 1 : l'agriculteur verifie d'abord s'il y a des parcelles sur lesquelles semer, si oui, il les seme 
			if (accelerateur_agricole["SEMIS"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresSemis <- activite(nb_heures_travails, SEMIS) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + 	heuresSemis;
			}

			// Etape 1bis : gestion des éventuels problèmes de semis non réalisé: soit recherche d'un ITK alternatif, soit forçage du semis
			if(activerITKalternatif){ // JV 300320 mantis 0002510
				do appliquerITKAlternatif();
			}
			else{ // forçage du semis
				heuresSemisForce <- activiteSemisForce(nb_heures_travails) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + heuresSemisForce;			
			}
									
			// Etape 2 : l'agriculteur verifie s'il y a des parcelles sur lesquelles recolter, si oui, il les recolte 
			if (accelerateur_agricole["RECOLTE"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresRecolte <- activite(nb_heures_travails, RECOLTE) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + heuresRecolte;
			}
			
			// Etape 2bis: effectue une récolte forcée au besoin
			heuresRecolteForcee <- activiteRecolteForcee(nb_heures_travails) - nb_heures_travails;
			nb_heures_travails <- nb_heures_travails + heuresRecolteForcee;			
			
			// Etape 3 : l'agriculteur verifie d'abord s'il y a des parcelles sur lesquelles il doit labourer, si oui, il effectue le labour
			if (accelerateur_agricole["TRAVAIL_SOL"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresLabour <- activite(nb_heures_travails, TRAVAIL_SOL) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + 	heuresLabour;
			}
			
			// Etape 4 : l'agriculteur verifie d'abord s'il y a des parcelles sur lesquelles il doit labourer, si oui, il effectue le labour
			if (accelerateur_agricole["REPRISE"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresRepriseLabour <- activite(nb_heures_travails, REPRISE_TRAVAIL_SOL) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + 	heuresRepriseLabour;
			}
			
			// Etape 5 : enfin, l'agriculteur verifie s'il y a des parcelles sur lesquelles recolter, si oui, il les recolte 
			if (accelerateur_agricole["FERTI"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresFerti <- activite(nb_heures_travails, FERTI) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + heuresFerti;
			}
							
			// Etape 6 : Si l'agriculteur a des parcelles irrigees cette annee
			if (accelerateur_agricole["IRRIGATION"] contains dateCour.nbJoursEcoulesDansAnnee) {
				if(nbParcellesIrriguees > 0 and isIrrigationSimulee){					
					if(nomChoixModeleIrrigation = GROUPE_IRRIGATION){							
						heuresIrrigation <- activiteIrriguerComplexe(nb_h:nb_heures_travails) -nb_heures_travails;
					}else if(nomChoixModeleIrrigation = Simple){
						heuresIrrigation <- activite(nb_heures_travails, IRRIGATION) - nb_heures_travails;
					}
					nb_heures_travails <- nb_heures_travails + heuresIrrigation;									
				}
				nb_heures_travails <- nb_heures_travails + heuresIrrigation;									
			}
			
			// Etape 7 : l'agriculteur verifie s'il y a des parcelles sur lesquelles il doit effectuer un traitement phyto
			if (accelerateur_agricole["PHYTO"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresPhyto <- activite(nb_heures_travails, PHYTO) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + heuresPhyto;
			}

			// Etape 8 : l'agriculteur verifie d'abord s'il y a des parcelles sur lesquelles il doit labourer, si oui, il effectue le labour
			if (accelerateur_agricole["FAUCHE"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresFauche <- activite(nb_heures_travails, FAUCHE) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + 	heuresFauche;
			}
			
			// Etape 9 : l'agriculteur verifie s'il y a des parcelles "a biner", si oui, il effectue le binage du sol
			if (accelerateur_agricole["BINAGE"] contains dateCour.nbJoursEcoulesDansAnnee) {
				heuresBinage <- activite(nb_heures_travails, BINAGE_SOL) - nb_heures_travails;
				nb_heures_travails <- nb_heures_travails + heuresBinage;
			}

				
			heuresEffectueesActivite <- min([nb_heures_travails,nb_heures_travails_max]);					
			if(derniereParcelleTraitee != nil and !dead(derniereParcelleTraitee)){
				location <- derniereParcelleTraitee.location;
				sonExploitation.listeIlots <- sonExploitation.listeIlots sort_by (each.location distance_to derniereParcelleTraitee.location);
			}
		}else{
			heuresLabour<- 0.0;
			heuresRepriseLabour <- 0.0;
			heuresSemis<- 0.0;
			heuresSemisForce <- 0.0;
			heuresIrrigation<- 0.0;
			heuresBinage<- 0.0;
			heuresRecolte<- 0.0;
			heuresRecolteForcee <- 0.0;
			heuresPhyto <- 0.0;
			heuresFerti <- 0.0;
			heuresFauche <- 0.0;
		}
		
		if (isWorkingHourTemporarlyChanged){
			nb_heures_travails_min <- travail_jour * sonExploitation.umo;
			nb_heures_travails_max <- travail_max_jour * sonExploitation.umo;  
			isWorkingHourTemporarlyChanged <- false;
		}
		
		// JV 301123 gestion des cas où on a raté le dernier jour de la fenêtre du semis à cause d'un report d'heures
		if avecContrainteDeMainOeuvre and !activerITKalternatif {
			// si il existe un ITK pour lequel c'est le dernier jour de semis
			if mapItkDernierJourSemis.keys contains dateCour.nbJoursEcoulesDansAnnee {
				// les ITK en question
				list<itk> itkDernierJourSemis <- mapItkDernierJourSemis[dateCour.nbJoursEcoulesDansAnnee];
				// les parcelles de l'agri qui suivent un de ces ITK (donc dont c'est le dernier jour de semis)
				list<parcelle> parcDernierJourSemis <- listeParcelles where (each.getITKAnnee() in itkDernierJourSemis);
				// pour chacune de ces parcelles
				ask parcDernierJourSemis {
					// si toujours pas semé on force le semis
					if cultureParcelle = nil {
						myself.listeParcellesEnSemisForce << self;
						myself.heuresSemisForce <- myself.activiteSemisForce(nb_heures_travails) - nb_heures_travails;
						nb_heures_travails <- nb_heures_travails + myself.heuresSemisForce;	
						// maj temps travaille ce jour
						myself.heuresEffectueesActivite <- min([nb_heures_travails,myself.nb_heures_travails_max]);	
						// si on force le semis ici c'est forcément des heures à reporter		
						myself.heuresRestantesActivite <- myself.heuresRestantesActivite + myself.heuresSemisForce;
					}
				}				
			}
		}
	}
	

	/*
	 *  *****************************************************************************************
	 */		
	float activite(float nb_h, string typeStrategie) {
		
		if(nb_h < nb_heures_travails_min){	// nb_h: nb heures déjà consommées dans la journée, nb_heures_travails_min: nb heures travail dans un jour normal
			//float debut <-  first(timeStamp as list).getTimeStamp();
			list<parcelle> parcellesTriees <- [];
			if (typeStrategie != "RECOLTE" or accelerateur_agricole["RECOLTE"] contains dateCour.nbJoursEcoulesDansAnnee) {
//				if (sequences_a_optimiser="" or (sequences_a_optimiser!="" and ([155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315] contains dateCour.nbJoursEcoulesDansAnnee))) { // A décommenter si parcelles à optimiser est activé : 
				// indiquer les jours où ces parcelles sont concernées par des activités dans la liste
					loop pc over: listeParcelles where (each.getITKAnnee() != nil){
						if(pc.getStrategie(typeStrategie)!=nil){
							ask (pc.getStrategie(typeStrategie)){
								if(isActivitePossible(pc, 0, myself.nbJoursDeDecalageActivite)){
									parcellesTriees << pc;
								}
							}			
						}
					}
//				} else { // A décommenter si parcelles à optimiser est activé
//					loop pc over: parcelles_non_optimisees where (each.getITKAnnee() != nil){
//						if(pc.getStrategie(typeStrategie)!=nil){
//							ask (pc.getStrategie(typeStrategie)){
//								if(isActivitePossible(pc, 0, myself.nbJoursDeDecalageActivite)){
//									parcellesTriees << pc;
//								}
//							}
//						}
//					}
//				}
			} else {
				loop pc over: parcelles_contenant_gel where (each.getITKAnnee() != nil){ 
					if(pc.getStrategie(typeStrategie)!=nil){
						ask (pc.getStrategie(typeStrategie)){
							if(isActivitePossible(pc, 0, myself.nbJoursDeDecalageActivite)){
								parcellesTriees << pc;
							}
						}			
					}
				}	
			}
									
			bool continuer_activite <- !(empty(parcellesTriees));
			if continuer_activite {

				/*JV 121221 (cf. Mantis #0002878)
				 * - si assolement par données: tri sur espérance chiffre affaires = surface * prix * rendement potentiel (pas d'agent mémoire)
				 * - sinon: tri sur espérance de profit: calcul d'origine basé sur les agents mémoire
				 */				
				agriculteur agri <- self;		
				if nomChoixAssolement="Donnees" {
					parcellesTriees <- (parcellesTriees sort_by (-1 * each.getEsperanceChiffreAffaires(agri)));
				} else{
					parcellesTriees <- (parcellesTriees sort_by (-1 * each.getEsperanceProfit(agri)));				
				}
			}
			
			loop parc over: parcellesTriees{	
				if continuer_activite { // TODO : pb avec valeur temps = 0     and parc.getStrategie(typeStrategie).tempsDexecution > 0.0
					float temps_traitement <- 0.0;
					float temps_travail_ha <- parc.getStrategie(typeStrategie).tempsDexecution;
					if temps_travail_ha > 0.0 {
						temps_traitement <- parc.surface / temps_travail_ha;
					} else {
						temps_traitement <- 0.0;
					}

					if(nb_h + temps_traitement < nb_heures_travails_max or nb_h = 0.0){ // nb_heures_travails_max: nb heures travail dans un jour avec pic d'activité
						nb_h <- nb_h + temps_traitement;
						heuresRestantesActivite <- max([0.0,nb_h - nb_heures_travails_max]); // heuresRestantesActivite: heures à reporter sur le jour suivant: 0 sauf si on a dépassé nb_heures_travails_max
						//memorisation des temps de travaux
						parc.tempsDeTravail <- parc.tempsDeTravail + temps_traitement;
						
						// Application activite
						ask (parc.getStrategie(typeStrategie)){							
							do miseEnOeuvreActivite(parc, myself);
						} 
						derniereParcelleTraitee <- parc;
						
						// pour output ITKParParcelleTemps
						if dateCour.annee > anneeDebutSimulation {
							outputITKParParcelleTemps <- outputITKParParcelleTemps + dateCour.annee + ";" + dateCour.nbJoursEcoulesDansAnnee + ";" + sonExploitation.id + ";" + parc.idParcelle + ";" + parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee + ";" + parc.surface + ";" + typeStrategie + ";" + temps_traitement + "\n";							
						}
						// JV 160322 stocke uniquement si utile
						if parc.memoireOTsurParcelle.keys contains typeStrategie {				 
							put temps_traitement at: dateCour.nbJoursEcoulesDansAnnee  in: (parc.memoireOTsurParcelleTemps at typeStrategie);
						}						
					}
					if(nb_h > nb_heures_travails_min){ // si on a dépassé nb heures d'un jour normal on arrête
						continuer_activite <- false;
					}
					
				}	
			}
		}
		return nb_h;
	}

	/* JV 24032020: special case for forced sowing see Mantis #0002510
	* most of the code comes from activite() but since the sowing is forced, all the tests about workload are discarded
	* EN CHANTIER -> VOIR AVEC OLIVIER SI ON DOIT AUSSI FORCER UNE REPRISE DE TRAVAIL DU SOL AVANT DE FORCER LE SEMIS
	* 	 -> pour le moment on lève cette contrainte (voir strategieSemis.isActivitePossible) et on ne réalise pas la reprise lors du forçage du semis.
	*  */	
	float activiteSemisForce(float nb_h) { 

		if(!empty(listeParcellesEnSemisForce)){ // au moins une parcelle en semis forcé détectée par strategieSemis.isActivitePossible
			/*  attention il est possible que certaines parcelles qui doivent être semées n'aient pas été détectées par strategieSemis.isActivitePossible car plus de temps de travail et on n'est pas entré dans strategieSemis.isActivitePossible
					-> on va récupérer les ITK de celles qui ont été détectées et faire un semis forcé sur toutes les parcelles de ces ITK
			*/
			list<itk> ITKASemer <- [];
			list<parcelle> parcellesASemer <- [];
			
			// on parcourt chaque parcelle détectée et on ajoute son ITK à la liste des ITK à semer s'il ne s'y trouve pas déjà
			ask(listeParcellesEnSemisForce){
				itk unITK <- self.getITKAnnee();
				if(!(ITKASemer contains unITK)){
					ITKASemer << unITK;
				}
			}
			
			// pour chaque ITK à semer on ajoute les parcelles de l'agriculteur qui suivent cet ITK et qui n'ont pas encore été semées à la liste des parcelles à semer
			ask(ITKASemer){
				itk unITK <- self;
				loop parc over:myself.listeParcelles where (each.getITKAnnee()=unITK and each.cultureParcelle=nil){
				//loop parc over:myself.listeParcellesEnSemisForce where (each.getITKAnnee()=unITK){
					parc.semis_prevu_non_realise <- true;  // utile dans miseEnOeuvreActiite
					parcellesASemer << parc;
				}								
			}
			
			// forçage effectif du semis sur les parcelles identifiées
			loop parc over: parcellesASemer{	
				float temps_traitement <- parc.surface / parc.getStrategie(SEMIS).tempsDexecution;
				nb_h <- nb_h + temps_traitement; // semis forcé: on ajoute le temps passé mais pas de test sur la durée max
				//memorisation des temps de travaux
				parc.tempsDeTravail <- parc.tempsDeTravail + temps_traitement;
				
				// JV 140121 stocke uniquement si utile
				if parc.memoireOTsurParcelle.keys contains SEMIS_FORCE {
					put parc.getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (parc.memoireOTsurParcelle at SEMIS_FORCE);
					put temps_traitement at: dateCour.nbJoursEcoulesDansAnnee  in: (parc.memoireOTsurParcelleTemps at SEMIS);
				}				
				// Application activite
				ask (parc.getStrategie(SEMIS)){
					if verboseMode {write "SEMIS FORCE sur parcelle " + parc.idParcelle + " ITK " + parc.getITKAnnee().idITK;}
					do miseEnOeuvreActivite(parc, myself);
				} 
				derniereParcelleTraitee <- parc;
			}
			listeParcellesEnSemisForce <- [];												
		}		
		return nb_h;
	}

	/* JV 24032020: special case for forced harvest see Mantis #0002510
	most of the code comes from activite() but since the harvest is forced, all the tests about workload are discarded */
	float activiteRecolteForcee(float nb_h) {

		if(!empty(listeParcellesEnRecolteForcee)){ // au moins une parcelle en récolte forcée détectée par strategieRecolte.isActivitePossible
			/*  attention il est possible que certaines parcelles qui doivent être récoltées n'aient pas été détectées par strategieRecolte.isActivitePossible car plus de temps de travail et on n'est pas entré dans strategieRecolte.isActivitePossible
					-> on va récupérer les ITK de celles qui ont été détectées et faire une récolte forcée sur toutes les parcelles de ces ITK
			*/
			list<itk> ITKARecolter <- [];
			list<parcelle> parcellesARecolter <- [];
			
			// on parcourt chaque parcelle détectée et on ajoute son ITK à la liste des ITK à récolter s'il ne s'y trouve pas déjà
			ask(listeParcellesEnRecolteForcee){
				itk unITK <- self.getITKAnnee();
				if(!(ITKARecolter contains unITK)){
					ITKARecolter << unITK;
				}
			}
			
			// pour chaque ITK à récolter on ajoute les parcelles de l'agriculteur qui suivent cet ITK à la liste des parcelles à récolter
			ask(ITKARecolter){
				itk unITK <- self;
				loop parc over:myself.listeParcelles where (each.getITKAnnee()=unITK){
				//loop parc over:myself.listeParcellesEnRecolteForcee where (each.getITKAnnee()=unITK){
					if parc.cultureParcelle!=nil { // vérifie que la culture est bien en place sur la parcelle (peut arriver que ce ne soit pas le cas la toute 1e année de simulation) 
						if parc.isConditionAgeOk() { // JV 200725 vérifie que la culture est a l'âge requis pour être récoltée (colza) cf issue #26 
							parc.recolteForcee <- true;  // utile dans miseEnOeuvreActivite
							parcellesARecolter << parc;
						}
					}
				}								
			}
			
			// forçage effectif de la récolte sur les parcelles identifiées
			loop parc over: parcellesARecolter{	
				float temps_traitement <- parc.surface / parc.getStrategie(RECOLTE).tempsDexecution;
				nb_h <- nb_h + temps_traitement; // récolte forcée: on ajoute le temps passé mais pas de test sur la durée max
				//memorisation des temps de travaux
				parc.tempsDeTravail <- parc.tempsDeTravail + temps_traitement;
				// JV 140121 stocke uniquement si utile
				if parc.memoireOTsurParcelle.keys contains RECOLTE_FORCEE {
					put parc.getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (parc.memoireOTsurParcelle at RECOLTE_FORCEE);
					put temps_traitement at: dateCour.nbJoursEcoulesDansAnnee  in: (parc.memoireOTsurParcelleTemps at RECOLTE);
				}
				// Application activite
				ask (parc.getStrategie(RECOLTE)){
					if verboseMode {write "RECOLTE FORCEE sur parcelle " + parc.idParcelle + " ITK " + parc.getITKAnnee().idITK + " age " + parc.cultureParcelle.age_culture;}
					do miseEnOeuvreActivite(parc, myself);
					// attention à partir d'ici parc.getITKAnnee() renvoit l'ITK suivant
				} 
				derniereParcelleTraitee <- parc;
			}
			listeParcellesEnRecolteForcee <- [];												
		}		
		return nb_h;
	}

	/*
	 *  *****************************************************************************************
	 * Si des fois la courbe des prelevements nest pas periodique, cest qu'il a trop plus peut etre. 
	 */			
	float activiteIrriguerComplexe(float nb_h){
		if(nb_h < nb_heures_travails_min){	
			ask listeGroupesIrrigation{	
				nb_h <- float(irrigation(nb_h:nb_h));
			}
			heuresRestantesActivite <- max([0.0,nb_h - nb_heures_travails_max]); // Heures à reporter sur les jours suivants
			groupeIrrigation gI_temp <- first(listeGroupesIrrigation where (each.derniereParcelleIrriguee != nil));
			if(gI_temp != nil){
				derniereParcelleTraitee <- gI_temp.derniereParcelleIrriguee ;
			}				
		}	
		
//			write "----------------------- " + idAgriculteur + " -------------------";
//			write "DEBUT GROUPE IRR AGRI ----------------";
//			ask listeGroupesIrrigation{	
//				write toString();
//			}
//			write "DEBUT GROUPE IRR CULTURE ----------------";
//			ask listeParcelles{
//				ask listeGroupeIrrigationCulture{
//					write toString();
//				}
//			}
													
		return nb_h;
	}


	/*
	 *  *****************************************************************************************
	 * A partir dune certaine surface a irriguee, il y aura parallelisation et N parcelles pourront etre irrigues en meme temps chaque jour
	 * 
	 */
	 	    	    	
	action creationGroupesIrrigation{  
		
		/* JV debug
		write "début creationGroupesIrrigation";
		write "\tparcelles ";
		ask listeParcelles{
			write "\t\t" + idParcelle + "\t" + getItkPrevusCetteAnnee() collect (each.idITK + "\t" + each.isIrriguee());
		}
		*/
		
		list<parcelle> listeParcellesAIrriguer <- getListeParcellesAIrriguer();
		//write "\t\tnbParcellesIrriguees: " + length(listeParcellesAIrriguer);
		if length(listeParcellesAIrriguer) > 0{
			int indiceDernierGroupe <- 1;				
			map<itk,list<parcelle>> mapParcelleAIrriguerParEspece <- getMapParcellesParItkIrrigue(listeParcellesAIrriguer); // itk::{listeParcelles}    
			/*
			write "\tmapParcelleAIrriguerParEspece";
			ask mapParcelleAIrriguerParEspece.keys{
				write "\t\t" + idITK + mapParcelleAIrriguerParEspece[self] collect each.idParcelle;
			}
			*/			 		
				
			// 0 - GROUPE PAR ITK
			loop itkCourante over: mapParcelleAIrriguerParEspece.keys{		    
				//write "\titkCourant: " + itkCourante.idITK;		
	    		list<parcelle> listeParcellesNonTraites <- (mapParcelleAIrriguerParEspece at itkCourante);	
	    		map<zoneAdministrative,list<parcelle>> mapParcelleAIrriguerParZA <- getMapParcellesParZA(listeParcellesEntree:listeParcellesNonTraites); // ZA::{listeParcelles}    										
				
				// 0.1 - GROUPE PAR ITK ET ZA
				loop zaCourante over: mapParcelleAIrriguerParZA.keys{
					list<parcelle> listeParcelleMemeZA <- (mapParcelleAIrriguerParZA at zaCourante);
//					listeParcellesNonTraites <- listeParcellesNonTraites - listeParcelleMemeZA;	 // TODO : marche pas pourquoi ???
					// on enleve les parcelles qui ont une ZA	
					loop parc over: listeParcelleMemeZA{
						remove parc from: listeParcellesNonTraites;			
					}
					
					//Maintenant on trie par MATERIEL
					map<materielIrrigation,list<parcelle>> mapParcelleAIrriguerParMateriel <- getMapParcellesParMateriel(listeParcellesEntree:listeParcelleMemeZA); // Materiel::{listeParcelles}  
					loop mat over: mapParcelleAIrriguerParMateriel.keys{
						list<parcelle> listeParcelleMemeMateriel <- (mapParcelleAIrriguerParMateriel at mat);
						groupeIrrigation avantDernier <- nil;
						groupeIrrigation dernier <- nil;
						loop while: (!empty(listeParcelleMemeMateriel)) {
							create groupeIrrigation number: 1{
								listeParcelleMemeMateriel <- creationGroupe(listeParcelleMemeMateriel, zaCourante, myself, indiceDernierGroupe, mat, itkCourante);
								myself.listeGroupesIrrigation << self;
								avantDernier <- dernier;
								dernier <- self;
							}
							indiceDernierGroupe <- indiceDernierGroupe + 1;		listeParcelleMemeMateriel<-[];
						}
						// Si on a cree au moins deux groupes d irrigation et donc qu il y a au moins deux materiel alors 
						// on doit reequilibrer	les groupes
						if(avantDernier != nil){
							ask world{
								do reequilibreGroupeIrrigation(avantDernier, dernier);
							}
						}
					}
				}

				// 0.2 - GROUPE PAR ITK ET SANS ZA (Si on a pas de ZA)			
				
				map<materielIrrigation,list<parcelle>> mapParcelleAIrriguerParMateriel <- getMapParcellesParMateriel(listeParcellesNonTraites); // Materiel::{listeParcelles}  
				/*
				write "\t\tmapParcelleAIrriguerParMateriel";
				ask mapParcelleAIrriguerParMateriel.keys{
					write "\t\t\t" + idMateriel + " " + mapParcelleAIrriguerParMateriel[self] collect each.idParcelle;
				}
				*/
				loop mat over: mapParcelleAIrriguerParMateriel.keys{
					list<parcelle> listeParcelleMemeMateriel <- (mapParcelleAIrriguerParMateriel at mat);
					groupeIrrigation avantDernier <- nil;
					groupeIrrigation dernier <- nil;
					loop while: (!empty(listeParcelleMemeMateriel)) {
						create groupeIrrigation number: 1{
							listeParcelleMemeMateriel <- creationGroupe(listeParcelleMemeMateriel, zoneAdministrative(nil), myself, indiceDernierGroupe, mat, itkCourante);
							myself.listeGroupesIrrigation << self;
							avantDernier <- dernier;
							dernier <- self;
						}
						indiceDernierGroupe <- indiceDernierGroupe + 1;		
					}
					// Si on a cree au moins deux groupes d irrigation et donc qu il y a au moins deux materiel alors 
					// on doit reequilibrer	les groupes
					if(avantDernier != nil){
						ask world{
							do reequilibreGroupeIrrigation(avantDernier, dernier);
						}
					}		
				}
				    				
			} 
		}
	}

	/* // ancienne version (1 an = 1 couvert) avant 1.3.12
	action creationGroupesIrrigation{  
		write "\tdébut creationGroupesIrrigation";
		if(nbParcellesIrriguees > 0){
			write "\t\tnbParcellesIrriguees > 0";
			int indiceDernierGroupe <- 1;				
			map<itk,list<parcelle>> mapParcelleAIrriguerParEspece <- getMapParcellesParITK(listeParcellesEntree:getListeParcellesAIrriguer()); // itk::{listeParcelles}    			 		
				
			// 0 - GROUPE PAR ITK
			loop itkCourante over: mapParcelleAIrriguerParEspece.keys{		    		
	    		list<parcelle> listeParcellesNonTraites <- (mapParcelleAIrriguerParEspece at itkCourante);	
	    		map<zoneAdministrative,list<parcelle>> mapParcelleAIrriguerParZA <- getMapParcellesParZA(listeParcellesEntree:listeParcellesNonTraites); // ZA::{listeParcelles}    										
				
				// 0.1 - GROUPE PAR ITK ET ZA
				loop zaCourante over: mapParcelleAIrriguerParZA.keys{
					list<parcelle> listeParcelleMemeZA <- (mapParcelleAIrriguerParZA at zaCourante);
//					listeParcellesNonTraites <- listeParcellesNonTraites - listeParcelleMemeZA;	 // TODO : marche pas pourquoi ???
					// on enleve les parcelles qui ont une ZA	
					loop parc over: listeParcelleMemeZA{
						remove parc from: listeParcellesNonTraites;			
					}
					
					//Maintenant on trie par MATERIEL
					map<materielIrrigation,list<parcelle>> mapParcelleAIrriguerParMateriel <- getMapParcellesParMateriel(listeParcellesEntree:listeParcelleMemeZA); // Materiel::{listeParcelles}  
					loop mat over: mapParcelleAIrriguerParMateriel.keys{
						list<parcelle> listeParcelleMemeMateriel <- (mapParcelleAIrriguerParMateriel at mat);
						groupeIrrigation avantDernier <- nil;
						groupeIrrigation dernier <- nil;
						loop while: (!empty(listeParcelleMemeMateriel)) {
							create groupeIrrigation number: 1{
								listeParcelleMemeMateriel <- creationGroupe(listeParcelleMemeMateriel, zaCourante, myself, indiceDernierGroupe, mat);
								myself.listeGroupesIrrigation << self;
								avantDernier <- dernier;
								dernier <- self;
							}
							indiceDernierGroupe <- indiceDernierGroupe + 1;		
						}
						// Si on a cree au moins deux groupes d irrigation et donc qu il y a au moins deux materiel alors 
						// on doit reequilibrer	les groupes
						if(avantDernier != nil){
							ask world{
								do reequilibreGroupeIrrigation(avantDernier, dernier);
							}
						}
					}
				}

				// 0.2 - GROUPE PAR ITK ET SANS ZA (Si on a pas de ZA)			
				
				map<materielIrrigation,list<parcelle>> mapParcelleAIrriguerParMateriel <- getMapParcellesParMateriel(listeParcellesNonTraites); // Materiel::{listeParcelles}  
				loop mat over: mapParcelleAIrriguerParMateriel.keys{
					list<parcelle> listeParcelleMemeMateriel <- (mapParcelleAIrriguerParMateriel at mat);
					groupeIrrigation avantDernier <- nil;
					groupeIrrigation dernier <- nil;
					loop while: (!empty(listeParcelleMemeMateriel)) {
						create groupeIrrigation number: 1{
							listeParcelleMemeMateriel <- creationGroupe(listeParcelleMemeMateriel, zoneAdministrative(nil), myself, indiceDernierGroupe, mat);
							myself.listeGroupesIrrigation << self;
							avantDernier <- dernier;
							dernier <- self;
						}
						indiceDernierGroupe <- indiceDernierGroupe + 1;		
					}
					// Si on a cree au moins deux groupes d irrigation et donc qu il y a au moins deux materiel alors 
					// on doit reequilibrer	les groupes
					if(avantDernier != nil){
						ask world{
							do reequilibreGroupeIrrigation(avantDernier, dernier);
						}
					}		
				}
				    				
			} 
		}
	}*/
	 
	
	/*
	 * *****************************************************************************************
	 */
	list<parcelle> getListeParcellesAIrriguer{
		list<parcelle> tmp <- listeParcelles where (each.auMoinsUnItkIrrigueCetteAnnee());
		/*
		ask tmp{
			write idParcelle + " eqIRR:" +  ilot_app.idsEquipementsAssocies;
		}
		*/
		return tmp;
		//return listeParcelles where (each.auMoinsUnItkIrrigueCetteAnnee() and !empty(each.ilot_app.idsEquipementsAssocies));
		//return listeParcelles where (each.isIrrigueeAnneeCourante() and !empty(each.ilot_app.idsEquipementsAssocies));
	}		  

	// Renvoie la liste des parcelles par itk irrigué
	// si une parcelle a plusieurs itk irrigués cette année, on choisit l'itk avec la fenêtre d'irrigation la plus longue
	map<itk,list<parcelle>> getMapParcellesParItkIrrigue(list<parcelle> listeParcellesEntree){
		
		map<itk,list<parcelle>> mapParcelleAIrriguerParItkIrrigue <- map([]);
		ask listeParcellesEntree {	
			itk itkAvecPlusLongueFenetreIrrigation <- world.getItkAvecLaPlusLongueFenetreIrrigation(getItkIrriguesPrevusCetteAnnee());  			
			//if(isIrrigueeAnneeCourante()){
				list<parcelle> listeTemp <- mapParcelleAIrriguerParItkIrrigue[itkAvecPlusLongueFenetreIrrigation];
				listeTemp << self;
				listeTemp <- remove_duplicates(listeTemp);
				mapParcelleAIrriguerParItkIrrigue[itkAvecPlusLongueFenetreIrrigation] <- listeTemp;
			//}																					
		}
		
		//Maintenant on assemble les itks par "libellé de groupe d'irrigation". Permet par exemple d'assembler les mais
		// au sein du meme bloc d'irrigation
		list<itk> itkAGrouper <- [];
		loop it over:mapParcelleAIrriguerParItkIrrigue.keys{ // JV: remplacer simplement par itkAGrouper <- mapParcelleAIrriguerParItkIrrigue.keys ?
			itkAGrouper << it;
		} 
		map<string,list<itk>> itkTriee <- ( itkAGrouper group_by (each.strategieIrrigationITK.idGRP));
		map<itk,list<parcelle>> mapParcelleAIrriguerParItkIrrigueEtTriee <- map([]);
		loop idG over:itkTriee.keys{
			list<itk> listITK <- (itkTriee at idG);
			itk unItk <- listITK[0];
			list<parcelle> listParc <- [];
			loop it over: listITK{
				listParc <- listParc + (mapParcelleAIrriguerParItkIrrigue[it]);
			}
			mapParcelleAIrriguerParItkIrrigueEtTriee[unItk] <- listParc;
		}
		return mapParcelleAIrriguerParItkIrrigueEtTriee;
	}

	// Renvoi la liste des parcelles par itk
	map<itk,list<parcelle>> getMapParcellesParITK(list<parcelle> listeParcellesEntree){
		map<itk,list<parcelle>> mapParcelleAIrriguerParITK <- map([]);
		ask listeParcellesEntree {	
			itk itkCourant <- self.getITKAnnee();   			
			if(isIrrigueeAnneeCourante()){
				list<parcelle> listeTemp <- mapParcelleAIrriguerParITK at itkCourant;
				listeTemp << self;
				listeTemp <- remove_duplicates(listeTemp);
				put listeTemp at: itkCourant in: mapParcelleAIrriguerParITK;	    				
			}																					
		}
		
		//Maintenant on assemble les itks par "libellé de groupe d'irrigation". Permet par exemple d'assembler les mais
		// au sein du meme bloc d'irrigation
		list<itk> itkAGrouper <- [];
		loop it over:mapParcelleAIrriguerParITK.keys{
			itkAGrouper << it;
		} 
		map<string,list<itk>> itkTriee <- ( itkAGrouper group_by (each.strategieIrrigationITK.idGRP));
		map<itk,list<parcelle>> mapParcelleAIrriguerParITKEtTriee <- map([]);
		loop idG over:itkTriee.keys{
			list<itk> listITK <- (itkTriee at idG);
			itk unItk <- listITK[0];
			list<parcelle> listParc <- [];
			loop it over: listITK{
				listParc <- listParc + (mapParcelleAIrriguerParITK at it);
			}
			put listParc at: unItk in: mapParcelleAIrriguerParITKEtTriee;
		}
		return mapParcelleAIrriguerParITKEtTriee;
	}
	    	
	// Renvoie la liste des parcelles par ZA
	map<zoneAdministrative,list<parcelle>> getMapParcellesParZA(list<parcelle> listeParcellesEntree){
		map<zoneAdministrative,list<parcelle>> mapParcelleAIrriguerParZA <- map([]); // ZA::{listeParcelles}
		ask listeParcellesEntree {																	
			if(ilot_app.getZAassociee() != nil){
				list<parcelle> listeTemp <- mapParcelleAIrriguerParZA at ilot_app.getZAassociee();
				listeTemp << self;
				listeTemp <- remove_duplicates(listeTemp);
				put listeTemp at: ilot_app.getZAassociee() in: mapParcelleAIrriguerParZA;								
			}																				
		}	   					
		return mapParcelleAIrriguerParZA;
	}
	
	// Renvoie la liste des parcelles par materiel
	map<materielIrrigation,list<parcelle>> getMapParcellesParMateriel(list<parcelle> listeParcellesEntree){
		map<materielIrrigation,list<parcelle>> MapParcellesParMateriel <- map([]); // materiel::{listeParcelles}
		ask listeParcellesEntree {																	
			if(ilot_app.materielIlot != nil){ //cas ne devant pas se produire
				list<parcelle> listeTemp <- MapParcellesParMateriel at ilot_app.materielIlot;
				listeTemp << self;
				listeTemp <- remove_duplicates(listeTemp); //Pourquoi y aurait-il des doublons ? 
				put listeTemp at: ilot_app.materielIlot in: MapParcellesParMateriel;								
			}else{
				write "Probleme: l'ilot "+ ilot_app+ " ne possede pas materiel d'irrigation! ";
			}																				
		}	   					
		return MapParcellesParMateriel;
	}
	  				
	/*
	 * *****************************************************************************************
	 */
	bool isAuMoinsUnIlotEnRestriction{
		ask (sonExploitation.listeIlots){
			if(isEnRestriction()){
				return true;
			}
		}			
		return false;
	}
	
	// JV 161219 appel depuis police de l'eau (bug #0002438)
	int nbIlotsEnRestriction{
		int res <- 0;
		ask (sonExploitation.listeIlots){
			if(isEnRestriction()){
				res <- res + 1;
			}
		}			
		return res;
	}
	
	// Appele dans la police de leau
	bool isIrrigueContreRestriction{
		if(nbParcellesIrriguees > 0){
			ask listeParcelles{
				// Si une des parcelles est en irrigation au pas de temps courant alors qu'une restriction est en cours alors on colore l'agri en rouge
				if(etatIrrigationParcelle = ETAT_IRRIGATION_CONTRE_RESTRICTION){
					return true;
				}
			}				
		}
		return false;
	}
	/*
	 * *****************************************************************************************
	 * Pour le moment même fonction pour les 2 types d'Agri
	 */
	action appliquerITKAlternatif{
		loop parc over: listeParcelles{
			if(parc.itkAlternatifAchercher){
				write "parcelle " + parc.idParcelle + " recherche d'un ITK alternatif";
				parc.itkAlternatifAchercher <- false;
				parc.critereSemiOk_Tmin <- 0;
				parc.critereSemiOk_HumiditeSol <- 0;
				parc.critereSemiOk_Pluie <- 0;
				parc.isTravailSolEffectue <- false;
				parc.OTTravailSolMultiplesEffectuee <- nil;
				parc.OTFaucheMultiplesEffectuee <- nil;
				parc.isBinagesSolEffectue <- false;
				 			
				//on recupere dabord l'information pour savoir si la culture non seme est une culture d'hiver ou non
				//write "parc.systemeDeCultureParcelle" + parc.systemeDeCultureParcelle;
				bool saisonCultureIntiale <- (parc.getITKPlanned().isCultureHiver);	
				bool saisonCultureAlternative <- (parc.getITKAnnee().isCultureHiver) ;	//In the case of an alternative itk, it contains something
																					// different from planned rotation																						
				
				// si on ne peux pas réaliser pour la deuxieme fois alors on repasse a la rotation normale
				if ((parc.itkAlternatif) and (saisonCultureAlternative != saisonCultureIntiale)){ // si on etait deja en itk alternatif alors on se contente de reprendre la rotation normale
					ask parc.systemeDeCultureParcelle{
						do changementITK();
						parc.itkAlternatif <-false;
					}
					if (parc.systemeDeCultureParcelle.isSdcTermine()) { //cas fin de rotation
						if (premierChoixAssolementAnnee){
							do choixAssolement();
							premierChoixAssolementAnnee <- false;
						}
						do getAssolement1parcelle(parc);					
					}
					write "double itkAlternatif !!! pour la parcelle "+parc;						
				}else{
					
					itk itkDeSaisonSuivante <- nil;
					string ZC <- "";
					if (parc.isParcelleHorsZone){
						list<parcelle> parcelleExploit <- (listeParcelles where (each.ilot_app.zoneHydroAssociee != nil));
						// Ben
						// parcelle parcelleATester <- (listeParcellesATester with_min_of(each.location distance_to (parc.location)));
						parcelle tmp <- (parcelleExploit with_min_of( each.location distance_to (parc.location) ));
						
						ZC <- tmp.ilot_app.zoneHydroAssociee.zoneClimatique;
						
					}else{
						ZC <- parc.ilot_app.zoneHydroAssociee.zoneClimatique;
					}
					
					list<parcelle> listeParcellesATester <- [];
					int jourFinSemiPossible <- 1; 
					
					if (saisonCultureIntiale){ //Si Hiver alors on cherche printemps
						// 1- On regarde dans la rotation s'il n'y a pas ITK de saison opposée
						itkDeSaisonSuivante <- parc.getITKDeSaisonSuivante(false);
					}else{
						jourFinSemiPossible <- 1 + parc.getStrategie(SEMIS).getJourJulienFinMax(nbJoursDeDecalageActivite); 
					}
					
				
				    // 2- On regarde les parcelles de l'exploitation
					if (itkDeSaisonSuivante = nil){
						listeParcellesATester <- copy(self.listeParcelles); 
						// enlever la parcelle de reference
						listeParcellesATester >> parc;
						loop p over:self.listeParcelles{ //boucle sur les parcelles de l'exploitation
							itk itkpotentielle <- p.getITKAnnee(); 
							//On supprime les parcelles HZ ou de saison opposée à celle recherchée (on recherche forcément un ITK de printemps car si on cherchait un ITK hiver soit on en aurait trouvé un dans le bloc précédent (et donc itkDeSaisonSuivante!=nil, soit on n'en a pas trouvé en on cherche maintenant un ITK de printemps)
							// si l'ITK est un gel on la supprime (pas d'ITK gel comme ITK alternatif)
							// si l'ITK est un CI on la supprime (pas de CI comme ITK alternatif)
							// si la parcelle est non irrigable et que l'itk est irrigable alors on l'enlève également
							// si l'ITK n'est pas realisable dans la zone climatique de la parcelle, on la supprime également
							if (p.isParcelleHorsZone) or (itkpotentielle.isCultureHiver) or (itkpotentielle.especeCultiveeITK.idEspeceCultivee="gel") or (itkpotentielle.especeCultiveeITK.isCI()) or
							 ((!parc.isParcelleIrrigable()) and (itkpotentielle.strategieIrrigationITK != nil)) or 
							 	!(itkpotentielle.especeCultiveeITK.listZoneClimatiquePossible contains ZC) or
							 	(jourFinSemiPossible > itkpotentielle.strategieSemisITK.getJourJulienFinMax(nbJoursDeDecalageActivite)){
								listeParcellesATester >> p;
							}
						}
						if (length(listeParcellesATester) >0){
							// parcelle parcelleATester <- (listeParcellesATester closest_to parc );
							parcelle parcelleATester <- (listeParcellesATester with_min_of(each.location distance_to (parc.location)));
							
							if (parcelleATester = nil){ // Ne devrait pas se produire!!! 
								// le problème vient du faire que les parcelles HZ sont également hors environment
								// en conséquence le closest to  renvoit nil
								parcelleATester <- first(listeParcellesATester);
							}
							itk itkpotentielle <- parcelleATester.getITKAnnee();
							itkDeSaisonSuivante <- itkpotentielle;
						}
					}
												
					// 3- Si on a pas troouvé d'ITK satisfaisant alors on regarde les parcelles des exploitations voisines
					if (itkDeSaisonSuivante = nil){
						listeParcellesATester <- copy(listeParcellesUtiles); //Ensemble de toutes les parcelles 
						// enlever la parcelle de reference
						listeParcellesATester >> parc;
						loop p over:listeParcellesUtiles{ //boucles parcelles du territoire
							itk itkpotentielle <- p.getITKAnnee();
							//On supprime les parcelles HZ ; les parcelles de saison opposées; 
							// si l'ITK est un gel on la supprime (pas d'ITK gel comme ITK alternatif)
							// si l'ITK est un CI on la supprime (pas de CI comme ITK alternatif)
							// si la parcelle est non irrigable et que l'itk est irrigable alors on l'enlève également
							// si l'ITK n'est pas realisable dans la zone climatique de la parcelle, on la supprime également
							if (p.isParcelleHorsZone) or (itkpotentielle.isCultureHiver) or (itkpotentielle.especeCultiveeITK.idEspeceCultivee="gel") or (itkpotentielle.especeCultiveeITK.isCI()) or
								((!parc.isParcelleIrrigable()) and (itkpotentielle.strategieIrrigationITK != nil)) or 
							 	!(itkpotentielle.especeCultiveeITK.listZoneClimatiquePossible contains ZC) or
							 	(jourFinSemiPossible > itkpotentielle.strategieSemisITK.getJourJulienFinMax(nbJoursDeDecalageActivite)){
								listeParcellesATester >> p;
							}
						}
						if (length(listeParcellesATester) >0){
							//parcelle parcelleATester <- (listeParcellesATester closest_to parc );
							parcelle parcelleATester <- (listeParcellesATester with_min_of(each.location distance_to (parc.location)));
							
							if (parcelleATester = nil){ parcelleATester <- first(listeParcellesATester);} // cf. remarque bloc précédent
							itk itkpotentielle <- parcelleATester.getITKAnnee();
							itkDeSaisonSuivante <- itkpotentielle;
						}
					}
					// 4- Dans le cas très particulier de la culture de printemps ou la recherche de la culture de printemps n'a rien donnee alors
					// on recherche un culture d'hiver
					if (itkDeSaisonSuivante = nil){
						if !(saisonCultureIntiale){ // si printemps
							
							// 4-1 On regarde dans la rotation s'il n'y a pas ITK de saison opposée
							itkDeSaisonSuivante <- parc.getITKDeSaisonSuivante(true);
							
							if (itkDeSaisonSuivante = nil){
								// 4-2 On regarde sur le reste du territoire
								listeParcellesATester <- copy(listeParcellesUtiles); //Ensemble de toutes les parcelles 
								// enlever la parcelle de reference
								listeParcellesATester >> parc;
								loop p over:listeParcellesUtiles{ //boucles parcelles du territoire
									itk itkpotentielle <- p.getITKAnnee();
									//On supprime les parcelles HZ ; les parcelles de saison opposées; 
									// si l'ITK est un gel on la supprime (pas d'ITK gel comme ITK alternatif)
									// si l'ITK est un CI on la supprime (pas de CI comme ITK alternatif)
									// si la parcelle est non irrigable et que l'itk est irrigable alors on l'enlève également
									// si l'ITK n'est pas realisable dans la zone climatique de la parcelle, on la supprime également
									if (p.isParcelleHorsZone) or !(itkpotentielle.isCultureHiver) or (itkpotentielle.especeCultiveeITK.idEspeceCultivee="gel") or (itkpotentielle.especeCultiveeITK.isCI()) or
										((!parc.isParcelleIrrigable()) and (itkpotentielle.strategieIrrigationITK != nil)) and 
								 	!(itkpotentielle.especeCultiveeITK.listZoneClimatiquePossible contains ZC){
										listeParcellesATester >> p;
									}
								}
								if (length(listeParcellesATester) >0){
									// parcelle parcelleATester <- (listeParcellesATester closest_to parc );
									parcelle parcelleATester <- (listeParcellesATester with_min_of(each.location distance_to (parc.location)));
									
									if (parcelleATester = nil){ parcelleATester <- first(listeParcellesATester);} // cf. remarque bloc précédent
									itk itkpotentielle <- parcelleATester.getITKAnnee();
									itkDeSaisonSuivante <- itkpotentielle;
								}
							}
						}
					}
					
					// 5- Affectatio de l'ITK alternatif					
					if (itkDeSaisonSuivante != nil){
						ask parc{
							write "a la place de "+ parc.getITKAnnee().idITK +" on va mettre " + itkDeSaisonSuivante.idITK + " pour la parcelle "+parc.idParcelle + " a la date du "+ string(dateCour.annee) + "/"+ dateCour.mois + "/" + dateCour.jour;
							do setITKAlternatif(itkDeSaisonSuivante);
						}
					}
				}
			}
		}
	} 
	
	action uniformisationBloc(parcelle parc, systemeDeCultureDeReference sdcDuBloc){
	//	do initRotation(parc);
	}

	/*
	 * determine a quelle etat de la rotation la parcelle commence
	 */
//		action initRotation(parcelle parc){
//			if(parc.systemeDeCultureParcelle != nil){
//				//mapIndiceDepartRotation
//			}
//		}
	
	// Fonction permettant d'enregistrer une rendement pour une année données, un sol donné et une culture donnée
	// -> pour incrémentation de la variable rendements_sol_culture Renaud 250625
	action memorisationRendementNminAnneeSolCulture (parcelle parcelleCourante, int annee, float rendement, float Nmin_cumul, string sol, especeCultivee espece, especeCultivee precedent, string typeExploitation) {
		// Si le précédent est nul (première récolte) on prend la culture de l'itk précédent
		if (precedent = nil) {
			precedent <- parcelleCourante.systemeDeCultureParcelle.getITKanneePrecedente().especeCultiveeITK;
		}

		// Identification de la situation courante
		situationAction situationActionCourante;
		situationActionCourante <- first(situationAction where (each.espece_situation.idEspeceCultivee = espece.idEspeceCultivee
																				and each.precedent_situation.idEspeceCultivee = precedent.idEspeceCultivee
																				and each.sol_situation = sol 
																				and each.typeExploitation_situation = typeExploitation
																			));		
		
		// Création de la situation si elle n'existe pas encore
		if (situationActionCourante = nil) {
			create situationAction number: 1 {
				set espece_situation <- espece;
				set precedent_situation <- precedent;
				set sol_situation <- sol;
				set typeExploitation_situation <- typeExploitation;
				set materieIrrigation_situation <- parcelleCourante.ilot_app.materielIlot;
				situationActionCourante <- self;
			}
		}
		// Enregistrement des variables d'intérêt
		// Rendements
		list<float> rendements_ <- situationActionCourante.annees_rendements[annee];
		rendements_ <+ rendement;
		situationActionCourante.annees_rendements[annee] <- rendements_;
		
		// Nmin
		list<float> Nmin_cumules_ <- situationActionCourante.annees_Nmin[annee];
		Nmin_cumules_ <+ Nmin_cumul;
		situationActionCourante.annees_Nmin[annee] <- Nmin_cumules_;
	}
	

	
	// Calcul du coefficient d'abattement corpen Renaud 220725
	float N_a_apporter_corrige_NminSOM (parcelleAqYieldNC parcelleCourante) {
		especeCultivee espece_courante <- parcelleCourante.getITKAnnee().especeCultiveeITK;
		string nom_espece_precedente <- parcelleCourante.systemeDeCultureParcelle.getITKanneePrecedente().especeCultiveeITK.idEspeceCultivee;
		string nom_espece_courante <- espece_courante.idEspeceCultivee;
		string nom_sol_courant <- parcelleCourante.ilot_app.sol.nom;
		string typeExpl_courant <- parcelleCourante.ilot_app.agriculteurAssocie.sonExploitation.type;
		
		// Identification de la situation courante
		situationAction situationActionCourante;
		situationActionCourante <- first(situationAction where (each.espece_situation.idEspeceCultivee = nom_espece_courante
																				and each.precedent_situation.idEspeceCultivee = nom_espece_precedente
																				and each.sol_situation = nom_sol_courant 
																				and each.typeExploitation_situation = typeExpl_courant
		 																	));	
//		write "espece = " + nom_espece_courante + " - prec = " + nom_espece_precedente + " - sol = " + nom_sol_courant + " - typeExpl = " + typeExpl_courant;
//		write "situationActionCourante = " + situationActionCourante;
		// Si ce n'est pas un CI et pas une prairie
		if (espece_courante.isCouvert = false and !(listeNomsEspecesHerbSim contains nom_espece_courante) and situationActionCourante != nil) {
			map rendements_situation <- situationActionCourante.annees_rendements; // Annee::sol::culture::[rendement1, rendement2, ...]
			map Nmin_situation <- situationActionCourante.annees_Nmin; // Annee::sol::culture::[rendement1, rendement2, ...]
			
			// 1. Quelles sont les années qui vont être utilisées pour calculer l'abattement ?
			int nb_annees <- corpenProfondeurTemporelle;
			list<int> annees_concernees <- [];
			int annee_ref <- dateCour.annee - (dateCour.nbJoursEcoulesDansAnnee < 213 ? 1 : 0); // 213 correspond au 1er aout
			
			// Remplissage de la liste en fonction de l’année de référence
			loop i from: 0 to: nb_annees - 1 {
				annees_concernees <+ (annee_ref - i);
			}
			
			// Nettoyage des années non concernées
			loop a over: rendements_situation.keys {
				if !(annees_concernees contains a) {
					rendements_situation[] >- a;
				}
			}
			loop a over: Nmin_situation.keys {
				if !(annees_concernees contains a) {
					Nmin_situation[] >- a;
				}
			}
			
//			write "------------";
//			write "rendements_situation --> " + rendements_situation;
//			write "Nmin_situation --> " + Nmin_situation;
//			write "CORPEN sol = " + nom_sol_courant;
//			write "CORPEN culture = " + nom_espece_courante;
//			write "CORPEN annees = " + annees_concernees;
			
			// 2. Récupération des rendements sur les années / sol / culture concernés
			list<float> rendements_situation_periode;
			loop a over: annees_concernees {
				list rendements_annee <- rendements_situation[a];
				if (length(rendements_annee) > 0) {
					rendements_situation_periode <<+ rendements_annee;
				}
			}
//			write "rendements corpen avant suppr rdmt trop faibles = " + rendements_situation_periode;
			
			// 3. Suppression des rendements trop faibles
			if (length(rendements_situation_periode) > 0) {
			  float moyenne_globale <- mean(rendements_situation_periode);
			  float seuil_rendements_faibles <- 0.75 * moyenne_globale;
			  rendements_situation_periode <- rendements_situation_periode where (each >= seuil_rendements_faibles);
			}
			
//			write "rendements corpen après suppr rdmt trop faibles = " + rendements_situation_periode;
			
			// 3. Récupération des Nmin
			list<float> Nmin_situation_periode;
			loop a over: annees_concernees {
				list<float> Nmins_annee <- Nmin_situation[a];
				if (length(Nmins_annee) = 1) {
					Nmin_situation_periode <+ float(Nmins_annee);
				} else if (length(Nmins_annee) > 1) {
					Nmin_situation_periode <+ float(mean(Nmins_annee));
				}
			}
//			write "Nmin corpen = " + Nmin_annees_sol_culture;
			
			// 4. Correction des besoins de la culture en fonction des rendements observés
			// Besoins originaux
//			write "espece_courante.besoin_N_total  = " + espece_courante.besoin_N_total;
//			write "espece_courante.besoin_N  = " + espece_courante.besoin_N;
			float besoin_base <- (espece_courante.besoin_N_total != 0.0) ? espece_courante.besoin_N_total : espece_courante.besoin_N * espece_courante.rendementOptimal;
			float besoins_espece_corriges <- 0.0;
			
			// Besoins corrigés par les rendements moyens observés
			if (length(rendements_situation_periode) = 0) {
			    besoins_espece_corriges <- besoin_base;
			} else {
			    float rendement_moyen <- mean(rendements_situation_periode);
			    if (espece_courante.besoin_N_total != 0.0) {
			        besoins_espece_corriges <- besoin_base * rendement_moyen / espece_courante.rendementOptimal;
			    } else {
			        besoins_espece_corriges <- espece_courante.besoin_N * rendement_moyen;
//			        write "rendement_moyen = " + rendement_moyen;
			    }
			}
//			write nom_espece_courante + " --> besoins corriges = " + besoins_espece_corriges;
			
			// 5. Calcul du N à apporter
			float quantite_N_a_apporter <- besoins_espece_corriges - mean(Nmin_situation_periode);
//			write "N_a_apporter_corrige_NminSOM() : " + nom_espece_courante + " " + quantite_N_a_apporter;
	
			//string rendements_annees <- parcelleCourante.ilot_app.agriculteurAssocie.rendements_sol_culture;
			return quantite_N_a_apporter;
		} else {
//			write "Pas d'abattement prévu (couvert, prairie, situationAction qui n'existe pas)";
			return -888.888;
		}

	}


	
	/*
	 * *****************************************************************************************
	 */
	bool isAafficher{
		if(nbParcellesIrriguees > 0){
			return true;		
		}else{
			return false;
		}    		
	}
	rgb getCouleurEauDisponible{
		if(nbParcellesIrriguees > 0){
			// coloration en fonction de l'eau dispo, si elle est < 0 cela veut dire que l'agri a utilise plus que son VP dispo : il est donc hors la loi
			if(eau_disponible < (-zeroApproche)){
				return couleurRouge;
			}else if(eau_disponible >= (-zeroApproche) and eau_disponible <= zeroApproche){
				return couleurOrange;
			}else{
				return couleurVertClaire;
			}			
		}else{
			return rgb('white');	
		}				
	}
	rgb getCouleurIrrigationContreRestriction{
		if(isIrrigueContreRestriction()){
			taillePointAgriculteur <- 2000;
			return couleurRouge;
		}else{
			return couleurVertClaire;
		}				
	}
	    	
	/*
	 * *****************************************************************************************
	 * Display
	 */
	aspect basic{
		draw circle(taillePoints) color: rgb('green');
	}
	aspect restrictionAspect{
		if(isAafficher()){ 
			draw circle(taillePointAgriculteur) color: getCouleurIrrigationContreRestriction() ; //float(taillePoints)   taillePointAgriculteur
		}			 
	}		
	aspect eauDisponibleAspect{
		if(isAafficher()){
			draw  circle(taillePoints) color: getCouleurEauDisponible();	
		}
	}	
	aspect imageAspect{
		draw image_file(imageAgriculteur) size: 800;
	}

	string toString{
		string chaine <- '';
		ask listeParcelles{
			chaine <- chaine + toString();
		}			
		return name + ' : listeParcelle = ' + listeParcelles + '\n' + chaine;
	}
}	


