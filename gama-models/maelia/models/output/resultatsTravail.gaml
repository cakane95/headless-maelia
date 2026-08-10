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
 *  resultatsTravail
 *  Author: Maelia
 *  Description: Sortie à traiter pour l'analyse de sensibilité
 */

model resultatsTravail

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
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"

global{
	action initialisationEcritureFichiersTravail{		
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers travail ...';		
		
		create resultatsTravail number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}
				
}


species resultatsTravail parent: ecritureResultats{
	map<agriculteur,float> nbHeuresTravail <- map<agriculteur,float>([]);
	map<agriculteur,int> nbJoursTravail <- map<agriculteur,int>([]);
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
	 	nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/Travail_Annuel'+ nomDeLaSimulation + '.csv';	
		string data <- '' + detailSimulation + '\nannee';
		ask listeAgriculteurs{
	    	data <- data + ';HeuresTravailles_' + name
	    			+ ';NombreDeJoursTravailles_' + name;
	    	put 0.0 at: self in: myself.nbHeuresTravail;
			put 0 at: self in: myself.nbJoursTravail;
	    }
		return data;
	 }
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/Agri_heuresEffectueesActivite'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'annee';
		ask listeAgriculteurs{
	    	dataJournaliere <- dataJournaliere + ';HeureTravaille_' + name;
	    }    
		return dataJournaliere;	 	
	 }

	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
		ask listeAgriculteurs{
			data <- data + ';' + heuresEffectueesActivite with_precision 1;
			put (heuresEffectueesActivite + ( myself.nbHeuresTravail at self)) at: self in: myself.nbHeuresTravail;
			if (heuresEffectueesActivite > 0){
				put (1 + (myself.nbJoursTravail at self)) at: self in: myself.nbJoursTravail;
			}
			
		}
				
		return data;
	 }
	 
	 string ecritureFinAnnuelle{		 	
		string data <- '' + (dateCour.annee);

		ask listeAgriculteurs{
			data <- data + ';' + (myself.nbHeuresTravail at self) with_precision 1
					+ ';' + (myself.nbJoursTravail at self);
			put 0.0 at: self in: myself.nbHeuresTravail;
			put 0 at: self in: myself.nbJoursTravail;
		}
				
		return data;
	 }			  			 
}
	

