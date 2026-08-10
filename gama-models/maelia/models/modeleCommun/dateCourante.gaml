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
 *  DateCourante
 *  Author: Maroussia Vavasseur
 *  Description: C'est ici que sont geres tous les aspects lies a la date de la simulation. 
 * 				 Les methodes de cette entites peuvent s'utiliser aussi bien sur la date courante que pour realiser des calcul intermediaires.
 * 				 Les 2 attributs pricipaux sont : idDate (ou identifiant date, entier de la form JJMMAAAA) et 
 * 				 indiceDate (entier incrementale pour chaque pas de temps de la simulation, ou le pas de temps est la journee) : 
 * 				 il ne commence pas a zero mais a un entier egale au nombre de jour ecoule depuis la date "zero" definie en dure.
 */

model dateCourante

import "timeStamp.gaml"

global{
	matrix initDataDate <- matrix(csv_file ( '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/date/joursParMois.csv',";",false )); // donne le nombre de jours par mois sur une annee (bissextile et non bissextile)	
	//matrix initDataDate <- matrix(file ( '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/date/joursParMois.csv' )); // donne le nombre de jours par mois sur une annee (bissextile et non bissextile)	
	

	int nbHeureDansUneJournee const: true <- 24;
	int nbSecondesDansUneHeure const: true  <- 3600;
	int nbJoursDansUneAnneeNonBissextile const: true  <- 365;
	int nbAnneesDansCycleIntercalaire const: true  <- 4; // un cycle I est, une sequence d'annees consecutives contenant un nombre fixe d'annees et de jours. Dans le calendier gregorien il est egale a 4 annees (avec un jour intercalaire)
	int nbJoursDansUnCycleIntercalaire const: true <- 1461; // 365 * 3 (3 annees non bissextiles) + 366 (1 annee bissextile)
	int nbJoursDansUneSemaine const: true <- 7; // il faut une annee bissextile de sorte que la 4ieme annee du cycle Intercalaire soit l'annee bissextile
	int jourZero const: true <- 1;
	int moisZero const: true <- 1;
	int anneeZero const: true <- 1949; // il faut une annee de sorte que la 4ieme annee du cycle Intercalaire soit l'annee bissextile
	int indiceJourDeLaSemaineDateZero const: true <- 2; // Jour de la semaine de la date zero
	int indiceColoneAnneeBissextile const: true <- 1;
	int indiceColoneAnneeNonBissextile const: true <- 2;	
	map<int,string> mapJoursDeLaSemaine const: true <- [1::'Lu', 2::'Ma', 3::'Me', 4::'Je', 5::'Ve', 6::'Sa', 7::'Di'];

	int indiceDateDebutEte <- 0;
	int indiceDateFinEte <- 0;	
	int indiceDateFinSimulation <- 0;
	int indiceDateDebutSimulation <- 0;
	int indexDateFinFrein <- 0;
	int indexDateDebutFrein <- 0; // Modif Renaud 22/05/19
	int idDateDebutSimulation <- 0; // 1012000
	int idDateFinSimulation <- 0; // 1012000
	dateCourante dateCour <- nil;
		
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionDateCourante{

		idDateDebutSimulation <- (jourDebutSimulation * 1000000) + (moisDebutSimulation * 10000) + (anneeDebutSimulation); // sous la forme 1011979 pour 01/01/1979
		int jourFinSimulation <- 31;
		int moisFinSimulation <- 12;		
		int anneeFinSimulation <- anneeDebutSimulation + (nbAnneesSimulation - 1);
		idDateFinSimulation <- (jourFinSimulation * 1000000) + (moisFinSimulation * 10000) + (anneeFinSimulation); // sous la forme 1011979 pour 01/01/1979
			
		create dateCourante number: 1;
		ask dateCourante { // ici i y a un "as list" mais il y a bel et bien une seule dateCourante instanciee
			do initialisationDateCourante;
		}
		dateCour <- first(dateCourante as list);
		do calculIndiceDatesDivers;
	}

	/*
	 * *****************************************************************************************
	 * Private
	 * Calcul d'indice ou ce nb de jour dans l'annee en fonction de jour specifiques (debut etiage, debut/fin ete)
	 */	
	action calculIndiceDatesDivers{			
		ask dateCour{
			indiceDateDebutSimulation <- convertirIdDateEnIndice(idDateAConvertir:idDateDebutSimulation);
			indiceDateFinSimulation <- convertirIdDateEnIndice(idDateAConvertir:idDateFinSimulation);
			indiceDateDebutEte <- convertirDateEnIndice(jourAConvertir:premierJourEte, moisAConvertir:premierMoisEte, anneeAConvertir:annee) ;
			indiceDateFinEte <- convertirDateEnIndice(jourAConvertir:dernierJourEte, moisAConvertir:dernierMoisEte, anneeAConvertir:annee) ;
			indexDateDebutFrein <- calculNbJourEcouleDansAnnee(jourEntree:premierJourFein ,moisEntree:premierMoisFein); // JV 290621 cf Mantis #0002849
			indexDateFinFrein <- calculNbJourEcouleDansAnnee(jourEntree:dernierJourFein ,moisEntree:dernierMoisFein);
		}
	}	
}
	
