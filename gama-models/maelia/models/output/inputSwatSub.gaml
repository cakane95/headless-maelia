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
 *  inputSwatSub
 *  Author: Maelia
 *  Description: 
 */

model inputSwatSub

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersInputSwatSub{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputSwatSub...';		
		
		create inputSwatSub number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species inputSwatSub parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));

		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/inputSWAT_Sub.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;area[km2];elevb[m];elevb_fr;snoeb[mm];plaps;tlaps;sno_sub;ch_l1[km];ch_s1[m/m];ch_w1[m];ch_k1[mm/hr];ch_n1\n';
		
		ask (zh){
			list<float> listElev <- [];
			list<float> listFraction <- [];
			list<float> listSnoeb <- [];
			ask (bandesDelevation){
				listElev << altitude;
				listFraction << fraction;
				listSnoeb << eauDansPaquetNeige;
			}
			
		 	dataJournaliere <-  	dataJournaliere + 	''  + int(idSWAT) +
		 											  	';' + string(idZoneHydrographique) +
		 											  	';' + float(shape.area / (1000^2)) +	
		 											  	';' + list(listElev) +		
		 											  	';' + list(listFraction) +		
		 											  	';' + list(listSnoeb) +
		 											  	';' + float(plaps) +	
		 											  	';' + float(tlaps) +	
		 											  	';' + float(eauDansPaquetNeigeZH) +	
		 											  	';' + float(longueurCoursEauTributaireMax) +	
		 											  	';' + float(penteMoyenneCoursEauTributaire) +	
		 											  	';' + float(largeurMoyenneCoursEauTributaire) +
		 											  	';' + '?'+
		 											  	';' + float(coefficientManningCoursEauTributaire) + '\n'; 
	 	}	
		return dataJournaliere;
	 } 
}

