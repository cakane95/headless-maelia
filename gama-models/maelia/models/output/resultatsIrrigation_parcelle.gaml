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
*  resultatsIrrigation_parcelle
*  Author: Jean Villerd
*  Description: 
 */

model resultatsIrrigation_parcelle

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
      action initialisationEcritureFichiersIrrigation_parcelle {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers irrigation par parcelle...';           
            
            create resultatsIrrigation_parcelle number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
            }
      }                 
}


species resultatsIrrigation_parcelle parent: ecritureResultats {
      map<string,list<parcelle>> mapParcellesParExploitation <- map([]);
      /*
            * @Overwrite
            */
      string initialisationJournalier{   
            nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/irrigation_parcelle'+ nomDeLaSimulation + '.csv';  
            
            // Ligne titre
            string data <- '' + detailSimulation + '\njour;exploitation;parcelle;culture;min temp;max temp;pluie [mm];irrigation [mm/m2]';
            
            return data;
      }

     
      /*
            * @Overwrite
            */
      string ecritureJournaliere{                                                      
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
                    	                      	
	                      if (premiere_donnee){
	                           premiere_donnee <- false;
	                      }else{
	                           data <- data + '\n';
	                      }
	                      
	                      // Inscription résultats
	                      data <- data + dateCour.annee + '/' + dateCour.mois + '/' + dateCour.jour + ";" +
	                                 exploit.id+";" + 
	                                 parc.idParcelle+";"+
	                                 parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee + ";" +
	                                 parc.ilot_app.meteo.tMin with_precision 2 +";"+
	                                 parc.ilot_app.meteo.tMax with_precision 2 +";"+
	                                 parc.ilot_app.meteo.pluie with_precision 2 +";"+
	                                 parc.irrigationReelle;
                       
                }
          }
                                                                      
            return data;      
      }    
            
}


