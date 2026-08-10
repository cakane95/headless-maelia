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

model resultatsIrrigation_debug

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
      action initialisationEcritureFichiersIrrigation_debug {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers irrigation debug...';           
            
            create resultatsIrrigation_debug number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
            }
      }                 
}


species resultatsIrrigation_debug parent: ecritureResultats {
      /*
            * @Overwrite
            */
 
     string initialisationDebutAnnuel{   

			// JV pour debug dans strategieIrrigation.isActivitePossible
			//string chaineDebug <- "annee;jour;parcelle;itk;ppaDispo;enRestriction;derogatoire;pluiePrevue;pluieMoinsEtp;surfaceIrrigableGrp;satisfHydriqueSol;applicationRetard;isHumidSolOK;nbIrrig;periodeTourEau;nbGrpIrrigCult;estOk";
			//save chaineDebug to: (cheminRelatifDuDossierDeSortieDeSimulation + "/irrigationIsActivitePossible.csv") type: 'text' rewrite: false; 

            nomFichierDebutAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/irrigation_groupes'+ nomDeLaSimulation + '.csv';  
            
            // Ligne titre
            string data <- 'annee;jour;exploitation;parcelle;surfaceParcelle;ITK;id_groupeIrrigationCulture;id_interne;surfaceGroupeIrrigationCulture;fractionParcelle;id_groupeIrrigationAssocie;id_interne;idMateriel;isIrrigation;ITKassocie;parcellesIrrigables';
            
            return data;
      }
      
      string ecritureDebutAnnuelle{
      	
   		write "ecritureDebutAnnuelle";
   		
   		// on récupère tous les groupeIrrigationCulture à partir des parcelles (on pourrait faire un ask sur l'espèce groupeIrrigationCulture mais c'est pour être certain de ne récupérer que les groupes "actifs"
   		list<groupeIrrigationCulture> tousGroupesIrrigationCulture <- [];
   		ask listeParcelles{
   			//if ilot_app.codeExploitationAssociee = "082-367492"{
   				tousGroupesIrrigationCulture <- tousGroupesIrrigationCulture union listeGroupeIrrigationCulture;   			
   			//}
   		}

      	string data <- "";
      	
      	// une ligne par groupeIrrigationCulture
      	ask tousGroupesIrrigationCulture{
      		
      		string ligne <- "" + dateCour.annee + ";" + dateCour.nbJoursEcoulesDansAnnee;
      		ligne <- ligne + ";" +	parcelleAssociee.ilot_app.codeExploitationAssociee;
      		ligne <- ligne + ";" + parcelleAssociee.idParcelle + ";" + parcelleAssociee.surface + ";" + parcelleAssociee.getITKAnnee().idITK;
      		ligne <- ligne + ";" + indiceGroupe + ";" + name + ";" + surface + ";" + getFraction();
      		if groupeAssocie!=nil {
      			ligne <- ligne + ";" + groupeAssocie.id + ";" + groupeAssocie.name + ";" + groupeAssocie.materielAssocie.idMateriel + ";" + groupeAssocie.isIrrigation + ";" + groupeAssocie.itkAssocie.idITK + ";" + groupeAssocie.parcellesIrrigable.keys collect (each.idParcelle + ";" + groupeAssocie.parcellesIrrigable[each]);
			}else{
      			ligne <- ligne + ";" + "" + ";" + ";" + ";" + ";" + ";" + ";" + ";" + ";" + ";" + ";";				
			}
			data <- data + "\n" + ligne;
		}
		
      	return data;
      
     }
             
}


