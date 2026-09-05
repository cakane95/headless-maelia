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
 *  Exploitations
 *  Author: Renaud Misslin
 *  Description: Un atelier d'élevage
 */

model batiment

import "lotAnimaux.gaml"

global{
	string batimentShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/batiments.shp';
	
	action constructionBatimentElevage {
		if file_exists(batimentShape)	{
			create batiment from: file(batimentShape) with: [id::string(read(ID_BATIMENT)), codeExploitationAssociee::string(read(ID_EXPL))] {
				monExploitation <- first(exploitation collect each where (each.id = codeExploitationAssociee));
				monExploitation.monBatiment <- self;
				if (monExploitation = nil) {
					do die;
				}
			}
		}
	}
}

	
species batiment {
	string id;
	exploitation monExploitation;
	string codeExploitationAssociee;

	/*
	* *****************************************************************************************
	* Initialisation
	*/
	
	
	/*
	* *****************************************************************************************
	* Actions / fonctions
	*/
	
	/*
	 * *****************************************************************************************
	 * Display
	 */
	 
	aspect basic{
		//draw shape color: couleurExploitation;
	}   	
}

	
