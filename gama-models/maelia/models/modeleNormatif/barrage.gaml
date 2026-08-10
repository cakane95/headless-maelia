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
 *  Barrages
 *  Author: Maroussia Vavasseur ; Romain Lardy
 *  Reprise du code en Février 2017
 *  Description: 
 */

model barrage

import "../modeleHydrographique/noeudHydrographique.gaml"
import "../modeleHydrographique/retenueCollinaire.gaml"
import "gestionnaireDeBarrage.gaml"

global{
	string cheminBarrages <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/barrages/';
 	string nomFichierBarrages <- 'barrages.csv';
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * TODO : est-il possible qu'un barrage soit affecte a plusieurs points DOE ? Pour le moment ce cas nest pas possible
	 */
	action constructionBarrage{		

		if !file_exists(cheminBarrages+nomFichierBarrages)	{do raiseError("fichier inexistant: " + cheminBarrages+nomFichierBarrages);}

		if(file_exists(cheminBarrages+nomFichierBarrages)){
			matrix matriceBarrages <- matrix(csv_file (cheminBarrages+nomFichierBarrages,";", false));
			// matrix matriceBarrages <- matrix(file (cheminBarrages+nomFichierBarrages));		
			 int nbColones <- length(matriceBarrages row_at 0);	
			 	
			 loop i from: 2 to: ( nbColones - 1 ) {
				list<string> coloneI <- (matriceBarrages column_at i) as list<string>;			
				string idBarrageLu <- coloneI at 0;	
				pointDeReference ptRef <- first(pointDeReference where (each.idPointDeReference = (coloneI at 1)));			
				zoneHydrographique zhLu <- mapZH at (coloneI at 4);
				if(zhLu != nil and ptRef != nil){		
					create barrage returns: barrageCourant{
						idBarrage <- idBarrageLu;
						zoneHydrographiqueAssociee <- zhLu;
						priorite <-  int(coloneI at 3);
						premierJourDeLanneeDeLachePossible <- int(coloneI at 5);
						listDesJoursDeLaSemainePourDecisionDeLacher <- ((coloneI at 6) split_with "|") collect(int(each));
						volumeMaxBarrage <- float(coloneI at 7) * 1E6; // m3 
						volumePourEtiageMax <- float(coloneI at 8) * 1E6; // m3  
						volumeCritique <- float(coloneI at 9) * 1E6; // m3
						debitDeReserve <- float(coloneI at 10) * nbSecondesDansUneJournee; // m3/s -> m3/jour
						debitPourEtiageMax <- float(coloneI at 11) * nbSecondesDansUneJournee; // m3/s -> m3/jour
						tauxDebitCritique <- float(coloneI at 12); // % (en fait, fraction) //TODO a renseigner en m3/s
						efficienceEntreeBassin <- float(coloneI at 13);
						efficienceDeGestion <- float(coloneI at 14);
						tempsDeTransfert <- int(coloneI at 15); // ATTENTION : il ne peut pas y avoir de temps de transfert de 0 pour le moment, car le debit des ZH est calcule en amont et les lachers ne peuvent etre pris en compte qua partir du lendemain	
						
						string idRet <- coloneI at 16;
						retenueAssocie <- first (listeRetenuesCollinaires where (each.id = idRet));
						if(retenueAssocie!=nil){
							ask retenueAssocie{
								if(abs((volumeMax -myself.volumeMaxBarrage)/1.0) > 0.05){
									write "Pour conserver la coherence des donnees fournies en entree des barrages, le volume de la retenue " + id
									+ " va etre modifie de " +(volumeMax/1E6 with_precision 2) + " hm3 en " +(myself.volumeMaxBarrage/1E6 with_precision 2) + " hm3";
									volumeMax <- myself.volumeMaxBarrage;
									volumeActuel <- myself.volumeMaxBarrage;
									volumeCulot <- relationVolumeCulot_VolumeMax*volumeMax;
								}
							}
						}						
						location <- zhLu.location;						
						do initialisationBarrage();											
					}
					ask world{
						do constructionGestionnairesBarrages(ptRef, first(barrageCourant));
					}					
				}else{
					if (!executerModeleSurUneZH){ // dans le cas executerModeleSurUneZH l'absence du point DOE ou du BVe pourrait etre normal!
						write "Probleme dans les proprietes du barrage " + idBarrageLu + " :";
						if(zhLu = nil){
							write "le BVe "+ (coloneI at 3) +" alimente par le barrage n'existe pas !" ;
						}
						if(ptRef = nil){
							write "le point DOE "+ (coloneI at 1) +" associe au barrage n'existe pas !" ;
						}
					}
				}
					
			}			
		}
	}
}

