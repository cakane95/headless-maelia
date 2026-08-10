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
 *  inputSwatRte
 *  Author: Maelia
 *  Description: 
 */

model inputSwatRte

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersInputSwatRte{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputSwatRte...';		
		
		create inputSwatRte number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species inputSwatRte parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));

		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/inputSWAT_RTE.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;chw2[m];chd[m];ch_s2[m/m];ch_l2[km];ch_n2;ch_k2[mm/hr];ch_wdr[m/m]\n';

	 	ask(zh){
			 dataJournaliere <-  	dataJournaliere + 	''  + int(idSWAT) +
														';' + string(idZoneHydrographique) +	 
														';' + float(largeurMoyenCourEauReel) + ' ou ' + float(largeurCourEauReel) +
														';' + float(profondeurMoyenneCoursEauReel) +
														';' + float(penteMoyenneCourEauReel) +
														';' + float(longueurCoursEauReel) +
														';' + float(coefficientManningCoursEauReel) +
														';' + '?' + 
														';' + '?' + '\n';	 		
	 	}		 	
		return dataJournaliere;
	 }	 
}
