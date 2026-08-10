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
 *  StrategiesSemi
 *  Author: Maroussia Vavasseur
 *  Description: La strategie de semi est l'entite qui va etre utilise par l'agriculteur pour determiner par exemple a quel moment il va semer.
 * 				 Il est possible de definir plusieurs strategies de semi differentes, choisie lors du parametrage de la simulation.
 */

model strategieSemi

import "../Ilots/ilot.gaml"

global{ }

species strategieSemis parent: strategieOT{		
	map<int,float> mapNbJoursTminMoyennee <- map<int,float>([]);// SEMIS
	map<int,float> mapTminMoyennee <- map<int,float>([]);// SEMIS
	map<int,float> mapNbJoursTmoy <- map<int,float>([]);// SEMIS
	map<int,float> mapTmoy <- map<int,float>([]);// SEMIS
	map<int, float> mapNbJoursAuMoinsPluiePrevuesCumuleeMin <- map<int, float>([]); //  SEMIS
	map<int, float> mapHauteurAuMoinsPluiePrevuesCumuleeMin <- map<int, float>([]); //  SEMIS
	
	// JV 251123 vrai si ancien includes sans les paramètres SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES, SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES, SEMIS_NJ_AU_MOINS_TEMP_MOY, SEMIS_AU_MOINS_TEMP_MOY
	// initialisé dans initialisationStategie, appelé dans lectureFichierReglesDeDecisions
	bool ancienIncludes <- false;
	
	// Est-ce que la température minimum moyenne est supérieure à la température seuil donnée dans les RDD ?
	bool isTemperatureMinMoyenneOK(zoneMeteo zoneMeteoIlotAssocie, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursTminMoyennee, parcelle(nil), deltaTemporel) and isDonnee(mapTminMoyennee, parcelle(nil), deltaTemporel)){		
			ask zoneMeteoIlotAssocie {
				res <- (getTmin(nb_jours:int(myself.mapNbJoursTminMoyennee at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel))) >= (myself.mapTminMoyennee at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel)));				
			}				
		}		
		return res;
	}		
	
	// Est-ce que la température moyenne est supérieure à la température seuil donnée dans les RDD ? // renaud 131023
	bool isTemperatureMoyenneOK(zoneMeteo zoneMeteoIlotAssocie, int deltaTemporel){		
		bool res <- true;			
		if(isDonnee(mapNbJoursTmoy, parcelle(nil), deltaTemporel) and isDonnee(mapTmoy, parcelle(nil), deltaTemporel)){		
			ask zoneMeteoIlotAssocie {
				res <- (getTmoy(nb_jours:int(myself.mapNbJoursTmoy at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel))) >= (myself.mapTmoy at myself.getIndiceSousPeriode(parcelle(nil), deltaTemporel)));				
			}				
		}
		
		return res;
	}
	
	// Est-ce que le cumul de pluie dans les n prochains jours est ok ? // renaud 131023
	bool isAuMoinsCumuleHauteurPluiePrevuesOK (zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel) {
		bool res <- true;
		if (isDonnee(mapNbJoursAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel)) {
			int nbJour <- int(getDonneeCourante(mapNbJoursAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurAuMoinsPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getCumulPluiesPrevues(nb_jours: nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau >= hauteur);
			}

		}
		return res;
	}
	
	/*
	 * *****************************************************************************************
	 */		
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){
		
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle = nil){
			if (parcelleEntree.isSowingAllowed and !parcelleEntree.isPrairiePermanente){
				// le semis ne peux avoir lieu que si la reprise du travail de sol a eu lieu -> JV 140420 supprimé pour le moment, on gèrera désormais la questions des contraintes entre opérations dans la déclaration des ITK
				// JV 060922 réintroduit ci-dessous dans le définition de estOk
//				if (parcelleEntree.isRepriseTravailSolEffectue or (parcelleEntree.getStrategie(REPRISE_TRAVAIL_SOL) = nil)){
					if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
						parcelleEntree.semis_prevu_non_realise<- true; //basculera a false si semis reellement realise
						estOk <- isTemperatureMinMoyenneOK(parcelleEntree.ilot_app.meteo, deltaTemporel) 
										and isHumiditeSolOK(parcelleEntree, deltaTemporel)
										and isCumuleHauteurPluieOK(parcelleEntree, deltaTemporel)
										and (parcelleEntree.isRepriseTravailSolEffectue or (parcelleEntree.getStrategie(REPRISE_TRAVAIL_SOL) = nil)); // JV 060922 semis conditionné à une reprise de travail du sol si prévue dans l'ITK cf. Mantis #0002940
						//write "parc " + parcelleEntree.idParcelle + " isTemperatureMinMoyenneOK=" + isTemperatureMinMoyenneOK(parcelleEntree.ilot_app.meteo, deltaTemporel) + " isHumiditeSolOK=" + isHumiditeSolOK(parcelleEntree, deltaTemporel) + " isCumuleHauteurPluieOK=" + isCumuleHauteurPluieOK + " isRepriseTravailSolEffectue=" + parcelleEntree.isRepriseTravailSolEffectue + " parcelleEntree.getStrategie(REPRISE_TRAVAIL_SOL)=" + parcelleEntree.getStrategie(REPRISE_TRAVAIL_SOL) + " estOk=" + estOk;
						// nouveaux paramètres complémentaires
						if !ancienIncludes {
							estOk <- estOk 	and isTemperatureMoyenneOK(parcelleEntree.ilot_app.meteo, deltaTemporel)
											and isAuMoinsCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel);
						}						
						
						if verboseMode and !(parcelleEntree.isRepriseTravailSolEffectue or (parcelleEntree.getStrategie(REPRISE_TRAVAIL_SOL))= nil) {
							write "parcelle " + parcelleEntree.idParcelle + " SEMIS " + parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee + " " + parcelleEntree.getITKAnnee().idITK + " en attente de reprise de travail du sol";
						}
										
						parcelleEntree.critereSemiOk_Tmin <- parcelleEntree.critereSemiOk_Tmin + int( isTemperatureMinMoyenneOK(parcelleEntree.ilot_app.meteo,deltaTemporel)) ;
						parcelleEntree.critereSemiOk_HumiditeSol <- parcelleEntree.critereSemiOk_HumiditeSol + int( isHumiditeSolOK(parcelleEntree,deltaTemporel)) ;
						parcelleEntree.critereSemiOk_Pluie <- parcelleEntree.critereSemiOk_Pluie + int( isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel)) ;
						
						if((dateCour.nbJoursEcoulesDansAnnee = getJourJulienFinMax(deltaTemporel)) and !estOk){ // si dernier jour fenêtre semis JV 170920 ajout: et que les conditions ne sont pas réunies (car on peut etre le dernier jour et pouvoir semer normalement)

							// on va rechercher un ITK alternatif (pas d'ITK alternatif si la culture qu'on cherchait à semer était une CI)
							if activerITKalternatif {
								if !parcelleEntree.getITKAnnee().especeCultiveeITK.isCI() {
									parcelleEntree.itkAlternatifAchercher <- true;
									write "parcelle "  + parcelleEntree.idParcelle + " - Semis non realise Tmin = " +parcelleEntree.critereSemiOk_Tmin +
									 " Hum = " + parcelleEntree.critereSemiOk_HumiditeSol+
									  " Pluie = " +  parcelleEntree.critereSemiOk_Pluie+
									  " pour itk "+ (parcelleEntree.getITKAnnee()).nomPourAffichage+
									  " pour culture "+tc.idEspeceCultivee + " on va chercher un ITK alternatif";
									parcelleEntree.critereSemiOk_Tmin <- 0 ;
									parcelleEntree.critereSemiOk_HumiditeSol <-0 ;
									parcelleEntree.critereSemiOk_Pluie <- 0 ;
								}
							}else{
								/* JV 100420: on va forcer le semis
								* les ITK sont supposés cohérents: la fenêtre récolte d'un ITK doit se terminer au plus tard un jour avant la fin de la fenêtre de semis de l'ITK suivant
								* -------------- R0[     R    ]R1------------ 
								* ----------------- S0[     S    ]S1---------- on doit avoir S1-R1 >= 1 du coup le seul cas possible de semis forcé est le jour S1
								*/		
								// JV 300821 pour les CI: seulement si forcerSemiscCI=vrai
								if forcerSemisCI or !parcelleEntree.getITKAnnee().especeCultiveeITK.isCI() {	 
									parcelleEntree.semis_prevu_non_realise <- true;
									parcelleEntree.getAgriculteur().listeParcellesEnSemisForce <<  parcelleEntree;
								}							
							}
						} // si dernier jour fenêtre semis
					} // si dans fenêtre semis
				} else if (parcelleEntree.isSowingAllowed and parcelleEntree.isPrairiePermanente) {
					estOk <- true;
				}
			} // if(parcelleEntree.cultureParcelle = nil)			
		return estOk;
	}
	
	
	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		// 1 - Creation culture
		culture cultureCreee <- nil;
		especeCultivee cult <- tc;		
		if(parc.isIrrigueeAnneeCourante()){	
			cultureCreee <- cultureIrrigable(world.creationCulture(typeCulture:cultureIrrigable, parcelleEntree:parc, especeEntree: cult));
		}else{
			cultureCreee <- world.creationCulture(typeCulture:culture, parcelleEntree:parc, especeEntree: cult);
		}
		
		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains SEMIS {				 
			ask parc{
				put getITKAnnee() at:dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at SEMIS);
					float profondeur <- nil;
					if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
						profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) with_precision nb_decimales_sorties;
					}				
					map<string,string> complements <- ["prof"::string(profondeur)];
					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at SEMIS);								
			}
		}
		
		// 2 - Petit travail du sol					
		do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
		
		// 3- Economie
		
		// 4 - Mise a jour variables
		put parc.getITKAnnee().especeCultiveeITK at: dateCour.annee in: parc.mapRotationSimulee;	 
		do ecritureDebugActivite(parc);
		parc.semis_prevu_non_realise<- false;
		if(activerITKalternatif){
			parc.itkAlternatifAchercher <- false;
		}
		parc.recolteForcee <- false;
		parc.dateDernierSemi <- string(dateCour.annee) + "/"+ dateCour.mois + "/" + dateCour.jour;
		
		parc.critereSemiOk_Tmin <- 0;
		parc.critereSemiOk_HumiditeSol <- 0;
		parc.critereSemiOk_Pluie <- 0;
		
		parc.cultureParcelle.anneeSemis <- dateCour.annee;
		
		// Mises en mémoire spécifiques module NC
		if (nomChoixModeleCroissancePlante = "AqYieldNC") {
			parc.nSemisCultures[tc.idEspeceCultivee] <- parc.nSemisCultures[tc.idEspeceCultivee] + 1;
			
			if (adaptationFertilisation = "corpen") {
				parcelleAqYieldNC(parc).N_dispo_semis <- parcelleAqYieldNC(parc).QNinitialeJ_w;
			}
		}

		// JV 140422 MAJ des variables de sortie
		ask parc{
			do changementCouvertSortiesParcelle(SEMIS);
		}

		/* JV 250321 finalement déplacé dans getAssolement1parcelle appelée juste après le changement d'ITK
		// JV 150420 MAJ variables irrigation (auparavant dans agriculteur.miseAJourVariables voir Mantis 0002510)
		// décrémentées lors de la récolte
		if(parc.isIrrigueeAnneeCourante()){
			if(parc.isParcelleIrrigable()){
				agri.surfaceIrriguee <- agri.surfaceIrriguee + parc.surface;
				agri.nbParcellesIrriguees <- agri.nbParcellesIrriguees + 1;
			}
			else{
				write '[AGRI/miseAJourVariables] PB parcelle ne peut pas etre irriguee car non irrigable ' + parc.toString();
			}
		}		 
		*/
		if(verboseMode){write "SEMIS " + parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 
	}			

	// JV 251123 vrai si ancien includes sans les paramètres SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES, SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES, SEMIS_NJ_AU_MOINS_TEMP_MOY, SEMIS_AU_MOINS_TEMP_MOY
	// initialisé dans initialisationStategie, appelé dans lectureFichierReglesDeDecisions		
	action initialisationStrategie {
		ancienIncludes <- empty(mapNbJoursTmoy) and empty(mapTmoy) and empty(mapNbJoursAuMoinsPluiePrevuesCumuleeMin) and empty(mapHauteurAuMoinsPluiePrevuesCumuleeMin);
	}

	string toString(parcelle parcelleEntree ,int deltaTemporel){
		return "" + self + " - parcelleEntree = " + parcelleEntree + " - Tmin = " + isTemperatureMinMoyenneOK(parcelleEntree.ilot_app.meteo, deltaTemporel)
																		 	+ " - Pluie = " + isCumuleHauteurPluieOK(parcelleEntree, deltaTemporel)
																		 	+ " - Humidite = " + isHumiditeSolOK(parcelleEntree, deltaTemporel)
																		 	+ " - culture = " + parcelleEntree.cultureParcelle;		
		
  	}
}	
