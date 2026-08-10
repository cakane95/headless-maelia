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
 *  culture
 *  Author: Maroussia Vavasseur
 *  Description: La culture est une entite qui ne va exister qu'entre le jour de son semi et celui de sa recolte. Elle est semee sur une parcelle.
 */

model cultureAqYield

import "../ITKs/itk.gaml"
import "../StressClimatique/echaudage.gaml"

global{
	
	}

species cultureAqYield  parent:modelDeCulture{
	
	int anneeCreation <- 0;

	bool isCultureHiver <- false; 
	float frein <- 0.0; // evolue pour les cultures dhivers uniquement
			
	
	float sommeTranspirationR <- 0.0; //[mm]
	float sommeTranspirationMax <- 0.0; //[mm]

	
	float sommeDegresJourCulture <- 0.0; // Somme des degres jour utilisée dans le module Azote
	float sommeDegresJourCulturePrec <- 0.0;
	
	float dKc_save; // Enregistrement du dKc pour comparaison AqYield Excel / Maelia
	
	int date_semis <- 0; //julian day
	
	int nJoursEchaudants <- 0; // nb de jours
	int nJoursRemplissageGrain <- 0; // nb de jours
	float risqueEchaudage <- 0.0; // % nJoursEchaudants / nJoursRemplissageGrain
	float partDestructionGel <- 0.0; // %
	
	/*
	 * *****************************************************************************************
	 * Uniquement pour le modele simple de croissance de plante
	 */		
	action comportementJournalier{			
//			do croissanceCulture;		
	}
		
	action initialisationCulture{		
		anneeCreation <- dateCour.annee;
		if(dateCour.mois >= moisDebutCultureHiver or dateCour.mois <= moisFinCultureHiver){
			isCultureHiver <- true;
		}			
		date_semis <- dateCour.calculNbJourEcouleDansAnnee(dateCour.jour, dateCour.mois);
		
		// Calcul de la profondeur maximale pouvant être atteinte par les racine pour la culture courante
		parcelleAqYield(parcelle_app).RUr_max <- RUr_max_culture_courante(); // Renaud 30052023
	}	
	 
	 float calculReserveAccessibleRacine{	
	 	arg RUrPrecEntree type: float default: 0.0;	
	 	arg noteQualiteStructureSolEntree type: float default: 0.0;
	 	
		// 2 -RUr (reserve utile accessible aux racines)
		float RUr <- 0.0;
		if(echV < espece.echelleVegetationStadeFloraison){ // avant floraison // Modifié Renaud 01/06/18 avec Hélène : passage de "<=" à "<" pour coller à AqYield
			RUr <- echV * espece.degresJourAfloraisonCult / (espece.croissanceRacineCult/noteQualiteStructureSolEntree); //  * 7.5
		}else{
			RUr <- RUrPrecEntree + 0.5 * parcelle_app.getTmoy() / (espece.croissanceRacineCult/noteQualiteStructureSolEntree);
		}
		
		return RUr;			
	 }

	/*
	 * *****************************************************************************************
	 * MODELE AQYIELD
	 * Appelee dans parcelle
	 */		 
	 // JV 290920 code croissanceCulture entierement reprise de la version de Renaud sous GAMA 1.7
	 action croissanceCulture{

	 	// 1. Calcul de la somme de degrés jour
	 	sommeDegresJourCulturePrec <- sommeDegresJourCulture; // 27/06/18 : Probablement à supprimer 
	 	float DegresJourCulture <- min([espece.tmax, parcelle_app.getTmoy()]);
	 	DegresJourCulture <- max([0, DegresJourCulture - espece.tbase]);
	 	sommeDegresJourCulture <- sommeDegresJourCulture + DegresJourCulture;
	 	
	 	// 2. Echelle vegetation
		float detlaEchelleVegetation <- (max([min([parcelle_app.getTmoy(), espece.tmax]) - espece.tbase, 0.0]) / espece.degresJourAfloraisonCult);				
	 	
	 	// 3. Frein (si dans annee de semis de culture hiver ou si date courante est supérieure à la date de début de frein et inférieure à la date de fin de frein)
		if(isCultureHiver and ((dateCour.annee = anneeCreation and dateCour.nbJoursEcoulesDansAnnee >= indexDateDebutFrein) or (dateCour.annee != anneeCreation and dateCour.nbJoursEcoulesDansAnnee <= indexDateFinFrein))){
			// frein <- frein + detlaEchelleVegetation * (1-espece.freinCult) ; // Modifié Renaud (Rdv Hélène 03/04/18) --> Le frein n'a pas besoin d'être calculé, son effet est donné par espece.freinCult
	 		detlaEchelleVegetation <- detlaEchelleVegetation * espece.freinCult; // Le frein est utilisé ici une première fois modif_frein
	 		//if verboseMode {write "frein " + espece.idEspeceCultivee + " OUI";} // JV debug
	 	}//else{if verboseMode {write "frein " + espece.idEspeceCultivee + " NON";}} // JV debug
	 	
	 	echV <- echV + detlaEchelleVegetation; //modif_feuillage
	 	if(echV >= 1 and kc_flo = 0.0){
	 		kc_flo <- kc;
	 	}
	 	
		// 4. Coefficient cultural	
		
		
		// Calcul du coefficient cultural (dKcMax)
		float lj <- dateCour.longueurDuJour;
		float coefTemp <- 1000.0;
		float dKcMax <- (parcelle_app.getTmoy() / coefTemp) * (lj*3) * indiceSatifactionHydrique * (espece.coefCulturalMax - kc);
		float dKc <- 0.0;
		// Référence doc : modif_frein
		// Ancienne version	
		//		if((echV+frein < espece.echelleVegetationStadeLevee)){
		//			dKc <- 0.0;
		//		}else if((echV+frein >= espece.echelleVegetationStadeLevee) and (echV+frein <= espece.echelleVegetationStadeFloraison)){
		//			dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (lj*3) * indiceSatifactionHydrique * espece.coefVigueurVegetativeCult * ((echV+frein)^1.5)]);						
		//		}else{
		//			dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (- 2)*(((echV+frein-1)/(espece.echelleVegetationStadeMaturite-1))^2.5)]);								
		//		}
		//		
		//		if(echV+frein >= espece.echelleVegetationStadeLevee){
		//			kc <- min([espece.coefCulturalMax, kc + dKc]);
		//			kc <- max([0.0, kc]);
		//		}else{
		//			kc <- 0.0;
		//		}
		
		// Modifié Renaud (Rdv Hélène 03/04/18) --> Le frein est utilisé deux fois, on enlève donc son effet sur echV ici
		if ((echV < espece.echelleVegetationStadeLevee or parcelle_app.getTmoy() <= espece.tbase)){
			dKc <- 0.0;
		} else if ((echV >= espece.echelleVegetationStadeLevee) and (echV <= espece.echelleVegetationStadeFloraison)){
			dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (lj*3) * indiceSatifactionHydrique * espece.coefVigueurVegetativeCult * (echV^1.5)]);
			dKc <- max([0.0, dKc]);
		} else if ((echV > espece.echelleVegetationStadeFloraison) and (kc > 0)) {
			dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (- 2)*(((echV-1)/(espece.echelleVegetationStadeMaturite-1))^2.5)]);
		} else {
			dKc <- 0.0;
		}

		if (echV >= espece.echelleVegetationStadeLevee){
			kc <- min([espece.coefCulturalMax, kc + dKc]);
			kc <- max([0.0, kc]);
		} else {
			kc <- 0.0;
			sommeDegresJourCulture <- 0.0; // Bon endroit pour remettre à 0 ?? Ca marche, mais est-ce le bon endroit ??
			kc_flo <- 0.0; //modif_feuillage --> à vérifier qu'il est bien réinitialisé au bon endroit			
		}
		
		dKc_save <- dKc;
		
		if (avecStressClimatique) {
			do calculJourEchaudant;
			do destructionGel;
		}
		do changementCouleurEnFonctionKc();
	 }
	 action calculIndiceSatisfactionHydrique{
	 	// JV 221019 add a test on RUrPrec=RUsPrec to avoid division by zero that may occur in some (rare) cases. (see Mantig bug #0002361)
	 	if(parcelleAqYield(parcelle_app).RUrPrec = parcelleAqYield(parcelle_app).RUsPrec){
	 		indiceSatifactionHydrique <- max([0.0, 1 - abs(1-(parcelleAqYield(parcelle_app).Hs)/(parcelleAqYield(parcelle_app).RUsPrec))^(parcelleAqYield(parcelle_app).ilot_app.sol.ctr_m * ((espece.coefFermetureStomatesCult) ^ parcelleAqYield(parcelle_app).getEchelleVegetation()))]);
	 	}
	 	else{
	 	indiceSatifactionHydrique <- max([0.0, 1 - abs(1-(parcelleAqYield(parcelle_app).Hr-parcelleAqYield(parcelle_app).Hs) 
	 			/ (parcelleAqYield(parcelle_app).RUrPrec - parcelleAqYield(parcelle_app).RUsPrec)
	 			) ^ (parcelleAqYield(parcelle_app).ilot_app.sol.ctr_m * ((espece.coefFermetureStomatesCult) ^ parcelleAqYield(parcelle_app).getEchelleVegetation()))]);					
		}
		//write "indiceSatifactionHydrique=" + indiceSatifactionHydrique;
	 }
	 
	 bool isEnStressHydrique{	
		if(echV < 0.9){				
			if(indiceSatifactionHydrique < (0.5 * parcelle_app.getITKAnnee().strategieIrrigationITK.sirr1)){
				return true;
			}
		}else if(echV >= 0.9 and echV < 1.3){
			if(indiceSatifactionHydrique < (0.5 * parcelle_app.getITKAnnee().strategieIrrigationITK.sirr2)){
				return true;
			}
		}else if(echV >= 1.3){
			if(indiceSatifactionHydrique < (0.5 * parcelle_app.getITKAnnee().strategieIrrigationITK.sirr3)){
				return true;
			}
		}			
		return false;
	}
	 
	 
	 /*
	 * *****************************************************************************************
	 */		 
	 float calculRendement{
	 	if (avecStressClimatique and espece.degresJourDebutRemplissage > 0 and nJoursRemplissageGrain > 0) {
	 		write "espece = " + espece.idEspeceCultivee;
	 		risqueEchaudage <- nJoursEchaudants / nJoursRemplissageGrain * 100;
	 	}
	 	
	 	float rendement <- 0.0;
	 	if(sommeTranspirationMax > 0.0 ){
		 	float satisH <- sommeTranspirationR / sommeTranspirationMax;
		 	float a <- espece.coeff_Fonction_Prod; //3.0 //Coefficient de la fonction de production // TODO : lire data fichier entree
		 	float rendementPotentiel <- espece.rendementOptimal;
		 	float effetStressHydriqueSurRendement <- max([0.1, 1 - min([1.0,a*((1-satisH)^2)])]);
		 	rendement <- effetStressHydriqueSurRendement * rendementPotentiel;
		 	
			sommeTranspirationR  <- 0.0; 
			sommeTranspirationMax <- 0.0; 			
	 	}
	 	
		return rendement;
	 }
	 
	 /*
	 * *****************************************************************************************
	 * 
	 */
	action majPourCalculRendement{
		// 1.75 correspond au seuil de maturité à partir duquel on considère que le rendement ne
		// sera plus impacté par le climat (sauf éventuellement par le "rendemen_malus"). On arrete
		// donc le calcul de la somme d' ETR et d'ETM
		if (parcelle_app.getEchelleVegetation() < espece.echelleVegetationStadeMaturite){ 
			sommeTranspirationR  <- sommeTranspirationR + parcelleAqYield(parcelle_app).transpirationR; 
			sommeTranspirationMax <- sommeTranspirationMax + transpirationMax; 
			
		}
	 }
	 
	 
	 float getTranspirationR{
		if(echV < espece.echelleVegetationStadeMaturite){
			return transpirationMax * indiceSatifactionHydrique;
		}else{
			return 0.0;
		}
	}

	// TODO Renaud 160724 -> pourquoi isJourEchaudant déclaré dans global de echaudage n'est pas reconnu ici ????
	// Est-ce que le jour courant est un jour échaudant ? (utilisée dans une action de cultureAqYield.gaml)
	bool isJourEchaudant (float tempJ, float tempMaxCulture) {
		bool result <- false;
		// Est-ce que la température du jour est trop élevée ?
		if (tempJ > tempMaxCulture) {
			result <- true;
		}
		return result;
	}
	
	// Est-ce qu'on est dans la période durant laquelle la plante est sensible à l'échaudage ?
	bool isPeriodeRemplissage (float cumulDegresJour, float gddDebutRemplissage, float gddMaturite) {
		bool result <- false;
//		write "test remplissage";
//		write "gddRemplissage = " + gddDebutRemplissage;
//		write "cumulDegresJour = " + cumulDegresJour;
//		write "gddMaturite = " + gddMaturite;
		if (cumulDegresJour >= gddDebutRemplissage and cumulDegresJour < gddMaturite) {
			result <- true;
		}
		return result;
	}
	
	// Détermine si on est dans un jour échaudant pour la plante ou non : Action executée dans croissanceCulture de cultureAqYield et cultureAqYieldNC
	action calculJourEchaudant {
		bool jourCourantEchaudant <- false;
		if (espece.degresJourDebutRemplissage > 0) {
			if (isPeriodeRemplissage(sommeDegresJourCulture, espece.degresJourDebutRemplissage, espece.degresJourMaturiteCult)) {
				nJoursRemplissageGrain <- nJoursRemplissageGrain + 1;
				if (isJourEchaudant(parcelle_app.getTmax(), espece.tmax)) {
					nJoursEchaudants <- nJoursEchaudants + 1;
				}
			}
		}
	}
	
	// Détermine le stade phénologique en cours
	string stadePheno (float gddCumul, float gddLevee, float gddJuvenile, float gddDebutFlo, float gddFinFlo) {
		string stade_pheno <- "";
		if (gddCumul < gddLevee) {
			stade_pheno <- "plantule";
		} else if (gddCumul >= gddLevee and gddCumul < gddJuvenile) {
			stade_pheno <- "juvenile";
		} else if (gddCumul >= gddJuvenile and gddCumul < gddDebutFlo) {
			stade_pheno <- "adulte";
		} else if (gddCumul >= gddDebutFlo and gddCumul < gddFinFlo) {
			stade_pheno <- "floraison";
		}
//		write "stade = " + stade_pheno;
		return stade_pheno;
	}
	
	// Calcul d'impact du gel
	float calculImpactGel (float tJ, float t10, float t90) {
		float result <- 0.0;
		if (t10 != 0 and t90 != 0) { // Utilisé pour savoir si c'est une culture sensible au gel ou pas mais à changer car 0 peut être une vraie valeur ?
//			write "temperature = " + tJ;
			if (tJ <= t10 and tJ > t90) {
//				write "t10 = " + t10;
//				write "t90 = " + t90;
				result <- (90-10)*((tJ-t10)/(t90-t10))+10;
//				write 'entre t10 et t90';
			} else if (tJ <= t90) {
//				write "t10 = " + t10;
//				write "t90 = " + t90;
//				write 'inferieure à t90';
				result <- 100.0; // Destruction totale
			}
		}
		return result;
	}
	
	// Détermine la part de destruction 
	action destructionGel {
		string stade <- stadePheno(sommeDegresJourCulture, espece.degresJourLeveeCult, espece.degresJourStadeJuvenile, espece.degresJourAfloraisonCult, espece.degresJourDebutRemplissage);
		float impactGel <- 0.0;
		
//		write "cumul temp = " + sommeDegresJourCulture;
//		write "plantule = " + espece.degresJourLeveeCult;
//		write "juvenile = " + espece.degresJourStadeJuvenile;
//		write "adulte = " + espece.degresJourAfloraisonCult;
//		write "floraison = " + espece.degresJourDebutRemplissage;
		
		switch stade {
			match "plantule" {
				impactGel <- calculImpactGel(parcelle_app.getTmin(), espece.tgelLev10, espece.tgelLev90);
//				write "plantule impact = " + impactGel;
			}
			match "juvenile" {
				impactGel <- calculImpactGel(parcelle_app.getTmin(), espece.tgelJuv10, espece.tgelJuv90);
//				write "juvenile impact = " + impactGel;
			}
			match "adulte" {
				impactGel <- calculImpactGel(parcelle_app.getTmin(), espece.tgelVeg10, espece.tgelVeg90);
//				write "adulte impact = " + impactGel;
			}
			match "floraison" {
				impactGel <- calculImpactGel(parcelle_app.getTmin(), espece.tgelFlo10, espece.tgelFlo90);
//				write "floraison impact = " + impactGel;
			}
		}
		
		partDestructionGel <- max([impactGel, partDestructionGel]);
	}
	
	/*
	 * *****************************************************************************************
	 */		 
	 action changementCouleurEnFonctionKc{					
		if(kc < 0.001){
			set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at 0;
		}else{
			set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at (int(kc * 10));
		}
	 }
	 
	 action incorporation_BM_senescent{}
}
