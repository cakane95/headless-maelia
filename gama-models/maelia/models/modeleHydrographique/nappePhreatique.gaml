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
 *  NappesPhreatiques
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model nappePhreatique

import "../modeleCommun/idVariablesShapfile.gaml"
import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/contourZoneMaelia.gaml"
import "ressourceEnEau.gaml"
import "zoneHydrographique.gaml"

global{	
	string nappeShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/nappes/nappeParZH.shp';
	list<nappePhreatique> listeNappesPhreatiques <- [];
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionNappePhreatique{
		if !file_exists(nappeShape) {do raiseError("fichier inexistant: " + nappeShape);}
		//if !is_shape(nappeShape) {do raiseError("le fichier " + nappeShape + " n'est pas un fichier shape");}
		
		listeNappesPhreatiques <- constructionRessourcesEnEau(typeRessource:nappePhreatique, cheminShp:nappeShape, type:NAPP) as list<nappePhreatique>;		
	}
}

species nappePhreatique parent: ressourceEnEau{

}
