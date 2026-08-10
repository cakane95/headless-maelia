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

model resultatsAS_m3

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
	action initialisationEcritureFichiersAS_m3{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsAS_m3 number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


	species resultatsAS_m3 parent: ecritureResultats{
		/*
		 * @Overwrite
		 */
		 string initialisationJournalier{			
			// Journaliers
			
			nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resAS'+ nomDeLaSimulation + '_m3.csv';
			string dataJournaliere <- 'date';
				
	        ask listeZonesHydrographiques{
	        	dataJournaliere <- dataJournaliere + ';Area[m2]' +'_' + name +
						 ';ET[m3]' +'_' + name +
						 ';SwFin[m3]'+'_' + name +
						 ';Perc[m3]' +'_' + name +
						 ';eauEntreeAquiferes[m3]' +'_' + name +
						 ';eauAquifereProfond[m3]' +'_' + name +
						 ';Recap[m3]' +'_' + name +
						 ';eauStockeeAquiferePeuProfond[m3]' +'_' + name +
						 ';ruissellementDeSurfaceHRU[m3]' +'_' + name +
						 ';ecoulementLateral[m3]' +'_' + name +
						 ';ecoulementEauSouterraine[m3]'+'_' + name+
						 ';pluie[m3]'+'_' + name;
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
				// JV 060219: adaptation en [m3] au lieu de [mm]
						

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
			 		SurfaceTotale <- SurfaceTotale + surface;
					RU <- RU + float(sum(mapTeneurEnEauSolParCouche.values)) * surface;
					RULast <- RULast + float(getPercolationDerniereCouche()) * surface;
					EntreeAquiferes <- EntreeAquiferes + float(eauEntreeAquiferes) * surface;
	   			 	AquifereProfond <- AquifereProfond + float(eauAquifereProfond) * surface;
	   			 	Recap <- Recap + float(eauRevap) * surface;
	   			 	AquiferePeuProfond <- AquiferePeuProfond + float(eauStockeeAquiferePeuProfond) * surface;
				}

				/*
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
				*/

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
			 		SurfaceTotale_RPG <- SurfaceTotale_RPG + surface ;
	   			 	EntreeAquiferes_RPG <- EntreeAquiferes_RPG + float(eauEntreeAquiferes) * surface;
	   			 	AquifereProfond_RPG <- AquifereProfond_RPG + float(eauAquifereProfond) * surface;
	   			 	Recap_RPG <- Recap_RPG + float(eauRevap) * surface;
	   			 	AquiferePeuProfond_RPG <- AquiferePeuProfond_RPG + float(eauStockeeAquiferePeuProfond) * surface;
				}
				
				
				// on somme les volumes des HRU non RPG et des HRU RPG:
				SurfaceTotale <- SurfaceTotale + SurfaceTotale_RPG;
				ETR <- ETR + ETR_RPG;
				RU <- RU + RU_RPG;
				RULast <- RULast + RULast_RPG;
				EntreeAquiferes <- EntreeAquiferes + EntreeAquiferes_RPG;
				AquifereProfond <- AquifereProfond + AquifereProfond_RPG;
				Recap <- Recap + Recap_RPG;
				AquiferePeuProfond <- AquiferePeuProfond + AquiferePeuProfond_RPG;
				Ruissellement <- Ruissellement + Ruissellement_RPG;
				ecoulementLat <- ecoulementLat + ecoulementLat_RPG;
				ecoulementEauSout <- ecoulementEauSout + ecoulementEauSout_RPG;
				
				float pluie_m3 <- pluie * SurfaceTotale; // car [mm] de pluie connus au niveau de la ZH
																
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
						';' + pluie_m3;												 						
			 }
					
			return data;
		 }			  			 
	}
	
	

