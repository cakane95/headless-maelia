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
 *  equipementDeRejetIND
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model equipementDeRejetIND

import "equipement.gaml"

global{
	string pointsRejetINDShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDeRejet/ind/rjI.shp';	
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Je cree un point de rejet au centre de chaque ZH
	 */ 
	action constructionEquipementsDeRejetIND{	
		if !file_exists(pointsRejetINDShape) 		{do raiseWarning("fichier des points de rejets en eau inddustriels inexistant: " + pointsRejetINDShape);}
		//else if !is_shape(pointsRejetINDShape) 		{do raiseWarning("le fichier des points de rejets en eau industriels n'est pas un fichier shape: " + pointsRejetINDShape);}
		do creationEquipements(cheminEntree:pointsRejetINDShape, typeEquipement:equipementDeRejetIND);				
	}
}

species equipementDeRejetIND parent: equipementDeRejet{	
	string acteurAssocie <- IND;
	rgb couleurEquipement <- rgb('orange');	
	float rapportPrelevement <- rapportConsomationPrelevementIND;		
}
