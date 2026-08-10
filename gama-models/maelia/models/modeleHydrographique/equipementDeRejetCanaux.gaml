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
 *  equipementDeRejetIND
 *  Author: Romain Lardy
 *  Description: 
 */

model equipementDeRejetCanaux

import "../modeleCommun/donneesGlobales.gaml"
import "zoneHydrographique.gaml"
import "equipement.gaml"
import "equipementDeRejet.gaml"
import "canaux.gaml"
import "ressourceEnEau.gaml"
import "../modeleCommun/dateCourante.gaml"


global{
	string canauxData <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/canaux/canaux.csv';			
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Je cree un point de rejet au centre de chaque ZH
	 */ 
	action constructionEquipementsDeRejetCAN{
		matrix InitCanaux <- matrix(csv_file(canauxData,";",false));
		//matrix InitCanaux <- matrix(file(canauxData));
		int nbColones <- length(InitCanaux row_at 0);
		int nbCanaux <- length(InitCanaux column_at 0);
		loop i from: 1 to: (nbCanaux -1){ // ligne 0 contient les entetes
			list ligneCourante <-  ( InitCanaux row_at i );
			
			float sommefractionData <- 0.0;
			float sommefractionNoData <- 0.0;
			
			loop j from: 1 to:(nbColones - 8)/3{
				int idx <- 8 + (j-1) * 3;
				string ZHretour <- string(ligneCourante at (idx));
				if (ZHretour != ''){
					create equipementDeRejetCAN returns: eq{
						
						natureRessourcePrelevee <- SURF;
						typologie <- SURF;
						idRessourceEnEauAssociee <- ZHretour;
						if((mapZH at idRessourceEnEauAssociee) = nil){
							write "[canaux] Probleme le BVe "+ idRessourceEnEauAssociee+ " n'existe pas";
							ask self{
								do die;	
							}
						}
						location <- (mapZH at idRessourceEnEauAssociee).location;
						idEquipement <- string(ligneCourante at (1));
						canalAssocie <- mapCanaux at idEquipement;
						// Il peut y avoir plusieurs ppa d entree mais ici on cherche juste a savoir si on a presence
						// d une donnee ou non (pour determiner les fractions de rejet
						// alors on ne considere que le premier point
						list<string> dataFiles <- string(ligneCourante at (3)) tokenize SEPARATEUR;
						string nomfichierDonneesDetaillee <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +
									 '/modeleHydrographique/canaux/' + first(dataFiles);
						if (file_exists(nomfichierDonneesDetaillee)){
							prelevementObs <- matrix(csv_file(nomfichierDonneesDetaillee,";",false));
							//prelevementObs <- matrix(file(nomfichierDonneesDetaillee));
						}
						else{
							noData <- true;
						}
						
						fractionData <- float(ligneCourante at (idx +1));
						sommefractionData <- sommefractionData + fractionData; 
						fractionNoData <- float(ligneCourante at (idx +2));
						sommefractionNoData <- sommefractionNoData + fractionNoData; 
						
						list<ressourceEnEau> listeRes <- (mapRessourcesEnEau at natureRessourcePrelevee);				
						ressourceAssociee <- first(listeRes where (each.id = idRessourceEnEauAssociee));
		
						ask (ressourceAssociee){
							do ajouterEquipementDeRejet acteur: myself.acteurAssocie equipementAajouter: myself;				 				 	
						}
						list<equipementDeRejet> listeTemp <- (mapEquipementsDeRejet at acteurAssocie) as list<equipementDeRejet>;
						add self to: listeTemp;
						put listeTemp at: acteurAssocie in: mapEquipementsDeRejet;
						
						name <- string(ligneCourante at (0)) + "-"+ ZHretour;
						if(ressourceAssociee != nil){
							ask listeZonesHydrographiques where (each.idZoneHydrographique = ZHretour){
								myself.zoneHydrographiqueAssociee <- self;	
							}
							if (zoneHydrographiqueAssociee = nil){
								ask self{
									do die;	
								}
							}else{
								listeEquipements << self;	
							}
						}else{
							ask self{
								do die;	
							}	
						}
						canalAssocie.listEquipementSortieCanal << self;
					}
				}
			}
			if((sommefractionData -1.0 )> 1.0E-4 ){
				write "Probleme dans les definitions de la gestion des canaux : la somme des fractions de rejet"+ 
						" en presence de donnees de forcages d'alimentation est superieur a 1, pour le canal "+ string(ligneCourante at (1));
			}
			if((sommefractionNoData -1.0 )> 1.0E-4 ){
				write "Probleme dans les definitions de la gestion des canaux : la somme des fractions de rejet"+ 
						" en absence de donnees de forcages d'alimentation est superieur a 1, pour le canal "+ string(ligneCourante at (1));
			}
			if(1.0 -sommefractionData )> 1.0E-4 {
				sommefractionData <- 1.0 -sommefractionData;
				write "En presence de donnees de forcage d'alimentation du canal "+ string(ligneCourante at (1)) +", " + sommefractionData *100 +
					 " % du volume du canal est rejette en dehors du territoire";
			}else{
				sommefractionData <- 0.0;
			}
			
			if(1.0 -sommefractionNoData )> 1.0E-4 {
				sommefractionNoData <- 1.0 -sommefractionNoData;
				write "En absence de donnees de forcage d'alimentation du canal "+ string(ligneCourante at (1)) +", "+ sommefractionNoData *100 +
					 " % du volume du canal est rejette en dehors du territoire";
			}else{
				sommefractionNoData <- 0.0;
			}
 		 	if( (sommefractionNoData > 0.0) or (sommefractionData > 0.0) ){
				create equipementDeRejetCAN returns: eq{
						
					natureRessourcePrelevee <- SURF;
					typologie <- SURF;
					idEquipement <- string(ligneCourante at (1));
					canalAssocie <- mapCanaux at idEquipement;
					if(canalAssocie = nil){
						write "suppression du canal " + idEquipement; 
						ask self{
							do die();
						}
					}
					// Il peut y avoir plusieurs ppa d entree mais ici on cherche juste a savoir si on a presence
					// d une donnee ou non (pour determiner les fractions de rejet
					// alors on ne considere que le premier point
					list<string> dataFiles <- string(ligneCourante at (3)) tokenize SEPARATEUR;
					string nomfichierDonneesDetaillee <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +
								 '/modeleHydrographique/canaux/' + first(dataFiles);
					if (file_exists(nomfichierDonneesDetaillee)){
						//prelevementObs <- matrix(csv_file(nomfichierDonneesDetaillee,";"));
						prelevementObs <- matrix(file(nomfichierDonneesDetaillee));
					}
					else{
						noData <- true;
					}
					
					fractionData <- sommefractionData;
					fractionNoData <- sommefractionNoData;
				
					ressourceAssociee <- nil;
					
					list<equipementDeRejet> listeTemp <- (mapEquipementsDeRejet at acteurAssocie) as list<equipementDeRejet>;
					add self to: listeTemp;
					put listeTemp at: acteurAssocie in: mapEquipementsDeRejet;
					
					name <- string(ligneCourante at (0)) + "-HZ";
					listeEquipements << self;	
					canalAssocie.listEquipementSortieCanal << self;
					canalAssocie.equipementRejetHorsZone <- self;
				}
			}	
			
			
		}				
	}
}

