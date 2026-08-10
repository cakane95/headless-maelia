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
 *  strategieBinage
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model strategieFerti

import "Ilots/ilot.gaml"

global{}

species strategieFerti parent: strategieOT{	

	float doseParHectare <- 0.0; // kg par Hectare --> pour les engrais miénraux, il s'ahit de la dose de N par Ha.
	float dosePParHectare <- 0.0; // kg par Hectare
	float doseKParHectare <- 0.0; // kg par Hectare
	
	map<int,float> mapFenetreEchvDebut <- map<int,float>([]); //    IRRIGATION FERTI
	map<int,float> mapFenetreEchvFin <- map<int,float>([]); //    IRRIGATION FERTI
	list<strategieFertiAlternative> mesStrategiesFertiAlternative <- nil;
	
	// Ici il faut donc ecrire une nouvelle methode pour savoir si la periode dirrigation est possible, car la methode generique se base sur lindice de la sous periode qui est ici donnee par lechelle de vegetation
 	bool isFenetreTemporelleGlobaleOk(int deltaTemporel) {	 		
 		if(fenetreTempOkLocal(jourC:(dateCour.nbJoursEcoulesDansAnnee- deltaTemporel), jourJulienFenetreMin:(mapFenetresTemporellesDebut at 0), jourJulienFenetreMax:(mapFenetresTemporellesFin at 0))){
 			return true;
 		}else{	 				
 			return false;
 		}
 	}
 		
	// Redéfinition de la fonction getIndiceSousPeriode pour réaliser une opération de ferti par sous-période
	int getIndiceSousPeriode(parcelle parcelleEntree, int deltaTemporel){
		int indiceCourant <- -1;
		if((mapFenetreEchvDebut at 0) != NA){
			if(parcelleEntree != nil){
				loop indice over: mapFenetreEchvDebut.keys{
					if(parcelleEntree.getEchelleVegetation() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionVegetation >= (mapFenetreEchvDebut at indice) and parcelleEntree.getEchelleVegetation() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionVegetation < (mapFenetreEchvFin at indice)){
						indiceCourant <- indice;
					}
				}
			}				
		}else{
			indiceCourant <- 0;
		}			
		return indiceCourant;
	}	
					
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){ //1 ferti par periode
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle != nil){
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel) and isFenetreTemporelleGlobaleOk(deltaTemporel)){
				// JV 101224 suppression condition isHumiditeSolOK (cf issue #6)
				estOk <- 	isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel)
							and !isDejaFait(parcelleEntree,deltaTemporel);
							
							//write "isCumuleHauteurPluieOK = " + isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel);
							//write "!isDejaFait = " + !isDejaFait(parcelleEntree,deltaTemporel);
			}
		}
		
		return estOk;
	}
	
		
	bool isDejaFait(parcelle parcelleEntree,int deltaTemporel){
		if(parcelleEntree.isFertiDeLaPeriodeEffectue at getIndiceSousPeriode(parcelleEntree, deltaTemporel) != nil){
			return parcelleEntree.isFertiDeLaPeriodeEffectue at getIndiceSousPeriode(parcelleEntree, deltaTemporel);				
		}else{
			return false;
		}			
	}	
	
	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){	
		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains FERTI {				 		
			ask parc{
				put getITKAnnee() at:dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at FERTI);
			}
		}
		put true at: getIndiceSousPeriode(parc, agri.nbJoursDeDecalageActivite) in: parc.isFertiDeLaPeriodeEffectue;				
		do ecritureDebugActivite(parc);																			
	}
}	

