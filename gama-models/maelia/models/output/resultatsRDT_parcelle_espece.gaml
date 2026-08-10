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
*  resultatsRDT_parcelle_espece
*  Author: Jean Villerd
*  Description: 
 */

model resultatsRDT_parcelle_espece

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
      action initialisationEcritureFichiersRDT_parcelle_espece {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers RDT...';           
            
            create resultatsRDT_parcelle_espece number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
            }
      }                 
}


species resultatsRDT_parcelle_espece parent: ecritureResultats {
      map<string,list<parcelle>> mapParcellesParExploitation <- map([]);
      /*
            * @Overwrite
            */
      string initialisationFinAnnuel{   
            nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/rendements_parcelle_espece'+ nomDeLaSimulation + '.csv';  
            
            // Ligne titre
            string dataDerniereProd <- '' + detailSimulation + '\nannee;Espece;Exploitation;Parcelle;RDT [t/ha];surface [ha]';
            
            loop exploit over: exploitation {
                  list<parcelle> tmp;
                  ask (exploitation as list){
                        tmp <- (listeIlots + listeIlotsHorsZone) accumulate (each.listeParcelles);
                  }
                  put tmp in: mapParcellesParExploitation at: exploit.id;    
            }

            
            return dataDerniereProd;
      }

     
      /*
            * @Overwrite
            */
      string ecritureFinAnnuelle{                                                      
            string data <- '' ;
            bool premiere_donnee <- true;
            
              // Exploitation
              loop exploit over: exploitation {
                   // write "exploitation = " + exploit.id;
                    list<parcelle> listeParcelles1Exploit;
                    ask (exploit){
                          listeParcelles1Exploit <- (listeIlots + listeIlotsHorsZone) accumulate (each.listeParcelles);
                    }
                                                                  
                    // Parcelle
                    loop parc over: listeParcelles1Exploit {
                        float production <- 0.0; // [q]
                        string harvestedCrop <- "";
                        float surfaceM2 <- parc.surface; // [m2]
                        float surfaceHa <- surfaceM2/nombreMeterCarreDansUnHectare; //[ha]                  
                     	 //if(parc.mapRotationSimulee at dateCour.annee != nil) {
                      	int nbHarvestCropsThisYear <- length(parc.rdtRecolteSurAnnee);
                      	
                      if(nbHarvestCropsThisYear>0){
                                            	                      
	                      	loop i from: 0 to: (nbHarvestCropsThisYear-1){
	                                     
	            	             production <- parc.rdtRecolteSurAnnee[i];
	            	             harvestedCrop <- parc.itkRecolteSurAnnee[i].especeCultiveeITK.idEspeceCultivee;
	                                     
	                             /*string cropList <- "";
	                             ask parc.itkRecolteSurAnnee{
	                             		cropList <- cropList + especeCultiveeITK.idEspeceCultivee + ",";
	                             }*/
	                             
		                        if (surfaceHa > 0.0){
		                              if (premiere_donnee){
		                                   premiere_donnee <- false;
		                              }else{
		                                   data <- data + '\n';
		                              }
		                              
		                              // Inscription résultats
		                              data <- data + dateCour.annee +';'+
		                              			harvestedCrop + ";" +
		                                         exploit.id + ";" + 
		                                         parc.idParcelle + ";" +
		                                         (production/surfaceHa) with_precision 2 + ";" +
		                                         surfaceHa with_precision 2;
		                                         
		                        }// if (surfaceHa > 0.0){
	                        } // loop i from: 1 to: nbHarvestCropsThisYear{
                        } // if(nbHarvestCropsThisYear>0){
                    } //  loop parc over: listeParcelles1Exploit {
            } // loop exploit over: exploitation {                                                          

            return data;      
      }    
            
}


