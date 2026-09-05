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
* Name: cultureHerbSimNC
* Author: Nirina Ratsimba
* Date de création: 18/04/2024
* Description: Version de cultureHerbSim prenant en compte l'azote ; espèce temporaire pour les besoins du projet LEGUMETHA
*/


model cultureHerbSimNC

import "../Cultures/cultureHerbSim.gaml"
import "../Parcelles/parcelleAqYieldNC.gaml"
import "../Parcelles/parcelle.gaml"

global {}

species cultureHerbSimNC parent: cultureHerbSim {
	float demandeN_max_couvertHS_j <- 0.0;
	//float demandeN_min_couvertHS_j <- 0.0; // Pour suivi du stress azoté à l'échelle du couvert (calcul de meanINN10j)
	float QN_acquis_sans_mic <- 0.0;
	float QN_acquis;
	float QN_fixe_j <- 0.0;
	float QN_fixe_cumul_couvertHS <- 0.0;
	float QN_cumul_senescent <- 0.0;
	float QC_cumul_senescent <- 0.0;
	//float BM_cumul_senescent <- 0.0;

	float QN_senescent_j <- 0.0; // SUIVI pour détection erreur // TODO a supprimer
	float pourcentage_N_actuel <- 0.0; // SUIVI pour détection erreur 
		
	list<int> dates_incorporation_BM_senescent <- [121,182,244]; // TODO vérifier si fait à l'initialisation (si oui à supprimer de l'init)
	list<int> dates_incorporation_BM_racines <- [244];
	list<float>  INN10j <- [];
	list<float>  INN_periode_culture <- [];
	
	float suivi_offreN <- 0.0; // NR A SUPPRIMER
   	float suivi_QN_acquis <- 0.0; // NR A SUPPRIMER
   	float suivi_demandeN_max_couvertHS_j <- 0.0; //NR A SUPPRIMER
   	float cumul_erreur_qn_pot <- 0.0;
	
	action initialisationCulture { // NR Herbsim 23/04/2024 - Récrit par dessus fonction existante dans cultureHerbsim.gaml, pour créer une espèce alfalfaNC et pas alfalfa
		// 1. init herbsim classique
		anneeCreation <- dateCour.annee;
		//compositionVegetation
		
		
		//fraction <- ??
		//write "culture_app cultureHerbSim = " + culture_app;

		ask especeHerbSim(espece) {
			self.cultureHerbSim_app <- myself;
			do initialisationVegetation();
			put 1.0 at: self in: myself.compositionVegetation ;
		}

		biomass_above_ground <- sum(compositionVegetation.keys collect each.biomass_above_ground_species);

		ProportionAlfalfa <- 0.0; 
		 
	 	// attribution des coefficients par compartiment de la vegetation et calcul
		// dun coefficient pondere par les abondances des compartiments
		CorrectionCoefficient <- 0.0;
		weightedThermalTimeAtFlowering <- 0.0;
	 	loop vege over: compositionVegetation.keys{
	 		weightedThermalTimeAtFlowering <- weightedThermalTimeAtFlowering + vege.ThermalTimeAtFlowering * vege.fraction;
	 		CorrectionCoefficient <- CorrectionCoefficient + vege.YieldCorrectionCoefficient * vege.fraction;
	 	}
		// la hauteur d'herbe non paturable est fixee a 3 cm, on recupere la biomasse
		// correspondante qui varie en fonction du temps et du type de prairie ==>
		// calcul de la hauteur si la biomasse est superieure a la biomasse correspondant a 3 cm
		
		indiceSatifactionHydrique <- 1.0;
		
		// Calcul de la profondeur maximale pouvant être atteinte par les racine pour la culture courante
		parcelleAqYield(parcelle_app).RUr_max <- RUr_max_culture_courante(); // Renaud 30052023
		
		// Si prairie permanente alors les racines sont tout de suite à leur max (selon espèce et profondeur du profil)
		if (parcelleAqYield(parcelle_app).isPrairiePermanente) {
			float rapport_RUm_RUrmax <- max([1.0, parcelleAqYield(parcelle_app).RUr_max / parcelleAqYield(parcelle_app).RUm]);
			parcelleAqYield(parcelle_app).RUr <- max([parcelleAqYield(parcelle_app).RUr_max, parcelleAqYield(parcelle_app).RUm]);			
			parcelleAqYield(parcelle_app).RUrPrec <- parcelleAqYield(parcelle_app).RUr;
			parcelleAqYield(parcelle_app).Hr <- parcelleAqYield(parcelle_app).Hm * rapport_RUm_RUrmax;
		}
			
		// 2. init herbsim NC 
	 	// attribution des coefficients par compartiment de la vegetation et calcul
		// dun coefficient pondere par les abondances des compartiments
		CorrectionCoefficient <- 0.0;
		weightedThermalTimeAtFlowering <- 0.0;
	 	loop vege over: compositionVegetation.keys{
	 		weightedThermalTimeAtFlowering <- weightedThermalTimeAtFlowering + vege.ThermalTimeAtFlowering*vege.fraction;
	 		CorrectionCoefficient <-CorrectionCoefficient + vege.YieldCorrectionCoefficient*vege.fraction;
	 	
	 		QN_acquis_cumul <- QN_acquis_cumul + vege.QN_acquis_cumul_especeHS;
	 	}
		// la hauteur d'herbe non paturable est fixee a 3 cm, on recupere la biomasse
		// correspondante qui varie en fonction du temps et du type de prairie ==>
		// calcul de la hauteur si la biomasse est superieure a la biomasse correspondant a 3 cm
		

	}
	
	
	float getTranspirationR{ // NR Herbsim 24/04/2024 - Redéfini d'après cultureAqYield
		return transpirationMax * indiceSatifactionHydrique;
	}
	
	// Calcul de la demande réelle en azote de la plante 
		//(calculé en parallèle de la demande des micro-organismes, avant arbitrage entre les 2)
	float demande_plante_w {
		// essai blocage
		if(isCultureLevee){ // si la culture a bien levé
			demandeN_max_couvertHS_j <- 0.0;// Remise à 0 car la demande est journalière
			loop vege over: compositionVegetation.keys{ // Cumul de la demande en azote pour l'ensemble du couvert
				ask vege {do updateDemandeAzote();} // Calculde la demande azote de chaque espèce prairiale
				demandeN_max_couvertHS_j <- demandeN_max_couvertHS_j + vege.demandeAzoteMax; // demandeN_max_couvertHS_j <- demandeN_max_couvertHS_j + vege.demandeAzoteMax;
			}
			//write "dezjbffer demande en azote du couvert dans demande_plante_w " + demandeN_max_couvertHS_j;
			float offreN <- parcelleAqYieldNC(parcelle_app).QNacq_pot(availN_w_arg: parcelleAqYieldNC(parcelle_app).availN_w);		       
			QN_acquis_sans_mic <- min([demandeN_max_couvertHS_j, offreN]);

			return QNacq_w(profR: parcelleAqYieldNC(parcelle_app).profR, 
				                          profW: parcelleAqYieldNC(parcelle_app).ilot_app.sol.profHum,
				                          QNinitialeJ_w_arg: parcelleAqYieldNC(parcelle_app).availN_w,
				                          QNfinaleJ_r_arg: parcelleAqYieldNC(parcelle_app).QNfinaleJ_r,
				                          QN_acquis_arg: QN_acquis_sans_mic
					);
		}else{ // si la culture n'a pas leve (=-> la demande en azote est nulle
				return 0.0;
		}   
    	}
    
        // 3. Consommation N
    action consommationN { // TODO dans le cas d'une legumineuse : compter la différence N demandé - N reçu et l'inscrire en tant qu'azote fixé. -> statut de legumineuse à préciser dans le fichier espèces prairiales
        if(isCultureLevee){
       	 float offreN <- parcelleAqYieldNC(parcelle_app).QNacq_pot(availN_w_arg: parcelleAqYieldNC(parcelle_app).availN_w_plant);
        float demandeN_min_cumul_couvertHS_nonleg_j <- 0.0; // cumul de la demande minimale en azote, pour tout le couvert, mais uniquement les non légumineuses lecomposant (soumises au stress azote)
        float QNacquis_cumul_couvertHS_nonleg_j <- 0.0; // cumul de l'azote acquis pour tout le couvert, mais uniquement les espèces non légumineuses le composant (soumises au stress azoté)
        QN_acquis <- min([demandeN_max_couvertHS_j, offreN]); // demandeN_j est actualisé dans demande_plante_w()  
      	QN_fixe_j <- 0.0; // Quantité d'azote fixée journalière pour l'ensemble du couvert (pour sorties_azote)
        
        list<float> list_INN_especes <- [];
        loop vege over: compositionVegetation.keys{
        	float offreN_especeHS_j <- offreN * vege.fraction; //vege.QN_acquis_especeHS_j <- QN_acquis * vege.fraction; // quantité d'azote reçue répartie entre les différentes espèces du couvert
			
			// **** Demande de la plante au sol et satisfaction des besoins azotés ****
			
			if vege.isLEG{ // ******** LEGUMINEUSE ********

/* Etapes pour la demande en azote
	* Croissance potentielle en biomasse (dans especeHerbSim.gaml)
	* Demande en N max (dans especeHerbSim.gaml)
	* Confrontation entre l'offre du sol et la demande max de la plante
		* 1 : offre du sol > demande N max 
		* 	=> Limitation de la consommation en N suivant la courbe de dilution max + Fin du processus
		* 2 : offre du sol < demande N max 
		* 	=>  Calcul de la quantité de N minimale pour INN à 1 + confrontation entre l'offre du sol et la demande à INN = 1 de la plante
				 * 2a : si offre du sol > demande N INN 1 => Consommation du N disponible, pas de fixation symbiotique + Fin du processus
				 * 2b : si offre du sol < demande N INN 1 => Consommation du N disponible et dfixation symbiotique pour arriver à INN 1 + Fin du processus
		*/
				 
	// Confrontation entre l'offre du sol et la demande max de la plante //
				
			float pourcN_1 <- vege.paramDilMinA * max(vege.BM_pot,vege.plateau_dilution_n)^(-vege.paramDilMinB); // pourcentage d'azote attendu pour un INN = 1, pour la biomass aér. potentielle (BM actuelle + BiomassGrown)
			pourcentage_N_actuel <- vege.QN_aer / vege.biomass_above_ground_species; // SUIVI A SUPRRIMER
			float QN_INN1 <- pourcN_1 * vege.BM_pot * 10; // quantité d'azote associée à la partie aérienne si croissance potentielle réalisée et si INN = 1
								
			if (offreN_especeHS_j >= vege.demandeAzoteMax) {  // 1 : offre du sol > demande N max 
			
			// Excès d'azote => Limitation de la consommation en N suivant la courbe de dilution max + Fin du processus 
					
		// * Parties aériennes * //			
			vege.QN_aer <- vege.QN_aer_prec + vege.demande_max_aer; // la nouvelle quantité de N dans la plante est la quantité précédente + la demande max
			vege.biomass_above_ground_species <- (vege.BM_pot * 1000) - vege.biomass_senescent_species; // la nouvelle BM est la biomasse potentielle, moins la biomasse sénéscente du jour
			QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf; // calcul de la quantité de N partant dans la biomasse en senescence
			vege.QN_aer <- vege.QN_aer - QN_senescent_j; // calcul de la quantité de N partant dans la biomasse en senescence
			vege.INN_j <- vege.QN_aer / QN_INN1; // MAJ INN
			list_INN_especes << vege.INN_j; // MAJ INN
					
		// * Parties racinaires * // avec une consommation qui varie par rapport à v95_croissance_rac
				vege.QN_rac <- vege.QN_rac + vege.demande_max_rac; // la nouvelle quantité de N dans les racines est la quantité précédente + la demande max
				vege.compart_N_turnover <- vege.compart_N_turnover + vege.demande_turnover; // la nouvelle quantité de N dans le compartiment de turnover est la quantité précédente + la demande max
				vege.BM_rac <- vege.BM_rac_pot;
				vege.compteur_N_jours <- vege.compteur_N_jours + 1;	// [commun?] pas de stress azoté, passage d'un jour-azote complet			
				vege.QN_fixe <- 0.0; 
					
		} else { // 2 : offre du sol < demande N max 
				
		
		// * parties aériennes *
				float demande_INN1_aer <- QN_INN1 - vege.QN_aer_prec; // N nécessaire pour arriver à un INN de 1 (compte tenu de la croissance en BM potentielle)
				float offreN_aer <- offreN_especeHS_j * (vege.demande_max_aer / vege.demandeAzoteMax); // part de l'offre du sol attribuée aux parties aériennes
				float QN_fixe_aer <- 0.0;

		// * parties racinaires *
				// N pour la croissance du système racinaire
				float offreN_rac <- offreN_especeHS_j * (vege.demande_max_rac / vege.demandeAzoteMax); // part de l'offre du sol attribuable aux racines
				vege.QN_rac <- vege.demande_max_rac + vege.QN_rac;
				vege.BM_rac <- vege.BM_rac_pot; // la croissance en biomasse potentielle est réalisée
				vege.compteur_N_jours <- vege.compteur_N_jours + 1;	// [commun?] pas de stress azoté, passage d'un jour-azote complet	
				float QN_fixe_rac <-  max(vege.demande_max_rac - offreN_rac,0.0); // partie de la demande en azote des racines qui a due être fixée symbiotiquement
				
				// N pour le turnover du système racinaire			
				float offreN_turnover <- offreN_especeHS_j * (vege.demande_turnover / vege.demandeAzoteMax);
				vege.compart_N_turnover <- vege.compart_N_turnover + vege.demande_turnover;
				float QN_fixe_turnover <- max(vege.demande_turnover - offreN_turnover,0.0); 
				

	// =>  Calcul de la quantité de N minimale pour INN à 1 + Confrontation entre l'offre du sol et la demande à INN = 1 de la plante
	// => confrontation de l'offre du sol à la demande en N pour maintenir l'INN à 1			
				
			if(offreN_aer < demande_INN1_aer){ // offre sol < demande pour maintenir INN = 1
						//write "OFFRE SOL INF DEMANDE INN 1";

				vege.QN_aer <- QN_INN1; // la quantité de N aérien est celle pour laquelle INN = 1 (compensation par fixation symbiotique)
				// soustraction de la senescence
				vege.biomass_above_ground_species <- (vege.BM_pot * 1000) - vege.biomass_senescent_species; // [commun à tous les cas de figure?] la biomasse aérienne potentielle est réalisée
				// calcul de la compensation par fixation symbiotique
				QN_fixe_aer <- demande_INN1_aer - offreN_aer;
				QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf;
				// mise à jour de la QN aerienne
				vege.QN_aer <- vege.QN_aer - QN_senescent_j;
				// Mise à jour de l'INN
				// Recalcul de QN_INN_1 pour prendre en compte la perte en biomasse et en azote dûe à la sénéscence
					float pourcN_1_senesc <- vege.paramDilMinA * max((vege.biomass_above_ground_species /1000),vege.plateau_dilution_n)^(-vege.paramDilMinB); // pourcentage d'azote attendu pour un INN = 1, pour la biomass aér. potentielle (BM actuelle + BiomassGrown)
					float QN_INN1_senesc <- (pourcN_1_senesc / 100) * vege.biomass_above_ground_species; // quantité d'azote associée à pourcN_1 dans toute la plante
					
					
				// Calcul de l'INN :
					vege.INN_j <-  vege.QN_aer / QN_INN1_senesc;
					list_INN_especes << vege.INN_j;

			} else { // offre sol > à la demande pour INN = 1
					
				vege.QN_aer <- vege.QN_aer_prec + offreN_aer;
				vege.biomass_above_ground_species <- (vege.BM_pot * 1000) - vege.biomass_senescent_species; // [commun à tous les cas de figure?] la biomasse aérienne potentielle est réalisée
				QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf;
					
			// Recalcul de QN_INN_1 pour prendre en compte la perte en biomasse et en azote dûe à la sénéscence
				float pourcN_1_senesc <- vege.paramDilMinA * max((vege.biomass_above_ground_species /1000),vege.plateau_dilution_n)^(-vege.paramDilMinB); // pourcentage d'azote attendu pour un INN = 1, pour la biomass aér. potentielle (BM actuelle + BiomassGrown)
				float QN_INN1_senesc <- (pourcN_1_senesc / 100) * vege.biomass_above_ground_species ; // quantité d'azote associée à pourcN_1 dans toute la plante
					
			// Calcul de l'INN :
				vege.INN_j <-  vege.QN_aer / QN_INN1_senesc;
				list_INN_especes << vege.INN_j;					
				}	
									
				// compensation symbiotique
				vege.QN_fixe <- QN_fixe_aer + QN_fixe_rac + QN_fixe_turnover;
				
				}
			} else {
			// *** NON-LEGUMINEUSE ***
				float pourcN_1 <- vege.paramDilMinA * max(vege.BM_pot,vege.plateau_dilution_n)^(-vege.paramDilMinB); // pourcentage d'azote attendu pour un INN = 1, pour la biomass aér. potentielle (BM actuelle + BiomassGrown)
				float QN_INN1 <- pourcN_1 * vege.BM_pot * 10; // quantité d'azote associée à pourcN_1 dans toute la plante
				

				if (offreN_especeHS_j >= vege.demandeAzoteMax) {  // ** si l'offre du sol excède la demande **

					// * parties aériennes *
					vege.QN_aer <- vege.QN_aer_prec + vege.demande_max_aer;
					vege.biomass_above_ground_species <- (vege.BM_pot * 1000) - vege.biomass_senescent_species;
					QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf;
					
					vege.QN_aer <- vege.QN_aer - QN_senescent_j;
					vege.INN_j <- vege.QN_aer / QN_INN1;
					list_INN_especes << vege.INN_j;

					
			// * parties racinaires * // absorption d'N par les racines fonction de v95
					vege.QN_rac <- vege.QN_rac + vege.demande_max_rac;
					vege.compart_N_turnover <- vege.compart_N_turnover + vege.demande_turnover;
					vege.BM_rac <- vege.BM_rac_pot;
					//QN_acquis <- QN_acquis + vege.demandeAzoteMax; // le N acquis par la plante est le maximum possible (pas l'offre totale) -> cumul pour toutes les espèces du couvert
					vege.compteur_N_jours <- vege.compteur_N_jours + 1;
					
				} else { 
				// ** si l'offre est inférieure à la demande **
				
				float QN_INN_lim <- QN_INN1 * vege.INN_lim; // quantité d'azote totale dans la partie aérienne, si INN = 0.3
				float pourcN_lim <- pourcN_1 * vege.INN_lim; // teneur en azote pour un INN de 0.3, à la biomasse du jour j

				// *parties racinaires*
				// les besoins des racines sont satisfaits en priorité, puis la croissance, puis le turnover (ou juste le turnover en fonction de v95)
				float offreN_rac <- min(offreN_especeHS_j,vege.demande_max_rac);// les racines prennent toute leur demande, ou au moins ce qui est disponible
				vege.QN_rac <- offreN_rac + vege.QN_rac;// TODO mettre à jour la quantité d'azote dans la partie racinaire
				
				if (vege.demande_max_rac > 0.0){ // demande_max_rac peut-être de zéro si les racines ne sont plus en phase de croissance (v95 atteinte)
					vege.BM_rac <- (vege.BM_rac_pot - vege.BM_rac_prec) * (offreN_rac/vege.demande_max_rac) + vege.BM_rac_prec; // MAJ de la biomasse racinaire -> croissance potentielle en BM du jour, modulée par la ratio de la demande réellement satisfaite
					vege.compteur_N_jours <- vege.compteur_N_jours + (offreN_rac / vege.demande_max_rac);// MAJ du nombre de jours de croissance
				}
			
				
				float offreN_apres_rac <- offreN_especeHS_j - offreN_rac; // N restant après consommation par les racines
				float offreN_turnover <- min(offreN_apres_rac, vege.demande_turnover); 
				vege.compart_N_turnover <- vege.compart_N_turnover + offreN_turnover;
				float offreN_apres_turnover <- offreN_apres_rac - offreN_turnover; // N restant après satisfaction croissance et turnover
				
				// * parties aériennes *				
					float QN_pot <- vege.QN_aer_prec + offreN_apres_rac; // La quantité d'azote potentiellement disponible pour la partie aérienne dépend de ce qu'il reste après consommation par les racines et le turnover
				
				// => confrontation à l'offre du sol
				if(QN_pot < QN_INN_lim) {
					// * Si l'offre est inférieure à ce qu'il est nécessaire d'avoir pour un INN d'au moins 0.3	
					float BM_lim <- QN_pot / pourcN_lim;
					vege.biomass_above_ground_species <- (BM_lim * 100) - vege.biomass_senescent_species; // la biomasse devient la biomasse equivalente a un INN de 0,3
					vege.QN_aer <- offreN_apres_turnover + vege.QN_aer_prec;
					QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf;
					vege.QN_aer <- vege.QN_aer - QN_senescent_j;
					vege.INN_j <- 0.3;
					list_INN_especes << vege.INN_j;

					// pas de rhizo déposition dans ce cas , vege.compart_N_rhizodep n'est pas modifié
					
					} else {
					// * Si l'offre est supérieure à ce qu'il est nécessaire pour un INN de 0.3 *
						// Pour le moment pas de rhizodeposition
						//float offreN_rhizo <- min(offreN_apres_rac,vege.demande_max_rhizo);
						//vege.compart_N_rhizodep <- vege.compart_N_rhizodep + offreN_rhizo;
						//float offreN_apres_rhizo <- offreN_apres_rac - offreN_rhizo ;

				// * parties aériennes *
					vege.QN_aer <- offreN_apres_turnover + vege.QN_aer_prec;
					vege.biomass_above_ground_species <- (vege.BM_pot * 1000) - vege.biomass_senescent_species;
					QN_senescent_j <- (vege.biomass_senescent_species * vege.C_aer) / vege.cn_senescent_leaf;
					vege.QN_aer <- vege.QN_aer - QN_senescent_j;
					vege.INN_j <- vege.QN_aer / QN_INN1; 
					list_INN_especes << vege.INN_j;	
					}
					
			
						
				}
			}
			
			do updateINN10j(mean(list_INN_especes));
			
        }
        
        QN_acquis_cumul <- QN_acquis_cumul + QN_acquis; // TODO Vérifier cohérence entre HerbSim et AqYield
        parcelleAqYieldNC(parcelle_app).sortie_acquisition <- QN_acquis_cumul; // Variable à supprimer utilisée pour vérifier le bilan N
		
		// Mise à jour de la GreenBiomass via la GreenBiomass recalculée des espèces (après calcul de la croissance)
		biomass_above_ground <- sum(compositionVegetation.keys collect each.biomass_above_ground_species);
        
    	} // fin de la condition isCultureLevee
    	do updateBiomassHeightKc; // RM 170925
    } // fin de consommationN
    
    float QNacq_w {
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
        arg QN_acquis_arg type: float default: 0.0; // Cet argument peut prendre 2 valeurs : QN_acquis ou QN_acquis_sans_mic 
        
        float resultat <- 0.0;
        if (profR > 0) {
            resultat <- min([QNinitialeJ_w_arg, QN_acquis_arg * profW / profR + max([0.0, (QN_acquis_arg * (profR - profW) / profR - QNfinaleJ_r_arg)])]); // les paramètres sont en arguments pour simplifier la lecture
        }
        return resultat;
    }

    float QNacq_r {
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
        arg QN_acquis_arg type: float default: 0.0;
        
        float resultat <- min([QNfinaleJ_r_arg, QN_acquis_arg * (profR - profW) / profR + max([0.0, (QN_acquis_arg * profW / profR - QNinitialeJ_w_arg)])]);
        return resultat;
    }
    
    action incorporation_retournement { // Fonction de calcul de la quantité d'azote et de carbone 
    	// Remarque : la "récolte" est dans le cas de la prairie un retournement. On retourne l'intégralité de la plante, il n'y a pas de rendement
   	
    	// Calcul de la biomasse restituée (aérienne et racinaire)
    	float MSA_restituee <- 0.0;
    	float MSR_restituee <- 0.0;
        float MSA_carbone <- 0.0;
        float MSR_carbone <- 0.0; 
        float MSA_azote <- 0.0;
        float MSR_azote <- 0.0;

		// Calcul pour chaque espèce du couvert		
        loop vege over: compositionVegetation.keys{
			//float QN_retournement <- vege.calcul_QN_dil_min(vege.GreenBiomass); // TODO à changer pour prendre la véritable valeur de QN
        	MSA_restituee <- MSA_restituee + vege.biomass_above_ground_species;
        	MSA_carbone <- MSA_carbone + (vege.biomass_above_ground_species * vege.C_aer);
        	//MSA_azote <- MSA_azote + QN_retournement;
        	MSA_azote <- MSA_azote + vege.QN_aer;
        	
        	MSR_restituee <- MSR_restituee + vege.BM_rac;
        	MSR_carbone <- MSR_carbone + (vege.BM_rac * vege.C_rac);
        	MSR_azote <- MSR_azote +  (MSR_carbone / vege.CN_rac);  
        	
        }
        
        
        // Inscription dans la parcelle pour enregistrement 
        parcelleAqYieldNC(parcelle_app).MSA_restituee_parcelle <- MSA_restituee / 1000; // conversion kg/ha (herbsim) -> tonnes/ha
    	parcelleAqYieldNC(parcelle_app).MSR_restituee_parcelle <- MSR_restituee / 1000; // conversion kg/ha (herbsim) -> tonnes/ha
    	
    	// Inscription dans la parcelle pour enregistrement0
    	float MSA_exportee <- 0.0;
    	parcelleAqYieldNC(parcelle_app).MSA_exportee_parcelle <- MSA_exportee; // Pas de biomasse exportée lors du retournement de la prairie
    	
   	
    	  // Apport des résidus à la parcelle
        ask (parcelleAqYieldNC(parcelle_app)) {
            do AddPoolResidus(MSR_carbone/MSR_azote, "incorpore", MSR_carbone, MSR_azote, "racine retournement","residus racinaires", "labile", 0.0, 0.0, 0.0, 0.0); // Parties racinaires
            do AddPoolResidus(MSA_carbone/MSA_azote, "incorpore", MSA_carbone, MSA_azote, "aerien retournement","residus aeriens", "labile", 0.0, 0.0, 0.0, 0.0); // Parties aériennes
        	
        }
    	
    } 
    
  	float getQN_fix{ // pour sorties_azote
  		float QN_fixe_culture <- 0.0;
  		loop vege over: compositionVegetation.keys{
  			QN_fixe_culture <- QN_fixe_culture + vege.QN_fixe;
  		}
  		return QN_fixe_culture;
  	}
  	
  	 // Enregistrement du stress azoté et calcul de la moyenne sur 10 j
    // TODO Non vérifié
    action updateINN10j (float stress){
    	if (length(INN10j) < 10){
    		INN10j << stress;
    	} else {
    		remove from:INN10j index:0;
    		INN10j << stress;
    		meanINN10j <- mean(INN10j);
    	}
    }
    
    	// FAUCHE
	 action updateHerbeFauche (float hauteur_coupe) {
	 		// a faire par les especesHS
	 		// calcul de la part de l'azote qui est récoltée
	 		ThermalAge <- 0.0; // NR : remise à niveau de l'age thermal pour un calcul de la sénéscence correct
	 		ThermalTime <- 0.0; 
	 		    	
	    	ask compositionVegetation.keys{
		 		do CalculHarvest(hauteur_coupe, "fauche");
		 	}		 	
		 			 			 	
		 	// Application de la perte via la fauche
		 	Yield <- cumul_rdt * (1 - HarvestLosses);
		 	
		 	// Calcul de la quantité de C et N exportés
		 	C_export_fauche <- cumul_rdt_C * (1 - HarvestLosses); // Valeur reportée dans suiviOTParPacelle // 
		 	N_export_fauche <- cumul_QN_aer_fauche - cumul_rdt_N_leaves; // Valeur reportée dans suiviOTParParcelle // Quant. de N dans la partie fauchée - ce qui se trouve dans les feuilles tombées
		 	biomasse_aer_restit_fauche <- cumul_rdt * HarvestLosses;
		 	// Calcul de la quantité de C dans les feuilles perdues
		 	float C_feuilles_perdues <- cumul_rdt_C * HarvestLosses;
		 	
		 	
		 	// Incorporation des pertes de fauche (voir plus bas) 	
		 	ask (parcelleAqYieldNC(parcelle_app)) {
		           	do AddPoolResidus(C_feuilles_perdues/myself.cumul_rdt_N_leaves, "incorpore", C_feuilles_perdues, myself.cumul_rdt_N_leaves, "feuilles perdues fauche","residus aeriens", "labile", 0.0, 0.0, 0.0, 0.0);		 			
   			}
		 	
		 	// Mise à jour de la GreenBiomass via la GreenBiomass recalculée des espèces
		 	biomass_above_ground <- sum(compositionVegetation.keys collect each.biomass_above_ground_species);
		 	

		 	parcelle_app.ilot_app.agriculteurAssocie.sonExploitation.stockHerbeFauchee <- parcelle_app.ilot_app.agriculteurAssocie.sonExploitation.stockHerbeFauchee + Yield;
		 	do updateBiomassHeightKc();
		 	
		 	// Incorporation des pertes de fauche
		 	
		 	//float C_quant_LostLeavesHarvest <- (GreenBiomass_beforeHarvest - GreenBiomass) * HarvestLosses * C_aer;
		 	//float N_quant_LostLeavesHarvest <- C_quant_LostLeavesHarvest; // Dépendant de l'espèce, faire par espèce, eventuellement le déplacer plus haut + penser à retirer l'azote de la plante avant prise en compte de la perte de rendement + retirer l'azote de la quantité d'azote exportée puisqu'elle est retournée au sol 
	 		
	 		cumul_rdt <- 0.0;
		 	cumul_rdt_N_leaves <- 0.0;
		 	cumul_rdt_C <- 0.0;
		 	cumul_QN_aer_fauche <- 0.0;
		 	
		 	// Annulation de l'effet de l'INN sur la croissance suivant la fauche : Démarrage du compteur 
		 	loop vege over: compositionVegetation.keys{
		 		vege.ignore_effet_INN <- true;
		 	}
		 	
		 } // Fin updateHerbeFauche
	 
	 action incorporation_BM_senescent{
	 	if (QN_cumul_senescent > 0){
	 		ask (parcelleAqYieldNC(parcelle_app)) {
            	do AddPoolResidus(myself.QC_cumul_senescent/myself.QN_cumul_senescent, "incorpore", myself.QC_cumul_senescent, myself.QN_cumul_senescent, "aerien senescent","residus aeriens","labile", 0.0, 0.0, 0.0, 0.0); // Parties aériennes
        	}
        }else{
        	write "Warning : essai d'insertion d'un pool avec QN = 0";
        }	
       	QN_cumul_senescent <- 0.0;
 		QC_cumul_senescent <- 0.0;
	 }
	 
	 action incorporation_BM_racines{
	 	float compart_N_turnover_couvertHS <- 0.0;
	 	float compart_C_rhizodep_couvertHS <- 0.0;
	 		loop vege over: compositionVegetation.keys{
	 			compart_N_turnover_couvertHS <- compart_N_turnover_couvertHS + vege.compart_N_turnover; // cumul de la quantité d'azote stockée pour toutes les espèces
	 			compart_C_rhizodep_couvertHS <- compart_C_rhizodep_couvertHS + (vege.cn_senescent_root * vege.compart_N_turnover); // calcul à partir du CN des racines en sénéscence pour chaque espèce
	 			vege.compart_N_turnover <- 0.0; // remise à zéro du stock de N pour rhizodéposition
	 		}
	 		if (compart_N_turnover_couvertHS > 0 ){		
	 			ask (parcelleAqYieldNC(parcelle_app)) {
            		do AddPoolResidus(compart_C_rhizodep_couvertHS/compart_N_turnover_couvertHS, "incorpore", compart_C_rhizodep_couvertHS, compart_N_turnover_couvertHS, "rhizodeposition","residus racinaires", "labile", 0.0, 0.0, 0.0, 0.0);
        		}
        	} else { write "WARNING HerbSimNC incorporation racines compart_N_rhizodep_couvertHS";}
	 }
	 
	 action calculBiomassAndKc{
	 	if (dateCour.nbJoursEcoulesDansAnnee = 32){ // * SENESCENCE HIVERNALE *
	 		/* 1er Février : réinitialisation des couverts HerbSim : la biomasse aérienne redescends à 700 kg/ha, 
	 		 * le différenciel avec ce qui a poussé pendant l'hiver doit être incorporé au sol. Ci-dessous, calcul de la quantité d'azote et de carbone contenu, dans les parties aériennes
	 		 */
	 		
	 		// Quantités de biomasse, d'azote et de carbone à incorporer, échelle du couvert, partie aérienne
	 		float GBM_aer_diff_reinit_couvertHS <- 0.0;
	 		float QN_aer_diff_reinit_couvertHS <- 0.0;
	 		float QC_aer_diff_reinit_couvertHS <- 0.0;
	 		
	 		loop vege over: compositionVegetation.keys{
	 			float GBM_avant_reinitialisation_especeHS <- vege.biomass_above_ground_species; // Garde trace de la biomasse aérienne avant réinitialisation
	 			float QN_avant_reinitialisation_especeHS <- vege.QN_aer; // Quantité d'azote contenue dans la partie aérienne avant réinitialisation
	 			ask vege {do senescenceHivernale();} // Réinitialisation de la biomasse (commune à HerbSim et HerbSimNC)
	 			float QN_diff_especeHS <-  QN_avant_reinitialisation_especeHS - vege.QN_aer;
	 			GBM_aer_diff_reinit_couvertHS <- GBM_aer_diff_reinit_couvertHS + (GBM_avant_reinitialisation_especeHS - vege.biomass_above_ground_species); // Cumul pout toutes les espèces du différentiel
	 			QN_aer_diff_reinit_couvertHS <- QN_aer_diff_reinit_couvertHS + QN_diff_especeHS;
	 			QC_aer_diff_reinit_couvertHS <- QC_aer_diff_reinit_couvertHS + (GBM_aer_diff_reinit_couvertHS * vege.C_aer);

	 		}
	 		// si après recalcul de QN_aer, la nouvelle valeur est supérieure ou égale à l'ancienne valeur (INN très faible), pas de résidus (rabattage de la biomasse, concentration de l'azote)
			if(QN_aer_diff_reinit_couvertHS > 0){
				ask (parcelleAqYieldNC(parcelle_app)) {
	            	do AddPoolResidus(QC_aer_diff_reinit_couvertHS/QN_aer_diff_reinit_couvertHS, "incorpore", QC_aer_diff_reinit_couvertHS, QN_aer_diff_reinit_couvertHS, "senescence hivernale","residus racinaires", "labile", 0.0, 0.0, 0.0, 0.0);
	        	}
        	
        	}
        	do incorporation_BM_senescent();
	 	}
	 	
	 	ask compositionVegetation.keys{
	 		do calculBiomass(); // Calcul de la croissance pour chaque espèce (ou groupe fonctionnel) du couvert
	 	}
	 	do updateBiomassHeightKc(); // Cumul de la croissance pour l'ensemble du couvert
	 }
    
}

