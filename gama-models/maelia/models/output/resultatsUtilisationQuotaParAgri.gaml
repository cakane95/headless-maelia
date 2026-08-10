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
 *  resultatsUtilisationQuotaParAgri
 *  Author: R. Lardy
 *  Description: 
 */

model resultatsUtilisationQuotaParAgri

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleNormatif/uniteDeDefinitionDuVP.gaml"
import "../modeleNormatif/uniteDeGestion.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"

global{
	action initialisationEcritureFichiersUtilisationQuotaParAgri{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers utilisation du quota par agri...';		
		create resultatsUtilisationQuotaParAgri number: 1 {
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}
}


species resultatsUtilisationQuotaParAgri parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/utilisationQuotaParAgri'+ nomDeLaSimulation + '.csv';
		string dataFinAnnee <- 'annee';
		ask listeAgriculteurs{
			dataFinAnnee<- dataFinAnnee + ';VolumeUtilise(m3)_' +name + ';VolumeAutorisee(m3)_' +name; 
		}
		return dataFinAnnee;	
	}

	 /*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{
		string data <- "" + dateCour.annee;			
	 	ask listeAgriculteurs{
			data<- data+ ';'+(eau_quotaExploitation - eau_disponible) with_precision 0+ ';' +eau_quotaExploitation with_precision 0; 
		}
	 	return data;		 			 	
	 }
	 

}

