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

model resultatsRecolteParcelles

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
      action initialisationEcritureFichiersresultatsRecolteParcelles {
            do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers resultatsRecolteParcelles';           
            
            create resultatsRecolteParcelles number: 1{
                  do initialisation();
                  listesFichiersAcreer << self;
            }
      }                 
}


species resultatsRecolteParcelles parent: ecritureResultats {
      /*
            * @Overwrite
            */
            
      string initialisationFinAnnuel {   
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsRecolteParcelles'+ nomDeLaSimulation + '.csv';  
		
		// Ligne titre
		string data <- '' + detailSimulation;
		
		// Ajout du nom de chaque parcelle à la ligne de titre
		string idParcelles;
		string surfaceParcelles;
		
		loop p over: listeParcelles {
			if (empty(idParcelles)) {
				idParcelles <- p.idParcelle;
				surfaceParcelles <- string(p.surface);
			} else {
				idParcelles <- idParcelles + ";" + p.idParcelle;
				surfaceParcelles <- surfaceParcelles + ";" + p.surface;
			}
		}
		data <- data + "\nidParcelles" + idParcelles + "\nsurfaceParcelles" + surfaceParcelles;
		return data;
      }

     
      /*
            * @Overwrite
            */
      string ecritureFinAnnuelle {
            string data <- string(first(dateCourante).annee);
            // Inscription de l'espece récoltée dans l'année pour chaque parcelle
            loop p over: listeParcelles {
            	// Pour chaque parcelle, le résultat est donné sous la forme suivante : culture|rendement
            	if (p.dernier_rendement > 0) {
            		data <- data + ";" + p.derniere_culture_recoltee + "|" + p.dernier_rendement;
            	} else {
            		data <- data + ";";
            	}
            	
            	// Remise à 0 des résultats annuels de la parcelle (attention aux conflit avec resultatsRDT_exploitation_espece, je n'ai pas testé les deux ensemble mais ca posera peut-être problème selon lequel est enregistré en premier)
            	p.derniere_culture_recoltee <- "";
				p.dernier_rendement <- 0.0;
				p.dateSemiDerniereCultureRecoltee <- "";
				p.culture_recoltee_dans_lannee <- ""; // cf resultatRecolteParcelle.gaml
            }
			
            return data;      
      }
}


