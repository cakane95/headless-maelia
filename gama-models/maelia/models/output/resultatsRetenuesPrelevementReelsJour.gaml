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
 *  resultatsRetenuesPrelevementReelsJour
 *  Author: Maelia
 *  Description: Sortie à traiter pour l'analyse de sensibilité
 */

model resultatsRetenuesPrelevementReelsJour

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/retenueCollinaire.gaml"
import "../modeleHydrographique/ressourceEnEau.gaml"

global{
	action initialisationEcritureFichiersRetenuesPrelevementsReelsJour{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsRetenuesPrelevementReelsJour number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsRetenuesPrelevementReelsJour parent: ecritureResultats{
	
	map<retenueCollinaire,float> mapRechargeEffective<- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,float> mapRemplissageDebutAnnee <- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,float> mapVolumePreleve <- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,int> mapNbJoursSousCulot <- map<retenueCollinaire,int>([]);
	list<retenueCollinaire> listeRetenuesCollinairesAsuivre <- [];
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/prelevementsReelsRetenues'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
			
		/*
		list<retenueCollinaire> listeRetenuesTemp <- listeRetenuesCollinaires where (each.typeOfRet = DECONNECTE) + 
																  listeRetenuesCollinaires where (each.typeOfRet = CONNECTE);
		ask listeRetenuesTemp{
			if(length(mapEquipementsCaptageAssocies at IRR)> 0){ // Si RET a usage Agricole
				myself.listeRetenuesCollinairesAsuivre << self;
			}
		}
 		*/
 		
 		listeRetenuesCollinairesAsuivre <- listeRetenuesCollinaires;
 		
 
		ask listeRetenuesCollinairesAsuivre{
			dataJournaliere <- dataJournaliere + ";" +self.id;
		}

		return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
			string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
			
		ask listeRetenuesCollinairesAsuivre{
		 	data <- data + ';' + self.getVolumePreleveReel();
		}
		 			
		return data;
	 }			  			 
}

