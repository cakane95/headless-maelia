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

model strategieBinageSol

import "Ilots/ilot.gaml"

global{ }

species strategieBinageSol parent: strategieOT{			
	/*
	 * *****************************************************************************************
	 * TODO : attention, il faut bien que ca se fasse avant la culture prevue, pas apres
	 */		
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle != nil){
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				estOk <- 	isEchelleVegetationOK(parcelleEntree,deltaTemporel) 
							and isHumiditeSolOK(parcelleEntree,deltaTemporel)
							and !parcelleEntree.isBinagesSolEffectue;								
//					write toString(parcelleEntree) + " - estOk = " + estOk;					
			}				
		}

		return estOk;
	}	
	
	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains BINAGE_SOL {				 
			ask parc{
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at BINAGE_SOL);
				float profondeur <- nil;
				if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
					profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) with_precision nb_decimales_sorties;
				}		
				map<string,string> complements <- ["prof"::string(profondeur)];
				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at BINAGE_SOL);								
			}
		}	
		do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
		parc.isBinagesSolEffectue <- true;
		if(verboseMode){write "BINAGE_SOL " + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 					
		do ecritureDebugActivite(parc);																			
	}
}	

