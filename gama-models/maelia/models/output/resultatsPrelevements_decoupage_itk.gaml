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

model resultatsPrelevements_decoupage_itk

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "ecritureResultats.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleNormatif/secteurAdministratif.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleHydrographique/equipement.gaml"

global{
	action initialisationEcritureFichiersPrelevements_decoupage_itk{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_decoupage_itk number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

//Utilise les donnees globales suivante 
//string filePrelevement_decoupage_itk <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +	 '/modeleCommun/communes/communes-trimUG.shp' ;
//string VariableDecoupagePrelevement_decoupage_itk <- "NOM";

species resultatsPrelevements_decoupage_itk parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de decoupage __ idITK
	map<string,float> volREEL <- map<string,float>([]);
	
	//list<string> listID <- [];
	map<string,list<parcelle>> mapGroupe <- map([]); //liste de parcelles par cle du decoupage
	
	list<itk> listeITKIrrigables <- [];
	list<decoupageSortie> listDecoupage <- [];
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string dataJournaliere <- 'date';
		if(file_exists(filePrelevement_decoupage_itk)){
			nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_decoupage_itk'+ nomDeLaSimulation + '.csv';
		
			create species: decoupageSortie from: file(filePrelevement_decoupage_itk) with: [name::string(read ( VariableDecoupagePrelevement_decoupage_itk))]{
				myself.listDecoupage << self;
			}
		
			//construction liste ITks irrigables
			loop it over: listeITKs{
				if (it.strategieIrrigationITK != nil){
					listeITKIrrigables << it ;
				}
			}
			
			
			int compteur <- 0;
			list<parcelle> parcelleUtileIrrigableAffectable <- (listeParcellesUtiles where each.ilot_app.isIrrigable);
			int nbParcelleUtileIrrigable <- length(parcelleUtileIrrigableAffectable);
			ask listDecoupage{
				list<parcelle> listTemp <- (parcelleUtileIrrigableAffectable where each.ilot_app.isIrrigable) inside(self);
				put listTemp at: self.name in:  myself.mapGroupe;
				compteur <- compteur + length(listTemp);
				parcelleUtileIrrigableAffectable <- parcelleUtileIrrigableAffectable - listTemp;
			}
			
			int i <- 0; // ajout jusqu'à 400 m de buffer
			loop while: ((compteur < nbParcelleUtileIrrigable) and (i < 4)){
				ask listDecoupage{ // on recommence avec un buffer de 50 m
					shape <- shape + 50;
					list<parcelle> listTemp <- (parcelleUtileIrrigableAffectable where each.ilot_app.isIrrigable) inside(self);
					put (listTemp + (myself.mapGroupe at self.name)) at: self.name in:  myself.mapGroupe;
					compteur <- compteur + length(listTemp);
					parcelleUtileIrrigableAffectable <- parcelleUtileIrrigableAffectable - listTemp;
				}
				i <- i +1;
			}
			
			if(compteur != nbParcelleUtileIrrigable){
				write "ATTENTION le decoupage spatial pose probleme : parcelles non affectees ou comptees au moins deux fois";
				write "parcelles affectees : "+ compteur + " vs. parcelles utiles et irrigables : "+ nbParcelleUtileIrrigable;
				write length(parcelleUtileIrrigableAffectable);
				write parcelleUtileIrrigableAffectable;
			}
			
			loop idDecoupage over: mapGroupe.keys{
				dataJournaliere <- dataJournaliere+";"+ idDecoupage +"_SOUHAIT;"+ idDecoupage +"_REEL" ;
			}
			
			
			loop idDecoupage over: mapGroupe.keys{
				loop it over: listeITKIrrigables{
					string id <- string(idDecoupage) +"_"+ it.nomPourAffichage+ "_"+ it.matITK.idMateriel;
					dataJournaliere <-dataJournaliere +';'
						 + string(id)+'_SOUHAIT;'
						 + string(id)+'_REEL';
				}
			}
			ask listDecoupage{
				do die();
			}
		}else{
			write "probleme le fichier de decoupage des prelevements par itk n existe pas ";
		}				
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_decoupage_itk'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;decoupage;itk;materielIrrigation;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	
	 	loop idDecoupage over: mapGroupe.keys{
			loop it over: listeITKIrrigables{
				string id <- string(idDecoupage) +"_"+ it.nomPourAffichage+ "_"+ it.matITK.idMateriel;
				float volume_SOUHAIT <- 0.0;
				float volume_REEL <- 0.0;
				list<parcelle> tmp <- (mapGroupe at idDecoupage);
				ask (tmp where (each.getITKAnnee() = it)){
					volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee/nombreMillimetreDansUnMetre) * self.surface;
					volume_REEL <- volume_REEL + (self.irrigationReelle/nombreMillimetreDansUnMetre) * self.surface;
				}
				dataJournaliere <-dataJournaliere +';'
					 + string(volume_SOUHAIT with_precision 0)+';'
					 + string(volume_REEL with_precision 0);
					 
				put (volume_SOUHAIT + (volSOUHAIT at id)) at: id in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at id)) at: id in: volREEL;
				
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
	 	loop idDecoupage over: mapGroupe.keys{
			loop it over: listeITKIrrigables{
				string id <- idDecoupage +"_"+ it.nomPourAffichage+ "_"+ it.matITK.idMateriel;
				
				if ((volSOUHAIT at id) > 0){
					if(!first){
						data <-  data +"\n";
					}
					data <-  data + (dateCour.annee) +
						';'+string(idDecoupage)+';'+it.nomPourAffichage+
						';'+it.matITK.idMateriel +';' +
						 float(volSOUHAIT at id) with_precision 0 +';'+
						 float(volREEL at id) with_precision 0 ;
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
	 }
 		 			 
}
	
