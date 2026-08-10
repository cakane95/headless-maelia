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
 *  strategieTravailSol
 *  Author: Renaud Misslin
 *  Description: Travail du sol multiple
 */

model strategieTravailSolMultiples

import "strategieTravailSol.gaml"

global{ }

species strategieTravailSolMultiples parent: strategieTravailSol {		
	strategieTravailSol strategieTravailSol_parent;
	
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		// write "bug travail du sol --> travail réalisé";
		//write "execution miseEnOeuvreActivite ---> strategieTravailSolMultiple";
		ask parc{
			// RM 290421 (copie de la modif JV 140121) de strategieTravailSol.gaml
			if parc.memoireOTsurParcelle.keys contains TRAVAIL_SOL {
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at TRAVAIL_SOL);
				float profondeur <- nil;
				if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
					profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) with_precision nb_decimales_sorties;
				}				
				map<string,string> complements <- ["prof"::string(profondeur)];
				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at TRAVAIL_SOL);												
			}
		}	
		do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
		if(verboseMode){write "TRAVAIL_SOL " + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 			
		add self to: parc.OTTravailSolMultiplesEffectuee;
		do ecritureDebugActivite(parc);										
	}
}	

