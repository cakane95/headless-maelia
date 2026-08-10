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
 *  equipementDeCaptage
 *  Author: Romain Lardy
 *  Description: Tous les points de prelevements, qu'ils soient industriel (IND), agricole (IRR) ou pour les collectivites (AEP)
 */

model equipementDeCaptageCanaux

import "ressourceEnEau.gaml"

global {	
	string canauxData <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/canaux/canaux.csv';			
	/*
	 * *****************************************************************************************
	 * Publique 
	 */ 
	action constructionEquipementsDeCaptageCanaux{	
		matrix InitCanaux <- matrix(csv_file(canauxData,";",false));
		//matrix InitCanaux <- matrix(file(canauxData));
		int nbColones <- length(InitCanaux row_at 0);
		int nbCanaux <- length(InitCanaux column_at 0);
		loop i from: 1 to: (nbCanaux -1){ // ligne 0 contient les entetes
			list ligneCourante <-  ( InitCanaux row_at i );
			// boucle sur les ppa de prelevement //cas relativement rare, traite par des | dans les chaines de caracteres
			list<string> listDonneesDetaillee <- string(ligneCourante at (3)) tokenize SEPARATEUR;
			list<string> listBVeOrigine <- string(ligneCourante at (2)) tokenize SEPARATEUR;
			list<string> listBesoinParDefautHiver <- string(ligneCourante at (4)) tokenize SEPARATEUR;
			list<string> listDebitMaxPrelevement <- string(ligneCourante at (7)) tokenize SEPARATEUR;
			
			int nbPointPrelevementPourCeCanal <- length(listDonneesDetaillee);
			
			loop jPointPrelevementCanaux from: 0 to: (nbPointPrelevementPourCeCanal -1){
				create equipementDeCaptageCanaux returns: eq{
					natureRessourcePrelevee <- SURF;
					typologie <- SURF;
					idRessourceEnEauAssociee <- listBVeOrigine at jPointPrelevementCanaux;
					if((mapZH at idRessourceEnEauAssociee) = nil){
						write "[canaux] Probleme le BVe "+ idRessourceEnEauAssociee+ " n'existe pas";
						ask self{
							do die;	
						}
					}
					location <- (mapZH at idRessourceEnEauAssociee).location;
					idEquipement <- string(ligneCourante at (1));
					canalAssocie <- mapCanaux at idEquipement;
					
					string nomfichierDonneesDetaillee <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +
														 '/modeleHydrographique/canaux/' + listDonneesDetaillee at jPointPrelevementCanaux;
					if (file_exists(nomfichierDonneesDetaillee)){
						prelevementObs <- matrix(csv_file(nomfichierDonneesDetaillee,";",false));
						//prelevementObs <- matrix(file(nomfichierDonneesDetaillee));
					}
					else{
						noData <- true;
						predict <- true;
					}
					
					besoinParDefaut <- float(listBesoinParDefautHiver at jPointPrelevementCanaux) *nbSecondesDansUneJournee ;
					
					//	ZHAvantObs	debitmax(m/s)
					string temp <- ligneCourante at (5) as string; //idPointRef
					ask pointDeReference where (each.idPointDeReference = temp){
						myself.pointDeReferencePourPrevision <- self;
					}
					temp <- ligneCourante at (6) as string;//ZHAvantObs
					zhEstimationBesoin <- mapZH at temp;
					debitmax <- float(listDebitMaxPrelevement at jPointPrelevementCanaux) *nbSecondesDansUneJournee;
					
					do initialisationEquipement();
					
					if(nbPointPrelevementPourCeCanal > 1){
						name <- string(ligneCourante at (0))+ "_"+ jPointPrelevementCanaux;
					}else{ // par defaut le nom du canal
						name <- string(ligneCourante at (0));
					}
					
					
					if(ressourceAssociee != nil){
						zoneHydrographiqueAssociee <- ressourceAssociee.zhAssociee;	
						listeEquipements << self;	
					}else{
						ask self{
							do die;	
						}	
					}
					canalAssocie.listEquipementAlimentantCeCanal << self;
				}
			}
			
			
			
		}
	}
}

