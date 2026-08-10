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
 *  resultatsSwatPhaseRoutageZH
 *  Author: Maelia
 *  Description: 
 */

model resultatsSwatPhaseRoutageZH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersSwatPhaseRoutageZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers SwatPhaseRoutageZH...';		
		
		create resultatsSwatPhaseRoutageZH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species resultatsSwatPhaseRoutageZH parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationSWAT_PhaseRoutage_ZH'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;date;Pluie;FlowIn;FlowOut;Evap';
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string data <- "";
	 	int num <- 0;		 	
//		 	if(zh != nil){
		ask(listeZonesHydrographiques){
			num <- num + 1;
		 	data <-  	data + ''  + int(zoneHydrographiqueSWAT(self).idSWAT) +
						';' + string(idZoneHydrographique) +	
						';' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +								
						';' + float(pluie) with_precision 5 +
						';' + float(volumeEntree / nbSecondesDansUneJournee) with_precision 5+	
						';' + float(debitCourant) with_precision 5+
						';' + float(zoneHydrographiqueSWAT(self).volumeEvaporationCourEau) with_precision 5;
//							';' + float(perteParTransmission);	
			if(num < length(listeZonesHydrographiques)){
				data <- data + '\n';
			}					 		
	 	}				
	 	return data;			 		 	
	 } 			 			 
}
