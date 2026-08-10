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
 *  ecritureFichiers
 *  Author: JV
 *  Description: sous-ensemble de resultatsModeleAqYield transposé (1 ligne par parcelle) (pour Myriam 190121)
 */


model resultatsModeleAqYield_light

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
	action initialisationEcritureFichiersModeleAqYield_light{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Modele AqYield light...';		
		
		// listParcellesPourSortiesAqYield is empty (i.e. no field in particular) -> fill with all fields
		if length(listParcellesPourSortiesAqYield)=0 {
			listParcellesPourSortiesAqYield <- (listeParcellesUtiles collect each.idParcelle);
		}
		
		create resultatsModeleAqYield_light number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsModeleAqYield_light parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_light_journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'annee;jour;parcelle;pluie[mm];irrigation[mm];ETP[mm];Kc;TRr[mm];TM[mm];TR_M;evaporation[mm];capilarite[mm];drain[mm];ruissellement[mm];RUr[mm];Hr[mm];RUm[mm]';

		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
//		 	int indiceDebut <- 0;
//		 	int indiceFin <- 0;
//		 	ask(date){
//		 		indiceDebut <- convertirDateEnIndice(jourAConvertir:25, moisAConvertir:10, anneeAConvertir: 2000);
//		 		indiceFin <- convertirDateEnIndice(jourAConvertir:31, moisAConvertir:12, anneeAConvertir: 2001);
//		 	}
	 	
	 	string data <- "";
	 		 	
		loop unIdParcelle over: listParcellesPourSortiesAqYield{

	 		parcelle uneParcelle <- first(listeParcelles where (each.idParcelle = unIdParcelle));
	 		parcelleAqYield uneParcelleAqYield <- parcelleAqYield(uneParcelle);

			data <- data + dateCour.annee + ';' + dateCour.nbJoursEcoulesDansAnnee + ";" + unIdParcelle;			 		
			
			data <- data +								
								';' + float(uneParcelleAqYield.getPluie()) +
								';' + float(uneParcelleAqYield.irrigationReelle) +
								';' + float(uneParcelleAqYield.ilot_app.meteo.etp) +
								';' + float(uneParcelleAqYield.getKc()) +
								';' + float(uneParcelleAqYield.transpirationR) +
								';'	+ float(uneParcelleAqYield.getTranspirationMax()) +
								';' + float(uneParcelleAqYield.getTR_M()) +
								';' + float(uneParcelleAqYield.evaporation) +
								';' + float(uneParcelleAqYield.capilarite) +								
								';' + float(uneParcelleAqYield.drain) +
								';' + float(uneParcelleAqYield.quantiteEauDeRuissellement) +
								';' + float(uneParcelleAqYield.RUr) +
								';' + float(uneParcelleAqYield.Hr) +
								';' + float(uneParcelleAqYield.RUm);
								
			if unIdParcelle!=last(listParcellesPourSortiesAqYield) {
				data <- data + "\n";
			}								
		}	
				
		return data;
	 }
	 
}

