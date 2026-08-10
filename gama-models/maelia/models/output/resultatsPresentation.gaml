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
 *  resultatsPresentation
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model resultatsPresentation

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"

global{
	action initialisationEcritureFichiersPresentation{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPresentation number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


	species resultatsPresentation parent: ecritureResultats{
		list<parcelle> listesParcellesDeLaZH <- [];

		/*
		 * @Overwrite
		 */
//		string initialisationJournalier{
//			// init listesParcellesDeLaZH
//			listesParcellesDeLaZH <- listeParcelles;// where (each.ilot_app.zoneHydroAssociee.idZoneHydrographique = "O060");
////			write "[OUT] listesParcellesDeLaZH = " + listesParcellesDeLaZH;
//			
//			string detail <- detailSimulation + '\n';			
//			nomFichierJournalier <- 'log/prelevements_Journalier_parEspece_IRR'+ nomDeLaSimulation + '.csv';
//			let dataJournaliere type: string value: '' + detail + '\ndate';
//			ask (especeCultivee as list){ 
//				dataJournaliere <- dataJournaliere + ';' + idEspeceCultivee + "_Irr[m3]" + ';' + idEspeceCultivee + "_pluie[m3]";
//			}
//			return dataJournaliere;	
//		}

		/*
		 * @Overwrite
		 */
		 string initialisationDebutAnnuel{			
			string detail <- detailSimulation + '\n';			
			nomFichierDebutAnnuel <- 'log/especeParParelleParAnnee'+ nomDeLaSimulation + '.csv';
			let dataAnnuelle type: string value: '' + detail + '\nannee;idParcelle;espece;isParcellePincipale' +
			';date de dernier semis;dernier itk reealise;dateDerniereRecolte';
			return dataAnnuelle;	 	
		 }
		
//		/*
//		 * @Overwrite
//		 */
//		 string initialisationFinAnnuel{			
//			string detail <- detailSimulation + '\n';			
//			nomFichierFinAnnuel <- 'log/sommeSurfaceParEspece'+ nomDeLaSimulation + '.csv';
//			let dataAnnuelle type: string value: '' + detail + '\nannee';
//			ask (especeCultivee as list){ 
//				dataAnnuelle <- dataAnnuelle + ';' + nom;
//			}
//			return dataAnnuelle;	 	
//		 }

		/*
		 * @Overwrite
		 */
//		 string ecritureJournaliere{
//			string data <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);	
//			
//			// On parcours les parcelles est on stocke par espece
//			map<especeCultivee,float> mapIrr <- map([]);
//			map<especeCultivee,float> mapPluie <- map([]);
//			ask(listesParcellesDeLaZH){
//				if(getITKAnnee() != nil){
//					float volume <- (mapIrr at getITKAnnee().especeCultiveeITK) + getVolumeIrrigueReel();	
//					put volume at: getITKAnnee().especeCultiveeITK in: mapIrr;
//					
//					float volumePluie <- (mapPluie at getITKAnnee().especeCultiveeITK) + getVolumePluie();	
//					put volumePluie at: getITKAnnee().especeCultiveeITK in: mapPluie;
//				}							
//			}
//			ask (especeCultivee as list){
//				if((mapIrr at self) != nil){
//					data <- data + ';' + (mapIrr at self)
//								 + ';' + (mapPluie at self);
//				}else{
//					data <- data + ';0.0'
//								 + ';0.0';
//				} 				
//			}
//		 	
//		 	return data;		 			 	
//		 }
//
		/*
		 * @Overwrite
		 */
		 string ecritureDebutAnnuelle{		 	
		 	int numero <- 0;
		 	string data <- '';	
		 	//ask(listesParcellesDeLaZH){
		 	ask((parcelleAqYield as list)){	
		 		numero <- numero + 1;
		 		string isParcPrincipale <- "N";
		 		
		 		if(getITKAnnee() != nil){
		 			if(self = ilot_app.parcellePrincipale){
			 			isParcPrincipale <- "O";
			 		}
					data <-  data + (dateCour.annee) +										
								';' + idParcelle +
								';' + getITKAnnee().especeCultiveeITK +
								';' + isParcPrincipale +';' + 
								dateDernierSemi + ';' + itkAnnePrec+ ';' +
								idJourDerniereRecolte +'\n';
					if(numero < length(myself.listesParcellesDeLaZH)){
						data <- data + '\n';
					}				 			
		 		}	 		
		 	}			
			return data;			 					 				
		 }	
		 
//		/*
//		 * @Overwrite
//		 */
//		 string ecritureFinAnnuelle{	
//			string data <-  	'' + (dateCour.annee);
//				
//			// On parcours les parcelles est on stocke par espece
//			map<especeCultivee,float> mapIrr <- map([]);
//			ask(listesParcellesDeLaZH){
//				if(ITK_annee != nil){
//					float sommeSurf <- (mapIrr at ITK_annee.especeCultiveeITK) + surface;	
//					put sommeSurf at: ITK_annee.especeCultiveeITK in: mapIrr;
//				}							
//			}	
//								
//			ask (especeCultivee as list){
//				if((mapIrr at self) != nil){
//					data <- data + ';' + (mapIrr at self);
//				}else{
//					data <- data + ';0.0';
//				} 				
//			}			
//			return data;			 					 				
//		 }		 			 
	}

