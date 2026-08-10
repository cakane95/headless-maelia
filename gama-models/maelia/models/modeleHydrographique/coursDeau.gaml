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
 *  coursDeau
 *  Author: Maroussia Vavasseur
 *  Description: Le cours deau en entree correspond au troncon principal de chaque ZH.
 */

model coursDeau

import "../modeleCommun/contourZoneMaelia.gaml"
import "equipementDeRejet.gaml"

global{
	string coursDeauShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/troncons/tronconsPrincipauxParZH.shp';
	list<ressourceEnEau> listeCoursDeau <- [];
		
	/*
	 * *****************************************************************************************
	 * Publique
	 * Creation des troncon hydro unique par zone
	 */
	action constructionCoursDeau{
		
		if !file_exists(coursDeauShape) {do raiseError("fichier inexistant: " + coursDeauShape);}
		//if !is_shape(coursDeauShape) {do raiseError("le fichier " + coursDeauShape + " n'est pas un fichier shape");}
				
		listeCoursDeau <- constructionRessourcesEnEau(typeRessource:coursDeau, cheminShp:coursDeauShape, type:SURF);
	}	
}

species coursDeau parent: ressourceEnEau{
	rgb couleurEvolutionDebitCoursDeau <- rgb('blue'); 	
	float debitCourant <- 0.0;
	map<string,list<equipementDeRejet>> mapEquipementsRejetAssocies <- map([]); 
	

	/*
	 * @Overwrite
	 */
	action complementMiseAzero{
		mapVolumeRejetReel <- map<string,float>([]);
	}

	// Accesseurs
	action ajouterEquipementDeRejet{
		arg acteur type: string default: '';
		arg equipementAajouter type: equipementDeRejet default: nil;
		
		list<equipementDeRejet> liste <- (mapEquipementsRejetAssocies at acteur);
		add equipementAajouter to: liste;
		put liste at: acteur in: mapEquipementsRejetAssocies;				
	}				
			
	float getVolumeRejetReel{
		if(!empty(mapVolumeRejetReel)){
			return float(sum(mapVolumeRejetReel.values));				
		}else{
			return 0.0;
		}
	}
	/*
	 * @Overwrite
	 */
	float getVolumeUtileApresPrelevementEtRejet{
		return float(volumeUtileAvantPrelevementEtRejet - getVolumePreleveReel() + getVolumeRejetReel());
	}
	
	/*
	 * *****************************************************************************************
	 * Il ny a des rejets que pour lAEP et lIND, uniquement en SURF ou CANAUX
	 */	
	action calculRejetsReels{	
		// AEP = Une fois le prelevement reel mise a jour (depuis la conso des communes)		
		// IND = Une fois le prelevement reel mise a jour dans lequipement de captage associe, on peut caluler le volume rejette
		//write "debut calculRejetsReels sur coursDeau " + id + "nbequipementsRejet=" + length(mapEquipementsRejetAssocies); // JV debug
		//write "mapVolumeRejetReel:" + mapVolumeRejetReel; // JV debug
		list<equipementDeRejet> liste <- interleave(mapEquipementsRejetAssocies.values) as list<equipementDeRejet>;																
		ask liste{
			//write "\tappel miseAJourVolumeReel sur " + idEquipement + " acteur " + acteurAssocie; // JV debug
			do miseAJourVolumeReel();
		}
		//write "mapVolumeRejetReel:" + mapVolumeRejetReel; // JV debug
		//write "fin calculRejetsReels"; // JV debug
	}

	/*
	 * *****************************************************************************************
	 */
	aspect evolutionDebitCoursDeauAspect{
		draw shape color: couleurEvolutionDebitCoursDeau size: 5000;
	}		
}
