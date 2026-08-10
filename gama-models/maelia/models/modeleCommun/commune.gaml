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
 *  Communes
 *  Author: Maroussia Vavasseur
 *  Description: C'est au niveau des communes qu'est pris en compte l'evolution de la population
 */

model commune

import "contourZoneMaelia.gaml" 

global{
	string communesShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/communes-trimUG.shp';
	string cheminPopulationCommunes <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/resultatsEDEM.csv';
	string cheminPrixEauCommunes <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/prix_eau_maelia_complet.csv';
	string cheminSalaireCommunes <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/salaires_maelia-complet.csv';
	string cheminResidencePrincipaleCommunes <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/residence_principale_maelia-complet.csv';
	
	float volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia <- 0.0;	
	float volumeJournalierEauPotableConsommeeSouhaiteZoneMaelia <- 0.0;
	
	
	/* 
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionCommunes{
		if(file_exists(communesShape)){
			matrix initDataPrixEauCommunes <- matrix(csv_file (cheminPrixEauCommunes,";",false));
			matrix initDataSalaireCommunes <- matrix(csv_file (cheminSalaireCommunes,";",false));
			matrix initDataResidencePrincipaleCommunes <- matrix(csv_file (cheminResidencePrincipaleCommunes,";",false));
		
			create commune from: file(communesShape) with: [codeInsee::string(read ( CODE_INSEE))]{
				codeInseeInt <- int(codeInsee);
				
				// Suppression des communes nappartenat pas a la zone detude 
				if(executerModeleSurUneZH and contourZoneEtude != nil and !(shape intersects contourZoneEtude.shape)){									
					ask self{
						do die;	
					}						
				}				
			}
			do initialisationCommunes;
			do lectureFichiers initDataEntree: initDataPrixEauCommunes isPrixEau: true isSalaire: false isResidencePrincipale: false;
			do lectureFichiers initDataEntree: initDataSalaireCommunes isPrixEau: false isSalaire: true isResidencePrincipale: false;
			do lectureFichiers initDataEntree: initDataResidencePrincipaleCommunes isPrixEau: false isSalaire: false isResidencePrincipale: true;			
		}else{
			do raiseWarning("fichier des communes inexistant: " + communesShape);
		}
	}
	
	
	/*
	 * *****************************************************************************************
	 * Private
	 * Initialisation des attributs des communes, notamment de la population
	 */
	 action initialisationCommunes{
		matrix initDataPopulationCommunes <- matrix(csv_file (cheminPopulationCommunes,";",false));

	 	int nbLignes <- length(initDataPopulationCommunes column_at 0);
	 	list<int> listeAnnees <- (initDataPopulationCommunes row_at 0 as list<int>);

		loop i from: 1 to: ( nbLignes - 1 ) {
			list ligneI <- (initDataPopulationCommunes row_at i);
			string codeInseeLigneCourante <- string(ligneI at 0);
			
			/*
			 * Rajout du '0' devant dans le cas ou la commune est dans le 09 car le fichier csv lu a son attribut 'codeInsee' de type int et n'a pas le 0 devant ce qui pose un conflit avec le
			 * codeInsee de l'agent commune qui est lui de type string
			 */
			if first(codeInseeLigneCourante) = '9'{
				set codeInseeLigneCourante value: '0' + codeInseeLigneCourante;
			}
			
			let communeCourante type: commune value: (commune as list) first_with (each.codeInsee = codeInseeLigneCourante);
						
			/*
			 * Boucle sur les colones pour mettre dans la map la population par annee.
			 * On commence a la colone 2 (sachant que la premi?re est la 0) car il s'agit de la premiere colone donnant la population pour la premiere annee
			 */
			 if communeCourante != nil{
			 	 loop coloneCourante from: 1 to: (length( listeAnnees ) - 2) { // -2 car gama rajoute une colone...
				 	put float(ligneI at coloneCourante) at: int(listeAnnees at coloneCourante) in: communeCourante.mapPopulationParAnnee;
				 }				
			 }			 
		 }
	 }	

	/*
	 * *****************************************************************************************
	 * Private
	 * Initialisation des attributs des communes, notamment de la population
	 */
	 action lectureFichiers{
	 	arg initDataEntree type: matrix default: [];
	 	arg isPrixEau type: bool default: false;
		arg isSalaire type: bool default: false;
		arg isResidencePrincipale type: bool default: false;
	 	
	 	let nbLignes type: int value: length(initDataEntree column_at 0);
	 	let listeAnnees type: list of: int value: initDataEntree row_at 0 as list<int>;

		loop i from: 1 to: ( nbLignes - 1 ) {
			let ligneI type: list value: (initDataEntree row_at i);
			let codeInseeLigneCourante type: int value: int(ligneI at 0);		
			let donneesAstockerCourante type: float value: float(ligneI at 1);		
			let communeCourante type: commune value: (commune as list) first_with (string(each.codeInseeInt) = string(codeInseeLigneCourante));
						
			if communeCourante != nil{
				if(isPrixEau){
//					put donneesAstockerCourante at: 2000 in: communeCourante.prixEauPotable;
					set communeCourante.prixEauPotable value: donneesAstockerCourante;
				}
				if(isSalaire){
					set communeCourante.salaireMoyen value: donneesAstockerCourante;
				}
				if(isResidencePrincipale){
					set communeCourante.tauxResidencesPrincipales value: donneesAstockerCourante;
				}
			}			 
		 }
	 }	
		 
	/*
	 * *****************************************************************************************
	 * Publique
	 * Doit etre fait apres la creation des UG
	 */
	 action initialisationUGCommunes{
		ask(commune as list){
			do initialisationCommune;
		}
	 }
	 
	/*
	 * *****************************************************************************************
	 * Publique [APPELLEE DEPUIS LE MAIN]
	 * Doit etre une fois par an
	 */
	 action calculVolumeAEPconsomeAnnuelZM{
	 	volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia <- 0.0;
		ask(commune as list){
			volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia <- volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia + (mapConsomationEauPotable at dateCour.annee);
		}
	 }		 
	/*
	 * *****************************************************************************************
	 * Publique [APPELLEE DEPUIS LE MAIN]
	 * Alogrithme de journalisation AEP
	 */		
	action calculVolumeAEPconsomeJournalierSouhaiteZM{
		let k type: float value: 0.34;
		let di type: int value: 0;
		let dj type: int value: 0;
		let jourCourant type: int value: 0;

		ask dateCour{
			set di value: calculNbJourEcouleDansAnnee(jourEntree:premierJourEtiageAEAG ,moisEntree:premierMoisEtiageAEAG); 
			set dj value: calculNbJourEcouleDansAnnee(jourEntree:dernierJourEtiageAEAG ,moisEntree:dernierMoisEtiageAEAG); 
			set jourCourant value: calculNbJourEcouleDansAnneeAlaDateCourante(); 
		}
			
		let a type: float value: (volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia*(1-k)) / (dateCour.getNbJoursDansAnneeCourante()-(dj-di));
		let b type: float value: volumeAnnuelEauPotableConsommeeSouhaiteZoneMaelia*k - a*(dj-di);
		let c type: float value: 3.72;
		let mu type: float value: (di+dj)/2;
		let sigma type: float value: (dj-di)/(2*c);
		volumeJournalierEauPotableConsommeeSouhaiteZoneMaelia 
				<- a + b*((1/sqrt(2*3.14*sigma)) * exp(-((jourCourant-mu)^2)/(2*(sigma^2))));
			
		//write "volumeJournalierEauPotableConsommeeSouhaiteZoneMaelia=" + volumeJournalierEauPotableConsommeeSouhaiteZoneMaelia;
	}
	
	float getNbHabitants_ZM{
		float nb <- 0.0;
		ask (commune as list){
			nb <- nb + populationAnneeCourante;
		}		
		return nb;
	}
}

