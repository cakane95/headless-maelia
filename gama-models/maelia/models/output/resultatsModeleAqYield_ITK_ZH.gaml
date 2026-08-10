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
 *  resultatsModeleAqYield_ITK_ZH
 *  Author: JV
 *  Description: évaporation, transpiration max, transpiration réelle agrégées par ITK et par ZH (demande Myriam Soutif)
 */


model resultatsModeleAqYield_ITK_ZH

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
	action initialisationEcritureFichiersModeleAqYield_ITK_ZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Modele AqYield ITK ZH...';		
		
		create resultatsModeleAqYield_ITK_ZH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsModeleAqYield_ITK_ZH parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/aqYield_eva_trmax_trr_ITK_ZH'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- "annee;jour;ZH;ITK;surface_m2;eva_m3;trmax_m3;trr_m3";
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{

	 	string data <- "";
		map<string,float> sommeEva <- []; // clé: ZH;ITK (concaténation idZH et idITK par un ;), valeur: sommeEva
		map<string,float> sommeTRmax <- [];
		map<string,float> sommeTRr <- [];
		map<string,float> sommeSurface <- [];

	 	// pour toutes les parcelles semées (cultureParcelle!=nil)
		loop uneParcelle over: listeParcelles where (each.cultureParcelle!=nil){

			string idITK_parcelle <- uneParcelle.getITKAnnee().idITK;
			string idZH_parcelle <- uneParcelle.ilot_app.zoneHydroAssociee.idZoneHydrographique;
			float surface <- uneParcelle.surface;
	 		parcelleAqYield uneParcelleAqYield <- parcelleAqYield(uneParcelle);

			string cle <- idZH_parcelle + ";" + idITK_parcelle;
			sommeEva[cle] <- sommeEva[cle] + (uneParcelleAqYield.evaporation/nombreMillimetreDansUnMetre)*surface; // [m3] = [m]*[m2]
			sommeTRmax[cle] <- sommeTRmax[cle] + (uneParcelleAqYield.getTranspirationMax()/nombreMillimetreDansUnMetre)*surface; // [m3] = [m]*[m2]
			sommeTRr[cle] <- sommeTRr[cle] + (uneParcelleAqYield.transpirationR/nombreMillimetreDansUnMetre)*surface; // [m3] = [m]*[m2]
			sommeSurface[cle] <- sommeSurface[cle] + surface;
		}	
		
		// pour chaque combinaison ZHxITK identifiée
		loop uneCle over: sommeEva.keys{
			string idZH <- uneCle tokenize ";" at 0;
			string idITK <- uneCle tokenize ";" at 1;
			
		 	data <- data + dateCour.annee + ';' + dateCour.nbJoursEcoulesDansAnnee + ";" + idZH + ";" + idITK+ ";" +
		 		sommeSurface[uneCle] + ";" + sommeEva[uneCle] + ";" + sommeTRmax[uneCle] + ";" + sommeTRr[uneCle] + "\n";
		}
		// supprime le dernier \n (https://regex101.com/r/MuuiHh/1)
		data <- replace_regex(data,"\n$","");
		
		return data;
	 }
	  			 
}

