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
 *  Equipements
 *  Author: Maroussia Vavasseur
 *  Description: equipement est la classe mere des equipements de type rejet et captage
 */

model equipement

import "../modeleCommun/idVariablesShapfile.gaml"
import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/commune.gaml"
import "zoneHydrographique.gaml"
import "ressourceEnEau.gaml"
import "equipementDeCaptage.gaml"
import "equipementDeCaptageAEP.gaml"
import "equipementDeCaptageIND.gaml"
import "equipementDeCaptageIRR.gaml"
import "equipementDeCaptageCanaux.gaml"
import "equipementDeRejet.gaml"
import "equipementDeRejetAEP.gaml"
import "equipementDeRejetIND.gaml"
import "equipementDeRejetCanaux.gaml"
 
global {
	list<equipement> listeEquipements <- [];
	map<string,float> mapVolumeConsommeReelJourPrecedent_ZM <- map(["AEP"::0.0,"IND"::0.0,"CAN"::0.0]);

	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action constructionEquipements{
		do constructionEquipementsDeCaptageAEP();
		do constructionEquipementsDeCaptageIND();
		do constructionEquipementsDeCaptageIRR();
		do constructionEquipementsDeRejetAEP();
		do constructionEquipementsDeRejetIND();
		if (isCanaux){
			//Creation des points de prelevement de l'eau pour les canaux //1 seul point de prelevement par canal
			do constructionEquipementsDeCaptageCanaux();
			//Creation des points de retour des canaux
			do constructionEquipementsDeRejetCAN();
		}		
	}
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action creationEquipements(string cheminEntree <- "", species<equipement> typeEquipement <- equipement) {
		
		if(file_exists(cheminEntree)){
			create typeEquipement from: file(cheminEntree) with: [ 	idEquipement::string(read( ID_EQU )), 
																natureRessourcePrelevee::string(read( NATURE )),
																typologie::string(read( NATURE )),
																codeInseeAssocie::string(read( CODE_INSEE )),
																tauxSurZM::float(read( TAUX )),
																idRessourceEnEauAssociee::string(read( ID_RESS_ZH ))]{	
																	
				//CODE_IRRIG
				string codeIrrig <- string(shape get( CODE_IRRIG ));
				if(!(empty(codeIrrig)) and (codeIrrig != nil)){
					if(!(codeIrrig contains "NULL")){
						idEquipement <- idEquipement + "--"+codeIrrig;
					}		
				}
				name <- idEquipement;
				do initialisationEquipement();
				if(ressourceAssociee != nil){
					zoneHydrographiqueAssociee <- ressourceAssociee.zhAssociee;	//On recupere l'info depuis la ressource associee
					// plutot que dans le fichier sous le nom ID_ZH; En effet cette variable peut etre null si PP situe a la limite de la zone
					listeEquipements << self;	
					// Uniquement pour les equipements IRR (mais evite de le reecrire la methode)
					if(shape get(ID_ASA) != nil){
						if(string(shape get(ID_ASA)) != ""){
							(equipementDeCaptageIRR(self)).isASA <- true;
							(equipementDeCaptageIRR(self)).idASA <- string(shape get(ID_ASA));
						}							
					}
				}else{
					if (!executerModeleSurUneZH){
						write name + ' - ' + natureRessourcePrelevee + ' - [EQUIPEMENTcaptage/init] pb ressourceAssociee nulle !!! = ' + idRessourceEnEauAssociee;	
					}
					ask self{
						do die;	
					}	
				}
			}	
		}
	}
	
	/*
	 * Appele journalierement depuis le main, apres le calcul de tous les volumes preleve reel (apres SWAT)
	 */
	action calculVolumeConsommeReel_ZM{
		put getVolumePreleve_EQU_ZM(acteur:AEP, type:REEL) at: AEP in: mapVolumeConsommeReelJourPrecedent_ZM;
		put getVolumePreleve_EQU_ZM(acteur:IND, type:REEL) at: IND in: mapVolumeConsommeReelJourPrecedent_ZM;
		put getVolumePreleve_EQU_ZM(acteur:CAN, type:REEL) at: CAN in: mapVolumeConsommeReelJourPrecedent_ZM;
	}
	
	float getVolumePreleve_EQU_ZM{
		arg acteur type: string default: AEP;
		arg type type: string default: SOUHAITE;
		
		float volume <- 0.0;
		list<equipementDeCaptage> liste <- mapEquipementsDeCaptage at acteur;
		ask (liste){
			volume <- volume + getVolume(type);		
		}		
		return volume;
	}
	float getVolumePreleve_1_ZH(string acteur <- AEP,
		string type <- SOUHAITE,
		zoneHydrographique zhConsidere <- nil
	){
		float volume <- 0.0;
		list<equipementDeCaptage> liste <- mapEquipementsDeCaptage at acteur;
		ask (liste where (each.zoneHydrographiqueAssociee = zhConsidere)){
			volume <- volume + getVolume(type);
		}		
		return volume;
	}
	
	float getVolumePreleve_ACTEUR_NATURE_ZH(string acteur <- AEP,
		string type <- SOUHAITE,
		string natureConsidere <- SURF,
		zoneHydrographique zhConsidere <- nil
	){
		float volume <- 0.0;
		list<equipementDeCaptage> liste <- mapEquipementsDeCaptage at acteur;
		ask (liste where ((each.zoneHydrographiqueAssociee = zhConsidere) and (each.natureRessourcePrelevee=natureConsidere))){
			volume <- volume + getVolume(type);
		}		
		return volume;
	}	
	// Forcement Reel
	float getVolumeRejet_EQU_ZM{
		arg acteur type: string default: AEP;
		
		float volume <- 0.0;
		list<equipement> liste <- mapEquipementsDeRejet at acteur;
		ask (liste){
			volume <- volume + volumeReel;	
		}		
		return volume;
	}	
	// Forcement Reel, il ny a pas de rejet souhaite
	float getVolumeConsome_EQU_ZM{
		arg acteur type: string default: AEP;
			
		return getVolumePreleve_EQU_ZM(acteur, REEL) - getVolumeRejet_EQU_ZM(acteur);
	}	
	float getSommeVolumePreleve_EQU_ZM{
		arg type type: string default: SOUHAITE;

		return getVolumePreleve_EQU_ZM(AEP,type) + getVolumePreleve_EQU_ZM(IND,type) + getVolumePreleve_EQU_ZM(IRR,type) + getVolumePreleve_EQU_ZM(CAN,type);
	}
	float getSommeVolumeRejet_EQU_ZM{
		return getVolumeRejet_EQU_ZM(AEP) + getVolumeRejet_EQU_ZM(IND) + getVolumeRejet_EQU_ZM(IRR) + getVolumeRejet_EQU_ZM(CAN);
	}
	float getSommeVolumeConsome_EQU_ZM{
		return getVolumeConsome_EQU_ZM(AEP) + getVolumeConsome_EQU_ZM(IND) + getVolumeConsome_EQU_ZM(IRR)+ getVolumeConsome_EQU_ZM(CAN) ;
	}	
	float getConsoParHabitantParJour{		
		return (getVolumeConsome_EQU_ZM(AEP) / getNbHabitants_ZM());	
	}							
}

