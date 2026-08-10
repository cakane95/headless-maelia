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
 *  equipementDeRejet
 *  Author: Maroussia Vavasseur
 *  Description: Tous les points de rejets, qu'ils soient industriel (IND), ou pour les collectivites (AEP).
 *				 Les agruculteurs n'ont pas de point de rejet.
 */

model equipementDeRejet

import "ressourceEnEau.gaml"

global {
	map<string,list<equipement>> mapEquipementsDeRejet <- map([]);
}

species equipementDeRejet parent: equipement{
	float rapportPrelevement <- 0.0; // le rapport entre le prelevement et les rejets
	
	/*
	 * @Overwrite
	 */		
	action initialisationEquipement{
		list<ressourceEnEau> listeRes <- (mapRessourcesEnEau at natureRessourcePrelevee);				
		ressourceAssociee <- first(listeRes where (each.id = idRessourceEnEauAssociee));
		
		if(ressourceAssociee != nil){
			ask (ressourceAssociee){
				do ajouterEquipementDeRejet acteur: myself.acteurAssocie equipementAajouter: myself;				 				 	
			}
			list<equipementDeRejet> listeTemp <- (mapEquipementsDeRejet at acteurAssocie) as list<equipementDeRejet>;
			add equipementDeRejet(self) to: listeTemp;
			put listeTemp at: acteurAssocie in: mapEquipementsDeRejet;
			name <- idEquipement;						
		}			
	}
		
	/*
	 * *****************************************************************************************
	 * @Overwrite  
	 */
	float getVolumeReel{
		return  tauxSurZM * (mapVolumeConsommeReelJourPrecedent_ZM at acteurAssocie) * (1 - rapportPrelevement);
	}	

	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
		
		volumeReel <- getVolumeReel();
		//write "\t\tvolumeReel=" + volumeReel; // JV debug
		 
		ask (ressourceAssociee ) {								
			do setMapVolumeRejetReel acteur:  myself.acteurAssocie valeur: myself.volumeReel;				
		}				
	}
}
