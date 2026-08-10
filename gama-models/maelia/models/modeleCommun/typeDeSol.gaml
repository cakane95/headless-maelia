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
 *  TypeDeSol
 *  Author: Maroussia Vavasseur
 *  Description: Le type de sol va etre different par parcelle. Ceratin coefficient, tel que la RU, vont avoir un impact plus ou moins fort sur la gestion de l'eau en fonction du type de sol.
 */

model typeDeSol

import "../modeleHydrographique/zoneHydrographique.gaml"

global{
	string chemintypeDeSolShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/typesDeSol/';
 	string nomFichiertypeDeSolShape <- 'typeDeSolParZH.shp';
	
	map<string, string> listNomZonePedo <- map([]);
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionTypeDeSol{				
		do checkExistenceOfFilesAndAttributes;
		create typeDeSol from: file(chemintypeDeSolShape+nomFichiertypeDeSolShape) with: [			idTypeDeSOl::string(read ( ID_SOL )),
																nom::string(read ( ZONE_PEDO )), 
																stuDominant::int(float(read ( STU_DOM ))), 
																profondeurMax::float(read( PRO_OC ))]{	// cm									
			zoneHydroAssociee <- mapZH at string(shape get( ID_ZH ));															
			// Suppression des zones meteos nappartenat pas a la zone detude
			if(zoneHydroAssociee = nil){
				ask self{
					do die;	
				}						
			}else{
				name <- nom + '_' + stuDominant;
				
				// SWAT
				if(shape get( 'RUPRH1' ) != nil){ // Si les variables pour SWAT sont definies
					float profondeurPremiereCouche <- 10.0;					
					loop indiceCoucheSol from: 1 to: 11{ //10 couches de sol max + la premiere.		
					
						if(shape get( 'P' + max([1,(indiceCoucheSol - 1)]) ) !=nil){ //verification de l exisitence de la couche
							float zDessus <- 0.0;
							float zDessous <- 0.0;
							float epaisseur <- 0.0;
							float awc <- 0.0;
							float kSat <- 0.0;
							float densiteApparente <- 0.0;
							float txArgile <- 0.0;
							
							if(indiceCoucheSol = 1){ // 0-10 mm
								zDessus <- 0.0;
								zDessous <- profondeurPremiereCouche;
								epaisseur <- profondeurPremiereCouche;
								awc <- float(shape get( 'RUPRH' + (indiceCoucheSol) )) 
										/(float(shape get( 'P1')) * nbMmDansCm)*epaisseur ;	 //[mm]
										
								
								kSat <- float(shape get( 'KSAT' + (indiceCoucheSol) ));				
								densiteApparente <- float(shape get( 'DAH' + (indiceCoucheSol) ));		
								txArgile <- float(shape get( 'ARG' + (indiceCoucheSol) ));						
								if (tauxArgile = 0) {
									tauxArgile <- txArgile;
								}
									
								// Variables pour aqyieldNC
								sand <- float(shape get( 'SAB' + (indiceCoucheSol) ));
								pHsol <- float(shape get( 'PH' + (indiceCoucheSol) ));
								CNsol <- float(shape get( 'CN' + (indiceCoucheSol) ));
								calcaire <- float(shape get( 'CAL' + (indiceCoucheSol) ));
								OM_perc <- float(shape get( 'MO' + (indiceCoucheSol) ));
								
							}else{
								zDessus <- mapProfondeurMaxParCouche at (indiceCoucheSol-1);               
								zDessous <- float(shape get( 'P' + (indiceCoucheSol - 1) )) * nbMmDansCm;

								/* ancienne version
								epaisseur <- (zDessous-zDessus);
								awc <- float(shape get( 'RUPRH' + (indiceCoucheSol - 1) )) ;           // [mm] 
								if(indiceCoucheSol = 2){
								       awc <- awc * (epaisseur -profondeurPremiereCouche)/epaisseur;
								}
								*/

								if(indiceCoucheSol = 2){ // horizon 10-w //mm
    								epaisseur <- zDessous - profondeurPremiereCouche;//correction hugues 210614 cf mail Myriam dans Mantis #0002846
    								awc <- float(shape get( 'RUPRH' + (indiceCoucheSol - 1) )) * epaisseur / zDessous; // Correction Hugues + Renaud 300523 --> Erreur dans la correction précédente
								} else { // horizons > 2
    								epaisseur <- (zDessous-zDessus);
    								awc <- float(shape get( 'RUPRH' + (indiceCoucheSol - 1) )) ;
								}
								
								kSat <- float(shape get( 'KSAT' + (indiceCoucheSol - 1) ));	
								densiteApparente <- float(shape get( 'DAH' + (indiceCoucheSol - 1) ));		
								txArgile <- float(shape get( 'ARG' + (indiceCoucheSol - 1) ));						
							}
			
							// inisialisation des fc, wp, awc et sat
							float wp <- (0.4 * (txArgile * densiteApparente) / 100); //fraction du sol
							if(wp <= 0.0){
								wp <- 0.005;
							}
							wp <- wp * epaisseur; //[mm]					
							float fc <- awc + wp; //car awc = FC - WP					
							
							float porositeSol <- (densiteApparente/2.65) * epaisseur;//2.65 density of quartz //[mm]
							if(fc >= porositeSol){
								fc <- porositeSol - 0.05 * epaisseur;
								wp <- fc - awc;
								if(wp <= 0.0){
									fc <- porositeSol * 0.75; // JV 130219 fc <- porositeSol * 0.75 * epaisseur;
									wp <- porositeSol * 0.25; // JV 130219 wp <- porositeSol * 0.25 * epaisseur;
								}
							}
							float sat <- (porositeSol - wp) ;
							fc <- (fc - wp);
												
							
							// Si la couche existe
							if(epaisseur > 0.0){
								put zDessus at: indiceCoucheSol in: mapProfondeurMinParCouche;
								put zDessous at: indiceCoucheSol in: mapProfondeurMaxParCouche;	
								put epaisseur at: indiceCoucheSol in: mapEpaisseurParCouche;	
								put fc at: indiceCoucheSol in: capaciteAuChamp;	
								put wp at: indiceCoucheSol in: pointFletrissementPermanent;
								put awc at: indiceCoucheSol in: capaciteEauDisponible;
								put sat at: indiceCoucheSol in: saturation;	
								put kSat at: indiceCoucheSol in: conductiviteHydroliqueSaturee;	
								put densiteApparente at: indiceCoucheSol in: densiteSol;		
								put txArgile at: indiceCoucheSol in: densiteArgile;							
							}
						}
									
					}
					nbCouches <- length(mapEpaisseurParCouche);
				}
								
				// OC
				if((shape get( ARG_OC )) != nil){
					tauxArgile <- float(shape get( ARG_OC ));
					if((shape get( DAH_OC )) != nil){ // sinon on garde 30% comme valeur par défaut ?
						tauxGravier <- float(shape get( DAH_OC ));
					}
					//////// temporaire!!!!!!!!!!!!!!!!!!!!
					if (tauxArgile=0){
						tauxArgile <- float(shape get( "ARG1" ));
					//	tauxGravier <- float(shape get( "DAH1" ));
						write 'Pbm : ARG_OC tauxArgile est nul, on prend le taux de la premiere couche de sol. ---> ' + tauxArgile;
					}
					//teneurEnMatiereOrganique <- float(shape get( MO ));
					noteQualiteStructureSol <- float(shape get( CSTRU ));
					//reservePotentielleUtileMax <- float(shape get( RUm )); //RL 07/07/2015 : ecrase par initialisationTypeDeSol
					permeabiliteSol <- float(shape get( PIRm ));
					if((shape get(PIRm )) = nil){
						permeabiliteSol <- float(shape get( "PIRm" ));
					}
					//mineralisationNannuelle <- float(shape get( MIN_NA ));
					//doseIrrigationMax <- float(shape get( DOS_IMAX ));
					//coefEfficaciteAzote <- float(shape get( EFN ));									
				}

				if((shape get( ARG_DECA1 )) != nil){
					arg_deca <- float(shape get( ARG_DECA1 ));
				}
								
				if((shape get( ARG1 )) != nil){
					clay <- float(shape get( ARG1 ));
					if ((shape get( ARG_DECA1 )) = nil) { // JV 020725 correction #25
						arg_deca <- clay;
					}
				}
				
				if((shape get( DAH1 )) != nil){
					daH1 <- float(shape get( DAH1 ));
				}
				if((shape get( EG1 )) != nil){
					tauxGravier <- float(shape get( EG1 ));
				}				
				if((shape get( HCC1 )) != nil){
					HCCH1 <- float(shape get( HCC1 ));
				}				
				if((shape get( HPFP1 )) != nil){
					HPFw1 <- float(shape get( HPFP1 ));
				}							
				do initialisationTypeDeSol();	
				
				ask (zoneHydroAssociee){					
					add myself to: listeTypeDeSolAssocies;
				}
				put nom at: nom in: listNomZonePedo;	
			}					
		}		
		
		/* JV 070921 check that all ZH have at least one soil
		bool ok <- true;
		ask listeZonesHydrographiques{
			ok <- ok and !empty(listeTypeDeSolAssocies);
		}
		if !ok {do raiseError("Une ZH sans sol");}
		*/
		
	}
	
	// JV 010921 teste la présence d'un ensemble minimal d'attributs nécessaires (le nombre exact dépend du nombre de couches représentées) en fonction du modèle (AqYield ou AqYieldNC)
	// cf https://bul.univ-lorraine.fr/index.php/s/g95zEAFoewFc6PJ
	action checkExistenceOfFilesAndAttributes {
		
		if !file_exists(chemintypeDeSolShape+nomFichiertypeDeSolShape) {do raiseError("fichier inexistant: " + chemintypeDeSolShape+nomFichiertypeDeSolShape);}
		//if !is_shape(chemintypeDeSolShape+nomFichiertypeDeSolShape) {do raiseError("le fichier sol " + chemintypeDeSolShape+nomFichiertypeDeSolShape + " n'est pas un fichier shape");}
		
		
		list<string> listAqYield 	<- [ARG1, CSTRU, DAH1, ID_SOL, ID_ZH, KSAT1, P1, PIRm, PRO_OC, RUPRH1, STU_DOM, ZONE_PEDO];
		list<string> listAqYieldNC 	<- [ARG1, CSTRU, DAH1, ID_SOL, ID_ZH, KSAT1, P1, PIRm, PRO_OC, RUPRH1, STU_DOM, ZONE_PEDO, CAL1, CN1, EG1, HCC1, HPFP1, MO1, SAB1];
		
		list<string> relevantList <- [];
		switch nomChoixModeleCroissancePlante {
			match "AqYield" 	{relevantList <- listAqYield;}
			match "AqYieldNC" 	{relevantList <- listAqYieldNC;}			
		}
		
		loop att over: relevantList {
			geometry tmp <- first(shape_file(chemintypeDeSolShape+nomFichiertypeDeSolShape)); // il faut sélectionner un élément du shape pour pouvoir lire les attributs			
			if (tmp get att)=nil {do raiseError("l'attribut " + att + " est obligatoire dans le fichier sol " + chemintypeDeSolShape+nomFichiertypeDeSolShape + " pour le modèle " + nomChoixModeleCroissancePlante);}
		}
	}
	
}

