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
 *  Author: Maelia
 *  Description: 
 */

model resultatsDrainIlotMensuel

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
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	action initialisationEcritureFichiersDrainIlotMensuel{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers DrainIlotMensuel...';		
		
		create resultatsDrainIlotMensuel number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsDrainIlotMensuel parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationMensuelle{	
		nomFichierMensuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/DrainIlotMensuel'+ nomDeLaSimulation + '.csv';
		string dataMensuelle <- 'date;drain;ruissellement;ETR';
		
		return dataMensuelle;	
	}

 
	/*
	 * @Overwrite
	 */
	string ecritureMensuelle{
		string data <-  '' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);			
	 	float drainMoy <- 0.0;
	 	float ruissellementMoy <- 0.0;
	 	float ETRMoy <- 0.0;
	 	float surfTot <- 0.0;
		ask listeIlots {
			drainMoy <- drainMoy + drainIlotCumulMois; //[m3]
			ruissellementMoy <- ruissellementMoy + ruissellementIlotCumulMois; //[m3]
			ETRMoy <- ETRMoy + ETRIlotCumulMois; //[m3]
			surfTot <- surfTot + surfaceParcellesUtiles	;
		}
		// moyenne spatiale
		drainMoy <- drainMoy/surfTot;
		ruissellementMoy <- ruissellementMoy/surfTot;
		ETRMoy <- ETRMoy/surfTot;
		
	 	data <- data +";"+ (drainMoy * nombreMillimetreDansUnMetre) with_precision 2 +
	 		 ";" + (ruissellementMoy * nombreMillimetreDansUnMetre) with_precision 2 +
	 		 ";" + (ETRMoy * nombreMillimetreDansUnMetre) with_precision 2;
	 	return data;		 			 	
	 }
		 
	action miseAzero{
		ask listeIlots {
			drainIlotCumulMois <- 0.0;
			ruissellementIlotCumulMois <- 0.0;
			ETRIlotCumulMois <- 0.0;
		}
	}
}

