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

model resultatsPrelevementsDetails

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
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleAgricole/ITKs/itk.gaml"

global{
	action initialisationEcritureFichiersPrelevementsDetails{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements Details...';		
		
		create resultatsPrelevementsDetails number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevementsDetails parent: ecritureResultats{
		list<parcelle> listeParcellesUtilesIrrigables <- [];

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string detail <- detailSimulation + '\n';			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/prelevements_Journalier_Details'+ nomDeLaSimulation + '.csv';
		let dataJournaliere type: string value: '' + detail + '\nannee';
		ask listeParcellesUtiles{
			if(ilot_app.isIrrigable){
				myself.listeParcellesUtilesIrrigables << self;
				dataJournaliere <- dataJournaliere 
				+ ";Surface_"+idParcelle
				+ ";Exploitation_"+idParcelle
				+ ";ITK_"+idParcelle
				+ ";TYPESOL_"+idParcelle
				+ ";RESSOURCE_IRR_"+idParcelle
				+ ";IRR_REEL_"+idParcelle
				+ ";IRR_SOUHAITEE_"+idParcelle
				+ ";ZA_"+idParcelle
				+ ";SECTEUR_"+idParcelle
				+ ";ECHV_"+idParcelle
				+ ";KC_"+idParcelle
				+ ";Hr_"+idParcelle
				+ ";Hm_"+idParcelle;
			}
		}
		return dataJournaliere;	
	}


	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
		string dataJournaliere <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) ;
		ask listeParcellesUtilesIrrigables{
				
			dataJournaliere <- dataJournaliere
			+ ";" +  (surface with_precision 0)
			+ ";"+ilot_app.codeExploitationAssociee
			+ ";"+ getITKAnnee().nomPourAffichage
			+ ";"+ilot_app.getNomZonePedo()
			+ ";"+ilot_app.ppaCourant
			+ ";"+irrigationReelle with_precision 4
			+ ";"+irrigationSouhaitee with_precision 4;
			if (length(listeGroupeIrrigationCulture) >0){
				groupeIrrigation gp <- first(listeGroupeIrrigationCulture).groupeAssocie;
				if (gp != nil){
					dataJournaliere <- dataJournaliere
					+ ";"+gp.zaAssociee;
					
					if (ilot_app.ppaCourant != nil){
						if(ilot_app.ppaCourant.getZaAssociee()!=nil){
							dataJournaliere <- dataJournaliere
							+ ";"+ilot_app.ppaCourant.secteurAdministratifAssocie.id;
						}else{
							dataJournaliere <- dataJournaliere
							+ ";NA";
						}
					}else{
						dataJournaliere <- dataJournaliere
						+ ";NA";
					}
					
					
					dataJournaliere <- dataJournaliere;
					//+ ";"+ gp.name;
				}
				else{
					dataJournaliere <- dataJournaliere
					+ ";NA"
					//+ ";NA"
					+ ";NA";
				}
				
			}else{
				dataJournaliere <- dataJournaliere
				+ ";NA"
				//+ ";NA"
				+ ";NA";
			}
			dataJournaliere <- dataJournaliere
			+ ";"+getEchelleVegetation() with_precision 3
			+ ";"+getKc() with_precision 3
			+ ";"+((parcelleAqYield(self).Hr / parcelleAqYield(self).RUr) with_precision 3)
			+ ";"+((parcelleAqYield(self).Hm / parcelleAqYield(self).RUm) with_precision 3)
			;
		}												
	 	return dataJournaliere;		 			 	
	 }
	 

}

