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
 *  SIR
 *  Author: maroussia
 *  Description: 
 */

model resultatsDetailsGroupeIrrigation

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Cultures/culture.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"  
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/StrategiesIrrigation/strategieIrrigation.gaml"
import "../modeleAgricole/strategieOT.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersDetailsGroupeIrrigation{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers DetailsGroupeIrrigation...';		
		
		create resultatsDetailsGroupeIrrigation number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsDetailsGroupeIrrigation parent: ecritureResultats{


	
	/*
	 * @Overwrite
	 */
	 string initialisationDebutAnnuel{
	 	string detail <- detailSimulation + '\n';			
		nomFichierDebutAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/groupesIrrigation'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- 'annee;idAgri;materiel;ZA;TD;idGrpITK;surfaceTotale;NbParcelles';
		
		return dataAnnuelle;	 			 		 	
	 } 	
	 
	 //ecritureDebutAnnuelle		
	 /*
	 * @Overwrite
	 */
	 string ecritureDebutAnnuelle{
	 	string data <- "";
	 	bool premierGroupe <- true;
	 	ask groupeIrrigation as list{
	 		if (premierGroupe){
	 			premierGroupe <- false;
	 		}else{
	 			data <- data +"\n";
	 		}
	 		data <- data +dateCour.annee + ";"+
			agriculteurAssocie.idAgriculteur + ";"+
			materielAssocie.idMateriel + ";";
			if (zaAssociee !=nil){
				data <- data + zaAssociee.idZoneAdministrative +";" ;
			}else{
				data <- data + "NA" +";" ;
			}
			data <- data + itkAssocie.strategieIrrigationITK.periodeTourEau + ";" +
			itkAssocie.strategieIrrigationITK.idGRP + ";" +
			surfaceTotale / 10000.0 with_precision 2 + ";"  + 
			length(parcellesIrrigable) + ";";
	 	}
	 	
	 	return data;			 		 	
	 } 	 			 
}

