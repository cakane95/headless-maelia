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

model inputs_sol_Parcelles

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
      action initialisationEcritureFichiersinputs_sol_Parcelles {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputs_sol_Parcelles';           
            
            create inputs_sol_Parcelles number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
                  self.ecriture_realisee <- false;
            }
      }                 
}


species inputs_sol_Parcelles parent: ecritureResultats {
      bool ecriture_realisee;
      /*
            * @Overwrite
            */
            
      string initialisationFinAnnuel {   
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/inputs_sol_Parcelles'+ nomDeLaSimulation + '.csv';  
		
		// Ligne titre
		string data <- '' + detailSimulation;
		
		// Ajout du nom de chaque parcelle à la ligne de titre
		string idParcelles;
		string solParcelles;
		string surfParcelles;
		string materielIrrParcelles;
		
		
		// Titres des colonnes
		data <- data + "idParcelles;sol;surface[m2];materiel_irrigation";
		
		loop p over: listeParcelles {
			if (empty(idParcelles)) {
				idParcelles <- p.idParcelle;
				solParcelles <- string(p.surface);
				surfParcelles <- string(p.surface);
				materielIrrParcelles <- string(p.surface);
			} else {
				idParcelles <- p.idParcelle;
				solParcelles <- p.ilot_app.sol.nom;
				surfParcelles <- string(p.surface);
				materielIrrParcelles <- string(p.ilot_app.materielIlot);
				
			}
			
			data <- data + "\n" + idParcelles + ";" + solParcelles + ";" + surfParcelles + ";" + materielIrrParcelles;
		}
		
		return data;
      }
      
}


