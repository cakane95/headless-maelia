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
 *  inputSwatSol
 *  Author: Maelia
 *  Description: 
 */

model inputSwatSol

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleCommun/bandeAltitude.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleCommun/clc.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersInputSwatSol{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers inputSwatRte...';		
		
		create inputSwatSol number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species inputSwatSol parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));

		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/inputSWAT_Sol.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;num;clc;studom;pente;fraction;nbLayers' +	
																		';Max_rooting_depth[mm]' +
																		';DepthMin[mm]' +
																		';DepthMax[mm]' +
																		';Bulk Density Moist[g/cc]' +
																		';Ave.AW Incl.Rock Frag' +
																		';Ksat.(est.)[mm/hr]' +
																		';Clay[weight %]\n';
		
		int numero <- 0;
	 	if(zh != nil){
		 	ask zh.listeHRUAssociees{
		 		numero <- numero + 1;
		 		
		 		ask sol{
				 	dataJournaliere <-  	dataJournaliere + 	'' + int(myself.zh.idSWAT) +
																';' + string(myself.zh.idZoneHydrographique) +	
																';' + int(numero) +	
																';' + string(myself.clcAssocie.typeClasse) +	
																';' + string(stuDominant) +	
																';' + float(myself.penteAssociee) +	
																';' + float(myself.fractionDansZH) +
																';' + int(length(mapProfondeurMinParCouche.keys)) +
																';' + float(getProfondeurMaxSWAT()) +
																';' + list(mapProfondeurMinParCouche.values) +
																';' + list(mapProfondeurMaxParCouche.values) +
																';' + list(densiteSol.values) +
																';' + list(capaciteEauDisponible.values) +
																';' + list(conductiviteHydroliqueSaturee.values) +
																';' + list(densiteArgile.values) + '\n'; 			 			
		 		}
		 	}		 		
	 	}
		return dataJournaliere;
	 } 
}

