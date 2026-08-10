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
 *  zoneHydrographiqueSWAT
 *  Author: Maroussia Vavsseur
 *  Description: Cette classe est la fille de la ZH classique, mais fait des traitements propore a SWAT pour tout ce qui est calcul des debits.
 */

model zoneHydrographiqueSWAT

import "ressourceEnEau.gaml"

global{
	string cheminParametresMNT <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/donneesMNT_ZH.csv';
	
	// JV bilan hydro
	bool bilanSolEnteteDejaEcrit <- false;
	bool bilanSolEnteteDejaEcrit_hydro <- false;
	bool bilanSolEnteteDejaEcrit_RPG <- false;
	bool bilanRoutageEnteteDejaEcrit <- false;

	/*
	 * *****************************************************************************************
	 * Publique
	 * Lit le fichier donnant le nombre dilots a disparaitre par ZH : remplissage map [idZH::nbIlotsDisparus]
	 */ 
	action initialisationParametresMNT{		
		 matrix<string> initDisparitionIlots <- matrix<string>(csv_file (cheminParametresMNT,";", string, false));	
		 int nbLignes <- length(initDisparitionIlots column_at 0);	
		 		 
		 loop i from: 1 to: ( nbLignes - 1 ) {
			list<string> ligneI <- initDisparitionIlots row_at i;	
			zoneHydrographiqueSWAT zhLu <- mapZH at (ligneI at 1) as zoneHydrographiqueSWAT;
			if(zhLu!=nil){
				ask(zhLu){		
					idSWAT <- int(ligneI at 0);
					largeurMoyenCourEauReel <- float(ligneI at 2);
					profondeurMoyenneCoursEauReel <- float(ligneI at 3);
					penteMoyenneCourEauReel <- float(ligneI at 4);
					penteMoyenneCoursEauTributaire <- float(ligneI at 7);
					longueurMoyennePente <- float(ligneI at 6);
					largeurMoyenneCoursEauTributaire <- float(ligneI at 8); //Lu mais non utilisé
				}	
			}
		}
		ask (mapZH.values){
			if(zoneHydrographiqueSWAT(self).idSWAT = 0){
				write "Probleme lecture donnees propriete ZH calcule a partir du MNT, pour le BV " + zoneHydrographiqueSWAT(self).idZoneHydrographique;
			}
		}
	}
} 

