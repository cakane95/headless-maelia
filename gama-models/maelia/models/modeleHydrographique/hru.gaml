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
 *  hru
 *  Author: Maroussia Vavasseur
 *  Description: Une HRU est un decoupage de la ZH en zone non georeferencees crees en fonction de : (pente,surface,clc)
 * 				 Pour des raisons de conformite au modele, tout est exprime en millimetre pour dans les HRU. La conversion en  metre se fait dans la ZH.
 */

model hru

import "zoneHydrographique.gaml"

global{
	string hruShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/hru/hru_0.25.shp';	// hru_0.0  hru_0.25
	string hruSansIlotsShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/hru/hruSansIlots_0.25.shp';	
	list<hru> listeHrus <- [];
	hru hruAffichee <- nil;
	float fractionEcoulementEauxSouterraines <- exp(-recessionEcoulementEauxSouterrainesGlobal*nbHeuresDansPasDeTemps); // on multiplie par 24H car unite differente de la doc theorique

	/*
	 * *****************************************************************************************
	 * Publique
	 * On cree toutes les HRU possibles au sein dune ZH, meme si celle ci correspond a une fraction de 0 (car ilot a la place), cela au cas ou lors de la disparition de lilot, on ai un nouveau type de sol de HRU par exemple
	 */ 
	action constructionHRUs{
		string chemin <- '';
		if(!executerModeleAgricole){
			chemin <- hruShape;
		}else{
			chemin <- hruSansIlotsShape;
		}

		if !file_exists(chemin)	{do raiseError("fichier inexistant: " + chemin);}
		//if !is_shape(chemin)	{do raiseError("le fichier " + chemin + " n'est pas un fichier shape");}	

		create hru from: file(chemin) with: [		idHRU::string(read ( ID_HRU )),  
											surface::float(read( SURFACE )),
											fractionDansZH::float(read( FRACTION )),
											penteAssociee::float(read( "ID_PENTE" ))]{ // PENTE_MOY
			
			name <- idHRU;
			zh <- zoneHydrographiqueSWAT(mapZH at string(shape get( ID_ZH )));		
			if(zh != nil){
				sol <- first(zh.listeTypeDeSolAssocies where (each.idTypeDeSOl = string(shape get(ID_SOL)))); // STU_DOM si lance avec HRU_0.0.shp
				clcAssocie <- first(zh.landCoverAssocie where (each.idClc = string(shape get( ID_CLC ))));		
				if(sol = nil or clcAssocie = nil){
					write "" + idHRU + " - [HRU/INIT] ATTENTION le sol ou le clc de la HRU lue est nul (sol = " + sol + " : "+string(shape get(ID_SOL))+ " - clc = " + clcAssocie + ")";
				}										
			}
			if(zh = nil or sol = nil or clcAssocie = nil or fractionDansZH < 0.001){
				ask self{
					do die();	
				}						
			}else{	
				penteAssociee <- penteAssociee / 100;
				couleurHRU <- rgb([rnd(255), rnd(255), rnd(255)]);								
				do initialisationHRU();	

				zh.listeHRUAssociees << self; 							
				listeHrus << self;					
				if(clcAssocie.typeClasse = FORET){
					hruAffichee <- self;
				}				
			}
		}
		
//		/*
//		 * DEBUG
//		 */			
//		ask listeZonesHydrographiques{	
//			let somme type: float value: 0.0;
//			let sommeFraction type: float value: 0.0;
//			ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
//				set somme value: somme + surface;
//				set sommeFraction value: sommeFraction + fractionDansZH;
//								
////				if(fractionDansZH * 100 < 5.0){
////					write '[HRU/Init] ' + name + ' fractionDansZH = ' + fractionDansZH * 100;			
////				}									 
//			}
//			write '[HRU/Init] ZH = ' + name + ' sommeSurface = ' + somme / shape.area;											
//			write '[HRU/Init] ZH = ' + name + ' sommeFraction = ' + sommeFraction;	
//			
////			write '[HRU/Init] ZH = ' + name + ' surfaceZhSansIlots = ' + surfaceZhSansIlots;		
////			write '[HRU/Init] ZH = ' + name + ' shape.area = ' + shape.area;				
//		}						
	}
}

