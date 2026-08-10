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
 *  equipementDeRejetAEP
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model equipementDeRejetAEP

import "equipement.gaml"

global{
	string pointsRejetAEPShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDeRejet/aep/rjAEP.shp';

	/*
	 * *****************************************************************************************
	 * Publique
	 * Je cree un point de rejet au centre de chaque ZH
	 */ 
	action constructionEquipementsDeRejetAEP{
		if !file_exists(pointsRejetAEPShape) 		{do raiseWarning("fichier des points de rejets en eau potable inexistant: " + pointsRejetAEPShape);}
		//else if !is_shape(pointsRejetAEPShape) 		{do raiseWarning("le fichier des points de rejets en eau potable n'est pas un fichier shape: " + pointsRejetAEPShape);}
		do creationEquipements(cheminEntree:pointsRejetAEPShape, typeEquipement:equipementDeRejetAEP);		
	}
}

species equipementDeRejetAEP parent: equipementDeRejet{
	string acteurAssocie <- AEP;
	rgb couleurEquipement <- rgb('blue');	
	float rapportPrelevement <- rapportConsomationPrelevementMogire;									
}