species zoneHydrographiqueSWAT parent: zoneHydrographique{		
	int idSWAT <- 0; 
	float volumeRuissellementDeSurfaceHydro <- 0.0; 
	float volumeEcoulementLateralHydro <- 0.0; 			
	float volumeEvapotranspirationHydro <- 0.0; 		
	float volumeEcoulementEauSouterraineHydro <- 0.0; 		
	float hauteurDeNappe <- 0.0;						
// ----------------------------------------- PHASE SOL -----------------------------------------
	list<hru> listeHRUAssociees <- [];	 // toutes les HRU possibles (avec fraction nulle)
	list<hruRPG> listeHRUrpgAssociees <- [];	
	// constantes initialisees GAMA (a partir des elements du MNT entre autre)
	float longueurMoyennePente <- 50.0; // Lslp [m]
	float longueurCoursEauTributaireMax <- 0.0; // LChTri [km]
	float largeurMoyenneCoursEauTributaire <- 0.8; // WchTri [km]
	float penteMoyenneCoursEauTributaire <- 0.01; // slpChTri [m/m]		
// ----------------------------------------- PHASE ROUTAGE -----------------------------------------
	float ecoulementEntree <- 0.0; // flwin et flwinPrec [m3] 
	float ecoulementSortie <- 0.0; // flwout et flwoutPrec [m3]
	float volumeStocke <- volumeStockeinit; // rchstor [m3]
	float volumeEvaporationCourEau <- 0.0; // Evap,ch [m3]		
	float fluxMoyen <- 0.0; // stdi [m3]
//		float perteParTransmission <- 0.0; // tlss,ch
//		float bankStorage <- 0.0; // bankst
	// constantes initialisees GAMA
	float largeurFondCourEauReel <- 0.0; // Wbtm [m]
	float ratioStockage <- 0.0; // Kch,bnkful		
	float ratioStockageProfondeurDefinie <- 0.0; // Kch,0.1 bnkful
	float tempsDeStockage <- 0.0; // Kmsk
	int nbIterationJournaliere <- 1; // nn
	int det <- nbHeuresDansPasDeTemps;
	// constantes initialisees a partir des elements du MNT
	float largeurMoyenCourEauReel <- 100.0; // Wbnk,ful [m]
	float penteCoteCoursEauReel <- 2.0; // Zch [m/m]
	float penteMoyenneCourEauReel <- 0.02; // slp,ch  [m/m]
	float longueurCoursEauReel <- 4.0; // LCh [km]  (=LChTri si point entree)
	float profondeurMoyenneCoursEauReel <- 3.0; // depth,bnk,ful  [m]
	float largeurCourEauReel <- 0.0; // Wch [m]
// ----------------------------------------- NEIGE -----------------------------------------
	list<bandeAltitude> bandesDelevation <- [];
	float chuteDeNeige <- 0.0; // snofall(j)
	float couvertureDeNeige <- 0.0; // snocov
	float eauDansPaquetNeigeZH <- 0.0; // snozh		
	float fonteDeNeigeZH <- 0.0; // snomlt

	// JV pour bilan phase sol
	float SWprec <- 0.0; // debug JV
	float SWprec_hydro <- 0.0; // debug JV
	float SWprec_RPG <- 0.0; // debug JV
	float aqPeuProfPrec <- 0.0; // debug JV
	float aqPeuProfPrec_hydro <- 0.0; // debug JV
	float aqPeuProfPrec_RPG <- 0.0; // debug JV

	// JV pour bilan phase routage
	float volumeStockePrec <- 0.0; // volume stocké du jour précédent [m3]
	float evaporationCH1 <- 0.0; // évaporation du volume stocké (volumeStocke) [m3]		
	float evaporationCH2 <- 0.0; // évaporation du flux (volumeSorti) [m3]		

   /*
  	* *****************************************************************************************
	* Initialisation des zones hydro pour SWAT
	*/
	action initialisationZoneHydrographique{	

		// Initialisation longueur cours eau (il ny en a quun par ZH!)
		if((ressourceEnEauAssociees at SURF)=nil){ // JV 250920 cas dans les données Dronne PNR Limousin -> erreur ?
			write "initialisationZoneHydrographique: la ZH " + idZoneHydrographique + " n'a pas de cours d'eau associé";
		}else{
			coursDeau coursEauPrincipal <- first(ressourceEnEauAssociees at SURF) as coursDeau;
			ask (coursEauPrincipal){
				myself.longueurCoursEauReel <- self.shape.perimeter / nbMDanskm;	
				myself.longueurCoursEauTributaireMax <- myself.longueurCoursEauReel;	
			}
		}					

		// Initialisation de la largeur du fond du cour deau (Wbtm)
		largeurFondCourEauReel <- abs(largeurMoyenCourEauReel - 2 * penteCoteCoursEauReel * profondeurMoyenneCoursEauReel);
		if(largeurFondCourEauReel <= 0.0){
			largeurFondCourEauReel <- 0.5 * largeurMoyenCourEauReel;
			penteCoteCoursEauReel <- (largeurMoyenCourEauReel - largeurFondCourEauReel) / (2 * profondeurMoyenneCoursEauReel);
		}
		
		do calculNbIterationJournaliere();
	}
	
	action initNeige{
		float altiMax <- 0.0;			
		//Determination de laltitude max ZH
		ask bandesDelevation{
			if(altiMax = 0.0 or altiMax < altitude){
				altiMax <- altitude;
			}
		}
				
	}
	
	float calculRatio{
		arg profondeurEntree type: float default: 0.0;
		
		float ratio <- 0.0;			
		float A <- (largeurFondCourEauReel + penteCoteCoursEauReel * profondeurEntree) * profondeurEntree;
		float P <- largeurFondCourEauReel + 2 * profondeurEntree * sqrt(1 + penteCoteCoursEauReel^2);
		float R <- A / P;
		//float q <- (A * R^0.6666 * sqrt(penteMoyenneCourEauReel)) / coefficientManningCoursEauReel;
		float v <- (1 * R^0.6666 * sqrt(penteMoyenneCourEauReel)) / coefficientManningCoursEauReel;
		float C <- (v * 5) / 3;			
		ratio <- longueurCoursEauReel / (3.6 * C * 5);
		
		return ratio;
	}
	action calculNbIterationJournaliere{
		// Initialisation du ratio de stockage (Kch,bnkful)
		ratioStockage <- calculRatio(profondeurEntree:profondeurMoyenneCoursEauReel);			
		// Initialisation du ratio de stockage a la profonfeur 0.1 (Kch,0.1 bnkful)
		float d <- 0.1 * profondeurMoyenneCoursEauReel;
		ratioStockageProfondeurDefinie <- calculRatio(profondeurEntree:d);			
	 	// Initialisation du temps de stockage (Kmsk)
		tempsDeStockage <- coefMuskingum1 * ratioStockage + coefMuskingum2 * ratioStockageProfondeurDefinie; // Kmsk		
	
		float detMax <- 2 * tempsDeStockage * (1 - coefMuskingumX); // 
		det <- 24;
		nbIterationJournaliere <- 1;
		if(det > detMax){
			if((det / 2) <= detMax){
				det <- 12;
				nbIterationJournaliere <- 2;
			}else if((det / 4) <= detMax){
				det <- 6;
				nbIterationJournaliere <- 4;					
			}else{
				det <- 1;
				nbIterationJournaliere <- 24;						
			}
		}			
	}

	

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE SOL des HRUs classiques
	 */
	action phaseSol{		
		if(isNeige){
			do ajustementTemperaturesEtPrecipitationsPourNeige();
			do fonteDesNeiges();				
		}
		volumeRuissellementDeSurfaceHydro <- 0.0;
		volumeEcoulementLateralHydro <- 0.0;
		volumeEvapotranspirationHydro <- 0.0;
		volumeEcoulementEauSouterraineHydro <- 0.0;
		hauteurDeNappe <- 0.0;
		float surface_cumul <- 0.0;

		ask (listeHRUAssociees){
			surface_cumul <- surface_cumul + surface;
			do calculRuissellementDeSurface();
			myself.volumeRuissellementDeSurfaceHydro <- myself.volumeRuissellementDeSurfaceHydro + (ruissellementDeSurfaceHRU / nombreMillimetreDansUnMetre) * surface; // [mm/1000]*[m2] = [m]*[m2] = [m3]
			do calculEcoulementLateral();
			myself.volumeEcoulementLateralHydro <- myself.volumeEcoulementLateralHydro + (ecoulementLateral / nombreMillimetreDansUnMetre) * surface;
			do calculEvapotranspirationReelle();	
			myself.volumeEvapotranspirationHydro <- myself.volumeEvapotranspirationHydro + (evapoTranspirationReelle / nombreMillimetreDansUnMetre) * surface;
			do calculEcoulementEauSouterraine();
			myself.volumeEcoulementEauSouterraineHydro <- myself.volumeEcoulementEauSouterraineHydro + (ecoulementEauSouterraine / nombreMillimetreDansUnMetre) * surface;			
			myself.hauteurDeNappe <- myself.hauteurDeNappe + (hauteur_nappe) * surface;
//				set balanceEau <- verificationBalanceEau(self, []);
			do remiseAzero;				
		}
		hauteurDeNappe <- hauteurDeNappe / 	surface_cumul;
		if(isNeige){
			do calculEauPaquetNeigeApresPhaseSol();
		}			
	}
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE SOL des HRUs RPG
	 */
	action phaseSolRPG{		
		ask (listeHRUrpgAssociees){
			do croissancePlanteHRU(); // on fait croitre la plante des parcelles de la HRUrpg juste apres avoir calculer le volume effectivment preleve pour lirrigation
			do calculRuissellementDeSurface();
			myself.volumeRuissellementDeSurfaceRPG <- myself.volumeRuissellementDeSurfaceRPG + (ruissellementDeSurfaceHRU / nombreMillimetreDansUnMetre) * surface;
//				do calculEcoulementLateral;
//				myself.volumeEcoulementLateralRPG <- myself.volumeEcoulementLateralRPG + (ecoulementLateral / nombreMillimetreDansUnMetre) * surface;	
			do calculEvapotranspirationReelle();	
			myself.volumeEvapotranspirationRPG <- myself.volumeEvapotranspirationRPG + (evapoTranspirationReelle / nombreMillimetreDansUnMetre) * surface;
			do calculEcoulementEauSouterraine();
			myself.volumeEcoulementEauSouterraineRPG <- myself.volumeEcoulementEauSouterraineRPG + (ecoulementEauSouterraine / nombreMillimetreDansUnMetre) * surface;
			// JV 150618 attention getPercolationDerniereCouche en [mm] (calculé en [m3] dans les îlots lors de la phase solRPG mais remis en [mm] dans calculEcoulementEauSouterraine)
			// donc on remet en [m3] ici 
			// variable stockée sinon remise à zéro
			myself.volumePercolationRPG <- myself.volumePercolationRPG + (getPercolationDerniereCouche()/nombreMillimetreDansUnMetre) * surface; 
			// JV 280618 pour calcul SwFin dans les HRU RPG
			do calculHumiditeHorizonTotal();				
			myself.volumeHumiditeHorizonTotalRPG <- myself.volumeHumiditeHorizonTotalRPG + (humiditeHorizonTotal/nombreMillimetreDansUnMetre) * surface;
//				do verificationBalanceEau();
			do remiseAzero();
		}	
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE ROUTAGE
	 * Les prelevemetns et les rejets sont fait avant la phase routage (pas le choix car on doit irrigguer avant la phase sol RPG)
	 */		 
	 action phaseRoutage{		
	 	volumeEntree <- getVolumeEntreePhaseRoutage() / nbIterationJournaliere;
	 	float qoutday <- 0.0;
	 	float qinday <- 0.0;	 	
	 	loop i from: 1 to: nbIterationJournaliere{	
		 	// 3 -Calcul du volume et de la profondeur
		 	float volRt <- (volumeEntree + volumeStocke) / nbSecondesDansUneJournee * nbIterationJournaliere;		 	
		 	if(volRt > zeroApproche){
			 	fluxMoyen <- 0.0;
				float surfaceSectionMouillee <- 0.0; // aCH
				float profondeurReelleCoursEauReel <- 0.0; // depthCh			
				
				//Recherche dichotomique de la profondeur du cours d'eau
				float minProfondeur <- 0.0;
				float maxProfondeur <- 10.0;
				
				loop while: (maxProfondeur - minProfondeur > 0.01){
					// On se place au milieu du domaine
					profondeurReelleCoursEauReel <- (minProfondeur + maxProfondeur)/2.0;
					// On cherche maintenant à évaluer le fluxMoyen
			 		surfaceSectionMouillee <- (largeurFondCourEauReel + penteCoteCoursEauReel * profondeurReelleCoursEauReel)*profondeurReelleCoursEauReel;
			 		float pCH <-  largeurFondCourEauReel + 2 * profondeurReelleCoursEauReel * sqrt(1 + penteCoteCoursEauReel^2);
			 		float rCH <- surfaceSectionMouillee / pCH;
			 		fluxMoyen <- (surfaceSectionMouillee * (rCH^0.6666) * sqrt(penteMoyenneCourEauReel)) / coefficientManningCoursEauReel;                                    
			 								
					if (fluxMoyen < volRt){ // alors on se déplace vers la droite
						minProfondeur <- profondeurReelleCoursEauReel ;
					}else{
						maxProfondeur <- profondeurReelleCoursEauReel ;
					}
				}
			 	
			 	fluxMoyen <- volRt;
			 	largeurCourEauReel <- largeurFondCourEauReel + 2 * profondeurReelleCoursEauReel * penteCoteCoursEauReel; 
			 	
			 	// 4 -Calcul de la vitesse et du volume de sortie
			 	float vitesse <- fluxMoyen / surfaceSectionMouillee; // vCH
			 	float dureeTrajet <- longueurCoursEauReel * nbMDanskm / (nbSecondesDansUneHeure * vitesse); // rttime
			 	float yy <- 2 * tempsDeStockage * (1 - coefMuskingumX) + det;
			 	float c1 <- (det - 2 * tempsDeStockage * coefMuskingumX) / yy;
			 	float c2 <- (det + 2 * tempsDeStockage * coefMuskingumX) / yy;
			 	float c3 <- (2 * tempsDeStockage * (1 - coefMuskingumX) - det) / yy;			 	
			 	float ecoulementEntreePrec <- 0.0; // flwinPrec [m3] 
				float ecoulementSortiePrec <- 0.0; // flwoutPrec [m3]
			 	if(dateCour.jour = jourDebutSimulation and dateCour.mois = moisDebutSimulation and dateCour.annee = anneeDebutSimulation){
			 		ecoulementEntreePrec <- volumeStocke;
					ecoulementSortiePrec <- volumeStocke;	
			 	}else{
				 	ecoulementEntreePrec <- ecoulementEntree;
					ecoulementSortiePrec <- ecoulementSortie;			 		
			 	}
				volumeSorti <- max([0.0, c1 * volumeEntree + c2 * ecoulementEntreePrec + c3 * ecoulementSortiePrec]);	
				volumeSorti <- min([volumeSorti, (volumeEntree + volumeStocke)]);	
				
				// 5 -Calcul de la quantite deau stocke dans le troncon
				volumeStocke <-  volumeStocke + volumeEntree - volumeSorti;
				if(volumeStocke < zeroApproche){
					volumeStocke <- 0.0;
				}

//				// 6 -Calcul des pertes par transmission
//				do calculDesPertesParTransmission();

				// 7 -Calcul des pertes par evaporation
				do calculPertesParEvaporation();		

//		 		// 8 -Calcul du bank storage		 		
//		 		do calculBankStorage();
				
				// 9 -Calcul des ecoulements dentree et de sortie		
				ecoulementEntree <- volumeEntree; // flwin
				ecoulementSortie <- volumeSorti; // flwout	
				qoutday <- qoutday + volumeSorti;
				qinday <- qinday + volumeEntree;					
	 			volumeSorti <- qoutday;
		 	}else{
		 		volumeSorti <- 0.0;
		 	}		 		
	 	} 
	 	volumeEntree <- qinday;
	 			 			
	 	// 10 -Si leau stockee est inferieur a une certaine valeur, alors on fait tout sortir du cours deau
	 	volumeSorti <- max([0.0, volumeSorti]);
	 	volumeStocke <- max([0.0, volumeStocke]);
	 	if(volumeStocke < 10.0){
	 		volumeSorti <- volumeSorti + volumeStocke;
	 		volumeStocke <- 0.0;
	 	}			 	
	 }

	/*
	 * *****************************************************************************************
	 */	
	action calculPertesParEvaporation{						
		if(volumeSorti > 0.0){
			float aaa <- coefAjustementEvaporation * meteo.etp / getSurfaceZhSansIlots();
			volumeEvaporationCourEau <- aaa * longueurCoursEauReel * nbMDanskm * largeurCourEauReel;
			
			// Evap 1 et 2 (intermediaires)
			float evapCH1 <- 0.0;
			float evapCH2 <- (volumeEvaporationCourEau * volumeStocke) / (volumeSorti + volumeStocke);				

			if(volumeStocke <= evapCH2){
				evapCH2 <- min([evapCH2, volumeStocke]);					
			}
			volumeStocke <- volumeStocke - evapCH2;
			evapCH1 <- volumeEvaporationCourEau - evapCH2;			

			if(volumeSorti <= evapCH1){
				evapCH1 <- min([evapCH1, volumeSorti]);						
			}
			volumeSorti <- volumeSorti - evapCH1;
			
			// Evaporation totale				
			volumeEvaporationCourEau <- evapCH1 + evapCH2;				
		}else{
			volumeSorti <- 0.0;
			fluxMoyen <- 0.0;
			ecoulementEntree <- 0.0; // flwin
			ecoulementSortie <- 0.0; // flwout		
		}		
	}

	
//		/*
//		 * *****************************************************************************************
//		 */	
//		action calculDesPertesParTransmission{
//			perteParTransmission <- 0.0; // tlss,ch
//			
//			if(volumeSorti > 0.0){
//				perteParTransmission <- det * ratioStockage * longueurCoursEauReel * profondeurMoyenneCoursEauReel;
//								
//				float perteParTransmission2 <- min([volumeStocke, perteParTransmission * volumeStocke / (volumeSorti + volumeStocke)]); // tlss2,ch
//				volumeStocke <- volumeStocke - perteParTransmission2;
//				
//				float perteParTransmission1 <- min([volumeSorti, perteParTransmission - perteParTransmission2]); // tlss1,ch
//				volumeSorti <- volumeSorti - perteParTransmission1;
//				
//				perteParTransmission <- perteParTransmission1 + perteParTransmission2;
//			} 		
//		}
//
//		/*
//		 * *****************************************************************************************
//		 */	
//		action calculBankStorage{
//			// 1 -Ajout de la perte par transmission au bank storage
//			if(perteParTransmission > 0.0){
//				bankStorage <- bankStorage + perteParTransmission * (1 - fractionPerteTransmission);
//			}
//			
//			// 2 -Calcul du revap
//			float revapBankStorage <- min([bankStorage, coefRevapEauSouterraineGlobal * meteo.etp * longueurCoursEauReel * largeurMoyenCourEauReel]); // rvbnk
//			bankStorage <- bankStorage - revapBankStorage;
//			
//			// 3 -Calcul de la contribution vers cours d'eau
//			float qdbank <- bankStorage * (1 - exp(-alphaBankGlobal));
//			bankStorage <- bankStorage - qdbank;
//			volumeSorti <- volumeSorti + qdbank;
//		}
	
	
	/*
	 * *****************************************************************************************
	 */	 		
	action ajustementTemperaturesEtPrecipitationsPourNeige{
		// 1 - Ajustement des bandes delevation
		ask(bandesDelevation){ 
			do ajustement();							
		}			
		// 2 - Mise a jour des temperatures de la ZH
		tMoy <- 0.0;
		tMin <- 0.0;
		tMax <- 0.0; 	
		pluie <- 0.0;		
		ask(bandesDelevation){ 				
 			myself.tMoy <- myself.tMoy + temperatureMoy * fraction;
 			myself.tMin <- myself.tMin + temperatureMin * fraction;
 			myself.tMax <- myself.tMax + temperatureMax * fraction;
 			myself.pluie <- myself.pluie + precipitations * fraction;	
		}	
	}		
	/*
	 * *****************************************************************************************
	 */	 		
	action fonteDesNeiges{ 
		// locales
		float xyz <- ln(sno50cov / 0.5 - sno50cov); // TODO : probleme pour faire le log en GAMA !!!!!
		float snowCov2 <- (xyz - ln(0.05)) / (0.95 - sno50cov); // TODO : probleme pour faire le log en GAMA !!!!!
		float snowCov1 <- xyz + (sno50cov * snowCov2);
		float smp <- 0.0; // smp			
		eauDansPaquetNeigeZH <- 0.0; // sum
		fonteDeNeigeZH <- 0.0;
		chuteDeNeige <- 0.0;
		
		ask(bandesDelevation){ 	
			temperatureNeige <- temperatureNeige * (1-timp)	+ temperatureMoy * timp;
			if(temperatureMoy < temperatureChuteDeNeige){
				eauDansPaquetNeige <- eauDansPaquetNeige + precipitations;
				myself.chuteDeNeige <- myself.chuteDeNeige + precipitations * fraction;
			}else if(temperatureMax > temperatureFonteDeNeige){
				float smfac <- (txFonteDeNeigeMax + txFonteDeNeigeMin)/2 + sin((dateCour.nbJoursEcoulesDansAnnee-81)/58.09 * (txFonteDeNeigeMax - txFonteDeNeigeMin)/2) ; // smfac(ib)
				fonteDeNeige <- smfac * (txFonteDeNeigeMax + txFonteDeNeigeMin)/2 - temperatureFonteDeNeige; // smleb(ib)
			
				// Ajustement de la couverture de neige
				if(eauDansPaquetNeige < snocovmx){
					float xx <- eauDansPaquetNeige / snocovmx;
					myself.couvertureDeNeige <- xx / (xx + exp(snowCov1 - snowCov2*xx));
				}else{
					myself.couvertureDeNeige <- 1.0;
				}
				fonteDeNeige <- max([0.0, fonteDeNeige * myself.couvertureDeNeige]);
				fonteDeNeige <- min([eauDansPaquetNeige, fonteDeNeige]);
				eauDansPaquetNeige <- eauDansPaquetNeige - fonteDeNeige;
				myself.fonteDeNeigeZH <- myself.fonteDeNeigeZH + fonteDeNeige * fraction; // TODO : voir si variable de HRU??
			}
			myself.eauDansPaquetNeigeZH <- myself.eauDansPaquetNeigeZH + eauDansPaquetNeige * fraction; // TODO: sum normalement??
			smp <- smp + precipitations * fraction;
		}
		pluie <- max([0.0, smp + fonteDeNeigeZH - chuteDeNeige]);	
	}
	action calculEauPaquetNeigeApresPhaseSol{
		// 1 -  Ajustement eau paquet neige par ZH
		eauDansPaquetNeigeZH <- 0.0;
		ask listeHRUAssociees{
			myself.eauDansPaquetNeigeZH <- myself.eauDansPaquetNeigeZH + eauDansPaquetNeigeHRU*fractionDansZH;
		}
		
		// 2 -  Ajustement eau paquet neige par bande		
		ask bandesDelevation{				
			eauDansPaquetNeige <- 0.0;
			ask myself.listeHRUAssociees{
				float fractionBandeDansHRUtemp <- fractionDansZH * (bandesDelevation at myself) / myself.fraction;
				myself.eauDansPaquetNeige <- myself.eauDansPaquetNeige + (eauDansPaquetNeigeHRUParBande at myself)*fractionBandeDansHRUtemp;
			}	
		}
	}


	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Utile uniquement si les HRU evoluent (si il y a la disparition des ilots)
	 * Mise a jour des fractions hruRPG et hruHydro
	 */		 
	 action miseAjourHRUrpg(map<string,list<ilot>> mapDisparitionIlots){				 	 	
	 	ask listeHRUrpgAssociees{
	 		do miseAJourFractionHRUs(mapIdClasse: mapDisparitionIlots);	 		
	 	}
	 }
	 

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Calcul Volume des nappes presant pour les prelevements
	 */	
	action calculVolumeUtileNappesReel{	
	 	float volumeUtilePourPrelevementsNappes <- 0.0;
	 	ask(listeHRUAssociees + listeHRUrpgAssociees){
	 		// eauStockeeAquiferePeuProfond est en mm; on le convertit en m
	 		// multiplie par la surface on obtient des m3
	 		volumeUtilePourPrelevementsNappes <- volumeUtilePourPrelevementsNappes + eauStockeeAquiferePeuProfond /1000.0 * self.surface;
	 	}		 		 	
	 	list<ressourceEnEau> listeNappes <- (ressourceEnEauAssociees at NAPP);			 			 			 			 	
	 	ask (listeNappes){
	 		volumeUtileAvantPrelevementEtRejet <- volumeUtilePourPrelevementsNappes/length(listeNappes) ; 
	 	}
	}
	 
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Une fois que les prelevements humains et rejets calcules, on peut mettre a jour la quantite presente dans les nappes de chaque HRU
	 */	
	action miseAjourVolumeNappe{
		float pourcentage <- 0.0;	
		float volumeNappeEntree <- 0.0;
		float volumeNappePreleve <- 0.0;		
		if(ressourceEnEauAssociees at NAPP != nil){
			ask (ressourceEnEauAssociees at NAPP){
		 		volumeNappeEntree <- volumeNappeEntree + getVolumeUtileAvantPrelevementEtRejet();
		 		volumeNappePreleve <- volumeNappePreleve + getVolumePreleve(REEL);
		 	}			
	 	}
	 	// JV 300918
	 	// on prend aussi en compte les prélèvements des retenues sur nappe, l'évaporation de la retenue et les précipitations sur la retenue
	 	// -> bilanRetenue = précipitations - évaporation - prélèvements
	 	// on retranche ce bilan à volumeNappePreleve (retranche car volumeNappePreleve>0 -> on retire de la nappe, mais bilanRetenue>0 -> on ajoute dans la nappe donc
	 	// 		volumeNappePreleve <- volumeNappePreleve - précipitations + évaporation + prélèvements
	 	// soit volumeNappePreleve <- volumeNappePreleve - bilanRetenue
		if(ressourceEnEauAssociees at RET != nil){
			ask (ressourceEnEauAssociees at RET){
				if(retenueCollinaire(self).typeOfRet = SURNAPPE){
					float bilanRetenue <- retenueCollinaire(self).getVolumePrecip() - retenueCollinaire(self).getVolumeEvap() - retenueCollinaire(self).getVolumePreleveReel();
			 		volumeNappePreleve <- volumeNappePreleve - bilanRetenue;
			 	}
		 	}	// fin modif JV		
		}
	 	// JV le pourcentage peut être négatif car volumeNappePreleve<0 si beaucoup de précipitations et peu de prélèvements
	 	// dans ce cas, le volume de la nappe (eauStockeeAquiferePeuProfond) augmente
		if(volumeNappeEntree > 0.0){
			pourcentage <- min([volumeNappePreleve / volumeNappeEntree,1.0]);
		}
		ask(listeHRUAssociees + listeHRUrpgAssociees){
	 		eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfond * (1 - pourcentage);
	 	} 			
	}
	
	float rechargeRetenueParNappe (float eauDemande){
		float pourcentage <- 0.0;	
		float volumeNappeEntree <- 0.0;
		float pourcentageEffectif <- 1.0;
		if(eauDemande > 0.0){
			if(ressourceEnEauAssociees at NAPP != nil){
				ask (ressourceEnEauAssociees at NAPP){
			 		volumeNappeEntree <- self.volumeUtileAvantPrelevementEtRejet;
			 	}
		 	}
		 	if(volumeNappeEntree > 0.0){
		 		pourcentage <- eauDemande / volumeNappeEntree;
		 		if(pourcentage > 1.0){
		 			pourcentage <- 1.0;
		 			pourcentageEffectif <- volumeNappeEntree/eauDemande;
		 		}
		 		ask(listeHRUAssociees + listeHRUrpgAssociees){
			 		eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfond * (1 - pourcentage);
			 	}
		 	}else{
		 		pourcentageEffectif <- 0.0;
		 	}	
		}	
		
		return pourcentageEffectif;
	} 
	
	action miseAjourVolumePhaseSolHydro (float fraction){
		do miseAjourVolumeRuissellement(fraction);
		volumeEcoulementLateralHydro <- volumeEcoulementLateralHydro * fraction;
		volumeEcoulementEauSouterraineHydro <- volumeEcoulementEauSouterraineHydro * fraction;
		
		ask (listeHRUAssociees){
			ecoulementLateral <- ecoulementLateral * fraction;
			ecoulementEauSouterraine <- ecoulementEauSouterraine * fraction; 
		}
		
		volumeEcoulementLateralRPG <- volumeEcoulementLateralRPG * (fraction);
		volumeEcoulementEauSouterraineRPG <- volumeEcoulementEauSouterraineRPG * (fraction);

		ask (listeHRUrpgAssociees){
			ecoulementLateral <- ecoulementLateral * fraction;
			ecoulementEauSouterraine <- ecoulementEauSouterraine * fraction; 
		}
	}
	
	action miseAjourVolumeRuissellement (float fraction){
		volumeRuissellementDeSurfaceHydro <- volumeRuissellementDeSurfaceHydro * fraction;			
		ask (listeHRUAssociees){
			ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU * fraction;
			}
		
		volumeRuissellementDeSurfaceRPG <- volumeRuissellementDeSurfaceRPG * (fraction);

		ask (listeHRUrpgAssociees){
			ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU * fraction;
		}
	}

	float getVolumePhaseSolHydro{
		return volumeRuissellementDeSurfaceHydro + volumeEcoulementLateralHydro + volumeEcoulementEauSouterraineHydro; // [m3]		
	}							
	float getVolumeRuissellementDeSurface{ // volQsurf [m3]
		return (volumeRuissellementDeSurfaceHydro + volumeRuissellementDeSurfaceRPG);
	}	
	float getVolumeEcoulementLateral{ // volQlat [m3]	
		return (volumeEcoulementLateralHydro + volumeEcoulementLateralRPG);
	}			
	float getVolumeEvapotranspiration{ 
		return (volumeEvapotranspirationHydro + volumeEvapotranspirationRPG);
	}	
	float getVolumeEcoulementEauSouterraine{ // Qgw [m3]			
		return (volumeEcoulementEauSouterraineHydro + volumeEcoulementEauSouterraineRPG);
	}
	
	// JV 130818 debug  
	float getEauStockeeAquiferePeuProfondHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(eauStockeeAquiferePeuProfond/1000.0) * float(surface);
	}
	
	return res;
}
	
	// JV 130818 debug  
	float getRuissHydroFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ruissellementDeSurfaceHRU/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
}

	// JV 130818 debug  
	float getRuissRPGFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUrpgAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ruissellementDeSurfaceHRU/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
}

	// JV 130818 debug  
	float getLatHydroFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ecoulementLateral/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
}

	// JV 130818 debug  
	float getLatRPGFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUrpgAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ecoulementLateral/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
}

	// JV 130818 debug  
	float getSoutHydroFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ecoulementEauSouterraine/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
}

	// JV 130818 debug  
	float getSoutRPGFromHRU{
	float res <- 0.0;
	float surfTot <- 0.0;
	
	ask listeHRUrpgAssociees{
		surfTot <- surfTot + float(surface);
		res <- res + float(ecoulementEauSouterraine/1000.0) * float(surface);
	}
	
	return res; // [m3]    		
	}

	// JV 250420
	float getVolumePercolationHydro{
		float res <- 0.0; // [m3]
		ask listeHRUAssociees{
			res <- res + float(getPercolationDerniereCouche())/nombreMillimetreDansUnMetre*surface;
		}
		return res;
	}
	
	// JV 250420
	float getVolumePercolationTotal{
		return getVolumePercolationHydro() + volumePercolationRPG;
	}
	

	// JV 200219 debug
	action checkBilanPhaseSol{
		
		string nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol.csv';
		string nomFichierJournalierZH <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol_' + name + '.csv';
		string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + name + ";";
		
		float pluieTot <- 0.0;
		//float ruissTot <- volumeRuissellementDeSurfaceHydro + volumeRuissellementDeSurfaceRPG;
		float ruissTot <- volumeRuissellementDeSurfaceRPG; // ruissellementHydro calculé dans la boucle car volumeRuissellementDeSurfaceHydro=Qday et pas Qsurf
		float ETTot <- volumeEvapotranspirationHydro + volumeEvapotranspirationRPG;
		//float ecoulSoutTot <- volumeEcoulementEauSouterraineHydro + volumeEcoulementEauSouterraineRPG;
		float ecoulSoutTot <- 0.0;
		float ecoulLatTot <- volumeEcoulementLateralRPG;
		float percolTot <- 0.0;
		float recapTot <- 0.0;
		float SWTot <- 0.0;
		float irrigTot <- 0.0;
		float aquiferePeuProfondTot <- 0.0;
		float aquifereProfondTot <- 0.0;
		float entreeAquifereTot <- 0.0;
		float surfTot <- 0.0;
		
		if(!bilanSolEnteteDejaEcrit){ // first day
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalier format: 'csv' rewrite:false;
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalierZH format: 'csv' rewrite:false;
			bilanSolEnteteDejaEcrit <- true;
		}
		
	ask listeHRUAssociees{
		surfTot <- surfTot + surface;
		ruissTot <- ruissTot + ruissellementDeSurfaceHRUtotal/nombreMillimetreDansUnMetre * surface;
		percolTot <- percolTot + getPercolationDerniereCouche()/nombreMillimetreDansUnMetre * surface;
		recapTot <- recapTot + eauRevap/nombreMillimetreDansUnMetre * surface;
			SWTot <- SWTot + sum(mapTeneurEnEauSolParCouche.values)/nombreMillimetreDansUnMetre * surface;
			aquiferePeuProfondTot <- aquiferePeuProfondTot + eauStockeeAquiferePeuProfond/nombreMillimetreDansUnMetre * surface;
			aquifereProfondTot <- aquifereProfondTot + eauAquifereProfond/nombreMillimetreDansUnMetre * surface;
			entreeAquifereTot <- entreeAquifereTot + eauEntreeAquiferes/nombreMillimetreDansUnMetre * surface;				
			ecoulLatTot <- ecoulLatTot + ecoulementLateralPourBilanSol/nombreMillimetreDansUnMetre * surface; 				
			ecoulSoutTot <- ecoulSoutTot + ecoulementEauSouterraine/nombreMillimetreDansUnMetre * surface;
	}
		
		percolTot <- percolTot + volumePercolationRPG;
		SWTot <- SWTot + volumeHumiditeHorizonTotalRPG;
		
	ask listeHRUrpgAssociees{
		surfTot <- surfTot + surface;
		recapTot <- recapTot + eauRevap/nombreMillimetreDansUnMetre * surface;    			
		irrigTot <- irrigTot + getVolumeIrrigationSurParcellesAssociees();
			aquiferePeuProfondTot <- aquiferePeuProfondTot + eauStockeeAquiferePeuProfond/nombreMillimetreDansUnMetre * surface;
			aquifereProfondTot <- aquifereProfondTot + eauAquifereProfond/nombreMillimetreDansUnMetre * surface;
			entreeAquifereTot <- entreeAquifereTot + eauEntreeAquiferes/nombreMillimetreDansUnMetre * surface;				
			ecoulSoutTot <- ecoulSoutTot + ecoulementEauSouterraine/nombreMillimetreDansUnMetre * surface;
	}
							
		pluieTot <- pluie/nombreMillimetreDansUnMetre * surfTot;
		
		float deltaSW <- SWTot - SWprec;
		float deltaFlux <- pluieTot + irrigTot - ruissTot - ETTot - percolTot - ecoulLatTot + recapTot; 
		float deltaAqPeuProf <- aquiferePeuProfondTot - aqPeuProfPrec;
		float deltaFluxNappe <- entreeAquifereTot - aquifereProfondTot - recapTot - ecoulSoutTot;
		
		chaineAEcrire <- chaineAEcrire + deltaSW + ';' + deltaFlux + ';' + SWTot + ';' + SWprec + ';' + pluieTot + ';' + ruissTot + ';' + ETTot + ';' + percolTot + ';' + ecoulLatTot + ';' + ecoulSoutTot + ';' + recapTot + ';' + irrigTot + ';' + deltaAqPeuProf + ';' + deltaFluxNappe + ';' + aquiferePeuProfondTot + ';' + aqPeuProfPrec + ';' + entreeAquifereTot + ';' + aquifereProfondTot;   			
		save chaineAEcrire to: nomFichierJournalier format: 'csv' rewrite:false;
		save chaineAEcrire to: nomFichierJournalierZH format: 'csv' rewrite:false;
		
		SWprec <- SWTot;		
		aqPeuProfPrec <- aquiferePeuProfondTot;
		
	}
	
	// JV 200219 debug
	action checkBilanPhaseSol_Hydro{
		
		string nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol_hydro.csv';			
		string nomFichierJournalierZH <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol_hydro_' + name + '.csv';
		string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + name + ";";
		
		float pluieTot <- 0.0;
		//float ruissTot <- volumeRuissellementDeSurfaceHydro;
		float ruissTot <- 0.0; // car volumeRuissellementDeSurfaceHydro
		float ETTot <- volumeEvapotranspirationHydro;
		//float ecoulSoutTot <- volumeEcoulementEauSouterraineHydro;
		float ecoulSoutTot <- 0.0;
		float ecoulLatTot <- 0.0;
		float percolTot <- 0.0;
		float recapTot <- 0.0;
		float SWTot <- 0.0;
		float irrigTot <- 0.0;
		float aquiferePeuProfondTot <- 0.0;
		float aquifereProfondTot <- 0.0;
		float entreeAquifereTot <- 0.0;
		float surfTot <- 0.0;
		
		if(!bilanSolEnteteDejaEcrit_hydro){ // first day
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalier format: 'csv' rewrite:false;
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalierZH format: 'csv' rewrite:false;
			save "date;ZH;HRU;couche;fc;sw;perc;et;ecouLat;pluieHRU;ruissHRU" to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugCouchesSolParHRU.csv' format: 'csv' rewrite:false;
			save "date;ZH;HRU;sw;pluie;recap;percol;et;ecoulLat;ruiss" to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugParHRU.csv' format: 'csv' rewrite:false;
			bilanSolEnteteDejaEcrit_hydro <- true;
		}
		
	ask listeHRUAssociees{
		surfTot <- surfTot + surface;
		ruissTot <- ruissTot + ruissellementDeSurfaceHRUtotal/nombreMillimetreDansUnMetre * surface; // JV: ruissellementDeSurfaceHRUtotal = Qsurf, ruissellementDeSurfaceHRU = qday
		percolTot <- percolTot + getPercolationDerniereCouche()/nombreMillimetreDansUnMetre * surface;
		recapTot <- recapTot + eauRevap/nombreMillimetreDansUnMetre * surface;
			SWTot <- SWTot + sum(mapTeneurEnEauSolParCouche.values)/nombreMillimetreDansUnMetre * surface;
			aquiferePeuProfondTot <- aquiferePeuProfondTot + eauStockeeAquiferePeuProfond/nombreMillimetreDansUnMetre * surface;
			aquifereProfondTot <- aquifereProfondTot + eauAquifereProfond/nombreMillimetreDansUnMetre * surface;
			entreeAquifereTot <- entreeAquifereTot + eauEntreeAquiferes/nombreMillimetreDansUnMetre * surface;
			ecoulLatTot <- ecoulLatTot + ecoulementLateralPourBilanSol/nombreMillimetreDansUnMetre * surface;
			ecoulSoutTot <- ecoulSoutTot + ecoulementEauSouterraine/nombreMillimetreDansUnMetre * surface;				 
	}
		
		pluieTot <- pluie/nombreMillimetreDansUnMetre * surfTot;
		
		float deltaSW <- SWTot - SWprec_hydro;
		float deltaFlux <- pluieTot + irrigTot - ruissTot - ETTot - percolTot - ecoulLatTot + recapTot; 
		float deltaAqPeuProf <- aquiferePeuProfondTot - aqPeuProfPrec_hydro;
		float deltaFluxNappe <- entreeAquifereTot - aquifereProfondTot - recapTot;
		
		chaineAEcrire <- chaineAEcrire + deltaSW + ';' + deltaFlux + ';' + SWTot + ';' + SWprec_hydro + ';' + pluieTot + ';' + ruissTot + ';' + ETTot + ';' + percolTot + ';' + ecoulLatTot + ';' + ecoulSoutTot + ';' + recapTot + ';' + irrigTot + ';' + deltaAqPeuProf + ';' + deltaFluxNappe + ';' + aquiferePeuProfondTot + ';' + aqPeuProfPrec_hydro + ';' + entreeAquifereTot + ';' + aquifereProfondTot;   			
		save chaineAEcrire to: nomFichierJournalier format: 'csv' rewrite:false;
		save chaineAEcrire to: nomFichierJournalierZH format: 'csv' rewrite:false;
		
		SWprec_hydro <- SWTot;			
		aqPeuProfPrec_hydro <- aquiferePeuProfondTot;
		
		// JV 170519 extrait SW pour chaque couche de sol de chaque HRU pour certains jours identifiés de la ZH 3451
		if(name="3451"){ 
			string idZH <- name;
			float pluieZH <- pluie; 
			if(((dateCour.annee=2006) and (dateCour.mois=10)) or ((dateCour.annee=2005) and (dateCour.mois=9)) or ((dateCour.annee=2003) and (dateCour.mois=2)) or ((dateCour.annee=2002) and (dateCour.mois=4)) or ((dateCour.annee=2001) and (dateCour.mois=7)) or ((dateCour.annee=2003) and (dateCour.mois=12)) or ((dateCour.annee=2006) and (dateCour.mois=4 or dateCour.mois=5))){
	    		ask listeHRUAssociees{
	    			map<int,float> capaciteAuChamp <- sol.capaciteAuChamp;		    			
	    			loop indiceCoucheSol from: 1 to: getNbCouches(){
	    				chaineAEcrire <- string(dateCour.annee as int) + "-" + string(dateCour.mois as int) + "-" + string(dateCour.jour as int) + ";" + idZH + ";" + idHRU + ";" + indiceCoucheSol + ";" + capaciteAuChamp at indiceCoucheSol + ";" + mapTeneurEnEauSolParCouche at indiceCoucheSol + ";" + mapPercolationParCouche at indiceCoucheSol + ";" + mapEvapotranspirationParCouche at indiceCoucheSol + ";" + mapEcoulementLateralParCouche at indiceCoucheSol + ";" + pluieZH + ";" + ruissellementDeSurfaceHRUtotal;
	    				save chaineAEcrire to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugCouchesSolParHRU.csv' format: 'csv' rewrite:false;
	    			}
    				chaineAEcrire <- string(dateCour.annee as int) + "-" + string(dateCour.mois as int) + "-" + string(dateCour.jour as int) + ";" + idZH + ";" + idHRU + ";" + sum(mapTeneurEnEauSolParCouche.values) + ";" + pluieZH + ";" + eauRevap + ";" + getPercolationDerniereCouche() + ";" + evapoTranspirationReelle + ";" + ecoulementLateral + ";" + ruissellementDeSurfaceHRUtotal;  
					save chaineAEcrire to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugParHRU.csv' format: 'csv' rewrite:false;		    			
	    		}					
			}
			/*
			write "HRU hydro";
			ask listeHRUAssociees{
				write idHRU + " " + surface + " " + penteAssociee + " " + fractionDansZH + " " + sol;
			}
			write "HRU RPG";
			ask listeHRUrpgAssociees{
				write idHRU + " " + surface + " " + penteAssociee + " " + fractionDansZH + " " + sol;
			}
			*/				
		}
	}
	
	// JV 200219 debug
	action checkBilanPhaseSol_RPG{
		
		string nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol_RPG.csv';			
		string nomFichierJournalierZH <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanSol_RPG_' + name + '.csv';
		string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + name + ";";
		
		float pluieTot <- 0.0;
		float ruissTot <- volumeRuissellementDeSurfaceRPG;
		float ETTot <- volumeEvapotranspirationRPG;
		//float ecoulSoutTot <- volumeEcoulementEauSouterraineRPG;
		float ecoulSoutTot <- 0.0;
		float ecoulLatTot <- volumeEcoulementLateralRPG;
		float percolTot <- volumePercolationRPG;
		float recapTot <- 0.0;
		float SWTot <- volumeHumiditeHorizonTotalRPG;
		float irrigTot <- 0.0;
		float aquiferePeuProfondTot <- 0.0;
		float aquifereProfondTot <- 0.0;
		float entreeAquifereTot <- 0.0;
		float surfTot <- 0.0;
		
		if(!bilanSolEnteteDejaEcrit_RPG){ // first day
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalier format: 'csv' rewrite:false;
			save 'date;ZH;deltaSw;deltaFluxSol;Sw_t;Sw_prec;pluie;ruiss;ET;percol;ecoulLat;ecoulSout;recap;irrig;deltaAqPeuProf;deltaFluxNappe;aqPeuProf_t;aqPeuProf_prec;entreeAquifere;aqProf' to: nomFichierJournalierZH format: 'csv' rewrite:false;
			save "date;ZH;HRU;sw;pluie;recap;percol;et;ecoulLat;ruiss" to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugParHRU_ZH192.csv' format: 'csv' rewrite:false;
			bilanSolEnteteDejaEcrit_RPG <- true;
		}
				
	ask listeHRUrpgAssociees{
		surfTot <- surfTot + surface;
		recapTot <- recapTot + eauRevap/nombreMillimetreDansUnMetre * surface;
		irrigTot <- irrigTot + getVolumeIrrigationSurParcellesAssociees();
			aquiferePeuProfondTot <- aquiferePeuProfondTot + eauStockeeAquiferePeuProfond/nombreMillimetreDansUnMetre * surface;
			aquifereProfondTot <- aquifereProfondTot + eauAquifereProfond/nombreMillimetreDansUnMetre * surface;
			entreeAquifereTot <- entreeAquifereTot + eauEntreeAquiferes/nombreMillimetreDansUnMetre * surface;
			ecoulSoutTot <- ecoulSoutTot + ecoulementEauSouterraine/nombreMillimetreDansUnMetre * surface;								
	}
							
		pluieTot <- pluie/nombreMillimetreDansUnMetre * surfTot;
		
		float deltaSW <- SWTot - SWprec_RPG;
		float deltaFlux <- pluieTot + irrigTot - ruissTot - ETTot - percolTot - ecoulLatTot + recapTot; 
		float deltaAqPeuProf <- aquiferePeuProfondTot - aqPeuProfPrec_RPG;
		float deltaFluxNappe <- entreeAquifereTot - aquifereProfondTot - recapTot;
		
		chaineAEcrire <- chaineAEcrire + deltaSW + ';' + deltaFlux + ';' + SWTot + ';' + SWprec_RPG + ';' + pluieTot + ';' + ruissTot + ';' + ETTot + ';' + percolTot + ';' + ecoulLatTot + ';' + ecoulSoutTot + ';' + recapTot + ';' + irrigTot + ';' + deltaAqPeuProf + ';' + deltaFluxNappe + ';' + aquiferePeuProfondTot + ';' + aqPeuProfPrec_RPG + ';' + entreeAquifereTot + ';' + aquifereProfondTot;   			
		save chaineAEcrire to: nomFichierJournalier format: 'csv' rewrite:false;
		save chaineAEcrire to: nomFichierJournalierZH format: 'csv' rewrite:false;
		
		SWprec_RPG <- SWTot;			
		aqPeuProfPrec_RPG <- aquiferePeuProfondTot;

		// JV check ZH 192
		if(name="192"){ 
			string idZH <- name;
			float pluieZH <- pluie; 
			if((dateCour.annee=2003) and (dateCour.mois=8)){
	    		ask listeHRUrpgAssociees{
    				chaineAEcrire <- string(dateCour.annee as int) + "-" + string(dateCour) + "-" + string(dateCour.jour as int) + ";" + idZH + ";" + idHRU + ";" + sum(mapTeneurEnEauSolParCouche.values) + ";" + pluieZH + ";" + eauRevap + ";" + getPercolationDerniereCouche() + ";" + evapoTranspirationReelle + ";" + ecoulementLateral + ";" + ruissellementDeSurfaceHRU;  
					save chaineAEcrire to: cheminRelatifDuDossierDeSortieDeSimulation +'/debugParHRU_ZH192.csv' format: 'csv' rewrite:false;		    			
	    		}					
			}
			
		}
	}

	action checkBilanPhaseRoutage{
		
		string nomFichier <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanRoutage.csv';
		
		if(!bilanRoutageEnteteDejaEcrit){
			save 'date;ZH;volumeStockePrec;volumeStocke;volumeEntree;volumeUtileAvanPrelevEtRejet;prelev;rejets;ruissRPG;ecoulLatRPG;ecoulSoutRPG;volumeSorti;evapFlux;evapStock' to: nomFichier format: 'csv' rewrite:false;
			bilanRoutageEnteteDejaEcrit <- true;
		}
		
		string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + name + ";";
		chaineAEcrire <- chaineAEcrire + ";" + idZoneHydrographique + ";" + volumeStockePrec + ";" + volumeStocke + ";" + getVolumeEntreePhaseRoutage() + ";" + getVolumeUtileAvantPrelevementEtRejet(SURF) + ";" + getVolumePreleve(SURF, REEL) + ";" + getVolumeRejet() + ";" + volumeRuissellementDeSurfaceRPG + ";" + volumeEcoulementLateralRPG + ";" + volumeEcoulementEauSouterraineRPG + ";" + volumeSorti + ";" + evaporationCH1 + ";" + evaporationCH2;
		save chaineAEcrire to: nomFichier format: 'csv' rewrite:false;
					
	}

	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- "[ZH] " + name;
		resultat <- resultat + ' - temperatureMoy : ' + tMoy;
		resultat <- resultat + ' - temperatureMin : ' + tMin;
		resultat <- resultat + ' - temperatureMax : ' + tMax;
		resultat <- resultat + ' - pluie : ' + pluie;
		resultat <- resultat + ' debitCourant : ' + debitCourant;
		return resultat; 					
		}				 				
}
