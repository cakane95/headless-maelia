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
 *  resultatsDebugSortieZH
 *  Author: Maelia
 *  Description: Sortie à traiter pour l'analyse de sensibilité
 */

model resultatsDebugSortieZH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleNormatif/pointDeReference.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

import "../modeleCommun/typeDeSol.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"

global{
	action initialisationEcritureFichiersDebugSortieZH{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsDebugSortieZH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsDebugSortieZH parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
			nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resDebugSortieZH'+ nomDeLaSimulation + '.csv';
			string dataJournaliere <- 'date';
				
	        ask listeZonesHydrographiques{
	        	dataJournaliere <- dataJournaliere + ';volumeSortie[m3]' +'_' + name;
	        }

			return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
			string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
			

			ask listeZonesHydrographiques{
				
				data <- data + ';' + volumeSorti;	
												 						
			 }

		return data;
	 }			  			 
}

