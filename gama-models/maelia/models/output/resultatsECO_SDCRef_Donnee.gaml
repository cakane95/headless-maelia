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

model resultatsECO_SDCRef_Donnee

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/bloc.gaml"
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
import "../modeleAgricole/marcheAgricole.gaml"

global{
	action initialisationEcritureFichiersECO_SDCRef_Donnee{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers ECO / SDCRef...';		
		
		create resultatsECO_SDCRef_Donnee number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsECO_SDCRef_Donnee parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/eco_SDC'+ nomDeLaSimulation + '.csv';	
		string data <- '' + detailSimulation + '\nannee;sdcRef'; 
		loop scenarioPrix over:listScenarioPrix{
			if(scenarioPrix = ''){
				data <- data + ';MargeBrute(Euro/ha);MargeSemiNette(Euro/ha)';	
			}else{
				data <- data + ';MargeBrute_'+scenarioPrix+'(Euro/ha);MargeSemiNette_'+scenarioPrix+'(Euro/ha)';	
			}
		}
		return data;
	 }

 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{			 		 			 		
		string data <- '';
		bool premierElem <- true; 
		loop sdc over: mapSystemesDeCultureDeRef.keys{ 
			bool premierScenario <- true;
			loop scenarioPrix over:listScenarioPrix{
				float margeBrute<- 0.0;
				float Surface<- 0.0;
				float margeSemiNette <- 0.0;
				loop agri over: listeAgriculteurs{
					ask (agri.listMemoire) where (each.blocMemoire.idSdcRefInitialDuBloc = sdc){
						map<especeCultivee, float> tmp <- ((leMarcheAgricole.prix_recoltes_par_scenario_par_annee at scenarioPrix) at dateCour.annee);
						float prixDeLEspece <- (tmp at itkAssocie.especeCultiveeITK);
						float margeBruteLoc <- getPrimes() + getProduction()*prixDeLEspece - getChargesOp() ;				
						margeBrute <- margeBrute + margeBruteLoc;
						Surface <- Surface + getSurfaceAnneeEnCours();
						margeSemiNette <- margeSemiNette + margeBruteLoc -getChargesFixes();
					}
				}
				if (Surface>0.0){
					if (premierElem){
						premierElem <- false;
					}else{
						if(premierScenario){
							data <- data + '\n' ;
						}
					}
					if(premierScenario){
						premierScenario <- false;
						data <- data + (dateCour.annee) + ";" +sdc ;
					}
					data <- data + 
							';' + (margeBrute/Surface*nombreMeterCarreDansUnHectare) with_precision 1 
							+ ';' + (margeSemiNette/Surface*nombreMeterCarreDansUnHectare) with_precision 1 ;
				}
			}					
		}
		return data;	
	 }	
		 
}

