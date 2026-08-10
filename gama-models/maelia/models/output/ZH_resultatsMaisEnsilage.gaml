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
 *  resultatsMaisEnsilage
 *  Author: david
 *  Description: 
 */

model ZH_resultatsMaisEnsilage

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
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
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersMaisEnsilage{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers assolement agriculteurs...';		
		
		create ZH_resultatsMaisEnsilage number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species ZH_resultatsMaisEnsilage parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/ZH_resultatsMaisEnsilage'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- "idZH;annee;surfMais;surfMaisEnsilage;taux";
		return dataAnnuelle;
	 }

 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	int numero <- 0;
	 	string data <- "";
	 	ask listeZonesHydrographiques{
		 	// Calcul surface mais ensilage et mais
		 	float surfMaisEns <- 0.0;
		 	float surfMais <- 0.0;		 	
		 	ask listeIlotsAssocies{
		 		ask listeParcelles{
		 			if(getITKAnnee().especeCultiveeITK.idEspeceCultivee = "mais_ensil"){
		 				surfMaisEns <- surfMaisEns + surface;
		 			}else if(getITKAnnee().especeCultiveeITK.idEspeceCultivee = "mais"){
		 				surfMais <- surfMais + surface;
		 			}
		 		}		 			
	 		}
	 		
	 		// Remplissage fichier		 		
	 		numero <- numero + 1;
	 		float tauxMaisEns <- 0.0;
	 		if(surfMaisEns + surfMais > 0.0){
	 			tauxMaisEns <- surfMaisEns / (surfMaisEns + surfMais);
	 		}
		 	data <-  	data + ''  + string(idZoneHydrographique) +	
						';' + (dateCour.annee) +
						';' + float(surfMais) +	
						';' + float(surfMaisEns) +	
						';' + float(tauxMaisEns); 
			if(numero < length(listeZonesHydrographiques)){
				data <- data + '\n';
			}	
	 	}		 		
	 	return data;		
	 }	 	
}

