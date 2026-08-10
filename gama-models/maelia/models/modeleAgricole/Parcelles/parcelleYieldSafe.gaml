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
 *  parcelleYieldSafe
 *  Author: Maroussia Vavasseur
 *  Description: Les parcelles AqYield sont les parcelles creees dans le cas ou le modele de croissance des plante est le modele AqYield
 */

model parcelleYieldSafe

import "../../modeleCommun/typeDeSol.gaml"
 
global {	
//	string parcellesAqYieldShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/zoneMaelia/parcelles_Utiles_2009.shp';
	
	/* 
	 * *****************************************************************************************
	 * Private
	 */
	action constructionParcelleYieldSafe{
		listeParcelles <- lectureFichierParcelle(cheminEntree:parcellesShape, typeParcelle:parcelleAqYield);
	}
}


species parcelleAqYieldSafe parent: parcelle {
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
	
	float apportEnEauUtile <- 0.0; // PIRj
	float evaporation <- 0.0; // eva
	float transpirationW <- 0.0; // TRw
	float transpirationR <- 0.0; // TRr 
	float coefRuissellement <- 0.0;

	float reserveUtileHorizonSurfaceW1 <- 7.0 ; // RUSw1 = 7mm
	
	// Parameter for the HerbSim model 							  //
	
	//part for comparison with herbSim
	float AvailableSoilWater <- 0.0; //[mm]
	float ActualEvapoTranspiration <- 0.0;//[mm]
	float FractionTranspirableSoilWater <- 1.0; //[-]
	
	
	// part to keep
	float NutrientIndex <- 0.0; //[-]
	float AdjustedNitrogenIndex <- 0.0;
	
	// TO GET IN INPUT
	float NitrogenIndex <- 0.8; //[-] //à lire en entree
//	float NitrogenIndexInit <- 0.75; //[-] //à lire en entree
	float PhosphorusIndex <- 0.8; //[-] // a lire en entree
	float TotalTranspirableSoilWater <- 100.0;
	
	// AqYield Azote, rempli si activé
//	cultureAqYieldNC myParcelleAqYieldNC <- nil;

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Initialisation
	 */
	action initialisationDonneesSol {
		// AQYIELD
		//coefRuissellement <- ((ilot_app.penteAssociee/ 100)^2) ; //RL 17/05/17 : correction de la formule pour que 
			//ce coeff soit compris entre 0 et 1 

		coefRuissellement <- (ilot_app.penteAssociee^2 / 100) ; // JV 06/11/17 retour à l'ancienne formule CR = Pente² / 100 suite à demande G. Obiang-Ndong (Mantis #1145)
		if(coefRuissellement > 1){
			coefRuissellement <- 1.0;
		} 

		RUm <- ilot_app.sol.reservePotentielleUtileMax;
		RUw <-  RUm / self.ilot_app.sol.profondeurMax * 30.0; //ilot_app.sol.reservoirHorizonTravailProfond; --> Modifié pour coller à AqYield excel (22/05/18)
		RUr <- RUw; // ilot_app.sol.reservoirHorizonTravailProfond; -->  Modifié pour coller à AqYield excel (22/05/18)
		RUs <- RUw * 0.95; // RUw -1.0; --> Modifié pour coller à AqYield excel (18/05/18)
		Hm <- 0.8 * ilot_app.sol.reservePotentielleUtileMax;
		Hw <- 0.8 * ilot_app.sol.reservoirHorizonTravailProfond;
		Hr <- Hw;
		Hs <- Hw * RUs / ilot_app.sol.reservoirHorizonTravailProfond;
		
		write "RUm = " + RUm + "RUw = " + RUw + "RUr = " + RUr + "RUs = " + RUs + "Hm = " + Hm + "Hw = " + Hw + "Hr = " + Hr + "Hs = " + Hs;
		
		reserveUtileHorizonSurfaceW1 <- horizonDeTravailSuperficiel / 10.0 * (1.0 - self.ilot_app.sol.tauxGravier / 100) *
		 (12.0 + 39.0 * (self.ilot_app.sol.tauxArgile / 100) - 64.0 * ((self.ilot_app.sol.tauxArgile / 100)^2));
		
		
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
		write "ilot_app.sol.coefStabiliteCultural = " + ilot_app.sol.coefStabiliteCultural;
		write "ilot_app.sol.coefStabiliteCultural = " + ilot_app.sol.tauxArgile;
		// 1 -RUr
		if (cultureParcelle != nil){
			ask cultureParcelle.monModelDeCulture{
				myself.RUr <- calculReserveAccessibleRacine(RUrPrecEntree:myself.RUrPrec, noteQualiteStructureSolEntree:myself.ilot_app.sol.noteQualiteStructureSol);			
			}
		}
	
		RUr <- min([RUm, RUr]);
		RUr <- max([RUw, RUr]);
		
		// 2 -RUs
		// Si il ny a pas eu de travail du sol
		if(!isTravailSolJourCourant) {
			RUs <- RUsPrec * float(1 - pluieEtIrrigation / ilot_app.sol.coefStabiliteCultural); //[mm]
			prof_w_sol <- 0.0; // TODO Supprimer  --> Ajout Renaud 30/05/18 (cf strategieOT.gaml)
		} else {
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
	 * Evapotranspiration
	 */
	float calculEvapoTranspirationAqYield{	
	 	// 1 -Evaporation
	 	float coefKc <- 0.0;
		
		if (cultureParcelle != nil){
//			coefKc <- getKc() / coefCulturalEva;// [m3] Ancienne méthode (sans prise en compte de la valeur de echV) modif_feuillage
			if (getEchelleVegetation() < 1 or cultureParcelle.espece.abscission > 0){ //modif_feuillage Modifié avec Hélène, abscission modifié avec Laurène
				coefKc <- getKc() / coefCulturalEva;
			} else {
				coefKc <- getKc_flo() / coefCulturalEva;
			}
			// Si echV est supérieure ou égale à 1 on utilise KcFlo (Kc au moment de la floraison, au moment où echV = 1)
		}
		evaporation <- ilot_app.meteo.etp * max([1-coefKc, 0.0]) * (max([float(Hs/RUs*ilot_app.sol.coefCC + 1 - ilot_app.sol.coefCC), 0.0])^2); //coefEvaSurRUs

	 	// 2 -Transpiration
		if (cultureParcelle != nil){
			ask cultureParcelle{
				monModelDeCulture.transpirationMax <- (myself.ilot_app.meteo.etp - myself.evaporation) * myself.getKc();					
				ask monModelDeCulture{
					do calculIndiceSatisfactionHydrique();
				}	
				// Calcul de Kc
				ask monModelDeCulture{
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
	 	Hw <- min([RUw, Hw]);
	 	
	 	// 5 -Hs
	 	float tauxHumiditeW <- (HwPrec/RUw - Hs/RUsPrec); // delta(tx_hum_w)/s(j-1)
	 	float humiditeW <- HwPrec - Hs; // delta(hum_w)		 	

		if(RUs > RUsPrec){
			Hs <- (Hs + apportEnEauUtile - evaporation) + (Ccap * tauxHumiditeW) + (humiditeW * (RUs-RUsPrec) / (RUw-RUsPrec));				
		} else {
			Hs <- (Hs + apportEnEauUtile - evaporation) + (Ccap * tauxHumiditeW);				
		}
		Hs <- max([RUs - RUs / ilot_app.sol.coefCC, Hs]);
		Hs <- min([RUs, Hs]);

		// 6 -Hr (si pas culture, pas forcement pertinent ...)			
		if(RUr = RUw){// <= (RUw  + 0.1) and RUr >= (RUw  - 0.1)){
			Hr <- Hw;
		}else if(RUr > RUrPrec){
			Hr <- Hr + apportEnEauUtile - evaporation - transpirationR + (RUr-RUrPrec) * (Hm-Hr) / (RUm-RUrPrec);	
		}else{
			Hr <- Hr + apportEnEauUtile - evaporation - transpirationR;					
		}
		Hr <- min([RUr, Hr]);
		Hr <- max([0.0, Hr]);
		
		
		
		// 7 -Hm
		HmPrec <- Hm;
		Hm <- min([RUm, Hm + apportEnEauUtile - evaporation - transpirationR]);		
		Hm <- max([0.0, Hm]);
		write "RUm = " + RUm + "RUw = " + RUw + "RUr = " + RUr + "RUs = " + RUs + "Hm = " + Hm + "Hw = " + Hw + "Hr = " + Hr + "Hs = " + Hs;
		return (evaporation + transpirationR); // [m]
	}

	action calculNutritionIndex{
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
		NutrientIndex <-  (2 * AdjustedNitrogenIndex + PhosphorusIndex) / 3;
		
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
		return (Hw / RUw);
	}
	float getHumiditeSolRacine{ // %
		return (Hr / RUrPrec);
	}
	action setRUs(float donnee){
		//if (donnee > RUs){
			Hs <- Hs * donnee / RUsPrec;
			
			//**********************************************************************
			// Ajout Renaud 31/05/18 à vérifier avec Olivier et Hélène
			//RUsPrec <- RUs;
			if (donnee = horizonDeTravailProfond) {
				RUs <- max([RUw * 0.95, RUsPrec]);
			} else {
				RUs <- max([RUm / ilot_app.sol.profondeurMax * donnee, RUsPrec]);    //  max entre (RUm / prof_sol x W_prof   ou    RUsPrec);
			}
			//**********************************************************************
			
			
			
			//**********************************************************************
			// Retirer Renaud 31/05/18 pour comparaison avec aqyield excel --> à vérifier avec Hélène et Olivier
			//RUs <- donnee;
			//RUsPrec <- donnee;
			//**********************************************************************
			
		//}//else{ //RUs > donnee //cas particulier d'un travail de sol moins profond peu de temps apres un travail de sol profond
		Ccap <- 0.0;
	}
	
	float addRevapparcelle(float eau){
		float eauNonTransmissible <- 0.0;
		if ((eau + Hm) > RUm){
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
}
