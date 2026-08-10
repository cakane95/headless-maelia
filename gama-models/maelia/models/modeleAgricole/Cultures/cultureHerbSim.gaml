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

model cultureHerbSim

import "../../modeleCommun/typeDeSol.gaml"
import "especeHerbSim.gaml"

global{
	
	}

species cultureHerbSim  parent:modelDeCulture{

	int anneeCreation <- 0;
	float ThermalAge <- 0.0; //age en somme de temperature en base 0 et max 25° // equivalent a echV
	float ThermalTime <- 0.0;
	float Height      <- 3.0;
	float biomass_above_ground <- 1000.0; // [kg/ha]
	float biomass_sheath <- 0.0; //[kg/ha] Biomasse contenue dans la partie de l'herbe inférieure à 3 cm 
	float biomass_senescent <- 0.0; // Cumul de la biomasse senescente pour toutes les espèces composant la prairie
	float BiomassGrown <- 0.0; // NR Herbsim 16/05/2024 - Cumuler du gain de biomasse journalier sur toutes les espèces de la prairie

	float Yield <- 0.0;
	float YieldPredicted <- 0.0; // TODO A supprimer ?
	
	float cumul_rdt <- 0.0; // Variable utilisée pour le cumul des rdt de chaque espèce, dans l'action  updateHerbeFauche
	float cumul_rdt_N_leaves <- 0.0; // Quantité d'azote contenu dans les feuilles tombant au sol au moment de la fauche; pour toutes les espèces cumulées
	float cumul_QN_aer_fauche <- 0.0; // Quantité d'azote dans la partie aérienne au dessus de la hauteur de coupe, pour toutes les espèces cumulées (comporte aussi les feuilles tombant au sol)
	float cumul_rdt_C <- 0.0; // Variable utilisée pour le cumul du carbone contenu dans la biomasse fauchée pour chaque espèce (teneur en C des feuilles ne varie pas entre espèce pour l'instant, mais pourrais éventuellement)
	
	float CO2CorrectionFactor <- 1.0;
	float BaselineDensity 	  <- 200.0; //kg de biomasse par cm de hauteur - OT
	
	// Pour NC
	float QC_cumul_senescent <- 0.0;
	float QN_cumul_senescent <- 0.0;
	float C_export_fauche <- 0.0; // NR 260924 carbone exporté à la fauche
	float N_export_fauche <- 0.0; // NR 260924 azote exporté à la fauche
	float biomasse_aer_restit_fauche <- 0.0; // NR 260924 biomasse aerienne restitutée au sol à la fauche
		 	
	
	float QN_acquis; // NR Herbsim 16/05/2024 (redéfini et utilisé dans cultureHerbSimNC)
	
	
	float ProportionAlfalfa <- 0.0; //To READ

	map<especeHerbSim,float> compositionVegetation <- map<especeHerbSim,float>([]);  //fraction:groupe
	float CorrectionCoefficient <- 0.0;
	float weightedThermalTimeAtFlowering <- 1500.0;
	
	//temp parametre de gestion
	float ResidualHeightHarvest <- 6.0; //[cm] Valeur arbitraire -> lue dans les rdd
	float HarvestLosses <- 0.05; // [-] fraction : proportion de la biomasse aérienne perdue au moment de la récolte (est restituée au sol)
	float OMD <- 0.0; //Organic Matter Digestibility
	bool isFauche_jourCourant <- false;  // TODO la variable ne passe jamais à true... utilité?
	float ResidualBiomassAbove3cm <- 0.0;
	float ResidualBiomassAfterHarvest <- 0.0;
	float GreenBiomass_beforeHarvest;
	
	float thermal_time_at_germination_culture <- 0.0;
	bool isCultureLevee <- false; // blocage de la croissance de la culture jusqu'à la levee
	float sommeDegresJourCulture_depuisSemis <- 0.0; // Cumul des dd depuis le semis de la culture (Warning : arrêt du cumul au moment de la levée TODO NR 031025

	/*
	 * *****************************************************************************************
	 * Non appelle pour le moment
	 */		
//	action comportementJournalier{			
//		do croissanceCulture;
//	}
		
	action initialisationCulture{
		anneeCreation <- dateCour.annee;
		//compositionVegetation
		
		
		//fraction <- ??

		ask especeHerbSim(espece) {
			self.cultureHerbSim_app <- myself;
			do initialisationVegetation();
			put 1.0 at: self in: myself.compositionVegetation ;
		}

//		create alfalfa{				
//			cultureHerbSim_app <- myself;
//			//fraction <- ??
//			do initialisationVegetation();		
//			put 1.0 at: especeHerbSim(self) in: myself.compositionVegetation ;	
//		}
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
		
		loop vege over: compositionVegetation.keys{ // Détermination du nombre de DD avant germination de la culture (date la plus précoce parmi les espèces)
			thermal_time_at_germination_culture <- min(thermal_time_at_germination_culture,vege.thermal_time_at_germination_species);
		}
	}	
	
		

	/*
	 * *****************************************************************************************
	 * MODELE HerbSim ; Adapatation du code de AqYield de façon à simuler l'implentation des prairies
	 * On considere qu'il 1.5 an pour atteindre RUm, si on considère 4000°C /an et un sol de 150 mm de RU
	 * on veut approximativement augmenter de 150 mm sur 6000°C, on approxime donc espece.croissanceRacineCult
	 * a (1500 + 4500 * 0.5)/150 = 25 °/mm
	 * Appelee dans parcelle
	 */		 
	 float calculReserveAccessibleRacine (float RUrPrecEntree, float noteQualiteStructureSolEntree ){	
		// 2 -RUr (reserve utile accessible aux racines)
//		float RUr <- 0.0;
//		if(echV <= 1.0){ // avant floraison
//			RUr <- ThermalAge  / (espece.croissanceRacineCult/noteQualiteStructureSolEntree); //  * 7.5
//			//write espece.idEspeceCultivee;
//			//write espece.croissanceRacineCult;
//		}else{
//			RUr <- RUrPrecEntree + 0.5 * parcelle_app.getTmoy() / (25.0/noteQualiteStructureSolEntree);
//		}
		//return RUr;
		float new_RUr <- 0.0;
		loop vege over: compositionVegetation.keys{
			// NR 2025 : changement façon de calculer la profondeur des racines
			float new_RUr_espece <- (vege.BM_rac/vege.BM_rac_max) * parcelleAqYield(parcelle_app).RUr_max;
			new_RUr <- max(new_RUr,new_RUr_espece); // On conserve la profondeur la plus grande parmi les espèces
		}
		return max([new_RUr, RUrPrecEntree]); 			
	 }
	
	/*
	 * *****************************************************************************************
	 * MODELE HerbSim
	 * Appelee dans parcelle
	 */		 
	 action verifLevee{
	 	if (!isCultureLevee){ // La prairie n'a pas encore levé
	 		float DegresJourCulture <- min([25, parcelle_app.getTmoy()]);  // espece.tmax = 25 // source = fichier especesCultivees pour alfalfa A NETTOYER
            DegresJourCulture <- max([0, DegresJourCulture - 0]); // espece.base = 0 // source = fichier especesCultivees pour alfalfa A NETTOYER
	 		sommeDegresJourCulture_depuisSemis <- sommeDegresJourCulture_depuisSemis + DegresJourCulture;
	 		if(sommeDegresJourCulture_depuisSemis > thermal_time_at_germination_culture){isCultureLevee <- true;}}
	 }
	 
	 action croissanceCulture{		
	 	if (isCultureLevee){
	 		
			// Si encore une fauche prévue, mise à jour de la hauteur de fauche pour estimer le rendement d'après cette hauteur
			if (parcelle_app.faucheMultipleCourant != nil) {
				ResidualHeightHarvest <- parcelle_app.faucheMultipleCourant.hauteurCoupe;
			} else {
				ResidualHeightHarvest <- 100000.0; // Empeche le déclenchement d'une fauche si pas d'OT prévue à cet effet
			}
			
			
			// Pas de fauche aujourd'hui
		 	if !isFauche_jourCourant { // TODO la variable ne passe jamais à true... utilité?
		    	Yield <- 0.0;
		 		
		 		if (dateCour.nbJoursEcoulesDansAnnee =31) or (dateCour.nbJoursEcoulesDansAnnee =1){
			 		ThermalAge <- 0.0;
			 		ThermalTime <- 0.0;
			 	}else{
			 		//getTmax
			 		float deltaEchelleVegetation <- (max([min([parcelle_app.getTmax(), 25.0]),0.0])+
								 max([min([parcelle_app.getTmin(), 25.0]),0.0])
		        			 )/2.0;
			 		ThermalAge <- ThermalAge + deltaEchelleVegetation;
			 		ThermalTime <- ThermalTime + deltaEchelleVegetation; 	
			 	}
			 	echV <- ThermalAge/weightedThermalTimeAtFlowering;
			 				 			
			 	do calculBiomassAndKc();	
		 	}       
		 	
			do changementCouleurEnFonctionEtatVegetation();
		 }
	}
	 
	 float calculRendement {
	 	// Définition de la biomasse de la sur-gaine (biomasse située entre la gaine et la hauteur de coupe)
	 	if (biomass_above_ground <= biomass_sheath){ // si la biomasse verte totale est égale (ou inf.) à la biomasse de la gaine -> il n'existe pas de sur-gaine
	        	ResidualBiomassAbove3cm <- 0.0; // Biomasse de la sur-gaine à 0
	        } else { // si il existe une sur-gaine
	        	// calcul de la biomasse de la sur-gaine
	        	float a <- 0.00000116501 * CorrectionCoefficient;
	    		float b <- 0.00507462472 * CorrectionCoefficient;
	    		float c <- 3.0 - ResidualHeightHarvest; // la hauteur d'herbe non paturable (gaine) est fixee a 3 cm
	 	    	ResidualBiomassAbove3cm <- (-b + sqrt((b^2) - 4.0 * a * c)) / (2.0 * a);
	        	if ((biomass_above_ground - (biomass_sheath + ResidualBiomassAbove3cm)) < 0 ) { // si la biomasse verte est inférieure à la somme gaine + sur-gaine
	        		ResidualBiomassAbove3cm <- biomass_above_ground - biomass_sheath; // -> la biomasse de la sur-gaine est limitée à ce qu'il reste de la biomasse verte hors gaine
	        	}
	         }
	
	        ResidualBiomassAfterHarvest <- biomass_sheath + ResidualBiomassAbove3cm;
	        YieldPredicted <- (biomass_above_ground - ResidualBiomassAfterHarvest) * (1.0 - HarvestLosses);

		return YieldPredicted;
	 } // fin de calculRendement

	 action calculBiomassAndKc{
	 	if (dateCour.nbJoursEcoulesDansAnnee = 2){
	 		ask compositionVegetation.keys{
	 			do initialisationVegetation();
	 		}
	 	}
	 	
	 	ask compositionVegetation.keys{
	 		do calculBiomass(); // Calcul de la croissance pour chaque espèce (ou groupe fonctionnel) du couvert
	 	}
	 	do updateBiomassHeightKc(); // Cumul de la croissance pour l'ensemble du couvert
	 }
	 
	 action updateBiomassHeightKc{

	 	biomass_above_ground <- 0.0; // NR - Remise à 0 ici car on garde trace de la biomasse dans le groupe fonctionnel et pas la cultureHerbSim
	 	biomass_sheath <- 0.0; // NR - Remise à 0 ici car on garde trace de la biomasse dans le groupe fonctionnel et pas la cultureHerbSim
	 	BiomassGrown <- 0.0;   // NR Herbsim 16/05/2024 - Remis à 0 car on cherche juste à connaitre la biomasse qui as poussé sur le pas de temps journalier (cumul ci-dessous pour toutes les espèces prairiales)
	 	kc <- 0.0;
	 	Height <- 0.0; // NRRM Herbsim 170925 Hauteur de l'espece herbsim la plus haute sur la parcelle
	 	
	 	loop vege over: compositionVegetation.keys{
	 		biomass_above_ground <- biomass_above_ground + vege.biomass_above_ground_species * vege.fraction;
	 		biomass_sheath <- biomass_sheath + vege.biomass_sheath_species * vege.fraction;
	 		BiomassGrown <- BiomassGrown + vege.BiomassGrown * vege.fraction;

	 		float BiomassUpTo3cm <- vege.biomass_above_ground_species - vege.biomass_sheath_species;
	 		float heightVege <- 0.0;
	 		if(vege.biomass_above_ground_species > vege.biomass_sheath_species){
				heightVege <- 3.0 + ((0.00000116501 * (BiomassUpTo3cm^2)) + (0.00507462472 * BiomassUpTo3cm)) * vege.YieldCorrectionCoefficient;
			}else{
				heightVege <- 3.0;
			}
	 		
	 		// Modification de la hauteur maximale de l'herbe
	 		if (heightVege > Height) {
	 			Height <- heightVege;
	 		}
	 		
	 		kc <- kc + max([0.1, min([heightVege/vege.hauteurPourKc1,coefCulturalEva])])*vege.fraction;
	 		kc_flo <- kc;
	 	}
	 }
	 
	// FAUCHE // TODO à revoir car probablement cassé 170625
	 action updateHerbeFauche (float hauteur_coupe) {
	 		
	 		Yield <- YieldPredicted;
//	 		write "FAUCHE Rendement de la fauche = " + Yield;
	    	ask compositionVegetation.keys{
		 		do CalculHarvest(hauteur_coupe, "fauche");
		 	}
		 	
		 	GreenBiomass_beforeHarvest <- biomass_above_ground;
		 	biomass_above_ground <- ResidualBiomassAfterHarvest;
		 	parcelle_app.ilot_app.agriculteurAssocie.sonExploitation.stockHerbeFauchee <- parcelle_app.ilot_app.agriculteurAssocie.sonExploitation.stockHerbeFauchee + Yield;
		 	do updateBiomassHeightKc();
	 }
	 
	 // PATURE
	 action updateHerbePature (float herbePreleveeParha) {
//		 	write "biomasse avant prélèvement = " + getBiomasseAboveGround() * (parcelle_app.surface / 10000);
//		 	write 'besoins par ha = ' + herbePreleveeParha;
		 	// Consommation de l'herbe
			loop vege over: compositionVegetation.keys {
				vege.biomass_above_ground_species <- vege.biomass_above_ground_species - (herbePreleveeParha * vege.fraction);
			}
		 	
		 	// Update des variables générales de l'herbe
		 	do updateBiomassHeightKc();
//		 	write "biomasse après prélèvement = " + getBiomasseAboveGround() * (parcelle_app.surface / 10000);
		 	
	 }
	 
	 float getBiomasseAboveGround {
	 	float result <- 0.0;
		loop vege over: compositionVegetation.keys {
			result <- result + vege.biomass_above_ground_species;
		}
	 	return result;
	 }
	 
	 action calculIndiceSatisfactionHydrique{

	 	// JV 221019 add a test on RUrPrec=RUsPrec to avoid division by zero that may occur in some (rare) cases. (see Mantig bug #0002361)
	 	if(parcelleAqYield(parcelle_app).RUrPrec = parcelleAqYield(parcelle_app).RUsPrec){
	 		indiceSatifactionHydrique <- max([0.0, 1 - abs(1-(parcelleAqYield(parcelle_app).Hs)/(parcelleAqYield(parcelle_app).RUsPrec))^(parcelleAqYield(parcelle_app).ilot_app.sol.ctr_m)]);
	 	}
	 	else{
	 	indiceSatifactionHydrique <- max([0.0, 1 - abs(1-(parcelleAqYield(parcelle_app).Hr-parcelleAqYield(parcelle_app).Hs)
	 			/ (parcelleAqYield(parcelle_app).RUrPrec - parcelleAqYield(parcelle_app).RUsPrec)
	 			) ^ (parcelleAqYield(parcelle_app).ilot_app.sol.ctr_m)]);					
		}
	 	
	 	// Pour info
		// float MinFTSWForUndisturbedGrowth <- 70.0; //MinFractionOfTranspirableSoilWaterForUndisturbedGrowth
		// float MinFTSWForGrowth <- 40.0; //MinFractionOfTranspirableSoilWaterForGrowth
	 	
//	 	float FractionTranspirableSoilWater <- sqrt(parcelleAqYield(parcelle_app).Hr * parcelleAqYield(parcelle_app).Hs / (parcelleAqYield(parcelle_app).RUr * parcelleAqYield(parcelle_app).RUs)) ;
//	 	float minFTSWForGrowthPercent <- MinFTSWForGrowth / 100.0;
//	 	float minFTSWForUndisturbedGrowthPercent <- MinFTSWForUndisturbedGrowth / 100.0;
//		if (FractionTranspirableSoilWater >= minFTSWForUndisturbedGrowthPercent){
//			indiceSatifactionHydrique <- 1.0;
//		}else{
//			if (FractionTranspirableSoilWater <= minFTSWForGrowthPercent){
//				indiceSatifactionHydrique <- 0.0;
//			}else{						
//				indiceSatifactionHydrique <- (FractionTranspirableSoilWater - minFTSWForGrowthPercent)/ (minFTSWForUndisturbedGrowthPercent - minFTSWForGrowthPercent);	
//			}
//		}
	 }
	 
//		 bool isEnStressHydrique{	
//			return false;
//		}
//		 
	// Fonction de calcul de la digestibilité de l'herbe
	action calculationOMD{
		float nutrIndex <- min([0.8,parcelleAqYield(parcelle_app).NutrientIndex]); //on borne l'INN a 0.8
		
	}

	 
	 /*
	 * *****************************************************************************************
	 * 
	 */
	action majPourCalculRendement{
	}
	 
	/*
	 * *****************************************************************************************
	 * TODO : definir la variable concerne
	 */		 
	 action changementCouleurEnFonctionEtatVegetation{					
//			if(kc < 0.001){
//				set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at 0;
//			}else{
//				set couleurCoefficientCultural value: paletteCouleursCoefficientCultural at (int(kc * 10));
//			}
	 }
	 
}
