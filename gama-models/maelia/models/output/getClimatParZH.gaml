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
 *  resultatsDebistSTH
 *  Author: Maelia
 *  Description: Sortie à traiter pour l'analyse de sensibilité
 */

model getClimatParZH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleNormatif/pointDeReference.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

import "../modeleCommun/typeDeSol.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"

global{
	action initialisationEcritureFichiersGetClimatParZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers détails Climat...';		
		
		create getClimatParZH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species getClimatParZH parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		// Journaliers
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/climatParZH'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'annee';
			
        ask listeZonesHydrographiques{
        	dataJournaliere <- dataJournaliere + ';Area[Km2]' +'_' + name +
					 ';tMoy[°C]' +'_' + name +
					 ';tMoyMaisArvalis[°C]' +'_' + name +
					 ';ETP[mm]'+'_' + name+
					 ';pluie[mm]'+'_' + name;
        }

			return dataJournaliere;
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);										
		
		
		//Pour récupérer les propriétés moyennes à l'échelles du territoire
		
		float SurfaceTotale <-0.0;

		ask listeZonesHydrographiques{
			
   			SurfaceTotale <- 0.0;
		 	
		 	ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
				SurfaceTotale <- SurfaceTotale + float(getSurfaceKm2()) ;
			}
			data <- data + ';' + SurfaceTotale with_precision 2 +	
					';' + tMoy with_precision 2+
					';' + ( max([(tMin + min([tMax,30.0]))/2.0 -6.0 ,0.0])) with_precision 2+
					';' + meteo.etp with_precision 2+
					';' + pluie with_precision 2;
		 }
				
		return data;
	 }			  			 
}

