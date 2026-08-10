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
 *  gestionaireDeBarrage
 *  Author: Maroussia Vavasseur
 *  Description: Le gestionnaire de barrage decide quand faire des laches pour l'hydroelectricite (les laches pour palier aux periodes d'etiages etant decides par le prefet).
 * 					Il y a un gestionnaire de barrage par point DOE
 */

model gestionnaireDeBarrage

import "../modeleAgricole/Ilots/ilot.gaml"

global{	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Creation de 1 gestionnaire par point DOE
	 */
	action constructionGestionnairesBarrages(pointDeReference ptEntree, barrage barrageEntree){		
		gestionnaireDeBarrage gest <- first((gestionnaireDeBarrage as list) where (each.pointNodalAssocie = ptEntree));
		if(gest = nil){
			create gestionnaireDeBarrage number: 1{
				barragesAssocies << barrageEntree;
				pointNodalAssocie <- ptEntree;
				listDesJoursDeLaSemainePourDecisionDeLacher <- barrageEntree.listDesJoursDeLaSemainePourDecisionDeLacher;
			}
		}else{
			gest.barragesAssocies << barrageEntree;
		}
	}
}

	
species gestionnaireDeBarrage{
	pointDeReference pointNodalAssocie <- nil;
	zoneAdministrative zaAssociee <- nil;
	list<barrage> barragesAssocies <- [];
	float prelevementsActivitesHumainesEstimes <- 0.0; // [m3]
	bool lacherDemande <- false;
	bool isIrrigationStarted <- false;
	list<int> listDesJoursDeLaSemainePourDecisionDeLacher <- [];
	/*
	 * *****************************************************************************************
	 */	
	action comportementHebdomadaire{	
		// On modifie les lachers tous les vendredi
		bool estUnJourDeDecision <- false;
		loop j over: listDesJoursDeLaSemainePourDecisionDeLacher{
			if(int (j) = int(dateCour.indiceJourDeLaSemaine)){
				estUnJourDeDecision <- true;
			}
		}
		if(estUnJourDeDecision){
			// LACHERS
			float debitALacher <- 0.0; // m3/j  
			if verboseMode {write "BARRAGES jour decision gestionnaire " + self + " pointNodalAssocie " + pointNodalAssocie + " " + pointNodalAssocie.idPointDeReference + " ZA associee=" + zaAssociee;}
			if(pointNodalAssocie.surveillancePointDeReference()){
				if verboseMode {write "BARRAGE ptRef " + pointNodalAssocie.idPointDeReference + " SOUS LE DOE: " + "QMJ3=" + pointNodalAssocie.qmj3 + " DOE=" + pointNodalAssocie.doe;}				
				debitALacher <- max([0.0, (pointNodalAssocie.seuilDeGestion - pointNodalAssocie.qmj3 )* nbSecondesDansUneJournee//debit manquant pour soutenir le DOE //m3/s -> m3/j
					//+ getDebitLachersPrecedents()  // On rajoute les volumes de lacher de barrages pour avoir un debit obs sans soutien d'étiage
					+ getPrelevementsActivitesHumainesEstimes()
				]);
				if verboseMode {write "BARRAGES\tprelevementsHumainsEstimes=" + getPrelevementsActivitesHumainesEstimes() + "m3/j, débitALacher=" + debitALacher + "m3/j";} 			
			}else{ // On veut diminuer les lachers de la valeurs en trop du doe
				float debitSansLacher <- pointNodalAssocie.debitJournalier*nbSecondesDansUneJournee - getDebitLachersPrecedents(); // m3/j
				
//					write "QMJ = " + pointNodalAssocie.debitJournalier*nbSecondesDansUneJournee + " - getDebitLachersPrecedents() = " + getDebitLachersPrecedents() + " - debitSansLacher = " + debitSansLacher;
				
				if(debitSansLacher < pointNodalAssocie.seuilDeGestion*nbSecondesDansUneJournee){ //on a quand même besoin du soutien d'etiage
					debitALacher <- max([0.0, (pointNodalAssocie.seuilDeGestion - pointNodalAssocie.debitJournalier)* nbSecondesDansUneJournee
												+ getDebitLachersPrecedents() 
											 // + getPrelevementsActivitesHumainesEstimes()
					]);
					if verboseMode {write "BARRAGES\tgetDebitLachersPrecedents=" + getDebitLachersPrecedents() + "m3/j, débitALacher=" + debitALacher + "m3/j";} 			
				}
			}				
			if(isLacherPossible() and debitALacher > 0.0){
//				write "QMJ3 = " + pointNodalAssocie.qmj3 + " debitJournalier "+ pointNodalAssocie.debitJournalier + " seuilDeGestion = " + pointNodalAssocie.seuilDeGestion + " getPrelevementsActivitesHumainesEstimes = " +getPrelevementsActivitesHumainesEstimes() + " lacherPrec = " + getDebitLachersPrecedents();
				do majDebitBarrages(debitALacher); // qmj3
			}else{
				ask barragesAssocies{
					do setDebitCourant(0.0, false);
				}
			}				
		}else{
			do miseAjourMemeDebit();				
		}				
	}			
	action comportementJournalier{
		ask barragesAssocies{ volumeTransfereZHCeJour <- 0.0;} // MAJ pour sortiie
		do regardeSiIrrigationACommence();	
		do lacherDebitReserve();
		do lacherPourSoutienEtiage();
		do majDatesLachers();
	}
	action comportementAnnuel{	
		do remplissageBarrages();
		isIrrigationStarted <- false;
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action estimationPrelevementsJournalier{
		float surfaceIrrigueeAnneeEnCoursPourlaZA <- 0.0;
		ask zaAssociee{	
			ask listIlotsIrrigablesAssocies{
				surfaceIrrigueeAnneeEnCoursPourlaZA <- surfaceIrrigueeAnneeEnCoursPourlaZA + surfaceIlotAvecCultureIrriguee ;
			}
		}
		prelevementsActivitesHumainesEstimes <- surfaceIrrigueeAnneeEnCoursPourlaZA * (4 / nombreMillimetreDansUnMetre); // 4 mm / jour soit un TD de 28 mm
	}
	
	action regardeSiIrrigationACommence{
		if (dateCour.mois = 9 and dateCour.jour = 15){ // au dela du 15 septembre on ne tient plus compte de l'irrigation
			isIrrigationStarted <- false;
		}else{ 
			if(!isIrrigationStarted){ // si l'irrigation n'a pas encore commence
				if(lePrefet.isPeriodeEtiageCommencee()){// entre le 15 mai et le 30 juin
					if((dateCour.mois = 6 and dateCour.jour = 30)){ //au plus tard au 30 juin on commence l'irrigation
						isIrrigationStarted <- true;
					}else{
						float volumePreleveSemaineDerniere <- zaAssociee.getPrelevementAgricoleMoyenSemaineDerniere(); //volume moyen/jour
						if(volumePreleveSemaineDerniere > prelevementsActivitesHumainesEstimes/4.0 ){
							//Seuil approximatif permettant de savoir que l'irrigation a commencé
							isIrrigationStarted <- true;
						}
					}
				}
			}
		}
	}
	
	float getPrelevementsActivitesHumainesEstimes{
		if(isIrrigationStarted){
			return prelevementsActivitesHumainesEstimes ;
		}else{
			return 0.0;
		}
	}
	action remplissageBarrages{
		ask barragesAssocies{
			do remplissageBarrage();
		}
	}
	
	/*
	 * *****************************************************************************************
	 */	
	bool isLacherEnCours{
		ask barragesAssocies{
			if(isLacherEnCours()){
				return true;
			}				
		}
		return false;
	}		
	bool isLacherPossible{
		bool res <- false;
		ask barragesAssocies{
			if(isLacherPossible()){
				res <- true;
			}				
		}
		return res;
	}
	bool isLacherPossible_old{
		ask barragesAssocies{
			if(isLacherPossible()){
				return true;
			}				
		}
		return false;
	}
	bool isDebitsCritiquesDepassesPourTousLesBarrages{
		bool res <- true;
		ask barragesAssocies{
			if(!isDebitCritiqueAtteint(false)){
				res <- false;
			}				
		}
		return res;
	}	
	bool isVolumesCritiquesDepassesPourTousLesBarrages{
		bool res <- true;
		ask barragesAssocies{
			if(!isVolumeCritiqueAtteint(false)){
				res <- false;
			}				
		}
		return res;
	}	
	list<barrage> getBarragesActifs{
		list<barrage> liste <- [];
		ask barragesAssocies{
			if(isLacherEnCours()){
				liste << self;
			}				
		}
		return liste;
	}
	list<barrage> getBarragesParPriorite(list<barrage> listeBarragesEntree, int prioriteEntree){
		return  listeBarragesEntree where (each.priorite = prioriteEntree);
	}
	float getDebitLachersPrecedents{
		float res <- 0.0;
		ask barragesAssocies{
			res <- res + getDebitCourantEntreeBasin();			
		}
		return res;
	}		
	int getNbPriorites{
		int res <- 0;
		ask barragesAssocies{
			if(res = 0 or res < priorite){
				res <- priorite;
			}
		}
		return res;
	}
	action majDatesLachers{
		ask barragesAssocies{
			do majDateLacher();
		}
	}		
	action miseAjourMemeDebit{
		ask barragesAssocies{
			do miseAjourMemeDebit();
		}
	}		
				
	/*
	 * *****************************************************************************************
	 * TODO : REVOIR LA MANIERE DE CALCULER LE DEBIT DE LACHER DES BARRAGES
	 */			
	action majDebitBarrages(float debitAFournirEntree){
		if verboseMode {write "" + self + " -------------------------- LACHER DEMANDE !!!!!!! debitAFournirEntree = " + debitAFournirEntree + " - barragesAssocies = " + barragesAssocies;}
		if verboseMode {write "BARRAGES lâcher envisagé (majDebitBarrages) debitAFournirEntree=" + debitAFournirEntree + " m3/j parmi barragesAssocies=" + barragesAssocies collect (each.idBarrage);}
		
		float debitRestant <- majDebitPourEtiageLocal(barragesAssocies, debitAFournirEntree);
		// Si il reste encore du debit a injecte, alors ca signifie que le barrages ne seront pas suffisants pour couvrir les besoins (ils sont au maximum de leut activite journaliere)
		if(debitRestant > 0.0){
			if verboseMode {write "" + self + " - [GEST_BARRAGE] !!!!!!! ATTENTION !!!!!!! Sur une demande de soutien detiage de = " + debitAFournirEntree + " m3/j, il reste " + debitRestant + " m3/j non couvert par les barrages, car ils ont atteints leur debitMAX.";}
		}	
	}
	
	float majDebitPourEtiageLocal(list<barrage> listeBarragesEntree, float debitAFournirEntree){
		float debitRestant <- debitAFournirEntree;	//debit en m3/jour		
		if(!empty(listeBarragesEntree) and debitRestant > 0.0){
			// Si le debit critique nest pas encore depasse pour tous les barrages, cela veut dire quau moins un peut etre encore lacher sans faire depasser les autres barrages plus prioritaires
			if(!isDebitsCritiquesDepassesPourTousLesBarrages()){
				if verboseMode {write "BARRAGES il reste au moins un barrage dont le débit critique n'est pas atteint";}
				debitRestant <- majDebitUnitaire(listeBarragesEntree, debitRestant, false);
			}			
			// Si il reste du debit a injecte, alors le debit critique va pouvoir etre depasse car tous les barrages sont maintenant actifs au niveau critique
			if(debitRestant > 0.0){
				if verboseMode {write "BARRAGES il reste " + debitRestant + " m3/j à affecter -> isForce=true";}
				debitRestant <- majDebitUnitaire(listeBarragesEntree, debitRestant, true);
			}			
		}
		return debitRestant;
	}		
	
	float majDebitUnitaire(list<barrage> listeBarragesEntree, float debitAFournirEntree, bool isForce){
		float debitRestant <- debitAFournirEntree;
		
		if verboseMode {write "" + self + " - listeBarragesEntree - " + listeBarragesEntree + " - debitRestant = " + debitRestant + " - getNbPriorites = " + getNbPriorites() + " - isForce = " + isForce;}
		// gere la priorite des barrages, et si un barrage prioritaire a atteint son seuil alors on active ceux de priorite inferieur (un ou plusieurs) et ainsi de suite
		loop prio from: 1 to: getNbPriorites(){
			list<barrage> barragesPrio <- getBarragesParPriorite(listeBarragesEntree, prio);	
			
				if verboseMode {write "" + self + " - barragesPrio - " + barragesPrio;}
			
			if verboseMode {write "BARRAGES priorité " + prio + ": " + barragesPrio collect (each.idBarrage) + " isForce=" + isForce;}		
			if(debitRestant > 0.0 and !empty(barragesPrio)){
				float debitPourBarragesMemePrioRestant <- debitRestant / length(barragesPrio);
				debitRestant <- 0.0;			
				ask barragesPrio{
					if verboseMode {write "BARRAGES avant tentative affectation debitPourBarragesMemePrioRestant=" + debitPourBarragesMemePrioRestant + " m3/j sur " + toString();}		
					debitRestant <- majDebitCourant((debitPourBarragesMemePrioRestant + debitRestant), isForce);
					if verboseMode {write "BARRAGES apres tentative affectation debitPourBarragesMemePrioRestant=" + debitPourBarragesMemePrioRestant + " m3/j sur " + toString();}		
				}					
			}					
		}
		return debitRestant;
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action lacherDebitReserve{
		ask barragesAssocies{
			if(debitDeReserve > 0.0){
				if(getVolumeBarrage() > debitDeReserve){
					do alimentationZH(self.debitDeReserve);
					volumeTransfereZHCeJour <- volumeTransfereZHCeJour + self.debitDeReserve;
					self.debitDeReserveCourant <- self.debitDeReserve;
					do setVolumeBarrage(getVolumeBarrage() - debitDeReserve, false); 
				}else{
					do alimentationZH(self.getVolumeBarrage());
					volumeTransfereZHCeJour <- volumeTransfereZHCeJour + self.getVolumeBarrage();
					self.debitDeReserveCourant <- self.getVolumeBarrage();
					do setVolumeBarrage(0.0, false); 
				}
				
			}	
		}
	}
	
	action lacherPourSoutienEtiage{
		float volumeAReafecter <- 0.0;			
		if(!isVolumesCritiquesDepassesPourTousLesBarrages()){
			volumeAReafecter <- lacherPourSoutienEtiageLocal(volumeAReafecter, false);
		}
		if(isVolumesCritiquesDepassesPourTousLesBarrages() or volumeAReafecter > 0.0){
			volumeAReafecter <- lacherPourSoutienEtiageLocal(volumeAReafecter, true);
		}
		// Si il reste encore du debit a injecte, alors ca signifie que le barrages ne seront pas suffisants pour couvrir les besoins (ils sont au maximum de leut activite journaliere)
		if(volumeAReafecter > 0.0 ){
			if verboseMode {write "" + self + " - [GEST_BARRAGE] !!!!!!! ATTENTION !!!!!!! Tous les barrages sont vides, et les " + volumeAReafecter + " m3 ne pourront pas etre lachers.";}
		}
	}	
	// Si renvoie un truc ca veut dire quon a depasse le critique et quon veut plus lacher jusqua ce que tous les autres barrages ai 
	// atteint le critique, mais il faut donc compenser le debit du barrage nouvellement inactif avec les autres barrages
	float lacherPourSoutienEtiageLocal(float volumeEtDebitEntree, bool isForce){
			if verboseMode {write "" + self + " - volumeEtDebitEntree 1 = " + volumeEtDebitEntree + " - isForce = " + isForce;}
		
		float volumeRestant <- volumeEtDebitEntree ;
		
		lacherDemande <- false;
		ask barragesAssocies{
			if (getDebitCourant() > 0.0){
				myself.lacherDemande <- true;
			}
		}

		// gere la priorite des barrages, et si un barrage prioritaire a atteint son seuil alors on active ceux de priorite inferieur (un ou plusieurs) et ainsi de suite
		loop prio from: 1 to: getNbPriorites(){
			list<barrage> barragesPrio <- getBarragesParPriorite(barragesAssocies, prio);	
			ask barragesPrio{
				
				if verboseMode {write "[GEST/lacherPourSoutienEtiageLocal]" + self + " - self.getDebitCourant() = " + self.getDebitCourant() + " - volumeRestant = " + volumeRestant;}
				
				if verboseMode {write "" + idBarrage + " appel lacher";}
				volumeRestant <- lacher(self.getDebitCourant() + volumeRestant, isForce) + volumeRestant;
				
				// Si il reste du volume, cad quil ny a plus de debit lache par le barrage courant, et quil faut donner ce debit aux autres barrages de moindre priorite
				if(volumeRestant > 0.0){
					//debitRestant <- debitRestant + (temp at 1); // ?? temp at 1 contient le debit que l'on a pu couvrir avec le barrage
					list<barrage> listeBarragesMoinsSelf <- myself.barragesAssocies where (each != self);
					
						if verboseMode {write "" + idBarrage + " - listeBarragesMoinsSelf = " + listeBarragesMoinsSelf + " - " + self.getDebitCourant() + " - volumeRestant = " + volumeRestant;}
					
					if(!empty(listeBarragesMoinsSelf)){
						volumeRestant <-  myself.majDebitPourEtiageLocal(listeBarragesMoinsSelf, volumeRestant);	
					}
					if( isForce and getVolumeBarrage() > 0.0 and quotaAnnuelRestant > 0.0){	 //debitRestant > 0.0 and
 							listeBarragesMoinsSelf <- [self];						
 							volumeRestant <- myself.majDebitPourEtiageLocal(listeBarragesMoinsSelf, volumeRestant);
 							
							if verboseMode {write "" + self + " - !!!!!! - volumeRestant = " + volumeRestant + " - liste = " + listeBarragesMoinsSelf;}
						
					}											
				}
			}										
		}	
		
		
		//write "" + self + " - volumeEtDebitEntree 2 = " + volumeEtDebitEntree + " - isForce = " + isForce;
						
		return volumeRestant;
	}		
}
