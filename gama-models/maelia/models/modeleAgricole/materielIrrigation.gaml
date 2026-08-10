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
 *  Bloc
 *  Author: Romain Lardy
 *  Description: le bloc est un ensemble de parcelles considerer comme un ensemble
 *  homogene lors de la gestion de l'assolement
 */

model materielIrrigation

import "../modeleCommun/donneesGlobales.gaml" 


global{	
	string fichierMateriel <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/materiel.csv';
	map<string,materielIrrigation> mapMateriel <- map([]);
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action initialisationMateriel{
				
		if (file_exists(fichierMateriel)){
			matrix InitMateriel <- matrix(csv_file(fichierMateriel,";",false));
	 		int nbLignes <- length(InitMateriel column_at 0);
	 		loop i from: 1 to: (nbLignes -1){ //boucle sur le materiel
	 			list<string> ligneCourante <- (InitMateriel row_at i) as list<string>;
	 			string id <- ligneCourante at (0);
	 			create materielIrrigation returns: mat{
	 				idMateriel <- id;
	 				surfaceIrrigableParJour <- float(ligneCourante at (1)) * nombreMeterCarreDansUnHectare;
	 				tempsDeTravailParJour <- float(ligneCourante at (2));
	 			}
	 			put first(mat) at: id in: mapMateriel;
	 	    }
	 	    // JV 290622 matériels correspondant aux jokers 'sans' et 'NA'
	 	   	mapMateriel["sans"] <- nil;
	 	   	mapMateriel["NA"] <- nil;	 	   	
		}else{
			do raiseWarning("fichier inexistant: " + fichierMateriel + "\nun matériel par défaut sera utilisé: 2,5 ha/jour et 1h de travail par jour");
			//write "Attention le fichier du materiel d'irrigation est inexistant ";
			//write "un materiel par defaut sera utilise : 2.5 ha/jour et 1 H de travail/jour";
			create materielIrrigation returns: mat{}
			put first(mat) at: "" in: mapMateriel;
		}
	}
			 			
}

species materielIrrigation {
	string idMateriel <- '';
	float surfaceIrrigableParJour <- 2.5;
	float tempsDeTravailParJour <- 1.0;
}
