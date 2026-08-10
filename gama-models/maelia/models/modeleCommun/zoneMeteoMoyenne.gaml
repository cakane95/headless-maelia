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
 *  zoneMeteoMoyenne
 *  Author: Maroussia Vavasseur
 *  Description: Une zone meteo moyenne va avoir la meme forme qu'une zone hydrographique.
 * 				 Elle correspond a la meteo d'une ZH. Celle-ci correspond a la somme des valeurs connues des zonesMeteo, interceptant la ZH, ramenee au prorata de l'interception ZH/ZoneMeteo.
 * 				 Correspond au donnees meteo d'une zone hydro moyenees en fonction des taux de surface. Ces valeurs evoluent en fonction du temps.
 */
model zoneMeteoMoyenne

import "../modeleHydrographique/zoneHydrographique.gaml"

global {
/*
	 * *****************************************************************************************
	 * Creation de une zone meteo moyenne par ZH
	 */
	action creationZoneMeteoMoyenne {
		
		loop zhCourante over: listeZonesHydrographiques {
			create zoneMeteoMoyenne {
				idZoneHydrographiqueAssociee <- zhCourante.idZoneHydrographique;
				idZoneMeteo <- idZoneHydrographiqueAssociee;
				self.shape <- zhCourante.shape;
				self.location <- zhCourante.location;
				list<zoneMeteo> listeZonesMeteo <- (zoneMeteo as list) where (each.shape intersects shape);
				if !empty(listeZonesMeteo) {
					loop zoneCourante over: listeZonesMeteo {
						put ((zoneCourante.shape inter shape).area / shape.area) at: zoneCourante in: mapZonesMeteo;
					}
				}

				do initialisation();
				// Association de la zone meteo a la ZH ainsi qu'a tous les ilots appartenant a la ZH
				zhCourante.meteo <- self;
			}
		}

		ask listeIlots {
		//Associer l'ilot au zoneMeteo le plus proche
			meteo <- first((zoneMeteoMoyenne as list) where (each.idZoneHydrographiqueAssociee = zoneHydroAssociee.idZoneHydrographique));
			// JV 080722 si (pasModuleHydro et pasAffecterMeteoMoyenneZHAIlot) ou meteoMoyenneZH non trouvée, cf. Mantis #0002929
			if !associerIlotMeteoZH or (meteo = nil) {
				// on trie les zoneMeteo interceptées par surface interceptée croissante et on prend la dernière (celle avec la plus grande surface interceptée)
				meteo <- last((zoneMeteo as list) where (each.shape intersects shape) sort_by (each.shape inter shape).area);
				// si l'îlot n'intercepte aucune zone météo (peut arriver dans des cas bien particuliers: ex îlot en Allemagne), on prend la zoneMeteo la plus proche
				if meteo=nil {
					meteo <- zoneMeteo closest_to location;
				}
			}
		}
		
		// écriture fichier correspondance ilot zone météo
		string chaine <- "ilot;zoneMeteo\n";
		ask listeIlots {
			chaine <- chaine + id + ";" + meteo.idZoneMeteo + "\n";
		}
		string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/corresponsanceIlotZoneMeteo.csv";
		save chaine to: fileName format: 'text' rewrite:false;

		ask (commune as list) {
		//Associer la commune a la zoneMeteo la plus proche
			zoneMeteoAssociee <- zoneMeteo closest_to location;
		}

	}

}

