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

model resultatsAS_HRU_RPG

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleNormatif/pointDeReference.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

import "../modeleCommun/typeDeSol.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"

global{
	action initialisationEcritureFichiersAS_HRU_RPG{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsAS_HRU_RPG number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsAS_HRU_RPG parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resAS_HRU_RPG'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
			
        ask listeZonesHydrographiques{
        	dataJournaliere <- dataJournaliere + ';Area[Km2]' +'_' + name +
					 ';ET[mm]' +'_' + name +
					 ';SwFin[mm]'+'_' + name +
					 ';Perc[mm]' +'_' + name +
					 ';eauEntreeAquiferes[mm]' +'_' + name +
					 ';eauAquifereProfond[mm]' +'_' + name +
					 ';Recap[mm]' +'_' + name +
					 ';eauStockeeAquiferePeuProfond[mm]' +'_' + name +
					 ';ruissellementDeSurfaceHRU[mm]' +'_' + name +
					 ';ecoulementLateral[mm]' +'_' + name +
					 ';ecoulementEauSouterraine[mm]'+'_' + name+
					 ';pluie[mm]'+'_' + name;
        }

			return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);															
			
			//Pour récupérer les propriétés moyennes à l'échelles du territoire
			
			float ETR <-0.0;
			float SurfaceTotale <-0.0;
			float RU <-0.0;
			float RULast <-0.0;
			float AquifereProfond <-0.0;
			float AquiferePeuProfond <-0.0;
			float EntreeAquiferes <-0.0;
			float Recap <-0.0;
			float Ruissellement <-0.0;
			float ecoulementLat <-0.0;
			float ecoulementEauSout <-0.0;


			// voir explications dans resultatsAS_HRU.gaml

			ask listeZonesHydrographiques{
				
				// ETR <- 0.0;
				ETR <- zoneHydrographiqueSWAT(self).volumeEvapotranspirationRPG; // JV 140618 déjà calculé à l'échelle de la ZH (voir commentaire boucle ci-dessous) [m3]
	   			SurfaceTotale <- 0.0;
	   			RU <- zoneHydrographiqueSWAT(self).volumeHumiditeHorizonTotalRPG; // JV 280618
				RULast <- zoneHydrographiqueSWAT(self).volumePercolationRPG;
				AquifereProfond <-0.0;
				AquiferePeuProfond <-0.0;
				EntreeAquiferes <-0.0;
				Recap <-0.0;
				Ruissellement <- zoneHydrographiqueSWAT(self).volumeRuissellementDeSurfaceRPG;
				ecoulementLat <- zoneHydrographiqueSWAT(self).volumeEcoulementLateralRPG;
				ecoulementEauSout <- zoneHydrographiqueSWAT(self).volumeEcoulementEauSouterraineRPG;
			 	
			 	ask zoneHydrographiqueSWAT(self).listeHRUrpgAssociees{
			 		SurfaceTotale <- SurfaceTotale + float(getSurfaceKm2()) ;
	   			 	EntreeAquiferes <- EntreeAquiferes + float(eauEntreeAquiferes) * float(getSurfaceKm2());
	   			 	AquifereProfond <- AquifereProfond + float(eauAquifereProfond) * float(getSurfaceKm2());
	   			 	Recap <- Recap + float(eauRevap) * float(getSurfaceKm2());
	   			 	AquiferePeuProfond <- AquiferePeuProfond + float(eauStockeeAquiferePeuProfond) * float(getSurfaceKm2());
				}
				
				/* JV 140618 : ETR Ruissellement, ecoulementLat et ecoulementEauSout déjà calculé à l'échelle de la ZH mais en [m3]
				 on veut en [mm] donc conversion: ETR[m3] * 1e9 (nb mm3 dans un m3) / (SurfaceTotale[km2] * 1e12 (nb mm2 dans un km2)) -> [mm3]/[mm2] = [mm]
				 comme on ne peut pas représenter la valeur 1e12 en int (max: 2.147483647E9) on va simplifier dans la fraction:
				 ETR           * 1e9           ETR
				 -------------------- = -------------------
				 SurfaceTotale * 1e12   SurfaceTotale * 1e3
				*/
				if(SurfaceTotale > 0.0){
					ETR <- ETR/(SurfaceTotale*1000.0);
					RU <- RU/(SurfaceTotale*1000.0);
					Ruissellement <- Ruissellement/(SurfaceTotale*1000.0);
					ecoulementLat <- ecoulementLat/(SurfaceTotale*1000.0);
					ecoulementEauSout <- ecoulementEauSout/(SurfaceTotale*1000.0);
					RULast <- RULast/(SurfaceTotale*1000.0);
	
					// pas de conversion car pondération par des [km2] dans la boucle puis division du total par des [km2] donc on retombe bien sur des [mm]								
					AquifereProfond <- AquifereProfond/SurfaceTotale;
					AquiferePeuProfond <- AquiferePeuProfond/SurfaceTotale;
					EntreeAquiferes <- EntreeAquiferes/SurfaceTotale;
					Recap <- Recap/SurfaceTotale;
				}			
				
				data <- data + ';' + SurfaceTotale +	
						';' + ETR +
						';' + RU +
						';' + RULast +
						';' + EntreeAquiferes +
						';' + AquifereProfond +
						';' + Recap +
						';' + AquiferePeuProfond +
						';' + Ruissellement +
						';' + ecoulementLat +
						';' + ecoulementEauSout+
						';' + pluie;
			 }
				
		return data;
	 }			  			 
}

