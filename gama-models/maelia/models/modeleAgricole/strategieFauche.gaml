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
 *  strategieTravailSol
 *  Author: Renaud Misslin
 *  Description: fauche des prairies, fonctionne avec herbsim
 */

model strategieFauche

import "Ilots/ilot.gaml"
import "strategieOT.gaml"

global{ }

species strategieFauche parent: strategieOT{
	list<strategieFaucheMultiples> mesStrategiesMultiples; 
	float hauteurCoupe <- 6.0; //    spécifique fauche [cm]
	int delaiCoupe <- 0; // Nombre de jours min entre chaque coupe
	map<int,float> mapNbJoursTminMoyennee <- map<int,float>([]);// voir SEMIS RM 220823
	map<int,float> mapTminMoyennee <- map<int,float>([]);// voir SEMIS pour code RM 220823
	map<int,float> mapVolumeHerbe <- map<int,float>([]);
	map<int,float> mapHauteurHerbeMin <- map<int,float>([]);
	map<int,float> mapQuantiteBiomasseMin <- map<int,float>([]);
	map<int,float> mapDigestabiliteMin <- map<int,float>([]);
	
	/*
	 * *****************************************************************************************
	 * TODO : attention, il faut bien que ca se fasse avant la culture prevue, pas apres
	 */		
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle != nil and parcelleEntree.isFauchable and parcelleEntree.lotAnimauxCourant = nil){
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){  
				estOk <- isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
								and isHauteurHerbeMinOk(parcelleEntree,deltaTemporel)
								and isTemperatureMinMoyenneOK(parcelleEntree.ilot_app.meteo, deltaTemporel)
								and isVolumeHerbeOk(parcelleEntree,deltaTemporel)
								and isQuantiteBiomasseOk(parcelleEntree,deltaTemporel, hauteurCoupe)
								and isDigestabiliteOk(parcelleEntree,deltaTemporel)
								and parcelleEntree.cpt_fauche >= delaiCoupe;
								//and !(parcelleEntree.OTFaucheMultiplesEffectuee contains self);
//				write "biomasse suffisante --> " + isQuantiteBiomasseOk(parcelleEntree,deltaTemporel, hauteurCoupe)
//					+ " -- fauche pas faite = " + !(parcelleEntree.OTFaucheMultiplesEffectuee contains self)
//					+ " -- hauteur = " + isHauteurHerbeMinOk(parcelleEntree,deltaTemporel)
//					+ " -- délai fauche = " + (parcelleEntree.cpt_fauche >= delaiCoupe)
//					+ " -- volume = " + isVolumeHerbeOk(parcelleEntree,deltaTemporel);
			} 
		}

		return estOk;
	}
	
	bool isTemperatureMinMoyenneOK(zoneMeteo zoneMeteoIlotAssocie, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursTminMoyennee, parcelle(nil), deltaTemporel) and isDonnee(mapTminMoyennee, parcelle(nil), deltaTemporel)){		
			ask zoneMeteoIlotAssocie {
				res <- (getTminMoyenne(nb_jours:int(myself.mapNbJoursTminMoyennee at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel))) >= (myself.mapTminMoyennee at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel)));				
			}				
		}		
		return res;
	}	
	/*
	 * *****************************************************************************************
	 */
//	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
//		// JV 140121 stocke uniquement si utile
//		if parc.memoireOTsurParcelle.keys contains REPRISE_TRAVAIL_SOL {				 		
//			ask parc{
//				put getITKAnnee() at:dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at REPRISE_TRAVAIL_SOL);
//				float profondeur <- nil;
//				if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
//					profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite);
//				}				
//				map<string,string> complements <- ["prof"::string(profondeur)];
//				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at REPRISE_TRAVAIL_SOL);								
//			}
//		}	
//		do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
//		parc.isRepriseTravailSolEffectue <- true;
//		do ecritureDebugActivite(parc);
//		
//		if(verboseMode){write "REPRISE_TRAVAIL_SOL " + parc.getITKAnnee().idITK + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 		
//	}
	
	
	
	// Méthodes de vérifications des contraintes spécifiques à la fauche des prairies
	
	// Fenêtre temporelle globale (pas de sous-période)
