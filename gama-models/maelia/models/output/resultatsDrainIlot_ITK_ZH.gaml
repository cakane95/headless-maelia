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
 *  resultatsAssolementAgri
 *  Author: Maelia
 *  Description: 
 */

model resultatsDrainIlot_ITK_ZH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"

global{
	action initialisationEcritureFichiersDrainIlot_ITK_ZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers DrainIlot_ITK_ZH...';		
		
		create resultatsDrainIlot_ITK_ZH number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsDrainIlot_ITK_ZH parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{	
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/DrainIlot_ITK_ZH'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date;ITK;ZH;drain;ruissellement;pluie;Irrigation;surface;humiditeSol';
		
		return dataJournaliere;	
	}

 
	/*
	 * @Overwrite
	 */
	string ecritureJournaliere{
		string data <-  '';
		string dateCour_str <- '' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
		bool NotFirstElem <- false;
		loop it over: (itk as list){
			loop zh over: listeZonesHydrographiques{
				float drainMoy <- 0.0;
			 	float ruissellementMoy <- 0.0;
			 	float pluieMoy <- 0.0;
			 	float irrigationReelleMoy <- 0.0;
			 	float humiditeSolMoy <- 0.0;

			 	float surfTot <- 0.0;
			 	ask listeParcellesUtiles where (each.ilot_app.zoneHydroAssociee = zh and each.getITKAnnee() = it) { 
					drainMoy<- drainMoy + drain* surface; //Attention Drain en mm //[mm]*[m2]
					ruissellementMoy <- ruissellementMoy + quantiteEauDeRuissellement * surface ; // quantiteEauDeRuissellement en mm
					pluieMoy <- pluieMoy + getPluie() * surface ; //[mm]*[m2]
					irrigationReelleMoy <- irrigationReelleMoy + irrigationReelle * surface;
					humiditeSolMoy <-humiditeSolMoy +  getHumiditeSol()* surface;
					surfTot <- surfTot + surface	;
				}
				if (surfTot > 0.0){
					if (NotFirstElem){
						data <- data  + "\n";
						
					}else{
						NotFirstElem <- true;
					}
					data <- data + date +";"+ it.nomPourAffichage+";" + zh.idZoneHydrographique +";"+
						 (drainMoy/surfTot)  with_precision 2 + ";" + (ruissellementMoy/surfTot)  with_precision 2 + ";"
						 + (pluieMoy/surfTot) with_precision 2 + ";"
						 + (irrigationReelleMoy/surfTot) with_precision 2 + ";"
						  + (surfTot/10000) with_precision 2 + ";"
						  + (humiditeSolMoy/surfTot) with_precision 2;
				}
			}
				
		}			
	 	return data;		 			 	
	 }
		 
}

