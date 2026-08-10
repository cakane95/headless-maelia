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

model culture

import "cultureSimple.gaml"
import "cultureAqYield.gaml"
import "cultureHerbSimNC.gaml"

global{
	list<culture> listeCultures <- [];	
	
	// Appellee dans la strategie de semis
	culture creationCulture(species<culture> typeCulture <- culture, parcelle parcelleEntree <- nil, especeCultivee especeEntree <- nil){	
			
		int indexDateCreationTemp <- 0;
		ask dateCour{
			indexDateCreationTemp <- calculNbJourEcouleDansAnneeAlaDateCourante();
		}	
					
		culture res <- nil;
		create typeCulture{	// typeCulture: culture ou cultureIrrigable			
			espece <- especeEntree;
			parcelleEntree.cultureParcelle <-  self ;
			location <- parcelleEntree.location;
			indexDateDeCreation <- indexDateCreationTemp;
			// AQYIELD				
			parcelle_app <- parcelleEntree;
					
			listeCultures << self;			
			res <- self;						
		}	
		//species typeModelVeg <- ModelDeCulture;
		//Filtre en fonction de typeCulture ?
		switch nomChoixModeleCroissancePlante{
			match 'Simple' {
                res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, especeEntree, res, cultureSimple);                       
            }
            match 'AqYield' {
            	if((especeEntree.isEspeceHerbSim) and (nomChoixModeleCroissancePrairie="HerbSim")){
					res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, especeEntree, res, cultureHerbSim);
				}
				else{
					res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, especeEntree, res, cultureAqYield);                       
				}
            }
            match 'AqYieldNC' {
            	if((especeEntree.isEspeceHerbSim) and (nomChoixModeleCroissancePrairie="HerbSimNC")){
            		especeCultivee copie_especeHerbsim <- constructionEspeceHerbSimConcrete(especeEntree.idEspeceCultivee);
					res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, copie_especeHerbsim, res, cultureHerbSimNC);                       
				}
				else{
					res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, especeEntree, res, cultureAqYieldNC);                       
				}
            }
			default {
                res.monModelDeCulture <- creationModelDeCulture(typeCulture,parcelleEntree, especeEntree, res, modelDeCulture);
            }
		}
		return res;		 		
	}
}

species culture{
	especeCultivee espece <- nil;
	parcelle parcelle_app <- nil;
	int indexDateDeCreation <- 0; // index du jour dans l'annee
	modelDeCulture monModelDeCulture <- nil;
	int age_culture <- 0; // Age du couvert en nb de jours
	int anneeSemis <- 0; // JV 020622: annee du semis, nécessaire pour déclencher la récolte des cultures biannuelles (cf Mantis #2905)
	float risqueEchaudage <- 0.0; // % nJoursEchaudants / nJoursRemplissageGrain
	/*
	reflex majAgeCulture {
		age_culture <- age_culture + 1;
	}
	 */
	 
	/*
	 * *****************************************************************************************
	 * Uniquement pour le modele simple de croissance de plante
	 */		
	action comportementJournalier{
		ask monModelDeCulture{
			do comportementJournalier();	
		}

	}
		
	bool isIrrigable{
		return false;
	}
			 
	 string toString{
	 	return "" + self + " / parcelle_app = " + parcelle_app + " / espece = " + espece + " / isCultureIrrigable = " + isIrrigable();
	 }
}
