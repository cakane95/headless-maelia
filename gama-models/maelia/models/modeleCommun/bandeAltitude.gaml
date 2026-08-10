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
 *  bandeAltitude
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model bandeDaltitude

import "../modeleHydrographique/zoneHydrographique.gaml"

global{
	string bandeAltitudeShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleCommun/altitude/altitudeAgregeesParZH.shp';	

	// Action appelee seulement dans initialisationModeleSWAT.  
	action constructionBandeAltitude{
		if(file_exists(bandeAltitudeShape)){
			create bandeAltitude from: file(bandeAltitudeShape)  /*with: [	id::string(read ( ID_ALTI ))]*/{			
				zhAssociee <- zoneHydrographiqueSWAT(mapZH at string(shape get( ID_ZH )));
	
				if((zhAssociee = nil) or (self.shape.area < 10)){
					ask self{
						do die;	
					}						
				}else{					
					altitude <- float(shape get( ALTI_MOY ));
					do initialisation();
				}
			}
			list<zoneHydrographiqueSWAT> listeTemp <- listeZonesHydrographiques as list<zoneHydrographiqueSWAT>;
			ask listeTemp{
				do initNeige();
			}
			//Ajout de bande d'élévation au ilot
			loop ilotLoc over: (ilot as list){ //bandeAltiAssocie		
				float maxSurface <- 0.0;
				loop ba over: (bandeAltitude as list){
					if (ba.shape intersects ilotLoc.shape){
						float surface <- (ba.shape intersection ilotLoc.shape).area;
						if (surface > maxSurface){
							ilotLoc.bandeAltiAssocie <- ba;
							maxSurface <- surface;
						}
					}
				}
			}
		}else{
			do raiseWarning("fichier inexistant: " + bandeAltitudeShape + " \u2192 neige non simulée");
			isNeige <- false;
		}		
	}	
}

species bandeAltitude {
	string id <- "";
	zoneHydrographiqueSWAT zhAssociee <- nil;
	float altitude <- 0.0; //elevb(ib,i)  [m]
	float fraction <- 0.0; // elevbfr(id,i)  dans ZH
	float tDiff <- 0.0;
	float pDiff <- 0.0;
	float temperatureMoy <- 0.0; // tavband(ib,izh)
	float temperatureMin <- 0.0; // tmnband(ib,izh)
	float temperatureMax <- 0.0; // tmxband(ib,izh)
	float precipitations <- 0.0; // pcpband(ib,izh) [mm]		
	float temperatureNeige <- 1.0; // snotmpeb(ib,i)
	float eauDansPaquetNeige <- 0.0; // snoeb(ib,j)  [mm]
	float fonteDeNeige <- 0.0; // smleb (snomelt de bande)
 			
 	action initialisation{
		id <- zhAssociee.idZoneHydrographique + "_" + int(altitude);
		name <- id;		
		fraction <- (self.shape intersection zhAssociee.shape).area / zhAssociee.shape.area;
		ask(zhAssociee){
			add myself to: bandesDelevation;
		}
 	}		
 			
	action ajustement{ 		
		// TODO : faire a initialisation 
		tDiff <- (altitude - zhAssociee.meteo.altitudeStationAssociee) * tlaps / 1000;
		pDiff <- (altitude - zhAssociee.meteo.altitudeStationAssociee) * plaps / 1000;
		
		temperatureMoy <- zhAssociee.tMoy + tDiff;
		temperatureMin <- zhAssociee.tMin + tDiff;
		temperatureMax <- zhAssociee.tMax + tDiff;
								
		if(zhAssociee.pluie > precipitationMin){
			precipitations <- max([0.0, zhAssociee.pluie + pDiff]);				
		}else{
			precipitations <- 0.0;
		}
	} 
			
    /*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- "[BANDE ALTI] " + id ; 
		resultat <- resultat + ' - zhAssociee  : ' + zhAssociee;
		resultat <- resultat + ' - altitude : ' + altitude;
		resultat <- resultat + ' - fraction : ' + fraction;
		resultat <- resultat + ' - tDiff : ' + tDiff;
		resultat <- resultat + ' - pDiff : ' + pDiff;
	 	resultat <- resultat + ' - temperatureMoy : ' + temperatureMoy;
		resultat <- resultat + ' - temperatureMin : ' + temperatureMin;
		resultat <- resultat + ' - temperatureMax : ' + temperatureMax;
		resultat <- resultat + ' - precipitations : ' + precipitations;
		resultat <- resultat + ' - temperatureNeige : ' + temperatureNeige;
		resultat <- resultat + ' - eauDansPaquetNeige : ' + eauDansPaquetNeige;
		resultat <- resultat + ' - fonteDeNeige : ' + fonteDeNeige;
		return resultat;
	}	
}  
