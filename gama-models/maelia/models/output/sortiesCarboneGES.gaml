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
 *  sortiesCarboneGES
 *  Author: JV
 *  Description: 
 */

model sortiesCarboneGES

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSortiesCarboneGES{
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers sorties carbone et GES.';           
        
        create sortiesCarboneGES number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species sortiesCarboneGES parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{	
	 	// JV 050625 renommage avant: sorties_carboneGES apres: sorties_GES (cf issue #10)
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/sorties_GES'+ nomDeLaSimulation + '.csv';
		// JV 050625 modifs unites sorties carboneGES et azote cf issue #10
		string entete <- "annee;jourDebut;jourFin;parcelle;couvert;itk;delta_Corg[kg_eqCO2/ha];tx_MO_fin[%];emissions_N2O_denit[kg_eqCO2/ha];emissions_N2O_nit[kg_eqCO2/ha];emissions_volat[kg_eqCO2/ha];emissions_lixiv[kg_eqCO2/ha];emissions_ferti[kg_eqCO2/ha];bilan_net_GES[kg_eqCO2/ha];ratio_Corg_Arg[%]\n";
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	list<string> ecritureFinAnnuelle{
		list<string> aEcrire <-  [];
		// JV 050625 pour conversions, cf issue #10
		float poid_mol_N2O_prg <- 296 * 44/28;
		float poid_mol_C <- 44/12;

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
						aEcrire <+ "" + "solnu;;";
					}
					ask parcelleAqYieldNC(parc){
						aEcrire <+ "" + (sorties_delta_Corg[k] * poid_mol_C * -1) with_precision nb_decimales_sorties + ";"; // OTRM 111024 - 1 pour traduction en eqCO2 : si stockage de C alors valeur négative // JV 050625 deplace ici cf issue #10
						aEcrire <+ "" + sorties_tx_MO_fin[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + (sorties_emissions_N2O_denit[k] * poid_mol_N2O_prg) with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + (sorties_emissions_N2O_nit[k] * poid_mol_N2O_prg) with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + (sorties_emissions_N2O_N_volat[k] * poid_mol_N2O_prg * 0.01) with_precision nb_decimales_sorties + ";"; //  MD 141223 // JV 050625 deplace ici cf issue #10
						aEcrire <+ "" + (sorties_emissions_N2O_N_lixiv[k] * poid_mol_N2O_prg * 0.0075) with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_emissions_ferti[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + sorties_bilan_net_GES[k] with_precision nb_decimales_sorties + ";";
						aEcrire <+ "" + (sorties_tx_Corg_Arg[k]/dureeCouvert) with_precision nb_decimales_sorties;
					}
					aEcrire <+ "\n";
				}
			}		
		}
		//aEcrire <- replace_regex(aEcrire,"\n$","");
		return aEcrire;
	}			


}
