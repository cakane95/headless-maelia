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
 *  sortiesEau
 *  Author: JV
 *  Description: 
 */

model sortiesEau

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSortiesEau{
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers sorties eau.';           
        
        create sortiesEau number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species sortiesEau parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/sorties_eau'+ nomDeLaSimulation + '.csv';
		string entete <- "annee;jourDebut;jourFin;parcelle;couvert;itk;evaporation[mm];transpiration[mm];percolation[mm];capilarite[mm];ruissellement[mm];Hr_debut[mm];Hm_debut[mm];Hr_fin[mm];Hm_fin[mm];Hr_1erJanv[mm];Hm_1erJanv[mm];satisfactionHydrique[%];pluie[mm];irrigation[mm];sommeDegresJourCulture[°C]\n";
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	list<string> ecritureFinAnnuelle{
		list<string> aEcrire <-  [];

		// pour chaque parcelle
		loop parc over: listeParcellesUtiles {
			
			// pour chaque période de couvert observée sur l'année
			loop k from: 0 to: length(parc.sorties_jDebutCouvert)-1 {
				int dureeCouvert <- parc.sorties_jFinCouvert[k] - parc.sorties_jDebutCouvert[k] + 1; // +1 car chaque jour de la période compte
				if dureeCouvert>=1 { // peut être <1 si SEMIS au 1er jour de la simulation, dans ce cas, le 1er couvert ne compte pas 
					aEcrire <+ "" + dateCour.annee + ";" + parc.sorties_jDebutCouvert[k] + ";" + parc.sorties_jFinCouvert[k] + ";" + parc.idParcelle + ";";
					if parc.sorties_especeCouvert[k]!=nil { 
						aEcrire <+ "" + parc.sorties_especeCouvert[k].idEspeceCultivee + ";" + parc.sorties_itkCouvert[k].idITK + ";";
					} else {
						aEcrire <+ "solnu;;";
					}
					ask parcelleAqYield(parc){
						aEcrire <+ "" + sorties_evaporation[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_transpiration[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_percolation[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_capilarite[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_ruisselement[k] with_precision nb_decimales_sorties + ";";// MD 30082023
						aEcrire <+ "" + sorties_Hr_debut[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_Hm_debut[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_Hr_fin[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_Hm_fin[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_Hr_1janv[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_Hm_1janv[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + (100 * sorties_satisfactionHydrique[k]/dureeCouvert) with_precision nb_decimales_sorties + ";"; // moyenne sur la durée de la période de couvert
						aEcrire <+ "" + sorties_pluie[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_irrigation[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_sommeDegresJourCulture[k] with_precision nb_decimales_sorties;					
					}
					aEcrire <+ "\n";
				}
			}		
		}
		return aEcrire;
	}			


}
