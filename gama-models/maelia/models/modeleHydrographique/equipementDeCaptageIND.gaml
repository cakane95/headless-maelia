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

model equipementDeCaptageIND

import "equipement.gaml"

global {
	string pointsPrelevementINDShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDePrelevement/ind/ppInd.shp';	
	string volumeRefIndCSV <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDePrelevement/ind/volumeRefAnnuelIND.csv';	
	float VOLUME_DE_REFERENCE_ANNUEL_PRELEVE_IND_ZM <- 0.0; // Volume de ref de 2010
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action constructionEquipementsDeCaptageIND{
		if !file_exists(pointsPrelevementINDShape) 		{do raiseWarning("fichier des points de prélèvements en eau pour l'industrie inexistant: " + pointsPrelevementINDShape);}
		//else if !is_shape(pointsPrelevementINDShape) 	{do raiseWarning("le fichier des points de prélèvements en eau pour l'industrie n'est pas un fichier shape: " + pointsPrelevementINDShape);}		
		do creationEquipements(cheminEntree:pointsPrelevementINDShape, typeEquipement:equipementDeCaptageIND);
		do initialisationVolumeReference();
	}
	
	/*
	 * Private
	 * Le fichier donne le volume moyen pour tous les points IND car si on est que sur une ZH, on pourra avoir une valeur plus ou moins coherente
	 */
	action initialisationVolumeReference{
		if !file_exists(volumeRefIndCSV) 		{do raiseWarning("fichier des volumes moyens de prélèvements en eau pour l'industrie inexistant: " + volumeRefIndCSV);}
		else{
			matrix matrice <- matrix(csv_file (volumeRefIndCSV, ";",false)); 
			//matrix matrice <- matrix(file (volumeRefIndCSV)); 			
			int nbLignes <- length(matrice column_at 0);
			if(nbLignes > 1){ //si il y a au moins 1 donnee
				loop i from: 1 to: ( nbLignes - 1 ) { 
					list<string> ligneI <- (matrice row_at i) as list<string>;
					string idEqu <- ligneI at 0;
					float volume <- float(ligneI at 1);
					
					equipementDeCaptageIND equIND <- first((equipementDeCaptageIND as list) where (each.idEquipement = idEqu));
					if(equIND != nil){
						VOLUME_DE_REFERENCE_ANNUEL_PRELEVE_IND_ZM <- VOLUME_DE_REFERENCE_ANNUEL_PRELEVE_IND_ZM + volume;
					}
				}
			}			
		}		
	}
}


species equipementDeCaptageIND parent: equipementDeCaptage{	
	float volumeSouhaite <- 0.0;
	string acteurAssocie <- IND;
	rgb couleurEquipement <- rgb('orange');				
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 */
	float getVolumeSouhaite{			
		return tauxSurZM*VOLUME_DE_REFERENCE_ANNUEL_PRELEVE_IND_ZM / dateCour.getNbJoursDansAnneeCourante();
	}	
}
