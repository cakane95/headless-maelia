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
 *  disparitionIlots
 *  Author: Maelia
 *  Description: 
 */

model disparitionIlots

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/contourZoneMaelia.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/PlansAssolement/planAssolement.gaml"
import "../modeleAgricole/PlansAssolement/planAssolementFonctionsCroyances.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Agriculteurs/agriculteurFonctionsDeCroyances.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "../modeleCommun/clc.gaml"

global{
	string cheminDisparitionIlots <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/clc/disparitionIlots.csv'; // disparitionIlots  disparitionIlotsParAnnee

	/*
	 * *****************************************************************************************
	 * Publique
	 * Lit le fichier donnant le nombre dilots a disparaitre par ZH : remplissage map [idZH::nbIlotsDisparus]
	 */
	action constructionDisparitionIlots{		
		 matrix initDisparitionIlots <- matrix(csv_file (cheminDisparitionIlots,";",false));
		 //matrix initDisparitionIlots <- matrix(file (cheminDisparitionIlots));		
		 int nbLignes <- length(initDisparitionIlots column_at 0);	
		 	
		 loop i from: 1 to: ( nbLignes - 1 ) {
			list<string> ligneI <- (initDisparitionIlots row_at i);			
			int anneeLue <- int(ligneI at 0);
			zoneHydrographique zhLu <- mapZH at (ligneI at 1);
			string clcLu <- (ligneI at 2);
			list<string> idIlotsSuppression <- (ligneI at 3) tokenize ('_');
			
			disparitionIlots processusDisparition <- first(disparitionIlots where (each.zhAssociee = zhLu));			
			// creation du processus si existe pas
			if(processusDisparition = nil){				
				create disparitionIlots number: 1{
					zhAssociee <- zhLu;
				}
			}
			
			// Mise a jour map des ilots a disparaitre
			ask processusDisparition{
				list<ilot> ilotsArajouter <- nil;
				loop idIlot over: idIlotsSuppression{
					ilot nouveau <- mapIlots at idIlot;
					if(nouveau != nil){
						add nouveau to: ilotsArajouter;	
					}else{
						write "[DISPARITION ILOT] Ilos existe pas !!! " + idIlot;
					}					
				}
				
				list<ilot> ilots <- (mapDisparitionIlots at anneeLue) at clcLu;
				ilots <- ilots + ilotsArajouter;				
				put ilots at: clcLu in: (mapDisparitionIlots at anneeLue);		// TODO voir si ok ??		
			}
		}
	}
}


species disparitionIlots{ // par ZH
	zoneHydrographique zhAssociee <- nil;
	map<int,map<string,list<ilot>>> mapDisparitionIlots <- map([]); // annee::{idClasseClcRemplacantIlot::{ilotsAsupprimer}}    idClasseClcRemplacantIlot = bati ou foret, mise a jour tous les ans par le processus de disparition des ilots
	
	action comportementAnnuel{	
		map<string,list<ilot>> mapParIdClasse <- (mapDisparitionIlots at dateCour.annee); // typeClasse::{ilots}	
		ask(zhAssociee){
			do miseAjourHRUrpg(mapDisparitionIlots: mapParIdClasse);	
		}	
		do disparitionDesIlots();		
	}
					
	/*
	 * *****************************************************************************************
	 * Processus qui supprime les ilots
	 */
	action disparitionDesIlots{
		map<int,list<ilot>> mapParIdClasse <- (mapDisparitionIlots at dateCour.annee); // typeClasse::{ilots}

		loop idClasseClcCourant over: mapParIdClasse.keys{
			list<ilot> listeIlotsAsupprimer <- mapParIdClasse at idClasseClcCourant;
			clc clcPlusProche <- first(zhAssociee.landCoverAssocie where (each.idClasse = idClasseClcCourant));
			
			// Suppression de lilot partout ou il apparait (list, map...)
			ask listeIlotsAsupprimer{
				// Mise a jour de la geometry du clc le plus proche de l'ilot avant sa disparition
				set clcPlusProche.shape value: clcPlusProche.shape union self.shape;

				// zh :  mapSurfaceOccupeeParIlots
				remove self from: myself.zhAssociee.listeIlotsAssocies;						
				// agriculteur (exploiation) : sonExploitation.listeIlots
				remove self from: agriculteurAssocie.sonExploitation.listeIlots;
				
				ask(listeParcelles){						
//						// Plan dassolement						
//						// TODO voir comment faire ca pour que ca soit generqiue pour tout type d'agri
//						loop planCourant over: ((ilot_app.agriculteurAssocie).listePlans){
//							if(self in planCourant.SdCs){
//								remove key: self from: planCourant.SdCs;
//							}		
//						}
//						if(agriculteurFonctionsDeCroyances(ilot_app.agriculteurAssocie).dernierPlan != nil){
//							if(self in agriculteurFonctionsDeCroyances(ilot_app.agriculteurAssocie).dernierPlan.SdCs){
//								remove key: self from: agriculteurFonctionsDeCroyances(ilot_app.agriculteurAssocie).dernierPlan.SdCs;
//							}							
//						}							
//						remove self from: ilot_app.agriculteurAssocie.listeParcelles;
//						if(cultureParcelle != nil){
//							do die;
//						}
//						do die;
				}										
				do die;					
			}							
		}			
	}
}
