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

model resultatsAS_HRU

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
	action initialisationEcritureFichiersAS_HRU{
		//do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails hydrologie...';		
		
		create resultatsAS_HRU number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsAS_HRU parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resAS_HRU'+ nomDeLaSimulation + '.csv';
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

			/* JV 260618
			 * 
			 * ET[mm] ETR = ZH.volumeEvapotranspirationHydro [m3] à diviser par somme des surfaces des HRU  pour [mm]
			 * 
			 * SwFin[mm] RU = somme sur les HRU des mapTeneurEnEauSolParCouche.values [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * 
			 * Perc[mm] RULast = somme sur les HRU des getPercolationDerniereCouche [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * 
			 * eauEntreeAquiferes[mm] EntreeAquiferes = somme sur les HRU des eauEntreeAquiferes [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * (HRU.eauEntreeAquiferes calculée dans HRU.calculEcoulementEauSouterraine)
			 * 
			 * eauAquifereProfond[mm] AquifereProfond = somme sur les HRU des eauAquifereProfond [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * (HRU.eauAquifereProfond calculée dans HRU.calculEcoulementEauSouterraine)
			 * 
			 * Recap[mm] Recap = somme sur les HRU des eauRevap [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * (HRU.eauRevap calculée dans HRU.calculEcoulementEauSouterraine)
			 * 
			 * eauStockeeAquiferePeuProfond[mm] AquiferePeuProfond = somme sur les HRU des eauStockeeAquiferePeuProfond [mm] * suface HRU -> somme de volumes [m3] à diviser par somme des surfaces des HRU pour [mm]
			 * (HRU.eauStockeeAquiferePeuProfond calculée dans HRU.calculEcoulementEauSouterraine)
			 * attention ne pas prendre ZH.volumeUtilePourPrelevementsNappes car déjà agrégé au niveau HRU + HRU_RPG (et en prenant les volumes de J-1 pour les HRU_RPG)
			 * 
			 * ruissellementDeSurfaceHRU[mm] Ruissellement = ZH.volumeRuissellementDeSurfaceHydro [m3] à diviser par somme des surfaces des HRU  pour [mm]
			 * 
			 * ecoulementLateral[mm] ecoulementLat = ZH.volumeEcoulementLateralHydro [m3] à diviser par somme des surfaces des HRU  pour [mm]
			 * 
			 * ecoulementEauSouterraine[mm] ecoulementEauSout = ZH.volumeEcoulementEauSouterraineHydro [m3] à diviser par somme des surfaces des HRU  pour [mm]
			 * 			  
			 * sommes sur les HRU: on pondère les [mm] par des [km2] dans la boucle donc en divisant le total par des [km2] on retombe bien sur des [mm]
			 * 
			 * volumes récupérés depuis ZH: ETR, ruissellement, ecoulementLat, ecoulementEauSout: on récupère des [m3] et on diviser par la somme des surfaces des HRU en [km2] pour avoir des [mm]
				 on veut en [mm] donc conversion: ETR[m3] * 1e9 (nb mm3 dans un m3) / (SurfaceTotale[km2] * 1e12 (nb mm2 dans un km2)) -> [mm3]/[mm2] = [mm]
				 comme on ne peut pas représenter la valeur 1e12 en int (max: 2.147483647E9) on va simplifier dans la fraction:
				 ETR           * 1e9           ETR
				 -------------------- = -------------------
				 SurfaceTotale * 1e12   SurfaceTotale * 1e3
			 * 
			 */
 
			ask listeZonesHydrographiques{
				
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

				// cf. explications au-dessus
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
			 	
/* ancienne version   
			 	ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
			 		SurfaceTotale <- SurfaceTotale + float(getSurfaceKm2()) ;
	   			 	ETR <- ETR + float(evapoTranspirationReelle) ;
	   			 	RU <- RU + float(sum(mapTeneurEnEauSolParCouche.values)) ;
	   			 	RULast <- RULast + float(getPercolationDerniereCouche()) ;
	   			 	EntreeAquiferes <- EntreeAquiferes + float(eauEntreeAquiferes) ;
	   			 	AquifereProfond <- AquifereProfond + float(eauAquifereProfond) ;
	   			 	Recap <- Recap + float(eauRevap) ;
	   			 	AquiferePeuProfond <- AquiferePeuProfond + float(eauStockeeAquiferePeuProfond) ;
	   			 	Ruissellement <- Ruissellement + float(ruissellementDeSurfaceHRU) ;
	   			 	ecoulementLat <- ecoulementLat + float(ecoulementLateral) ;
	   			 	ecoulementEauSout <- ecoulementEauSout + float(ecoulementEauSouterraine) ;
				}

*/

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

