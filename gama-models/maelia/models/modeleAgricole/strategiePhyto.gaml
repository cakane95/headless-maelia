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
 *  strategieBinage
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model strategiePhyto

import "Ilots/ilot.gaml"

global{}

species strategiePhyto parent: strategieOT{
	list<strategiePhytoMultiples> mesStrategiesMultiples; 

	map<int,float> mapNbJoursPluiePrevues <- map<int,float>([]);//  IRRIGATION PHYTO
	map<int,float> mapHauteurPluiePrevuesMin <- map<int,float>([]);//  IRRIGATION PHYTO
	float doseParHectare <- 0.0;
	string unite_dose <- "";
	string type_phyto <- "";
	
	bool isCumuleHauteurPluiePrevuesOK(zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursPluiePrevues, parcelleEntree, deltaTemporel) and
			isDonnee(mapHauteurPluiePrevuesMin, parcelleEntree, deltaTemporel)
		){		
			int nbJour <- int(getDonneeCourante(mapNbJoursPluiePrevues,parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurPluiePrevuesMin,parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getMaxPluiesPrevues(nb_jours:nbJour) *parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
			}				
		}		
		return res;
	}
	
			
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){ //1 ferti par periode
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle != nil){
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				estOk <- 	isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
							and isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel)
							and !isDejaFait(parcelleEntree,deltaTemporel);								
			}
//			write "cumul de pluie ok = " + isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel);
//			write "cumul de pluie prévue ok = " + isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel);
//			write "déjà fait = " + !isDejaFait(parcelleEntree,deltaTemporel);
			
		}
		

		return estOk;
	}
	
		
	bool isDejaFait(parcelle parcelleEntree,int deltaTemporel){
		if(parcelleEntree.isPhytoDeLaPeriodeEffectue at getIndiceSousPeriode(parcelleEntree, deltaTemporel) != nil){
			return parcelleEntree.isPhytoDeLaPeriodeEffectue at getIndiceSousPeriode(parcelleEntree, deltaTemporel);				
		}else{
			return false;
		}			
	}	
	
	action sauvegarde_donnees_ibio (parcelle parc) {
		// write "i-bio : Application de " + type_phyto;
		// Nb psticide total
		parc.nb_traitements_total <- parc.nb_traitements_total + 1;
		
		// Timing d'application de l'herbicide
		if (type_phyto contains 'herbicide') {
			// Variable indiquant quand ont été fait les traitements sur la culture (avant la levée ou après ou les deux ?) 
			if (parc.cultureParcelle = nil) { // Si pas de culture en place
				parc.herbicide_timing <- "Both or pre-emergence";
			} else { // Si il y a une culture en place
				parc.herbicide_timing <- "Post-emergence";
			}
		}
		
		// Monocot, dicot, insecticide ou autre ?
		if (type_phyto = 'herbicide systémique') { // Monocot. et dicot.
			parc.nb_traitements_monocot <- parc.nb_traitements_monocot + 1;
			parc.nb_traitements_dicot <- parc.nb_traitements_dicot + 1;
		} else if (type_phyto = 'herbicide monocot.') { // Monocot
			parc.nb_traitements_monocot <- parc.nb_traitements_monocot + 1;
		} else if (type_phyto = 'herbicide dicot.') { // Dicot
			parc.nb_traitements_dicot <- parc.nb_traitements_dicot + 1;
		} else if (type_phyto = 'insecticide') { // Insecticide
			parc.nb_traitements_insecticides <- parc.nb_traitements_insecticides + 1;
		} else { // Autre (fongi)
			parc.nb_traitements_autres <- parc.nb_traitements_autres + 1;
		}	
	}
	
	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		if (!plusieursTraitementsPhytoParITK) {
			// JV 140121 stocke uniquement si utile
			if parc.memoireOTsurParcelle.keys contains PHYTO {				 		
				ask parc{
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at PHYTO);
				}
			}	
			put true at: getIndiceSousPeriode(parc, agri.nbJoursDeDecalageActivite) in: parc.isPhytoDeLaPeriodeEffectue;
			do ecritureDebugActivite(parc);	
		} else { // Plusieurs opérations phyto
			ask parc.phytoMultipleCourant {
				do miseEnOeuvreActivite(parc, agri, idGroupe, surfaceIrrigueeEntree);
			}
		}
		
		// Inscription en mémoire des données concernant ibio si activé
		if (sorties_iBio) {
			do sauvegarde_donnees_ibio(parc);
		}
	}
	
	// Gestion traitement phyto multiple ajout le 20/03/23 copié de Renaud 18/03/2020 dans wsol multiple
	action getProchaineOT (parcelle parcelleCourante) { // Récupère la prochaine OT seulement si la date courante tombe dans la fenêtre temporelle de l'OT et que celle-ci n'a jamais été réalisée sur la parcelle
		// Les OT qui tombent dans les bonnes dates et qui n'ont pas éncore été effectuées (qui n'apparaissent pas dans la liste correspondante de la parcelle) sont récupérées
		list<strategiePhytoMultiples> OT_non_realisees <- self.mesStrategiesMultiples where (!(parcelleCourante.OTPhytoMultiplesEffectuee contains each)); // Toutes les OT du type en cours non réalisées 
		list<strategiePhytoMultiples> OT_possibles_aujourdhui;
		strategiePhytoMultiples prochaineOT <- nil;
		
		// 1. On regarde si une ou plusieurs OT ont une fenêtre temporelle qui correspond au jour courant, si oui la prochaine OT est l'OT qui commence le plus tôt
		
		ask OT_non_realisees {
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
			list<strategiePhytoMultiples> OT_dates_debut_sup <- OT_non_realisees where ((each.mapFenetresTemporellesDebut[0] > dateCour.nbJoursEcoulesDansAnnee)
																							or (each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee and last(each.mapFenetresTemporellesFin) >= dateCour.nbJoursEcoulesDansAnnee)
																							or ((each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee) and last(each.mapFenetresTemporellesFin) < each.mapFenetresTemporellesDebut[0])
																							); // Récupération des OT non réalisées dont la date de début est supérieure au jour courant et celles pour lesquelles le jour courant tombe dans la fenêtre temporelle
			
			if (length(OT_dates_debut_sup) > 0) { // Si il y a des OT non réalisée dont la date de début est supérieure à la date courante, on prend la plus petite date parmi les OT en question
				OT_dates_debut_sup <- OT_dates_debut_sup sort_by (dateCour.calculNbJour_futur(each.mapFenetresTemporellesDebut[0])); // modif renaud 010623
				prochaineOT <- first(OT_dates_debut_sup);		
			} else { // Si il n'y a QUE une/des OT dont la date de début est inférieure à la date courante, on prend la plus petite date parmi l'ensemble des OT
				OT_non_realisees <- OT_non_realisees sort_by each.mapFenetresTemporellesDebut[0]; // Récupère la date de début de la première sous-période
				prochaineOT <- first(OT_non_realisees);
			}
		}

		parcelleCourante.phytoMultipleCourant <- prochaineOT;
		
		return prochaineOT;
	}
	
}	

