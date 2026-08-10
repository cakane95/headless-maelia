/***************************************************************************
 * MAELIA - http://maelia-platform.inra.fr/
 *    Copyright (C) 2014-2017 
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
* Name: zoneAdministrativeComplexe
* Author: lardyr
* Description: Gestion des ZA selon une approche simple sur le debit
*/

model zoneAdministrativeSimple

import "zoneAdministrative.gaml"

global{
	int nbJoursMinPourChangerRestriction <- 3 const: true; // Il faut attendre 3 jours pour pouvoir baisser ou monter de 1 niveau si il y a eu une amelioration
	string cheminSeuilsDeRestriction <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/zonesAdministratives/';
 	string nomFichierSeuilsDeRestriction <- 'seuilsDeRestriction.csv';
	
	
	action creationZonesAdministrativesSimple{
		do creationZonesAdministratives(zoneAdministrativeSimple);
		do lectureSeuilDeGestionZA;
	}
	
	action lectureSeuilDeGestionZA{
		if !(file_exists(cheminSeuilsDeRestriction + nomFichierSeuilsDeRestriction)){
			write "Probleme, le fichier des seuils pour la gestion des restrictions n'existe pas";
			do die;
		}
		matrix InitSeuils <- matrix<string>(csv_file(cheminSeuilsDeRestriction + nomFichierSeuilsDeRestriction,";", string,false));
		//matrix InitSeuils <- matrix(file(cheminSeuilsDeRestriction + nomFichierSeuilsDeRestriction));
		int nbLignes <- length(InitSeuils column_at 0);
		loop i from: 1 to: (nbLignes -1){
			list<string> ligneI <- InitSeuils row_at i;	
			ask zoneAdministrativeSimple where (each.idZoneAdministrative = (ligneI at 0)){
				int niveau <- int(ligneI at 2);
				put (ligneI at 1)  at: niveau in: nomAffichageNiveauRestriction;
				put float(ligneI at 3)  at: niveau in: mapSeuilNiveauDeRestriction;
			}
		}
		
	}
}

species zoneAdministrativeSimple parent:zoneAdministrative{
	map<int,float> mapSeuilNiveauDeRestriction <- map<int,float>([]) ;
	/*
	 * *****************************************************************************************
	 * // Les lachers sont fait de puis le gestionnaire de barrage
	 */			
	action gestionEtiage{	
		// RESTRICTIONS
		if(isEnCampagneEtiage){				
			// On ne peut baisser ou monter le niveau de l'arrete que si il y est depuis 3 jours

			if((niveauDeRestriction = 0) or nbJoursMemeNiveauRestriction >= nbJoursMinPourChangerRestriction){
				int nouveauNiveauRestriction <- 0;
				loop niveau from:1 to: length(mapSeuilNiveauDeRestriction) {
					if(pointDeReferenceAssocie.qmj3 < (mapSeuilNiveauDeRestriction at niveau)){
						nouveauNiveauRestriction <- niveau ;
					}else{
						break;
					}
				}
				do interdictionPompage(nouveauNiveauRestriction);
			}else{
				nbJoursMemeNiveauRestriction <- nbJoursMemeNiveauRestriction +1;
			}
							
			// Si la zone aval est en restriction : il faut que le niveau de la ZA courante soit >= niv -1 de la ZA avale
			// On ne force le niveau de la ZA courante que si il est strictement < a celui de la ZA aval (car si le niveau de la ZA courante >= niveau de la ZA aval alors on ne prend pas en compte)
			// Si le debit de la ZA courante est > au debit max alors aucun traitement n'est necessaire					
			if(zoneAdministrativeAval != nil and zoneAdministrativeAval.niveauDeRestriction > (niveauDeRestriction + 1)){				
				consoleDebug <- consoleDebug + '[gestionEtiage]  za aval en restriction sup \n';									
				do interdictionPompage(zoneAdministrativeAval.niveauDeRestriction - 1);					
			}
		}
	}	
	
}
