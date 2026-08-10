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
 *  strategieFertiApport
 *  Author: Renaud Misslin
 *  Description: 
 */

model strategieFertiApport 

import "Ilots/ilot.gaml"

global{}

species strategieFertiApport parent: strategieFertiAlternative {	
	int ordre_apport;
	string nom_produit;
	bool agriw;
	string outil;
	int n_passages;
	bool premier_apport_mineral;
//	map<int,float> mapNbJoursPluiePrevues <- map<int,float>([]);//  IRRIGATION PHYTO
//	map<int,float> mapHauteurPluiePrevuesMin <- map<int,float>([]);//  IRRIGATION PHYTO
	map<int, float> mapNbJoursAuMoinsPluiePrevuesCumuleeMin <- map<int, float>([]); //  APPORT
	map<int, float> mapHauteurAuMoinsPluiePrevuesCumuleeMin <- map<int, float>([]); //  APPORT	
 	
 	// Est-ce que le cumul de pluie dans les n prochains jours est inferieur à la hauteur donnée ?
//	bool isCumuleHauteurPluiePrevuesOK(zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel){
//		bool res <- true;			
//		if(isDonnee(mapNbJoursPluiePrevues, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurPluiePrevuesMin, parcelleEntree, deltaTemporel)
//		){		
//			int nbJour <- int(getDonneeCourante(mapNbJoursPluiePrevues,parcelleEntree, deltaTemporel));
//			float hauteur <- getDonneeCourante(mapHauteurPluiePrevuesMin,parcelleEntree, deltaTemporel);
//			ask zoneMeteoIlotAssocie {
//				res <- (getMaxPluiesPrevues(nb_jours:nbJour) *parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
//			}				
//		}		
//		return res;
//	}
 	
	// Est-ce que le cumul de pluie dans les n prochains jours est superieur à la hauteur donnée ? // renaud 131023
	bool isAuMoinsCumuleHauteurPluiePrevuesOK (zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel) {
		bool res <- true;
		if (isDonnee(mapNbJoursAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel)) {
			int nbJour <- int(getDonneeCourante(mapNbJoursAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getCumulPluiesPrevues(nb_jours: nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau >= hauteur);
			}

		}

		return res;
	}
 	
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){ //1 ferti par periode
		bool estOk <- false;
		
		if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
			
			estOk <- isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
							and isHumiditeSolOK(parcelleEntree,deltaTemporel)
							and isEchelleVegetationOK(parcelleEntree,deltaTemporel)
							and !(parcelleAqYieldNC(parcelleEntree).apportsEffectues contains self)
							and !(parcelleAqYieldNC(parcelleEntree).apportsAnnules contains self)
							and isAuMoinsCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel);
//							and isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel);
	
//			write "--";
//			write "essai apport " + ordre_apport + " sur " + parcelleEntree.idParcelle;
//			write 'isCumuleHauteurPluieOK '+ isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel);
//			write 'isHumiditeSolOK '+ isHumiditeSolOK(parcelleEntree,deltaTemporel);
//			write 'isEchelleVegetationOK '+ isEchelleVegetationOK(parcelleEntree,deltaTemporel);
//			write '!apportsEffectues '+ !(parcelleAqYieldNC(parcelleEntree).apportsEffectues contains self);
//			write '!apportsAnnules '+ !(parcelleAqYieldNC(parcelleEntree).apportsAnnules contains self);
//			write 'isAuMoinsCumuleHauteurPluiePrevuesOK '+ isAuMoinsCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel);
		}

		
		parcelleAqYieldNC(parcelleEntree).apport_courant <- self;
		return estOk;
		
	}
	
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
//		write parc.idParcelle + " -ITKFERTi- Mise en oeuvre de l'activité de fertilisation";
		
		bool apport_annule <- false;
		// Doses à apporter pour l'apport en cours
		Engrais produit_apport <- Engrais first_with (each.nomEngrais = self.nom_produit); // Dose per Ha
		
		float doseN <- doseParHectare;
		float doseP <- dosePParHectare;
		float doseK <- doseKParHectare;

		float doseN_originale <- doseParHectare;
		
		ask parcelleAqYieldNC(parc) { // Application de la fertilisation
			// Adaptation de la ferti (recalcul des doses si nécéssaire)
			if (adaptationFertilisation = "corpen" and getITKAnnee().optimisation_corpen and doseN > 0.0) {
				// Si produit minéral (seuls les apports minéraux sont rabattus)
				if (produit_apport.Fertilizer_type = "mineral") {
					doseN <- myself.doseParHectare * parcelleAqYieldNC(parc).coef_abattement_corpen;
					doseP <- myself.dosePParHectare;
					doseK <- myself.doseKParHectare;
					
//					write "--------- Apport minéral";
//					write "parcelle = " + parc.idParcelle + " -- " + getITKAnnee().especeCultiveeITK.idEspeceCultivee;
//					write "dose originale corpen = " + doseN + " --- dose itk = " + doseN_originale;
//					write "Nmin_apports_min = " + Nmin_apports_min;
					//float ratio_apportMin_courant <- myself.doseParHectare / Nmin_apports_min;
					
					// Premier apport : abattement selon le N dispo au semis
					if (myself.premier_apport_mineral = true) {
						float diff_dose_Ndispo <- doseN - N_dispo_semis;
//						write "premier apport minéral de " + doseN + " kg N/ha (N_dispo_semis = " + N_dispo_semis + ")";
						
						// Annulation ou réduction de l'apport en fonction du N dispo
						if (diff_dose_Ndispo < 20) { // Si (doseN - QNinitialeJ_r) < 20 pas de premier apport
//							write "apport annulé car trop faible";
							apport_annule <- true;
							doseN <- 0.0;
						} else { // Sinon, on fait 20 +  (doseN - QNinitialeJ_r)
							doseN <- float(doseN - round(N_dispo_semis / 10)  * 10); // On enlève la différence entre la dose N initiale et le N dispo dans R arrondie à la dizaine la plus proche
//							write "doseN corrigée = " + doseN;
						}
					} else {
						// Annulation ou réduction de l'apport en fonction du N dispo
						if (doseN < 20) { // Si (doseN - QNinitialeJ_r) < 20 pas de premier apport
//							write "apport annulé car trop faible";
							apport_annule <- true;
							doseN <- 0.0;
						} else { // Sinon, on fait 20 +  (doseN - QNinitialeJ_r)
//						write "doseN avant correction = " + doseN + " -- N_dispo_semis non arrondi = " + N_dispo_semis;
							doseN <- float(round(doseN / 10)  * 10); // On enlève la différence entre la dose N initiale et le N dispo dans R arrondie à la dizaine la plus proche
//							write "doseN corrigée = " + doseN + "(N_dispo_semis arrondi = " + round(N_dispo_semis / 10)  * 10 + ")";
						}
					}
					
					// Pour l'instant on ne rabat pas le P et le K en fonction du coefficient d'abattement corpen (Renaud Olivier 20082025)
//					doseP <- doseP * ratio_abattementN;
//					doseK <- doseK * ratio_abattementN;
				// Si produit organique -> rien ne se passe
				}
			}
			
//			write "apport " + produit_apport.Fertilizer_type + " sur " + parc.idParcelle; 
			// Récupération de la dose potentiellement modifiée par gestion souple des PRO à l'échelle exploitation 060225 Renaud
			if (produit_apport.Fertilizer_type = "organic" and gestionStocksEngrais = 'exploitation') {
				doseN <- parcelleAqYieldNC(parc).engrais_reserves_parcelle[produit_apport];
//				write 'je vais apporter ' + doseN + " de " + myself.nom_produit + " sur " + parc.idParcelle;
				//doseN_corpen <- doseN;
			}
			
			// Si l'apport n'est pas annulé (annulation possible seulement pour le permier apport) ou si le module d'adaptation de la ferti n'est pas activé
			if (!apport_annule) {
				do fertilisation (myself.nom_produit, doseN, doseP, doseK, myself.outil, 0.0);
//				do calculPrix(myself.nom_produit, doseN, doseP, doseK, myself.outil, 1 / (myself.tempsDexecution / 10000)); // Ici le temps de travail est converti en h/ha
				
				// Réalisation effective de la fertilisation			
				// Update de la quantité d'engrais utilisée sur le territoire (par type d'engrais)
				// Attention : les PRO sont en T et les engrais minéraux sont en Kg de N
				float quantite_deja_utilisee <- quantites_engrais_annuelles[myself.nom_produit];
				float nouvelle_quantite_utilisee <- quantite_deja_utilisee + doseN * (self.surface / nombreMeterCarreDansUnHectare);
//				write "Apport de " + doseN * (self.surface / nombreMeterCarreDansUnHectare) + " - " + myself.nom_produit;
				engrais_reserves_parcelle >- parcelleAqYieldNC(parc).engrais_reserves_parcelle[produit_apport];
				put nouvelle_quantite_utilisee at: myself.nom_produit in: quantites_engrais_annuelles; // Décompte au niveau territoire
				put nouvelle_quantite_utilisee at: myself.nom_produit in: parc.ilot_app.agriculteurAssocie.sonExploitation.cumul_engrais_utilises;
			} else {
//				write "!!!! apport annulé !!!!";
			}
			

				
//			write parc.idParcelle + "|" + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + "|" + myself.nom_produit + "|" + doseN + "|" + parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee;
//			write "Apport original -> " + myself.doseParHectare * (self.surface / nombreMeterCarreDansUnHectare) + "Apport corrigé -> " + doseN * (self.surface / nombreMeterCarreDansUnHectare);
//			write "Quantité totale de PRO utilisée -> " + myself.nom_produit + " = " + quantites_engrais_annuelles[myself.nom_produit];
			
		}
		
		
		// ------------------------------------
		// Reallocation d'une partie ou de tout l'apport si l'apport est annulé ou si la dose a changé
		// Si l'apport a été annulé (peut arriver seulement pour le permier apport
		if (apport_annule) {
			do  reallocationProduit(parcelleAqYieldNC(parc), self, doseParHectare);
			add self to: parcelleAqYieldNC(parc).apportsAnnules;
//			write "Réallocation totale du produit en provenance de la parcelle " + parcelleAqYieldNC(parc).idParcelle;
		}
		
		// Si la dose a changé
		if (doseN < doseN_originale) {
			float dose_reallouee <- doseN_originale - doseN; // Peut être négatif ?
			do  reallocationProduit(parcelleAqYieldNC(parc), self, dose_reallouee);
//			write "Réallocation partielle du produit en provenance de la parcelle " + parcelleAqYieldNC(parc).idParcelle;
		} else if (doseN > doseN_originale) {
//			write "Renaud 120825 --> Correction à faire si dose appliquée est supérieure à dose prévue"; 
		}
		// ------------------------------------
		
		
		if (!apport_annule) {
			// Ajout du temps de retour pour le produit courant sur la parcelle courante
			if (parcelleAqYieldNC(parc).temps_retour.keys contains nom_produit) {
				int tps_retour <- parcelleAqYieldNC(parc).temps_retour[nom_produit];
				if (tps_retour > 0) {
					parcelleAqYieldNC(parc).temps_retour_courant <+ nom_produit::tps_retour;
				}
				 
			}
			
			// Application des effets du travail du sol
			do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite); 
			
			// Apport réalisé --> ajouté à la liste des apports effectués
			add self to: parcelleAqYieldNC(parc).apportsEffectues;
			
			// Enregistrement du produit et de la quantité apportée (cf parcelle.gaml)
			parc.nApportProduits[nom_produit] <- parc.nApportProduits[nom_produit] + 1;
			parc.quantitesProduits[nom_produit] <- parc.quantitesProduits[nom_produit] + doseParHectare;
	
			if parc.memoireOTsurParcelle.keys contains FERTI {
				ask parc{
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at FERTI);
					Engrais produit <- Engrais first_with (each.nomEngrais = myself.nom_produit);
					float profondeur <- nil;
					if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
						profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite);
					}		
					/* JV 210522
					 * si produit minéral
					 * 		doseProduitBrute = NA (on n'a pas l'info de la dose brute dans l'ITK on a la dose en équivalement N minéral)
					 * 		apportNmin = dose (directement la dose lue dans l'ITK en kg/ha)
					 * 		apportNorg = 0 (pas de N org dans un produit minéral)
					 * si produit organique
					 * 		doseProduitBrute = 1000*dose (car en t/ha dans l'ITK)
					 * 		apportNmin = QNapport_pro_direct_calc = 1000*dose * produit.Nmin / 100
					 * 		apportNorg = N_labile + N_recalcitrant
					 */
					float doseProduitBrute <- -1.0; // -1 pour produits minéraux car on ne connaît pas la dose brute
					float apportNminTheorique <- 0.0;
					float apportNminReel <- 0.0;
					float N_labile <- 0.0;
					float N_recalcitrant <- 0.0;
					if produit.Fertilizer_type="mineral" {
						apportNminTheorique <- doseN_originale;
						apportNminReel <- doseN;
					} else {
						doseProduitBrute <- 1000.0 * myself.doseParHectare;
						apportNminTheorique <- doseProduitBrute*produit.Nmin/100.0;
						apportNminReel <- doseProduitBrute*produit.Nmin/100.0;
						float C_recalcitrant <- doseProduitBrute * produit.C / 100 * produit.C2; // Quantité de carbone dans le pool récalcitrant; sans self.surface / 10000
						float C_labile <- doseProduitBrute * produit.C / 100 * (1 - produit.C2); // Quantité de carbone dans le pool labile; sans self.surface / 10000
						float CNres_labile <- produit.CNorg * produit.aCN1;
						float CNres_recalcitrant <- produit.C2 * produit.CNorg * produit.aCN1 * produit.CNorg / (produit.aCN1 * produit.CNorg - (1 - produit.C2) * produit.CNorg);
						N_labile <- C_labile / CNres_labile; // Quantité d'azote dans le pool labile
						N_recalcitrant <- C_recalcitrant / CNres_recalcitrant;					
					}
					map<string,string> complements <- ["prof"::string(profondeur with_precision nb_decimales_sorties), "fertiNCdoseBruteOrg"::string(doseProduitBrute with_precision nb_decimales_sorties), "fertiNCproduit"::myself.nom_produit, "fertiNCnature"::produit.Fertilizer_type, "fertiNCAnnulee"::"N", "fertiNCapportNminTheorique"::string(apportNminTheorique with_precision nb_decimales_sorties), "fertiNCapportNminReel"::string(apportNminReel with_precision nb_decimales_sorties), "fertiNCapportNorg_labile"::string(N_labile with_precision nb_decimales_sorties), "fertiNCapportNorg_recalcitrant"::string(N_recalcitrant with_precision nb_decimales_sorties)];					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at FERTI);								
				}
			}
			
		} else { // Si apport annulé, on enregistre le fait qu'il ait été annulé
			if parc.memoireOTsurParcelle.keys contains FERTI {
				ask parc{
					Engrais produit <- Engrais first_with (each.nomEngrais = myself.nom_produit);
					float apportNminTheorique <- 0.0;
					float apportNminReel <- 0.0;
					if produit.Fertilizer_type="mineral" {
						apportNminTheorique <- doseN_originale;
						apportNminReel <- doseN;
					}
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at FERTI);
					map<string,string> complements <- ["prof"::string(0), "fertiNCproduit"::myself.nom_produit, "fertiNCnature"::produit.Fertilizer_type, "fertiNCAnnulee"::"O", "fertiNCapportNminTheorique"::string(apportNminTheorique), "fertiNCapportNminReel"::string(apportNminReel), "fertiNCapportNorg_labile"::string(0), "fertiNCapportNorg_recalcitrant"::string(0)];
					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at FERTI);
				}
			}
		}

		// L'apport n'est plus à faire : soit il a été réalisé, soit il a été annulé
		parcelleAqYieldNC(parc).apport_courant <- nil;

		do ecritureDebugActivite(parc);
		 
	}
}	