/*
 * Cette espece doit etre placee avant toutes les autres qui sont dynamiques (avec des reflexs) car la prise en compte du temps doit etre
 * faite en premier pour que tous les agents se basent sur le meme temps reajuste en date.
 * Donne la date courante (sous la forme d'un indice incremente) correspondant au "time" de gama.
 * Par exemple, si on prend comme date zero le 01/01/1952 et que la simulation commence a une date de 01/01/1953, 
 * alors le time = 0 equivaut a la dateCourante = 365.
 */
species dateCourante{
	int idDate <- 0;
	int jour <- 0;
	int mois <- 0;
	int annee <- 0;
	int indiceDate <- 0;
	int indiceDateInitial <- 0;
	int nbJoursEcoulesDansAnnee <- 1;
	int indiceJourDeLaSemaine <- 0;
//		int nombreJourDansAnneeCourante <- 0;
	bool isAnneeBissextile <- false;
	float longueurDuJour <- 0.9;
	int idJourMois <- 0;
	
	/*
	 * *****************************************************************************************
	 */
	action comportementJournalier{
		do miseAJourDateCourante();
		do majJourDeLaSemaine();
	}

	/*
	 * 	*****************************************************************************************
	 * Initialisation de l'indice de la date courante en fonction de la date de debut de simulation definie en entree de la simulation
	 */
	action initialisationDateCourante{				
		idDate <- idDateDebutSimulation; // sous la forme 1011979 pour 01/01/1979
		jour <- int(idDate / 1000000);		
		mois <- int(idDate / 10000) - jour * 100;
		annee <- idDate - (jour * 1000000 + mois * 10000);	

		// Par defaut, si l'annee initiale est inferieure a l'annee zero, on la met egale a l'annee zero
		if (annee < anneeZero){
			annee <- anneeZero;
		}
		indiceDateInitial <- int(convertirDateEnIndice(jourAConvertir:jour, moisAConvertir:mois, anneeAConvertir:annee));	
		indiceDate <- indiceDateInitial;
						
	}
				
	/*
	 * *****************************************************************************************
	 * Mise a jour de l'indice de la date courante en fonction du time gama (tous les pas de temps).
	 */	
	action miseAJourDateCourante{			
		indiceDate <- indiceDateInitial + (cycle); // le time commence a 0	
		do convertirIndiceEnDateJourCourant() ; // met a jour le jour, mois et annee courante
		idJourMois <- (jour * 100) + mois;	
		nbJoursEcoulesDansAnnee <- calculNbJourEcouleDansAnneeAlaDateCourante();
		
		// on sauvegarde le temps ecoule au moment ou on lance la simulation (run) depuis le lancement de l'initialisation
		if(idDate = idDateDebutSimulation){
			float timeStampTemp <- 0.0;
			ask first(timeStamp as list){
				timeStampTemp <- getTimeStamp();
			}										
			timeStampPremierJourSimulation <- timeStampTemp;
		}
		
		// Mise a jour nb jour dans lannee
//			do isAnneeBissextile;			
		
		// Calcul de la longeur du jour (heure)
		int nbJoursParRapportDateRef <- calculNbJourEcouleEntreDeuxDates(jourDebutEntree:jourRefCalculLongueurJour, moisDebutEntree:moisRefCalculLongueurJour, jourFinEntree:jour, moisFinEntree:mois);			
		
		longueurDuJour <- (1 + indiceLJ * sin((nbJoursParRapportDateRef*2*PI/getNbJoursDansAnneeCourante()) * 180 / PI))^coefLJ; // Vérifié Renaud avec Hélène 05/06/18 colle bien à AqYield Excel // JV 270721 ajoute lors de la fusion (auparavant meme code mais en deux lignes avec variable intermediaire)
	}
	
	string getNom{
		string j <- "" + jour;
		if(jour < 10){
			j <- "0" + jour;
		}
		string m <- "" + mois;
		if(mois < 10){
			m <- "0" + mois;
		}			
		return j + "/" + m + "/" + annee;
	}
	string getNomDetail{		
		return "" + mapJoursDeLaSemaine at indiceJourDeLaSemaine + " " + getNom();
	}
	
	int getNbJoursDansAnneeCourante{
		if(!isAnneeBissextile){
			return nbJoursDansUneAnneeNonBissextile;
		}else{
			return nbJoursDansUneAnneeNonBissextile + 1;
		}	
	}

	/*
	 * *****************************************************************************************
	 * La formule se base sur la date du jour zero, le 01/01/1952 est un mardi. Cela equivaut a dire que l'indiceDate 0 equivaut a l'indice jour de la semaine 2.
	 * Partant de la il suffit de faire un modulo (+1) sur l'indiceDate a chaque pas de temps en soustrayant a l'indiceDate le nombre de jour entre l'indiceDate 0 et 
	 * l'indiceDate ou on est pour la premiere fois un lundi (pour nous il y a 6 jours).
	 * ATTENTION : Ce calcul ne marche donc pas pour les 6 premiers, donc du 01/01/1952 au 06/01/1952
	 */
	action majJourDeLaSemaine{
		indiceJourDeLaSemaine <- ((indiceDate - 6) mod nbJoursDansUneSemaine) + 1;
	}
		
	/*
	 * 	*****************************************************************************************
	 * Pour un mois et un jour precise en entree, cette methode renvoi le nombre de jours ecoulee depuis le debut de l'annee (l'indiceDateDansLannee)
	 */		
	int calculNbJourEcouleDansAnnee(int jourEntree, int moisEntree){
		int resultat <- 0;
		list ligneAuMoisCourant <- (initDataDate row_at moisEntree);
		if(!isAnneeBissextile){
			resultat <- jourEntree + int(ligneAuMoisCourant at indiceColoneAnneeNonBissextile);
		}else{
			resultat <- jourEntree + int(ligneAuMoisCourant at indiceColoneAnneeBissextile);
		}		
				
		return resultat;
	}
	

	/*
	 * *****************************************************************************************
	 */
	int calculNbJourEcouleDansAnneeAlaDateCourante{
		return calculNbJourEcouleDansAnnee(jour, mois);
	}		


	/*
	 * *****************************************************************************************
	 * Renvoi le nb de jours compris entre les 2 dates donnees en entree
	 */
	int calculNbJourEcouleEntreDeuxDates {
		arg jourDebutEntree type: int default: 1;
		arg moisDebutEntree type: int default: 1;
		arg jourFinEntree type: int default: 1;
		arg moisFinEntree type: int default: 1;
									
		int indiceDateDebut <- convertirDateEnIndice(jourAConvertir:jourDebutEntree , moisAConvertir:moisDebutEntree , anneeAConvertir:annee );
		int indiceDateFin <- convertirDateEnIndice(jourAConvertir:jourFinEntree , moisAConvertir:moisFinEntree , anneeAConvertir:annee );
		
		int nbJours <- indiceDateFin - indiceDateDebut;
		
		return nbJours;	
	}

	// Nombre de jours entre la date actuelle et une date donnée (combien de jours se sont écoulés depuis le jour donné en entrée ?)
	int calculNbJour(int indiceEntree) {						
		return (indiceDate - indiceEntree);	
	}
	
	// Nombre de jours entre une date donnée et la date actuelle en jours julien (dans combien de jours a lieu le jour donné en entrée ?)
	int calculNbJour_futur(int jourEntree) {
		int difference_j <- jourEntree - nbJoursEcoulesDansAnnee;
		
		// Si indiceEntree est plus petit que nbJoursEcoulesDansAnnee, on considère que jourEntree a lieu l'année suivante
		if (difference_j < 0) {
			if (isAnneeBissextile(dateCour.annee)) {
				difference_j <- difference_j + 366;
			} else {
				difference_j <- difference_j + 365;
			}
		}
		return (difference_j);
	}
	
	int calculNbJour_passe(int jourEntree) {
		int difference_j <- nbJoursEcoulesDansAnnee - jourEntree;
		
		// Si indiceEntree est plus petit que nbJoursEcoulesDansAnnee, on considère que jourEntree a lieu l'année suivante
		if (difference_j < 0) {
			if (isAnneeBissextile(dateCour.annee - 1)) {
				difference_j <- difference_j + 366;
			} else {
				difference_j <- difference_j + 365;
			}
		}
		return (difference_j);
	}

	/*
	 * *****************************************************************************************
	 * Soit divisible par 4 mais pas par 100, ou divisible par 400
	 */
	bool isAnneeBissextile{
		arg anneeEntree type: int default: 0;
		
		bool resultat <- false;
		if((anneeEntree mod 4) = 0 and (anneeEntree mod 100) != 0 or (anneeEntree mod 400) = 0){
			resultat <- true;
		}
		isAnneeBissextile <- resultat;
		
		return resultat;
	}


	/*
	 * *****************************************************************************************
	 * Renvoi un booleen a true si la date courante est comprise entre les 2 dates donnees en entree
	 */
	bool isDateCourantEntreDeuxDates {
		arg jourDebutEntree type: int default: 1;
		arg moisDebutEntree type: int default: 1;
		arg jourFinEntree type: int default: 1;
		arg moisFinEntree type: int default: 1;
									
		int indiceDateDebut <- convertirDateEnIndice(jourAConvertir:jourDebutEntree , moisAConvertir:moisDebutEntree , anneeAConvertir:annee );
		int indiceDateFin <- convertirDateEnIndice(jourAConvertir:jourFinEntree , moisAConvertir:moisFinEntree , anneeAConvertir:annee );
		
		bool isDateCouranteEntreDeuxDatesEntree <- false;
		if(indiceDateDebut <= indiceDate and indiceDate <= indiceDateFin){
			isDateCouranteEntreDeuxDatesEntree <- true;
		}
		
		return isDateCouranteEntreDeuxDatesEntree;	
	}
			
	/*
	 * *****************************************************************************************
	 * Action qui va donner la date en fonction de l'indice incremental
	 * @Parametres : nul
	 * @Return : la date correspondant a l'indice de la date courante
	 */
	 action convertirIndiceEnDateJourCourant{
	 	idDate <- convertirIndiceEnDate(indiceDate);
		// TODO : ne pas repeter !!
		jour <- int(idDate / 1000000);		
		mois <- int(idDate / 10000) - jour * 100;
		annee <- idDate - (jour * 1000000 + mois * 10000);	
	 }
	 
	int convertirIndiceEnDate (int indiceDateEntree){
		int jourTemp <- 0;
		int moisTemp <- 0;
		int anneeTemp <- 0;
		

		int indiceColoneSiAnneeBissextileOuNon <- indiceColoneAnneeBissextile;
		int joursRestantAconvertir <- indiceDateEntree;
		
		// Calcul de l'annee
		int nombreCyclesIntercalairesEntier <- int(indiceDateEntree / (nbJoursDansUnCycleIntercalaire));
		// Dans le cas ou on est le dernier jour de l'annee bissextile (la derniere du cycle), cad que indiceDate est un multiple de 1461, alors est pas encore dans le nouveau cycle
		if((indiceDateEntree mod nbJoursDansUnCycleIntercalaire) = 0){
			nombreCyclesIntercalairesEntier <- nombreCyclesIntercalairesEntier - 1; 
		}
		anneeTemp <- anneeZero + nbAnneesDansCycleIntercalaire * nombreCyclesIntercalairesEntier;	
		joursRestantAconvertir <- joursRestantAconvertir - nombreCyclesIntercalairesEntier * nbJoursDansUnCycleIntercalaire;
		int nbAnneeAAjouter <- int(joursRestantAconvertir / nbJoursDansUneAnneeNonBissextile);
		// Dans le cas ou on est le dernier jour de l'annee non bissextile (pas la derniere du cycle), cad que joursRestantAconvertir est un multiple de 356, alors est pas encore dans la nouvelle annee
		if((joursRestantAconvertir mod nbJoursDansUneAnneeNonBissextile) = 0){
			nbAnneeAAjouter <- nbAnneeAAjouter - 1; 
		}						
			
		// la derniere annee est l'annee bissextile
		if((nbAnneeAAjouter >= 3)){
			isAnneeBissextile <- true;
			indiceColoneSiAnneeBissextileOuNon <- indiceColoneAnneeBissextile;
			nbAnneeAAjouter <- 3; // pour prendre en compte le jour deplus de l'annee bissextile
		}else{
			isAnneeBissextile <- false;
			indiceColoneSiAnneeBissextileOuNon <- indiceColoneAnneeNonBissextile;
		}
		anneeTemp <- anneeTemp + nbAnneeAAjouter;			
		joursRestantAconvertir <- joursRestantAconvertir - (nbAnneeAAjouter * nbJoursDansUneAnneeNonBissextile);		

		// Nous sommes dans l'annee courante : Calculs des jours et mois
		loop indiceLigneI from: 1 to: (length(initDataDate) - 1) {
			list ligneI <- (initDataDate row_at indiceLigneI);
			
			// Si on est pas sur la derniere ligne
			if (indiceLigneI <= 12){
				list ligneISuivante <- (initDataDate row_at (indiceLigneI + 1));
				
				// Si le nb de joursRestantAconvertir est compris entre les nombres de jours du mois lu a la ligne courante et le nb de jours du mois lu a la ligne suivante, 
				// alors le mois courant est celui lu a la ligne courante					
				if ((joursRestantAconvertir > int(ligneI at indiceColoneSiAnneeBissextileOuNon)) and (joursRestantAconvertir <= int(ligneISuivante at indiceColoneSiAnneeBissextileOuNon))){						
					moisTemp <- int(ligneI at 0);
					jourTemp <- joursRestantAconvertir - int(ligneI at indiceColoneSiAnneeBissextileOuNon);
				}					
			}	
		}
		
		return convertirJMAenDate(jourTemp, moisTemp, anneeTemp);			
	}
	
	int convertirJMAenDate (int jourEntree, int moisEntree, int anneeEntree){
		return (jourEntree * 1000000) + (moisEntree * 10000) + (anneeEntree);
	}
					
	/*
	 * *****************************************************************************************
	 * Action qui va calculer le nombre de jours entre la date de l'agent et une date initiale definie en dur a l'avance.
	 * @Parametres : jour, moi et annee
	 * @Return : l'indice correspondant a la date donnee en entree
	 */
	int convertirDateEnIndice {
		arg jourAConvertir type: int default: 1;
		arg moisAConvertir type: int default: 1;
		arg anneeAConvertir type: int default: 1;
		
		int nbAnnees <- (anneeAConvertir - anneeZero);
		int nbJoursDesMoisPrecedentsDeLAnneeCourante <- 0;
		int nbAnneeEcouleesDansCycleIntercalaire <- 0;
		list ligneAuMoisCourant <- (initDataDate row_at moisAConvertir);
		int indiceColoneSiAnneeBissextileOuNon <- indiceColoneAnneeBissextile;
					
		int indiceDateAConvertir <- 0; // mise a zero de la variable globale
		
		//Si l'annee courante n'est pas une annee bissextile (l'annee bissextile est la derniere du cycle intercalaire donc quand le modulo = 3
		if ((nbAnnees mod nbAnneesDansCycleIntercalaire) != 3){
		//if (isAnneeBissextile(nbAnnees)){							
			indiceColoneSiAnneeBissextileOuNon <- indiceColoneAnneeNonBissextile;				
		}
		indiceDateAConvertir <- int(nbAnnees / 4) * nbJoursDansUnCycleIntercalaire;
		nbAnneeEcouleesDansCycleIntercalaire <- (nbAnnees mod nbAnneesDansCycleIntercalaire);	
		nbJoursDesMoisPrecedentsDeLAnneeCourante <- int(ligneAuMoisCourant at indiceColoneSiAnneeBissextileOuNon);				
		
		// 2 - Ajout des jours correpondants aux annees entieres ecoulees dans le cycle I courant
		indiceDateAConvertir <- indiceDateAConvertir + nbAnneeEcouleesDansCycleIntercalaire * nbJoursDansUneAnneeNonBissextile;
		
		// 3 - Ajout des jours correpondants a l'intervalle entre le debut de l'annee courante et la date courante
		indiceDateAConvertir <- indiceDateAConvertir + jourAConvertir + nbJoursDesMoisPrecedentsDeLAnneeCourante;		
					
		return indiceDateAConvertir;
	}
	
	/*
	 * *****************************************************************************************
	 * @Parametres : identifiant de la date (112000 pour 01/01/2000 par exemple)
	 * @Return : l'indice correspondant a l'identifiant (un entier incremental)
	 */
	int convertirIdDateEnIndice(int idDateAConvertir <- 1) {
					
		int jourAConvertir <- int(idDateAConvertir / 1000000);
		int moisAConvertir <- int(idDateAConvertir / 10000) - jourAConvertir * 100;
		int anneeAConvertir <- idDateAConvertir - (jourAConvertir * 1000000 + moisAConvertir * 10000);
		
		int indiceDateAConvertir <- 0;
		indiceDateAConvertir <- convertirDateEnIndice(jourAConvertir:jourAConvertir, moisAConvertir:moisAConvertir, anneeAConvertir:anneeAConvertir);
		
		return indiceDateAConvertir;
	}		
	
	string toString{		
		if(not(testRegressionMode)){	
			if(afficheDateComplete){
				return "-----------------" + getNomDetail() + " (j " + nbJoursEcoulesDansAnnee + ") (" + (cycle) + ") ----------------- (" + int(world.getTempsEcouleDepuisPremierJourSimulation()) + " s)\n";					
			}else{
				return getNom() + "     " + int(world.getTempsEcouleDepuisPremierJourSimulation()) + " s";	
			}									
		} else {
			if(afficheDateComplete){
				return "-----------------" + getNomDetail() + " (" + (cycle) + ") ----------------- \n";					
			}else{
				return getNom() ;	
			}
		}
	}

	/*
	 * *****************************************************************************************
	 * Soustraction de jours sur des jours julien
	 * @Parametres : jour julien d'intérêt, nb de jours à soustraire, 
	 * @Return : résultat de la soustraction
	 * @Auteur : Renaud
	 */
	 
	 int soustractionDate(int dateEntree, int nbJoursAsoustraire) {
	 	int result <- dateEntree - nbJoursAsoustraire;
	 	if (result <= 0) {
	 		result <- 365 - abs(result);
	 	}
	 	return result;
	 }
	 
	 int additionDate(int dateEntree, int nbJoursAadditionne) {
	 	int result <- dateEntree + nbJoursAadditionne;
	 	if (result >= 366) {
	 		result <- result - 366;
	 	}
	 	return result;
	 }	 
	 
	 bool estCetteDate(int unJour, int unMois, int uneAnnee) {
	 	return (jour=unJour and mois=unMois and annee=uneAnnee);
	 }
	 
}	
