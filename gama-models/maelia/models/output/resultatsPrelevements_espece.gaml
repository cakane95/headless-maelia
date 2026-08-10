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
 *  ZHresultatsPrelevements
 *  Author: Maroussia
 *  Description: 
 */

model resultatsPrelevements_espece

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "ecritureResultats.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleNormatif/secteurAdministratif.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleHydrographique/equipement.gaml"

global{
	action initialisationEcritureFichiersPrelevements_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_espece number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevements_espece parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de idEspece
	map<string,float> volREEL <- map<string,float>([]);
	
	//list<string> listID <- [];
	list<parcelle> listParcelleUtilesIrrigables <- []; //liste de parcelles par type de sol
	
	list<especeCultivee> listeEspeceIrrigables <- [];
	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_espece'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
		

		ask listeParcellesUtiles{
			if(self.ilot_app.isIrrigable){
				myself.listParcelleUtilesIrrigables << self;
			}
		}
		
		
		loop vari over: listeEspecesCultiveesParOrdreSaisie{
			dataJournaliere <-dataJournaliere +';'
				 + string(vari.idEspeceCultivee)+'_SOUHAIT;'
				 + string(vari.idEspeceCultivee)+'_REEL';
		}
			
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_espece'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;espece;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	

		loop vari over: listeEspecesCultiveesParOrdreSaisie{
			float volume_SOUHAIT <- 0.0;
			float volume_REEL <- 0.0;
			ask (listParcelleUtilesIrrigables where (each.getITKAnnee().especeCultiveeITK = vari)){
				volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee/nombreMillimetreDansUnMetre) * self.surface;
				volume_REEL <- volume_REEL + (self.irrigationReelle/nombreMillimetreDansUnMetre) * self.surface;
			}
			dataJournaliere <-dataJournaliere +';'
				 + string(volume_SOUHAIT with_precision 0)+';'
				 + string(volume_REEL with_precision 0);
				 
			put (volume_SOUHAIT + (volSOUHAIT at vari.idEspeceCultivee)) at: vari.idEspeceCultivee in: volSOUHAIT;
 			put (volume_REEL +(volREEL at vari.idEspeceCultivee)) at: vari.idEspeceCultivee in: volREEL;
			
		}

	 	
	 	return dataJournaliere;		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	string data <- "";
	 	bool first <- true;
		loop vari over: listeEspecesCultiveesParOrdreSaisie{
			
			if ((volSOUHAIT at vari.idEspeceCultivee) > 0){
				if(!first){
					data <-  data +"\n";
				}
				data <-  data + (dateCour.annee) +
					';'+vari.idEspeceCultivee+ ';' +
					 float(volSOUHAIT at vari.idEspeceCultivee) with_precision 0 +';'+
					 float(volREEL at vari.idEspeceCultivee) with_precision 0;
				first<- false;
			}
		}
	 	return data;		
	 }

	/*
	 * @Overwrite
	 */		 
	 action miseAzero{		
		volSOUHAIT <- map<string,float>([]);
		volREEL <- map<string,float>([]);
	 }
 		 			 
}

