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
 *  resultatsStrategieTemp
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model resultatsStrategieTemp

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Cultures/culture.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"  
import "../modeleNormatif/pointDeReferenceNonRealimente.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleNormatif/pointDeReference.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersStrategieTemp{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers initialisationEcritureFichiersStrategieTemp...';		
		
		create resultatsStrategieTemp number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsStrategieTemp parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debitZhNonRealimentees.csv';
		string dataJournaliere <- '' + detailSimulation + '\ndate;zh;za;phaseSol;debit';
		return dataJournaliere;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string data <- "";
	 	int numero <- 0;	 	
	 	int taille <- 0;
	 	
	 	ask(listZonesAdministratives where (!each.pointDeReferenceAssocie.isRealimente)){		 		
	 		ask(pointDeReferenceNonRealimente(pointDeReferenceAssocie).zhsControlees){		
	 			taille <- taille + 1;
	 		}
	 	}
	 	
	 	ask(listZonesAdministratives where (!each.pointDeReferenceAssocie.isRealimente)){		 		
	 		ask(pointDeReferenceNonRealimente(pointDeReferenceAssocie).zhsControlees){		
	 			numero <- numero + 1;
		 		data <-  	data + ''  + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
		 							';'  + idZoneHydrographique +
									';'  + myself.idZoneAdministrative +
									';'  + (getVolumePhaseSol() / nbSecondesDansUneJournee) +										
									';' + debitCourant;
	 			if(numero < taille){
					data <- data + '\n';
				}
	 		}
	 	}
	 	return data;			 		 	
	 } 
	
//		parcelle parcelleTemp <- nil;
//		/*
//		 * @Overwrite
//		 */
//		 string initialisationJournalier{
//		 	parcelleTemp <- first(listeParcelles where (each.idParcelle = "4946098_00"));
//		 	write "!!!!!!!!!!!! " + parcelleTemp;
//		 	
//		 	string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + cultureForceeParcelle + '\nSol : ' + parcelleTemp.ilot_app.sol + '\n';
//			
//			nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/parametreStratTemp.csv';
//			string dataJournaliere <- '' + detail + '\ndate;pluie;HumiditeParcelle;HumuditeSol;Pluie-ETP';
//			return dataJournaliere;
//		 }
//
//		/*
//		 * @Overwrite
//		 */
//		 string ecritureJournaliere{
//		 	string data <- "";
//		 	ask (parcelleTemp){
//		 		data <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
//		 							';'  + getPluie() +
//									';'  + getHumiditeSol() +
//									';' + ilot_app.sol.getSeuilHumidite();
//				ask ilot_app.meteo {
//					data <- data + ";" + getCumulePluiesMoinsETP(nb_jours:7);					
//				}
//		 	}
//		 	
//		 	return data;			 		 	
//		 } 			 			 
}

