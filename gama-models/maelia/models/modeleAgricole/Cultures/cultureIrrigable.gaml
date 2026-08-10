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
 *  cultureIrrigable
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model cultureIrrigable

import "../Parcelles/parcelle.gaml" 
	
species cultureIrrigable parent: culture{
	int dernierTourEau <- 0;	// Irrigation basique		   
			
	/*
	 * *****************************************************************************************
	 */		
	action majDerniereIrrigation{
		if(nomChoixModeleIrrigation = GROUPE_IRRIGATION){ 
			ask(parcelle_app.listeGroupeIrrigationCulture){
				do miseAjourMapDerniereIrrigation();
			}
		}else{
			do miseAjourNbJoursDernierTourEauBasique();
		}			
	}

	/*
	 * *****************************************************************************************
	 * Retourne vrai si au moins une portion de la parcelle peut etre irriguee dans au moins un groupe
	 */	
	action miseAjourNbJoursDernierTourEauBasique{			
		dernierTourEau <- max([0, dernierTourEau - 1]);	
	}		
	/*
	 * *****************************************************************************************
	 */	
	bool isIrrigable{
		return true;
	}
	float getSurfaceIrrigueeJourCourant{
		float resultat <- 0.0;
		ask(parcelle_app.listeGroupeIrrigationCulture){
			resultat <- resultat + float(getSurfaceIrrigueeJourCourant());
		}		
		return resultat;
	}
	bool isEnStressHydrique{
		return monModelDeCulture.isEnStressHydrique();
	}


}
