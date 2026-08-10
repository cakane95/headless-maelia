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

model resultatsAssolement_SDC

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
import "../modeleAgricole/materielIrrigation.gaml"

global{
	action initialisationEcritureFichiersAssolement_SDC{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers assolement agriculteurs...';		
		
		create resultatsAssolement_SDC number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsAssolement_SDC parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		//nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/assolement_SDC'+ nomDeLaSimulation + '.csv';
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/assolement_SDC'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detailSimulation + '\nannee';
		loop sdc over: mapSystemesDeCultureDeRef.values{ 
			list<itk> listITKPourUnMATERIEL <- first(sdc.mapRotationType);				
			string nomSDC <- sdc.name;
			loop it over: listITKPourUnMATERIEL{
				nomSDC <- nomSDC + "|" + it.especeCultiveeITK.name  ;
			}
			dataAnnuelle <- dataAnnuelle + ';' + nomSDC + '_NB'+ ';' + nomSDC + '_SURFACE(ha)';
		}
		return dataAnnuelle;
	 }

 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{	 	
	 	string data <- '' + (dateCour.annee);
	 	
	 	loop sdc over: mapSystemesDeCultureDeRef.values{ 
			int  NB<- 0;
			float Surface<- 0.0;
			loop parc over: listeParcellesUtiles where (each.systemeDeCultureParcelle.sdcRefAssocie = sdc){
				Surface <- Surface + parc.surface;
				NB <- NB + 1;
			}
			
			data <- data + ';' + NB + ';' + (Surface/10000.0) with_precision 2 ;

		}
		return data;
	 }			 
		 			 
}

