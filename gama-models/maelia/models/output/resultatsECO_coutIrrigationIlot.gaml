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
 *  resultatsECO_coutIrrigationIlot
 *  Author: Romain Lardy
 *  Description: 
 */

model resultatsECO_coutIrrigationIlot

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
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	action initialisationEcritureECO_coutIrrigationIlot{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers cout Irrigation moyen par Ilot...';		
		
		create resultatsECO_coutIrrigationIlot number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsECO_coutIrrigationIlot parent: ecritureResultats{
	list<ilot> listeIlotsIrrigable <- listeIlots where each.isIrrigable;
	/*
	 * @Overwrite
	 */

	string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/eco_coutIrrigationIlot'+ nomDeLaSimulation + '.csv';
		string dataAnnee <- 'ANNEE;ID_ILOT;COUT';
		return dataAnnee;	
	}

 
	/*
	 * @Overwrite
	 */	 
	 string ecritureFinAnnuelle{
	 	string data <-  '' ;
	 	bool first <- true;
	 	float surf <- 0.0;
	 	float cout <- 0.0;
	 	ask listeIlotsIrrigable{
	 		surf <- 0.0;
	 		cout <- 0.0;
	 		ask listeParcelles{
	 			if(coutIrrigationSurAnnee > 0.0){
	 				cout <- cout + coutIrrigationSurAnnee;
	 				surf <- surf + surface; //[m2]
	 			}
	 		}
	 		if(surf > 0.0){
	 			if(first){
	 				first <- false;
	 			}else{
	 				data <- data + "\n";
	 			}
	 			data <- data + (dateCour.annee)+ ";"+self.id + ";" + (cout/(surf/nombreMeterCarreDansUnHectare)) with_precision 1;
	 		}
		}	 	
	 	return data;
	 }
		 
}

