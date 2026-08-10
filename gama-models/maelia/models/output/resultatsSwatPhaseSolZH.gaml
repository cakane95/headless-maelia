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
 *  resultatsSwatPhaseSolZH
 *  Author: Maroussia Vavasseur
 *  Description: 
 */ 
 
model resultatsSwatPhaseSolZH

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersSwatPhaseSolZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers SwatPhaseSolZH...';		
		
		create resultatsSwatPhaseSolZH number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

species resultatsSwatPhaseSolZH parent: ecritureResultats{
	zoneHydrographiqueSWAT zh <- nil;
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		zh <- zoneHydrographiqueSWAT(first(listeZonesHydrographiques where (each.idZoneHydrographique = first(listNomsZHsDecoupageZone))));
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationSWAT_PhaseSol_ZH.csv';
		string dataJournaliere <- '' + detailSimulation + '\nSUB;idZH;date;AreaKm2;PRECIPmm;SNOMELTmm;PETmm;ETmm;SWmm;PERCmm;SURQmm;GW_Qmm;LATQmm;WYLDmm';
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string data <- "";
	 	int num <- 0;		 	
//		 	if(zh != nil){
		ask(listeZonesHydrographiques){
			num <- num + 1;
		 	float sw <- 0.0;
		 	float perc <- 0.0;
		 	ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
		 		sw <- sw + (sum(mapTeneurEnEauSolParCouche.values) * fractionDansZH);
		 		perc <- perc + (getPercolationDerniereCouche() * fractionDansZH); // sur derniere couche
		 	}

		 	data <-  	data + string(zoneHydrographiqueSWAT(self).idSWAT) +
						';' + string(idZoneHydrographique) +	
						';' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +								
						';' + float(shape.area / (1000^2)) +	
						';' + float(pluie) +
						';' + float(zoneHydrographiqueSWAT(self).fonteDeNeigeZH) +
						';' + float(meteo.etp) +		
						';' + float(zoneHydrographiqueSWAT(self).volumeEvapotranspirationHydro / shape.area * nombreMillimetreDansUnMetre) +		
						';' + float(sw) +	
						';' + float(perc) +	
						';' + float(zoneHydrographiqueSWAT(self).volumeRuissellementDeSurfaceHydro / shape.area * nombreMillimetreDansUnMetre) +	
						';' + float(zoneHydrographiqueSWAT(self).volumeEcoulementEauSouterraineHydro / shape.area * nombreMillimetreDansUnMetre) +
						';' + float(zoneHydrographiqueSWAT(self).volumeEcoulementLateralHydro / shape.area * nombreMillimetreDansUnMetre) +							
						';' + float(getVolumePhaseSol() / shape.area * nombreMillimetreDansUnMetre);	
			if(num < length(listeZonesHydrographiques)){
				data <- data + '\n';
			}	 		
	 	}

	 	return data;			 		 	
	 } 			 			 
}
