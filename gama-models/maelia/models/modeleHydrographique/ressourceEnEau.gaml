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
 *  ressourceEnEau
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model ressourceEnEau

import "nappePhreatique.gaml"

global{
	map<string,list<ressourceEnEau>> mapRessourcesEnEau <- map([]); // 'SURF'::{listCoursDeau};...
		
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action creationRessourcesEnEau{ // Attention non appele
        do constructionCoursDeau();                    
        do constructionNappePhreatique(); 
        do constructionRetenueCollinaire();
        do constructionCanaux();                          
	}

	list<ressourceEnEau> constructionRessourcesEnEau(species<ressourceEnEau> typeRessource <- ressourceEnEau, string cheminShp <- "", string type <- ""){
		
		list<ressourceEnEau> listeSortie <- [];
		
		create typeRessource from: file(cheminShp) {
			zhAssociee <- mapZH at string(shape get( ID_ZH ));				
						
			// Suppression des zones meteos nappartenat pas a la zone detude
			if(zhAssociee = nil){
				ask self{
					do die;	
				}						
			}else{	
				id <- string(shape get( ID_RESSOUR ));			
				natureRessourcePrelevee <- type;
				
				do initialisation();
				add self to: listeSortie;
			}
			do complementConstructionRessourceEau();
		}	
		return	listeSortie;
	}
}

