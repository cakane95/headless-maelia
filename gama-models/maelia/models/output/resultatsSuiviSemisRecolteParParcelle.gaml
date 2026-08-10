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
 *  resultatsSuiviSemisRecolteParPArcelle
 *  Author: JV
 *  Description: pour Myriam voir mail 14/10/20
 */

model resultatsSuiviSemisRecolteParParcelle

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSuiviSemisRecolteParParcelle{
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suiviSemisRecolteParParcelle.';           
        
        create resultatsSuiviSemisRecolteParParcelle number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuiviSemisRecolteParParcelle parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviSemisRecolteParParcelle'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;nbJour;date;parcelle;surface [m2];culture;ITK;OT;irriguee';
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	string ecritureFinAnnuelle{
		string aEcrire <- "";
		string premierJanvier <- "" + dateCour.annee + "0101";
		date datePremierJanvier <- date(premierJanvier); // date au format yyyymmdd
		date dateOT;

		loop parc over: listeParcellesUtiles{						
			loop ot over: [SEMIS, RECOLTE]{				
				map<int, itk> opParDate <- parc.memoireOTsurParcelle at ot;									
				loop d over: opParDate.keys{
					dateOT <- (datePremierJanvier add_days d-1); // d-1 car 1er janvier = jour 1
					aEcrire <- aEcrire + dateCour.annee + ";" + d + ";" + dateOT + ";" + parc.idParcelle + ";" + parc.surface + ";" + opParDate[d].especeCultiveeITK.idEspeceCultivee + ";" + opParDate[d].idITK + ";" + ot + ";" + opParDate[d].isIrriguee() + "\n"; 					
				}			
			}
			
		}
		return aEcrire;
	}			


}
