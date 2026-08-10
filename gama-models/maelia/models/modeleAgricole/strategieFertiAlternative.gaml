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
 *  strategieFertiAlternative
 *  Author: Renaud Misslin
 *  Description: 
 */

model strategieFertiAlternative

import "../modeleCommun/donneesGlobales.gaml"
import "strategieFertiApport.gaml"
import "exploitation.gaml"

global{}

species strategieFertiAlternative parent: strategieFerti{	
	string nom_alternative;
	int ordre_alternative;
	strategieFerti strategieFerti_parent;
	list<strategieFertiApport> mesApports;
	int jourChoixStrategie; // J-15 avant le premier apport
	float apport_Nmin_total_sans1erApport <- 0.0; // Dose totale de N minéral apportée dans l'itk sans compter la dose du premier apport minéral de l'itk //adaptation ferti
	float seuil_acceptation_pro <- 0.1; // Mode gestion des stocks par exploitation : je prends le reste du stock seulement si ca me permet de satisfaire au moins x % de ma demande initiale

 		
	// Redéfinition de la fonction getIndiceSousPeriode pour repasser en mode classique (une OT ferti sur l'ensemble des sous-périodes)
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
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){	
		// Retrouver le bon apport à mettre en oeuvre (c'est là que la fonction de parcelleAqYeildNC est appelé (dose+type d'engrais)

		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains FERTI {				 
			ask parc{
				put getITKAnnee() at:dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at FERTI);
			}
		}
		put true at: getIndiceSousPeriode(parc, agri.nbJoursDeDecalageActivite) in: parc.isFertiDeLaPeriodeEffectue;				
		do ecritureDebugActivite(parc);																			
	}
	
	// Permet de tester si le temps de retour est ok pour un produit x une parcelle
	bool isTempsRetourOk(parcelle parc) {
		list<bool> isProduitsOk;
		
		// On parcourt les apports en comparant les noms des produits aux produits contenu dans la liste des temps de retour courant de la parcelle
		loop apport over: mesApports {
			string produit_courant <- apport.nom_produit;
			if (parcelleAqYieldNC(parc).temps_retour_courant.keys contains produit_courant) {
				isProduitsOk <+ false;
			} else {
				isProduitsOk <+ true;
			}
		}
//		write parc.idParcelle + " -- Temps de retour -> " + isProduitsOk;
		
		// L'alternative peut-elle être réalisée ?
		if (isProduitsOk contains false) {
			return false;
		} else {
			return true;
		}
	}
	
	// Permet de tester si les produits (cumulés si même catégorie) des différents apports de la stratégie sont dispo pour une quantité spécifique (dose * surface d'application)
	bool isMesProduitsDisponibles(parcelle parc) {
		// Collecte des quantités nécéssaires par produit pour l'alternative en cours
		map<string, float> mapProduitDosesCumulees;
		loop apport over: mesApports {
			string produit_courant <- apport.nom_produit;
			float dose_courante <- apport.doseParHectare; // La conversion en dose réelle est réalisée plus loin
			if (mapProduitDosesCumulees[produit_courant] = nil) { // Si le produit n'existe pas dans la map, on le rajoute avec sa dose
				mapProduitDosesCumulees <+ produit_courant::dose_courante;
			} else {
				mapProduitDosesCumulees[produit_courant] <- mapProduitDosesCumulees[produit_courant] + dose_courante;
			}
		}
		
		// Test de la quantité disponible pour chaque couple produit-dose
		map<string,bool> produitsDispo; // Liste qui contiendra la dispo (T/F) de chaque produit //  TODO Renaud 180624 voir ci-dessous
		map<string, bool> disponibiliteDesProduits; // TODO Renaud 180624 COuplage filiere/agricole -> à voir quelle map on garde
		
		loop produit_demande over: mapProduitDosesCumulees.keys {
			string produit_courant <- produit_demande;
			float dose_courante <- mapProduitDosesCumulees[produit_demande];
			bool isDispo;
			float dose_necessaire <- (parc.surface / nombreMeterCarreDansUnHectare) * dose_courante; // Dose demandée en kg
			string type <- (Engrais first_with (each.nomEngrais = produit_courant)).Fertilizer_type;
			
			if(type = "mineral") { // Si c'est du minéral, c'est toujours dispo
				isDispo <- true;
			} else { // Si c'est un PRO, il faut vérifier l'état des stocks
				float dose_dispo;
				// Si gestion des stocks de PRO au niveau territoire
				if (gestionStocksEngrais = 'territoire') {
					dose_dispo <- first(Engrais collect each where (each.nomEngrais = produit_courant)).quantiteDispoKg;
					if (dose_dispo >= dose_necessaire) {
						isDispo <- true;
					} else {
						isDispo <- false;
					}				
				}
				// Si gestion des stocks de PRO au niveau exploitation Renaud 060225
				else if (gestionStocksEngrais = 'exploitation') {
					Engrais engrais_demande <- first(Engrais collect each where (each.nomEngrais = produit_courant));
					exploitation exploitation_courante <- parc.ilot_app.agriculteurAssocie.sonExploitation;	
					dose_dispo <- exploitation_courante.stocks_engrais_exploit[engrais_demande];
					float part_PRO_dispo <-  dose_dispo / dose_necessaire;
					
					// Est-ce qu'il y a assez de PRO dans le stock ? Le prélèvement "souple" est géré dans l'action prelevementProduits
					if (part_PRO_dispo > seuil_acceptation_pro) { // Si stock dispo supérieur à 10 % de la dose nécessaire
						isDispo <- true;
					} else {
						isDispo <- false;
					}
					
//					write exploitation_courante.id + " -- engrais demandé = " + dose_necessaire + " t de '" + engrais_demande.nomEngrais + "' -- dose dispo = " + dose_dispo;
				}
			}
			produitsDispo <+ produit_courant::isDispo;
		}


		
//		// L'alternative peut-elle être réalisée ?  171024 Renaud ne marche pas car disponibiliteDesProduits jamais utilisé
//		if !(disponibiliteDesProduits contains false) {
//			write "alternative ok";
//			return true;
//		} else {
//			write "alternative PAS ok";
//			return false;
//		}
// TODO Renaud 180624 couplage filiere/agricole -> il faut essayer de comprendre pourquoi la version ci-dessous (filiere) est différente de la version actuelle (ci-dessus)	
		// Si tous les produits sont dispo on renvoie true. Si tous les produits ne sont pas dispo, on renvoie false.
		if (produitsDispo all_match (each)) {
//			write "Sélection de la stratégie -> test de " + nom_alternative + " ok";
			return true; // L'alternative peut être réalisée
		} else {
//			write "Sélection de la stratégie -> test de " + nom_alternative + " pas ok";
//			write 'alternative non réalisable';
			return false;
		}
		
	}
	
	// Prélèvement de produits dans le stock général du territoire
	action prelevementProduits(parcelleAqYieldNC parcelle_concernee) {
		loop apport over: mesApports {
			string produit_courant <- apport.nom_produit;
			float dose_necessaire <- apport.doseParHectare * (parcelle_concernee.surface / nombreMeterCarreDansUnHectare);	
			string type <-  (Engrais first_with (each.nomEngrais = produit_courant)).Fertilizer_type;
			//write "-ITKFERTi- Prélèvement - produit courant = " + produit_courant + " ---- Dose = " + dose_necessaire + " ---- surface = " + parcelle_concernee.surface / nombreMeterCarreDansUnHectare;
			if (type != "mineral") {
				Engrais engrais_concerne <- first(Engrais collect each where (each.nomEngrais = produit_courant));
				
				// Si gestion des stocks de PRO au niveau territoire
				if (gestionStocksEngrais = 'territoire') {
					engrais_concerne.quantiteDispoKg <- engrais_concerne.quantiteDispoKg - dose_necessaire;
				}
				// Si gestion des stocks de PRO au niveau exploitation
					// Intégration d'une forme de souplesse des agri concernant la gestion de leurs stocks de PRO
					// - Si il reste entre 100 et 110 % de l'apport en cours dans le stocks, alors on prend ce qu'il reste et on épend un peu plus que la dose prévue
					// - Si il le stock qui reste représente moins de 50 % de ce qui est demandé pour l'apport, alors on prend et complète par du minéral
					// - Si il le stock qui reste représente entre 50 et 100 % de ce qui est demandé pour l'apport, alors on prend et complète complète pas
				else if (gestionStocksEngrais = 'exploitation') {
					exploitation exploitation_concernee <- parcelle_concernee.ilot_app.agriculteurAssocie.sonExploitation;
					float dose_dispo <- exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
					float part_PRO_dispo <-  dose_dispo / dose_necessaire;
					float dose_prelevee;
					
					if (part_PRO_dispo >= 1.1) {
						dose_prelevee <- dose_necessaire;
					} else if (part_PRO_dispo >= 1 and part_PRO_dispo < 1.1) {
						dose_prelevee <- exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
					} else if (part_PRO_dispo >= seuil_acceptation_pro and part_PRO_dispo < 1) {
						dose_prelevee <- exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
					}
					
					exploitation_concernee.stocks_engrais_exploit[engrais_concerne] <- exploitation_concernee.stocks_engrais_exploit[engrais_concerne] - dose_prelevee;
					parcelle_concernee.engrais_reserves_parcelle <+ engrais_concerne::dose_prelevee / (parcelle_concernee.surface / nombreMeterCarreDansUnHectare);
					//parcelle_concernee.quantites_reservees_parcelle <+ dose_prelevee;
//					write " -- engrais demandé = " + engrais_concerne.nomEngrais + " -- dose souhaitée = " + dose_necessaire + " -- dose prélevée = " + dose_prelevee + " -- nvlle dose dispo = " + exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
//					write exploitation_concernee.id + " -- engrais demandé = " + engrais_concerne.nomEngrais + " -- nvlle dose dispo dans exploit = " + exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
				}
				
				// Mise en mémoire du N min apporté par le PRO (pour optimisation corpen)
				if (adaptationFertilisation = 'corpen' and parcelle_concernee.getITKAnnee().optimisation_corpen) {
					parcelle_concernee.Nmin_apports_pro <- parcelle_concernee.Nmin_apports_pro + (apport.doseParHectare * 1000 * engrais_concerne.Nmin / 100);
//					write "CORPEN - Nmin contenu dans " + engrais_concerne.nomEngrais + " --> " + (apport.doseParHectare * 1000 * engrais_concerne.Nmin / 100) + "(pour une dose de " + apport.doseParHectare + " t/ha)";
				}
			} else {
				if (adaptationFertilisation = 'corpen' and parcelle_concernee.getITKAnnee().optimisation_corpen) {
					// Calcul de la quantité de N totale apportée pour les engrais minéraux
					parcelle_concernee.Nmin_apports_min <- parcelle_concernee.Nmin_apports_min + apport.doseParHectare;
//					write "CORPEN - Nmin de l'apport --> " + apport.doseParHectare;
				}
			}
		}
		
		// Calcul de l'abbatement CORPEN des engrais minéraux tenant compte du N minéral apporté par les PRO et du Nmin SOM
		// Renaud 260725 En l'état les stocks d'engrais minéraux ne sont pas limitant. Le prélèvement dans les stocks d'engrais miénraux devrait se faire après abattement corpen si c'est le cas.
		if (adaptationFertilisation = 'corpen' and parcelle_concernee.getITKAnnee().optimisation_corpen) {
			
			
			float total_apports_Nmin <- parcelle_concernee.Nmin_apports_pro + parcelle_concernee.Nmin_apports_min; // Total du N minéral apporté en org et en min
			parcelle_concernee.N_a_apporter_corrige_rdmtObs_NminSOM <- parcelle_concernee.ilot_app.agriculteurAssocie.N_a_apporter_corrige_NminSOM(parcelle_concernee); // Besoins N corrigés en fonction des rendements et quantités Nmin observés
			parcelle_concernee.coef_abattement_corpen <- parcelle_concernee.N_a_apporter_corrige_rdmtObs_NminSOM / total_apports_Nmin;
			if parcelle_concernee.N_a_apporter_corrige_rdmtObs_NminSOM = -888.888 {parcelle_concernee.coef_abattement_corpen <- 1.0;}
//			write "total N minéral prévu dans l'ITK = " + total_apports_Nmin;
//			write "N à apporter corrigé (rdmt et NminSOM) = " + parcelle_concernee.N_a_apporter_corrige_rdmtObs_NminSOM;
//			write "Coefficient d'abattement = " + parcelle_concernee.coef_abattement_corpen;
//			write "---------------";
		}
	}
	
	// Réallocation des PRO non utilisés aux stocks du territoire (modifié pour adaptation de la ferti)
	action reallocationProduit(parcelleAqYieldNC parcelle_concernee, strategieFertiApport apport_concerne, float dose_reallouee) {

			float quantite_produit <- dose_reallouee * (parcelle_concernee.surface / nombreMeterCarreDansUnHectare);
			string produit_courant <- apport_concerne.nom_produit;
			string type <-  (Engrais first_with (each.nomEngrais = produit_courant)).Fertilizer_type;
	//		if (type != "mineral") {
			Engrais engrais_concerne <- first(Engrais collect each where (each.nomEngrais = produit_courant));
			
			// Si gestion des stocks de PRO au niveau territoire
			if (gestionStocksEngrais = 'territoire') {
				engrais_concerne.quantiteDispoKg <- engrais_concerne.quantiteDispoKg + quantite_produit;
			}
			// Si gestion des stocks de PRO au niveau exploitation
			else if (gestionStocksEngrais = 'exploitation') {
				quantites_engrais_annuelles >- parcelleAqYieldNC(parcelle_concernee).engrais_reserves_parcelle[engrais_concerne];
				exploitation exploitation_concernee <- parcelle_concernee.ilot_app.agriculteurAssocie.sonExploitation;
				exploitation_concernee.stocks_engrais_exploit[engrais_concerne] <- exploitation_concernee.stocks_engrais_exploit[engrais_concerne] + quantite_produit;
//				write exploitation_concernee.id + "parcelle = " + parcelleAqYieldNC(parcelle_concernee).idParcelle + " -- engrais restitué = " + engrais_concerne.nomEngrais + " -- nvlle dose dispo dans exploit = " + exploitation_concernee.stocks_engrais_exploit[engrais_concerne];
			}
				//write "Réallocation de " + engrais_concerne.nomEngrais + " ---> nouveau stock = " + engrais_concerne.quantiteDispoKg;
	//		}

	}
	
	// Gestion des apports Renaud 24/03/2020
	action getprochainApport (parcelleAqYieldNC parcelleCourante) { // Récupère la prochaine OT seulement si la date courante tombe dans la fenêtre temporelle de l'OT et que celle-ci n'a jamais été réalisée sur la parcelle
		// Les OT qui tombent dans les bonnes dates et qui n'ont pas éncore été effectuées (qui n'apparaissent pas dans la liste correspondante de la parcelle) sont récupérées
		list<strategieFertiApport> apports_non_realises <- self.mesApports where (!(parcelleCourante.apportsEffectues contains each) and !(parcelleCourante.apportsAnnules contains each)); // Toutes les OT du type en cours non réalisées et non annulés
		
		// Classement des opérations pour sélectionner l'opération non réalisée la plus proche dans le temps
		list<strategieFertiApport> apports_dates_debut_sup <- apports_non_realises where ((each.mapFenetresTemporellesDebut[0] > dateCour.nbJoursEcoulesDansAnnee)
																						or (each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee and last(each.mapFenetresTemporellesFin) >= dateCour.nbJoursEcoulesDansAnnee)
																						); // Récupération des OT non réalisées dont la date de début est supérieure au jour courant et celles pour lesquelles le jour courant tombe dans la fenêtre temporelle
																						
//		write "-----";
//		write "Prochain apport = ";
//		write "apports_non_realises = " + apports_non_realises;
//		write "apports_dates_debut_sup = " +  apports_non_realises where ((each.mapFenetresTemporellesDebut[0] > dateCour.nbJoursEcoulesDansAnnee)
//																						or (each.mapFenetresTemporellesDebut[0] <= dateCour.nbJoursEcoulesDansAnnee and last(each.mapFenetresTemporellesFin) >= dateCour.nbJoursEcoulesDansAnnee)
//																						); // Récupération des OT non réalisées dont la date de début est supérieure au jour courant et celles pour lesquelles le jour courant tombe dans la fenêtre temporelle
//																						
//		write "-----";
		
		strategieFertiApport prochainApport <- nil;
		if (length(apports_dates_debut_sup) > 0) { // Si il y a des OT non réalisée dont la date de début est supérieure à la date courante, on prend la plus petite date parmi les OT en question
			apports_dates_debut_sup <- apports_dates_debut_sup sort_by each.mapFenetresTemporellesDebut[0];
			prochainApport <- first(apports_dates_debut_sup);
		} else { // Si il n'y a aucune OT dont la date de fin est inférieure à la date courante, on prend la plus petite date parmi l'ensemble des OT
			apports_non_realises <- apports_non_realises sort_by each.mapFenetresTemporellesDebut[0]; // Récupère la date de début de la première sous-période
			prochainApport <- first(apports_non_realises);
		}
		parcelleCourante.prochainApport <- prochainApport;

		// RM 080221 réallocation d'engrais aux stocks territoriaux si l'apport courant a changé et qu'il figure toujours dans la liste des apports à réaliser
		if (apports_non_realises contains parcelleCourante.apport_courant and prochainApport != parcelleCourante.apport_courant) {
//			write parcelleCourante.idParcelle + " apport non réalisé figurant toujours dans la liste " + nom_alternative;
			do  reallocationProduit(parcelleCourante, parcelleCourante.apport_courant, parcelleCourante.apport_courant.doseParHectare);
			parcelleCourante.apport_courant <- nil;
		}
		
		//write "-ITKFERTi- Prochain Apport --> " + prochainApport;
		
		return prochainApport;
	}
	
}	

