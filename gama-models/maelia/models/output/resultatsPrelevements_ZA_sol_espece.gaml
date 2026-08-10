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

model resultatsPrelevements_za_sol_espece

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
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/Cultures/groupeIrrigationCulture.gaml"

global{
	action initialisationEcritureFichiersPrelevements_za_sol_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_za_sol_espece number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevements_za_sol_espece parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de za __ sol __ idEspece
	map<string,float> volREEL <- map<string,float>([]);
	map<string,float> surface <- map<string,float>([]);
	
	//list<string> listID <- [];
	map<string,list<parcelle>> mapGroupe <- map([]); //liste de parcelles par type de sol
	
	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_za_sol_espece'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
		//liste des parcelles Irrigable et Utile
		//sol a distinguer par nom
		ask listeParcellesUtiles{
			if(self.ilot_app.isIrrigable){
				string idSolZA <- self.ilot_app.getNomZonePedo() +"_" + self.ilot_app.getZAassociee();
				list<parcelle> listTemp <- myself.mapGroupe at idSolZA;
				listTemp << self;
				put listTemp at:idSolZA in:myself.mapGroupe;
			}
		}			
			
		
		loop idSolZA over: mapGroupe.keys{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idZaSolVari <- string(idSolZA) + "_"+ vari.idEspeceCultivee;
				dataJournaliere <-dataJournaliere +';'
					 + string(idZaSolVari)+'_SOUHAIT;'
					 + string(idZaSolVari)+'_REEL';
			}
		}
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_za_sol_espece'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;za;sol;espece;volSouhaite[m3];volReel[m3];surface(ha)';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	
	 	//parcellesUtilesIrrigables
	 	loop idSolZA over: mapGroupe.keys{
 			list<parcelle> tmp <- (mapGroupe at idSolZA);
 			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idSolZaVari <- string(idSolZA) + "_"+ vari.idEspeceCultivee;
				float volume_SOUHAIT <- 0.0;
				float volume_REEL <- 0.0;
				float surf <- 0.0;
				
				ask (tmp where ((each.getITKAnnee().especeCultiveeITK = vari) and
						 (length(each.listeGroupeIrrigationCulture) >0)))
				{
					if (self.ilot_app.ppaCourant != nil){
						volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee/nombreMillimetreDansUnMetre) * self.surface;
						volume_REEL <- volume_REEL + (self.irrigationReelle/nombreMillimetreDansUnMetre) * self.surface;
						surf <- surf + self.surface ;
					}
				}
				dataJournaliere <-dataJournaliere +';'
					 + string(volume_SOUHAIT with_precision 0) +';'
					 + string(volume_REEL with_precision 0);
					 
				put (volume_SOUHAIT + (volSOUHAIT at idSolZaVari)) at: idSolZaVari in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at idSolZaVari)) at: idSolZaVari in: volREEL;
	 			put (max([surf,(surface at idSolZaVari)])) at: idSolZaVari in: surface;
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
	 	loop za over: listZonesAdministratives{
	 		loop idSol over: listNomZonePedo{
	 			string idSolZA <- idSol +"_" + za;
	 			list<parcelle> tmp <- (mapGroupe at idSolZA);
				loop vari over: listeEspecesCultiveesParOrdreSaisie{
					string idSolZaVari <- string(idSol)+ "_"+string(za.idZoneAdministrative) +"_"+   vari.idEspeceCultivee;
					
					if ((volSOUHAIT at idSolZaVari) > 0){
						if(!first){
							data <-  data +"\n";
						}
						data <-  data + (dateCour.annee) +
							';'+string(za.idZoneAdministrative)+';'+string(idSol)+';'+vari.idEspeceCultivee+ ';' +
							 float(volSOUHAIT at idSolZaVari) with_precision 0 +';'+
							 float(volREEL at idSolZaVari) with_precision 0 +
							 ";"+ ((surface at idSolZaVari)/nombreMeterCarreDansUnHectare) with_precision 1 ;
						first<- false;
					}
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

