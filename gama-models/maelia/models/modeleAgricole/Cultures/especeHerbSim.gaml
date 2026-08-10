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
 *  culture
 *  Author: Maroussia Vavasseur
 *  Description: La culture est une entite qui ne va exister qu'entre le jour de son semi et celui de sa recolte. Elle est semee sur une parcelle.
 */

model especeHerbSim

import "../Ilots/ilot.gaml"

global{
	string cheminTypeCultureHerbSim <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/especesHerbSim.csv';
	list<string> listeNomsEspecesHerbSim <- []; 
//	map<string,especeHerbSim> mapEspecesHerbSimParId <- map([]);
		
	// Variables permettant la construction des especes
	matrix initDataTypeCultureHerbSim; 
   	int nbColones;
   	list<string> entetesLues;
	map<string,int> nomsParametres;
	
	action constructionTableauEspeceHerbSim {
		initDataTypeCultureHerbSim <- matrix(csv_file (cheminTypeCultureHerbSim,";",false)); 
       	nbColones <- length(initDataTypeCultureHerbSim row_at 0);
       	entetesLues <- (initDataTypeCultureHerbSim column_at 0) as list<string>;
		nomsParametres <- remplissageMapEnteteFichier(entetesLues);
	}
	
	action constructionEspeceHerbSim {	
		if !file_exists(cheminTypeCultureHerbSim) {do raiseError("fichier inexistant: " + cheminTypeCultureHerbSim);}
		
		do constructionTableauEspeceHerbSim();
				
		loop i from: 1 to: ( nbColones - 1 ) {
			list<string> coloneCourante <- (initDataTypeCultureHerbSim column_at i) as list<string>;
			if((coloneCourante at 1) != nil){
				create especeHerbSim {
					// Noms de l'espece
					idEspeceCultivee <- (coloneCourante at (nomsParametres at "Espece"));
					name <- idEspeceCultivee;
					listeNomsEspecesHerbSim <+ idEspeceCultivee;
					isEspeceHerbSim <- true;
					nomSequenceEspeceHerbSim <- (coloneCourante at (nomsParametres at "nomSequenceEspeceHerbSim"));
					
					// Caractéristiques (paramètres)
					biomass_above_ground_reinit_winter_species <- float(coloneCourante at (nomsParametres at "biomass_above_ground_reinit_winter_species"));
					LeafAngle <- float(coloneCourante at (nomsParametres at "LeafAngle"));
					LeafAreaIndexRate <- float(coloneCourante at (nomsParametres at "LeafAreaIndexRate"));
					LeafLifeSpanMin <- float(coloneCourante at (nomsParametres at "LeafLifeSpanMin"));
					LeafLifeSpanMax <- float(coloneCourante at (nomsParametres at "LeafLifeSpanMax"));
					RegrowthKSward <- float(coloneCourante at (nomsParametres at "RegrowthKSward"));
					hauteurPourKc1 <- float(coloneCourante at (nomsParametres at "hauteurPourKc1"));
					croissanceRacineCult <- float(coloneCourante at (nomsParametres at "croissanceRacineCult"));
					VegetativePotentialRadiationUseEfficiencyRate <- float(coloneCourante at (nomsParametres at "VegetativePotentialRadiationUseEfficiencyRate"));
					ThermalTimeAtFlowering <- float(coloneCourante at (nomsParametres at "ThermalTimeAtFlowering"));
					ThermalTimeAtStemElongation <- float(coloneCourante at (nomsParametres at "ThermalTimeAtStemElongation"));
					thermal_time_at_germination_species <- float(coloneCourante at (nomsParametres at "thermal_time_at_germination_species"));
					PotentialOrganicMatterDigestibility <- float(coloneCourante at (nomsParametres at "PotentialOrganicMatterDigestibility"));
					YieldCorrectionCoefficient <- float(coloneCourante at (nomsParametres at "YieldCorrectionCoefficient"));
					casCroissanceSenescence <- string(coloneCourante at (nomsParametres at "casCroissanceSenescence"));
					isLEG <- bool(coloneCourante at (nomsParametres at "isLEG"));
					C_aer <- float(coloneCourante at (nomsParametres at "C_aer"));
					C_rac <- float(coloneCourante at (nomsParametres at "C_rac"));
					coeffRacBM <- float(coloneCourante at (nomsParametres at "coeffRacBM"));
					coeffRacN <- float(coloneCourante at (nomsParametres at "coeffRacN"));
					paramDilMaxA <- float(coloneCourante at (nomsParametres at "paramDilMaxA"));
					paramDilMaxB <- float(coloneCourante at (nomsParametres at "paramDilMaxB"));
					paramDilMinA <- float(coloneCourante at (nomsParametres at "paramDilMinA"));
					paramDilMinB <- float(coloneCourante at (nomsParametres at "paramDilMinB"));
					CN_LostLeafHarvest <- float(coloneCourante at (nomsParametres at "CN_LostLeafHarvest"));
					prof_max_racines <- float(coloneCourante at (nomsParametres at "profMaxRacines"));
					BM_rac_max <- float(coloneCourante at (nomsParametres at "BM_rac_max"));
					v95_croissance_rac <- float(coloneCourante at (nomsParametres at "v95_croissance_rac"));
					CN_rac <- float(coloneCourante at (nomsParametres at "CN_rac"));
					cn_senescent_root <- float(coloneCourante at (nomsParametres at "cn_senescent_root"));
					cn_sheath <- float(coloneCourante at (nomsParametres at "cn_sheath"));
					couleur <- rgb([coloneCourante at (nomsParametres at "couleur_r"),
									coloneCourante at (nomsParametres at "couleur_g"),
									coloneCourante at (nomsParametres at "couleur_b")
					]);
					
					// Inscription dans la liste des espèces
					listeEspecesCultiveesParOrdreSaisie << self;
					put self at: idEspeceCultivee in: mapEspecesCultiveesParId;
				}
			}			
		}

	}
	
	especeHerbSim constructionEspeceHerbSimConcrete (string nomEspeceHerbsim) {
		especeHerbSim especeResultat;			

			int numEspece <- (listeNomsEspecesHerbSim index_of nomEspeceHerbsim) + 1;
			list<string> coloneCourante <- (initDataTypeCultureHerbSim column_at numEspece) as list<string>;
						
			if((coloneCourante) != nil){
				create especeHerbSim {
					// Noms de l'espece
					idEspeceCultivee <- (coloneCourante at (nomsParametres at "Espece"));
					name <- idEspeceCultivee;
					listeNomsEspecesHerbSim <+ idEspeceCultivee;
					isEspeceHerbSim <- true;
					nomSequenceEspeceHerbSim <- (coloneCourante at (nomsParametres at "nomSequenceEspeceHerbSim"));
					isEspeceHerbSimRattacheeParcelle <- true;
					
					// Caractéristiques (paramètres)
					biomass_above_ground_reinit_winter_species <- float(coloneCourante at (nomsParametres at "biomass_above_ground_reinit_winter_species"));
					LeafAngle <- float(coloneCourante at (nomsParametres at "LeafAngle"));
					LeafAreaIndexRate <- float(coloneCourante at (nomsParametres at "LeafAreaIndexRate"));
					LeafLifeSpanMin <- float(coloneCourante at (nomsParametres at "LeafLifeSpanMin"));
					LeafLifeSpanMax <- float(coloneCourante at (nomsParametres at "LeafLifeSpanMax"));
					RegrowthKSward <- float(coloneCourante at (nomsParametres at "RegrowthKSward"));
					hauteurPourKc1 <- float(coloneCourante at (nomsParametres at "hauteurPourKc1"));
					croissanceRacineCult <- float(coloneCourante at (nomsParametres at "croissanceRacineCult"));
					VegetativePotentialRadiationUseEfficiencyRate <- float(coloneCourante at (nomsParametres at "VegetativePotentialRadiationUseEfficiencyRate"));
					ThermalTimeAtFlowering <- float(coloneCourante at (nomsParametres at "ThermalTimeAtFlowering"));
					ThermalTimeAtStemElongation <- float(coloneCourante at (nomsParametres at "ThermalTimeAtStemElongation"));
					thermal_time_at_germination_species <- float(coloneCourante at (nomsParametres at "thermal_time_at_germination_species"));
					PotentialOrganicMatterDigestibility <- float(coloneCourante at (nomsParametres at "PotentialOrganicMatterDigestibility"));
					YieldCorrectionCoefficient <- float(coloneCourante at (nomsParametres at "YieldCorrectionCoefficient"));
					casCroissanceSenescence <- string(coloneCourante at (nomsParametres at "casCroissanceSenescence"));
					isLEG <- bool(coloneCourante at (nomsParametres at "isLEG"));
					C_aer <- float(coloneCourante at (nomsParametres at "C_aer"));
					C_rac <- float(coloneCourante at (nomsParametres at "C_rac"));
					coeffRacBM <- float(coloneCourante at (nomsParametres at "coeffRacBM"));
					coeffRacN <- float(coloneCourante at (nomsParametres at "coeffRacN"));
					paramDilMaxA <- float(coloneCourante at (nomsParametres at "paramDilMaxA"));
					paramDilMaxB <- float(coloneCourante at (nomsParametres at "paramDilMaxB"));
					paramDilMinA <- float(coloneCourante at (nomsParametres at "paramDilMinA"));
					paramDilMinB <- float(coloneCourante at (nomsParametres at "paramDilMinB"));
					CN_LostLeafHarvest <- float(coloneCourante at (nomsParametres at "CN_LostLeafHarvest"));
					prof_max_racines <- float(coloneCourante at (nomsParametres at "profMaxRacines"));
					BM_rac_max <- float(coloneCourante at (nomsParametres at "BM_rac_max"));
					v95_croissance_rac <- float(coloneCourante at (nomsParametres at "v95_croissance_rac"));
					CN_rac <- float(coloneCourante at (nomsParametres at "CN_rac"));
					cn_senescent_root <- float(coloneCourante at (nomsParametres at "cn_senescent_root"));
					cn_sheath <- float(coloneCourante at (nomsParametres at "cn_sheath"));
					cn_senescent_leaf <- float(coloneCourante at (nomsParametres at "cn_senescent_leaf"));
					couleur <- rgb([coloneCourante at (nomsParametres at "couleur_r"),
									coloneCourante at (nomsParametres at "couleur_g"),
									coloneCourante at (nomsParametres at "couleur_b")
					]);
					especeResultat <- self;
				}
			}			

		return (especeResultat);
	}

	
	
	
	/*
	 * Private
	 * Prend en entree la liste des entetes lues dans le fichier, et leur affecte un numero de ligne
	 */
	map<string,int> remplissageMapEnteteFichier{
		arg entetesLues type: list<string> default: [];
		map<string,int> mapResultat <- map<string,int>([]);
		int numLigne <- 0;
		loop entete over: entetesLues{
			put numLigne at: entete in: mapResultat;
	        numLigne <- numLigne + 1;		
		}			
			
		return mapResultat;
	}
}