species equipementDeRejetCAN parent: equipementDeRejet{	
	string acteurAssocie <- CAN;
	rgb couleurEquipement <- rgb('blue');
	canal canalAssocie <- nil;
	float fractionData <- 0.0;
	float fractionNoData <- 0.0;
	matrix prelevementObs <- nil;
	bool noData <- false;
	map<int,float> restrictionRejet <- map<int,float>([]);	
	
	/*
	 * *****************************************************************************************
	 * @Overwrite  
	 */
	float getVolumeReel{
		float fraction <- fractionNoData; //no data ou hiver
		if  (!noData) and (dateCour.mois >5) and (dateCour.mois < 10){ //1er juin au 31 oct
			list annees <-  ( prelevementObs row_at 0 );
			if (dateCour.annee >= int(annees at 1)) and (dateCour.annee <= int(annees at (length(annees) -1))){
				fraction<- fractionData;
			}
		}
		if(canalAssocie.isEnRestriction()){
			fraction <- fraction * restrictionRejet at canalAssocie.getNiveauRestriction();
		}
		return  canalAssocie.volumeUtileAvantPrelevementEtRejet*fraction;
	}

	/*
	* *****************************************************************************************
	*  @Overwrite
	*/
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
			
		volumeReel <- getVolumeReel();
			 
		ask (ressourceAssociee ) {								
			do setMapVolumeRejetReel acteur:  myself.acteurAssocie valeur: myself.volumeReel;				
		}
		ask (canalAssocie ) {	
			do setMapVolumePreleveReel acteur:  'CAN' valeur: myself.volumeReel;
		}				
	}				
}
	
