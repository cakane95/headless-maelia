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

model resultatsValidationHerbSimNC

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
	action initialisationEcritureFichiersValidationHerbSimNC{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers ValidationHerbSimNC...';		
		
		create resultatsValidationHerbSimNC number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsValidationHerbSimNC parent: ecritureResultats{
	list<parcelle> listeParcellesUtilesIrrigables <- [];

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/validationHerbSimNC'+ nomDeLaSimulation + '.csv';
		string entete <- "annee;jour;idParcelle;espece;biomass_above_ground;biomass_sheath;BM_rac;INN_j;QN_aer;QN_rac;QN_fixe;Chum\n";
		return entete;

	}

	/*
	 * @Overwrite
	 */
	 list<string> ecritureJournaliere{
	 	
		list<string> aEcrire <-  [];
	 	string ecriture_espece <- "none";
	 	float ecriture_green_biomass <- -1.0; 
	 	float ecriture_green_biomass_sheath <- -1.0;
	 	float ecriture_BM_rac <- -1.0;
	 	float ecriture_INN_j <- -1.0;
	 	float ecriture_QN_aer <- -1.0;
	 	float ecriture_QN_rac <- -1.0;
	 	float ecriture_QN_fixe <- -1.0;
	 	float ecriture_Chum <- -1.0;
	 	
	 	
		//string dataJournaliere <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) ;
		ask listeParcellesUtiles{
			ecriture_Chum <- self.Chum;
	 		if (cultureParcelle != nil){
	 			ecriture_espece <- cultureParcelle.monModelDeCulture.espece.idEspeceCultivee;
	 			if(species(cultureParcelle.monModelDeCulture) = cultureHerbSimNC){
		 			ecriture_green_biomass <- cultureHerbSimNC(self.cultureParcelle.monModelDeCulture).biomass_above_ground;
		 			ecriture_green_biomass_sheath <- cultureHerbSimNC(self.cultureParcelle.monModelDeCulture).biomass_sheath;
		 			ecriture_BM_rac <- especeHerbSim(self.cultureParcelle.monModelDeCulture.espece).BM_rac;
		 			ecriture_INN_j <- especeHerbSim(self.cultureParcelle.monModelDeCulture.espece).INN_j;
		 			ecriture_QN_aer <- especeHerbSim(self.cultureParcelle.monModelDeCulture.espece).QN_aer;
		 			ecriture_QN_rac <- especeHerbSim(self.cultureParcelle.monModelDeCulture.espece).QN_rac;
		 			ecriture_QN_fixe <- especeHerbSim(self.cultureParcelle.monModelDeCulture.espece).QN_fixe;
	 			} 
	 		}
	 		
			aEcrire <+ string(dateCour.annee)  
			+ ";"+ string(dateCour.nbJoursEcoulesDansAnnee)
			+ ";"+ idParcelle
			+ ";"+ ecriture_espece
			+ ";"+ ecriture_green_biomass
			+ ";"+ ecriture_green_biomass_sheath
			+ ";"+ ecriture_BM_rac
			+ ";"+ ecriture_INN_j
			+ ";"+ ecriture_QN_aer
			+ ";"+ ecriture_QN_rac
			+ ";"+ ecriture_QN_fixe
			+ ";"+ ecriture_Chum
			+ "\n";

		}												
	 	return aEcrire;		 			 	
	 }
}

