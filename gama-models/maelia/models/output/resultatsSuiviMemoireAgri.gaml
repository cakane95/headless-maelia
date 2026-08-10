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
 *  resultatsSuiviMemoireAgri
 *  Author: JV
 *  Description: 
 */

model resultatsSuiviMemoireAgri

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSuiviMemoireAgri{
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suiviOTParParcelle.';           
        
        create resultatsSuiviMemoireAgri number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuiviMemoireAgri parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviMemoireAgri'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;agri;ITK;recolteObserves;surfaceCumule;chargesOp;chargesFixes;primes;tempsTravaux';
		return entete;
	 }
	/*
	 * @Ecriture
	 */
	string ecritureFinAnnuelle{

		string aEcrire <- "";
		loop agri over: listeAgriculteurs{			
			list<memoire> memoires <- agri.listMemoire;
			loop mem over: memoires{
				// on cherche si il s'est passé quelque chose cette année là pour cet ITK/mémoire là
				if(mem.tempsTravaux.keys contains dateCour.annee){
					aEcrire <- "" + dateCour.annee + ";" + agri.idAgriculteur + ";" + mem.itkAssocie.idITK + ";" +
						mem.recolteObserves[dateCour.annee] + ";" +
						mem.surfaceCumule[dateCour.annee] + ";" +
						mem.chargesOp[dateCour.annee] + ";" +
						mem.chargesFixes[dateCour.annee] + ";" +
						mem.primes[dateCour.annee] + ";" +
						mem.tempsTravaux[dateCour.annee];
				}		
			}
			
		}

		return aEcrire;
	}			


}
