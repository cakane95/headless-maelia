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
 *  resultatsPrelevements
 *  Author: Maelia
 *  Description: 
 */

model resultatsValidationHerbSim

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/Cultures/groupeIrrigationCulture.gaml"
import "../modeleAgricole/Cultures/culture.gaml"
import "../modeleAgricole/Cultures/cultureHerbSim.gaml"
import "../modeleAgricole/Cultures/especeHerbSim.gaml"
import "../modeleAgricole/Cultures/modelDeCulture.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleAgricole/ITKs/itk.gaml"

global{
	action initialisationEcritureFichiersValidationHerbSim{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers ValidationHerbSim...';		
		
		create resultatsValidationHerbSim number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsValidationHerbSim parent: ecritureResultats{
	list<parcelle> listeParcellesUtilesIrrigables <- [];

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string detail <- detailSimulation + '\n';			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/ValidationHerbSim'+ nomDeLaSimulation + '.csv';
		let dataJournaliere type: string value: '' + detail + '\nannee';
		ask listeParcellesUtiles{
			dataJournaliere <- dataJournaliere 
				+";AdjustedNitrogenIndex_"+idParcelle
				+";Yield_"+idParcelle
				+";Height_"+idParcelle
				+";ThermalAge 	_"+idParcelle
				+";IndexHarvest_"+idParcelle
				+";GreenBiomass_"+idParcelle
				+";WaterIndex_"+idParcelle
				+";LAI"
				+";RUE"
				+";echV"
				+";kc";
		}
		return dataJournaliere;	
	}

	/*
	 * @Overwrite
	 */
	 list<string> ecritureJournaliere{
		list<string> dataJournaliere <-  	['' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee)];
		ask listeParcellesUtiles{
				
			dataJournaliere <+ ";" + (parcelleAqYield(self).NutrientIndex);
			dataJournaliere <+ ";" +  cultureHerbSim(self.cultureParcelle.monModelDeCulture).Yield;
			dataJournaliere <+ ";" +  (cultureHerbSim(self.cultureParcelle.monModelDeCulture).Height);
			dataJournaliere <+ ";" +  (cultureHerbSim(self.cultureParcelle.monModelDeCulture).ThermalAge);
			dataJournaliere <+ ";" +  (0.0);
			dataJournaliere <+ ";" +  (cultureHerbSim(self.cultureParcelle.monModelDeCulture).biomass_above_ground);
			dataJournaliere <+ ";" +  ((self.cultureParcelle.monModelDeCulture).indiceSatifactionHydrique );
			ask (cultureHerbSim(self.cultureParcelle.monModelDeCulture).compositionVegetation.keys){
				dataJournaliere <+ ";" +  LeafAreaIndex;
				dataJournaliere <+ ";" +  RadiationUseEfficiency;
			}
			dataJournaliere <+ ";" + cultureParcelle.monModelDeCulture.echV; 
			dataJournaliere <+ ";" + cultureParcelle.monModelDeCulture.kc;
			dataJournaliere <+ "\n";

		}												
	 	return dataJournaliere;		 			 	
	 }
}