species typeDeSol {
	string idTypeDeSOl <- ''; 
	string nom <- ''; 
	zoneHydrographique zoneHydroAssociee <- nil;
	rgb couleurReserveUtile <- rgb('white');
	float profondeurMax <- 1.0; // [cm]				
	float reserveFacilementUtilisableMaximum <- 0.072; // 72mm	= 60cm * 0.18 * 2/3
// ----------------------------------------- VARIABLES SWAT -----------------------------------------
	int nbCouches <- 0;
	map<int,float> mapProfondeurMinParCouche <- map<int,float>([]); // zu  indiceCoucheSol::profondeurDessus  [mm]
	map<int,float> mapProfondeurMaxParCouche <- map<int,float>([]); // zl  indiceCoucheSol::profondeurDessous  [mm]
	map<int,float> mapEpaisseurParCouche <- map<int,float>([]); // zl  indiceCoucheSol::epaisseur  [mm]
	map<int,float> capaciteAuChamp <- map<int,float>([]); //Capacite au champ - point de fletrissement   // indiceCouche::FC    [mm]  (meme valeur pour toute les couches du sol)
	map<int,float> pointFletrissementPermanent <- map<int,float>([]); // indiceCouche::WP  [mm]
	map<int,float> capaciteEauDisponible <- map<int,float>([]); //Capacite au champ - point de fletrissement // indiceCouche::AWC  [mm]				
	map<int,float> saturation <- map<int,float>([]); //Capacite a saturation - point de fletrissement // indiceCouche::SAT [mm]
	map<int,float> conductiviteHydroliqueSaturee <- map<int,float>([]); // indiceCouche::KSAT [mm/hr]
	map<int,float> densiteSol <- map<int,float>([]); // indiceCouche::PourcGravier [kg.kg]
	map<int,float> densiteArgile <- map<int,float>([]); // indiceCouche::PourcArcgile [%]
	int stuDominant <- 0;
// ----------------------------------------- VARIABLES AQYIELD -----------------------------------------
	// Constantes : 
	float reservoirHorizonTravailProfond <- 40.0; // RUw,sol [mm]   horizonHumifere
	
	float reservePotentielleUtileMax <- 138.0; // RUm [mm]
	
//		float doseIrrigationMax <- 34.0; // dosIm [mm]
	//float coefEfficaciteAzote <- 0.9; // efN
	float coefStabiliteCultural <- 0.0; // alpha
	float coefCC <- 0.0;
	float ctr_m <- 0.0;		
	// Constantes : Lecture fichier ?
	float tauxGravier <- 0.0; // JV 290920 recuperation valeur code Renaud 1.7, auparavant: 30.0; // AqYield : %grav [sans unite]
	float tauxArgile <- 0.0; // JV 290920 recuperation valeur code Renaud 1.7, auparavant: 15.0; // %
	//float teneurEnMatiereOrganique <- 2.5; // %MO
	float noteQualiteStructureSol <- 1.0; // Cstru
	float permeabiliteSol <- 50.0; // PIRm [mm]
//		float mineralisationNannuelle <- 120.0; // minNA [kgN/ha]
	float coefLimitantDoseIrr <- 0.25; // alpha
	float effetTextureSurTravailDuSol <- 0.0;
//		float pente <- 10.0; // alpha		
	
	// Variables Aqyield CN à donner dans le fichier sol d'entrée
	float pHsol <- 0.0;
	float CNsol <- 0.0;
	float calcaire <- 0.0;
	float HCCH1 <- 0.0;// Humidité à la capacité au champ en volumique
	float HPFw <- 0.0; // Humidité au point de flétrissement en massique
	float HPFw1 <- 0.0;// Humidité au point de flétrissement en volumique
	float HCCw <- 0.0; // Humidité à la capacité au champ en massique
	float HCCw_mm <- 0.0; // Hauteur d'eau calculée pour l'Humidité à la capacité au champ
	float HPFw_ptf  <- 0.0;
	float RUw_ptf  <- 0.0;	
	float daHOw <- 0.0; // ???
	float OM_perc <- 0.0;
	float arg_deca <- 0.0; // Argiles décarbonatés
	float profHum <- 0.0; //
	float NHumInitActif <- 0.0; // Initialisation du stock d'N organique actif (en Kg / N / ha) vue avec Hugues (26/08/19)
	float CHumInitActif <- 0.0; // Initialisation du stock de C organique actif (en Kg / N / ha) vue avec Hugues (26/08/19)
	float NHumInitStable <- 0.0; // N stable
	float CHumInitStable <- 0.0;
	float sand <- 0.0;
	float clay <- 0.0;
	float daH1 <- 0.0;		   
	float Soil_mass_profHum <- 0.0;	  
	
	// Variables Aqyield CN forcées
	// Détermination du Finert de départ (Fraction de la MO du sol inerte)
	float Finert <- 0.65; // utilisé si "option_Finert_calc" = false (voir launcher) ; % de MO stable adaptable en fonction de l'historique. Paramétrage par défaut = 0.65 pour historique grde culture de lg terme; 0.4 pr historique prairie lg terme.
	
	/*
	 * *****************************************************************************************
	 */	
	action initialisationTypeDeSol{			
		/*
		 *  AQYIELD
		 */	
		reservoirHorizonTravailProfond <- horizonDeTravailProfond/10.0 * (1.0-tauxGravier/100) * (12.0+39.0*(tauxArgile/100) - 64.0*((tauxArgile/100)^2));	//division par 10 de la hauteur pour avoir des mm				
		//FORMULE NON VALIDE si tauxArgile >80%
		
		
		// Si RUw est calculé avec la texture de son horizon alors il faudra calculer la RUmax différement
		reservePotentielleUtileMax <- 0.0;
		loop i from: 0 to: (nbCouches){
			reservePotentielleUtileMax <- reservePotentielleUtileMax + capaciteEauDisponible at i;
		} 			
//			doseIrrigationMax <- reservePotentielleUtileMax*coefLimitantDoseIrr;
//			coefEfficaciteAzote <- 0.9 * noteQualiteStructureSol;
		coefStabiliteCultural  <- (tauxArgile)^2;
		coefCC <- 0.6; // Rdv Hélène 03/04/18 --> passer à 0.6 au lieu d'utiliser la formule suivante : /(1 + 0.02 * tauxArgile); Référence doc : calc_coeffcc
		ctr_m <- 120 / (tauxArgile + 15);
		
		effetTextureSurTravailDuSol <- 1/10.0*(1.0-tauxGravier/100)*(12.0+39.0*(tauxArgile/100) - 64.0*((tauxArgile/100)^2));
		
		// Initialisation couleures
		do colorationReserveUtile;

		
		/*
		 *  AQYIELD NC
		 */	
		// Variables forcées pour tests
		//sand <- 30.0;
		//pHsol <- 7.0;
		//CNsol <- 9.2;
		//calcaire <- 20.0; 
		//OM_perc <- 2.0;
		
		// JV 290920 recuperation code Renaud GAMA 1.7
		
		// Définition du Finert en fonction du % de MO (si option activée)
		if (option_Finert_calc){
			Finert <- max([min([-0.0202 * (OM_perc / 1.72*10) + 1.0243 , 0.65]) , 0.40]); // Hugues Clivot 26/11/2024	
		}
			
		// Calcul de profHum
		if (profondeurMax < 30.0) {
			profHum <- profondeurMax;
		} else {
			profHum <- 30.0;
		}
		
		// Variables calculées
		daHOw <- daH1;
//		HCCw <- 100 * (0.127 + 2.29*10^-3 * clay + (-1.21*10^-3)* sand + 4.35*10^-2 * (OM_perc/1.72) + 7.35*10^-2 * daH1);
		HCCw <- HCCH1 / daH1;
		HPFw <- HPFw1 / daH1;
		HCCw_mm <- HCCw * daH1 * profHum/10 * (1 - tauxGravier / 100);
//		HPFw_ptf <- 100* ((-0.029) + 4.35*10^-3 * clay + (-6.08*10^-5)* sand + 1.70*10^-2 * (OM_perc/1.72) + 4.77*10^-2 * daH1);
//		RUw_ptf <- (HCCw - HPFw_ptf) * daH1 * profHum/10;
		Soil_mass_profHum <- profHum/100 * daH1 * 10000*(100-tauxGravier)/100*1000; // soil mass in kg/ha at profHum depth

		// uniquement pour AqYieldNC (si AqYield: division par 0 car CNsol=0) JV 100821
		if nomChoixModeleCroissancePlante="AqYieldNC" {
			//NHumInit <- daHOw * (teneurMO * 0.58 / 10) * profHum * 1000; // approximativement 5000 avec les valeur de paramètres actuelles
			NHumInitActif <- (((OM_perc / 1.72 * profHum * daH1) / CNsol) * (1 - tauxGravier / 100) * 1000) * (1 - Finert); // Initialisation du stock d'N organique actif (en Kg / N / ha) vue avec Hugues (26/08/19)
			CHumInitActif <- (((OM_perc / 1.72 * profHum * daH1)) * (1 - tauxGravier / 100) * 1000) * (1 - Finert); // Initialisation du stock d'N organique actif (en Kg / N / ha) vue avec Hugues (26/08/19)		
			NHumInitStable <- (((OM_perc / 1.72 * profHum * daH1) / CNsol) * (1 - tauxGravier / 100) * 1000) * Finert; // N stable
			CHumInitStable <- NHumInitStable * CNsol;
		}
	}
	
	/*
	 * *****************************************************************************************
	 */
	action colorationReserveUtile{			
//			if(int(profondeurMax/10) < 12){
//				couleurReserveUtile <- paletteCouleursCoefficientCultural at int(profondeurMax/10);			
//			}else{
//				couleurReserveUtile <- paletteCouleursCoefficientCultural at 12;			
//			}
		
		if(profondeurMax > 100){
			couleurReserveUtile <- rgb([255,250,190]);
		}else if(profondeurMax > 50 and profondeurMax <= 100){
			couleurReserveUtile <- rgb([255,250,220]);
		}else{				
			couleurReserveUtile <- rgb([255,250,250]);
		}						
	}
	
	float getProfondeurMaxSWAT{
		return profondeurMax * nbMmDansCm; // [cm] * 10
	}
	float getSeuilHumidite{
		return 1-(tauxArgile/100)^2;
	}
	
	/*
	 * *****************************************************************************************
	 * Display
	 */
	aspect reserveUtileAffichage{
		draw shape color: couleurReserveUtile border: couleurReserveUtile; 		
	}	
	
    	string toString{
    		return '' + idTypeDeSOl + ' - ' + nom + ' = ' +	stuDominant  + ' / ' + profondeurMax;
    	}
}
