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
 *  parcelleAqYield
 *  Author: Maroussia Vavasseur
 *  Description: Les parcelles AqYield sont les parcelles creees dans le cas ou le modele de croissance des plante est le modele AqYield
 */

model parcelleAqYield

import "../Cultures/cultureAqYieldNC.gaml"
 
global {	
//	string parcellesAqYieldShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/zoneMaelia/parcelles_Utiles_2009.shp';
	
	/* 
	 * *****************************************************************************************
	 * Private
	 */
	action constructionParcellesAqYield{
		listeParcelles <- lectureFichierParcelle(cheminEntree:parcellesShape, typeParcelle:parcelleAqYield);
	}				
} 


species parcelleAqYield parent: parcelle {
	//*************************************************
	// Debug
	int essai_ferti_cpt <- 0;
	float repartN_cumul <- 0.0;
	//*************************************************
	
	parcelleAqYieldNC myParcelleAqYieldNC <- nil;
	
	float RUw <- 0.0; // [mm]
	float RUm <- 0.0; // [mm]
	float RUr <- 0.0; // mapReserveUtileAccessibleRacines  [mm]
	float RUs <- 0.0; // mapReserveUtileHorizonSurface  [mm]
	float Hs  <- 0.0; // mapHauteurReserveUtileHorizonSurface [mm]
	float Hm  <- 0.0; // mapHauteurReservePotentielleUtileMax  [mm]
	float Hr  <- 0.0; // mapHauteurReserveUtileAccessibleRacines(j)  [mm]
	float Hw  <- 0.0; // mapHauteurTravail  [mm]
	float Ccap <- 0.0; // mapCoefCapilarite(j)  [mm]	
	float capilarite <- 0.0; // cap(j)  [mm]						
	float RUrPrec <- 0.0; // mapReserveUtileAccessibleRacines  [mm]
	float RUsPrec <- 0.0; // mapReserveUtileHorizonSurface  [mm]
	float HmPrec <- 0.0; // mapHauteurReservePotentielleUtileMax  [mm]
	float HwPrec <- 0.0;
	float HPFs_mm <- 0.0; // Hauteur d'eau à HPF calculée à partir de HCC et de la RU
	float RUr_max <- 0.0; // RU maximale explorable par les racine [mm] --> actualisé par chaque culture à son init // Renaud 26052023
		
	float apportEnEauUtile <- 0.0; // PIRj
	float evaporation <- 0.0; // eva
	float transpirationW <- 0.0; // TRw
	float transpirationR <- 0.0; // TRr 
	float coefRuissellement <- 0.0;

	float reserveUtileHorizonSurfaceW1 <- 7.0 ; // RUSw1 = 7mm
	
	// Variables pour enregistrement (quick and dirty...) -> cf. resultatsRDT_exploitation_espece
	string derniere_culture_recoltee <- "";
	float dernier_rendement <- 0.0;
	float humiditeSolRacineVeille <- 0.0; // JV 190120 pour sortie resultatsModeleAqYield_light pour Myriam: valeur de getHumiditeSolRacine() de la veuille (MAJ dans remiseAzeroParcelle), à virer ?par la suite ?
	
	//------------------------------------------------------------//
	// Parameter for the HerbSim model 							  //
	
	//part for comparison with herbSim
	float AvailableSoilWater <- 0.0; //[mm]
	float ActualEvapoTranspiration <- 0.0;//[mm]
	float FractionTranspirableSoilWater <- 1.0; //[-]
	
	
	// part to keep
	float NutrientIndex <- 0.0; //[-]
	float AdjustedNitrogenIndex <- 0.0;
	
	// TO GET IN INPUT
	float NitrogenIndex <- 1.0; //[-] //à lire en entree [0,1]
//	float NitrogenIndexInit <- 0.75; //[-] //à lire en entree
	float PhosphorusIndex <- 1.0; //[-] // a lire en entree [0,1]
	float TotalTranspirableSoilWater <- 100.0;
		
	 // JV 120422 variables pour les fichiers de sorties: 1 élément de liste par couvert pendant l'année, liste de couverts définie dans parcelle	
	 list<float> sorties_evaporation; // [mm] cumul de l'évaporation des sols sur la période de couvert (parcelleAqYield.evaporation)
	 list<float> sorties_transpiration; // [mm] cumul de la transpiration des plantes sur la période de couvert (parcelleAqYield.transpirationR)
	 list<float> sorties_percolation; // [mm] cumul de la percolation sur la période de couvert (parcelleAqYield.calculEcoulementEauSouterraine())
	 list<float> sorties_capilarite; // [mm] cumul des remontées capilaires sur la période de couvert (parcelleAqYield.capilarite)
	 list<float> sorties_ruisselement; // [mm] cumul du ruisselement de surface MD 30082023
	 list<float> sorties_Hr_debut; // [mm] Eau dans le sol au début de la période horizon racinaire (parcelleAqYield.Hr jour du semis)
	 list<float> sorties_Hm_debut; // [mm] Eau dans le sol au début de la période profondeur totale du sol (parcelleAqYield.Hm jour du semis)
	 list<float> sorties_Hr_fin; // [mm] Eau dans le sol à la fin de la période horizon racinaire (parcelleAqYield.Hr jour de la récolte)
	 list<float> sorties_Hm_fin; // [mm] Eau dans le sol à la fin de la période profondeur totale du sol (parcelleAqYield.Hm jour de la récolte)
	 list<float> sorties_Hr_1janv; // [mm] Eau dans le sol au 1er janvier horizon racinaire (parcelleAqYield.Hr 1er janvier)
	 list<float> sorties_Hm_1janv; // [mm] Eau dans le sol au 1er janvier profondeur totale du sol (parcelleAqYield.Hm 1er janvier)
	 list<float> sorties_satisfactionHydrique; // [%] moyenne du pourcentage de satisfaction hydrique sur la période de couvert (parcelleAqYield.cultureParcelle.monModeleDeCulture.calculIndiceSatisfactionHydrique())
	 list<float> sorties_pluie; // [mm] cumul des précipitations (parcelle.getPluie())
	 list<float> sorties_irrigation; // [mm] cumul des doses d'irrigation réelle (parcelle.irrigationReelle)
	 list<float> sorties_sommeDegresJourCulture; // [°C] somme degrés jour (base culture) (parcelleAqYield.cultureParcelle.monModeleDeCulture.sommeDegresJourCulture)	 
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Initialisation
	 */
	action initialisationDonneesSol {
		// AQYIELD
		//coefRuissellement <- ((ilot_app.penteAssociee/ 100)^2) ; //RL 17/05/17 : correction de la formule pour que 
			//ce coeff soit compris entre 0 et 1 

		coefRuissellement <- (ilot_app.penteAssociee^2/ 100) ; // JV 06/11/17 retour à l'ancienne formule CR = Pente² / 100 suite à demande G. Obiang-Ndong (Mantis #1145)
		if(coefRuissellement>1){
			coefRuissellement <- 1.0;
		} 

		RUm <- ilot_app.sol.reservePotentielleUtileMax;
		RUw <-  RUm / self.ilot_app.sol.profondeurMax * self.ilot_app.sol.profHum; //ilot_app.sol.reservoirHorizonTravailProfond; --> Modifié pour coller à AqYield excel (22/05/18)
		RUr <- RUw; // ilot_app.sol.reservoirHorizonTravailProfond; -->  Modifié pour coller à AqYield excel (22/05/18)
		RUs <- RUw * 0.95; // RUw -1.0; --> Modifié pour coller à AqYield excel (18/05/18)
		Hm <- 0.8 * ilot_app.sol.reservePotentielleUtileMax;
		Hw <- 0.8 * RUw;//ilot_app.sol.reservoirHorizonTravailProfond -> RUw cor hugues
		Hr <- Hw;
		Hs <- Hw * RUs / RUw;//ilot_app.sol.reservoirHorizonTravailProfond -> RUw cor hugues
		

		
		HPFs_mm <- self.ilot_app.sol.HCCw * self.ilot_app.sol.daH1 * RUs / RUw * self.ilot_app.sol.profHum / 10 - RUs;
		
		reserveUtileHorizonSurfaceW1 <- horizonDeTravailSuperficiel / 10.0 * (1.0 - self.ilot_app.sol.tauxGravier / 100) *
		 (12.0 + 39.0 * (self.ilot_app.sol.clay / 100) - 64.0 * ((self.ilot_app.sol.clay / 100)^2));
		
		
		//HerbSim
		AvailableSoilWater <- 2 * TotalTranspirableSoilWater / 3;
	    ActualEvapoTranspiration <- 0.0;
	    NutrientIndex <- ((2 * 0.75 * NitrogenIndex) + PhosphorusIndex) / 3;
			 
	}
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Appellee depuis ilot
	 */			
	action remiseAzeroParcelle{
		irrigationSouhaitee <- 0.0;
		irrigationReelle <- 0.0;
		
		// Remise a zero les variables daffichage
		etatIrrigationParcelle <- ETAT_PAS_IRRIGATION_DEMANDEE;
		
		// MAJ humiditeSolVeille
		humiditeSolRacineVeille <- getHumiditeSolRacine();
		
		// Remise a zero variables AqYield
		RUrPrec <- RUr;
		RUr <- 0.0;
		RUsPrec <- RUs;
		RUs <- 0.0;
		
//			if((getITKAnnee().especeCultiveeITK).idEspeceCultivee ="prairiep" and (nomChoixModeleCroissancePrairie="HerbSim")){
//				if (dateCour.nbJoursEcoulesDansAnnee <=1){
				//do initialisationDonneesSol();
//				}
//			}
		
	}


	/* 
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort en surface apres la croissance de la plante
	 */
	float calculQuantiteEauDeRuissellement{		
		
		// 1 -RUr
		if (cultureParcelle != nil){
			ask cultureParcelle.monModelDeCulture{
				myself.RUr <- calculReserveAccessibleRacine(RUrPrecEntree:myself.RUrPrec, noteQualiteStructureSolEntree:myself.ilot_app.sol.noteQualiteStructureSol);			
			}
		}
		//RUr <- min([RUm, RUr]);
		RUr <- min([RUr_max, RUr]); // Renaud 300523
		RUr <- max([RUw, RUr]);

		// 2 -RUs
		// Si il ny a pas eu de travail du sol
		if(!isTravailSolJourCourant){
			if (isPrairiePermanente) { // Si prairie permanente alors RUs ne change pas //Renaud 03/06/2024
				RUs <- RUsPrec;
			} else {
				RUs <- RUsPrec * float(1-pluieEtIrrigation/ilot_app.sol.coefStabiliteCultural); //[mm]
			}
			
			prof_w_sol <- 0.0; // TODO Supprimer  --> Ajout Renaud 30/05/18 (cf strategieOT.gaml)
		}else{	
			isTravailSolJourCourant <- false;
		}
		float RUsmin <- 8.0; // Modifié Hélène (29/05/18) : passage de 5.0 à 8.0
		RUs <- max([RUsmin, RUs]);
	
		// 3 -ruis
		quantiteEauDeRuissellement <- max([0.0, ((pluieEtIrrigation - ilot_app.sol.permeabiliteSol * (min([1.0, RUs/reserveUtileHorizonSurfaceW1]))) * coefRuissellement)]); // [mm]

		return quantiteEauDeRuissellement; // [mm]
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEvapoTranspiration{
//			if ((getITKAnnee().especeCultiveeITK).idEspeceCultivee ="prairiep") and (nomChoixModeleCroissancePrairie="HerbSim"){
//				do calculNutritionIndex();
//				if (cultureParcelle != nil){
//					float tmp <- calculEvapoTranspirationHerbSim();
//					
//					ask cultureParcelle.monModelDeCulture{
//						do croissanceCulture();	
//					}
//					return tmp;
//				}else{
//					evaporation <- ilot_app.meteo.etp * (float((Hs/RUs)*ilot_app.sol.coefCC + 1 - ilot_app.sol.coefCC)^coefEvaSurRUs);
//					return evaporation;
//				}
//			}else{
		do calculNutritionIndex();
		return calculEvapoTranspirationAqYield();
//			}		
	}
	
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	// JV 290920: code entierement reprise de la version GAMA 1.7 de Renaud
	float calculEvapoTranspirationAqYield{	
		
	 	// 1 -Evaporation
	 		// Pour HerbSimNC :
	 	if(cultureParcelle != nil and string(species(cultureParcelle.monModelDeCulture))= "cultureHerbSimNC"){ // TODO à adapter pour HerbSim
	 		RUsPrec <- max([8.0,RUsPrec]);
	 		evaporation <- ilot_app.meteo.etp * max([1-cultureParcelle.monModelDeCulture.kc, 0.0]) * (max([float(Hs/RUsPrec*ilot_app.sol.coefCC + 1 - ilot_app.sol.coefCC), 0.0])^2);
			
	 	} else {
	 		// Pour autres situations que HerbSimNC (pas de culture ou cultureAqYield
	 		float coefKc <- 0.0;
			if (cultureParcelle != nil){		
//				coefKc <- getKc() / coefCulturalEva;// [m3] Ancienne méthode (sans prise en compte de la valeur de echV) modif_feuillage
				if (getEchelleVegetation() < 1 or cultureParcelle.espece.abscission > 0){ //modif_feuillage Modifié avec Hélène, abscission modifié avec Laurène
					coefKc <- getKc() / coefCulturalEva;
				} else {
					// Si echV est supérieure ou égale à 1 on utilise KcFlo (Kc au moment de la floraison, au moment où echV = 1)
					coefKc <- getKc_flo() / coefCulturalEva;
				}
			}
			RUsPrec <- max([8.0,RUsPrec]);
			evaporation <- ilot_app.meteo.etp * max([1-coefKc, 0.0]) * (max([float(Hs/RUsPrec*ilot_app.sol.coefCC + 1 - ilot_app.sol.coefCC), 0.0])^2); //coefEvaSurRUs
	 	}
	 		 	
	 	// 2 -Transpiration
		if (cultureParcelle != nil){
			ask cultureParcelle{
				monModelDeCulture.transpirationMax <- (myself.ilot_app.meteo.etp - myself.evaporation) * myself.getKc();	
				ask monModelDeCulture{
					do calculIndiceSatisfactionHydrique();
				}	
				// Calcul de Kc
				ask monModelDeCulture{
					do verifLevee();
					do croissanceCulture();
				}
				myself.transpirationR <- monModelDeCulture.getTranspirationR();	
				 
			}
			// rdv Hélène 03/04/18 -> Référence doc : modif_transpirationW  
			if(Hr > 0.0){
				transpirationW <- transpirationR * Hw / Hr;
			}
			transpirationW <- max([0.0, transpirationW]); // Modifié avec Hélène 03/04/18 Partie ajoutée pour modif_transpirationW 
		} else {	
			transpirationW <- 0.0;
			transpirationR <- 0.0;
		}
			 			 	
	 	// 3 -Ccap
	 	Ccap <- Ccap + max([0.0, (1-Ccap)]) * apportEnEauUtile / coefCeva;
		
		// Supprimer Renaud 31/05/18 avec Hélène pour coller avec excel
		capilarite <- max([0.0, Ccap * (Hw/RUw - Hs/RUsPrec)]); 
		//Hw <- Hw - capilarite;
		//Hs <- Hs + capilarite;
			 	
	 	// 4 -Hw
	 	apportEnEauUtile <- max([0.0, pluieEtIrrigation - quantiteEauDeRuissellement]); // PIRj
	 	HwPrec <- Hw;
	 	Hw <- Hw + apportEnEauUtile - evaporation - transpirationW; // Hw <- max([1.0,Hw + apportEnEauUtile - evaporation - transpirationW]); // Supprimer Renaud 05/06/2018 --> pas besoin de borne inférieure
	 	Hw <- max([min([RUw, Hw]),0.0]);//Hw <- min([RUw, Hw]) correction sinon Hw peut devenir négatif ???
		
	 	// 5 -Hs
	 	float tauxHumiditeW <- (HwPrec/RUw - Hs/RUsPrec); // delta(tx_hum_w)/s(j-1)
	 	float humiditeW <- HwPrec - Hs; // delta(hum_w)
		if(RUs > RUsPrec){
			Hs <- (Hs + apportEnEauUtile - evaporation) + (Ccap * tauxHumiditeW) + (humiditeW * (RUs-RUsPrec) / (RUw-RUsPrec));				
		} else {
			Hs <- (Hs + apportEnEauUtile - evaporation) + (Ccap * tauxHumiditeW);				
		}
		Hs <- max([RUs - RUs / ilot_app.sol.coefCC, Hs]);

		Hs <- max([min([RUs, Hs]), 0.0]);//Hs <- min([RUs, Hs]) correction hugues sinon Hs peut devenir négatif ???
		
		HPFs_mm <- self.ilot_app.sol.HCCw * self.ilot_app.sol.daH1 * RUs / RUw * self.ilot_app.sol.profHum / 10 - RUs;


		// 6 -Hr (si pas culture, pas forcement pertinent ...)			
		if (RUr = RUw){// <= (RUw  + 0.1) and RUr >= (RUw  - 0.1)){
			Hr <- Hw;
		} else if (RUr > RUrPrec){
			Hr <- Hr + apportEnEauUtile - evaporation - transpirationR + (RUr-RUrPrec) * (Hm-Hr) / (RUm-RUrPrec);	
		} else {
			Hr <- Hr + apportEnEauUtile - evaporation - transpirationR;					
		}
		Hr <- min([RUr, Hr]);
		Hr <- max([0.0, Hr]);
		
		// 7 -Hm
		HmPrec <- Hm;
		Hm <- min([RUm, Hm + apportEnEauUtile - evaporation - transpirationR]);		
		Hm <- max([0.0, Hm]);

		return (evaporation + transpirationR); // [m]
	}

	action calculNutritionIndex{ // NR 030624 Uniquement pour Herbsim: A revoir pour HerbSimNC (à basculer ailleurs...)
		// --------------------------------
		// calcul de l'indice de stress mineral
		// --------------------------------
		
		
		switch dateCour.mois {
			match_one [2, 3] { 
				AdjustedNitrogenIndex <- 1.004237 * AdjustedNitrogenIndex;
			}
			match_one [4, 5, 6] { 
				AdjustedNitrogenIndex <- NitrogenIndex;
			}
			match 7 {
				if (dateCour.jour <=15){
					AdjustedNitrogenIndex <- 0.99 * AdjustedNitrogenIndex;
				}else{
					AdjustedNitrogenIndex <- 0.85 * NitrogenIndex;
				} 
			}
			match 8 { 
				if (dateCour.jour <=15){
					AdjustedNitrogenIndex <- 0.85 * NitrogenIndex;
				}else{
					AdjustedNitrogenIndex <- 1.011290 * AdjustedNitrogenIndex;
				} 
			}
			match 9 { 
				if (dateCour.jour <=15){
					AdjustedNitrogenIndex <- 1.011290 * AdjustedNitrogenIndex;
				}else{
					AdjustedNitrogenIndex <- 1.2 * NitrogenIndex;
				} 
			}
			match 10 { 
				if (dateCour.jour <=30){
					AdjustedNitrogenIndex <- 1.2 * NitrogenIndex;
				}else{
					AdjustedNitrogenIndex <- 0.987143 * AdjustedNitrogenIndex;
				} 
			}
			match 11 { 
				AdjustedNitrogenIndex <- 0.987143 * AdjustedNitrogenIndex;
			}
			default { //(1 et 12) Janvier et decembre
                		AdjustedNitrogenIndex <- 0.75 * NitrogenIndex;                         
            		}
		}

		AdjustedNitrogenIndex <- max([0.0, min([1.0, AdjustedNitrogenIndex])]);    
		NutrientIndex <- (2 * AdjustedNitrogenIndex + PhosphorusIndex) / 3;

	}

	// RL 06/10/2016 Fonction a supprimer. Elle a ete code pour valider le codage d'HerbSim
	float calculEvapoTranspirationHerbSim{

		// --------------------------------
		// calcul ASW du jour j en tenant compte de la presence de luzerne
		// --------------------------------
		float NonAdjustedAvailableSoilWater <- AvailableSoilWater + pluieEtIrrigation - ActualEvapoTranspiration;
		if ( cultureHerbSim(cultureParcelle.monModelDeCulture).ProportionAlfalfa <= 0.0){
			AvailableSoilWater <- max([0.0, min([NonAdjustedAvailableSoilWater, TotalTranspirableSoilWater])]);
		}else{
	 		AvailableSoilWater <- max([0.0, min([NonAdjustedAvailableSoilWater, TotalTranspirableSoilWater * 1.3])]);
		}
		// --------------------------------
		// calcul de la fraction d'eau transpirable du sol
		// --------------------------------
		if (cultureHerbSim(cultureParcelle.monModelDeCulture).ProportionAlfalfa > 0.0) {
			FractionTranspirableSoilWater <- min([1.0, AvailableSoilWater / TotalTranspirableSoilWater]);
			// min (1... pour tenir compte de la correction du TTSW dans
			// updateAvailableSoilWater qui peut conduire a un ASW > TTSW
			// or on veut juste reproduire la moindre sensibilite de la luzerne
		}else{
			FractionTranspirableSoilWater <- AvailableSoilWater / TotalTranspirableSoilWater;
		}
		// --------------------------------
		// calcul de l'evapotranspiration reelle
		// --------------------------------
		float minFTSWForUndisturbedGrowth <- MinFTSWForUndisturbedGrowth / 100.0;
		if (FractionTranspirableSoilWater < minFTSWForUndisturbedGrowth){
			ActualEvapoTranspiration <- FractionTranspirableSoilWater * ilot_app.meteo.etp / minFTSWForUndisturbedGrowth;
		}else{
			ActualEvapoTranspiration <- ilot_app.meteo.etp;
		}
		// --------------------------------
		// calcul de l'indice de stress hydrique
		// --------------------------------
		float minFTSWForGrowthPercent <- MinFTSWForGrowth / 100.0;
		if (FractionTranspirableSoilWater >= minFTSWForUndisturbedGrowth){
			(cultureParcelle.monModelDeCulture).indiceSatifactionHydrique <- 1.0;
		}else{ if (FractionTranspirableSoilWater <= minFTSWForGrowthPercent){
				(cultureParcelle.monModelDeCulture).indiceSatifactionHydrique <- 0.0;
			}else{
				(cultureParcelle.monModelDeCulture).indiceSatifactionHydrique <-
					(FractionTranspirableSoilWater / (minFTSWForUndisturbedGrowth + minFTSWForGrowthPercent))
					+ (minFTSWForGrowthPercent * (minFTSWForUndisturbedGrowth + minFTSWForGrowthPercent));
			}
		}
		
		return ActualEvapoTranspiration; // [m]
	}



	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEcoulementEauSouterraine{		
	 	// 4 -Calcul du drain -> bilan hydrique
	 	drain <- max([0.0, HmPrec + apportEnEauUtile - evaporation - transpirationR - ilot_app.sol.reservePotentielleUtileMax]);	
		return drain; // [mm]
	}


	float getFrein{// frein
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureAqYield(cultureParcelle.monModelDeCulture).frein;
		}
		return resultat;
	}
	float getTranspirationMax{// TM
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.transpirationMax;
		}
		return resultat;
	}
	float getEchelleVegetation{ // echV
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.echV;
		}
		return resultat;
	}
	float getTR_M{ // TR_M
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.indiceSatifactionHydrique;
		}
		return resultat;
	}
	float getHumiditeSol{ // %
		float result <- 0.0;
		if(RUw != 0.0){ // JV 110919: RUw when getHumiditeSol is called in a data/value part of a launcher, it is called at initialisation when RUw=0
			result <- Hw / RUw;
		}
		return result;
	}
	float getHumiditeSolRacine{ // %
		float result <- 0.0;
		if(RUrPrec != 0.0){ // JV 110919: RUrPrec when getHumiditeSolRacine is called in a data/value part of a launcher, it is called at initialisation when RUrPrec=0
			result <- Hr / RUrPrec;
		}
		return result;
	}
	action setRUs(float donnee){
		//if (donnee > RUs){
			//Hs <- Hs * donnee / RUsPrec;
			
			//**********************************************************************
			// Ajout Renaud 31/05/18 à vérifier avec Olivier et Hélène
			//RUsPrec <- RUs;
			if (donnee = horizonDeTravailProfond) {
				RUs <- max([RUw * 0.95, RUsPrec]);
			} else {
				RUs <- max([RUm / ilot_app.sol.profondeurMax * donnee, RUsPrec]);    //  max entre (RUm / prof_sol x W_prof   ou    RUsPrec);
			}

			
		//}//else{ //RUs > donnee //cas particulier d'un travail de sol moins profond peu de temps apres un travail de sol profond
		Ccap <- 0.0;
	}
	
	float addRevapparcelle(float eau){
		float eauNonTransmissible <-0.0;
		if ((eau + Hm) >RUm){
			eauNonTransmissible <- Hm + eau - RUm;
			Hm <- RUm;
		}else{
			Hm <- Hm + eau;
		}
		return eauNonTransmissible;
	}
	
	float getKc{// kc
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.kc;
		}
		return resultat;
	}
	
	float getKc_flo{// kc au moment de la floraison modif_feuillage
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureParcelle.monModelDeCulture.kc_flo;
		}
		return resultat;
	}
	
	float getDateLabour{// frein
		float heure <- 0.0;										
		ask listeAgriculteurs{
			heure <- heuresLabour;
		}
				
		return heure;
	}


	// JV 280618 redefinition
	float getHumiditeHorizonTotal{
		return Hm;
	}

	// RM 210823 Récupération de variables spécifiques herbsim
	float getHauteurHerbe{ // 
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureHerbSim(cultureParcelle.monModelDeCulture).Height;
			//write "HERBSIM Renaud - Height = " + cultureHerbSim(cultureParcelle.monModelDeCulture).Height;
		}
		return resultat;
	}	

	float getQuantiteHerbe{ // Renvoie la quantité d'herbe TOTALE présente sur la parcelle (en tenant compte de la surface de la parcelle)
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureHerbSim(cultureParcelle.monModelDeCulture).getBiomasseAboveGround() * surface / 10000;
//			write "HERBSIM Renaud - quantité biomasse par ha = " + cultureHerbSim(cultureParcelle.monModelDeCulture).getBiomasseAboveGround();
		}
		return resultat;
	}	

	float getVolumeHerbe{ // 
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureHerbSim(cultureParcelle.monModelDeCulture).YieldPredicted;
			//write "HERBSIM Renaud - YieldPredicted (volume) = " +cultureHerbSim(cultureParcelle.monModelDeCulture).YieldPredicted;
		}
		return resultat;
	}	
	
	float getQuantiteBiomasse(float hauteurCoupeStrat) { // 
        float resultat <- 0.0;
        if (cultureParcelle != nil){
            float biomasseNonRecoltable <- cultureHerbSim(cultureParcelle.monModelDeCulture).biomass_sheath / 3 * hauteurCoupeStrat;
            resultat <- cultureHerbSim(cultureParcelle.monModelDeCulture).biomass_above_ground - biomasseNonRecoltable;         
        }
        return resultat;
    }	

	float getDigestabiliteHerbe{ // 
		float resultat <- 0.0;
		if (cultureParcelle != nil){
			resultat <- cultureHerbSim(cultureParcelle.monModelDeCulture).OMD;
			//write "HERBSIM Renaud - OMD (diges.) = " + cultureHerbSim(cultureParcelle.monModelDeCulture).OMD;
		}
		return resultat;
	}	

	// JV 130422 MAJ des variables de sortie, redéfinie de parcelle
	action comportementJournalier{		
		if !desactivationMAJsorties {do majSortiesEau;}
		else {desactivationMAJsorties <- false;} // réactivation pour le lendemain
	}
	
	// RM 040425 issue #15 Problème de maj des apports déjà réalisés sur prairie permanente -> remise à 0 au 1er janvier (formation dev 03/2025, modif proposée par Kevin Chapuis)
	action comportementFinAnnuel{
        invoke comportementFinAnnuel();
    }
	
	// JV 130422 RAZ variables sortie eau, appelee le 1er janvier par parcelle.remiseAZeroSortiesParcelle, elle-meme appelée parcelle.comportementAnnuel
	action remiseAZeroSortiesEau {
		sorties_evaporation <- [0.0];
		sorties_transpiration <- [0.0];
		sorties_percolation <- [0.0];
		sorties_capilarite <- [0.0];
		sorties_ruisselement <- [0.0]; // MD 30082023
		sorties_Hr_debut <- [Hr];
		sorties_Hr_debut <- [Hm];
		sorties_Hr_fin <- [0.0];
		sorties_Hm_fin <- [0.0];
		sorties_Hr_1janv <- [Hr];	
		sorties_Hm_1janv <- [Hm];	
		sorties_satisfactionHydrique <- [0.0];
		sorties_pluie <- [0.0];
		sorties_irrigation <- [0.0];
		sorties_sommeDegresJourCulture <- [0.0];
	}
	
	// JV 130422 MAJ des variables de sortie, appelé dans comportementJournalier
	action majSortiesEau {
		// on MAJ les variables du dernier élément des listes (correspond au couvert courant)
		int indiceCouvertCourant <- length(sorties_jDebutCouvert)-1; // commence à 0
		sorties_evaporation[indiceCouvertCourant] <- sorties_evaporation[indiceCouvertCourant] + evaporation;
		sorties_transpiration[indiceCouvertCourant] <- sorties_transpiration[indiceCouvertCourant] + transpirationR;
		sorties_percolation[indiceCouvertCourant] <- sorties_percolation[indiceCouvertCourant] + calculEcoulementEauSouterraine();
		sorties_capilarite[indiceCouvertCourant] <- sorties_capilarite[indiceCouvertCourant] + capilarite;
		sorties_ruisselement[indiceCouvertCourant] <- sorties_ruisselement[indiceCouvertCourant] + quantiteEauDeRuissellement ; // ajout MD 30082023
		sorties_pluie[indiceCouvertCourant] <- sorties_pluie[indiceCouvertCourant] + getPluie();
		sorties_irrigation[indiceCouvertCourant] <- sorties_irrigation[indiceCouvertCourant] + irrigationReelle;
		sorties_Hr_fin[indiceCouvertCourant] <- Hr; // pas de cumul: on veut récupérer la valeur du dernier jour du couvert
		sorties_Hm_fin[indiceCouvertCourant] <- Hm; // pas de cumul: on veut récupérer la valeur du dernier jour du couvert		
		// JV 281123 pour benchmark sortie	
		//string aEcr <- "" + dateCour.annee + ";" + dateCour.nbJoursEcoulesDansAnnee + ";" + idParcelle + ";" + getITKAnnee().especeCultiveeITK.idEspeceCultivee + ";" + evaporation + ";" + transpirationR + ";" + calculEcoulementEauSouterraine() + ";" + capilarite + ";" + getPluie() + ";" + Hr + ";" + Hm; 
		if cultureParcelle!=nil { // s'il y a un couvert (pas sol nu)
			sorties_satisfactionHydrique[indiceCouvertCourant] <- sorties_satisfactionHydrique[indiceCouvertCourant] + cultureParcelle.monModelDeCulture.indiceSatifactionHydrique;
			//aEcr <- aEcr + ";" + cultureParcelle.monModelDeCulture.indiceSatifactionHydrique;// JV 281123 pour benchmark sortie
			if string(species(cultureParcelle.monModelDeCulture))="cultureAqYield" or string(species(cultureParcelle.monModelDeCulture))="cultureAqYieldNC" {
				sorties_sommeDegresJourCulture[indiceCouvertCourant] <- cultureAqYield(cultureParcelle.monModelDeCulture).sommeDegresJourCulture; // pas de cumul pour les degrés-jour car ce sont déjà des cumuls: on récupérera la valeur du dernier jour du semis					
			} else if string(species(cultureParcelle.monModelDeCulture))="cultureHerbSim" or string(species(cultureParcelle.monModelDeCulture))="cultureHerbSimNC" { // NR Herbsim 26/04/2024
				sorties_sommeDegresJourCulture[indiceCouvertCourant] <- cultureHerbSim(cultureParcelle.monModelDeCulture).ThermalAge; // mail RM 281123												
			}
		} //else {aEcr <- aEcr + ";"; } // JV 281123 pour benchmark sortie
		// JV 281123 pour benchmark sortie
		//string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/eau.csv";
		//save aEcr to: fileName type: 'text' rewrite:false;
	}
	
}