species zoneMeteoMoyenne parent: zoneMeteo {
	string idZoneHydrographiqueAssociee <- "";
	map<zoneMeteo, float> mapZonesMeteo <- map<zoneMeteo, float>([]); // contient toutes les zones meteo que la zone hydro intercepte avec le pourcentage de surface de chaque zoneMeteo
	action initialisation {
		float sommePourcentageTemp <- 0.0;
		// Pour calculer la moyenne, il faut ajouter chaque valeur de meteo au prorata des pourcentage
		loop zoneMeteoCourante over: (mapZonesMeteo.keys) {
			if (zoneMeteoCourante.altitudeStationAssociee > 0.0) {
				sommePourcentageTemp <- sommePourcentageTemp + (mapZonesMeteo at zoneMeteoCourante);
				altitudeStationAssociee <- altitudeStationAssociee + (zoneMeteoCourante.altitudeStationAssociee) * (mapZonesMeteo at zoneMeteoCourante);
			}

		}

		if (sommePourcentageTemp != 0.0) {
			altitudeStationAssociee <- altitudeStationAssociee / sommePourcentageTemp;
		}

	}

	/*
	 * *****************************************************************************************
	 * Fait la moyenne des differentes valeurs des zones meteo en fontion du pourcentage associe par zone meteo sur la zone hydro
	 * Il se peut quil ai ete calcule (pour les previsions) donc on ne le recalcule pas
	 */
	action miseAjourDonnees (int indiceDate) {
		if (!pluieFutur) {
			if ((mapRrMms at indiceDate) = nil) {
				float sommePourcentageTemp <- 0.0;
				tMin <- 0.0;
				tMax <- 0.0;
				pluie <- 0.0;
				etp <- 0.0;
				radiation <- 0.0;

				// Pour calculer la moyenne, il faut ajouter chaque valeur de meteo au prorata des pourcentage
				loop zoneMeteoCourante over: (mapZonesMeteo.keys) {
					sommePourcentageTemp <- sommePourcentageTemp + (mapZonesMeteo at zoneMeteoCourante);
					tMin <- tMin + (zoneMeteoCourante.mapTemperaturesMin at dateCour.indiceDate) * (mapZonesMeteo at zoneMeteoCourante); // (mapZonesMeteo at zoneMeteoCourante) renvoi le pourcentage
					tMax <- tMax + (zoneMeteoCourante.mapTemperaturesMax at dateCour.indiceDate) * (mapZonesMeteo at zoneMeteoCourante);
					pluie <- pluie + (zoneMeteoCourante.mapRrMms at dateCour.indiceDate) * (mapZonesMeteo at zoneMeteoCourante);
					etp <- etp + (zoneMeteoCourante.mapEtpMms at dateCour.indiceDate) * (mapZonesMeteo at zoneMeteoCourante);
					radiation <- radiation + (zoneMeteoCourante.mapRadiation at dateCour.indiceDate) * (mapZonesMeteo at zoneMeteoCourante);
				}

				if (sommePourcentageTemp != 0.0) {
					tMin <- tMin / sommePourcentageTemp;
					tMax <- tMax / sommePourcentageTemp;
					tMoy <- (tMin + tMax) / 2;
					pluie <- pluie / sommePourcentageTemp;
					etp <- etp / sommePourcentageTemp;
				}

				put pluie with_precision 4 at: dateCour.indiceDate in: mapRrMms;
				put etp at: indiceDate in: mapEtpMms;
				put radiation at: indiceDate in: mapRadiation;
				put tMin at: indiceDate in: mapTemperaturesMin;
				put tMax at: indiceDate in: mapTemperaturesMax;
			}

		}

		if (pluieFutur) {
			if (indiceDate > dateCour.indiceDate) {
				if ((mapRrMms at indiceDate) = nil) {
					float sommePourcentageTempF <- 0.0;
					pluieF <- 0.0;
					loop zoneMeteoCourante over: (mapZonesMeteo.keys) {
						sommePourcentageTempF <- sommePourcentageTempF + (mapZonesMeteo at zoneMeteoCourante);
						pluieF <- pluieF + (zoneMeteoCourante.mapRrMms at indiceDate) * (mapZonesMeteo at zoneMeteoCourante);
					}

					if (sommePourcentageTempF != 0.0) {
						pluieF <- pluieF / sommePourcentageTempF;
					}

					pluieJourF <- pluieF;
				}

			}

		}

	}

	/*
	 * *****************************************************************************************
	 */
	aspect basic {
		draw shape color: rgb('white');
		draw '' + int(altitudeStationAssociee) at: location color: rgb('black') size: taillePointsMax;
	}

}

