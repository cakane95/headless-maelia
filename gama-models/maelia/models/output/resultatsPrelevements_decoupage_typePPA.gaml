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

model resultatsPrelevements_decoupage_typePPA

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
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"

global{
	action initialisationEcritureFichiersPrelevements_decoupage_typePPA{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_decoupage_typePPA number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}

//Utilise les donnees globales suivante 
//	string filePrelevement_decoupagePPA <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +	 '/modeleCommun/communes/communes-trimUG.shp' ;
//	string VariableDecoupagePrelevement_decoupagePPA <- "NOM";

species resultatsPrelevements_decoupage_typePPA parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de id_decoupage __ typePPA
	map<string,float> volREEL <- map<string,float>([]);
	
	//list<string> listID <- [];
	map<string,list<equipementDeCaptageIRR>> mapGroupe <- map([]); //liste de equipementDeCaptageIRR par cle du decoupage
	list<decoupageSortie> listDecoupage <- [];
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{
		string dataJournaliere <- 'date';
		if(file_exists(filePrelevement_decoupagePPA)){
			nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_decoupage_PPA'+ nomDeLaSimulation + '.csv';
		
			create species: decoupageSortie from: file(filePrelevement_decoupagePPA) with: [name::string(read ( VariableDecoupagePrelevement_decoupagePPA))]{
				myself.listDecoupage << self;
			}
			
			list<equipementDeCaptageIRR> listEquipementAaffecter <- (equipementDeCaptageIRR as list) ;
			int nbEquipAaffecter <- length(listEquipementAaffecter);
			int compteur <- 0;
			ask listDecoupage{
				list<equipementDeCaptageIRR> listTemp <- listEquipementAaffecter inside(self);
				map<string,list<equipementDeCaptageIRR>> listEquipTriee <- ( listTemp group_by (each.natureRessourcePrelevee));
				loop nat over:listEquipTriee.keys{
					put (listEquipTriee at nat) at: (nat+'__'+self.name) in: myself.mapGroupe;
				}
				listEquipementAaffecter <- listEquipementAaffecter - listTemp;
				compteur <- compteur + length(listTemp);
			}

			if (compteur < nbEquipAaffecter) {
				ask listDecoupage{
					shape <- shape + 50;
					list<equipementDeCaptageIRR> listTemp <- listEquipementAaffecter inside(self);
					map<string,list<equipementDeCaptageIRR>> listEquipTriee <- ( listTemp group_by (each.natureRessourcePrelevee));
					loop nat over:listEquipTriee.keys{
						put ((listEquipTriee at nat)+ (myself.mapGroupe at (nat+'__'+self.name))) at: (nat+'__'+self.name) in: myself.mapGroupe;
					}
					listEquipementAaffecter <- listEquipementAaffecter - listTemp;
					compteur <- compteur + length(listTemp);
				}
			}
			if(compteur < nbEquipAaffecter){
				write "Attention tous les ppa irrigations ("+( nbEquipAaffecter - compteur)+") n ont pas ete affectees dans le zonage";
			}
			loop idDecoupage over: mapGroupe.keys{
				dataJournaliere <- dataJournaliere+";"+ idDecoupage +"_SOUHAIT;"+ idDecoupage +"_REEL" ;
			}
			ask listDecoupage{
				do die();
			}
		}else{
			write "probleme le fichier de decoupage des prelevements par type ppa n existe pas : "+ filePrelevement_decoupagePPA;
		}				
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_decoupage_PPA'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;NATURE;id;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	
	 	
	 	loop idDecoupage over: mapGroupe.keys{
	 		float volume_SOUHAIT <- 0.0;
			float volume_REEL <- 0.0;
	 		loop ppa over: (mapGroupe at idDecoupage){
	 			volume_SOUHAIT <- volume_SOUHAIT + equipementDeCaptageIRR(ppa).getVolumeSouhaite();
	 			volume_REEL <- volume_REEL + equipementDeCaptageIRR(ppa).getVolumeReel();
	 		}
	 		
	 		dataJournaliere <-dataJournaliere +';'
					 + string(volume_SOUHAIT with_precision 0)+';'
					 + string(volume_REEL with_precision 0);
					 
				put (volume_SOUHAIT + (volSOUHAIT at idDecoupage)) at: idDecoupage in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at idDecoupage)) at: idDecoupage in: volREEL;
			
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
			if ((volSOUHAIT at idDecoupage) > 0){
				if(!first){
					data <-  data +"\n";
				}
				data <-  data + (dateCour.annee) +
					';'+string(idDecoupage tokenize "__" at 0)+
					 ";"+string(idDecoupage tokenize "__" at 1) +";"+
					 float(volSOUHAIT at idDecoupage) with_precision 0 +';'+
					 float(volREEL at idDecoupage) with_precision 0 ;
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
	
