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
 *  Author: Maroussia Vavasseur
 *  Description: Il sagit du travail du sol preleminaire au semis
 */

model strategieTravailSol

import "Ilots/ilot.gaml"

global{ }

species strategieTravailSol parent: strategieOT {		
	list<strategieTravailSolMultiples> mesStrategiesMultiples; // Liste comprenant les stratégies multiple de l'opération technique courante. Reste vide si l'option "stratégies multiples" est désactivée // Gestion travaux du sol multiple Renaud 18/03/2020
	
	/*
	 * *****************************************************************************************
	 * TODO : attention, il faut bien que ca se fasse avant la culture prevue, pas apres
	 */		
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){
		bool estOk <- false;
		if !(plusieursTravauxDuSolParITK) { // Une seule opération de travail du sol // Gestion travaux du sol multiple Renaud 18/03/2020
			if(parcelleEntree.cultureParcelle = nil){ // TODO : vérifier si cette condition doit aussi être appliquée en cas d'opération multiple (Renaud 25/03/2020)
				if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){					
					estOk <- isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo,parcelleEntree,deltaTemporel)
									and isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
									and isHumiditeSolOK(parcelleEntree,deltaTemporel)
									and !parcelleEntree.isTravailSolEffectue;
				}			
			}
		} else { // Plusieurs opérations de travail du sol 
			// L'opération de travail du sol sélectionnée est testée
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				estOk <- isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo,parcelleEntree,deltaTemporel)
								and isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
								and isHumiditeSolOK(parcelleEntree,deltaTemporel)
								and !(parcelleEntree.OTTravailSolMultiplesEffectuee contains self);
			}
		}

		return estOk;
	}
	
	
	
	// TODO : enlever la condition sur plusieursTravauxDuSolParITK et redéfinir miseEnOeuvreActivite dans strategieTravailSolMultiples
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		if !(plusieursTravauxDuSolParITK) { // Une seule opération de travail du sol
			// JV 140121 stocke uniquement si utile
			if parc.memoireOTsurParcelle.keys contains TRAVAIL_SOL {				 		
				ask parc{
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at TRAVAIL_SOL);
					float profondeur <- nil;
					if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
						profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) with_precision nb_decimales_sorties;
					}				
					map<string,string> complements <- ["prof"::string(profondeur)];
					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at TRAVAIL_SOL);								
				}
			}
			do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
			parc.isTravailSolEffectue <- true;
			if(verboseMode){write "TRAVAIL_SOL " + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 			
			do ecritureDebugActivite(parc);										
		} else { // Plusieurs opérations de travail du sol
			ask parc.travailDuSolMultipleCourant {
				do miseEnOeuvreActivite(parc, agri, idGroupe, surfaceIrrigueeEntree);
			}
		}						

	}

	// Gestion travaux du sol multiple Renaud 18/03/2020
	action getProchaineOT (parcelle parcelleCourante) { // Récupère la prochaine OT seulement si la date courante tombe dans la fenêtre temporelle de l'OT et que celle-ci n'a jamais été réalisée sur la parcelle
		// Les OT qui tombent dans les bonnes dates et qui n'ont pas éncore été effectuées (qui n'apparaissent pas dans la liste correspondante de la parcelle) sont récupérées
		list<strategieTravailSolMultiples> OT_non_realisees <- self.mesStrategiesMultiples where (!(parcelleCourante.OTTravailSolMultiplesEffectuee contains each)); // Toutes les OT du type en cours non réalisées 
		list<strategieTravailSolMultiples> OT_possibles_aujourdhui;
		strategieTravailSolMultiples prochaineOT <- nil;
		
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
			list<strategieTravailSolMultiples> OT_dates_debut_sup <- OT_non_realisees where ((each.mapFenetresTemporellesDebut[0] > dateCour.nbJoursEcoulesDansAnnee)
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
		
		parcelleCourante.travailDuSolMultipleCourant <- prochaineOT;
		
		return prochaineOT;
	}

}	

