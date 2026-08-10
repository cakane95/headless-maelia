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

model resultatsRDT_itk

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
	action initialisationEcritureFichiersRDT_itk{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers RDT...';		
		
		create resultatsRDT_itk number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}

species resultatsRDT_itk parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/rendements_itk'+ nomDeLaSimulation + '.csv';	
		string dataDerniereProd <- '' + detailSimulation + '\nannee';
		loop it over: (itk as list){ 
			dataDerniereProd <- dataDerniereProd + ';' + it.nomPourAffichage ;
		}
		return dataDerniereProd;
	 }

 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{			 		 			 		
		string data <- '' + (dateCour.annee);										
		loop it over: (itk as list){
			float RDT<- 0.0;
			float Surface<- 0.0;
			loop agri over: listeAgriculteurs{
				ask (agri.listMemoire) where (each.itkAssocie = it){
					RDT <- RDT + getMoyenneRendementsAnneeEnCours() *getSurfaceAnneeEnCours();
					Surface <- Surface + getSurfaceAnneeEnCours();
				}
			}
			if (Surface>0.0){
				data <- data + ';' + (RDT/Surface*nombreMeterCarreDansUnHectare) with_precision 2 ;//pour avoir un rdt en t/ha
			}else{
				data <- data + ';' ;
			}
		}		
		return data;	
	 }	
		 
}

