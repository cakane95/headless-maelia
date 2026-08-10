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
 *  sortiesBarrages
 *  Author: JV
 *  Description: 
 */

model sortiesBarrages

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSortiesBarrages{
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers sorties barrages.';           
        
        create sortiesBarrages number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species sortiesBarrages parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/sorties_barrages'+ nomDeLaSimulation + '.csv';
		string entete <- "date;ZH;idBarrage;volumeFinJour[m3];volumeTransfereZH[m3];debitLacherCourant[m3];debitReserve[m3];quotaLacherAnnuelRestant[m3];idRetenueAssociee;typeRetenue;surDrainPrincipal;volumeDebut[m3];volumeFin[m3];tauxRemplissage[0-1];volumePrecipitations[m3];volumeRechargeParHRU[m3];volumeRechargeParCoursEau[m3];volumeEvaporation[m3];volumePercolation[m3];volumePrelevements[m3];volumeSurplusRejete[m3]\n";
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	list<string> ecritureJournaliere{
		list<string> aEcrire <-  [];

		ask barrage {
			aEcrire <+ "" + dateCour.annee + '/' + dateCour.mois + '/' + dateCour.jour + ";" + zoneHydrographiqueAssociee.idZoneHydrographique + ";" + idBarrage + ";" + getVolumeBarrage() + ";" + volumeTransfereZHCeJour + ";" + getDebitCourant() + ";" + debitDeReserve + ";" + quotaAnnuelRestant;
			if retenueAssocie!=nil {
				aEcrire <+ ";" + retenueAssocie.id + ";" + 
					retenueAssocie.typeOfRet + ";" + 
					retenueAssocie.isOnDrainPrincipal + ";" + 
					retenueAssocie.bilan_volumeDebut with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_volumeFin with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_tauxRemplissage with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_precip with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_rechargeHRU with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_rechargeCoursEau with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_evap with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_percol with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_prelev with_precision nb_decimales_sorties + ";" + 
					retenueAssocie.bilan_surplus with_precision nb_decimales_sorties + "\n";
			} else {
				aEcrire <+ ";;;;;;;;;;;;;\n";
			}						
		}

		return aEcrire;
	}			


}
