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

model resultatsGestionnaireDeBarrage

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleNormatif/barrage.gaml"
import "../modeleNormatif/gestionnaireDeBarrage.gaml"

global{
	action initialisationEcritureFichiersGestionnaireDeBarrage{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers GestionnaireDeBarrage...';		
		
		create resultatsGestionnaireDeBarrage number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}
	
				
}


species resultatsGestionnaireDeBarrage parent: ecritureResultats{
	map<gestionnaireDeBarrage,int> nbJourDebitInsuffisant <-  map<gestionnaireDeBarrage,int>([]);	
	map<gestionnaireDeBarrage,int>  nbJourDestockageImpossible <-  map<gestionnaireDeBarrage,int>([]);	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string detail <- detailSimulation + '\n';			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/Barrage_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detail + '\nannee';
		
		ask (gestionnaireDeBarrage as list){
			ask (barragesAssocies){
				dataJournaliere <- dataJournaliere + ';Volume(m3)_'+idBarrage + ';QuotaEtiageRestant(m3)_'+idBarrage +';debitJournalier(m3/j)_'+idBarrage  +';debitDeReserve(m3/j)_'+idBarrage;
			}
			put 0 at: self in: myself.nbJourDebitInsuffisant;
			put 0 at: self in: myself.nbJourDestockageImpossible;
		}
		return dataJournaliere;	
	}

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		string detail <- detailSimulation + '\n';			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/Barrage_Annuel'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detail + '\nannee';
		ask (gestionnaireDeBarrage as list){
			ask (barragesAssocies){
				dataAnnuelle <- dataAnnuelle + ';volumeDestocke'+idBarrage;
			}
			dataAnnuelle <- dataAnnuelle + ';nbJourDestockageInsuffisant'+
				';nbJourDestockageImpossible';
		}
		return dataAnnuelle;	 	
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
		string data <-  	'' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);		
	 	ask (gestionnaireDeBarrage as list)
	 	{
	 		bool isforcee <- false;
	 		if (isVolumesCritiquesDepassesPourTousLesBarrages()) {
	 			isforcee <- true;
	 		}
	 		bool isDebitInsuffisant <- true;
	 		bool isWaterLeft <- true;
			ask (barragesAssocies){
		 		data <- data + ';'+ getVolumeBarrage() with_precision 0 + ';'+quotaAnnuelRestant  with_precision 0 +';'+ getDebitCourant()  with_precision 0 + ";" + debitDeReserveCourant with_precision 0;
				if (min([getVolumeBarrage(),quotaAnnuelRestant]) > getVolumeCritique(false)){	// si il reste de suffisament d'eau ou de quota dans au moins un barrage
					isDebitInsuffisant <- false;
				}
				if (min([getVolumeBarrage(),quotaAnnuelRestant]) > 0.0) { // si il reste de l'eau ou du quota a au moins un barrage
					isWaterLeft <- false;
				}
	 		}
	 		if isDebitInsuffisant and lacherDemande{
	 			put ((myself.nbJourDebitInsuffisant at self) +1) at: self in: myself.nbJourDebitInsuffisant;
	 		}
	 		if isWaterLeft and lacherDemande{
	 			put ((myself.nbJourDestockageImpossible at self) +1) at: self in: myself.nbJourDestockageImpossible;
	 		}	
	 	}
		 	
	 	return data;		 			 	
	 }
	 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{	
		string data <-  	'' + (dateCour.annee) ;	
		ask (gestionnaireDeBarrage as list)
	 	{
	 		ask (barragesAssocies){
				data <- data + ';'+ (volumePourEtiageMax - quotaAnnuelRestant)  with_precision 0;
			}
			data <- data + ';'+ (myself.nbJourDebitInsuffisant at self)
				+ ';'+ (myself.nbJourDestockageImpossible at self);
			put 0 at: self in: myself.nbJourDebitInsuffisant;
			put 0 at: self in: myself.nbJourDestockageImpossible;
		}		
		return data;			 					 				
	 }	

}

