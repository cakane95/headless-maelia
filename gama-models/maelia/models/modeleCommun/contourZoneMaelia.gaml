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
 *  contourZoneMaelia
 *  Author: Maelia
 *  Description: 	Cette classe gaml represente le contour de la zone dՎtude. 
 * 					Il peut correspondre soit a une seule zone hydrographique, un agregat de zones hydrographique ou la zone MAELIA complete.
 */

model contourZoneMaelia

import "../modeleHydrographique/zoneHydrographique.gaml"

global{
	string contourZMShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/contourZH.shp';	
	contourZoneMaelia contourZoneEtude <- nil;
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action constructionContourZoneMaelia{
		if(!executerModeleSurUneZH){
			if !file_exists(contourZMShape) {do raiseError("fichier inexistant: " + contourZMShape);}
			//if !is_shape(contourZMShape) {do raiseError("le fichier " + contourZMShape + " n'est pas un fichier shape");}
			create contourZoneMaelia from: file(contourZMShape);
		}else{
			if(!empty(listeZonesHydrographiques)){
				create contourZoneMaelia number: 1{					
					geometry zhAggregeGeometry <- nil;
					loop zhCourante over: listeZonesHydrographiques{
						zhAggregeGeometry <- zhAggregeGeometry union zhCourante.shape;
					}
					self.shape <- zhAggregeGeometry; 
				}				
			}			
		}	
		//write "contourZoneMaelia="+ (contourZoneMaelia as list) collect (each.shape.area); // JV debug 080921
		contourZoneEtude <- first(contourZoneMaelia as list);	
	}
}

species contourZoneMaelia{
	rgb couleurContour <- rgb('white'); 	
	
	aspect basic{
		draw shape color: couleurContour border: rgb('black');  // lightGray
	}		
}
