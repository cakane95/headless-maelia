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
 *  resultatsDebistSTH
 *  Author: Maelia
 *  Description: 
 */

model resultatsDebistSTH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleNormatif/pointDeReference.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersDebistSTH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers debits STH...';		
		
		create resultatsDebistSTH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsDebistSTH parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/DebistSTH'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detailSimulation + '\nannee';
		loop idPointSTH over: listeIdSthAcomparer{
			dataJournaliere <- dataJournaliere + ';' + idPointSTH + '_SIM;' + idPointSTH + '_OBS;doe;qa;qi;qar;dcr';
		}			
		return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
		loop idPointSTH over: listeIdSthAcomparer{
			pointDeReference ptRef <- first((pointDeReference as list) where (each.idPointDeReference = idPointSTH));	
			if(ptRef != nil){
				data <- data 	+ ';' + (ptRef.debitJournalier) 
								+ ';' + (ptRef.mapDebitReel at dateCour.indiceDate) 
								+ ';' + (ptRef.doe) 
								+ ';' + (ptRef.qa) 
								+ ';' + (ptRef.qi) 
								+ ';' + (ptRef.qar) 
								+ ';' + (ptRef.dcr);
			}else{
				data <- data + ';null;null;null;null;null;null;null';
			}					
		}			
		return data;
	 }			  			 
}

