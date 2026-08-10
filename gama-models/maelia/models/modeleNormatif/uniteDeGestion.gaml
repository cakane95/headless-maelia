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
 *  uniteDeGestion
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model uniteDeGestion

import "../modeleCommun/contourZoneMaelia.gaml"
 
global{
	string uniteDeGestionShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/uniteDeGestion/UG_region_L93_BGA.shp';
	
	/* 
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionUnitesDeGestion{
		if(file_exists(uniteDeGestionShape)){
			create uniteDeGestion from: file(uniteDeGestionShape) with: [idUG::string(read (ID_UG))]{
				// Suppression des polygones nappartenant pas a la zone detude
				if(executerModeleSurUneZH and contourZoneEtude != nil and !(shape intersects contourZoneEtude.shape)){
					ask self{
						do die;	
					}						
				}else{
					do initialisationUniteDeGestion();
				}						
			}			
		}else{ // TODO : supprimer et mettre les vraies UG pour laveyron
			if(contourZoneEtude != nil){
				create uniteDeGestion{
					shape <- contourZoneEtude.shape;
					do initialisationUniteDeGestion();						
				}				
			}
		}
	}
}


species uniteDeGestion{
	rgb couleurUniteDeGestion <- rgb('white');
	pointDeReference pointNodalAssocie <- nil;
	string idUG<-"";
	
	/*
	 * *****************************************************************************************
	 */		
	action initialisationUniteDeGestion{
		set pointNodalAssocie value: first((pointDeReference as list) where (each.isNodal and  each.shape intersects shape)); 
		// Le fichier des UG n'est pas complet, il manque l'affectation de certaine UG a des points DOE, donc on en prend une au hasard si elle n'y est pas
		if(pointNodalAssocie = nil){
			set pointNodalAssocie value: one_of(pointDeReference where (each.isNodal));
		}
	}
	
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw shape color: couleurUniteDeGestion;
	}
	
	/*
	 * *****************************************************************************************
	 */
	action toString{
		write "******* " + name + " *******"; 
		write "pointNodalAssocie = " + pointNodalAssocie; 
	}		
}


