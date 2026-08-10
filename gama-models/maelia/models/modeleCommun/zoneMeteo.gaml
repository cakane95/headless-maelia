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
 *  ZonesMeteo
 *  Author: Maroussia Vavasseur
 *  Description: Une zone meteo se defini comme un polygone autour des points meteo donnes par MeteoFrance (SAFRAN) ; donnees observees (12km* ?).
 * 				 Anisi, sur la zone d'etude, les zones meteo font une grille recouvrant toute la zone. 
 * 				 En 2010, les donnees observees sont remplacees par les donnees projettees d'ARPEGE. Dans ce cas les polygones n'ont plus la meme taille (8 km2 ?)
 */
model zoneMeteo

import "contourZoneMaelia.gaml"

global {
	string polygonesMeteoShape <- "";
	string cheminMeteoObservee <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/meteo/observee/'; // trim2000_2009.csv
	string cheminMeteoProjettee <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/meteo/simulee/';
		
	bool pluieFutur <- false;
	int nbJourF;
	float pluieJourF;

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionZoneMeteo {
				
		/* JV 070422: dorénavant les shapes polygones sont stockés dans le même répertoire que les données météo correspondantes (car les polygones peuvent changer selon les scénarios et si observee ou pas) cf. Mantis #0002892
		 * si nomScenarioClimatique!="" on cherche dans /modeleCommun/meteo/simulee/nomScenarioClimatique
		 * sinon						on cherche dans /modeleCommun/meteo/observee
		 * si pas trouve on cherche à la racine de /modeleCommun/meteo/ pour rétro-compatibilité avec les anciens includes 
		 */ 
		if nomScenarioClimatique!="" {
			polygonesMeteoShape <- cheminMeteoProjettee + nomScenarioClimatique + "/polygonesMeteoFrance.shp";
		}else {
			polygonesMeteoShape <- cheminMeteoObservee + "polygonesMeteoFrance.shp";
		}
		if !file_exists(polygonesMeteoShape) {
			polygonesMeteoShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/meteo/polygonesMeteoFrance.shp';
		}
		if !file_exists(polygonesMeteoShape) 	{do raiseError("fichier inexistant: " + polygonesMeteoShape);}
		//if !is_shape(polygonesMeteoShape) 		{do raiseError("le fichier " + polygonesMeteoShape + " n'est pas un fichier shape");}
		
		// teste existence fichiers météo nécessaires à la simulation, déclenche une erreur s'il manque un fichier
		do checkExistenceMeteoFiles;
		
		create zoneMeteo from: file(polygonesMeteoShape) with: [idZoneMeteo::string(read(ID_PDG)), altitudeStationAssociee::float(read(ALTI_MOY))] {
			set name value: idZoneMeteo;
			
			// Suppression des zones meteos nappartenat pas a la zone detude
			if (contourZoneEtude = nil or !(shape intersects contourZoneEtude.shape) and !utiliserMemeDonnesMeteoPartout) {
				ask self {
					do die;
				}
			}
		}

		do chargementDataMeteoAnneeCourante();
	}

	action chargementDataMeteoAnneeCourante {
		string meteoAnneeCourantChemin <- getCheminMeteoAnneeCourante();
		if (file_exists(meteoAnneeCourantChemin)) {
			file meteoFile <- csv_file (meteoAnneeCourantChemin, ";", false);
			do lectureData(matrix(meteoFile));
			if (utiliserMemeDonnesMeteoPartout) {
				do affectationMemeDonneesPourTousPointsMeteo();
			}

			ask zoneMeteo {
				do comportementJournalier();
			}

		} else {
			//write "[ZoneMeteo/chargementDataAnneeAvenir] !! Le fichier nexiste pas : " + meteoAnneeCourantChemin;
			do raiseError("fichier météo manquant: " + meteoAnneeCourantChemin); // ne devrait jamai se produire car existence des fichiers météo testée à l'initialisation
		}

	}

	// JV 160322: désormais chemin=observee si pas de scénario climatique spécifié dans le launcher, chemin=simulee/scenario sinon (Mantis #0002888)
	string getCheminMeteoAnneeCourante {
		string chemin <- "";
		if nomScenarioClimatique="" {
			chemin <- cheminMeteoObservee + string(dateCour.annee) + ".csv";
		}else{
			chemin <- cheminMeteoProjettee + nomScenarioClimatique + "/" + string(dateCour.annee) + '.csv' ;
		}
		return chemin;
	}


	/*
	 * *****************************************************************************************
	 * Private
	 * Lecture des fichiers .csv pour initialiser les zonesMeteo
	 * ATTENTION : le fichier lu doit etre avec un format de date : jj/mm/aaaa (sans le 000000 apres) et les float doivent avoir un point et non une virgule de decimal
	 */
	action lectureData {
		arg dataMeteoEntree type: matrix default: [];
		int nbLignes <- length(dataMeteoEntree column_at 0);
		loop i from: 1 to: (nbLignes - 1) {
			list<string> ligneI <- (dataMeteoEntree row_at i) as list<string>;
			string idLigneCourante <- (ligneI at 0);
			zoneMeteo zoneMeteoCourant <- (zoneMeteo as list) first_with (each.idZoneMeteo = idLigneCourante);
			if(zoneMeteoCourant!=nil){
				ask zoneMeteoCourant {
				// Parsing date
					let dateCouranteTemporaire type: list<string> value: (ligneI at 1) tokenize '/, ';
					let anneeCourant type: int value: int(dateCouranteTemporaire at 2);
					let jourCourant type: int value: int(dateCouranteTemporaire at 0);
					let moisCourant type: int value: int(dateCouranteTemporaire at 1);
					let idDateCourante type: int value: jourCourant * 1000000 + moisCourant * 10000 + anneeCourant;
					int indiceDateConverti <- dateCour.convertirDateEnIndice(jourAConvertir: jourCourant, moisAConvertir: moisCourant, anneeAConvertir: anneeCourant);
					put float(ligneI at 2) at: indiceDateConverti in: mapRrMms;
					//write "MAP : " + mapRrMms;		
					put float(ligneI at 2) at: indiceDateConverti in: mapRrMmsF;
					put float(ligneI at 3) at: indiceDateConverti in: mapTemperaturesMin;
					put float(ligneI at 4) at: indiceDateConverti in: mapTemperaturesMax;
					put float(ligneI at 5) at: indiceDateConverti in: mapEtpMms;
					if (length(ligneI) > 6) {
						put float(ligneI at 6) at: indiceDateConverti in: mapRadiation;
					}	
				}
			}
		}
	}

	/*
	 * Local
	 */
	action affectationMemeDonneesPourTousPointsMeteo {
		zoneMeteo meteoUtile <- (zoneMeteo as list) first_with (each.idZoneMeteo = idPointMeteoUnique);
		if (meteoUtile != nil) {
			ask ((zoneMeteo as list) - meteoUtile) {
				do clone(zoneEntree: meteoUtile);
			}

		} else {
			do raiseWarning("le point météo unique " + idPointMeteoUnique + " ne correspond à aucune zone météo, la météo considérée sera la météo réelle");
			//write "[ZoneMeteo/affectationMemeDonneesPourTousPointsMeteo] Attention la zone meteo est nulle (la meteo consideree sera donc la meteo reelle) : " + idPointMeteoUnique;
		}
		// On suprime ensuite les zone meteo inutiles
		ask (zoneMeteo as list) {
		// Suppression des zones meteos nappartenat pas a la zone detude
			if (!(shape intersects contourZoneEtude.shape)) {
				ask self {
					do die;
				}
			}
		}
	}

	/* teste la présence de tous les fichiers météo nécessaires à la simulation, i.e. pour chaque année doit être présent
	 * - dans modeleCommun/meteo/observee/ si aucun scénario climatique spécifié dans le launcher
	 * - dans modeleCommun/meteo/simulee/nomScenarioClimatique/ si spécifié
	 * - déclenche une erreur si fichier absent
	 * JV 160322  (Mantis #0002888)
	 */
	action checkExistenceMeteoFiles {
		string chemin <- "";
		if nomScenarioClimatique!="" {
			chemin <- cheminMeteoProjettee + nomScenarioClimatique + "/";
		}else{
			chemin <- cheminMeteoObservee;
		}
		loop i from: anneeDebutSimulation to: anneeDebutSimulation+nbAnneesSimulation-1 {
			if !file_exists(chemin + i + ".csv") {
				do raiseError("aucun fichier météo pour l'année " + i + ": fichier " + chemin + i + ".csv absent");
			}
		}
	}
	

	// TODO : supprimer les valeurs des dernieres annes sauf la toute deniere
	action miseAzeroZoneMeteo {
		ask (zoneMeteo as list) {
			do miseAzero();
		}

	}

}

