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

model resultatsSIR

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
import "../modeleNormatif/pointDeReference.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersSIR{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Modele Aveyron...';		
		
		create resultatsSIR number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsSIR parent: ecritureResultats{
	bool isSeme <- false ;
	bool isRecolte <- false ;

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
	 	string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + rotationForceeParcelle + '\nSol : ' + typeDeSolForceParcelle + '\n';
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_SIR.csv';
		string dataJournaliere <- '' + detail + '\ndate;activite;dose';
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string data <- "";
	 	if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle != nil){
			isRecolte <- true ;
			if(! isSeme) {
				isSeme <- true; 
				data <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
								';Semis'  +
								';';
			}	
			if(parcelleAffichee.irrigationReelle > 0.0 ) {
				data <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
								';Irrigation'  +
								';'+ parcelleAffichee.irrigationReelle;
			}				
	 	}else if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle = nil and isRecolte = true){
	 		isSeme <- false;	
	 		isRecolte <- false;
	 		data <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
								';Recolte'  +
								';';
	 	}
	 	return data;			 		 	
	 } 			 			 
}