//	bool isFenetreTemporelleGlobaleOk (int jourC, int jourJulienFenetreMin, int jourJulienFenetreMax) {
//		if (jourJulienFenetreMax < jourJulienFenetreMin) {
//			return jourC >= jourJulienFenetreMin or jourC <= jourJulienFenetreMax;	
// 		}else {
//			return jourC >= jourJulienFenetreMin and jourC <= jourJulienFenetreMax;
//		}
//	}
	
	// Hauteur de coupe
	bool isHauteurHerbeMinOk (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true; 
		}else{
			if(isDonnee(mapHauteurHerbeMin, parcelleEntree, deltaTemporel)){
				res <- parcelleAqYield(parcelleEntree).getHauteurHerbe() >= getDonneeCourante(mapHauteurHerbeMin, parcelleEntree, deltaTemporel);
			}else{
				res <- true;
			}				
		}						
		return res;
	}
	
	// Volume d'herbe
	bool isVolumeHerbeOk (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true;
		}else{
			if(isDonnee(mapVolumeHerbe, parcelleEntree, deltaTemporel)){
				res <- parcelleAqYield(parcelleEntree).getVolumeHerbe() >= getDonneeCourante(mapVolumeHerbe, parcelleEntree, deltaTemporel);
			}else{
				res <- true;
			}				
		}						
		return res;
	}
	
	// Quantite de biomasse
	bool isQuantiteBiomasseOk (parcelle parcelleEntree, int deltaTemporel, float hauteurCoupeStrat) {
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true; 
		}else{
			if(isDonnee(mapQuantiteBiomasseMin, parcelleEntree, deltaTemporel)){
//				write "test fauche 2208 --> seuil biomasse = " + getDonneeCourante(mapQuantiteBiomasseMin, parcelleEntree, deltaTemporel);			
				res <- parcelleAqYield(parcelleEntree).getQuantiteBiomasse(hauteurCoupeStrat) / 1000 >= getDonneeCourante(mapQuantiteBiomasseMin, parcelleEntree, deltaTemporel);
//				write "test fauche 2208 --> biomasse recoltable = " + parcelleAqYield(parcelleEntree).getQuantiteBiomasse(hauteurCoupeStrat) / 1000;
			}else{
				res <- true;
			}				
		}
		// write "quantité biomasse = " + parcelleAqYield(parcelleEntree).getQuantiteBiomasse() + " -- valeur rdd = " + getDonneeCourante(mapQuantiteBiomasseMin, parcelleEntree, deltaTemporel);	
		return res;
	}
		
	// Digestabilte
	bool isDigestabiliteOk (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;
		if (parcelleEntree.isParcelleHorsZone){
			res <- true; 
		}else{
			if(isDonnee(mapDigestabiliteMin, parcelleEntree, deltaTemporel)){
				res <- parcelleAqYield(parcelleEntree).getDigestabiliteHerbe() >= getDonneeCourante(mapDigestabiliteMin, parcelleEntree, deltaTemporel);
			}else{
				res <- true;
			}				
		}						
		return res;
	}
	
	// Gestion fauche multiple Renaud 220823
	action getProchaineOT (parcelle parcelleCourante) { // Récupère la prochaine OT seulement si la date courante tombe dans la fenêtre temporelle de l'OT et que celle-ci n'a jamais été réalisée sur la parcelle
		// Les OT qui tombent dans les bonnes dates et qui n'ont pas éncore été effectuées (qui n'apparaissent pas dans la liste correspondante de la parcelle) sont récupérées
		list<strategieFaucheMultiples> toutes_ot_fauche <- self.mesStrategiesMultiples;// where (!(parcelleCourante.OTFaucheMultiplesEffectuee contains each)); // Toutes les OT du type en cours non réalisées 
		list<strategieFaucheMultiples> OT_possibles_aujourdhui;
		strategieFaucheMultiples prochaineOT <- nil;
		
		// 1. On regarde si une ou plusieurs OT ont une fenêtre temporelle qui correspond au jour courant, si oui la prochaine OT est l'OT qui commence le plus tôt
		
		ask toutes_ot_fauche {
			if (self.isFenetreTemporelleOk(parcelleCourante, parcelleCourante.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite)) {
				OT_possibles_aujourdhui <+ self;
			}
		}

		if (length(OT_possibles_aujourdhui) > 0) {
			OT_possibles_aujourdhui <- reverse(OT_possibles_aujourdhui sort_by (dateCour.calculNbJour_passe(each.mapFenetresTemporellesDebut[0]))); // On classe les OT possibles aujourd'hui de celle qui a commencé le plus tôt à celle qui a commencé le plus tard
			prochaineOT <- first(OT_possibles_aujourdhui);
		} else {
			// 2. Si pas d'OT possible au jour courant, on récupère l'OT qui commence au plus proche dans le temps
			// Classement des opérations pour sélectionner l'opération non réalisée la plus proche dans le temps
			list<strategieFaucheMultiples> OT_dates_debut_sup <- toutes_ot_fauche where ((each.mapFenetresTemporellesDebut[0] > dateCour.nbJoursEcoulesDansAnnee)
																							or (each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee and last(each.mapFenetresTemporellesFin) >= dateCour.nbJoursEcoulesDansAnnee)
																							or ((each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee) and last(each.mapFenetresTemporellesFin) < each.mapFenetresTemporellesDebut[0])
																							); // Récupération des OT non réalisées dont la date de début est supérieure au jour courant et celles pour lesquelles le jour courant tombe dans la fenêtre temporelle
			
			if (length(OT_dates_debut_sup) > 0) { // Si il y a des OT non réalisée dont la date de début est supérieure à la date courante, on prend la plus petite date parmi les OT en question
				OT_dates_debut_sup <- OT_dates_debut_sup sort_by (dateCour.calculNbJour_futur(each.mapFenetresTemporellesDebut[0])); // modif renaud 010623
				prochaineOT <- first(OT_dates_debut_sup);		
			} else { // Si il n'y a QUE une/des OT dont la date de début est inférieure à la date courante, on prend la plus petite date parmi l'ensemble des OT
				toutes_ot_fauche <- toutes_ot_fauche sort_by each.mapFenetresTemporellesDebut[0]; // Récupère la date de début de la première sous-période
				prochaineOT <- first(toutes_ot_fauche);
			}
		}
		
		parcelleCourante.faucheMultipleCourant <- prochaineOT;
		
		return prochaineOT;
	}


}	