species zoneMeteo {
	string idZoneMeteo <- '';
	float tMin <- 0.0; // [C]  temperaturesMin
	float tMax <- 0.0; // [C]  temperaturesMax
	float tMoy <- 0.0; // [C]  temperatureMoy
	float pluie <- 0.0; // [mm]  rrMms	
	float pluieF <- 0.0; // [mm]  rrMms
	float etp <- 0.0; // [mm]  etpMms
	float radiation <- 0.0; // [MJ.m-2.d-1]		
	map<int, float> mapTemperaturesMin <- map<int, float>([]); // par jour on a une valeur de tMin
	map<int, float> mapTemperaturesMax <- map<int, float>([]);
	map<int, float> mapRrMms <- map<int, float>([]); // [m]
	map<int, float> mapRrMmsF <- map<int, float>([]); // [m]
	map<int, float> mapEtpMms <- map<int, float>([]); // [m]
	map<int, float> mapRadiation <- map<int, float>([]); // ?
	float altitudeStationAssociee <- 0.0;
	rgb couleurPrecipitations <- rgb('white');
	rgb couleurTemperature <- rgb('white');

	/*
	 * *****************************************************************************************
	 */
	action comportementJournalier {
		do miseAjourDonnees(dateCour.indiceDate);
		do coloration();
	}

	action miseAzero {
		mapTemperaturesMin <- map<int, float>([]);
		mapTemperaturesMax <- map<int, float>([]);
		mapRrMms <- map<int, float>([]);
		mapRrMmsF <- map<int, float>([]);
		mapEtpMms <- map<int, float>([]);
		mapRadiation <- map<int, float>([]);
	}

	/*
	 * *****************************************************************************************
	 * Sans BD
	 */
	action miseAjourDonnees (int indiceDate) {
		tMin <- mapTemperaturesMin at indiceDate;
		tMax <- mapTemperaturesMax at indiceDate;
		tMoy <- (tMin + tMax) / 2;
 
		//pluie <- pluie;
		pluie <- mapRrMms at indiceDate;
		etp <- mapEtpMms at indiceDate;
		radiation <- mapRadiation at indiceDate;
	}

	/*
	 * *****************************************************************************************
	 * Si donnees existe pas (la calculer)
	 */
	float getValeurMoyenne (map<int, float> mapData, int jourEntree, int nb_jours) {
		float dataMoy <- 0.0;
		loop i from: jourEntree - (nb_jours - 1) to: jourEntree {
			dataMoy <- dataMoy + mapData at i;
		}

		dataMoy <- dataMoy / nb_jours;
		return dataMoy;
	}

	float getValeurMin (map<int, float> mapData, int jourEntree, int nb_jours) {
		float dataMin <- 10000000.0;
		loop i from: jourEntree - (nb_jours - 1) to: jourEntree {
			dataMin <- min([mapData at i, dataMin]);
		}

		return dataMin;
	}

	float getValeurMax (map<int, float> mapData, int jourEntree, int nb_jours) {
		float dataMax <- 10000000.0;
		loop i from: jourEntree - (nb_jours - 1) to: jourEntree {
			dataMax <- max([mapData at i, dataMax]);
		}

		return dataMax;
	}

	float getMaxPluiesPrevues (int nb_jours) {
	//			float pluiesPrevues <- 0.0;
	//			loop i from: dateCour.indiceDate  to: (dateCour.indiceDate + nb_jours -1){
	//				if((mapRrMms at i) = nil){
	//					do miseAjourDonnees(i);
	//				}
	//				pluiesPrevues <- max( [pluiesPrevues , (mapRrMms at i)]);
	//			} 			
	//			return pluiesPrevues;
		return max(liste_pluies_futur(nb_jours: nb_jours));
	}
	
	float getCumulPluiesPrevues (int nb_jours) {
		return sum(liste_pluies_futur(nb_jours: nb_jours));
	}

	float getCumulePluiesMoinsETP (int nb_jours) {
		float pluiesMoinsETP <- 0.0;
		loop i from: (dateCour.indiceDate - nb_jours) to: (dateCour.indiceDate - 1) {
			float pluieMoy <- getValeurMoyenne(mapRrMms, i, 5);
			float etpMoy <- getValeurMoyenne(mapEtpMms, i, 5);
			pluiesMoinsETP <- pluiesMoinsETP + (pluieMoy - etpMoy);
		}

		return pluiesMoinsETP;
	}

	float cumulePluies (int nb_jours) {
		return sum(liste_pluies(nb_jours: nb_jours));
	}

	float getMaxPluieObs (int nb_jours) {
		return max(liste_pluies(nb_jours: nb_jours));
	}

	float getTminMoyenne (int nb_jours) {
		return getValeurMoyenne(mapTemperaturesMin, dateCour.indiceDate, nb_jours);
	}

	float getTmoy (int nb_jours) {
		float tmin <- getValeurMoyenne(mapTemperaturesMin, dateCour.indiceDate, nb_jours);
		float tmax <- getValeurMoyenne(mapTemperaturesMax, dateCour.indiceDate, nb_jours);
		return(mean(tmin, tmax));
	}

	float getTmax (int nb_jours) {
		return getValeurMax(mapTemperaturesMax, dateCour.indiceDate, nb_jours);
	}

	float getTmin (int nb_jours) {
		return getValeurMin(mapTemperaturesMin, dateCour.indiceDate, nb_jours);
	}

	list<float> liste_pluies (int nb_jours) {
		let pluies type: list of: float value: [];
		loop i from: (dateCour.indiceDate - nb_jours) to: (dateCour.indiceDate - 1) {
			add item: mapRrMms at i to: pluies;
		}

		return pluies;
	}

	list<float> liste_pluies_futur (int nb_jours) {
		let pluiesF type: list of: float value: [];
		nbJourF <- nb_jours;
		loop i from: (dateCour.indiceDate) to: (dateCour.indiceDate + nb_jours - 1) {
			if ((mapRrMms at i) = nil) {
				pluieFutur <- true;
				do miseAjourDonnees(i);
				add item: pluieJourF to: pluiesF;
			} else {
				add item: mapRrMms at i to: pluiesF;
			}

		}

		pluieFutur <- false;
		return pluiesF;
	}

	float pluies_periode (int debut, int fin) {
		let pluiePeriode type: float value: 0.0;
		loop i from: debut to: fin {
			set pluiePeriode value: pluiePeriode + (mapRrMms at i);
		}

		return pluiePeriode;
	}

	float ETP_periode (int debut, int fin) {
		float etpPeriode <- 0.0;
		loop i from: debut to: fin {
			etpPeriode <- etpPeriode + (mapEtpMms at i);
		}

		return etpPeriode;
	}

	/*
	 * *****************************************************************************************
	 */
	action coloration {
		if (pluie = 0.0) {
			set couleurPrecipitations value: rgb('white');
		} else {
			loop indiceCorrespondantALaPlageDuDebit over: mapCorrespondanceIndicePlageHauteurPluie.keys {
				let debitMin type: int value: (((mapCorrespondanceIndicePlageHauteurPluie at indiceCorrespondantALaPlageDuDebit)) at 0);
				let debitMax type: int value: (((mapCorrespondanceIndicePlageHauteurPluie at indiceCorrespondantALaPlageDuDebit)) at 1);
				if (pluie > debitMin) and (pluie <= debitMax) {
					set couleurPrecipitations value: paletteCouleursDebitZoneHydro at indiceCorrespondantALaPlageDuDebit;
				}

			}

		}

		couleurTemperature <- paletteCouleursTemperature at int(tMoy); // temperatureMoyenne		

	}

	action clone (zoneMeteo zoneEntree) {
		mapRrMms <- zoneEntree.mapRrMms;
		mapTemperaturesMin <- zoneEntree.mapTemperaturesMin;
		mapTemperaturesMax <- zoneEntree.mapTemperaturesMax;
		mapEtpMms <- zoneEntree.mapEtpMms;
		mapRadiation <- zoneEntree.mapRadiation;
	}

	/*
	 * *****************************************************************************************
	 */
	aspect basic {
		draw shape color: couleurPrecipitations;
		//			draw '' + int(idZoneMeteo) + '-' + int(altitudeStationAssociee) at: location color: rgb('black') size: tailleTexte;

	}

	/*
	 * *****************************************************************************************
	 */
	aspect precipitationsAspect {
		draw shape color: couleurPrecipitations;
		draw '' + int(idZoneMeteo) + '-' + pluie at: location color: rgb('black') size: tailleTexte;
	}

	/*
	 * *****************************************************************************************
	 */
	aspect temperatureAspect {
		draw shape color: couleurTemperature;
		draw '' + int(idZoneMeteo) + '-' + tMoy at: location color: rgb('black') size: tailleTexte;
	}
	/*
	 * *****************************************************************************************
	 */
	string toString {
		string resultat <- name;
		resultat <- resultat + " - temperaturesMin : " + tMin;
		resultat <- resultat + " - temperaturesMax : " + tMax;
		resultat <- resultat + " - rrMms : " + pluie;
		resultat <- resultat + " - etpMms : " + etp;
		return resultat;
	}

}

species previsionMeteo parent: zoneMeteo {
	int indiceDeConfiance ;
}
