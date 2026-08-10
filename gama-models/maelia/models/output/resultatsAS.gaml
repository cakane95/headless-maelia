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

model resultatsAS

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
	action initialisationEcritureFichiersAS{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsAS number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsAS parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resAS'+ nomDeLaSimulation + '.csv';
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
			
			// variables des HRU non RPG
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

			// variables des HRU RPG
			float ETR_RPG <-0.0;
			float SurfaceTotale_RPG <-0.0;
			float RU_RPG <-0.0;
			float RULast_RPG <-0.0;
			float AquifereProfond_RPG <-0.0;
			float AquiferePeuProfond_RPG <-0.0;
			float EntreeAquiferes_RPG <-0.0;
			float Recap_RPG <-0.0;
			float Ruissellement_RPG <-0.0;
			float ecoulementLat_RPG <-0.0;
			float ecoulementEauSout_RPG <-0.0;

			ask listeZonesHydrographiques{
				
			 	// JV 150618: on fait d'abord HRU puis HRU_RPG dans deux boucles séparées car pas les mêmes variables récupérées



				ETR <- zoneHydrographiqueSWAT(self).volumeEvapotranspirationHydro;
	   			SurfaceTotale <- 0.0;
	   			RU <-0.0;
				RULast <-0.0;
				AquifereProfond <-0.0;
				AquiferePeuProfond <-0.0;
				EntreeAquiferes <-0.0;
				Recap <-0.0;
				Ruissellement <- zoneHydrographiqueSWAT(self).volumeRuissellementDeSurfaceHydro;
				ecoulementLat <- zoneHydrographiqueSWAT(self).volumeEcoulementLateralHydro;
				ecoulementEauSout <- zoneHydrographiqueSWAT(self).volumeEcoulementEauSouterraineHydro;
			 				 	
			 	ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
			 		SurfaceTotale <- SurfaceTotale + float(getSurfaceKm2());
					RU <- RU + float(sum(mapTeneurEnEauSolParCouche.values)) * float(getSurfaceKm2());
					RULast <- RULast + float(getPercolationDerniereCouche()) * float(getSurfaceKm2());
					EntreeAquiferes <- EntreeAquiferes + float(eauEntreeAquiferes) * float(getSurfaceKm2());
	   			 	AquifereProfond <- AquifereProfond + float(eauAquifereProfond) * float(getSurfaceKm2());
	   			 	Recap <- Recap + float(eauRevap) * float(getSurfaceKm2());
	   			 	AquiferePeuProfond <- AquiferePeuProfond + float(eauStockeeAquiferePeuProfond) * float(getSurfaceKm2());
				}

				// cf. explications dans resultatsAS_HRU.gaml
				if(SurfaceTotale > 0.0){				
					ETR <- ETR/(SurfaceTotale*1000.0);
					Ruissellement <- Ruissellement/(SurfaceTotale*1000.0);
					ecoulementLat <- ecoulementLat/(SurfaceTotale*1000.0);
					ecoulementEauSout <- ecoulementEauSout/(SurfaceTotale*1000.0);
					
					RU <- RU/SurfaceTotale;
					RULast <- RULast/SurfaceTotale;
					AquifereProfond <- AquifereProfond/SurfaceTotale;
					AquiferePeuProfond <- AquiferePeuProfond/SurfaceTotale;
					EntreeAquiferes <- EntreeAquiferes/SurfaceTotale;
					Recap <- Recap/SurfaceTotale;
				}


				// on passe aux HRU RPG

				ETR_RPG <- zoneHydrographiqueSWAT(self).volumeEvapotranspirationRPG; // JV 140618 déjà calculé à l'échelle de la ZH (voir commentaire boucle ci-dessous) [m3]
	   			SurfaceTotale_RPG <- 0.0;
	   			RU_RPG <- zoneHydrographiqueSWAT(self).volumeHumiditeHorizonTotalRPG; // JV 280618
				RULast_RPG <- zoneHydrographiqueSWAT(self).volumePercolationRPG;
				AquifereProfond_RPG <-0.0;
				AquiferePeuProfond_RPG <-0.0;
				EntreeAquiferes_RPG <-0.0;
				Recap_RPG <-0.0;
				Ruissellement_RPG <- zoneHydrographiqueSWAT(self).volumeRuissellementDeSurfaceRPG;
				ecoulementLat_RPG <- zoneHydrographiqueSWAT(self).volumeEcoulementLateralRPG;
				ecoulementEauSout_RPG <- zoneHydrographiqueSWAT(self).volumeEcoulementEauSouterraineRPG;
			 	
			 	ask zoneHydrographiqueSWAT(self).listeHRUrpgAssociees{
			 		SurfaceTotale_RPG <- SurfaceTotale_RPG + float(getSurfaceKm2()) ;
	   			 	EntreeAquiferes_RPG <- EntreeAquiferes_RPG + float(eauEntreeAquiferes) * float(getSurfaceKm2());
	   			 	AquifereProfond_RPG <- AquifereProfond_RPG + float(eauAquifereProfond) * float(getSurfaceKm2());
	   			 	Recap_RPG <- Recap_RPG + float(eauRevap) * float(getSurfaceKm2());
	   			 	AquiferePeuProfond_RPG <- AquiferePeuProfond_RPG + float(eauStockeeAquiferePeuProfond) * float(getSurfaceKm2());
				}
				
				/* JV 140618 : ETR Ruissellement, ecoulementLat et ecoulementEauSout déjà calculé à l'échelle de la ZH mais en [m3]
				 on veut en [mm] donc conversion: ETR[m3] * 1e9 (nb mm3 dans un m3) / (SurfaceTotale[km2] * 1e12 (nb mm2 dans un km2)) -> [mm3]/[mm2] = [mm]
				 comme on ne peut pas représenter la valeur 1e12 en int (max: 2.147483647E9) on va simplifier dans la fraction:
				 ETR           * 1e9           ETR
				 -------------------- = -------------------
				 SurfaceTotale * 1e12   SurfaceTotale * 1e3
				*/
				if(SurfaceTotale_RPG > 0.0){
					ETR_RPG <- ETR_RPG/(SurfaceTotale_RPG*1000.0);
					RU_RPG <- RU_RPG/(SurfaceTotale_RPG*1000.0);
					Ruissellement_RPG <- Ruissellement_RPG/(SurfaceTotale_RPG*1000.0);
					ecoulementLat_RPG <- ecoulementLat_RPG/(SurfaceTotale_RPG*1000.0);
					ecoulementEauSout_RPG <- ecoulementEauSout_RPG/(SurfaceTotale_RPG*1000.0);
					RULast_RPG <- RULast_RPG/(SurfaceTotale_RPG*1000.0);
					
					AquifereProfond_RPG <- AquifereProfond_RPG/SurfaceTotale;
					AquiferePeuProfond_RPG <- AquiferePeuProfond_RPG/SurfaceTotale;
					EntreeAquiferes_RPG <- EntreeAquiferes_RPG/SurfaceTotale;
					Recap_RPG <- Recap_RPG/SurfaceTotale;
				}
				
				
				// on somme les variables des HRU non RPG et des HRU RPG:
				// (varHRU*surfaceHRU + varHRU_RPG*surfaceHRU_RPG)/(surfaceHRU+surfaceHRU_RPG)
								
				if((SurfaceTotale + SurfaceTotale_RPG) > 0.0){
					ETR <- (ETR*SurfaceTotale + ETR_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					RU <- (RU*SurfaceTotale + RU_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					RULast <- (RULast*SurfaceTotale + RULast_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					EntreeAquiferes <- (EntreeAquiferes*SurfaceTotale + EntreeAquiferes_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					AquifereProfond <- (AquifereProfond*SurfaceTotale + AquifereProfond_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					Recap <- (Recap*SurfaceTotale + Recap_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					AquiferePeuProfond <- (AquiferePeuProfond*SurfaceTotale + AquiferePeuProfond_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					Ruissellement <- (Ruissellement*SurfaceTotale + Ruissellement_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					ecoulementLat <- (ecoulementLat*SurfaceTotale + ecoulementLat_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
					ecoulementEauSout <- (ecoulementEauSout*SurfaceTotale + ecoulementEauSout_RPG*SurfaceTotale_RPG)/(SurfaceTotale + SurfaceTotale_RPG);
				}	
				
				SurfaceTotale <- SurfaceTotale + SurfaceTotale_RPG;
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

