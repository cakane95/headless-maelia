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

model resultatsPrelevements_sol_espece

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
	action initialisationEcritureFichiersPrelevements_sol_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_sol_espece number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevements_sol_espece parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de sol __ idEspece
	map<string,float> volREEL <- map<string,float>([]);
	map<string,float> surface <- map<string,float>([]);
	
	//list<string> listID <- [];
	map<string,list<parcelle>> mapGroupe <- map([]); //liste de parcelles par type de sol
	
	list<itk> listeITKIrrigables <- [];
	list<especeCultivee> listeEspeceIrrigables <- [];
	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_sol_espece'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
		
		//sol a distinguer par nom
		ask listeParcellesUtiles{
			if(self.ilot_app.isIrrigable){
				list<parcelle> listTemp <- myself.mapGroupe at self.ilot_app.getNomZonePedo();
				listTemp << self;
				put listTemp at:self.ilot_app.getNomZonePedo() in:myself.mapGroupe;
			}
		}
		
		loop idSol over: mapGroupe.keys{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idSolVari <- string(idSol) +"_"+ vari.idEspeceCultivee;
				dataJournaliere <-dataJournaliere +';'
					 + string(idSolVari)+'_SOUHAIT;'
					 + string(idSolVari)+'_REEL';
			}
		}	
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_sol_espece'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;sol;espece;volSouhaite[m3];volReel[m3];surface[ha]';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	
	 	loop idSol over: mapGroupe.keys{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idSolVari <- string(idSol) +"_"+ vari.idEspeceCultivee;
				float volume_SOUHAIT <- 0.0;
				float volume_REEL <- 0.0;
				list<parcelle> tmp <- (mapGroupe at idSol);
				float surf <- 0.0;
				ask (tmp where (each.getITKAnnee().especeCultiveeITK = vari)){
					volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee/nombreMillimetreDansUnMetre) * self.surface;
					volume_REEL <- volume_REEL + (self.irrigationReelle/nombreMillimetreDansUnMetre) * self.surface;
					surf <- surf + self.surface;
				}
				dataJournaliere <-dataJournaliere +';'
					 + (volume_SOUHAIT with_precision 0)+';'
					 + (volume_REEL with_precision 0);
					 
				put (volume_SOUHAIT + (volSOUHAIT at idSolVari)) at: idSolVari in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at idSolVari)) at: idSolVari in: volREEL;
	 			if(volume_SOUHAIT > 0.0){
	 				put (max([surf,(surface at idSolVari)])) at: idSolVari in: surface;
	 			}					
			}
		}	
	 	
	 	return dataJournaliere;		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	string data <- "";
	 	bool first <- true;
	 	loop idSol over: mapGroupe.keys{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idSolVari <- string(idSol) +"_"+ vari.idEspeceCultivee;
				
				if ((volSOUHAIT at idSolVari) > 0){
					if(!first){
						data <-  data +"\n";
					}
					data <-  data + (dateCour.annee) +
						';'+string(idSol)+';'+vari.idEspeceCultivee+ ';' +
						 float(volSOUHAIT at idSolVari) with_precision 0 +';'+
						 float(volREEL at idSolVari) with_precision 0 + ';' +
						 ((surface at idSolVari) / nombreMeterCarreDansUnHectare) with_precision 1;
					 first<- false;
				}
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
		surface <- map<string,float>([]);
	 }
 		 			 
}

