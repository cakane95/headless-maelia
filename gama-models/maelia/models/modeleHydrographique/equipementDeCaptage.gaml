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
 *  equipementDeCaptage
 *  Author: Maroussia Vavasseur
 *  Description: Tous les points de prelevements, qu'ils soient industriel (IND), agricole (IRR) ou pour les collectivites (AEP)
 */

model equipementDeCaptage

import "ressourceEnEau.gaml"
 
global {
	string imagePrelevement <- cheminRacineMaelia + 'images/prelevement.png' ;
	map<string,list<equipementDeCaptage>> mapEquipementsDeCaptage <- map([]);
}

species equipementDeCaptage parent: equipement{	
				
			
	/*
	 * @Overwrite
	 */		
	action initialisationEquipement{	

		list<ressourceEnEau> listeRes <- (mapRessourcesEnEau at natureRessourcePrelevee);				
		ressourceAssociee <- first(listeRes where (each.id = idRessourceEnEauAssociee));
		
		if(ressourceAssociee != nil){
			ask ressourceAssociee{
				do ajouterEquipementDeCaptage acteur: myself.acteurAssocie equipementAajouter: myself;				 				 	
			}
			
			list<equipementDeCaptage> listeTemp <- mapEquipementsDeCaptage at acteurAssocie;
			add self to: listeTemp;
			put listeTemp at: acteurAssocie in: mapEquipementsDeCaptage;
			name <- idEquipement;							
		}else{
			if (!executerModeleSurUneZH){
				write idEquipement + " - ATTENTION RESSOURCE NULLE  ! " + idRessourceEnEauAssociee; //(normale si pas sur toute la zone)
			}
		}				
	}

	/*
	 * *****************************************************************************************
	 */
	action miseAJourVolumeSouhaite{	
		arg volumeApreleverEntree type: float default: 0.0;
				
		float volumeSouhaite <- getVolumeSouhaite();

		ask ressourceAssociee{								
			do setMapVolumePreleveSouhaite acteur:  myself.acteurAssocie valeur: volumeSouhaite;				
		}	
	}

	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
		
		volumeReel <- getVolumeSouhaite() * pourcentage;
		
		ask ressourceAssociee{								
			do setMapVolumePreleveReel acteur:  myself.acteurAssocie valeur: myself.volumeReel;				
		}				
	}
	
	/*
	 * *****************************************************************************************
	 * @Overwrite 
	 */
	float getVolumeReel{
		return volumeReel;
	}		
	float getVolume{
		arg type type: string default: SOUHAITE;			
		if(type = SOUHAITE){
			return getVolumeSouhaite();
		}else if(type = REEL){
			return volumeReel;
		}	
	}
		

	/*
	 * *****************************************************************************************
	 */				
	aspect imageAspect{
		draw imagePrelevement size: taillePoints;
	}	
	
	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- "[EQU_CAPT] " + name; 
		resultat <- resultat + ' / idEquipement  : ' + idEquipement;
		resultat <- resultat + ' / natureRessourcePrelevee : ' + natureRessourcePrelevee;	
		resultat <- resultat + ' / acteurAssocie : ' + acteurAssocie;
		resultat <- resultat + ' / volumeReel : ' + volumeReel;	 
		resultat <- resultat + ' / volumeSouhaite : ' + getVolumeSouhaite();	 			
		return resultat;			 			
		}
}
