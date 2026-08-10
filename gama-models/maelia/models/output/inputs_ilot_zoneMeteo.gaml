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
*  Author: Renaud Misslin
*  Description: 
 */

model inputs_ilot_zoneMeteo

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
      action initialisationEcritureFichiersinputs_ilot_zoneMeteo {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputs_ilot_zoneMeteo';           
            
            create inputs_ilot_zoneMeteo number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
                  self.ecriture_realisee <- false;
            }
      }                 
}


species inputs_ilot_zoneMeteo parent: ecritureResultats {
      bool ecriture_realisee;
      /*
            * @Overwrite
            */
            
      string initialisationFinAnnuel {   
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/id_ilot_zoneMeteo.csv';  
		
		// Ligne titre
		string data <- '' + detailSimulation;
		
		// Ajout du nom de chaque parcelle à la ligne de titre
		string idIlots;
		string idZoneMeteo;
		
		// Titres des colonnes
		data <- data + "id;meteo.idZoneMeteo";
		
		loop current_ilot over: listeIlots {
			idIlots <- current_ilot.id;
			idZoneMeteo <- current_ilot.meteo.idZoneMeteo;
			
			data <- data + "\n" + idIlots + ";" + idZoneMeteo;
		}
		
		return data;
      }
      
}


