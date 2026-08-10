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

model resultatsECO_espece

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
import "../modeleAgricole/marcheAgricole.gaml"

global{
	action initialisationEcritureFichiersECO_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers ECO / espece...';		
		
		create resultatsECO_espece number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsECO_espece parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/eco_espece'+ nomDeLaSimulation + '.csv';	
		string data <- '' + detailSimulation + '\nannee'; //
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			loop scenarioPrix over:listScenarioPrix{
				if(scenarioPrix = ''){
					data <- data + ';MB_' + espece.idEspeceCultivee + ';MN_' + espece.idEspeceCultivee;
				}else{
					data <- data + ';MB_' +scenarioPrix + '_' + espece.idEspeceCultivee + ';MN_' +scenarioPrix + '_' + espece.idEspeceCultivee;
				}
			}
		}
		loop scenarioPrix over:listScenarioPrix{
			if(scenarioPrix = ''){
				data <- data + ';MB_Territoire' +  ';MN_Territoire' ;
			}else{
				data <- data + ';MB_'+scenarioPrix + '_' +'Territoire' +  ';MN_'+scenarioPrix + '_' +'Territoire' ;
			}	
		}
		return data;
	 }

 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{			 		 			 		
		string data <- '' + (dateCour.annee);
		map<string, float> MBTerritoire_ParScenarioDePrix <- map<string, float>([]);
		map<string, float> MNTerritoire_ParScenarioDePrix <- map<string, float>([]);
		float SurfaceTerritoire <- 0.0;
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 										
			loop scenarioPrix over:listScenarioPrix{

				float margeBrute<- 0.0;
				float Surface<- 0.0;
				float margeSemiNette <- 0.0;
				float Prod <- 0.0;
			
				loop agri over: listeAgriculteurs{
					ask (agri.listMemoire) where (each.itkAssocie.especeCultiveeITK = espece){
						float margeBruteLoc <- getPrimes() - getChargesOp() ;
						Prod <- Prod + getProduction();
								//(leMarcheAgricole.prix_recoltes at itkAssocie.especeCultiveeITK);
						
						margeBrute <- margeBrute + margeBruteLoc;
						Surface <- Surface + getSurfaceAnneeEnCours();
						margeSemiNette <- margeSemiNette + margeBruteLoc -getChargesFixes();
					}
				}
				
				map<especeCultivee, float> tmp <- ((leMarcheAgricole.prix_recoltes_par_scenario_par_annee at scenarioPrix) at dateCour.annee);
				float prixDeLEspece <- (tmp at espece);
				margeBrute <- margeBrute + Prod * prixDeLEspece; //// itkAssocie.especeCultiveeITK);
				margeSemiNette <- margeSemiNette + Prod * prixDeLEspece;
				
				if (Surface>0.0){
					data <- data + ';' + (margeBrute/Surface*nombreMeterCarreDansUnHectare) with_precision 1 
								 + ';' + (margeSemiNette/Surface*nombreMeterCarreDansUnHectare) with_precision 1 ;
					put ((MBTerritoire_ParScenarioDePrix at scenarioPrix) + margeBrute) at:scenarioPrix in:MBTerritoire_ParScenarioDePrix;
					put ((MNTerritoire_ParScenarioDePrix at scenarioPrix) + margeSemiNette) at:scenarioPrix in:MNTerritoire_ParScenarioDePrix;
					SurfaceTerritoire <- SurfaceTerritoire + Surface;
					
				}else{
					data <- data + ';;' ;
				}
			}//Fin boucle de prix	
		} // Fin boucle espece
		
		if(SurfaceTerritoire > 0.0){
			SurfaceTerritoire <- SurfaceTerritoire /length(listScenarioPrix);
			loop scenarioPrix over:listScenarioPrix{
				data <- data + ';' + ((MBTerritoire_ParScenarioDePrix at scenarioPrix)/SurfaceTerritoire*nombreMeterCarreDansUnHectare) with_precision 1 
						+ ';' + ((MNTerritoire_ParScenarioDePrix at scenarioPrix)/SurfaceTerritoire*nombreMeterCarreDansUnHectare) with_precision 1 ;
			}
		}
		return data;	
	 }	
		 
}

