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
 *  resultatsSuiviITKParPArcelle
 *  Author: JV
 *  Description: 
 */

model resultatsSuiviITKParParcelleTemps

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSuiviITKParParcelleTemps{
	
		// toutes les OT sont à mémoriser
		listOTAMemoriser <- listOT;
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suiviOTParParcelleTemps.';           
        
        create resultatsSuiviITKParParcelleTemps number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuiviITKParParcelleTemps parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{			
		nomFichierJournalier<- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviOTParParcelleTemps'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;date;exploitation;parcelle;culture;surface;OT;duree';
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	string ecritureJournaliere{		
		string aEcrire <-  "";
		loop agri over: listeAgriculteurs{
			aEcrire <- aEcrire + agri.outputITKParParcelleTemps;
			agri.outputITKParParcelleTemps <- "";
		}
		return aEcrire;
	}			


}
