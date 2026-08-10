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
 *  resultatsSWATHRU
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model resultatsSwatHRU

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
	action initialisationEcritureFichiersSwatHRU{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers SwatHRU...';		
		
		create resultatsSwatHRU number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species resultatsSwatHRU parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationSWAT_HRU.csv';
		string dataJournaliere <- '' + detailSimulation + 	'\nSUB' +
															';idZH' + 
															';date' + 
															';num' + 
															';clc' + 
															';sol' + 
															';pente' + 
															';fraction' + 
															';Area[Km2]' + 
															';PRECIP[mm]' + 
															';Snowfall[mm]' + 
															';SnowMelt[mm]' + 
															';IRR[mm]' + 
															';PET[mm]' + 
															';ET[mm]' + 
															';SwFin[mm]' +
															';Perc[mm]' + 
															';GwRchgv[mm]' +
															';DaRchg[mm]' + 
															';Revap[mm]' + 
															';SaSt[mm]' + 
															';DaSt[mm]' + 
															';SurqGen[mm]' + 
															';SurqCnt[mm]' + 
															';Tloss[mm]' + 
															';LatQgen[mm]' + 
															';GwQ[mm]' + 
															';Wyld[mm]' + 
															';DailyCN' + 
															';TmpAv' + 
															';TmpMx' + 
															';TmpMn' + 
															';SolTmp' + 
															';Solar\n';
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
		 		float snowmelt <- 0.0;
		 		ask(bandesDelevation.keys){ 
					float fractionHRU <- myself.bandesDelevation at self;
					snowmelt <- snowmelt + fractionHRU*fonteDeNeige;
				}
		 		
			 	data <-  	data + ''  + int(zh.idSWAT) +
							';' + string(zh.idZoneHydrographique) +	
							';' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
							';' + int(numero) +	
							';' + string(clcAssocie.typeClasse) +	
							';' + string(sol.stuDominant) +	
							';' + float(penteAssociee) +	
							';' + float(fractionDansZH) +	
							';' + float(getSurfaceKm2()) +	
							';' + float(zh.pluie) +	
							';' + float(zh.chuteDeNeige) +
							';' + float(snowmelt) +
							';' + float(0.0) +
							';' + float(zh.meteo.etp) +
							';' + float(evapoTranspirationReelle) +								
							';' + float(sum(mapTeneurEnEauSolParCouche.values)) +
							';' + float(getPercolationDerniereCouche()) +
							';' + float(eauEntreeAquiferes) +
							';' + float(eauAquifereProfond) +
							';' + float(eauRevap) +
							';' + float(eauStockeeAquiferePeuProfond) +
							';' + '?' +
							';' + float(ruissellementDeSurfaceHRUtotal) +
							';' + float(ruissellementDeSurfaceHRU) +
							';' + float(perteParTransmission) +
							';' + float(ecoulementLateral) +
							';' + float(ecoulementEauSouterraine) +
							';' + float(getEauSortie()) +
							';' + float(curveNumber) +
							';' + float(zh.tMoy) +
							';' + float(zh.tMax) +
							';' + float(zh.tMin) +
							';' + '?' +
							';' + '?'; 
				if(numero < length(zh.listeHRUAssociees)){
					data <- data + '\n';
				}	
		 	}		 		
	 	}
	 	return data;			 		 	
	 } 			 			 
}

