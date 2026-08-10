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

model cultureSimple

import "../Ilots/ilot.gaml"

global{
	
	}

species cultureSimple  parent:modelDeCulture{

	
	float etm <- 0.0;// [m]
	float kc <- 0.0;  // coefficientCultural
	float kc_flo <- 0.0;  // coefficientCultural au moment de la floraison modif_feuillage
	float alpha <- 0.0;
	int anneeCreation <- 0;
	int nombreJourEcouleDepuisCreationCulture <- 0;	
	bool isCultureHiver <- false; 
	float frein <- 0.0; // evolue pour les cultures dhivers uniquement
	float echV <- 0.0;  // echV  (j)  [mm]
	

	//Pour l irrigation
	float ratio <- 0.0; 	// Croissance simple
	map mapCoeffAbattementRendementParJour <- map([]);	 // Croissance simple	 	
	
	/*
	 * *****************************************************************************************
	 * Uniquement pour le modele simple de croissance de plante
	 */		
	action comportementJournalier{			
		do croissanceCulture;
	}
	
	action initialisationCulture{
		anneeCreation <- dateCour.annee;
		if(dateCour.mois >= moisDebutCultureHiver or dateCour.mois <= moisFinCultureHiver){
			isCultureHiver <- true;
		}			
	}	
	
		
	bool isEnStressHydrique{	
		if(ratio < 1.0){				
			return true;
		}else{
			return false;
		}	
	}
		
	/*
	 * *****************************************************************************************
	 * MODELE SIMPLE
	 */
	 action croissanceCulture{		 	
	 	set nombreJourEcouleDepuisCreationCulture value: nombreJourEcouleDepuisCreationCulture + 1;
	 	// Le coefficient cultural est mis a jour en fonction du nombre de jours passes depuis la creation de la culture
	 	let indexDecade type: int value: int(nombreJourEcouleDepuisCreationCulture / 10);
		// Mise a jour Kc
		if (indexDecade <= (length(espece.kcParDecade) - 1)){
			set kc value: float(espece.kcParDecade at indexDecade);						
		}	
		else{
			set kc value: 0.0;
		}			
		// Mise a jour Alpha
		if (indexDecade <= (length(espece.alphaParDecade) - 1)){
			set alpha value: float(espece.alphaParDecade at indexDecade);						
		}	
		else{
			set alpha value: 0.0;
		}				
	 		 	
	 	// Besoin Plante
	 	set etm value: parcelle_app.ilot_app.meteo.etp * kc;
	 	
	 	// 1 -Echelle vegetation
	 	
	 	float tMoyVegetation <- (parcelle_app.getTmin() + min([parcelle_app.getTmax(),30.0]))/2;
	 	
		float detlaEchelleVegetation <- (max([min([tMoyVegetation, 30.0]) -espece.tbase,0.0]));				
	 	// 0 - Frein (si dans annee de semis de culture hiver ou si avant 09/02)
	 	if(		isCultureHiver 
	 		and (dateCour.nbJoursEcoulesDansAnnee <= indexDateFinFrein 
	 		or	dateCour.annee = anneeCreation)){
			frein <- frein + parcelle_app.getTmoy() * (1-espece.freinCult) / espece.degresJourAfloraisonCult;		 		
	 		detlaEchelleVegetation <- detlaEchelleVegetation * espece.freinCult;
	 	}
	 	echV <- echV + detlaEchelleVegetation;	
	 	do changementCouleurEnFonctionDebit;
	 }

/*
		 * *****************************************************************************************
		 * Cette methode va mettre a jour le coeff d'abattement pour la prevision du calcul de rendement (appelee dans parcelle)
		 */									
	action calculCoefficientAbattement(float esEntree, float rfuEntree, float hauteurEauPasDeTempsCourantEntree){	
		//3. Apport du sol
		float apportDuSol <- 0.0;
		if(esEntree > 0.0){
			apportDuSol <- 0.0;	
		}else if((esEntree + rfuEntree) > 0.0){
			apportDuSol <- -esEntree;	
		}else{
			apportDuSol <- rfuEntree;			
		}

		// 4. Ratio = stress hydrique				
		if(etm <= 0.0){
			ratio <- 1.0;
		}else{
			ratio <- min([1.0, (hauteurEauPasDeTempsCourantEntree + apportDuSol)/etm]);							
		}
		
		// 5. Coefficient d'abattement du rendement
		if(ratio > alpha){
			put 1.0 at: dateCour.indiceDate in: mapCoeffAbattementRendementParJour;					
		}else if(ratio = 0.0){
			// TODO : enlever ce cas, le ratio ne devrait pas etre nul !!!!!!
			put 0.0 at: dateCour.indiceDate in: mapCoeffAbattementRendementParJour;		
		}else{
			put (ratio / alpha) at: dateCour.indiceDate in: mapCoeffAbattementRendementParJour;
		}		
	}


	/*
	 * Appellee depuis la strat de recolte juste avant la suppression de la culture: donc on peut encore acceder aux valeurs de celles-ci
	 */
	float calculRendement {
		float rendement <- 0.0;	

		if(self.isIrrigable()){
			loop i over: mapCoeffAbattementRendementParJour.keys{
				rendement <- rendement + float(mapCoeffAbattementRendementParJour at i);
			}
			if(length(mapCoeffAbattementRendementParJour) > 0){
				rendement <- rendement / length(mapCoeffAbattementRendementParJour) * espece.rendementOptimal;
			}					
			// il faut reinitialiser la map de rendement par jour
			mapCoeffAbattementRendementParJour <- map([]);
		}else{
			rendement <- TGauss([espece.rendementMoyen,espece.rendementOptimal - espece.rendementMin]); 
		}				
		return rendement;
	}

/*
		 * Appelee depuis l'ilot, dans la methode ruissellementVersZH
		 * Elle met a jour des variables utiles pour le calcul du rendement
		 */
	action majPourCalculRendement{
		// Une fois la valeur du ruissellement calculee on peut calculer le rendement de la culture
	 	if(isIrrigable()){
	 		do calculCoefficientAbattement(esEntree: parcelle_app.ES, rfuEntree: parcelle_app.reserveFacilementUtilisable, hauteurEauPasDeTempsCourantEntree: parcelle_app.pluieEtIrrigation);
	 	}		 		
	}	


	/*
	 * *****************************************************************************************
	 */		 
	 action changementCouleurEnFonctionDebit{					
		if(kc < 0.001){
			set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at 0;
		}else{
			set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at (int(kc * 10));
		}
	 }
	 
}
