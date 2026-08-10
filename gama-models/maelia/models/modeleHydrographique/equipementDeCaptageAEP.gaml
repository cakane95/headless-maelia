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

model equipementDeCaptageAEP

import "equipement.gaml" 

global {	
	string pointsPrelevementAEPShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDePrelevement/aep/ppAep.shp';
				
	/*
	 * *****************************************************************************************
	 * Publique 
	 */ 
	action constructionEquipementsDeCaptageAEP{	
		if !file_exists(pointsPrelevementAEPShape) 		{do raiseWarning("fichier des points de prélèvements en eau potable inexistant: " + pointsPrelevementAEPShape);}
		//else if !is_shape(pointsPrelevementAEPShape) 	{do raiseWarning("le fichier des points de prélèvements en eau potable n'est pas un fichier shape: " + pointsPrelevementAEPShape);}
		do creationEquipements(cheminEntree:pointsPrelevementAEPShape, typeEquipement:equipementDeCaptageAEP);
	}
}

species equipementDeCaptageAEP parent: equipementDeCaptage{	
	string acteurAssocie <- AEP;
	rgb couleurEquipement <- rgb('blue');				

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Modele Mogire : on recalcul le volume utilise par chaque commune chaque annee puis on l'agrege a la zone et on le reaffect au pp en fonction de son taux
	 * Voir document sur le journalisation des series AEP
	 */
	float getVolumeSouhaite{			
		return tauxSurZM*volumeJournalierEauPotableConsommeeSouhaiteZoneMaelia / rapportConsomationPrelevementMogire;
	}
}
