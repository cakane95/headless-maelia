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
 *  resultatsSuiviITKParPArcelle_humidite 190121 pour Myriam
 *  Author: JV
 *  Description: 
 */

model resultatsSuiviITKParParcelle_humidite

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSuiviITKParParcelle_humidite{
	
		// OT ont à mémoriser: semis, irrigation, récolte
		listOTAMemoriser << [SEMIS, IRRIGATION, RECOLTE];
		listOTAMemoriser <- remove_duplicates(listOTAMemoriser); // supprime les éventuels doublons (au cas où listOTAMemoriser contenait déjà des OT)
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suiviOTParParcelle_humidite.';           
        
        create resultatsSuiviITKParParcelle_humidite number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuiviITKParParcelle_humidite parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviOTParParcelle_humidite'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;jour;parcelle;culture;ITK;OT;humiditeSolAvantOT;humiditeSolApresOT;irrigation_souhaitee[mm];irrigation_reelle[mm]';
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	string ecritureJournaliere{
		string aEcrire <-  "";
		int jourCourant <- dateCour.nbJoursEcoulesDansAnnee;

		loop uneParc over: listeParcellesUtiles{
												
			parcelleAqYield parc <- parcelleAqYield(uneParc);	
			loop ot over: [SEMIS, IRRIGATION, RECOLTE]{
				map<int, itk> opParDate <- parc.memoireOTsurParcelle at ot;
				if opParDate contains_key jourCourant {
					aEcrire <- "" + aEcrire + dateCour.annee + ";" + jourCourant + ";" + parc.idParcelle + ";" + opParDate[jourCourant].especeCultiveeITK.idEspeceCultivee + ";" + opParDate[jourCourant].idITK + ";" + ot + ";" + parc.humiditeSolRacineVeille + ";" + parc.getHumiditeSolRacine() + ";" + parc.irrigationSouhaitee + ";" + parc.irrigationReelle + "\n";
				}
			}
		}
		return aEcrire;
	}			


}
