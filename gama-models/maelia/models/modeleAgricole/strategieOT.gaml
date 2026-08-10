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
 *  StrategiesSIR
 *  Author: Maroussia Vavasseur
 *  Description: Classe mere des strategies Semi, Irrigation, Recolte
 */

model strategieOT

import "../modeleCommun/typeDeSol.gaml"

species strategieOT {
	int nbSousPeriode <- 0;  // SEMIS   IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	especeCultivee tc <- nil; // SEMIS   IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	float tempsDexecution <- 0.0; // SEMIS   IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	string operateur <- "";   // SEMIS   IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,int> mapFenetresTemporellesDebut <- map<int,int>([]); // [idFenetre::jourJulienDebut]   // SEMIS  IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,int> mapFenetresTemporellesFin <- map<int,int>([]); // SEMIS  IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapNbJoursPluieObsCumulee <- map<int,float>([]);// SEMIS  IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapHauteurPluieObsCumuleeMax <- map<int,float>([]);// SEMIS  IRRIGATION  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapHumiditeSolMax <- map<int,float>([]); // %RU   // SEMIS  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapEffetRUs <- map<int,float>([]); // SEMIS  RECOLTE  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapNbJoursEtpCumule <- map<int,float>([]); //   IRRIGATION  TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapEtpCumuleMax <- map<int,float>([]); //   IRRIGATION   TRAVAILSOL REPRISE_TRAVAILSOL
	map<int,float> mapEchelleVegetationMin <- map<int,float>([]); //    RECOLTE   BINAGE
	materielIrrigation matITK <- nil;
	/*
	 * *****************************************************************************************
	 */
	action initialisationStrategie {}
	
	// Initialisation des maps des stratégies basées sur le nombre de sous-périodes
 	action initialisationMapsStrategies {
 		arg donnees type: string default: "";
 		arg mapEntree type: map<int,float> default: map([]);			
 		
 		list<string> liste <- donnees tokenize SEPARATEUR;
 		if(nbSousPeriode = length(liste)){
	 		int id <- 0;
	 		loop donnee over: liste{
	 			if(!(donnee contains "NA")){
	 				if(donnee contains "W"){
	 					put (MAP_LECTURE_W at donnee) at: id in: mapEntree;	
	 				}else{
	 					put float(donnee) at: id in: mapEntree;	
	 				}			 					 						
	 			}else{
	 				put NA at: id in: mapEntree; // TODO : faire des maps de string et faire les accesseurs pour lid correspondant avec nil ou valeur (si nil a alors on ne prend pas en compte la condition)
	 			}
	 			id <- id+1;		 	
	 		}		 				 			
 		}else{
 			if(!(donnees contains "NA")){
 				// Si il ny a quune valeur alors on met la meme partout
 				if(length(liste) = 1){
 					loop indice from:0 to: (nbSousPeriode-1){
 						put float(donnees) at: indice in: mapEntree;			 
 					}
 				}else{
 					write "[StrategieOT] PB lecture map !! " + tc.idEspeceCultivee+ " - " + self + " - " + donnees + " -> il est attendu " + nbSousPeriode + " valeurs, il ny en a que " + length(liste) + " - liste = " + liste;	 				 				
 				}		 			
 			}else{
 				// Si NA, alors on met NA partout
 				loop indice from:0 to: (nbSousPeriode-1){
 					put NA at: indice in: mapEntree;			 
 				}
 			}
 		}
  	}
  	
	/*
	 * *****************************************************************************************
	 */
 	bool isFenetreTemporelleOk(parcelle parcelleEntree, int deltaTemporel) {
 		if(getIndiceSousPeriode(parcelleEntree, deltaTemporel) >= 0){
 			return true;
 		}else{
 			return false;
 		}
 	}
 	bool fenetreTempOkLocal(int jourC, int jourJulienFenetreMin, int jourJulienFenetreMax){
		if (jourJulienFenetreMax < jourJulienFenetreMin) {
			return jourC >= jourJulienFenetreMin or jourC <= jourJulienFenetreMax;	
 		}else {
			return jourC >= jourJulienFenetreMin and jourC <= jourJulienFenetreMax;
		}
 	}	 		 	
 	int getIndiceSousPeriode(parcelle parcelleEntree, int deltaTemporel){
 		int id <- -1;
 		loop idMap over: mapFenetresTemporellesDebut.keys{
 			if(fenetreTempOkLocal(jourC:(dateCour.nbJoursEcoulesDansAnnee- deltaTemporel), jourJulienFenetreMin:(mapFenetresTemporellesDebut at idMap), jourJulienFenetreMax:(mapFenetresTemporellesFin at idMap))){
 				id <- idMap;
 			}
 		}
 		return id;
 	}
	
	/*
	 * *****************************************************************************************
	 */
	int getJourJulienDebutMin (int deltaTemporel){
		return (mapFenetresTemporellesDebut at 0) + deltaTemporel;
	}		
	int getJourJulienFinMax(int deltaTemporel){
		return (mapFenetresTemporellesFin at (length(mapFenetresTemporellesFin) - 1)) + deltaTemporel;
	}
	int getNbJoursFenetreTemporelle{
		return getJourJulienFinMax(0) - getJourJulienDebutMin(0);
	}
	
	/*
	 * *****************************************************************************************
	 */
	bool isCumuleHauteurPluieOK(parcelle parcelleEntree, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursPluieObsCumulee, parcelleEntree, deltaTemporel) 
			and isDonnee(mapHauteurPluieObsCumuleeMax, parcelleEntree, deltaTemporel)
		){		
			int nbJour <- int(getDonneeCourante(mapNbJoursPluieObsCumulee, parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurPluieObsCumuleeMax, parcelleEntree, deltaTemporel);
			ask parcelleEntree.ilot_app.meteo {
				res <- (cumulePluies(nb_jours:nbJour)*parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
			}				
		}		
		return res;
	}
	bool isHumiditeSolOK(parcelle parcelleEntree, int deltaTemporel){
		bool res <- false;			
		if(isDonnee(mapHumiditeSolMax, parcelleEntree, deltaTemporel)){
			//res <- parcelleEntree.getHumiditeSol()* parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= getDonneeCourante(mapHumiditeSolMax, parcelleEntree, deltaTemporel) * parcelleEntree.ilot_app.sol.getSeuilHumidite();
			res <- parcelleEntree.getHumiditeSol()* parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= getDonneeCourante(mapHumiditeSolMax, parcelleEntree, deltaTemporel); // JV 121220 suppression correction tauxArgile cf Mantis #0002747
			if (getDonneeCourante(mapHumiditeSolMax, parcelleEntree, deltaTemporel) = 1) { // HumiditéOK forcée si la valeur de la sous-période est égale à 1 (puisque la valeur est fixée à 1 dans l'objectif de forcer l'opé)
				res <- true;
			}
		}else{
			res <- true;
		}		
		return res;
	}	
	bool isEchelleVegetationOK(parcelle parcelleEntree, int deltaTemporel){
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true; 
		}else{
			if(isDonnee(mapEchelleVegetationMin, parcelleEntree, deltaTemporel)){
				res <- parcelleEntree.getEchelleVegetation()*parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionVegetation >= getDonneeCourante(mapEchelleVegetationMin, parcelleEntree, deltaTemporel);
			}else{
				res <- true;
			}				
		}						
		return res;
	}
	
	bool isMaturiteAqYieldOK(parcelle parcelleEntree){
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true; 
		}else{
			res <- parcelleEntree.getIsMaturiteOk();			
		}						
		return res;
	}
	
	bool isCumuleHauteurPluieMoinsEtpOK(zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursEtpCumule, parcelleEntree, deltaTemporel) and isDonnee(mapEtpCumuleMax, parcelleEntree, deltaTemporel)){		
			int nbJour <- int(getDonneeCourante(mapNbJoursEtpCumule, parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapEtpCumuleMax,parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getCumulePluiesMoinsETP(nb_jours:nbJour)*parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
			}				
		}		
		return res;
	}
	
	// Pour lapplication de lactivite
	action applicationEffetRUs(parcelle parcelleEntree, int deltaTemporel){
		if(isDonnee(mapEffetRUs, parcelleEntree, deltaTemporel)){				
			float nouvelRUs <- getDonneeCourante(mapEffetRUs,parcelleEntree, deltaTemporel);
			float prof <- mapEffetRUs[deltaTemporel]; // TODO Supprimer  --> Ajout Renaud 30/05/18 : enregistrement de la profondeur de travail pour comparaison AqYield Eau, à supprimer (cf. .gaml)
			// JV 061020 auparavant nouvelRUs ponderee par fonction de pedotransfert cf Mantis #2686
			ask (parcelleEntree){
				do setRUs(nouvelRUs);
				isTravailSolJourCourant <- true;
				if (nomChoixModeleCroissancePlante = 'AqYieldNC') and (prof > 0) {
					parcelleAqYieldNC(self).isTravailSolJourCourant_NC <- true;
					self.prof_w_sol <- prof;
				}
				
				// Update variable ibio
				if (prof > intensite_travailSol) {
					intensite_travailSol <- prof; // on garde que la profondeur la plus grande
				}
			}
		}
	}
		
				
	/*
	 * *****************************************************************************************
	 */		
	bool isDonnee(map<int,float> mapEntree, parcelle parcelleEntree, int deltaTemporel){
		if(mapEntree at getIndiceSousPeriode(parcelleEntree,deltaTemporel) != nil){
			if(mapEntree at getIndiceSousPeriode(parcelleEntree,deltaTemporel) = NA){
				return false;
			}else{
				return true;
			}	
			
//				write "" + self + " - [strategieOT] data = " +  mapEntree at getIndiceSousPeriode();				
		}else{			
//			write "" + self + " - [strategieOT] Pb la map est nulle a cette id = " +  getIndiceSousPeriode(parcelleEntree, deltaTemporel) + 
//					" sur parcelle " + parcelleEntree + " de deltaTemporel " + deltaTemporel+ " a la date de " + dateCour.nbJoursEcoulesDansAnnee;
			return false;
		}		
	}
	float getDonneeCourante(map<int,float> mapEntree, parcelle parcelleEntree, int deltaTemporel){
		return (mapEntree at getIndiceSousPeriode(parcelleEntree, deltaTemporel));
	}
	
	action ecritureDebugActivite(parcelle parcelleEntree){
//			write "" + self + " parc = " + parcelleEntree;
	}
 	
 	/*
	 * *****************************************************************************************
	 */	
  	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){return false;}	
  	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe<-0, float surfaceIrrigueeEntree<-0.0){}
  	
	string toString(parcelle parcelleEntree ,int deltaTemporel){
		return "" + self + " - parcelleEntree = " + parcelleEntree 
									+ 'date = '+ dateCour.nbJoursEcoulesDansAnnee
									+ " - Pluie-ETP = " + isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo,parcelleEntree,deltaTemporel)	
								 	+ " - Pluie = " + isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel)
								 	+ " - Humidite = " + isHumiditeSolOK(parcelleEntree,deltaTemporel)
								 	//+ " - EchV = " + isEchelleVegetationOK(parcelleEntree,deltaTemporel)
								 	+ " - culture = " + parcelleEntree.cultureParcelle;					
  	}
}