species equipement{
	string idEquipement <- '';
	string acteurAssocie <- '';
	string codeInseeAssocie <- '';	
	zoneHydrographique zoneHydrographiqueAssociee <- nil;
	float volumeReel <- 0.0;				
	string natureRessourcePrelevee <- '';	 // SURF, NAPP ou RET ou CAN
	string typologie <- '';	 // SURF, NAPP, RET ou ASA
	ressourceEnEau ressourceAssociee <- nil;
	rgb couleurEquipement <- rgb('white');
	string idRessourceEnEauAssociee <- '';	
	float tauxSurZM <- 0.0;		// Si on applique ce taux sur le volume total de la zoneMaelia (ZM) on aura le volume du point		
	
	/*
	 * *****************************************************************************************
	 */		
	action initialisationEquipement{}

	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		do miseAJourVolumeSouhaite();
	}
			
	/*
	 * *****************************************************************************************
	 */
	float getVolumeSouhaite{
		return 0.0;
	}
	/*
	 * *****************************************************************************************
	 */
	float getVolumeReel{
		return 0.0;
	}		
	/*
	 * *****************************************************************************************
	 */
	action miseAJourVolumeSouhaite{
		arg volumeApreleverEntree type: float default: 0.0;
	}

	/*
	 * *****************************************************************************************
	 */
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
	}

	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw circle(taillePoints) color: couleurEquipement border: couleurEquipement;
	}
		
	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- "[EQU] " + name; 
		resultat <- resultat + ' / idEquipement  : ' + idEquipement;	
		resultat <- resultat + ' / volumeReel : ' + volumeReel;	 			
		return resultat;			 			
		}	
}
