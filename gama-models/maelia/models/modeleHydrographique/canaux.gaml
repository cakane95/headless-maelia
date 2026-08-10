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
 *  RetenuesCollinaires
 *  Author: Romain Lardy
 *  Description: 
 *  */

model canaux

import "../modeleCommun/contourZoneMaelia.gaml"
 
global{	
	string canauxShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/canaux/canaux.shp';
	list<ressourceEnEau> listeCanaux <- [];
	map<string, canal> mapCanaux <- map([]);
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionCanaux{
		listeCanaux <- constructionRessourcesEnEau(typeRessource:canal, cheminShp:canauxShape, type:CAN);
		ask listeCanaux{
			put self as canal at: id in: mapCanaux;
		}
	}

}


species canal parent: ressourceEnEau{
	map<string,list<equipementDeRejet>> mapEquipementsRejetAssocies <- map([]); 
	list<equipementDeCaptageCanaux> listEquipementAlimentantCeCanal <- [];
	list<equipementDeRejetCAN> listEquipementSortieCanal <- [];
	secteurAdministratif secteurAdministratifAssocie <- nil;
    equipementDeRejetCAN equipementRejetHorsZone <- nil;
	
	action ajouterEquipementDeRejet (string acteur, equipementDeRejet equipementAajouter){ // Necessaire ???
		list<equipementDeRejet> liste <- (mapEquipementsRejetAssocies at acteur);
		add equipementAajouter to: liste;
		put liste at: acteur in: mapEquipementsRejetAssocies;				
	}
	
	bool isEnRestriction{	
		if(secteurAdministratifAssocie != nil){
			return secteurAdministratifAssocie.isEnRestriction();
		}else{
			return false;
		}
	}
	
	int getNiveauRestriction{
		if(isEnRestriction()){
			return secteurAdministratifAssocie.getNiveauRestriction();
		}else{
			return 0;
		}			
	}
	action gestionRejetHZ{
		ask equipementRejetHorsZone{
			do miseAJourVolumeReel();
		}
	}	
}
	
