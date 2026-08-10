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
 *  parcelleAqYield
 *  Author: Romain Lardy
 *  Description: Les parcelles ETP représente un réservoir simplement gérer selon un bilan simple de type P - ETP
 */

model parcelleETP

import "../Cultures/culture.gaml"
import "../../modeleCommun/zoneMeteo.gaml" 
import "../Cultures/modelDeCulture.gaml"
 
global {	
	
	/* 
	 * *****************************************************************************************
	 * Private
	 */
	action constructionParcellesETP{
		listeParcelles <- lectureFichierParcelle(cheminEntree:parcellesShape, typeParcelle:parcelleETP);
	}				
} 


species parcelleETP parent: parcelle {
	float RU <- 0.0;
		
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Appellee depuis ilot
	 */			
	action remiseAzeroParcelle{
		irrigationSouhaitee <- 0.0;
		irrigationReelle <- 0.0;
		
		// Remise a zero les variables daffichage
		etatIrrigationParcelle <- ETAT_PAS_IRRIGATION_DEMANDEE;
		
	}

	action initialisationDonneesSol {
		// La parcelle a besoin de connaitre quelques attributs du type de sol de l'ilot.	
		RU <- ilot_app.sol.reservePotentielleUtileMax;		
	}
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort en surface apres la croissance de la plante
	 */
	float calculQuantiteEauDeRuissellement{
		ask cultureParcelle{
			ask monModelDeCulture{
				do croissanceCulture();	
			}
		}
		return 0.0;
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEvapoTranspiration{		
	 	// 1 -Evaporation
	 	float deltaJour <- getPluie() - ilot_app.meteo.etp;
	 	//float RUmax <- ilot_app.sol.reservePotentielleUtileMax;
		//RUr	 			 	
							 	
		return max([0.0, min([ilot_app.meteo.etp, RU + deltaJour])]); // [m]
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEcoulementEauSouterraine{		
	 	// 4 -Calcul du drain -> bilan hydrique
	 	float deltaJour <- getPluie() - ilot_app.meteo.etp;
	 	drain <- max([0.0, RU +deltaJour - ilot_app.sol.reservePotentielleUtileMax]);	
		RU <- max([0.0, RU +deltaJour - drain]);
		return drain; // [mm]
	}

		
		
}