species commune {
	string codeInsee <- ""; // Remarque: le type du code doit etre 'string' car sinon il y a un pb pour les communes du 09 (le 0 place devant n'est pas reconnu comme un entier)
	int codeInseeInt <- 0;
	float populationAnneeCourante <- 0.0;
	map<int, float> mapPopulationParAnnee <- map<int, float>([]); // annee::population
	map<int, float> mapConsomationEauPotable <- map<int, float>([]); // annee::conso
	float prixEauPotable <- 0.0;
	float salaireMoyen <- 0.0;
	float tauxResidencesPrincipales <- 0.0;
	zoneMeteo zoneMeteoAssociee <- nil;
	rgb couleurCommune <- rgb('lightGray'); //rgb([206, 206, 206]);
	uniteDeGestion uniteDeGestionAssociee <- nil;
	
	/*
	 * *****************************************************************************************
	 */	
	action comportementAnnuel{	
		do agmentationDeLaPopulation;
		do consomationEauPotableMogire;
	}

	/*
	 * *****************************************************************************************
	 */		
	action initialisationCommune{
		uniteDeGestionAssociee <- uniteDeGestion closest_to location;
		if(uniteDeGestionAssociee = nil){
			write "Problem on closest_to for uniteDeGestion and Commune" ;
			uniteDeGestionAssociee <- first(uniteDeGestion);
		}
	}
	
	/*
	 * *****************************************************************************************
	 * Processus externe : Chaque annee la population augmente : cette augmentation se fait a l'aide d'equation statistiquement precalculees a l'aide de donnees sue 5 ans
	 */
	action agmentationDeLaPopulation{			
		set populationAnneeCourante value: mapPopulationParAnnee at (dateCour.annee);			
	}		

	/*
	 * *****************************************************************************************
	 * Modele Mogire : on recalcule chaque annee la consommation en eau potable en fonction entre autre de la population
	 */
	action consomationEauPotableMogire{	
//			if((prixEauPotable at (int(dateCour.annee) - 1)) != nil){
//				put prixEauPotable at (int(dateCour.annee) - 1) at: int(dateCour.annee) in: prixEauPotable; // TODO : rajouter l'annee suivante
//			}		
//			let P type: float value: prixEauPotable at int(dateCour.annee);
		
		let P type: float value: prixEauPotable;
		let I type: float value: salaireMoyen;
		let T type: float value: 0.0;
		if(zoneMeteoAssociee != nil){
			loop indiceDateCourante from: indiceDateDebutEte to: indiceDateFinEte{
				set T value: T + (zoneMeteoAssociee.mapTemperaturesMax at indiceDateCourante);
			}
		}			
		set T value: T / (indiceDateFinEte - indiceDateDebutEte);						
		let R type: float value: tauxResidencesPrincipales;
		let D type: float value: populationAnneeCourante / (shape.area*0.000001); // hab/km2

		let volmueConsommeTemp type: float value: 0.0;
		if(P != 0.0 and I != 0.0 and T != 0.0 and R != 0.0 and D != 0.0){
			set volmueConsommeTemp value: (dateCour.getNbJoursDansAnneeCourante()) * populationAnneeCourante * exp(-1.574 - 0.260*ln(P) + 0.006*ln(I*152*12) - 0.017*ln(T) + 1.493*ln(R) - 0.097*ln(D/100));				
		}
		
		put volmueConsommeTemp at: dateCour.annee in: mapConsomationEauPotable;
	}
			
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw shape color: couleurCommune border: #black;
	}
	
	/*
	 * *****************************************************************************************
	 */
	action toString{
		write "******* " + name + " *******"; 
		write "codeInsee = " + codeInsee;
		write "uniteDeGestionAssociee = " + uniteDeGestionAssociee; 
		write "zoneMeteoAssociee = " + zoneMeteoAssociee; 
		write "mapPopulationParAnnee = " + mapPopulationParAnnee; 
		write "populationAnneeCourante = " + populationAnneeCourante; 
		write "prixEauPotable = " + prixEauPotable; 
		write "salaireMoyen = " + salaireMoyen; 
		write "tauxResidencesPrincipales = " + tauxResidencesPrincipales; 
		write "mapConsomationEauPotable = " + mapConsomationEauPotable; 			
	}
}
