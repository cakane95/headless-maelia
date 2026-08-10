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
 *  resultatsPrelevements
 *  Author: Maelia
 *  Description: 
 */

model resultatsPrelevementsAS

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"

global{
	action initialisationEcritureFichiersPrelevementsAS{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevementsAS number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevementsAS parent: ecritureResultats{
	float volumeSouhaiteAnnuelIRR_EQU_ZM <- 0.0;
	float volumeReelAnnuelIRR_EQU_ZM <- 0.0;

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{	
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/prelevements_Journalier_IRR_AS'+ nomDeLaSimulation + '.csv';
		let dataJournaliere type: string value: 'annee';
		ask equipementDeCaptageIRR {
			dataJournaliere<- dataJournaliere + ';' + idEquipement; 	
		}
		return dataJournaliere;	
	}

		/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
		string data <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);			
	 	
		ask equipementDeCaptageIRR {
			data <- data + ';' + volumeReel with_precision 0; 	
		}
	 	
	 	return data;		 			 	
	 }
	 

}