species equipementDeCaptageCanaux parent: equipementDeCaptageIRR{	
	string acteurAssocie <- CAN;
	float besoinParDefaut <- 0.0 ; // besoin d'alimentation du canal en dehors de la periode de donnes
	// correspond en partie a l'hiver
	matrix prelevementObs <- nil;
	rgb couleurEquipement <- rgb('blue');
	canal canalAssocie <- nil;
	bool predict <- false;
	pointDeReference pointDeReferencePourPrevision <- nil;
	float debitmax <- 0.0 ; 
	map<int,float> prelevementsemainePasse <- map<int,float>([]);
    zoneHydrographique zhEstimationBesoin <- nil;
    bool noData <- false;
    map<int,float> restrictionDebitPrelevement <- map<int,float>([]);
    float volumeSouhait <- 0.0;				

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * debit par defaut ou debit lu en entree
	 */
	float getVolumeSouhaite{
		return  volumeSouhait;
	}
	
	
	
	float calculVolumeSouhaite{
		// le format actuel est jour puis une colonne par annee
		float volume <- besoinParDefaut - canalAssocie.volumeDuJourPrecedent;
		//Capter le cas particulier d une simulation commencant avant la periode obs
		if(!noData and (dateCour.nbJoursEcoulesDansAnnee = 1)){
			list annees <-  ( prelevementObs row_at 0 );
			if(dateCour.annee = int(annees at 1)){
				predict <- false;
			}
		}
		if (predict){
			//Volume dispo brut
			volume <- pointDeReferencePourPrevision.debitJournalier - pointDeReferencePourPrevision.dcr; 
			volume <-  volume *nbSecondesDansUneJournee; // [m.s-1] -> [m3 d-1]
			//volume dispo avec prise en compte des prelevement de la ZH du point de ref
			//on utilise la moyenne sur les 7 jours precedents
			volume <- volume - mean(prelevementsemainePasse.values) - canalAssocie.volumeDuJourPrecedent; //moins le volume deja present;
			volume <- max([0.0, volume]);
			volume <- min([volume,debitmax]);
			
			//Mise à jour de la table prelevementsemainePasse
			int i <- 7;
			loop while: (i>1){
				put (prelevementsemainePasse at (i-1)) at: i in: prelevementsemainePasse;
				i <- i -1;
			}
			if (zhEstimationBesoin != nil){
				
				zoneHydrographique tmp <- zhEstimationBesoin; //variable intermedaire necessaire
				float volumePreleveZH <- world.getVolumePreleve_1_ZH(IRR, REEL, tmp)
				  						//+ world.getVolumePreleve_1_ZH(CAN, REEL, tmp)
				  						+ world.getVolumePreleve_1_ZH(IND, REEL, tmp)
				  						+ world.getVolumePreleve_1_ZH(AEP, REEL, tmp);
				put volumePreleveZH at: 1 in: prelevementsemainePasse;
			}
			
		}else{
			list annees <-  ( prelevementObs row_at 0 );
			if (dateCour.annee >= int(annees at 1)) and (dateCour.annee <= int(annees at (length(annees) -1))){ // on est dans la periode de donnee obs
				int indiceY <- dateCour.annee -int(annees at 1) +1;
				int indiceJ <- dateCour.nbJoursEcoulesDansAnnee ;
				if (dateCour.isAnneeBissextile) and (dateCour.nbJoursEcoulesDansAnnee >= 60){
					indiceJ <- indiceJ -1;
				}
				if !((prelevementObs column_at indiceY) at indiceJ =""){
					volume <- (prelevementObs column_at indiceY) at indiceJ as float;
					volume <- min([debitmax, volume]) * nbSecondesDansUneJournee;
				}
				
			}
			else{
				predict <- true;
			}
		}
		volumeSouhait <- min([volume, getDebitMaxAutorise()]);  // debitMaXAutoriseParLa restriction!
		
		return  volumeSouhait;
	}
	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
		
		volumeReel <- getVolumeSouhaite() * pourcentage;
		
		ask ressourceAssociee{								
			do setMapVolumePreleveReel acteur:  myself.acteurAssocie valeur: myself.volumeReel;				
		}
		//Ajout de cet eau dans la resource canal!
		ask canalAssocie{
			volumeUtileAvantPrelevementEtRejet <- volumeUtileAvantPrelevementEtRejet + myself.volumeReel;
		} 				
	}
	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	bool isEnRestriction{	
		if(secteurAdministratifAssocie != nil){
			return secteurAdministratifAssocie.isEnRestriction();
		}else{
			return false;
		}
	}
	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	int getNiveauRestriction{
		if(isEnRestriction()){
			return secteurAdministratifAssocie.getNiveauRestriction();
		}else{
			return 0;
		}			
	}
	
	float getDebitMaxAutorise{
		if(isEnRestriction()){
			return restrictionDebitPrelevement at getNiveauRestriction();
		}else{
			return 1E20;
		}
		return 0.0;
	}
}
