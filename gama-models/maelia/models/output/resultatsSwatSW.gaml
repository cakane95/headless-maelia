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
 *  resultatsSwatSW
 *  Author: Maelia
 *  Description: 
 */

model resultatsSwatSW


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
	action initialisationEcritureFichiersSwatSW{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers SwatHRU...';		
		
		create resultatsSwatSW number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species resultatsSwatSW parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationSWAT_SW.csv';
		string dataJournaliere <- '' + detailSimulation + 	'\nSUB' +
															';idZH' + 
															';date' + 
															';num' + 
															';clc' + 
															';sol' + 
															';pente' + 
															';fraction' + 
															';Area[Km2]'; 
															ask first(zh.listeHRUAssociees){
																loop indiceCoucheSol from: 1 to: sol.nbCouches{	
																	dataJournaliere <-  dataJournaliere + ';'  + indiceCoucheSol;
																}																	
															}
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	int numero <- 0;
	 	string data <- "";
	 	if(zh != nil){
		 	ask zh.listeHRUAssociees{
		 		numero <- numero + 1;
		 		
			 	data <-  	data + ''  + int(zh.idSWAT) +
							';' + string(zh.idZoneHydrographique) +	
							';' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
							';' + int(numero) +	
							';' + string(clcAssocie.typeClasse) +	
							';' + string(sol.stuDominant) +	
							';' + float(penteAssociee) +	
							';' + float(fractionDansZH) +	
							';' + float(getSurfaceKm2()); 
							
				loop indiceCoucheSol from: 1 to: sol.nbCouches{	
					data <-  data + ';'  + float(mapTeneurEnEauSolParCouche at indiceCoucheSol);
				}	
				data <-  data + '\n'; 							
		 	}		 		
	 	}
	 	return data;			 		 	
	 } 			 			 
}