species especeHerbSim parent: especeCultivee{
	string nomSequenceEspeceHerbSim;
	rgb couleur <- rgb("lightgreen");
	
	cultureHerbSim cultureHerbSim_app <- nil;
	float fraction <- 1.0; // TODO Nirina -> A modifier/déplacer quand on pourrait simuler des mélanges d'espèce
	
	bool isEspeceHerbSimRattacheeParcelle <- false; // Est-ce que cet agent est rattaché à une parcelle ? (2 types de especeHerbSim : 1) créée systématique en début de simulation 2) rattaché à un instanciation du modèle de culture d'une parcelle)
	
	// Paramètres présents dans le fichier especesHerbSim
	float LeafLifeSpanMin; //[°C]
	float LeafLifeSpanMax; //[°C]
	float LeafAreaIndexRate;
	float LeafAngle;
	float ThermalTimeAtFlowering; //[°C]
	float ThermalTimeAtStemElongation; //[°C]
	float thermal_time_at_germination_species; //[°C]
	float VegetativePotentialRadiationUseEfficiencyRate;
	float YieldCorrectionCoefficient;
	float RegrowthKSward;
	float hauteurPourKc1; //[mm] //moyenne sur 30 ans ([1981-2010]) hauteur de l'herbe à echV=1
	float PotentialOrganicMatterDigestibility; //potential OMD [unit ?]
	float croissanceRacineCult;
	string casCroissanceSenescence; // Détermine quelles equations utiliser dans les fonctions suivantes : calculCroissanceSenescenceLAI, calculRadiationUseEfficiency et calculBiomassSenescent
	bool isLEG;
	float C_aer;
	float C_rac;
	float coeffRacBM;
	float coeffRacN;
	float paramDilMaxA; // NR 29/05/2024 - Tiré de SystN (Juin 2023) "AMAX"
	float paramDilMaxB; // NR 29/05/2024 - Tiré de SystN (Juin 2023) "BMAX"
	float paramDilMinA; // NR 29/05/2024 - Tiré de SystN (Juin 2023) "PARAM_NC_A"
	float paramDilMinB; // NR 29/05/2024 - Tiré de SystN (Juin 2023) "PARAM_NC_B"
	
	// Autres paramètres (pas dans espècesHerbSim.csv)
	float LeafSheathHeigth <- 3.0; //[cm] Hauteur de la gaine, utilisée pour déterminer la part de la biomasse contenu dans la gaine foliaire
	//float cn_senescent_leaf <- 0.0 ; // Ratio C/N  de la biomasse en sénéscence 26 pour le lolium; 33 pour festuca et 24 pour dactylis (Sanaullah et al., 2010): TODO à affiner et faire un paramétre dans le fichier csv ?
	float CN_LostLeafHarvest; // NR 19/09/2024 - ratio C/N des feuilles perdues lors de la fauche
	
	// Variables
	float biomass_above_ground_species <- 700.0; // [kg/ha]
	float biomass_above_ground_reinit_winter_species <- 0.0; // [kg/ha]
	float biomass_sheath_species <- 0.0; // [kg/ha]
	float ResidualBiomass 		<- 700.0; // [kg/ha]
	float biomass_above_ground_species_prec <- 0.0; //[kg/ha]
	float BiomassSenescentBolinder <- 0.0;
	
	float ResidualLeafAreaIndex <- 0.5; //[m2/m2]
	float LeafAreaIndex 		<- 0.5; //[m2/m2]
	float LeafAreaIndexGrowth   <- 0.0; //[m2/m2]
	float LeafAreaIndexSenescent<- 0.0; //[m2/m2]
	float TimeOfTheYearCorrectionFactor <- 0.6;
	
	float LeafAreaIndexInit <- 0.5; //[m2/m2]
	float RadiationUseEfficiency <- 0.0;
	
	float QN_suivi_plante <- 0.0;
	
	
	float BM_compartiment_rac <- 0.0;
	float QN_compartiment_rac <- 0.0;
	float QC_compartiment_rac <- 0.0;
	

	
	float BM_rac <- 0.0; // TODO vérifier les doublons
	float BM_rac_max <- 0.0; // KG -> biomasse maximale à atteindre
	float v95_croissance_rac <- 0.0; // JOURS -> nbrs de jours nécessaire pour obtenir 95% de la biomasse racinaire
	float lambda_croissance_rac <- 0.0; // paramètre de l'équation de croissance des racines
	float compteur_N_jours <- 0.0;
	float CN_rac <- 0.0;
	float cn_senescent_root <- 0.0;
	float cn_sheath <- 0.0;
	float cn_senescent_leaf <- 0.0;
	
	float demande_N_rac_j; // TODO à déplacer ? variable de suivi
	float demande_N_rac_rhizodep_j; // TODO à déplacer ? variable de suivi 
	float compart_N_turnover <- 0.0;
	
	
	float cumul_demandeMin <- 0.0;
	float cumul_demandeMax <- 0.0;
	float cumul_acquis <- 0.0;
	
	float INN_j <- 1.0; // INN journalier (acquis /  demande minimale)
	// Paramètres de la courbe de dilution max et min //TODO 030624 Renaud --> passer tous ces paramètres dans le fichier especeHerbSim
	// Courbe de dilution max -> utilisée pour définir la demande (incluant une consommation "de luxe")
	// Courbe de dilution min -> utilisée pour définir le stress azoté ou la fixation symbiotique (en fonction de la quantité d'azote donnée par le sol)

	
	
	float Difference <- 700.0;
	float Average <- 1250.0;
	bool DefoliationDoneAfterStemElongation <- false;
	float biomass_senescent_species <- 0.0;
	float BiomassGrown <- 0.0; // NR Herbsim 22/04/2024 - Attention il existe une variable BiomassGrown pour le especeHerbSim et pour cultureHerbSim -> A changer
	float QN_acquis_especeHS_j <- 0.0; // NR Herbsim 21/05/2024 - Quantité d'azote acquise par jour, pour chaque espèce composant la prairie
	float QN_acquis_cumul_especeHS <- 0.0; // NR Herbsim 21/05/2024 - Quantité d'azote acquise sur la période de culture, pour chaque espèce composant la prairie
	float QN_fixe_cumul_especeHS <- 0.0;
	float stress_N_especeHS_j <- 0.0;
	
	float demandeAzoteMax <- 0.0; // Utilisé dans HerbSimNC // NR HerbSim // TODO plutôt faire une fonction qui renvoie une valeur, plutot qu'une fonction qui modifie une valeur (risque de ne pas prendre la valeur actualisée au bon moment)

	float BiomassGrown_tot_cumul <- 0.0; // NR variable de suivi
	float BiomassNet_tot_cumul <- 0.0; // NR variable de suivi
	float BiomassSenescent_tot_cumul <- 0.0; // NR variable de suivi
	
	float satisfaction_azote_especeHS <- 1.0 ; // Fixée à 1 au départ (satisfaction OK) 

	float pourcentage_F <- 0.0; // NR A SUPPRIMER fzekfjnbf
	float somme_diff_calcul_senescent <- 0.0; // fzekfjnbf A SUPPRIMER
	
	float BM_pot <- 0.0; // garde trace de la biomasse aérienne potentielle
	float BM_rac_pot <- 0.0; // garde trace de la biomasse racinaire potentielle
	float BM_rac_prec <- 0.0;
	float QN_aer <- 0.0; // Nouvelle formalisation de la demande Déc. 2024 ; quantité d'azote contenu dans les parties aériennes de la plante
	float QN_rac <- 0.0;// Nouvelle formalisation de la demande en azote Déc. 2024 ; quantité d'azote contenu dans les parties aériennes de la plante
	float QN_aer_prec <- 0.0; 
	float demande_max_aer <- 0.0;
	float demande_max_rac <- 0.0;
	float demande_turnover <- 0.0; 
	
	float QN_fixe <- 0.0; // Nouvelle formalisation de la demande Déc. 2024 ; quantité d'azote fixé dans toute la plante pour un jour donné
	
	float prof_max_racines <- 100.0; // TODO à mettre dans especesHerbSim
	
	bool ignore_effet_INN <- false; // Permet d'ignorer l'effet de l'INN sur la croissance potentiel quelques jours après la fauche (nbr de jours défini par longueur_effet_INN)
	float longueur_effet_INN <- 0.0; // Nombre de jour (après la fauche) d'annulation de l'effet de l'INN sur la croissance => TODO à transférer eventuellement dans especesHerbSim
	float compteur_effet_INN <- 0.0; // Compteur de jours passés depuis la fauche
	
	float INN_lim <- 0.3; // Valeur minimale de l'INN pour l'espèce (limitation de la croissance pour rester toujours au-dessus de cette valeur)
	
	float plateau_dilution_n <- 1.0; // Avant 1 tMS.ha, il n'y a pas de dilution (Lemaire et Gastal, 1997)
	
	float annual_root_turnover <- 1.0; // taux de turnover racinaire annuel (analyse de sensibilité sur le paramétre pour le fixer à faire)
	
	/*
	 * *****************************************************************************************
	 * Non appelle pour le moment
	 */		
	action comportementJournalier{
		
	}
	//Init ANNUEL :
	//DefoliationDoneAfterStemElongation <- false;
		
	action initialisationVegetation{ // TODO : il s'agit ici de la procédure de démarrage de simulation pour une prairie permanente; à modifier pour un semis de prairie temporaire
		lambda_croissance_rac <- - ln(0.05)/v95_croissance_rac; // paramètres de l'équation 
		
		ResidualLeafAreaIndex <- LeafAreaIndexInit;
		LeafAreaIndex <- LeafAreaIndexInit;

		float GreenBiomassInit <- 1.0; // Biomasse aérienne de démarrage arbitraire, pour ne pas mettre 0
		ResidualBiomass <- GreenBiomassInit;
		biomass_above_ground_species <- GreenBiomassInit;
		biomass_sheath_species <- min([biomass_above_ground_species, TimeOfTheYearCorrectionFactor * 3.0 * cultureHerbSim_app.BaselineDensity]);
		Difference <- ThermalTimeAtFlowering - ThermalTimeAtStemElongation;
		Average <- (ThermalTimeAtFlowering + ThermalTimeAtStemElongation) / 2.0;
		DefoliationDoneAfterStemElongation <- false;
		QN_aer <- GreenBiomassInit * 0.01; //Pourcentage fixe d'azote au démarrage de la culture 

//		if (QN_aer = 0){ 
//			QN_aer <- ((paramDilMinA * (GreenBiomass/1000)^(-paramDilMinB)) * GreenBiomass / 100);
//		} else { // Si il s'agit de la reinitialisation d'hiver (senescence d'hiver)
//			QN_aer <- ((paramDilMinA * (GreenBiomass/1000)^(-paramDilMinB)) * GreenBiomass / 100);
//		}
		
		// Variable utilisée seulement avec module HerbSimNC
//		if (nomChoixModeleCroissancePrairie = "HerbSimNC") {
//			QN_acquis_cumul_especeHS <- (paramDilMinA * (GreenBiomass/1000)^(-paramDilMinB)); // Acquisition d'azote pendant le démarrage de la croissance (annulé car compliqué -> prise en compte nécéssaire de l'azote accumulé avant si couvert pluri-annuel) 
//		}
	}
	
	action senescenceHivernale{ // réinitialisation réalisée au passage de l'hiver (sénescence hivernale) à reprendre pour les prairies permanentes 
		ResidualLeafAreaIndex <- LeafAreaIndexInit;
		LeafAreaIndex <- LeafAreaIndexInit;
				
		if(biomass_above_ground_species > biomass_above_ground_reinit_winter_species){ // si la biomasse aérienne est supérieure à la biomasse de réinitialisation après l'hiver : rabatage de la biomasse
			ResidualBiomass <- biomass_above_ground_reinit_winter_species;
			biomass_above_ground_species <- biomass_above_ground_reinit_winter_species;
			biomass_sheath_species <- min([biomass_above_ground_species, TimeOfTheYearCorrectionFactor * 3.0 * cultureHerbSim_app.BaselineDensity]);
			float new_QN <- ((paramDilMinA * (max(biomass_above_ground_species/1000,plateau_dilution_n))^(-paramDilMinB)) * biomass_above_ground_species / 100);// nouvelle quantité d'azote potentielle après sénésence hivernale
			QN_aer <- min(QN_aer,new_QN);
		} else { // si la biomasse aérienne est inférieure à la biomasse de réinitialisation : rabattage uniquement de la biomasse résiduelle
			ResidualBiomass <- biomass_above_ground_species;
		}
		Difference <- ThermalTimeAtFlowering - ThermalTimeAtStemElongation;
		Average <- (ThermalTimeAtFlowering + ThermalTimeAtStemElongation) / 2.0;
		DefoliationDoneAfterStemElongation <- false;
	}
	
	action calculBiomass{
				
		//---------------------------
        // MAJ du LAI et de la biomasse residuelle a chaque DVF pour le calcul de la senescence
        //---------------------------
        float ratioAgeLeafLife <- cultureHerbSim_app.ThermalAge / LeafLifeSpanMin;
        if (abs(ratioAgeLeafLife - round(ratioAgeLeafLife)) <= 0.015 ) and (ratioAgeLeafLife > 0.5){ // rempli quand l'âge thermique de la plante se rapporche de LeafLifeSpanMin ou d'un multiple de LeafLifeSpanMin (Versions HerbSim sans NC)
		//if (abs(ratioAgeLeafLife - 1) <= 0.015){ // si l'âge thermal de la plante se rapproche de DVFmin -> redéfinition de la biomasse résiduelle (= biomasse totale à age thermal = DVFmin) voir Duru et al. Fourrages éq. 18
            ResidualLeafAreaIndex <- LeafAreaIndex;
            ResidualBiomass <- biomass_above_ground_species; 
		}
        //---------------------------
        // calcul de la croissance du LAI
        //---------------------------
        float MeanTemperature <- (max([min([cultureHerbSim_app.parcelle_app.getTmax(), 25.0]),0.0])+
	 										 max([min([cultureHerbSim_app.parcelle_app.getTmin(), 25.0]),0.0])
	 			                			 )/2.0;
	 			                			 
	 	do calculCroissanceSenescenceLAI(MeanTemperature);		                			 
        //---------------------------
        // calcul du LAI
        //---------------------------
        if (LeafAreaIndex < 1){ // NR 04/11/2025 Garde fou, en cas de sénescence forte du LAI, pour ne pas que le LAI soit négatif
        	LeafAreaIndex <- LeafAreaIndex + LeafAreaIndexGrowth;
        	ResidualLeafAreaIndex <- LeafAreaIndex;
        } else {
        	 LeafAreaIndex <- LeafAreaIndex + LeafAreaIndexGrowth - LeafAreaIndexSenescent;
        }
        //write "LeafAreaIndex = " + LeafAreaIndex;
        //---------------------------
        // calcul de la capture du rayonnement
        //---------------------------
        float PhotoSyntheticActiveRadiation <- 0.48 * 0.95 * (1.0 - exp((-LeafAngle * LeafAreaIndex))) * cultureHerbSim_app.parcelle_app.ilot_app.meteo.radiation;

  		do calculRadiationUseEfficiency(MeanTemperature);           

        //---------------------------
        // calcul de la croissance brute
        //---------------------------
        BiomassGrown <- RadiationUseEfficiency * PhotoSyntheticActiveRadiation * 10.0;
        // multiplication par 10 pour le passage de g / m2 en kg / ha
        //---------------------------
        // calcul de la senescence
        //---------------------------
        
        float biomass_senescent_species_temp <- calculBiomassSenescent(MeanTemperature); 
    	if(biomass_above_ground_species < biomass_senescent_species_temp){
    		biomass_senescent_species <- 0.0;
    	} else {
    		biomass_senescent_species <- biomass_senescent_species_temp;
        }
 		BiomassSenescentBolinder <- BiomassGrown  * 0.45 * 0.15;  
        //BiomassSenescent <- BiomassGrown  * 0.45 * 0.15;  
        
        //---------------------------
        // calcul de la biomasse
        //---------------------------
        biomass_above_ground_species_prec <- biomass_above_ground_species; // NR La nouvelle biomasse aérienne va dépendre de la disponibilité en azote, donc pas de MAJ immédiate.
        //GreenBiomass <- max([300.0, GreenBiomass + BiomassGrown - BiomassSenescent]); //NR déplacé pour tenir compte de l'azote disponible dans le sol
     	
     	// variable de suivi à supprimer
     	BiomassGrown_tot_cumul <- BiomassGrown_tot_cumul + BiomassGrown; // NR suivi de la biomasse gagnée pour l'espèce
     	BiomassSenescent_tot_cumul <- BiomassSenescent_tot_cumul + biomass_senescent_species; // NR suivi de biomasse sénescent pour l'espèce
     	BiomassNet_tot_cumul <- BiomassNet_tot_cumul + (biomass_above_ground_species - biomass_above_ground_species_prec); // NR suivi du bilan net journalier de biomasse (ne tient pas compte du plafonnement à 300 !)

        do addNSenescent(biomass_senescent_species); // NR -> option avec utilisation du coefficient de bolinder uniquement pour l'ajout de la sénescence en résidus (pas pour la croissance de la plante)
		do calculBiomassSheath();
	}
	
	action calculCroissanceSenescenceLAI (float MeanTemperature){	
		switch casCroissanceSenescence {
			// Toutes espèces HerbSim sauf légumineuses
			match "autre" {
				// calcul de la croissance du LAI
				float TemperatureEffectLAI <- 1.71 * 0.001 * (MeanTemperature^2);
		        LeafAreaIndexGrowth <- LeafAreaIndexRate * cultureHerbSim_app.indiceSatifactionHydrique * parcelleAqYield(cultureHerbSim_app.parcelle_app).NutrientIndex * TemperatureEffectLAI;
		        
		        // calcul de la senescence du LAI
		        LeafAreaIndexSenescent <- ResidualLeafAreaIndex * MeanTemperature / LeafLifeSpanMin;
			}
			
			// Alfalfa
			match "alfalfa" {
		        // calcul de la croissance du LAI
		        float TemperatureEffectLAIGrowth <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAIGrowth <- 0.009 * min([MeanTemperature, 23.0]);
		        }          
		
		       	float DayLengthEffectLAI <- -0.00215 * dateCour.nbJoursEcoulesDansAnnee + 1.0625;
		        LeafAreaIndexGrowth <- LeafAreaIndexRate * cultureHerbSim_app.indiceSatifactionHydrique * TemperatureEffectLAIGrowth * DayLengthEffectLAI;

		        // calcul de la senescence du LAI
		        float TemperatureEffectLAISenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAISenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        LeafAreaIndexSenescent <- ResidualLeafAreaIndex * TemperatureEffectLAISenescent / LeafLifeSpanMin;      
			}
			
			// Trifolium
			match "trifoliumPratense" {
		        // calcul de la croissance du LAI
		        float TemperatureEffectLAIGrowth <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAIGrowth <- 0.024 * min([MeanTemperature, 23.0]) - 0.137;
		        }          
		        LeafAreaIndexGrowth <- LeafAreaIndexRate * cultureHerbSim_app.indiceSatifactionHydrique * TemperatureEffectLAIGrowth;

		        // calcul de la senescence du LAI
		        float TemperatureEffectLAISenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAISenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        LeafAreaIndexSenescent <- ResidualLeafAreaIndex * TemperatureEffectLAISenescent / LeafLifeSpanMin; 
			}
			
			match "trifoliumRepens" {
		        // calcul de la croissance du LAI
		        float TemperatureEffectLAIGrowth <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAIGrowth <- 0.024 * min([MeanTemperature, 23.0]) - 0.137;
		        }          
		        LeafAreaIndexGrowth <- LeafAreaIndexRate * cultureHerbSim_app.indiceSatifactionHydrique * TemperatureEffectLAIGrowth;

		        // calcul de la senescence du LAI
		        float TemperatureEffectLAISenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectLAISenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        LeafAreaIndexSenescent <- ResidualLeafAreaIndex * TemperatureEffectLAISenescent / LeafLifeSpanMin;     
			}
		}

		
	}
	
	action calculRadiationUseEfficiency (float MeanTemperature){ // calcul de l'efficience de conversion du rayonnement
		switch casCroissanceSenescence {
			// Toutes espèces HerbSim sauf légumineuses
			match "autre" {
		        float TemperatureEffectRUE <- 0.037 + (0.09 * MeanTemperature) - 0.0022 * (MeanTemperature^2); // même relation que dans Fourrages 2010
		        float DayLengthEffectRUE <- 0.0;
		        if (dateCour.nbJoursEcoulesDansAnnee <= 31){
		        	DayLengthEffectRUE <- 0.002553 * dateCour.nbJoursEcoulesDansAnnee + 0.92333;
		        }else if(dateCour.nbJoursEcoulesDansAnnee <= 304){
		        	DayLengthEffectRUE <- -0.00085 * dateCour.nbJoursEcoulesDansAnnee + 1.026; // même relation que dans Fourrages 2010
		        }else{
		        	DayLengthEffectRUE <- 0.002553 * (dateCour.nbJoursEcoulesDansAnnee - 304) + 0.7676;
		        }
		        // calcul de leffet phenologie (vegetatif / repro) pour les graminees
		        //    - calcul de lintensite de la phase reproductive (fonction de la nutrition), ce coeff = 1 en phase vegetative
		        //    - calcul des coefficients a, b, c qui dependent de la phenologie et de lintensite de la phase reproductive
		
		        
		        //float AdjustedNutrientIndex <- parcelleAqYield(cultureHerbSim_app.parcelle_app).NutrientIndex * 0.8 + 0.2; // ancien calcul avec azote variant au cours de l'année
		        
		        // Effet de l'azote sur la croissance : 
		        float index_azote;
		        if(ignore_effet_INN){
		        	index_azote <- (2 * 0.75 * 1 + parcelleAqYield(cultureHerbSim_app.parcelle_app).PhosphorusIndex) / 3;
		        	compteur_effet_INN <- compteur_effet_INN + 1.0;
		        	if (compteur_effet_INN > longueur_effet_INN){ // vérification que la longueur de l'annulation de l'effet de l'INN 
		        		ignore_effet_INN <- false;
		        		compteur_effet_INN <- 0.0;
		        	}
		        } else {
		        	index_azote <- (2 * 0.75 * max(0.0,min(1, INN_j)) + parcelleAqYield(cultureHerbSim_app.parcelle_app).PhosphorusIndex) / 3;
		        }
		        
		        float AdjustedNutrientIndex <- index_azote * 0.8 + 0.2;

		        // correction sur l'indice de nutrition car le modele a ete calibre pour des conditions de nutrition sub-optimales
		            float ReproductionIntensity <- 1.19 * AdjustedNutrientIndex + 0.59;
		            float a <- ((ReproductionIntensity - 1.0) * Difference) / ((( (ThermalTimeAtFlowering^2)
		                       - (ThermalTimeAtStemElongation^2)) * (ThermalTimeAtFlowering - Average))
		                       - (( (ThermalTimeAtFlowering^2) - (Average^2)) * (Difference)));
		
		            float b <- (1.0 - ReproductionIntensity - a * ((ThermalTimeAtFlowering^2) - (Average^2)))
			                   / (ThermalTimeAtFlowering - Average);
		            float c <- ReproductionIntensity - a * (Average^2) - (b * Average);
		 
		 
		            // calcul du RUE selon le stade phenologique et selon quil y a deja eu une defoliation apres la montaison
		        // correction liee au taux de CO2 dans l'atmosphere
				//float RadiationUseEfficiency <- 0.0;
		        if((cultureHerbSim_app.ThermalTime >= ThermalTimeAtStemElongation)
		                and (cultureHerbSim_app.ThermalTime < ThermalTimeAtFlowering)
		                and ! DefoliationDoneAfterStemElongation){
		  	        RadiationUseEfficiency <-
		                    1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                    * TemperatureEffectRUE * DayLengthEffectRUE * AdjustedNutrientIndex * cultureHerbSim_app.indiceSatifactionHydrique
		        			* (a * (cultureHerbSim_app.ThermalTime^2) + b * cultureHerbSim_app.ThermalTime + c) * cultureHerbSim_app.CO2CorrectionFactor;
		                	
		       }else if((cultureHerbSim_app.ThermalTime >= ThermalTimeAtFlowering)
		       		and ! DefoliationDoneAfterStemElongation ){
		       		RadiationUseEfficiency <-
		                    1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                    * TemperatureEffectRUE * DayLengthEffectRUE * AdjustedNutrientIndex * cultureHerbSim_app.indiceSatifactionHydrique
		        			* (2.0 - ReproductionIntensity) * cultureHerbSim_app.CO2CorrectionFactor;
		       	}else{
		            RadiationUseEfficiency <-
		                    1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                    * TemperatureEffectRUE * DayLengthEffectRUE * AdjustedNutrientIndex * cultureHerbSim_app.indiceSatifactionHydrique
		        			*  cultureHerbSim_app.CO2CorrectionFactor;
		       	}
			}
			
			// Alfalfa
			match "alfalfa" {
		        float TemperatureEffectRUE <- 1.0;
		        if ((MeanTemperature >= 5.0) and (MeanTemperature <= 15.0)){
		        	TemperatureEffectRUE <- -0.0032 * (MeanTemperature^2) + 0.1141 * MeanTemperature + 0.0027;
		        }else if (MeanTemperature < 5.0){
		        	TemperatureEffectRUE <- 0.0;
		        }
				
		        float DayLengthEffectRUE <- 0.0;
		        if (dateCour.nbJoursEcoulesDansAnnee <= 31){
		        	DayLengthEffectRUE <- 0.00557 * dateCour.nbJoursEcoulesDansAnnee + 0.8273;
		        }else if(dateCour.nbJoursEcoulesDansAnnee <= 249){
		        	DayLengthEffectRUE <- -0.001 * dateCour.nbJoursEcoulesDansAnnee + 1.05;
		        }else if(dateCour.nbJoursEcoulesDansAnnee <= 299){
		        	DayLengthEffectRUE <- -0.006 * dateCour.nbJoursEcoulesDansAnnee + 2.3;
		        }else{
		        	DayLengthEffectRUE <- 0.004868 * (dateCour.nbJoursEcoulesDansAnnee - 299) + 0.506;
		        }
		        RadiationUseEfficiency <-
		                1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                * TemperatureEffectRUE * DayLengthEffectRUE * cultureHerbSim_app.indiceSatifactionHydrique
		    			*  cultureHerbSim_app.CO2CorrectionFactor;
			}
			
			// Trifolium
			match "trifoliumPratense" {
		        float TemperatureEffectRUE <- 1.0;
		        if ((MeanTemperature >= 5.0) and (MeanTemperature <= 15.0)){
		        	TemperatureEffectRUE <- -0.0032 * (MeanTemperature^2) + 0.1141 * MeanTemperature + 0.0027;
		        }else if (MeanTemperature < 5.0){
		        	TemperatureEffectRUE <- 0.0;
		        }
				
		        float DayLengthEffectRUE <- 0.004213 * (dateCour.nbJoursEcoulesDansAnnee - 304) + 0.6124;
		        if (dateCour.nbJoursEcoulesDansAnnee <= 31){
		        	DayLengthEffectRUE <- 0.004213 * dateCour.nbJoursEcoulesDansAnnee + 0.8694;
		        }else if(dateCour.nbJoursEcoulesDansAnnee <= 304){
		        	DayLengthEffectRUE <- -0.0014 * dateCour.nbJoursEcoulesDansAnnee + 1.038;
		        }
		        RadiationUseEfficiency <-
		                1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                * TemperatureEffectRUE * DayLengthEffectRUE * cultureHerbSim_app.indiceSatifactionHydrique
		    			*  cultureHerbSim_app.CO2CorrectionFactor;
			}
			
			match "trifoliumRepens" {
		        float TemperatureEffectRUE <- 1.0;
		        if ((MeanTemperature >= 5.0) and (MeanTemperature <= 15.0)){
		        	TemperatureEffectRUE <- -0.0032 * (MeanTemperature^2) + 0.1141 * MeanTemperature + 0.0027;
		        }else if (MeanTemperature < 5.0){
		        	TemperatureEffectRUE <- 0.0;
		        }
				
		        float DayLengthEffectRUE <- 0.004213 * (dateCour.nbJoursEcoulesDansAnnee - 304) + 0.6124;
		        if (dateCour.nbJoursEcoulesDansAnnee <= 31){
		        	DayLengthEffectRUE <- 0.004213 * dateCour.nbJoursEcoulesDansAnnee + 0.8694;
		        }else if(dateCour.nbJoursEcoulesDansAnnee <= 304){
		        	DayLengthEffectRUE <- -0.0014 * dateCour.nbJoursEcoulesDansAnnee + 1.038;
		        }
		        RadiationUseEfficiency <-
		                1.8 * VegetativePotentialRadiationUseEfficiencyRate
		                * TemperatureEffectRUE * DayLengthEffectRUE * cultureHerbSim_app.indiceSatifactionHydrique
		    			*  cultureHerbSim_app.CO2CorrectionFactor;
			}
		}
	}
	
	// calcul de la senescence
	float calculBiomassSenescent(float MeanTemperature){ 
		switch casCroissanceSenescence {
			// Toutes espèces HerbSim sauf légumineuses
			match "autre" {
		        float LeafPercentage <- min([1.0, 0.824 * ((biomass_above_ground_species / 1000.0)^(-0.42))]);
		        
		        float res <- 0.0;
		        if ((cultureHerbSim_app.ThermalTime >= ThermalTimeAtStemElongation)
		                and ! DefoliationDoneAfterStemElongation){
		            res <- (1.0 - 0.33) * LeafPercentage * biomass_above_ground_species * MeanTemperature / LeafLifeSpanMin;	
		        }else{
		        	res <- (1.0 - 0.33) * ResidualBiomass * MeanTemperature / LeafLifeSpanMin;
		        }
		        return res;
			}
			
			// Alfalfa
			match "alfalfa" {
				/// NR 151024
		        pourcentage_F <- min([1.0,0.89 * ((biomass_above_ground_species/100)^(-0.315))]);
		        float LeafPercentage <- min([1.0,0.89 * ((biomass_above_ground_species/100)^(-0.315))]);
		        float TemperatureEffectBiomassSenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectBiomassSenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        float calcul_og <-  ((1.0 - 0.33) * ResidualBiomass * TemperatureEffectBiomassSenescent / LeafLifeSpanMin);  
		        float calcul_leaf_perc <-  ((1.0 - 0.33) * biomass_above_ground_species * LeafPercentage * TemperatureEffectBiomassSenescent / LeafLifeSpanMin); 
		        somme_diff_calcul_senescent <- somme_diff_calcul_senescent + (calcul_og - calcul_leaf_perc);
		        return ((1.0 - 0.33) * ResidualBiomass * LeafPercentage * TemperatureEffectBiomassSenescent / LeafLifeSpanMin);
		           
		        // nouveau 
//		        float LeafPercentage <- min([1.0,0.89 * ((GreenBiomass/1000)^(-0.315))]);
//		        float TemperatureEffectBiomassSenescent <- 0.0;
//		        if (MeanTemperature >= 5.0){
//		        	TemperatureEffectBiomassSenescent <- max([5.0, min([MeanTemperature, 23.0])]);
//		        }
//		        float res <- 0.0;
//		        if ((cultureHerbSim_app.ThermalTime >= ThermalTimeAtStemElongation)
//		                and ! DefoliationDoneAfterStemElongation){
//		            res <- (1.0 - 0.33) * LeafPercentage * GreenBiomass * TemperatureEffectBiomassSenescent / LeafLifeSpanMin;
//		                	
//		        }else{
//		        	res <- (1.0 - 0.33) * ResidualBiomass * TemperatureEffectBiomassSenescent / LeafLifeSpanMin;
//		        }
//		        return res;
			}
			
			// Trifolium
			match "trifoliumPratense" {
		        float TemperatureEffectBiomassSenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectBiomassSenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        return (1.0 - 0.33) * ResidualBiomass * TemperatureEffectBiomassSenescent / LeafLifeSpanMin;    
			}
			
			match "trifoliumRepens" {
		        float TemperatureEffectBiomassSenescent <- 0.0;
		        if (MeanTemperature >= 5.0){
		        	TemperatureEffectBiomassSenescent <- max([5.0, min([MeanTemperature, 23.0])]);
		        }
		        return (1.0 - 0.33) * ResidualBiomass * TemperatureEffectBiomassSenescent / LeafLifeSpanMin;   
			}
		}
	}	
	
	action calculBiomassSheath{
		
       	//---------------------------
		// calcul de la biomasse contenue dans la gaine foliaire
		//---------------------------
		
//			// hiver beaucoup de pertes par senescence
		if ((dateCour.nbJoursEcoulesDansAnnee <= 31) or (dateCour.nbJoursEcoulesDansAnnee >= 335)){
			TimeOfTheYearCorrectionFactor <- 0.6;
		}				
		// debut de printemps: reprise progressive de la croissance
		else if (dateCour.nbJoursEcoulesDansAnnee <= 105){
			TimeOfTheYearCorrectionFactor <- TimeOfTheYearCorrectionFactor + 0.005333333;
		// plein printemps: croissance maximale
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 181){
			TimeOfTheYearCorrectionFactor <- 1.0;
		// debut de lete: senescence accrue avec les premieres chaleurs
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 212){
			TimeOfTheYearCorrectionFactor <- TimeOfTheYearCorrectionFactor - 0.009677419;
		// plein ete: forte senescence
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 243){
			TimeOfTheYearCorrectionFactor <- 0.7;
		// debut de lautomne: reprise progressive de la croissance
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 258){
			TimeOfTheYearCorrectionFactor <- TimeOfTheYearCorrectionFactor + 0.006666667;
		// plein automne: thalage des graminees
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 304){
			TimeOfTheYearCorrectionFactor <- 0.8;
		// fin dautomne: reprise de la senescence
		}else if (dateCour.nbJoursEcoulesDansAnnee <= 334){
			TimeOfTheYearCorrectionFactor <- TimeOfTheYearCorrectionFactor - 0.006451613;
		}
		biomass_sheath_species <- min([biomass_above_ground_species, TimeOfTheYearCorrectionFactor * 3.0 * cultureHerbSim_app.BaselineDensity]);
//
	}

	action CalculHarvest (float hauteur_coupe, string type_coupe) { // Remarque NR : 2 calculs du rendement, un par l'espèceHS et un par la cultureHS = pas nécessaire en théorie
		float ResidualBiomassAboveSheath <- 0.0;
		// Définition de la biomasse de la sur-gaine (biomasse située au-dessus de la gaine et en dessous de la hauteur de coupe)
        if (biomass_above_ground_species > biomass_sheath_species){ // si il existe une sur-gaine
        	// calcul de la biomasse de la sur-gaine
        	float a <- 0.00000116501 * YieldCorrectionCoefficient;
    		float b <- 0.00507462472 * YieldCorrectionCoefficient;
    		float c <- 3.0 - cultureHerbSim_app.ResidualHeightHarvest; // la hauteur d'herbe non paturable est fixee a 3 cm // TODO changer le 3cm par la hauteur de coupe LeafSheathHeigth (pas défini pour cultureHerbSim)
 	    	ResidualBiomassAboveSheath <- (-b + sqrt((b^2) - 4.0 * a * c)) / (2.0 * a);
        	if ((biomass_above_ground_species - (biomass_sheath_species + ResidualBiomassAboveSheath)) < 0 ) { // si la biomasse verte est inférieure à la somme gaine + sur-gaine
        		ResidualBiomassAboveSheath <- biomass_above_ground_species - biomass_sheath_species; // -> la biomasse de la sur-gaine est limitée à ce qu'il reste de la biomasse verte hors gaine
        	}
         }
		
		ResidualBiomass <- biomass_sheath_species + ResidualBiomassAboveSheath; // TODO Attention !!! ici on est pas dans le périmètre de vérification qu'il existe bien une sur-gaine

        LeafAreaIndex <- max([0.1,
                RegrowthKSward * 1.9 * ((0.01 * ResidualBiomass / 10.0)^0.73)
                * ResidualBiomass / biomass_above_ground_species]);

        
        // calcul temporaire de la quantité d'azote restante si on calcul différemment l'azote qui sort
        	// version 1 : matcher l'INN
				
				// frolzqhfiuhgeqsgh     
        		//float pourcN_1 <- paramDilMinA * max((ResidualBiomass/1000),1.0)^(-paramDilMinB);
        		//float QN_INN1 <- (pourcN_1/100) * ResidualBiomass;
        		//float QN_INNJ <-  INN_j * QN_INN1;

        		
        	// version 2 :  matcher la quantité d'azote
        
        
        // Calcul de la quantité d'azote dans les différents compartiments des parties aériennes (gaine, sur-gaine, partie fauchée)
        float QN_sheath <- (biomass_sheath_species * C_aer) / cn_sheath; // Qunaité d'azote contenue dans la gaine// TODO mettre le CN ratio de la gaine dans especeHerbSim
        float QN_aer_without_sheath <- QN_aer - QN_sheath; // Quantité d'azote contenue dans la partie aérienne hors gaine
        float QN_residual_above_sheath <- QN_aer_without_sheath * (ResidualBiomassAboveSheath / (biomass_above_ground_species - biomass_sheath_species));// Quantité d'azote contenue dans ResidualBiomassAboveSheath (= partie aérienne sous la hauteur de coupe mais au-dessus de la gaine);

        
        // Calcul de valeurs cumulés pour tout le couvert, concernant les rendements (en biomasse, carbone et azote), et les pertes via les feuilles perdues
        	// cumul du rendement en biomasse de tte les espèces (partie fauchée + perte en feuilles)
        cultureHerbSim_app.cumul_rdt <- cultureHerbSim_app.cumul_rdt + (biomass_above_ground_species - ResidualBiomass);
        	// cumul du rendement en carbone de tte les espèces (partie fauchée + pertes en feuilles); fait ici pour avoir accès facilement au C_aer de l'espèce
        cultureHerbSim_app.cumul_rdt_C <- cultureHerbSim_app.cumul_rdt_C + (biomass_above_ground_species - ResidualBiomass) * C_aer;
        	// cumul de l'azote contenu dans les feuilles perdues pour ttes les espèces
        cultureHerbSim_app.cumul_rdt_N_leaves <- cultureHerbSim_app.cumul_rdt_N_leaves + (((biomass_above_ground_species - ResidualBiomass) * C_aer) * cultureHerbSim_app.HarvestLosses) / CN_LostLeafHarvest ;
        	// cumul de l'azote contenu dans la partie aérienne coupée totale (partie fauchée et exporté + pertes en feuilles)
        cultureHerbSim_app.cumul_QN_aer_fauche <- cultureHerbSim_app.cumul_QN_aer_fauche + (QN_aer - QN_sheath - QN_residual_above_sheath); // 
        // Mise à jour du QN_aer -> soustraction de la partie fauchée
        QN_aer <- QN_sheath + QN_residual_above_sheath;
        
		// Mise à jour de la biomasse aérienne
        biomass_above_ground_species <- ResidualBiomass;
                
        // ajout dune division par 10 car lequation du modele initial est calibree
        // pour une biomasse en g / m2 et non en kg / ha
        ResidualLeafAreaIndex <- LeafAreaIndex;
        if (cultureHerbSim_app.ThermalTime >= ThermalTimeAtStemElongation){
            DefoliationDoneAfterStemElongation <- true;
        }else{ 
        	DefoliationDoneAfterStemElongation <- false;
        }

		// MAJ des autres variables
        LeafAreaIndexGrowth <- 0.0;
		LeafAreaIndexSenescent <- 0.0;
		RadiationUseEfficiency <- 0.0;
		
		
	}			

	action updateDemandeAzote{
		// Formalisme Décembre 2024 (NR) :
		
		BM_rac_prec <- BM_rac;
		QN_aer_prec <- QN_aer; // changer pour QN_aer
		
		
		// * Demande des parties aériennes
		BM_pot <- (biomass_above_ground_species_prec + BiomassGrown) / 1000; // en tonnes
		// * Teneur en azote associée à la courbe de consommation maximale 
		float pourcN_max <- (paramDilMaxA * max(BM_pot,plateau_dilution_n)^(- paramDilMaxB)) / 100 ; // pourcentage ramené à 1
		//write "pourcN_max " + pourcN_max;
		float QN_aer_max <- pourcN_max * BM_pot * 1000; // en kilos d'azote
		demande_max_aer <-  QN_aer_max - QN_aer_prec;
		
		// * Demande en azote des racines
			// 2 cas de figure : avant ou après atteinte de 95% de la biomasse racinaire max
		
		// Cas 1 : Croissance de la biomasse racinaire (avant atteinte des 95%)	
		if(compteur_N_jours < v95_croissance_rac){ // demande pour la croissance et le turnover sur l'incrément de biomasse racinaire
			BM_rac_pot <- BM_rac_max * (1 - exp(- lambda_croissance_rac * (compteur_N_jours + 1)));
			demande_max_rac <- ((BM_rac_pot - BM_rac_prec) * C_rac) / CN_rac; 
		
		// Cas 2 : Plus de demande en azote pour croissance de la biomasse racinaire
		} else { 
			BM_rac_pot <- BM_rac; // pas d'évolution de la biomasse
			demande_max_rac <- 0.0; // pas de demande en azote
			
		}
		
		
		
		// * Demande pour le turnover
		demande_turnover <- (((annual_root_turnover * BM_rac) * C_rac)/ cn_senescent_root)*(1/365); // TODO Chantier : utiliser les degres-jour au lieu des simples jours
		
		// * Demande totale
		demandeAzoteMax <- demande_max_aer + demande_max_rac + demande_turnover ;

	}
	// Ajout de la biomasse senescent au stock du couvert
	action addNSenescent (float BM_senescent){ 
		float QC_senescent <- BM_senescent * C_aer; // Estimation de la teneur en C de la BM senescente
		float QN_senescent <- QC_senescent / cn_senescent_leaf; // Estimation de la teneur en N de la BM senescente
		cultureHerbSim_app.QC_cumul_senescent <- cultureHerbSim_app.QC_cumul_senescent + QC_senescent;
		cultureHerbSim_app.QN_cumul_senescent <- cultureHerbSim_app.QN_cumul_senescent + QN_senescent;
		QN_suivi_plante <- QN_suivi_plante - QN_senescent; // Ajout de la BM senescente au stock du couvert
		// TODO suivi de l'azote sortant : à mettre en sortie !! (comme pour la fauche)
	}

	

	

}
