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

model resultatsECO_SDCRef_FonctionsCroyances

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
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
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/marcheAgricole.gaml"

global{
	action initialisationEcritureFichiersECO_SDCRef_FonctionsCroyances{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers ECO / SDCRef...';		
		
		create resultatsECO_SDCRef_FonctionsCroyances number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsECO_SDCRef_FonctionsCroyances parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/eco_SDC'+ nomDeLaSimulation + '.csv';	
		string data <- '' + detailSimulation + '\nannee;sdcRef;MaterielIrrigation;Sol'; 
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
		loop sdc over: mapSystemesDeCultureDeRef.values{ 
			
			list<string> listIDMat <- ["NA"];
			if (sdc.parcelleIrrigableSdC){
				loop mat over: mapMateriel.keys {
					listIDMat << mat;
				}
			}
			loop mat over: listIDMat{
				loop SOL over: listNomZonePedo.keys{
					
					list<itk> listITKPourUnMATERIEL <- sdc.mapRotationType at (mat +"_"+ SOL) ;
					bool premierScenario <- true;
					loop scenarioPrix over:listScenarioPrix{
						float margeBrute<- 0.0;
						float margeSemiNette <- 0.0;
						int nbITK <- 0;
						loop it over: listITKPourUnMATERIEL{
							float margeBruteUnITK <- 0.0;
							float margeSemiNetteUnITK <- 0.0;
							int nb <- 0;
							loop agri over: listeAgriculteurs{
								ask (agri.listMemoire) where (each.itkAssocie = it){
									float Surface <- getSurfaceAnneeEnCours();
									if (Surface > 0.0){
										nb <- nb +1;
										map<especeCultivee, float> tmp <- ((leMarcheAgricole.prix_recoltes_par_scenario_par_annee at scenarioPrix) at dateCour.annee);
										float prixDeLEspece <- (tmp at itkAssocie.especeCultiveeITK);
										float margeBruteLoc <- getPrimes() + getProduction()*prixDeLEspece - getChargesOp() ;				
										margeBruteUnITK <- margeBruteUnITK + margeBruteLoc;
										Surface <- Surface + getSurfaceAnneeEnCours();
										margeSemiNetteUnITK <- margeSemiNetteUnITK + margeBruteLoc -getChargesFixes();
									}
								}
							}
							if (nb > 0){
								nbITK <- nbITK +1;
								margeBrute <- margeBrute + margeBruteUnITK/nb;
								margeSemiNette <- margeSemiNette + margeSemiNetteUnITK/nb;
							}
							
						}	
						if (nbITK = length(listITKPourUnMATERIEL)){ //Si on a bien au moins une valeur de marge pour chaque culture de la rotation
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
							loop it over: listITKPourUnMATERIEL{
								data <- data + "|" + it.nomPourAffichage  ;
							}
							data <- data + ';' +  mat + ';' + SOL ;
						}
							data <- data + 
									';' + (margeBrute/nbITK) with_precision 1 
									+ ';' + (margeSemiNette/nbITK) with_precision 1 ;
						}
					}
					
				}
				
			}
			
			
			
		}
		return data;	
	 }	
		 
}

