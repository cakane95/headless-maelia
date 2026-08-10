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
 *  Description: Sortie à traiter pour l'analyse de sensibilité
 */

model resultatsRestrictions

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"

import "ecritureResultats.gaml"



global{
	action initialisationEcritureFichiersRestrictions{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Restrictions...';		
		
		create resultatsRestrictions number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}	
	map<zoneAdministrative,map<int,int>> nbJoursRestrictionsParNiveau <- map<zoneAdministrative,map<int,int>>([]);
}


species resultatsRestrictions parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
	 	nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/Restrictions_Annuel'+ nomDeLaSimulation + '.csv';	
		string data <- '' + detailSimulation + '\nannee';
		ask listZonesAdministratives{
			map<int,int> initnbJoursRestrictionsParNiveau <- map<int,int>([]);
			loop niveau over: self.nomAffichageNiveauRestriction.keys {
				data <- data + ';nbJours_'+ nomAffichageNiveauRestriction at niveau +'_' + idZoneAdministrative ;
				put 0 at: niveau in: initnbJoursRestrictionsParNiveau;
			}
			put initnbJoursRestrictionsParNiveau at: self in: nbJoursRestrictionsParNiveau;
        }
		return data;
	 }
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/Restrictions_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
			
        ask listZonesAdministratives{
        	dataJournaliere <- dataJournaliere + ';' + idZoneAdministrative ;
        }

		return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										

		ask listZonesAdministratives{
			data <- data + ';' + (nomAffichageNiveauRestriction at niveauDeRestriction) ;
			map<int,int> nbJoursRestrictionsParNiveauZAenCours  <- nbJoursRestrictionsParNiveau at self;
			put (1 + (nbJoursRestrictionsParNiveauZAenCours at niveauDeRestriction)) at: niveauDeRestriction in: nbJoursRestrictionsParNiveauZAenCours;
			put nbJoursRestrictionsParNiveauZAenCours at:self in: nbJoursRestrictionsParNiveau;
		 }
				
		return data;
	 }
	 /*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{		 	
		string data <- '' + (dateCour.annee);

		ask listZonesAdministratives{
			map<int,int> nbJoursRestrictionsParNiveauZAenCours  <- nbJoursRestrictionsParNiveau at self;
		 	loop niveau over: self.nomAffichageNiveauRestriction.keys {
		 		data <- data + ';' + (nbJoursRestrictionsParNiveauZAenCours at niveau);
		 		put 0 at: niveau in: nbJoursRestrictionsParNiveauZAenCours;
		 	}
		 }
		
		return data;
	 }			  			 
}
	
