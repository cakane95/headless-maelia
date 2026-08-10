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
 *  sortiesAzote
 *  Author: JV
 *  Description: 
 */

model sortiesAzote

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSortiesAzote{
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers sorties azote.';           
        
        create sortiesAzote number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species sortiesAzote parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
	 	// JV 050625 renommage avant: sorties_azote apres: sorties_CN cf issue #10
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/sorties_CN'+ nomDeLaSimulation + '.csv';
		// JV 050625 modifs unites sorties carboneGES et azote cf issue #10		
		string entete <- "annee;jourDebut;jourFin;parcelle;couvert;itk;N_lixivie[kgN/ha];N_volatilise_NH3[kgN/ha];N_mineralise_net_SOM[kgN/ha];N_mineralise_net_residus[kgN/ha];N_acquis_couvert[kgN/ha];N_mineral_debut[kgN/ha];N_mineral_fin[kgN/ha];emissions_N2O_directes[kgN/ha];emissions_N2[kgN/ha];N_fixe_legumineuses[kgN/ha];satisfactionAzote_culture[%];satisfactionAzote_ci[%];delta_Corg[kgC/ha];emissions_N2O_denit[kgN-N2O/ha];emissions_N2O_nit[kgN-N2O/ha];emissions_N2O_indirectes_volat[kgN-N2O/ha];emissions_N2O_indirectes_lixiv[kgN-N2O/ha]\n";
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
					ask parcelleAqYieldNC(parc){
						aEcrire <+ "" + sorties_N_lixivie[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_volatilise_NH3[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_mineralise_net_SOM[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_mineralise_net_residus[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_acquis_couvert[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_mineral_debut[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_N_mineral_fin[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2O_directes[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2[k] with_precision nb_decimales_sorties + ";";
						// Ecriture fixation d'azote - Version NR 20/10/2025
						if parc.sorties_especeCouvert[k]!=nil{ 
							if parc.sorties_especeCouvert[k].isLEG { // NR HerbSim 27/05/2024
								aEcrire <+ "" + sorties_N_fixe_legumineuses[k] with_precision nb_decimales_sorties + ";";
							} else {
								aEcrire <+ "" + 0 + ";";
							}
						} else { // sol nu
							aEcrire <+ "" + 0 + ";";
						}

						// Ecriture de satisfactionAzote_cult - Version NR 20/10/2025
						if parc.sorties_especeCouvert[k]!=nil { // Couvert sur la parcelle
							if !(listeNomsEspecesHerbSim contains parc.sorties_especeCouvert[k].idEspeceCultivee) and !parc.sorties_especeCouvert[k].isCouvert{ // AqYield en mode Cult. Princ.
									aEcrire <+ "" + (100 * sorties_satisfactionAzote_cult[k]) with_precision nb_decimales_sorties + ";"; // Ecriture de la valeur finale de satisfaction  (1 seule valeur dans le vecteur)
							} else {
								aEcrire <+ "" + 0 + ";"; // si autre cas, inscription de "0" dans satisfactionAzote_cult, écriture de la satis. azotée dans satisfactionAzote_ci
							}
						} else { // sol nu
							aEcrire <+ "" + 0 + ";"; // si pas de couvert, inscription de "0" dans satisfactionAzote_cult
						}
						
						// Ecriture de satisfactionAzote_ci - Version NR 20/10/2025
						if parc.sorties_especeCouvert[k]!=nil { // Couvert sur la parcelle
							if !(listeNomsEspecesHerbSim contains parc.sorties_especeCouvert[k].idEspeceCultivee) and !parc.sorties_especeCouvert[k].isCouvert{ // AqYield en mode Cult. Princ.
									aEcrire <+ "" + 0 + ";"; // écriture dans satisfactionAzote_cult
							} else { // Tous les autres cas (HerbSimNC, AqYield en mode ci), légumineuses ou non 
								aEcrire <+ "" + (100 * sorties_satisfactionAzote_ci[k] / dureeCouvert) with_precision nb_decimales_sorties + ";";
							}
						} else{ // sol nu
							aEcrire <+ "" + 0 + ";"; // si pas de couvert, inscription de "0" dans satisfactionAzote_ci
						}
						
						aEcrire <+ "" + sorties_delta_Corg[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2O_denit[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2O_nit[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2O_N_volat[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_N2O_N_lixiv[k] with_precision nb_decimales_sorties;
					}
					aEcrire <+ "\n";
				}
			}		
		}
		//aEcrire <- replace_regex(aEcrire,"\n$","");
		return aEcrire;
	}			


}
