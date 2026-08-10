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
 *  Exploitations
 *  Author: Renaud Misslin
 *  Description: Un lot d'animaux
 */

model lotAnimaux

import "atelierElevage.gaml"
import "../../Engrais/Engrais.gaml"



global{
	map<string,string> imageLotAnimaux <- map(["pre"::'../../images/vache1.png', "batiment"::'../../images/etable1.png']) ; 
//	map mapExploitations <- map([]); // utilisees a des fins d'optimisation de l'initialisation
	string fichierLotsAnimaux <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/lotsAnimaux.csv';
//	string fichierDepartement <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/communes/departement.shp';
//	string fichierCaracExploit <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/exploitations.csv';
//
//	map<exploitation, float> surfacePP <- map<exploitation, float>([]) ; //map contenant par exploitation
//	list<departement> listDepartements <- []; 
//	list<string> listIDDepartements <- []; 
//	list<string> listTypeExploit;

	// Création des ateliers d'élevage et des lots d'animaux à partir du fichier lotAnimaux.csv
	action constructionLotAnimaux {
		// Lecture du fichier décrivant les lots d'animaux
		if !file_exists(fichierLotsAnimaux)	{do raiseError("fichier inexistant: " + fichierLotsAnimaux);}
		//if !is_csv(fichierLotsAnimaux)	{do raiseError("le fichier " + fichierLotsAnimaux + " n'est pas un fichier csv");}	
		
		if file_exists(fichierLotsAnimaux)	{
			matrix matrixLotsAnimaux <- matrix(csv_file(fichierLotsAnimaux,";",true));
			int nbLignes <- length(matrixLotsAnimaux column_at 0);
			list<string> exploitElevageDejaCrees;
			list<string> liste_exploit <- exploitation collect each.id; // TODO Renaud 030425  -> Vérifier si c'est bon (rappatrié d'une ancienne version de maelia)
			
			//write "Nombre de lignes lotsAnimaux.csv = " + nbLignes;
			loop i from: 0 to: (nbLignes -1){ //boucle sur les exploitations
				// Lecture de l'entrée courante du fichier lotsAnimaux
				string current_id_exploit <- matrixLotsAnimaux[0,i];
				string current_id_lot <- matrixLotsAnimaux[1,i];
				string current_lot_typeAnimaux <- matrixLotsAnimaux[2,i];
				string current_lot_nbUGB <- matrixLotsAnimaux[3,i];
				string current_lot_dureePaturage <- matrixLotsAnimaux[4,i];
				string current_lot_cstAlim <- matrixLotsAnimaux[5,i];
				string current_lot_stockFoin <- matrixLotsAnimaux[6,i];
				string current_lot_type_feces <- matrixLotsAnimaux[7,i];
				string current_lot_part_restitution_batiment <- matrixLotsAnimaux[8,i];
				string current_lot_eloignement_min <- matrixLotsAnimaux[9,i];
				string current_lot_eloignement_max <- matrixLotsAnimaux[10,i];
				
				if (liste_exploit contains current_id_exploit) {
						//				write "HERBSIM Renaud - idExploit = " + current_id_exploit + " | id_lot = " + current_id_lot + " | nbUGM = " + current_lot_nbUGB + " | dureePaturage = " + current_lot_dureePaturage
	//					 + " | cst_alim = " + current_lot_cstAlim
	//					 + " | stockFoin = " + current_lot_stockFoin;
					// Création de l'atelier d'élevage si il n'existe pas (il ne peut y en avoir qu'un seul par exploitation pour l'instant

					if !(exploitElevageDejaCrees contains current_id_exploit) {
						agriculteur monAgri <- first(listeAgriculteurs collect each where (each.sonExploitation.id = current_id_exploit));
						create atelierElevage {
							set monExploitation value: mapExploitations[current_id_exploit];
							set monAgriculteur value: monAgri;
							set location value: monExploitation.monBatiment.location;
						}
						exploitElevageDejaCrees <+ current_id_exploit;
					}
					
					// Création du lot d'animaux
					atelierElevage atelier_courant <- first(atelierElevage collect each where (each.monExploitation.id = current_id_exploit));
					
					create lotAnimaux returns: lotCourant {
						set idLotAnimaux value: current_id_lot;
						set monAtelierElevage value: atelier_courant;
						set typeAnimaux value: current_lot_typeAnimaux;
						set nb_UGB value: float(current_lot_nbUGB);
						set duree_paturage value: int(current_lot_dureePaturage);
						set cst_alim value: float(current_lot_cstAlim);
						set location value: monAtelierElevage.location;
						set type_feces value: current_lot_type_feces;
						set part_restitution_batiment value: float(current_lot_part_restitution_batiment);
						set eloignement_min value: float(current_lot_eloignement_min);
						set eloignement_max value: float(current_lot_eloignement_max);
					}
					 ask lotCourant {
					 	location <- atelier_courant.location;
					 }
					// MAJ du stock de foin de l'atelier à initialisation
					atelier_courant.monExploitation.stockHerbeFauchee <- atelier_courant.monExploitation.stockHerbeFauchee + int(current_lot_stockFoin);
					atelier_courant.mesLotsAnimaux <<+ lotCourant;
					//write "HERBSIM Renaud - lot créé = " + lotCourant;
				}

			}
		}				
		
	}

}

	
species lotAnimaux {
	// ID
	string idLotAnimaux;
	atelierElevage monAtelierElevage;
	
	// Caractéristiques générales du lot (définies en constantes pour plus de 
	string typeAnimaux;
	float nb_UGB; // Unité gros bétail (chargement animal)
	int duree_paturage;
	float cst_alim; // [kgMS de fourrage]
	string type_feces; // Type de PRO (engrais.csv) associé au lot d'animaux
	float part_restitution_batiment; // Part de feces et pissat restituée au bâtiment (entre 0 et 1)
	
	// Variables de gestion du lot
	parcelle parcelleCourante;
	bool auBatiment <- true; // Est-ce que le lot est au batiment actuellement ?
	float besoinJourCourant; // Besoin herbe aujourd'hui (kg/MS)
	int tempsPatureParcelleCourante <- 0;
	float coefHerbeAccessibleITKCourant <- 0.0;	
	float herbeConsoParcelleCourante <- 0.0;
	strategiePatureMultiples maStrategiePatureCourante;
	float eloignement_min;
	float eloignement_max;
	
	// Affichage
	string imgCourante <- imageLotAnimaux["batiment"];
	
	/*
	 * *****************************************************************************************
	 * Actions / fonctions
	 */

	// Scheduler journalier
	action comportementJournalier {
//		write "+++++++++++++++++++++";
//		write "HERBSIM Renaud - comportement journalier du lot " + self;
		
		// 1. Calcul des besoins du jour [tMS]
		besoinJourCourant <- calculBesoinsAlimentation();
//		write "HERBSIM Renaud - besoin j du lot = " + besoinJourCourant + " --- parcelleCourante " + parcelleCourante + " --- tempsPatureParcelleCourante " + tempsPatureParcelleCourante + " --- auBatiment " + auBatiment;
		
		// 2. Est-ce que lot doit changer de parcelle ou sortir du bâtiment ?
		if (parcelleCourante != nil) { // Est-ce que le parcelle courant permet de satisfaire 
			do testSortieParcelle(besoinJourCourant);
		} else if (auBatiment) {
			do choixParcelle(besoinJourCourant);
		} else { // Pas possible normalement, je garde le if comme ça pour les tests mais il faudra le changer 140923
//			write "Il y a un lot d'animaux qui se balade";
		}
		
		// 3. Consommation de l'herbe ou fourrage
		if (auBatiment and parcelleCourante = nil) {
			do consommationFoin(besoinJourCourant);
//			write "consommation fourrage et paille";
		} else if (!auBatiment and parcelleCourante != nil) {
			// Est-ce que la parcelle a assez d'herbe --> pour l'instant ca ne devrait pas arriver
			
			// Si pas assez d'herbe on affourage
			
			float herbe_disponibleTotale <- cultureHerbSimNC(parcelleCourante.cultureParcelle.monModelDeCulture).getBiomasseAboveGround() * maStrategiePatureCourante.coefHerbeAccessible * (parcelleCourante.surface / 10000);
//			write "herbe_disponible = " + herbe_disponibleTotale;
//			write "besoins = " + besoinJourCourant;
			
			// Enregistrement de la conso journalière
			if (herbe_disponibleTotale > besoinJourCourant) {
				
				herbeConsoParcelleCourante <- herbeConsoParcelleCourante + besoinJourCourant;
				tempsPatureParcelleCourante <- tempsPatureParcelleCourante + 1;
//				write "consommation d'herbe";
			} else {
//				write "Problème --> conso d'herbe alors que pas assez de biomasse accessible";
			}
		}
		
	}
	
	// Calcul des besoins journalier du lot [kgMS]
	float calculBesoinsAlimentation {
		float besoinsJour <- nb_UGB * cst_alim;
		return besoinsJour;
	}
	
	// Consommation de l'herbe dans le patûrage
	action consommationHerbe(float herbeTotaleConsommee) {
		float herbeTotaleConsommeeParHa <- herbeTotaleConsommee / (parcelleCourante.surface / 10000);
		
		ask cultureHerbSim(parcelleCourante.cultureParcelle.monModelDeCulture) {
			do updateHerbePature(herbeTotaleConsommeeParHa);
		}
	}

	// Consommation de foin dispo dans le stock de l'atelier d'élevage
	action consommationFoin(float besoinsJourFoin) {
		monAtelierElevage.monExploitation.stockHerbeFauchee <- monAtelierElevage.monExploitation.stockHerbeFauchee - besoinsJourFoin * 1000;
	}
	
	// Sélection d'une nouvelle parcelle si besoin : le parcelle est sélectionné dans une liste de parcelles paturables
	action choixParcelle(float besoinsJourHerbe) {
		
		// 1. Si le lot est déjà sur une parcelle, on le fait sortir de la parcelle et on essaye de lui en trouver une autre
		if (parcelleCourante != nil and !auBatiment) {
//			write "HERBSIM Renaud - sortie de parcelle, nouvelle parcelle recherchée";
			// Est-ce que la parcelle courante correspond encore aux critères de pature ?			
			parcelleCourante.tpsReposParcelle <- maStrategiePatureCourante.tempsReposParcelle;			
			parcelleCourante.lotAnimauxCourant <- nil;  // On sort de la parcelle courante
			parcelleCourante <- nil; // On sort de la parcelle courante
			maStrategiePatureCourante <- nil;
		}
		
		// 2. Si pas de parcelle sélectionné pour l'instant ou si les animaux sont au bâtiment en ce moment
		if (parcelleCourante = nil or auBatiment) {
//			write "HERBSIM Renaud - recherche de parcelle (pas de parcelle ou au bâtiment)";
			parcelleCourante <- first(monAtelierElevage.SelectionParcellesPaturables(self));
			if (parcelleCourante != nil) {
//				write "HERBSIM Renaud - parcelle trouvée --> " + parcelleCourante;
				parcelleCourante.lotAnimauxCourant <- self;
				maStrategiePatureCourante <- getMaStrategiePatureMultiples();
				auBatiment <- false;
				
				coefHerbeAccessibleITKCourant <- maStrategiePatureCourante.coefHerbeAccessible;
				do changementLocalisation;
			}
		}
		
		// 3. Si toujours pas de parcelle, on rentre au bâtiment
		if (parcelleCourante = nil) {
			auBatiment <- true;
			coefHerbeAccessibleITKCourant <- 0.0;
			do changementLocalisation;
		}
	}
	
	// Sortie du parcelle courant si les contraintes de patûrage le demandent
	action testSortieParcelle(float besoinsJourHerbe) {
//		write "HERBSIM Renaud - test sortie parcelle";

		// 1. Est-ce que les contraintes de paturage obligent le lot à sortir de la parcelle ?
		bool lotASortir <- true;
//		write parcelleCourante.idParcelle + " - culture itk courant -> " + parcelleCourante.getITKAnnee().especeCultiveeITK.idEspeceCultivee;
		ask maStrategiePatureCourante {
			lotASortir <- isSortieObligatoire(myself.parcelleCourante,  myself.parcelleCourante.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite, myself.herbeConsoParcelleCourante, besoinsJourHerbe); // Test tps de pature, hauteur herbe et humidité du sol
		}
//		write "HERBSIM Renaud - Lot doit sortir : " +  lotASortir;
		
		// 2. On sort le lot du parcelle si besoin
		if (lotASortir) {
			do sortieDeParcelle(besoinsJourHerbe);
		}
		
	}
	
	action changementLocalisation {
//		write "changementLocalisation";
		if (auBatiment) {
			location <- monAtelierElevage.location;
			imgCourante <- imageLotAnimaux["batiment"];
		} else {
			location <- parcelleCourante.location;
			imgCourante <- imageLotAnimaux["pre"];
		}
	}
	
	// Calcule les retours au sol (kg/ha) d'azote et de carbone liés au pâturage
	map<string, float> retour_sol_paturage (
	    float biomasse_ingeree_kgMS_ha, // herbe ingérée (kg MS/ha) pendant la pature
		float C_fraction_ms, // kg C / kg MS	    
	    float CN_plante, // CN des feuilles de l'herbe
	    float p_feces // part des fèces déposées hors parcelle (déf. 0.2)
	    
	) {
		// Constantes issues de l'article
	    float alpha_gN_par_kgMS <- 7.53; // g N / kg MS (Eq. A.1)
	    float beta_max_CN_feces <- 32.201; // (Eq. A.3)
	    float gamma_pente <- 505.29; // (Eq. A.3)
	    float delta_gN_par_kgMS <- 16.25; // g N / kg MS (Eq. A.4)
		
		float N_fraction_ms <- C_fraction_ms / CN_plante; // kg N / kg MS
		
	    map<string, float> result <- [];
	
	    // --- Fèces (Eq. A.1 et A.3) ---
	    float N_feces_kg_ha <- (alpha_gN_par_kgMS * (1.0 - p_feces) * biomasse_ingeree_kgMS_ha) / 1000.0;
	    float CN_ratio_feces <- beta_max_CN_feces - (gamma_pente * N_fraction_ms);
	    if (CN_ratio_feces < 0.0) { CN_ratio_feces <- 0.0; } // garde-fou
	    float C_feces_kg_ha <- CN_ratio_feces * N_feces_kg_ha;
	
	    // --- Urine (Eq. A.4 et A.5) ---
	    // excédent d’azote ingéré par kg de matière sèche
	    float excedentN_g_par_kgMS <- (1000.0 * N_fraction_ms) - delta_gN_par_kgMS;
	
	    float N_urine_kg_ha <- 0.0;
	    if (N_fraction_ms > (delta_gN_par_kgMS / 1000.0) and excedentN_g_par_kgMS > 0.0) {
	        N_urine_kg_ha <- (excedentN_g_par_kgMS * (1.0 - p_feces) * biomasse_ingeree_kgMS_ha) / 1000.0;
	    }
	
	    // Urine considérée minérale -> pas de carbone associé
	    float C_urine_kg_ha <- 0.0;
	
	    // Totaux
	    float N_total_kg_ha <- N_feces_kg_ha + N_urine_kg_ha;
	    float C_total_kg_ha <- C_feces_kg_ha + C_urine_kg_ha;
	    
	    
		// Sortie : map<string, float> avec clés :
		//   "N_feces", "C_feces", "N_urine", "C_urine", "N_total", "C_total" (kg/ha)
//		write "biomasse_ingeree_kgMS_ha = " + biomasse_ingeree_kgMS_ha;
//		write "N_feces_kg_ha = " + N_feces_kg_ha + " -- C_feces_kg_ha = " + C_feces_kg_ha;
//		write "N_urine_kg_ha = " + N_urine_kg_ha + " -- C_urine_kg_ha = " + C_urine_kg_ha;
//		write "N_total_kg_ha = " + N_total_kg_ha + " -- C_total_kg_ha = " + C_total_kg_ha;
		
	    result["N_feces"] <- N_feces_kg_ha;
	    result["C_feces"] <- C_feces_kg_ha;
	    result["N_urine"]  <- N_urine_kg_ha;
	    result["C_urine"]  <- C_urine_kg_ha;
	    result["N_total"]  <- N_total_kg_ha;
	    result["C_total"]  <- C_total_kg_ha;
	
	    return result;
	}
	
	
	// Récupère la stratgie paturage en cours
	strategiePatureMultiples getMaStrategiePatureMultiples {
		list<strategiePatureMultiples> result <- nil;
		
		// Parcours des stratégie multiples pour savoir laquelle est la bonne actuellement
		loop stratMult over: parcelleCourante.getITKAnnee().strategiePatureITK.mesStrategiesMultiples {
			if (stratMult.isFenetreTemporelleOk(parcelleCourante, parcelleCourante.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite)) {
				result <+ stratMult;
			}
		}
		
		// Garde-fous
		if (result = nil) {
			write "Problème paturage : un lot qui devrait avoir une parcelle n'en a pas";
		} else if (length(result) > 1) {
			write "Problème paturage : deux fenêtres paturage se recouvrent, c'est la première qui est choisie";
		}
		
		return first(result);
	}
	
	action sortieDeParcelle (float besoinsJourHerbe) {
//		write "Le lot doit sortir de la parcelle";
		// Enregistrement des données de suivi de paturage
		ask maStrategiePatureCourante {
			do ecrituresSortiesPature(myself.parcelleCourante, myself);
		}
		
		// Consommation effective de l'herbe (besoins journaliers * n jours de paturage)
		do consommationHerbe(herbeConsoParcelleCourante);
		
		if (nomChoixModeleCroissancePrairie = "HerbSimNC") {
			if (herbeConsoParcelleCourante > 0) {
				map<string, float> NC_restitutions <- retour_sol_paturage(herbeConsoParcelleCourante, 0.45, 16.0, part_restitution_batiment);
				float c_feces <- NC_restitutions["C_feces"];
				float n_feces <- NC_restitutions["N_feces"];
				float c_urine <- NC_restitutions["C_urine"];
				float n_urine <- NC_restitutions["N_urine"];
				
				// Calcul de la dose totale de feces
				Engrais produit_feces <- Engrais first_with (each.nomEngrais = type_feces); // Identification du produit associé aux feces
				float dose_totale_feces <- (n_feces * 100 / produit_feces.N) / 1000; // Calcule de la dose totale sur la base de la dose N (résultat en tonnes)
				
				// Calcul de la dose totale d'urine
				Engrais produit_urine <- Engrais first_with (each.nomEngrais = "urine"); // Identification du produit associé aux feces
				float dose_totale_urine <- (n_urine * 100 / produit_urine.N) / 1000; // Calcule de la dose totale sur la base de la dose N (résultat en tonnes)
				
				ask parcelleAqYieldNC(parcelleCourante) {
					do fertilisation (myself.type_feces, dose_totale_feces, 0.0, 0.0, "paturage", c_feces); // nom_produit, dose, doseP, doseK, outil
					do fertilisation ("urine", dose_totale_urine, 0.0, 0.0, "paturage", c_urine); // nom_produit, dose, doseP, doseK, outil
				}	
			}
		}
		
		// Remise à 0 des variable de suivi du paturage
		tempsPatureParcelleCourante <- 0;
		herbeConsoParcelleCourante <- 0.0;
		
		// Tentative de sélection d'une nouvelle parcelle
		do choixParcelle(besoinsJourHerbe);
	}
	
	/*
	 * *****************************************************************************************
	 * Display
	 */
	
	aspect imageAspect{
		draw image_file(imgCourante) size: 800;
	}   	

}

	
