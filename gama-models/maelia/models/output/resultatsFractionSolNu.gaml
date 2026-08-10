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
 *  resultatsFractionSolNu
 *  Author: Romain Lardy
 *  Description: 
 */

model resultatsFractionSolNu

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	action initialisationEcritureFichiersFractionSolNu{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers FractionSolNu et Recolte forcee...';		
		
		create resultatsFractionSolNu number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsFractionSolNu parent: ecritureResultats{
	map<int,float> historiqueSolNu <- map<int,float>([]);
	map<ilot, float> fractionSolNuIlotDureeSimulation <- map<ilot,float>([]);
	map<ilot, float> fractionRecolteForceeDureeSimulation <- map<ilot,float>([]);
	float surfaceUtileTerritoire <- 0.0;
	int compteur <- 0;
	int nbAnneeEcoule <- 0;
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{	
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/fractionSolNuJournalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date;fractionSolNu';
		
		return dataJournaliere;	
	}
	
	string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/fractionSolNuAnnuel'+ nomDeLaSimulation + '.csv';
		string dataAnnee <- 'annee;fractionSolNu';
		ask listeIlots{
			myself.surfaceUtileTerritoire <- myself.surfaceUtileTerritoire + self.surfaceParcellesUtiles;
			put 0.0 at: self in: myself.fractionSolNuIlotDureeSimulation;
		}
		return dataAnnee;	
	}

 
	/*
	 * @Overwrite
	 */
	string ecritureJournaliere{
		string data <-  '' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);			
	 	float surfaceSolNu <- 0.0;
	 	loop il over:fractionSolNuIlotDureeSimulation.keys{
	 		float surfaceSolNuIlot <- 0.0;
	 		ask il.listeParcelles where (each.isParcelleUtile){
	 			if(cultureParcelle = nil){ // si pas de culture seme
		 			surfaceSolNuIlot <- surfaceSolNuIlot + surface; //m2
		 		}
	 		} //
	 		put (surfaceSolNuIlot/il.surfaceParcellesUtiles + fractionSolNuIlotDureeSimulation at il ) 
	 			at: il in: fractionSolNuIlotDureeSimulation;
	 		surfaceSolNu <- surfaceSolNu + surfaceSolNuIlot;  //m2
	 	}
		put surfaceSolNu at:dateCour.nbJoursEcoulesDansAnnee in: historiqueSolNu;
	 	data <- data +";"+ (surfaceSolNu/surfaceUtileTerritoire) with_precision 4;
	 	
	 	compteur <- compteur +1;
	 	return data;		 			 	
	 }
	 
	 string ecritureFinAnnuelle{
	 	string data <-  '' + (dateCour.annee)+";"+ (mean(historiqueSolNu.values)/surfaceUtileTerritoire) with_precision 4;
	 	
	 	//reinit
	 	historiqueSolNu <- map<int,float>([]);
	 	nbAnneeEcoule <- nbAnneeEcoule +1;
	 	
	 	string nomFichierIlot <- cheminRelatifDuDossierDeSortieDeSimulation + '/solNuIlots'+ nomDeLaSimulation + '.csv';
		string dataIlot <- "ID_ILOT;SOLNU;RECOLTE_FORCEE";
		loop il over:fractionSolNuIlotDureeSimulation.keys{
			float SurfaceRecolteForce<- 0.0;
			loop parc over: il.listeParcelles where (each.isParcelleUtile){
				if (parc.semis_prevu_non_realise)
				{
					SurfaceRecolteForce <- SurfaceRecolteForce + parc.surface;
				}
			}
			SurfaceRecolteForce <- SurfaceRecolteForce /il.surfaceParcellesUtiles;
			put SurfaceRecolteForce at: il in: fractionRecolteForceeDureeSimulation;
			
			dataIlot <- dataIlot + '\n'+ il.id + ";" + ((fractionSolNuIlotDureeSimulation at il)/compteur) with_precision 4 +
									";" + ((fractionRecolteForceeDureeSimulation at il)/nbAnneeEcoule) with_precision 4;
		}
		//on va recreer un fichier a chaque fois
		save dataIlot to: nomFichierIlot format: 'text' rewrite: true;
		
	 	return data;
	 }
		 
}

