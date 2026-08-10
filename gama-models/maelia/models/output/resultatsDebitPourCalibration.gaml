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
 *  resultatsDebitPourCalibration
 *  Author: Maelia
 *  Description: Sortie à pour calibration sur le cluster Meso@LR
 */

model resultatsDebitPourCalibration

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
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
	action initialisationEcritureFichiersDebitPourCalibration{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers debits aux points de references...';		
		
		create resultatsDebitPourCalibration number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsDebitPourCalibration parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debit_'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'annee';
		ask pointDeReference{
			dataJournaliere <- dataJournaliere + ';' + idPointDeReference ;
		}
			
			return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
		
		ask pointDeReference{
			data <- data + ';' + debitJournalier with_precision 2;
		}	
		return data;
	 }			  			 
}
	

