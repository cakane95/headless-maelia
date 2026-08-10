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
	action initialisationEcritureFichiersPrelevementsDetail_onList{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements Details...';		
		
		create resultatsPrelevementsDetails_onList number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevementsDetails_onList parent: ecritureResultats{
		list<parcelle> lisParASortir <- [];
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		
		loop idPar over: listParcellesASuivre{ 
			parcelle parAsuivre <- first ( listeParcellesUtiles where (each.idParcelle = idPar));
			lisParASortir << parAsuivre;
			write "lisParASortir " + lisParASortir;
		}
		string detail <- detailSimulation + '\n';			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/prelevements_Journalier_Details_onList'+ nomDeLaSimulation + '.csv';
		let dataJournaliere type: string value: '' + detail + '\nannee';

		dataJournaliere <- dataJournaliere 
		+ ";Parcelle"
		+ ";ITK"
		+ ";TYPESOL"
		+ ";RESSOURCE_IRR"
		+ ";IRR_REEL"
		+ ";IRR_SOUHAITEE"
		+ ";ZA"
		+ ";SECTEUR"
		+ ";ECHV"
		+ ";KC"
		+ ";Hr/RUr"
		+ ";Hm/Rum";
		return dataJournaliere;	
	}


	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
		string dataJournaliere <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) ;
		string d <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) ;
		bool firstOne <- true;
		
		ask lisParASortir{
			if (firstOne){
				firstOne<-false;
			}else{
				dataJournaliere <- dataJournaliere + "\n" +d;
			}	
			dataJournaliere <- dataJournaliere
			+ ";"+self.idParcelle
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
				}
				else{
					dataJournaliere <- dataJournaliere
					+ ";NA"
					+ ";NA";
				}
				
			}else{
				dataJournaliere <- dataJournaliere
				+ ";NA"
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

