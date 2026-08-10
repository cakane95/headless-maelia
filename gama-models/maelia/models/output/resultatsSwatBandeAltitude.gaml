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
 *  resultatsSwatBandeAltitude
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model resultatsSwatBandeAltitude

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
	action initialisationEcritureFichiersSwatBandeAltitude{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers SwatHRU...';		
		
		create resultatsSwatBandeAltitude number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species resultatsSwatBandeAltitude parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationSWAT_BANDE_ALTI.csv';
		string dataJournaliere <- '' + detailSimulation + 	'\nidBande' +
															';date' + 
															';AltiPtMeteo' + 
															';altitude' + 
															';fraction' + 
															';PuieInit' + 
															';TminInit' + 
															';TmaxInit' + 
															';tDiff' + 
															';pDiff' + 
															';temperatureMoy' +
															';temperatureMin' +
															';temperatureMax' +
															';precipitations' +
															';temperatureNeige' +
															';eauDansPaquetNeige' +
															';fonteDeNeige';
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	int numero <- 0;
	 	string data <- "";
	 	if(zh != nil){		 		
	 		int taille <- length(zh.bandesDelevation);		 		
		 	ask zh.bandesDelevation{
		 		numero <- numero + 1;

			 	data <-  	data + ''  + string(id) +	
							';' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
							';' + float(zhAssociee.meteo.altitudeStationAssociee) +	
							';' + float(altitude) +	
							';' + float(fraction) +	
							';' + float(zhAssociee.meteo.pluie) +
							';' + float(zhAssociee.meteo.tMin) +
							';' + float(zhAssociee.meteo.tMax) +
							';' + float(tDiff) +	
							';' + float(pDiff) +	
							';' + float(temperatureMoy) +
							';' + float(temperatureMin) +
							';' + float(temperatureMax) +
							';' + float(precipitations) +
							';' + float(temperatureNeige) +
							';' + float(eauDansPaquetNeige) +
							';' + float(fonteDeNeige); 						
				if(numero < taille){
					data <- data + '\n';
				}	
		 	}		 		
	 	}
	 	return data;			 		 	
	 } 			 			 
}

