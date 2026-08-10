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

model modelDeCulture

import "../Ilots/ilot.gaml"

global{
	
	// Appellee dans la strategie de semis
	modelDeCulture creationModelDeCulture(
		species<culture> typeCulture <- culture, 
		parcelle parcelleEntree <- nil, 
		especeCultivee especeEntree <- nil,
		culture cultureEntree <- nil, 
		species<modelDeCulture> modelDeCultureEntree <- modelDeCulture
	){	
		
		modelDeCulture res <- nil;
		create modelDeCultureEntree{				
			espece <- especeEntree;
			location <- parcelleEntree.location;
			// AQYIELD				
			parcelle_app <- parcelleEntree;
			culture_app <- cultureEntree;
			do initialisationCulture();
			res <- self;						
		}	
		
		return res;		 		
	}
}

species modelDeCulture{
	especeCultivee espece <- nil;
	parcelle parcelle_app <- nil;
	culture culture_app <- nil;
	rgb couleurCoefficientCultural <- rgb('white');	
	float kc <- 0.0;  // coefficientCultural
	float kc_flo <- 0.0; // modif_feuillage
	float echV <- 0.0;  // echV  (j)  [mm]
	float transpirationMax <- 0.0; // TMj [mm]
	float indiceSatifactionHydrique <- 0.0; // TR_M // //perception par la plante de l etat hydrique du sol
	list<int> dates_incorporation_BM_senescent <- [];
	list<int> dates_incorporation_BM_racines <- [];
	float QN_acquis_cumul <- 0.0; // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC
	float meanINN10j <- 0.0; // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC et cumtureHerbSimNC
	float QN_acquis <- 0.0; // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC et cultureHerbSimNC
	float sommeDegresJourCulture_depuisSemis <- 0.0; // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC
	float QN_cumul_senescent;
	/*
	 * *****************************************************************************************
	 * Uniquement pour le modele simple de croissance de plante
	 */		
	action comportementJournalier{
	}
	action croissanceCulture{}
	action initialisationCulture{}	
	
	 float calculReserveAccessibleRacine (float RUrPrecEntree, float noteQualiteStructureSolEntree){
	 	return 0.0;
	 }
	
	bool isIrrigable{
		return false;
	}
	
	float getTranspirationR{
		return transpirationMax * indiceSatifactionHydrique;
	}
	
	
	bool isEnStressHydrique{
		return false;
	}
	float calculRendement {
		write "calculRendement modeleCulture";
		
		return 0.0;
	}
	action majPourCalculRendement{}
	action calculIndiceSatisfactionHydrique{}
	
	float getQN_fix{return 0.0;} // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC
	action calculStressN {} // NR Herbsim 18/04/2024 - redéfini dans cultureAqYieldNC
	action consommationN {} // NR Herbsim 18/04/2024  - redéfini dans cultureAqYieldNC
	action N_entrant_postrecolte(float R){} // NR Herbsim 18/04/2024  - redéfini dans cultureAqYieldNC
	action incorporation_retournement{}
	float demande_plante_w {return 0.0;} // NR Herbsim 24/04/2024  - redéfini dans cultureAqYieldNC et dans cultureHerbSimNC
	action incorporation_BM_senescent{}
	action incorporation_BM_racines{}
		
	string toString{
	 	return "" + self + " / parcelle_app = " + parcelle_app + " / espece = " + espece + " / isCultureIrrigable = " + isIrrigable();
	 }
	 
	 // Initialisation de la profondeur maximale explorable par les racine (RUr ne pourra pas dépasser cette profondeur)
	 float RUr_max_culture_courante { // Renaud 30052023
	 	// Initialisation de Hr_max -> profondeur max explorable par les racines
		float prof_sol_racines_sous_w <- max([0.0, parcelle_app.ilot_app.sol.profondeurMax - parcelle_app.ilot_app.sol.profHum]); // Profondeur de sol accessible par les racines sous l'horizon W
    

//		// Si il y a du sol sous profHum et la prof explorable par les racines est inférieure à la prof totale du sol
		if (prof_sol_racines_sous_w > 0 and parcelle_app.ilot_app.sol.profondeurMax > espece.prof_max_racines) {
			float RU_sous_w <- parcelleAqYield(parcelle_app).RUm - parcelleAqYield(parcelle_app).RUw;
			//write "Rur_max" + (parcelleAqYield(parcelle_app).RUw + RU_sous_w * ((espece.prof_max_racines - parcelle_app.ilot_app.sol.profHum) / prof_sol_racines_sous_w));
			return parcelleAqYield(parcelle_app).RUw + RU_sous_w * ((espece.prof_max_racines - parcelle_app.ilot_app.sol.profHum) / prof_sol_racines_sous_w);
		} else {
			return parcelleAqYield(parcelle_app).RUm;
		}
	 }
	 float QNacq_w { // redefini pour cultureAqYieldNC et cultureHerbSimNC NR Herbsim 16/05/2024
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
        arg QN_acquis_arg type: float default: 0.0; // Cet argument peut prendre 2 valeurs : QN_acquis ou QN_acquis_sans_mic 

        return 0.0;
    }

    float QNacq_r { // redefini pour cultureAqYieldNC et cultureHerbSimNC NR Herbsim 16/05/2024
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
	    arg QN_acquis_arg type: float default: 0.0;
        
        return 0.0;
    }
    
    action verifLevee {}
}