species hru{
	string idHRU <- '';
	zoneHydrographiqueSWAT zh <- nil;
	float fractionDansZH <- 0.0; // FrHRU
	float surface <- 0.0;
	typeDeSol sol <- nil;
	clc clcAssocie <- nil;
	float penteAssociee <- 0.0;
	bool isHRUimpermeable <- false; // si cest du bati
	rgb couleurHRU <- rgb('white');
	
	// Curve Number for runoff calculation
	float curveNumber1 <- 0.0; // CN1
	float curveNumber2 <- 0.0; // CN2
	float curveNumber3 <- 0.0; // CN3
	
// ----------------------------------------- Phase Sol -----------------------------------------
	// Variables : commun
	map<int, float> mapTeneurEnEauSolParCouche <- map<int, float>([]); // indiceCouche::SW,ly  [mm]
	float teneurEnEau <- 0.0; // [mm]   -> avant evapotranspiration et apres percolation (utile uniquement pour la verification de la balance deau)
	float teneurEnEauPrec <- 0.0; // [mm]   -> avant evapotranspiration et apres percolation (utile uniquement pour la verification de la balance deau)
	float perteParTransmission <- 0.0;  // tlss,surq  [mm]		
	// Variables : ruissellement
	float ruissellementDeSurfaceHRU <- 0.0; // qDay [mm]  -> la quantite qui part effectivement vers la ZH le jour courant
	float ruissellementDeSurfaceHRUtotal <- 0.0; // Qsurf(j) [mm]  -> on a besoin de garder la quantite total pour le calcul de leau qui arrive bien dans le sol
	float ruissellementDeSurfaceHRUStockeePrec <- 0.0; // Qstor(j-1) [mm]
	float parametreDeRetention <- 0.0; // S(j) [mm]	
	float curveNumber <- 0.0; // CN		
	// Variables : ecoulement lateral
	float ecoulementLateral <- 0.0;  // latDay  [mm]   -> la quantite qui part effectivement vers la ZH le jour courant	
	float ecoulementLateralPourBilanSol <- 0.0; // JV 300519 idem mais sans prendre en compte le temps de latence
	float ecoulementLateralStockeeJourPrecedent <- 0.0; // latStor(j-1) [mm] 	
	map<int, float> mapPercolationParCouche <- map<int, float>([]); // omegaPerc(indiceCouche)    indiceCouche::(quantite Eau Qui Sinfiltre Dans La Couche Inferieure)
	map<int, float> mapEcoulementLateralParCouche <- map<int, float>([]); // JV 260519 pour debug
	// Variables : evapotranspiration
	float evapoTranspirationReelle <- 0.0; // Ea [mm]
	map<int, float> mapEvapotranspirationParCouche <- map<int, float>([]); // JV 260519 pour debug
	// Variables : base flow
	float ecoulementEauSouterraine <- 0.0;  // Qgw  [mm]
	float eauEntreeAquiferes <- 0.0;  // omegaRchrg(i)	
	float eauAquifereProfond <- 1500.0; // omegaDeep  [mm]
	float eauRevap <- 0.0;  // omegaRevap
	float eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfondInit;  // aqSh(i)	
	float hauteur_nappe <- 0.0; //hwtbl (m)
	
	// Constantes : Constante liees a la ZH		
	float tempsDeConcentrationHRU <- 0.0; // tConc
	float fractionRuissellement <- 0.0; // brt
	float fractionEcoulementDeSurface <- 1.0; // FrTtlag
	float parametreDeRetentionMax <- 0.0; // Smx [mm] 
	float coefDeFormePourRetention1 <- 0.0; // omega1
	float coefDeFormePourRetention2 <- 0.0; // omega2
	// NEIGE
	map<bandeAltitude, float> bandesDelevation <- map<bandeAltitude, float>([]); // bandeAltiZH::FractionHRU dans bande (initialisees dans bande elevation)
	float eauDansPaquetNeigeHRU <- 0.0; // snoHRU
	map<bandeAltitude,float> eauDansPaquetNeigeHRUParBande <- map<bandeAltitude, float>([]); // snoeb,hru,

	// JV debug
	float sommeEntreeAquifere <- 0.0;
	float sommeEauSout <- 0.0;
	
	/*
	 * *****************************************************************************************
	 */	
	action initialisationHRU{				
		// SI RPG : Je reajuste la surface des hru avec les parcelles en prairies * (associees a un ilot contenant des parcelles de grandes cultures)
		map<string, float> mapClef <- map<string, float>([]);	
		put penteAssociee at: (sol.idTypeDeSOl) in: mapClef;
		if((mapSurfaceParcellesAtraiteesParHydro at mapClef) != nil and clcAssocie.idClasse = 2){				
			float surfaceAajouter <- mapSurfaceParcellesAtraiteesParHydro at mapClef;
			surface <- surface + surfaceAajouter;
			fractionDansZH <- surface / zh.shape.area;
		}	
		
		// Initialisation teneur en sol par couche et par jour
		loop indiceCoucheSol from: 1 to: sol.nbCouches{	
			float sw0 <- (sol.capaciteAuChamp at indiceCoucheSol) * coefEauCoucheInit;		
			put sw0/2 at: indiceCoucheSol in: mapTeneurEnEauSolParCouche;
		}
//			put sum(mapTeneurEnEauSolParCouche.values) at: (dateCour.indiceDate - 1) in: mapTeneurEnEauTotalParJour;
		teneurEnEau <- sum(mapTeneurEnEauSolParCouche.values);
		
		// Calcul du temps de concentration et des fractions qui vont effectivement aller a la ZH le jour courant (une fois)
			// Ruissellement			
		float tempsTerrainHRU <- ((zh.longueurMoyennePente * coefficientManningTerrain)^0.6) / (18* (penteAssociee^0.3));
        float tempsCoursEauHRU <- (0.62 * getLongueurCoursEauTributaireMax() * (coefficientManningTerrain^0.75)) / ((getSurfaceKm2())^0.125 * (zh.penteMoyenneCoursEauTributaire^0.375));
        tempsDeConcentrationHRU <- tempsTerrainHRU + tempsCoursEauHRU;
        fractionRuissellement <-  1 - exp(-coefficientSurfaceRuissellementLag / tempsDeConcentrationHRU);				// Ecoulement lateral
		float tempsDeConcentrationEcoulementSurface <- 10.4 * zh.longueurMoyennePente / max(sol.conductiviteHydroliqueSaturee.values); // TTlag
		fractionEcoulementDeSurface <- 1 - exp(-1 / tempsDeConcentrationEcoulementSurface);	
		
		// Calcul des CN
		curveNumber3 <- clcAssocie.curveNumber2 * exp(0.00673 * (100 - clcAssocie.curveNumber2));
		curveNumber2 <- (curveNumber3 - clcAssocie.curveNumber2)/3 * (1 -2 * exp(-13.86 * penteAssociee)) + clcAssocie.curveNumber2; // Effect of slope on curveNumber
		curveNumber3 <- curveNumber2 * exp(0.00673 * (100 - curveNumber2));
		curveNumber1 <- curveNumber2 - (20*(100 - curveNumber2) / (100 - curveNumber2 + exp(2.533 - 0.0636 * (100 - curveNumber2))));		
		curveNumber1 <- max([curveNumber1, 0.4*curveNumber2]);					
		
		// Calcul de Smax et omege1 et 2 (une fois)
		parametreDeRetentionMax <- 254 * (100/curveNumber1 - 1);
		float s3 <- 254 * (100/curveNumber3 - 1);
		float fc <- sum(sol.capaciteAuChamp.values);
		float sat <- sum(sol.saturation.values);
		float xx1 <- 1 - s3/parametreDeRetentionMax;
		float xx2 <- 1 - 2.54/parametreDeRetentionMax;	
		float xx3 <- 0.0;
		if((fc/xx1 - fc) > 0.0){
			xx3 <- ln(fc/xx1 - fc);
		}else{
			write "[HRU/init] PB VALEUR < 0";
		}
		coefDeFormePourRetention2 <- (xx3 - ln(abs(sat/xx2 - sat))) / (sat - fc);
		coefDeFormePourRetention1 <- xx3 + coefDeFormePourRetention2*fc;
		
		// Inialisation des BANDEs ELEVATION des HRU
		ask(zh.bandesDelevation){
			if(self.shape intersects (myself.shape+0.01)){ //+0.01 = petite rustine pour windows pour eviter une exception de geotools sous GAMA 1.6
			//if(self.shape  intersects (myself.shape)){ //+0.01 = petite rustine pour windows pour eviter une exception de geotools sous GAMA 1.6

				float fractionAlt <- (self.shape intersection myself.shape).area / myself.shape.area;
				//float fractionAlt <- (self.shape).area / myself.shape.area;
				put fractionAlt at: self in: myself.bandesDelevation;
			}					
		}				
	}

	/*
	 * *****************************************************************************************
	 * 1 -Methode calculant la quantite deau de ruissellement de la HRU va arrivee dans le cour deau principal
	 */	
	float calculRuissellementDeSurface{	
		float sw <- sum(mapTeneurEnEauSolParCouche.values); // somme teneur en eau dans le sol de toutes les couchess			 			 
															// en excluant la teneur en eau en dessous du point de 
															// fletrissement!
		if (isNeige){
			ruissellementDeSurfaceHRUtotal <- 0.0;
			ask(bandesDelevation.keys){ 
				float fractionHRU <- myself.bandesDelevation at self;	
				if(precipitations >= 0.0){
					// a -Calcul d'une varable temporaire qui doit etre comprise entre -20 et 20
					float yy <- myself.coefDeFormePourRetention1 - myself.coefDeFormePourRetention2*sw;
					if(yy < -20){
						yy <- -20.0;
					}else if(yy > 20){
						yy <- 20.0;
					}								
					// b -Calcul de S
					if((sw + exp(yy)) > 0.001){
						myself.parametreDeRetention <- myself.parametreDeRetentionMax * (1 - sw / (sw + exp(yy)));
					}else{
						write '[HRU/calculRuissellementDeSurface] Probleme de valeur de sw ! ';
					}			
					// c -Calcul du curve number
					myself.curveNumber <- 25400 / (myself.parametreDeRetention+254);												
				}
				// 2 -Calcul de linfiltration et interception
				float ia <- 0.2 * myself.parametreDeRetention;
				
				// 3 -Calcul du ruissellement total sur la journee
				if((precipitations - ia) > 0.0){
					myself.ruissellementDeSurfaceHRUtotal <- myself.ruissellementDeSurfaceHRUtotal + ((precipitations - ia)^2 / (precipitations + 0.8*myself.parametreDeRetention)) * fractionHRU; 
				}else{
					myself.ruissellementDeSurfaceHRUtotal <- 0.0;
				}
				
			}
		}else{
			if(zh.pluie >= 0.0){
				// a -Calcul d'une varable temporaire qui doit etre comprise entre -20 et 20
				float yy <- coefDeFormePourRetention1 - coefDeFormePourRetention2*sw;
				if(yy < -20){
					yy <- -20.0;
				}else if(yy > 20){
					yy <- 20.0;
				}								
				// b -Calcul de S
				if((sw + exp(yy)) > 0.001){
					parametreDeRetention <- parametreDeRetentionMax * (1 - sw / (sw + exp(yy)));
				}else{
					write '[HRU/calculRuissellementDeSurface] Probleme de valeur de sw ! ';
				}			
				// c -Calcul du curve number
				curveNumber <- 25400 / (parametreDeRetention+254);												
			}
				
			// 2 -Calcul de linfiltration et interception
			float ia <- 0.2 * parametreDeRetention;
			
			// 3 -Calcul du ruissellement total sur la journee
			if((zh.pluie - ia) > 0.0){
				ruissellementDeSurfaceHRUtotal <- (zh.pluie - ia)^2 / (zh.pluie + 0.8*parametreDeRetention); 
			}else{
				ruissellementDeSurfaceHRUtotal <- 0.0;
			}

		}
		
		// 3 - Si Bati
		if(clcAssocie.typeClasse = BATI){
			float curveNumberImp <- 98.0;
			float parametreDeRetentionImp <- 25.4 * (1000 / curveNumberImp -10);
			float iaImp <- 0.2 * parametreDeRetentionImp;
			
			if((zh.pluie - iaImp) > 0.0){
				float ruissellementDeSurfaceHRUtotalImp <- (zh.pluie - iaImp)^2 / (zh.pluie + 0.8*parametreDeRetentionImp); 					
				ruissellementDeSurfaceHRUtotal <- ruissellementDeSurfaceHRUtotal * (1-fractionImpermeable) + ruissellementDeSurfaceHRUtotalImp * fractionImpermeable;
			}
		}
					
		// 4 -Calcul quantite stockee pour jour suivant
		ruissellementDeSurfaceHRUStockeePrec <- max([0.000001, ruissellementDeSurfaceHRUtotal+ruissellementDeSurfaceHRUStockeePrec]);
		ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRUStockeePrec * fractionRuissellement;
		ruissellementDeSurfaceHRUStockeePrec <- ruissellementDeSurfaceHRUStockeePrec - ruissellementDeSurfaceHRU;
//			do calculPerteParTransmissionDuRuissellementDeSurface pluieEntree: pluie;			

		return ruissellementDeSurfaceHRU;					
	}	

	/*
	 * *****************************************************************************************
	 * 2 -Calcul de lecoulement lateral (inter flow) (eau infiltree dans le sol)
	 */	
	float calculEcoulementLateral{	
		ecoulementLateral <- 0.0;  // Qlat  [mm]
		
		// 1- calcul de leau arrivant sur la surface (utilisee ensuite pour la premiere couche)
		float percolation0 <- zh.pluie - ruissellementDeSurfaceHRUtotal;
					
		// 2 -Calcul teneur en eau dans chaque couches
		loop indiceCoucheSol from: 1 to: sol.nbCouches{
			float kSat <- sol.conductiviteHydroliqueSaturee at indiceCoucheSol;			
			float fc <- sol.capaciteAuChamp at indiceCoucheSol;
			float wp <- sol.pointFletrissementPermanent at indiceCoucheSol;
			float sat <- sol.saturation at indiceCoucheSol;
			float tempsParcoursPercolation <- (sat - fc)/kSat;  // TTperc
			put 0.0 at: indiceCoucheSol in: mapEcoulementLateralParCouche; // JV debug (au cas où pas remplie dans le if)
						
			// a -Calcul percolation par couche
			float swPrec <- (mapTeneurEnEauSolParCouche at indiceCoucheSol);
			float percolationCouchePrec <- 0.0;
			if(indiceCoucheSol = 1){
				percolationCouchePrec <- percolation0;
			}else{
				percolationCouchePrec <- mapPercolationParCouche at (indiceCoucheSol - 1);
			}				
			float sw <- swPrec + percolationCouchePrec;				
			float swExces <- 0.0;
			if(sw > fc){
				swExces <- sw - fc;					
			}else{
				swExces <- 0.0;
			}

			float percolation <- 0.0;
			if(swExces > 0.0){
				// b -Calcul ecoulement lateral par couche				
				float dg <- (sol.mapEpaisseurParCouche at indiceCoucheSol);
				float h0 <- 0.0;
				if((sat - fc) > 0.0){
					h0 <- 2*swExces*dg / (sat-fc);
				}					
				float ecoulementLateralCoucheCourante <- max([0.0, min([swExces, nbHeuresDansPasDeTemps*h0*(kSat * penteAssociee) / (zh.longueurMoyennePente * nombreMillimetreDansUnMetre)])]); // Qlat,ly				
				// JV unité: [h]*[mm]*[mm/h]*[1]/([m]*1000) = [mm]^2/[mm] = [mm]
				
				// Calcul percolation
				percolation <- swExces * (1-exp(-nbHeuresDansPasDeTemps/tempsParcoursPercolation)) ; // omegaPerc,ly
				
																	
				// c -Verification de la balance de leau
				if((ecoulementLateralCoucheCourante + percolation) > swExces){
					float ratio <- percolation / (ecoulementLateralCoucheCourante + percolation);
					percolation <- swExces * ratio;
					ecoulementLateralCoucheCourante <- swExces * (1-ratio);
				}
				
				// d -Calcul de SW par couche
				sw <- max([swMin, sw - percolation - ecoulementLateralCoucheCourante]);

				// e -Calcul ecoulement lateral total
				ecoulementLateral <- ecoulementLateral + ecoulementLateralCoucheCourante;
				put ecoulementLateralCoucheCourante at: indiceCoucheSol in: mapEcoulementLateralParCouche; // JV debug	
			}													
			// remplissage percolation
			put percolation at: indiceCoucheSol in: mapPercolationParCouche; 
			put sw at: indiceCoucheSol in: mapTeneurEnEauSolParCouche;	
							
			// JV debug 080219
			if(percolation<0.0){
				write("^^^ percolation=" + percolation + " swExces=" + swExces + " nbHeuresDansPasDeTemps=" + nbHeuresDansPasDeTemps + " tempsParcoursPercolation=" + tempsParcoursPercolation + " 1-exp()=" + (1-exp(-nbHeuresDansPasDeTemps/tempsParcoursPercolation)));
				write("^^^ sat=" + sat + " fc=" + fc + " kSat=" + kSat);
			}
		}

		// JV ecoulement latéral pour bilan phase sol
		ecoulementLateralPourBilanSol <- ecoulementLateral;

		// 3 -Calcul quantite stockee pour jour suivant
		ecoulementLateralStockeeJourPrecedent <- max([0.0, ecoulementLateral+ecoulementLateralStockeeJourPrecedent]);
		ecoulementLateral <- ecoulementLateralStockeeJourPrecedent * fractionEcoulementDeSurface;
		ecoulementLateralStockeeJourPrecedent <- ecoulementLateralStockeeJourPrecedent - ecoulementLateral;
		
		// 4 -DEBUG : pour le calcul de la balance deau
		teneurEnEauPrec <- teneurEnEau;
		teneurEnEau <- (sum(mapTeneurEnEauSolParCouche.values));
					
		return ecoulementLateral;
	}

	/*
	 * *****************************************************************************************
	 * 3 -Evapotraspiration : Methode calculant la quantite deau qui va sevaporer par evaporation de la canopee, transpiration, sublimation et evaporation du sol
	 */	
	float calculEvapotranspirationReelle{	
		float etp <- zh.meteo.etp; // E0 [mm]		
		float eauDansPaquetNeigeZH <- zh.eauDansPaquetNeigeZH;
		
		evapoTranspirationReelle <- 0.0;
		if(etp > 0.0){
			// 1 -Calcul de la transpiration potentielle
			float Et <- 0.0; // transpirationPotentielle			
			if(clcAssocie.lai >= 3.0){
				Et <- etp;
			}else{
				Et <- etp*clcAssocie.lai / 3.0;
			}				
			// 2 -Calcul de levaporation et sublimation potentielle
			float couvertureSol <- 1.0; // covSol
			if(eauDansPaquetNeigeZH >= 0.5){
				couvertureSol <- 0.5;
			}
			float Es <- etp*couvertureSol; // evaporationPotentielle
							
			float eos1 <- etp / (Es + Et + exp(-10));
			eos1 <- eos1 * Es;
			Es <- min([Es,eos1]);	
			Es <- max([0.0,Es]);		
			if(etp < (Et + Es)){ //  or etp = 0.0
				Es <- etp - Et;
				Es <- (Es*etp / (Es+Et));
				Et <- (Et*etp / (Es+Et));
			}
			
			// 3 -Calcul de levaporation reelle du sol pour chaque couche
			float evaporationRestante <- Es; // esleft
			if(isNeige and !empty(bandesDelevation)){
				evaporationRestante <- sublimationDeNeige(evaporationRestante);				
			}				
			float evaporationReelleTotale <- 0.0;
			float transpirationReelleTotale <- 0.0;			
			loop indiceCoucheSol from: 1 to: sol.nbCouches{
				float zDessus <- sol.mapProfondeurMinParCouche at indiceCoucheSol;
				float zDessous <- sol.mapProfondeurMaxParCouche at indiceCoucheSol;
				float sw <- mapTeneurEnEauSolParCouche at indiceCoucheSol;
				put 0.0 at: indiceCoucheSol in: mapEvapotranspirationParCouche; // JV debug (au cas où pas remplie dans le if)

				// Levaopration du sol a lieu uniquement pour les couches au dessus de 500 mm
				if(zDessous <= profondeurEvaporationMax){
					// evapo 0 : Es,act,ly
					float evaporationZdessus <- evaporationZ(z:zDessus, evaporationPotentielle:Es); // Es,zp
					float evaporationZdessous <- evaporationZ(z:zDessous, evaporationPotentielle:Es); // Es,z
					float evaporationCouche <- evaporationZdessous - evaporationZdessus*esco;  // Es,act,ly				
	
					// evapo 1					
					float fc <- sol.capaciteAuChamp at indiceCoucheSol;
					//float wp <- sol.pointFletrissementPermanent at indiceCoucheSol;						
					if(sw < fc){						
						evaporationCouche <- evaporationCouche * exp((2.5*(sw-fc) / fc));				
					}				
					
					// evapo 2
					evaporationCouche <- min([evaporationCouche, (0.8*sw)]);
					evaporationCouche <- max([0.0, evaporationCouche]);
					evaporationCouche <- min([evaporationRestante, evaporationCouche]);						
										
					// Mise a jour SW
					if(sw > evaporationCouche){
						sw <- max([0.0, (sw-evaporationCouche)]);
						evaporationRestante <- evaporationRestante - evaporationCouche;
					}else{
						evaporationRestante <- evaporationRestante - sw;
						sw <- 0.0;
					}					
					evaporationReelleTotale <- evaporationReelleTotale + evaporationCouche;	
					put evaporationCouche at: indiceCoucheSol in: mapEvapotranspirationParCouche; // JV debug 
					put sw at: indiceCoucheSol in: mapTeneurEnEauSolParCouche;			
				}
			}

			// 4 -Calcul du stress de laeration
			float swTot <- sum(mapTeneurEnEauSolParCouche.values);
			float fcTot <- sum(sol.capaciteAuChamp.values);
			float satTot <- sum(sol.saturation.values);
			float strsa <- 1.0;
			if(swTot > fcTot){
				float satco <- (swTot - fcTot) / (satTot - fcTot);
				strsa <- 1 - satco / (satco + exp(0.176 - 4.544 * satco));
			}
			
			// 5 -Calcul de la transpiration des plantes pour chaque couche
			loop indiceCoucheSol from: 1 to: sol.nbCouches{
				float zDessus <- sol.mapProfondeurMinParCouche at indiceCoucheSol;
				float zDessous <- sol.mapProfondeurMaxParCouche at indiceCoucheSol;
				float sw <- mapTeneurEnEauSolParCouche at indiceCoucheSol;

				// transpiration 0 : Et,act,ly
				float transpirationZdessus <- 0.0; // Et,zp
				float transpirationZdessous <- 0.0; // Et,z	
				if(sol.getProfondeurMaxSWAT() <= 0.01){
					transpirationZdessus <- 0.0;
					transpirationZdessous <- Et / (1-exp(-10));	
				}else{
					transpirationZdessus <- transpirationZ(z:zDessus, transpirationPotentielle:Et);
					transpirationZdessous <- transpirationZ(z:zDessous, transpirationPotentielle:Et);						
				}
				float transpirationCouche <- transpirationZdessous - transpirationZdessus;  // Et,act,ly	
				
				// transpiration 1 	
				float eManque <- 0.0;
				if(strsa <= 0.99){
					//write "if(strsa <= 0.99)";
					// JV 170524 bug the new variable eManque below was shading the previous one
					//float eManque <- transpirationZdessus - transpirationReelleTotale; // on enleve a ce qui entre dans la couche la somme des transpiration des couches precedentes						
					eManque <- transpirationZdessus - transpirationReelleTotale; // on enleve a ce qui entre dans la couche la somme des transpiration des couches precedentes						
				}			
				transpirationCouche <- transpirationCouche + eManque * epco; // omegaUse(jj)
				
				// transpiration 2
				float fc <- sol.capaciteAuChamp at indiceCoucheSol;
				float wp <- sol.pointFletrissementPermanent at indiceCoucheSol;
				if(sw < 0.25*fc){
					transpirationCouche <- transpirationCouche * exp(5 * ((4 * sw / fc) - 1));
				}
				if(sw < transpirationCouche){
					transpirationCouche <- sw;
				}				
				transpirationReelleTotale <- transpirationReelleTotale + transpirationCouche;				
				
				// Mise a jour SW
				sw <- max([swMin, sw - transpirationCouche]);
				put sw at: indiceCoucheSol in: mapTeneurEnEauSolParCouche;	
				
				// JV debug on ajoute la transipration des plantes à celle du sol
				float etCoucheCourante <- mapEvapotranspirationParCouche at indiceCoucheSol;
				etCoucheCourante <- etCoucheCourante + transpirationCouche;
				put etCoucheCourante at: indiceCoucheSol in: mapEvapotranspirationParCouche;
			}		
			evapoTranspirationReelle <- evaporationReelleTotale + transpirationReelleTotale;
		}						
		
		return evapoTranspirationReelle;			
	}

	/*
	 * *****************************************************************************************
	 * Calcul de la sublimation de la neige
	 */
	float sublimationDeNeige{ 
		arg esleft type: float default: 0.0;
		
		eauDansPaquetNeigeHRU <- zh.eauDansPaquetNeigeZH; // mm
			
		float sumsnoeb <- 0.0;
		float snoeb <- 0.0;			
		ask(bandesDelevation.keys){ 
			float fractionHRU <- myself.bandesDelevation at self;				
			// On initialise eauDansPaquetNeigeHRUParBande avec les memes valeurs globales
			put eauDansPaquetNeige at: self in: myself.eauDansPaquetNeigeHRUParBande;
			if(temperatureMoy > 0.0){
				snoeb <- myself.eauDansPaquetNeigeHRUParBande at self;
				sumsnoeb <- sumsnoeb + snoeb * fractionHRU;					
			}				
		}
		float snoev <- 0.0;
		ask(bandesDelevation.keys){ 				
			float fractionHRU <- myself.bandesDelevation at self;	
			snoeb <- myself.eauDansPaquetNeigeHRUParBande at self;			
			if(sumsnoeb > esleft and sumsnoeb > 0.01){
				if(temperatureMoy > 0.0){						
					snoev <- snoev + snoeb * (esleft / sumsnoeb) * fractionHRU;
					snoeb <- snoeb - snoeb * (esleft / sumsnoeb);						
				}				
			}else{ //si sumsnoeb < 0.01 alors on considere que le paquet de neige fond entierement 
				if(temperatureMoy > 0.0){ // si la temperature le permet
					snoev <- snoev + snoeb * fractionHRU;
					snoeb <- 0.0;						
				}				
			}
			put snoeb at: self in: myself.eauDansPaquetNeigeHRUParBande;
		}
		esleft <- max([esleft - snoev,0.0]); // dans le cas sumsnoeb > 0.01 on risquerait de renvoyer des valeurs négatives d'ETR
		
		eauDansPaquetNeigeHRU <- eauDansPaquetNeigeHRU - snoev;
		
		return esleft;
	}



			
	/*
	 * *****************************************************************************************
	 */	
	float evaporationZ{
		arg z type: float default: 0.0;
		arg evaporationPotentielle type: float default: 0.0;
		
		float evapotranspirationZ <- evaporationPotentielle * z/(z+exp(2.374-0.00713*z));
		
		return evapotranspirationZ;
	}
	/*
	 * *****************************************************************************************
	 */	
	float transpirationZ{
		arg z type: float default: 0.0;
		arg transpirationPotentielle type: float default: 0.0;
		
		float transpirationZ <- transpirationPotentielle / (1-exp(-10)) * (1 - exp(-10 * z/(sol.getProfondeurMaxSWAT())));
		
		return transpirationZ;
	}

	/*
	 * *****************************************************************************************
	 * 4 -Calcul de lecoulement des eaux souterraines (base flow) : la balance deau pour laquifere peu profond
	 */	
	float getPercolationDerniereCouche{	   // omegaSeep  [mm]
		if( mapPercolationParCouche at sol.nbCouches != nil){
			return mapPercolationParCouche at sol.nbCouches;
		}else{
			return 0.0;
		}			
	}
	action setPercolationDerniereCouche{
		arg eau type: float default: 0.0;
		put eau at: sol.nbCouches in: mapPercolationParCouche;
	}
	float getEauDerniereCouche{	   //   [mm]
		if( mapPercolationParCouche at sol.nbCouches != nil){
			return mapTeneurEnEauSolParCouche at sol.nbCouches;
		}else{
			return 0.0;
		}			
	}
	action setEauDerniereCouche{
		arg eau type: float default: 0.0;
		put eau at: sol.nbCouches in: mapTeneurEnEauSolParCouche;
	}
	
	float addRevapEauDerniereCouche (float eau){
		float eauNonTransmissible <- 0.0; //Water that cannot be put to the last soil layer
										 // due to water saturation
		float teneurActuelle <- getEauDerniereCouche();
		if ((teneurActuelle +eau ) > sol.saturation at sol.nbCouches){
			eauNonTransmissible <- teneurActuelle +eau - (sol.saturation at sol.nbCouches);
			put (sol.saturation at sol.nbCouches) at: sol.nbCouches in: mapTeneurEnEauSolParCouche;
			 
		}else{
			put (teneurActuelle +eau) at: sol.nbCouches in: mapTeneurEnEauSolParCouche;
		}
		
		return eauNonTransmissible;
	}
	
	action miseAJourEauEntreePourCalculEcoulementSouterrain{}

	/*
	 * *****************************************************************************************
	 * 4 -Calcul de lecoulement des eaux souterraines (base flow) : la balance deau pour laquifere peu profond
	 * Coresspondance variable SWAT - variable MAELIA
	 * DeltaGw			 -> retardEntreSortiSolEtEntreeAquifereGlobal
	 * Omega_rchg        -> eauEntreeAquiferes
	 * Beta_deep         -> coefPercolationVersAquifereProfondGlobal
	 */	
	float calculEcoulementEauSouterraine{
		do miseAJourEauEntreePourCalculEcoulementSouterrain();
				
		// 1 -Calcul recharge
		eauEntreeAquiferes <- ((1 - exp(-1/retardEntreSortiSolEtEntreeAquifereGlobal)) * getPercolationDerniereCouche() + exp(-1/retardEntreSortiSolEtEntreeAquifereGlobal) * eauEntreeAquiferes);
		if(eauEntreeAquiferes < 0.000001){
			eauEntreeAquiferes <- 0.0;
		}
		// 2 -Partition de rechage entre laquifere peu profond/profond
		eauAquifereProfond <- coefPercolationVersAquifereProfondGlobal * eauEntreeAquiferes;
		float eauEntreeAquiferePeuProfond <- eauEntreeAquiferes - eauAquifereProfond;  // omegaRchrg,sh  [mm]
		eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfond + eauEntreeAquiferePeuProfond;
		
		// 3 -Calcul de lecoulement de leau souterraine et de la hauteur
		if(eauStockeeAquiferePeuProfond > seuilEcoulementAquiferePeuProfond){
			ecoulementEauSouterraine <- ecoulementEauSouterraine * fractionEcoulementEauxSouterraines + eauEntreeAquiferePeuProfond * (1-fractionEcoulementEauxSouterraines);
		}else{
			ecoulementEauSouterraine <- 0.0;
		}
		
		// 4 -Calcul du revap (eau qui remonte de laquifere peu profond a linter flow)
		float eauRevapMax <- coefRevapEauSouterraineGlobal*zh.meteo.etp;  // omegaRevap,mx
		if(eauStockeeAquiferePeuProfond <= seuilRevapAquiferePeuProfond){
			eauRevap <- 0.0;				
		}else{
			if(eauStockeeAquiferePeuProfond < (eauRevapMax + seuilRevapAquiferePeuProfond)){
				eauRevap <- eauStockeeAquiferePeuProfond - seuilRevapAquiferePeuProfond; 
			}else{
				eauRevap <- eauRevapMax;
			}
			eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfond - eauRevap;
			//Reporter l eau vers la couche haute
			eauRevap <- eauRevap - addRevapEauDerniereCouche(eauRevap);
		}
		
		
		// 5 -Calcul du stockage dans laquifere peu profond au jour courant
		if(eauStockeeAquiferePeuProfond >= seuilEcoulementAquiferePeuProfond){
			eauStockeeAquiferePeuProfond <- eauStockeeAquiferePeuProfond - ecoulementEauSouterraine;				
			if(eauStockeeAquiferePeuProfond < seuilEcoulementAquiferePeuProfond){
				ecoulementEauSouterraine <- eauStockeeAquiferePeuProfond +  ecoulementEauSouterraine - seuilEcoulementAquiferePeuProfond;
				eauStockeeAquiferePeuProfond <- seuilEcoulementAquiferePeuProfond;
			}
		}else{
			ecoulementEauSouterraine <- 0.0;
		}
		
		//6 calcul hauteur de nappes //hwtbl = Qgw / 8000/ Ksat /lgw2
		// Hauteur_nappe = ecoulementEauSouterraine / 8000/ 
		// hwtbl = Qgw / 800 /mu / alphaGw
		 hauteur_nappe <- ecoulementEauSouterraine / 800.0 / rendementAquiferePeuProfond / recessionEcoulementEauxSouterrainesGlobal ;		
	
		return ecoulementEauSouterraine;
	}

	/*
	 * *****************************************************************************************
	 * Total
	 */	
	float calculTotalPhaseSol{   // Qhru  [mm]
		return (ruissellementDeSurfaceHRU + ecoulementLateral + ecoulementEauSouterraine);
	}

	/*
	 * *****************************************************************************************
	 * Balance deau
	 */	
	action verificationBalanceEau{	
		float terme1 <- zh.pluie + ruissellementDeSurfaceHRU;
		float terme2 <- (teneurEnEau - teneurEnEauPrec) + (mapPercolationParCouche at sol.nbCouches) + ecoulementLateral; // (sommeSw - sommeSwPrec)
											
		return (abs(terme1 - terme2) < 1.0);
	}


	/*
	 * *****************************************************************************************
	 * 1 -Perte par transmission de ruissellement de surface
	 */	
//		action calculPerteParTransmissionDuRuissellementDeSurface{
//			arg pluieEntree type: float default: 0.0;
//			
//			
//			bool isMethode <- false;
//			
//			if(pluieEntree > zeroApproche and ruissellementDeSurfaceHRU > zeroApproche){				
//				// 1 -Calcul de la precipitation sur une demi-heure (half-hour rainfall)
//				float precipitationDemiHeure <- 0.1;  // alpha,0.5h
//				
//				// 2 -Calcul du pic de ruissellement du surface
//				float alphaTC <- 1 - exp(2 * tempsDeConcentrationHRU * ln(1 - precipitationDemiHeure));
//				float picRuissellementSurface <- (alphaTC * ruissellementDeSurfaceHRU) / tempsDeConcentrationHRU;  // qPeak	[mm/h]
//				precipitationDemiHeure <- (precipitationDemiHeure * getSurfaceKm2()) / 3.6; // [m3/s]	
//				
//				if(isAfficher and isMethode){
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] pluieEntree = ' + pluieEntree;
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] ruissellementDeSurfaceHRU = ' + ruissellementDeSurfaceHRU;
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] alphaTC = ' + alphaTC;
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] picRuissellementSurface = ' + picRuissellementSurface;		
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] precipitationDemiHeure = ' + precipitationDemiHeure;			
//				}				
//				
//				// 3 -Calcul de la perte par transmission
//				float qInit <- ruissellementDeSurfaceHRU;
//				float pic <- picRuissellementSurface;
//				float v0 <- pluieEntree * getSurfaceKm2() * 1000;  // [m3]
//				float dur <- min([24.0, v0 / (picRuissellementSurface * 3600)]); // [hr]   duree du trajet pour le ruissellement
//
//				if(isAfficher and isMethode){
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] qInit = ' + qInit;
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] pic = ' + pic;		
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] v0 = ' + v0;	
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] dur = ' + dur;		
//				}	
//
//				
//				picRuissellementSurface <- 0.0;
//				ruissellementDeSurfaceHRU <- 0.0;				
//				float xx <- 2.6466 * zh.conductiviteCoursEauTributaire * dur / v0;				
//
//				if(isAfficher and isMethode){
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] KchTri = ' + zh.conductiviteCoursEauTributaire;
//					write '[HRU/calculPerteParTransmissionDuRuissellementDeSurface] xx = ' + xx;		
//				}	
//
//				if(xx < 1){
//					float kk <- -2.22 * world.log(1 - xx); // probleme pour faire le log en GAMA !!!!!
//					float b <- exp(-0.4905 * kk);										
//					if((1 - b) > 0){
//						float zz <- -kk * getLargeurMoyenneCoursEauTributaire() * getLongueurCoursEauTributaireMax();											
//						if(zz >= -30){
//							float bx <- exp(zz);
//							float a <- -0.2258 * zh.conductiviteCoursEauTributaire * dur;
//							
//							float ax <- 0.0;
//							if((1 - b) > 0.01){
//								float ax <- a / (1 - b) * (1 - bx);
//							}
//							
//							float volx <- -ax / bx;
//							if(v0 > volx){
//								ruissellementDeSurfaceHRU <- ax + bx * v0; // [m3]
//								ruissellementDeSurfaceHRU <- max([0.0, ruissellementDeSurfaceHRU / (1000 * getSurfaceKm2())]); // [mm]
//								
//								if(ruissellementDeSurfaceHRU > 0.0){
//									picRuissellementSurface <- max([0.0, (1 / (3600 * dur)) * (ax - (1 - bx) * v0) + bx * pic]); // [m3/s]
//								}
//							}
//						}						
//					}
//				}
//				
//				perteParTransmission <- qInit - ruissellementDeSurfaceHRU;
//				if(perteParTransmission < 0.0){
//					ruissellementDeSurfaceHRU <- qInit;
//					perteParTransmission <- 0.0;
//				}
//			}			
//		}

 
   		/*
	 * *****************************************************************************************
	 * Balance deau
	 */	
	float getEauSortie{	
		return (ruissellementDeSurfaceHRU + ecoulementLateral + ecoulementEauSouterraine);
	}		
	float getSurfaceKm2{
		return (surface / (nbMDanskm^2));
	}		
	float getLongueurCoursEauTributaireMax{ // LChTri,j [km]
		return (zh.longueurCoursEauTributaireMax * fractionDansZH);
	}				
	float getLargeurMoyenneCoursEauTributaire{// WchTri,j [km]	
		return (zh.largeurMoyenneCoursEauTributaire * fractionDansZH);
	}				

	/*
	 * *****************************************************************************************
	 * Remise a zero de certains attributs pour le jour suivant
	 */	 		
	action remiseAzero{}
	
	
	/*
	 * Affichage
	 */
	aspect basic{
		if(fractionDansZH > zeroApproche){
			draw shape color: couleurHRU border: couleurHRU;
		}    		
	}     	
	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- name; 
		resultat <- resultat + ' - zh  : ' + zh;
		resultat <- resultat + ' - ruissellementDeSurfaceHRU : ' + ruissellementDeSurfaceHRU;
		resultat <- resultat + ' - Percolation derniere couche : ' + mapPercolationParCouche at sol.nbCouches;
		resultat <- resultat + ' - curveNumber : ' + curveNumber;
		return resultat;
	}

	int getNbCouches{
		return sol.nbCouches;
	}
}	