species ressourceEnEau{
	string id <- '';
	string natureRessourcePrelevee <- ''; // SURF, NAPP, RET ou CAN
	zoneHydrographique zhAssociee <- nil;		
	map<string,list<equipementDeCaptage>> mapEquipementsCaptageAssocies <- map([]); // acteur::listeEqu
	float volumeDuJourPrecedent <- 0.0; // Utile au moment du choix des equipements a solliciter dans les groupes dirrigation
	float volumeUtileAvantPrelevementEtRejet <- 0.0; // mise a jour dans ZH			
	map<string,float> mapVolumePreleveSouhaite <- map<string,float>([]); // AEP:volume;IND:vol;IRR:vol  // mise a jour dans equ captage AEP
	map<string,float> mapVolumePreleveReel <- map<string,float>([]);
	map<string,float> mapVolumeRejetReel <- map<string,float>([]);
	// Affichage
	rgb couleurRessource <- rgb('blue'); 
				 							
	action initialisation{	
		list<ressourceEnEau> liste <- mapRessourcesEnEau at natureRessourcePrelevee;
		add self to: liste;
		put liste at: natureRessourcePrelevee in: mapRessourcesEnEau;
			
		ask zhAssociee{			
			liste <- ressourceEnEauAssociees at myself.natureRessourcePrelevee;
			add myself to: liste;
			put liste at: myself.natureRessourcePrelevee in: ressourceEnEauAssociees;
		}
	}

	action complementConstructionRessourceEau{}

	action miseAzero{
		if(!(id in ID_RESSOURCES_INFINIES)){
			volumeDuJourPrecedent <- max([0.0, volumeUtileAvantPrelevementEtRejet - getVolumePreleveReel()]);
		}else{
			volumeDuJourPrecedent <- quantiteEauMaxDispoAgri;
		}
		volumeUtileAvantPrelevementEtRejet <- 0.0;	
		mapVolumePreleveSouhaite <- map<string,float>([]);
		mapVolumePreleveReel <- map<string,float>([]);
		do complementMiseAzero();
	}
	action complementMiseAzero{}
	
	float getVolumePreleve{
		arg type type: string default: SOUHAITE; 			

		if(type = SOUHAITE){
			return getVolumePreleveSouhaite();
		}else if(type = REEL){
			return getVolumePreleveReel();
		}
	}		
	float getVolumePreleveSouhaite{
		if(!empty(mapVolumePreleveSouhaite)){
			return sum(mapVolumePreleveSouhaite.values);
		}else{
			return 0.0;
		}						
	}	
	float getVolumePreleveReel{
		if(!empty(mapVolumePreleveReel)){
			return sum(mapVolumePreleveReel.values);
		}else{
			return 0.0;
		}
	}
	float getVolumeUtileApresPrelevementEtRejet{
		return volumeUtileAvantPrelevementEtRejet - getVolumePreleveReel();
	}
	float getVolumeUtileAvantPrelevementEtRejet{
		return volumeUtileAvantPrelevementEtRejet;
	}		
	action setMapVolumePreleveSouhaite{
		arg acteur type: string default: '';
		arg valeur type: float default: 0.0;
		
		float temp <- valeur + (mapVolumePreleveSouhaite at acteur);
		put temp at: acteur in: mapVolumePreleveSouhaite;				
	}
	action setMapVolumePreleveReel{
		arg acteur type: string default: '';
		arg valeur type: float default: 0.0;
		
		float temp <- valeur + (mapVolumePreleveReel at acteur);
		put temp at: acteur in: mapVolumePreleveReel;				
	}
	action setMapVolumeRejetReel{
		arg acteur type: string default: '';
		arg valeur type: float default: 0.0;
		
		float temp <- valeur + (mapVolumeRejetReel at acteur);
		put temp at: acteur in: mapVolumeRejetReel;
	}		
	action ajouterEquipementDeCaptage{
		arg acteur type: string default: '';
		arg equipementAajouter type: equipementDeCaptage default: nil;
		
		list<equipementDeCaptage> liste <- (mapEquipementsCaptageAssocies at acteur);
		add equipementAajouter to: liste;
		put liste at: acteur in: mapEquipementsCaptageAssocies;				
	}		

	// Pour les cour d'eau et les canaux
	action ajouterEquipementDeRejet (string acteur<-'',
		equipementDeRejet equipementAajouter <- nil
	){
						
	}

	/* 
	 * Appelee depuis ZH
	 */				
	action calculVolumePrelevesReels{		 	
	 	float volumeRestant <- volumeUtileAvantPrelevementEtRejet;
		map<string,float> pourcentage <- map<string,float>([]);

		// Il faut appeler les equipements par ordre de priorite : AEP, IND, IRR
		loop acteur over: ACTEURS_PAR_PRIORITE{
			if(mapVolumePreleveSouhaite at acteur != nil){
				float volumeSouhaite <- mapVolumePreleveSouhaite at acteur;
				float  pourcentageApresContrainteDebit <- 1.0;
				if(acteur=IRR) and (executerModeleNormatif){
					loop eq over:(mapEquipementsCaptageAssocies at IRR){
						float demande <- sum(equipementDeCaptageIRR(eq).mapVolumeSouhaiteParParcelle.values); //m3
						demande <- demande/nbSecondesDansUneJournee;
						float quotaDebitDelaPeriode <- equipementDeCaptageIRR(eq).getQuotaDebit(dateCour.nbJoursEcoulesDansAnnee);
						if(demande > quotaDebitDelaPeriode) and (demande > 0.0)
							and (quotaDebitDelaPeriode > -1){
							pourcentageApresContrainteDebit <- quotaDebitDelaPeriode/demande;
						}
					} 
				}
				
				
				if(volumeRestant >= 0.0 and volumeRestant < volumeSouhaite * pourcentageApresContrainteDebit){					
					put (volumeRestant / (volumeSouhaite* pourcentageApresContrainteDebit)) at: acteur in: pourcentage;
				}else if(volumeRestant >= (volumeSouhaite * pourcentageApresContrainteDebit)){
					put pourcentageApresContrainteDebit at: acteur in: pourcentage;
				}else{
					put 0.0 at: acteur in: pourcentage;
				}
				volumeRestant <- max([0.0, (volumeRestant - volumeSouhaite * pourcentageApresContrainteDebit)]);
				}			
		}

		// Mise a jour volume preleve reels des equipements
		list<equipementDeCaptage> liste <- interleave(mapEquipementsCaptageAssocies.values);
		// JV debug
	 	ask liste{	 		
	 		do miseAJourVolumeReel(pourcentage at acteurAssocie);
		}	
	}	


	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw shape color: couleurRessource;
		draw '' + int(volumeUtileAvantPrelevementEtRejet) at: location color: rgb('black') size: taillePointsMax;
	}	
	
	string toString{		
		return natureRessourcePrelevee + ' - ' + name + ' - zhAssociee = ' + zhAssociee+ ' - mapVolumePreleveSouhaite = ' + mapVolumePreleveSouhaite + ' - mapVolumePreleveReel = ' + mapVolumePreleveReel;
	}
}
