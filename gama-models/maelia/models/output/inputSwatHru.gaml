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
 *  inputSwatHru
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model inputSwatHru

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleCommun/clc.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersInputSwatHRU{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputSwatHru...';		
		
		create inputSwatHru number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species inputSwatHru parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));

		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/inputSWAT_HRU.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;num;clc;sol;pente;fraction;slSubbsn[m];Hru_slp[m/m];ov_n;Lat_ttime[days];slsoil[m];canmx;esco;epco\n';

	 	int numero <- 0;
	 	if(zh != nil){
		 	ask zh.listeHRUAssociees{
		 		numero <- numero + 1;
		 		
			 	dataJournaliere <-  	dataJournaliere + 	'' + int(zh.idSWAT) +
															';' + string(zh.idZoneHydrographique) +	
															';' + int(numero) +	
															';' + string(clcAssocie.typeClasse) +	
															';' + string(sol.stuDominant) +	
															';' + float(penteAssociee) +	
															';' + float(fractionDansZH) +	
															';' + float(zh.longueurMoyennePente) +	
															';' + float(penteAssociee) +	
															';' + float(coefficientManningTerrain) +	
															';' + '?' +	
															';' + '?' +	
															';' + '?' +	
															';' + esco +	
															';' + epco + '\n'; 
			 	}		 		
		 	}
			return dataJournaliere;
		 }	 
	}