species barrage{
	// Constante lues dans fichier
	string idBarrage <- "";
	zoneHydrographique zoneHydrographiqueAssociee <- nil;
	//barrage barrageAssocie <- nil; // Le barrages de moindre priorite (peut etre nul)
	int priorite <- 0; // 0 est la plus forte priorite
	int premierJourDeLanneeDeLachePossible <- 0;
	float efficienceEntreeBassin <- 0.0; // [%] =	efficience d'un transfert en entrée du terrain/ Ex je lache 10M3/s j'en trouve 7 à l'entrée du terrain
	float efficienceDeGestion <- 0.0; // [%] =	efficience considere dans la gestion : je lache 10M3 pour en avoir 7 au point DOE
	int tempsDeTransfert <- 1; // [jours] = temps pour retrouver un laché en entree du terrain
	float volumeMaxBarrage <- 0.0; // [m3]
	float volumePourEtiageMax <- 0.0; // [m3] = reserve max pour la partie consacree a l'etiage	
	float volumeCritique <- 0.0; // [m3] = V qui dit qu'il faut commencer a regarder dans d'autre reserve moins prioritaire avant d'augmenter le lacher 
	float debitPourEtiageMax <- 0.0;	 // [m3/jour] =	debit maximum mobilisable pour le SE/Agri	
	float tauxDebitCritique <- 0.0;	 // [%] =	Q qui dit qu'il faut commencer à regarder dans d'autre reserve moins prioritaire avant d'augmenter le lache
	// Variables
	int indiceJourDebutLacher <- -1;	
	float debitDeReserve <- 0.0;	 // [m3/jour] = debit minimum qui sort du barrage tout les jours. Pas activé en Aveyron car deja inclus dans les debit force. A conserver pour Garonne Amont	
	float debitDeReserveCourant <- 0.0; // JV 190822 test pour sortie, normalement = debitDeReserve chaque jour sauf si volumeBarrage insuffisant
	map<int,float> debitsDeLacher <- map<int,float>([]);	 // [m3/jour] - indiceJour::debitLacher		
	float volumeCourant <- 0.0; // [m3] = volume reservee pour letiage
	float quotaAnnuelRestant <- 0.0;
	list<int> listDesJoursDeLaSemainePourDecisionDeLacher <- [];
	float volumeTransfereZHCeJour <- 0.0; // [m3] JV 060922 pour sortie, peut être supérieur au débit du jour en cas de forçage
	
	retenueCollinaire retenueAssocie <- nil;

	action initialisationBarrage{
		do setVolumeBarrage(volumeMaxBarrage, true);
		quotaAnnuelRestant <- volumePourEtiageMax;
	}
	
	/*
	 * *****************************************************************************************
	 * Les laches de barrages pour l'etiage ne peuvent pas se faire avant le 15 aout
	 */	
	 bool isLacherPossible{		
	 	bool res <- false; 	 
		 if(dateCour.nbJoursEcoulesDansAnnee >= premierJourDeLanneeDeLachePossible){
		 	// Il faut qu'il y ai du stock et qu'aucun lache n'ai ete effectue depuis les 3 derniers jours
		 	if(getVolumeBarrage() > 0.0) and (quotaAnnuelRestant > 0.0){
		 		res <- true;		 		
		 	}
		 }			 
	 	//write "\t" + idBarrage + "\tnbJoursEcoulesDansAnnee=" + dateCour.nbJoursEcoulesDansAnnee + " premierJourDeLanneeDeLachePossible= " + premierJourDeLanneeDeLachePossible + " getVolumeBarrage()=" + getVolumeBarrage() + " quotaAnnuelRestant=" + quotaAnnuelRestant + " res=" + res; // JV debug 
		//if verboseMode {write "BARRAGES lacher possible " + name + " " + idBarrage + " premierJourDeLanneeDeLachePossible=" + premierJourDeLanneeDeLachePossible + " getVolumeBarrage=" + getVolumeBarrage() + " m3 quotaAnnuelRestant=" + quotaAnnuelRestant + " m3 -> " + res;}
		return res;		
	 }		
	 /*
	 bool isLacherPossible_old{		 	 
	 	//write "\t" + idBarrage + "\tnbJoursEcoulesDansAnnee=" + dateCour.nbJoursEcoulesDansAnnee + " premierJourDeLanneeDeLachePossible= " + premierJourDeLanneeDeLachePossible + " getVolumeBarrage()=" + getVolumeBarrage() + " quotaAnnuelRestant=" + quotaAnnuelRestant; // JV debug 
		 if(dateCour.nbJoursEcoulesDansAnnee >= premierJourDeLanneeDeLachePossible){
		 	// Il faut qu'il y ai du stock et qu'aucun lache n'ai ete effectue depuis les 3 derniers jours
		 	if(getVolumeBarrage() > 0.0) and (quotaAnnuelRestant > 0.0){
		 		return true;			 		
		 	}
		 }			 
		 return false;		
	 }		 * 
	 */	
	 bool isLacherEnCours{
	 	bool res <- false;		
		 if(getDebitCourant() > 0.0){
		 	res <- true;
		 }
	 	return res;		 
	 }
	/*
	 bool isLacherEnCours{		
		 if(getDebitCourant() > 0.0){
		 	return true;
		 }else{
		 	return false;
		 }
	 }
	 * *
	 */
	 
	 bool isVolumeCritiqueAtteint(bool isForce){
	 	bool res <- false;		
		 if(min([getVolumeBarrage(),quotaAnnuelRestant])  <= getVolumeCritique(isForce)) {
		 	res <- true;
		 }
		 return res;		 
	 }
	 
	 /*
	 bool isVolumeCritiqueAtteint(bool isForce){		
		 if(min([getVolumeBarrage(),quotaAnnuelRestant])  <= getVolumeCritique(isForce)) {
		 	return true;
		 }else{
		 	return false;
		 }
	 }
	*/

	 float getVolumeCritique(bool isForce){
	 	float res <- 0.0;
	 	if(!isForce){
	 		res <- volumeCritique;
	 	}
 		return res;	 			 	
	 }

	/*
	 float getVolumeCritique(bool isForce){
	 	if(!isForce){
	 		return volumeCritique;
	 	}else{
	 		return 0.0;
	 	}		 	
	 }
	*/
	
	 bool isDebitCritiqueAtteint(bool isForce){
	 	bool res <- false;		
		 if(getDebitCourant() >= getDebitCritique(isForce)){
		 	res <- true;
		 }
	 	return res;		 
	 }

	/*
	 bool isDebitCritiqueAtteint(bool isForce){		
		 if(getDebitCourant() >= getDebitCritique(isForce)){
		 	return true;
		 }else{
		 	return false;
		 }
	 }
	*/

	 float getDebitCritique(bool isForce){
	 	float res <- debitPourEtiageMax * tauxDebitCritique;
	 	if(!isForce){
	 		res <- debitPourEtiageMax ;
	 	}
 		return res;
	 }		 

	/*
	 float getDebitCritique(bool isForce){
	 	if(!isForce){
	 		return debitPourEtiageMax ;
	 	}else{
	 		return debitPourEtiageMax * tauxDebitCritique;
	 	}		 	
	 }		 
	 */
	 	 
	 action setDebitCourant(float debitEntree, bool isAjout){
//			write "" + self + "setDebitCourant" + debitEntree + "  - " + isAjout;
	 	
	 	float debitExistant <- 0.0;
	 	if(isAjout){
	 		debitExistant <- getDebit(dateCour.indiceDate);
	 	}
	 	put (debitEntree+debitExistant) at: dateCour.indiceDate in: debitsDeLacher;
	 }	
	 
	 float getDebitCourant{
	 	return getDebit(dateCour.indiceDate);
	 }
	 		 
	 float getDebit(int dateEntree){
	 	float res <- 0.0;
	 	if((debitsDeLacher at dateEntree) != nil){
	 		res <- debitsDeLacher at dateEntree;
	 	}
	 	return res;	 			 	
	 }
	 
	 float getDebitJourTransfert{
	 	return getDebit(dateCour.indiceDate-tempsDeTransfert);	 	
	 }
	 
	 float getDebitCourantEntreeBasin{
	 	return getDebitJourTransfert() * efficienceEntreeBassin;	 	
	 }
	 
	 float getDebitJourPrecedent{
	 	return getDebit(dateCour.indiceDate-1);	 	
	 }
	 		
	 int getNbJoursDebutLacher{
	 	int res <- indiceJourDebutLacher;
	 	if(indiceJourDebutLacher >= 0){
	 		int id <- indiceJourDebutLacher;
	 		res <- dateCour.calculNbJour(id);	 		
 		}
 		return res;
	 }

	/*
	 int getNbJoursDebutLacher{
	 	if(indiceJourDebutLacher >= 0){
	 		int id <- indiceJourDebutLacher;
	 		return dateCour.calculNbJour(id);
	 	}else{
	 		return indiceJourDebutLacher;
	 	}		 	
	 }
	 */	
	 	
	 	
	/*
	 * *****************************************************************************************
	 * Renvoie false si le nouveau debit atteint le critique
	 * isForce va etre a true si tous les barrages ont atteint le debit critiques
	 */	
	float majDebitCourant(float debitARajouter, bool isForce){
		float debitRestant <- 0.0;
//			write "" + self + " - 1b - " + debitARajouter + " -isforce = "+ isForce;

		//if verboseMode {write "BARRAGES\tgetDebitCourant=" + getDebitCourant() + " getDebitCritique(isForce)=" + getDebitCritique(isForce) + " isDebitCritiqueAtteint(isForce)=" + isDebitCritiqueAtteint(isForce);}
		//if verboseMode {write "BARRAGES\tgetVolumeBarrage=" + getVolumeBarrage() + " quotaAnnuelRestant=" + quotaAnnuelRestant + " getVolumeCritique(isForce)=" + getVolumeCritique(isForce) + " isVolumeCritiqueAtteint(isForce)=" + isVolumeCritiqueAtteint(isForce);}
		
		if(!isDebitCritiqueAtteint(isForce) and !isVolumeCritiqueAtteint(isForce)){
			//si on peut encore ajouter du debit et si il reste de l'eau

			if verboseMode {write "BARRAGES majDebitCourant " + idBarrage + " - 2b - debitCourant=" + getDebitCourant();}

			//debit souhaité en tenant compte de l'efficience de gestion
			do setDebitCourant(debitARajouter / efficienceDeGestion, true);					

//				write "" + self + " - 3b - " + getDebitCourant();
			if verboseMode {write "BARRAGES majDebitCourant " + idBarrage + " - 3b - debitCourant=" + getDebitCourant();}


			if(isDebitCritiqueAtteint(isForce)){
				debitRestant <- (getDebitCourant() - getDebitCritique(isForce)) * efficienceDeGestion;
				do setDebitCourant(getDebitCritique(isForce), false);
				
//					write "" + self + " - 4b - " + getDebitCourant();
				if verboseMode {write "BARRAGES majDebitCourant " + idBarrage + " - 4b - debitCourant=" + getDebitCourant();}
			}else{
				
//					write "" + self + " - 5b - " + getDebitCourant();
				if verboseMode {write "BARRAGES majDebitCourant " + idBarrage + "- 5b - debitCourant=" + getDebitCourant();}
				
				debitRestant <- 0.0;				
			}				
		}else{
			
//				write "" + self + " - 6b - " + getDebitCourant();
			if verboseMode {write "BARRAGES majDebitCourant " + idBarrage + "- 6b - debitCourant=" + getDebitCourant();}
			
			debitRestant <- debitARajouter;			
		}
//			write " - 7b - " + debitRestant;	
		if verboseMode {write "BARRAGES fin majDebitCourant debitCourant=" + getDebitCourant() + " debitRestant à affecter=" + debitRestant;}
		return debitRestant;
	}

	/*
	 * *****************************************************************************************
	 * 	Renvoie le volume restant par rapport au critique atteint le critique
	 *  ATTENTION : ici je soustrait des debits (m3/j) avec des volume (m3). Tant que le pas de temps est la journee c'est bon.
	 *  RL 07/02/2017 : Renvoie le volume restant a lacher 
	 */
	float lacher(float volumeAlacherJourCourant, bool isForce){	
		float res<- 0.0;
		float volumeRestant <- 0.0;
		
			if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 1 - debitCourant=" + getDebitCourant() + " - volumeAlacherJourCourant = " + volumeAlacherJourCourant + " - volumeCourant = " + getVolumeBarrage();}
				
		if(!isVolumeCritiqueAtteint(isForce)){				
			float volumePrecedent <- getVolumeBarrage();
			float quotaPrecedent <- quotaAnnuelRestant;
			
			//if(verboseMode){write "" + self + " - 2 - " + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage() + " - quotaAnnuelRestant = " + quotaAnnuelRestant;} 
			if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 2 - debitCourant=" + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage() + " - quotaAnnuelRestant = " + quotaAnnuelRestant;} 
			
			if(verboseMode){write "" + idBarrage + " appel setVolumeBarrage("+volumePrecedent+"-"+volumeAlacherJourCourant+")";}
			do setVolumeBarrage(volumePrecedent - volumeAlacherJourCourant, false) ; // m3 - m3/j (et cette methode est appelee une fois par jour)
			if(verboseMode){write "" + idBarrage + " getVolumeBarrage()=" + getVolumeBarrage();}
			if verboseMode and retenueAssocie!=nil {write "" + idBarrage + " retenue associee volumeActuel=" + retenueAssocie.volumeActuel;}
							
			quotaAnnuelRestant <- quotaAnnuelRestant - volumeAlacherJourCourant;
			
			if(isVolumeCritiqueAtteint(isForce)){ //le lacher du jour fait passer en dessous du seuil critique
				float volumeLachableAvantVolCrit <- min([volumePrecedent, quotaPrecedent ]) - getVolumeCritique(isForce);
				volumeRestant <- volumeAlacherJourCourant - volumeLachableAvantVolCrit; //volume restant a fournir
				if(verboseMode){write "" + idBarrage + " appel setVolumeBarrage("+volumePrecedent+"-"+volumeLachableAvantVolCrit+")";}
				do setVolumeBarrage(volumePrecedent - volumeLachableAvantVolCrit, false);
				if(verboseMode){write "" + idBarrage + " getVolumeBarrage()=" + getVolumeBarrage();}
				if verboseMode and retenueAssocie!=nil {write "" + idBarrage + " retenue associee volumeActuel=" + retenueAssocie.volumeActuel;}
			    quotaAnnuelRestant <- quotaPrecedent - volumeLachableAvantVolCrit;
				do setDebitCourant(volumeLachableAvantVolCrit, false); // On reduit le lacher
				//if(verboseMode){write "" + self + " - 3 - " + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}
				if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 3 - debitCourant=" + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}
										
			}else{
				volumeRestant <- 0.0;
				//if(verboseMode){write "" + self + " - 4 - " + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}		
				if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 4 - debitCourant=" + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}		
			}
			// Lacher dans ZH				
			do alimentationZH(volumePrecedent - getVolumeBarrage());
			volumeTransfereZHCeJour <- volumeTransfereZHCeJour + volumePrecedent - getVolumeBarrage();
			
			//if(verboseMode){write "" + self + " - 5 - " + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}
			if(verboseMode){write "BARRAGES lâcher" + idBarrage + " - 5 - debitCourant=" + getDebitCourant() + " - volumeCourant = " + getVolumeBarrage();}
			
			res <- volumeRestant;
		}else{
			
			//if(verboseMode){write "" + self + " - 6 - " + getDebitCourant() + " - volumeCourant = " + volumeCourant;}
			if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 6 - debitCourant=" + getDebitCourant() + " - volumeCourant = " + volumeCourant;}
			
			do setDebitCourant(0.0, false); // On arrete le lacher
			
			res <- volumeAlacherJourCourant;
		}
		
		//if(verboseMode){write "" + self + " - 7 - volumeRestant = " + volumeRestant + " - res = " + res;}
		if(verboseMode){write "BARRAGES lâcher " + idBarrage + " - 7 - volumeRestant = " + volumeRestant + " - res = " + res;}
		
		
		return res;							
	}


	action alimentationZH(float volumePourZH){
		ask(zoneHydrographiqueAssociee){
			int indiceDateFuture <- dateCour.indiceDate + myself.tempsDeTransfert; 
			do stockageLacherBarrage(volumePourZH*myself.efficienceEntreeBassin, indiceDateFuture);
		}
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action remplissageBarrage{
		if(retenueAssocie = nil){
			do setVolumeBarrage(volumeMaxBarrage, true);
		}//pour les barrages relies a une retenues on a pas besoin de les recharger ici
		quotaAnnuelRestant <- volumePourEtiageMax;
	}		

	// JV 060922 ajout d'un booléen car quand il y a une retenue associée il faut mettre à jour son volume (ce qui n'était pas fait) sauf en cas de recharge hivernale (remplissage du barrage au 1er janvier), cf. Mantis #0002939 
	action setVolumeBarrage(float newVolume, bool isRechargeHivernale){
		if(retenueAssocie = nil){
			volumeCourant <- newVolume;
		}else{
			if !isRechargeHivernale {
				retenueAssocie.volumeActuel <- newVolume; 
			}
			//TODO recharge hivernale par pompage ?
		}
	}
	
	float getVolumeBarrage{
		if(retenueAssocie = nil){
			return volumeCourant;
		}else{
			ask retenueAssocie{
				return volumeActuel;
			}
		}
	}

	/*
	 * *****************************************************************************************
	 */	
	
	/*
	 * Appelle apres chaque lacher (car la valeur du debit courant peut etre modifiee a chauqe lacher, si il ny a plus de volume par ex)
	 */
	action majDateLacher{
		// On verifie si il y a eu une augmentation de lacher aujourdhui
		if(getDebitCourant() != getDebitJourPrecedent()){
			indiceJourDebutLacher <- dateCour.indiceDate;	// A chaque changement de valeur de lache, on remet a zero la date	
		}			
//			write "CHANGEMENT DATE !!!! = " + getNbJoursDebutLacher() + " indiceJourDebutLacher = " + indiceJourDebutLacher;
	}

	action miseAjourMemeDebit{			
		// On met chaque debut de jour le meme debit que la veille car pendant 7 jours le debit ne pourra etre inferieur (sauf si mis a 0)
		do setDebitCourant(max([getDebitCourant(), getDebitJourPrecedent()]), false);
	}

	/*
	 * *****************************************************************************************
	 */	
	rgb getCouleurBarrage{
		if(isLacherEnCours()){
			if(getDebitCourant() < 0.0){
				return rgb('red');
			}else if(getDebitCourant() < 1.0){
				return rgb('blue');
			}else if(getDebitCourant() > 1.0){
				return rgb('lightGray');					
			}
		}else{
			return rgb('white');
		}
	}
	int getTailleAffichage{
		if(isLacherEnCours()){
			return taillePointsMax;
		}else{
			return taillePointsMin;
		}
	}
	string getTexteAffichage{
		if(isLacherEnCours()){
			return "" + int(getDebitCourant() / nbSecondesDansUneJournee);
		}else{
			return "";
		}
	}
	
	/*
	 * *****************************************************************************************
	 */	
	aspect evolutionDebitLache{
		draw circle(getTailleAffichage()) color: getCouleurBarrage();
		draw getTexteAffichage() at: location color: rgb('black') size: getTailleAffichage();
	}	
				
	/*
	 * *****************************************************************************************
	 */
	string toString{			
		return 		idBarrage
					+ ' \t/ zh = ' + zoneHydrographiqueAssociee.idZoneHydrographique		
					+ ' \t/ volumeCourant = ' + getVolumeBarrage()	 
					+ ' \t/ volumeCritique = ' + volumeCritique	 
					+ ' \t/ volumePourEtiageMax = ' + volumePourEtiageMax
					+ ' \t/ debitCourant = ' + getDebitCourant()	
					+ ' \t/ debitCritique = ' + getDebitCritique(true)	
					+ ' \t/ debitPourEtiageMax = ' + debitPourEtiageMax
					+ ' \t/ isPossible = ' + isLacherPossible()	
					+ ' \t/ isEnCours = ' + isLacherEnCours()
					+ ' \t/ indJour = ' + indiceJourDebutLacher
					+ ' \t/ NbJr = ' + getNbJoursDebutLacher()
					+ ' \t/ prio = ' + priorite;				
	}			
}
