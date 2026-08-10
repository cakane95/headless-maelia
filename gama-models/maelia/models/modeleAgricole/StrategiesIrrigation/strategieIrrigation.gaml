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
 *  StrategiesIrrigation
 *  Author: Maroussia Vavasseur
 *  Description: La strategie dirrigation est l'entite qui va etre utilise par l'agriculteur pour determiner par exemple a quel moment il va irriguer.
 * 				 Il est possible de definir plusieurs strategies dirrigation differentes, qui sera alors choisie lors du parametrage de la simulation.
 */
model strategieIrrigation

import "../../modeleCommun/typeDeSol.gaml"

global { }

species strategieIrrigation parent: strategieOT {
	int periodeTourEau <- 7;
	float sirr1 <- 0.0;
	float sirr2 <- 0.0;
	float sirr3 <- 0.0;
	map<int, float> mapFenetreEchvDebut <- map<int, float>([]); //    IRRIGATION
	map<int, float> mapFenetreEchvFin <- map<int, float>([]); //    IRRIGATION
	map<int, float> mapNbJoursPluieSignif <- map<int, float>([]); //   IRRIGATION
	map<int, float> mapHauteurPluieSignifReport <- map<int, float>([]); //   IRRIGATION
	map<int, float> mapNbJoursPluiePrevuesCumulee <- map<int, float>([]); //  IRRIGATION
	map<int, float> mapHauteurPluiePrevuesCumuleeMin <- map<int, float>([]); //  IRRIGATION
	map<int, float> mapQuantiteEau <- map<int, float>([]); //  IRRIGATION  [mm]
	int reportMAX <- 7;
	string idGRP <- ''; //id de Groupe d'irrigation
	bool irrSurTauxSatisfaction <- false;
	//map<string, int> mapNbIrrig <- map([]); //  nombre d'irrigations realises sans arret de l'irrigation
	/*
	 * ATTENTION : Contrairement aux strategies de recolte et de semis, les periodes temporelles se font sur lechV pour lirrigation.
	 * Les fenetres temporelles debut et fin sont alors des entiers (on les met dans la map a lindice 0, mais ça ne correspond pas a lindice de la periode temporelle...)
	 */
	action initialisationMapsFenetreTemporelle (string donnees, map<int, float> mapEntree) {
		put int(donnees) at: 0 in: mapEntree;
	}
	// Ici il faut donc ecrire une nouvelle methode pour savoir si la periode dirrigation est possible, car la methode generique se base sur lindice de la sous periode qui est ici donnee par lechelle de vegetation
	bool isFenetreTemporelleGlobaleOk (int deltaTemporel) {
		if (fenetreTempOkLocal(jourC: (dateCour.nbJoursEcoulesDansAnnee - deltaTemporel), jourJulienFenetreMin: (mapFenetresTemporellesDebut at 0)
		, jourJulienFenetreMax: (mapFenetresTemporellesFin at 0))) {
			return true;
		} else {
			return false;
		}

	}

	// On recupere la sous periode dirrigation en regardant letat de la variable echV de la parcelle
	int getIndiceSousPeriode (parcelle parcelleEntree, int deltaTemporel) {
		int indiceCourant <- -1;
		if ((mapFenetreEchvDebut at 0) != NA) {
			if (parcelleEntree != nil) {
				loop indice over: mapFenetreEchvDebut.keys {
					if (parcelleEntree.getEchelleVegetation() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionVegetation >= (mapFenetreEchvDebut at indice) and
					parcelleEntree.getEchelleVegetation() < (mapFenetreEchvFin at indice)) {
						indiceCourant <- indice;
					}
				}
			}
		} else {
			indiceCourant <- 0;
		}
		return indiceCourant;
	}

	float getQuantiteEau (parcelle parcelleEntree, int deltaTemporel) {
		int indice <- getIndiceSousPeriode(parcelleEntree, deltaTemporel);
		if (indice >= 0) {
			return (mapQuantiteEau at indice) / nombreMillimetreDansUnMetre;
		} else {
			return 0.0;
		}
	}

	/*
	 * *****************************************************************************************
	 */
	bool isCumuleHauteurPluiePrevuesOK (zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel) {
		bool res <- true;
		if (isDonnee(mapNbJoursPluiePrevuesCumulee, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel)) {
			int nbJour <- int(getDonneeCourante(mapNbJoursPluiePrevuesCumulee, parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurPluiePrevuesCumuleeMin, parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getMaxPluiesPrevues(nb_jours: nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
			}

		}

		return res;
	}

	bool isCumuleHauteurPluieOK (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- true;
		if (isDonnee(mapNbJoursPluieObsCumulee, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurPluieObsCumuleeMax, parcelleEntree, deltaTemporel) and
		isDonnee(mapNbJoursPluieSignif, parcelleEntree, deltaTemporel) and isDonnee(mapHauteurPluieSignifReport, parcelleEntree, deltaTemporel)) {
			int nbJour <- int(getDonneeCourante(mapNbJoursPluieObsCumulee, parcelleEntree, deltaTemporel));
			int nbJourSignif <- int(getDonneeCourante(mapNbJoursPluieSignif, parcelleEntree, deltaTemporel));
			float hauteurMax <- getDonneeCourante(mapHauteurPluieObsCumuleeMax, parcelleEntree, deltaTemporel);
			float hauteurSignifReport <- getDonneeCourante(mapHauteurPluieSignifReport, parcelleEntree, deltaTemporel);
			float pluieMaxRelle <- 0.0;
			float hauteurReelle <- 0.0;
			ask parcelleEntree.ilot_app.meteo {
				hauteurReelle <- cumulePluies(nb_jours: nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau;
				pluieMaxRelle <- getMaxPluieObs(nb_jours: nbJourSignif) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau;
				if ((hauteurReelle > hauteurMax) or (pluieMaxRelle > hauteurSignifReport)) {
					res <- false;
				}
			}
		}
		return res;
	}

	action applicationRetardIrrigation (parcelle parcelleEntree, int idGroupe, int deltaTemporel) {
		int nbJour <- int(getDonneeCourante(mapNbJoursPluieObsCumulee, parcelleEntree, deltaTemporel));
		//int nbJourSignif <- int(getDonneeCourante(mapNbJoursPluieSignif, parcelleEntree, deltaTemporel));
		//float hauteurMax <- getDonneeCourante(mapHauteurPluieObsCumuleeMax, parcelleEntree, deltaTemporel);
		//float hauteurSignifReport <- getDonneeCourante(mapHauteurPluieSignifReport, parcelleEntree, deltaTemporel);
		float hauteurReelle <- 0.0;
		//float pluieMaxRelle <- 0.0;
		float doseParJour <- getDonneeCourante(mapQuantiteEau, parcelleEntree, deltaTemporel) / periodeTourEau;
		ask parcelleEntree.ilot_app.meteo {
			hauteurReelle <- cumulePluies(nb_jours: nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau;
			//pluieMaxRelle <- getMaxPluieObs(nb_jours: nbJourSignif) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau;
		}

		ask parcelleEntree {
		// On repporte le tour deau (pour ce bout de parcelle) de x jours	
			do applicationRetardIrrigation(min([myself.reportMAX, int((hauteurReelle - 15.0) / doseParJour)]), idGroupe);
		}
	}

	// Represente le taux de satifaction hydrique du sol
	// renvoie false si irrigation necessaire
	bool isTauxDeSatisfactionEauOk (parcelle parcelleEntree, int deltaTemporel) {
		if (irrSurTauxSatisfaction) and (nomChoixModeleCroissancePlante = "AqYield" or nomChoixModeleCroissancePlante = "AqYieldNC") {
			float Sirr <- 0.0;
			float echVSirr1 <- 0.4;
			float echVSirr2 <- 0.8;
			float echVSirr3 <- 1.1;
			float echVMat <- parcelleEntree.cultureParcelle.monModelDeCulture.espece.echelleVegetationStadeMaturite;
			float echVPercu <- parcelleEntree.getEchelleVegetation() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionVegetation;

			if (echVPercu >= 0) and (echVPercu < echVSirr1) {
				Sirr <- sirr1;
			} else if (echVPercu > echVSirr1) and (echVPercu < echVSirr2) {
				Sirr <- sirr1 + (sirr2 - sirr1) * (echVPercu - echVSirr1) / (echVSirr2 - echVSirr1);
			} else if (echVPercu >= echVSirr2) and (echVPercu < echVSirr3) {
				Sirr <- sirr2;
			} else if (echVPercu >= echVSirr3) and (echVPercu < echVMat) {
				Sirr <- sirr2 + (sirr3 - sirr2) * (echVPercu - echVSirr3) / (echVMat - echVSirr3);
			}// else { //(echVPercu >= echVMat)
			//	Sirr <- 0.0; // inutile deja initialise a 0.0
			//}
			if (parcelleEntree.cultureParcelle.monModelDeCulture.indiceSatifactionHydrique < Sirr) {
				return false;
			} else {
				return true;
			}
		} else {
			return false;
		}

	}

	bool isHumiditeSolOK (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;
		if (isDonnee(mapHumiditeSolMax, parcelleEntree, deltaTemporel)) {
		//res <- parcelleEntree.getHumiditeSolRacine()*parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= getDonneeCourante(mapHumiditeSolMax, parcelleEntree, deltaTemporel) * parcelleEntree.ilot_app.sol.getSeuilHumidite();
	      res <- parcelleEntree.getHumiditeSolRacine() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= getDonneeCourante(mapHumiditeSolMax, parcelleEntree, deltaTemporel);
		} else {
			res <- true;
		}
		return res;
	}
	/*
	 * *****************************************************************************************
	 * TODO : rajouter un attribut propentionARespecterRestriction (calculer dans le comportement de l'agriculteur)
	 */
	bool isActivitePossible (parcelle parcelleEntree, int idGroupe, int deltaTemporel) {
		string chaineDebug <- ""+ dateCour.annee + ";" + dateCour.nbJoursEcoulesDansAnnee; // JV debug
		bool estOk <- false;
		cultureIrrigable cultureIrrigueeTemp <- (cultureIrrigable(parcelleEntree.cultureParcelle));

		if (cultureIrrigueeTemp != nil) {
			if (isFenetreTemporelleOk(parcelleEntree, deltaTemporel) and isFenetreTemporelleGlobaleOk(deltaTemporel)) {
				parcelleEntree.itkIrrigue <- parcelleEntree.getITKAnnee(); // variable pour affichage
				
				chaineDebug <- chaineDebug + ";" + parcelleEntree.idParcelle + ";" + parcelleEntree.getITKAnnee().idITK; // JV debug
				
				bool disponibiliteRessource <- true;
				if(parcelleEntree.itkIrrigue.isDerogatoire()){
					disponibiliteRessource <- (parcelleEntree.ilot_app.ppaCourant != nil);
				}else{
					disponibiliteRessource <- parcelleEntree.ilot_app.isPpaDispo();
				}

				chaineDebug <- chaineDebug + ";" + disponibiliteRessource;  // JV debug
				if parcelleEntree.ilot_app.ppaCourant != nil {chaineDebug <- chaineDebug + ";" + parcelleEntree.ilot_app.isEnRestrictionJourCourant();}
				else {chaineDebug <- chaineDebug + ";NA";}
				chaineDebug <- chaineDebug + ";" + parcelleEntree.itkIrrigue.isDerogatoire();

				estOk <- isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel) and
				isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel) and parcelleEntree.getSurfacePouvantEtreIrriguee(idGroupe) > 0.0 and
				disponibiliteRessource and !isTauxDeSatisfactionEauOk(parcelleEntree, deltaTemporel);
				
				chaineDebug <- chaineDebug + ";" + isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel) + ";" + isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel) + ";" + parcelleEntree.getSurfacePouvantEtreIrriguee(idGroupe) +
					";" + isTauxDeSatisfactionEauOk(parcelleEntree, deltaTemporel);

				if (!isCumuleHauteurPluieOK(parcelleEntree, deltaTemporel) and estOk) {
					do applicationRetardIrrigation(parcelleEntree, idGroupe, deltaTemporel);
					estOk <- false;
					chaineDebug <- chaineDebug + ";true";
				}
				else{chaineDebug <- chaineDebug + ";false";}

				chaineDebug <- chaineDebug + ";" + isHumiditeSolOK(parcelleEntree, deltaTemporel)+
					";" + parcelleEntree.nbIrrig + ";" + periodeTourEau + ";" + length(parcelleEntree.listeGroupeIrrigationCulture);

				if( estOk and !isHumiditeSolOK(parcelleEntree, deltaTemporel) and // si humidite du sol limitant ET
					(parcelleEntree.nbIrrig > (periodeTourEau * length(parcelleEntree.listeGroupeIrrigationCulture)) //si plus d'un tour d'eau
					or (parcelleEntree.nbIrrig = 0)) // ou si redemarage irrigation  
				){
					estOk <- false;
				}

				if (!estOk) {
					parcelleEntree.nbIrrig <- 0;
				}else{
					parcelleEntree.nbIrrig <- parcelleEntree.nbIrrig +1;
				}					

				chaineDebug <- chaineDebug + ";" + estOk;
				//write chaineDebug;
				/*
				if parcelleEntree.ilot_app.codeExploitationAssociee = "082-367492"{
					save chaineDebug to: (cheminRelatifDuDossierDeSortieDeSimulation + "/irrigationIsActivitePossible.csv") type: 'text' rewrite: false; 
				}
 				*/
			}

		}

		return estOk;
	}

	/*
	 * *****************************************************************************************
	 * On met a jour l'eau qui arrive sur la culture
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree) {

	// Si parcelle dans la zone on irrigue, sinon on met la valeur au max
		if (!parc.isParcelleHorsZone) {
			float eau_irr <- 0.0; // [m3]	
			float surfaceAirriguer <- surfaceIrrigueeEntree; // Il faut rajouter cette variable car dans le cas ou il ny a rien en entree (null) gama ne pointe vers rien et on ne peut donc pas affecter une valeur sur un pointeur vide
			ask parc {
				
				if (nomChoixModeleIrrigation = GROUPE_IRRIGATION) {
					groupeIrrigationCulture gp <- getGroupe(idGroupe);
					ask gp {
						do ajoutSurfaceIrriguee(surfaceAirriguer);
					}

				} else {
					cultureIrrigable(cultureParcelle).dernierTourEau <- myself.periodeTourEau;
					surfaceAirriguer <- surface;
				}

				put (surfaceAirriguer + (parc.memoireSurfaceIrriguee at dateCour.nbJoursEcoulesDansAnnee)) at:dateCour.nbJoursEcoulesDansAnnee in:parc.memoireSurfaceIrriguee;
																					
				parcelle temp <- self; // Je dois creer une variable temp ici car sinon dans lutilisation de la methode myself.getQuantiteEau(temp) , gama ne sait plus ou il est
				eau_irr <- min([agri.eau_disponible, myself.getQuantiteEau(temp, agri.nbJoursDeDecalageActivite) * surfaceAirriguer]); // [m3], [m] * [m2]	
				if (eau_irr < zeroApproche) {
					eau_irr <- 0.0;
				}

				if verboseMode {
					write "IRRIGATION " + parc.idParcelle + "\t" + getITKAnnee().idITK + "\t" + eau_irr with_precision 2 + " m3";
					write "\tagri.eau_disponible=" + agri.eau_disponible with_precision 2 + " getQteEau=" + myself.getQuantiteEau(temp, agri.nbJoursDeDecalageActivite) with_precision 2 + " surfaceAirriguer=" + surfaceAirriguer with_precision 2;
				}
				
				// On stocke dans les PR la quantite dirrigation souhaitee, elle sera ensuite traitee par la ZH et mise a jour
				ask ilot_app {
					do prelevementEau(myself, eau_irr);
				}
				// On la donne la quatite deau souhaite pour la croissance de la plante (en [m])
				
				do hauteurEauIrrigationARajouter(quantiteEauARajouter: ((eau_irr / surface) * nombreMillimetreDansUnMetre)); // pour le mettre en hauteur je divise par la surface tot de la parcelle et non par la surfIrr				

				// JV 140121 stocke uniquement si utile
				if parc.memoireOTsurParcelle.keys contains IRRIGATION {
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at IRRIGATION);
					//map<string,string> complements <- ["irrigDose"::string(eau_irr), "irrigReelle"::"0.0"];
					// JV 041023 si module hydro activé et prélèvements simulés, irrigReelle à 0, sera MAJ lors des calculs de prélèvements dans equipementDeCaptageIRR.miseAJourVolumeReel  cf Manits #0002949
					map<string,string> complements;
					if (executerModeleHydrographique and isPrelevementEtRejetSimules) {
						complements <- ["irrigDose"::string(parc.irrigationSouhaitee with_precision nb_decimales_sorties), "irrigReelle"::string(0 with_precision nb_decimales_sorties)];
					} else { // sinon irrigationReelle = irrigationSouhaitee = irrigDose
						complements <- ["irrigDose"::string(parc.irrigationSouhaitee with_precision nb_decimales_sorties), "irrigReelle"::string(parc.irrigationReelle with_precision nb_decimales_sorties)];
					}					
					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at IRRIGATION);
				}
				
			}

		} else {
		// on dit que lirrigation reelle est nulle car alors lagriculteur devra enlever la quantite prelevee a son VP, or, l'ilot hors zone nest pas compte dans le calcul du VP au debut dannee
			ask parc {
				irrigationReelle <- 0.0; //myself.quantite_eau / surface;

			}

		}

		do ecritureDebugActivite(parc);
	}

	string toString (parcelle parcelleEntree, int deltaTemporel) {
		string date2 <- '' + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
		return
		"" + "parcelleEntree (sol_itk_materiel) =" + parcelleEntree.ilot_app.getNomZonePedo() + "_" + parcelleEntree.itkIrrigue.nomPourAffichage + "_" + parcelleEntree.itkIrrigue.matITK.idMateriel + '\n'
		//	+ " - RESTRICTION (isEnRestrictionJourCourant) = " + parcelleEntree.ilot_app.isEnRestrictionJourCourant()
 + "idparcelle =" + parcelleEntree.idParcelle + '\n' + ' date =' + date2 + '\n'
		+ ' - nbJoursEcoulesDansAnnee = '+ dateCour.nbJoursEcoulesDansAnnee
																					+ "Stress hydrique (isEnStressHydrique) =" +  parcelleEntree.isEnStressHydrique() + '\n'
																				 	+ "Pluie (isCumuleHauteurPluieOK) =" + isCumuleHauteurPluieOK(parcelleEntree, deltaTemporel)+ '\n'
																				 	+ "PluiePrevues (isCumuleHauteurPluiePrevuesOK) =" + isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel)+ '\n'
																				 	+ "Humidite (isHumiditeSolOK) =" + isHumiditeSolOK(parcelleEntree, deltaTemporel)+ '\n'
																				 	+ "Pluie-ETP (isCumuleHauteurPluieMoinsEtpOK) =" + isCumuleHauteurPluieMoinsEtpOK(parcelleEntree.ilot_app.meteo, parcelleEntree, deltaTemporel)+ '\n'
																				 	+ "SURF (getSurfaceTotalePouvantEtreIrriguee > 0,0 ) =" + parcelleEntree.getSurfaceTotalePouvantEtreIrriguee() with_precision 4 + '\n'
																				 	+ "isPpaDispo =" + parcelleEntree.ilot_app.isPpaDispo()+ '\n'
																				 	+ "isTauxDeSatisfactionEauOk =" + isTauxDeSatisfactionEauOk(parcelleEntree, deltaTemporel)+ '\n'
																				 	+ "culture = " + parcelleEntree.cultureParcelle+ '\n'
																				 	+ "EchV =" + parcelleEntree.getEchelleVegetation() with_precision 4 + '\n' 															 	
																				 	+" - Pluie Obs = " + parcelleEntree.ilot_app.meteo.liste_pluies(3)+ '\n'	
																				 	+ " - Pluie Prevus = " + parcelleEntree.ilot_app.meteo.liste_pluies_futur(7)+ '\n'	
																				 	+ " - Pluie cumulee = " + parcelleEntree.ilot_app.meteo.liste_pluies(14)+ '\n'	
																			
																				 	+ "pluie =" + parcelleEntree.getPluie()+ '\n'
																				 	+ "SURFACE =" + parcelleEntree.surface;	
																				 													 												 	
																				 	


	}

}

