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

model resultatsCanaux

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"

global{
	action initialisationEcritureFichiersCanaux{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsCanaux number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsCanaux parent: ecritureResultats{
		
	map<equipementDeCaptageCanaux, float> prelevementCanauxReel <- map<equipementDeCaptageCanaux, float>([]);
	map<equipementDeCaptageCanaux, float> prelevementCanauxSouhaite <- map<equipementDeCaptageCanaux, float>([]);
	list<equipementDeCaptageCanaux> listeEqCaptageCanaux <- (mapEquipementsDeCaptage at CAN) as list<equipementDeCaptageCanaux>;

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string detail <- detailSimulation + '\n';			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/Canaux_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detail + '\nannee';
		
		ask listeEqCaptageCanaux{
			put 0.0 at: self in: myself.prelevementCanauxReel;
			put 0.0 at: self in: myself.prelevementCanauxSouhaite;
			dataJournaliere <- dataJournaliere + ';debitSouhaiteJour'+name +';debitReelJour'+name;
		}
		return dataJournaliere;	
	}

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		string detail <- detailSimulation + '\n';			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/Canaux_Annuel'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detail + '\nannee';
		ask listeEqCaptageCanaux{
			dataAnnuelle <- dataAnnuelle + ';volumeSouhaite'+name +';volumeReel'+name;
		}
		return dataAnnuelle;	 	
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
		string data <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);		
	 	ask listeEqCaptageCanaux{
	 		put (myself.prelevementCanauxSouhaite at self + getVolumeSouhaite()) at: self in: myself.prelevementCanauxSouhaite;
	 		put (myself.prelevementCanauxReel at self + volumeReel) at: self in: myself.prelevementCanauxReel;
	 		data <- data + ';'+getVolumeSouhaite()/nbSecondesDansUneJournee with_precision 0 +';'+ volumeReel/nbSecondesDansUneJournee with_precision 0;
	 	}
		 	
	 	return data;		 			 	
	 }
	 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{	
		string data <-  	'' + (dateCour.annee) ;	
		ask listeEqCaptageCanaux{
			data <- data + ';'+(myself.prelevementCanauxSouhaite at self) with_precision 0 +';'+(myself.prelevementCanauxReel at self) with_precision 0 ;
		}		
		return data;			 					 				
	 }	

	/*
	 * @Overwrite
	 */		 
	 action miseAzero{		
		ask listeEqCaptageCanaux{
			put 0.0 at: self in: myself.prelevementCanauxSouhaite;
			put 0.0 at: self in: myself.prelevementCanauxReel;
		}
	 }		 			 
}

