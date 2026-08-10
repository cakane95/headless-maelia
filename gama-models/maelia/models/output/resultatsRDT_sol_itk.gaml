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

model resultatsRDT_sol_itk

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
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
	action initialisationEcritureFichiersRDT_sol_itk{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers RDT...';		
		
		create resultatsRDT_sol_itk number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsRDT_sol_itk parent: ecritureResultats{
	map<string,list<parcelle>> mapParcellesParTypeDeSol <- map([]);
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/rendements_sol_itk'+ nomDeLaSimulation + '.csv';	
		string dataDerniereProd <- '' + detailSimulation + '\nannee;ZonePedo;itk;RDT;surface';
		

		loop zoneP over: listNomZonePedo{
			list<parcelle> tmp <- listeParcellesUtiles where (each.ilot_app.getNomZonePedo()=zoneP);
			put tmp in: mapParcellesParTypeDeSol at: zoneP; 
		}

		
		return dataDerniereProd;
	 }

 	
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{			 		 			 		
		string data <- '' ;
		bool premiere_donnee <- true;
		
		loop it over: itk {
			loop zoneP over: mapParcellesParTypeDeSol.keys{
				list<parcelle> listeParcelles1ZoneP <- listeParcellesUtiles where (each.ilot_app.getNomZonePedo()=zoneP);
				float RDT<- 0.0;
				float Surface<- 0.0;
				loop parc over: listeParcelles1ZoneP { //where (length(each.itkRecolteSurAnnee > 0)
					if (length(parc.itkRecolteSurAnnee) > 0){
						loop i from: 0 to: (length(parc.itkRecolteSurAnnee) -1){
							if(parc.itkRecolteSurAnnee[i]=it){
								RDT <- RDT + parc.rdtRecolteSurAnnee[i]; //itkRecolteSurAnnee
								Surface <- Surface + parc.surface; ///(parc.surface * nombreMeterCarreDansUnHectare)
							}
						}
					}
				}
				if (Surface > 0.0){
					if (premiere_donnee){
						premiere_donnee <- false;
					}else{
						data <- data + '\n';
					}
					data <- data + dateCour.annee+';'+
							zoneP+";" +
							it.nomPourAffichage+";" + 
							(RDT/Surface*nombreMeterCarreDansUnHectare) with_precision 2  //pour avoir un rdt en t/ha
							+";" + (Surface/nombreMeterCarreDansUnHectare) with_precision 2;
				}
			}
		}										
//			loop it over: (itk as list){
//				loop zoneP over: listNomZonePedo{
//					float RDT<- 0.0;
//					float Surface<- 0.0;
//					loop agri over: listeAgriculteurs{
//						ask (agri.listMemoire) where ((each.itkAssocie = it) and (each.blocMemoire.zonePedo =zoneP)){ 
//							RDT <- RDT + getMoyenneRendementsAnneeEnCours() *getSurfaceAnneeEnCours();
//							Surface <- Surface + getSurfaceAnneeEnCours();
//						}
//					}
//					if (Surface>0.0){
//						if (init){
//							init <- false;
//						}else{
//							data <- data + '\n';
//						}
//						data <- data + dateCour.annee+';'+
//								zoneP+";" +
//								it.nomPourAffichage+";" + 
//								(RDT/Surface*nombreMeterCarreDansUnHectare) with_precision 2  //pour avoir un rdt en q/ha
//								+";" + (Surface/nombreMeterCarreDansUnHectare) with_precision 2;
//					}
//				} 
//			}		
		return data;	
	 }	
		 
}

