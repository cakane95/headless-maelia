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
 *  poiliceDeLeau
 *  Author: Maroussia Vavasseur
 *  Description: Son role est de controler et potentiellement verbaliser les agriculteurs qui ne respectent pas une restriction pendant la periode d'etiage.
 * 				 De plus, chaque annee elle va controler quels agriculteurs ont utilise plus d'eau que leur VP alloue et les verbalise si besoin.
 */

model policeDeLeau

import "../modeleCommun/commune.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "prefet.gaml"

global{
	map<int,list<float>> mapCorrepondanceNiveauVerbalisationQuantiteEauPreleveeEnTrop <- ([1::[0.0, 100000.0], 2::[100000.0, 10000000.0], 3::[10000000.0, 1000000000.0]]);

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionPoliceDeLeau{
		create policeDeLeau number: 1;
	}
}

species policeDeLeau{
	int nbAgriculteursAControler <- 100;
	map<int,int> mapNbAgriculteursIrriguantEnRestriction <- map<int,int>([]); // (nbFois prit en flagrant deli)::nbAgri
	map<int,int> mapNbAgriculteursNiveauVerbalisation <- map<int,int>([]); // (niveau de verbalisation en fonction de la quantite d'eau utilisee en plus du VP)::nbAgri
	int jourDeLaSemainePrecedenteControlee <- 0;
	int jourDeLaSemaineAControler <- 0;

	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		do controleRespectRestriction();
	}

	/*
	 * *****************************************************************************************
	 * A executer a la fin de l'annee et non au debut
	 */	
	action comportementAnnuel{	
		do controleRespectVolumePrelevable();
		do recapitulatifAnnuel();
		jourDeLaSemainePrecedenteControlee <- 0;
		jourDeLaSemaineAControler <- 0;
	}
	
	/*
	 * *****************************************************************************************
	 * Hebdomadaire : La police de l'eau va controler de maniere aleatoire un certain nombre d'agriculteur en periode d'etiage (1 ou 2 fois pas semaines selon l'etat du cour d'eau)
	 */			
	action controleRespectRestriction{		
		// Si on est en periode d'etiage
		if(lePrefet.isPeriodeEtiageCommencee()){							
			// Petit algo qui permet de rentrer dans la methode une fois par semaine avec a chaque fois un jour d'application different (lundi, puis mardi puis... jusqu'a dimanche et ainsi de suite)
			if(dateCour.indiceJourDeLaSemaine = 1){
				jourDeLaSemaineAControler <- (jourDeLaSemainePrecedenteControlee + 1) mod 7;
				// le modulo 7mod7 = 0, or on veut le jour 7 donc on le remet
				if(jourDeLaSemaineAControler = 0){
					jourDeLaSemaineAControler <- 7;
				}
			}
				
			if(jourDeLaSemaineAControler != jourDeLaSemainePrecedenteControlee){					
				// Il  va controler un jour different d'une semaine sur l'autre (lundi, puis mardi puis... jusqu'a dimanche)
				if(dateCour.indiceJourDeLaSemaine = jourDeLaSemaineAControler){
					
					// Il va controler uniquement les agriculteurs qui sont sous restriction ?
					list<agriculteur> listeAgriculteursAyantUneParcelleIrrigableMinimum <- listeAgriculteurs where (each.nbParcellesIrriguees > 0);	
					if(verboseMode){write "listeAgriculteursAyantUneParcelleIrrigableMinimum = " + listeAgriculteursAyantUneParcelleIrrigableMinimum collect each.idAgriculteur;}
					//list<agriculteur> listAgriculteurEnRestrictionTemp <- listeAgriculteursAyantUneParcelleIrrigableMinimum where (each.isAuMoinsUnIlotEnRestriction());
					list<agriculteur> listAgriculteurEnRestrictionTemp <- listeAgriculteursAyantUneParcelleIrrigableMinimum where (each.nbIlotsEnRestriction() > 0);  // JV 161219 the code above unexpectedly crashes on GAMA 1.8 RC2 (bug #0002438)
					if(verboseMode){write "listAgriculteurEnRestrictionTemp = " + listAgriculteurEnRestrictionTemp collect each.idAgriculteur;}
					// On prend au hasard 100 agri parmit la liste
				 	list<agriculteur> liste100AgriTemp <- nbAgriculteursAControler among listAgriculteurEnRestrictionTemp;
					if(verboseMode){write "liste100AgriTemp = " + liste100AgriTemp collect each.idAgriculteur;}

				 	// Si l'agriculteur est en train de preleve en periode de restriction
				 	// Je stocke le nombre d'agriculteur avec le nb de fois ou il a ete prit en flagrant deli et je donne a l'agriculteur une verbalisation
				 	ask (liste100AgriTemp){			 		
				 		if(isIrrigueContreRestriction()){
				 			int valeurtemp <- 0;
				 			if(mapVerbalisationsLieesRestriction at dateCour.annee != nil){
				 				valeurtemp <- mapVerbalisationsLieesRestriction at dateCour.annee;
				 			}
				 			put (valeurtemp + 1) at: dateCour.annee in: mapVerbalisationsLieesRestriction;
				 		}
				 	}						 	
				 	jourDeLaSemainePrecedenteControlee <- jourDeLaSemaineAControler;
				}
			}							
		}
	}		

	/*
	 * *****************************************************************************************
	 * La police de l'eau va controler et verbaliser si besoin les agriculteurs ayant utilise plus que leur VP, une fois par an.
	 * Ce controle se fait a la fin de l'annee
	 */			
	action controleRespectVolumePrelevable{
		let anneeCourante type: int <- dateCour.annee;
		
		// On parcours tous les agriculteurs qui ont au moins une culture irriguee cette annee
		list<agriculteur> listeAgriculteursAyantUneParcelleIrrigableMinimum <- listeAgriculteurs where (each.nbParcellesIrriguees > 0);
		ask listeAgriculteursAyantUneParcelleIrrigableMinimum{
			// Si ils ont utilise plus d'eau que leur VP alloue (equivalent a eau_disponible < 0)
			if(eau_disponible < 0.0){
				let niveauTemp type: int <- 0;
				
				loop indiceCorrespondantALaPlageEauUtiliseeEnPlus over: mapCorrepondanceNiveauVerbalisationQuantiteEauPreleveeEnTrop.keys{						
					let eauMin type: float value: (mapCorrepondanceNiveauVerbalisationQuantiteEauPreleveeEnTrop at indiceCorrespondantALaPlageEauUtiliseeEnPlus) at 0;
					let eauMax type: float value: (mapCorrepondanceNiveauVerbalisationQuantiteEauPreleveeEnTrop at indiceCorrespondantALaPlageEauUtiliseeEnPlus) at 1;
					if (abs(eau_disponible) > eauMin) and (abs(eau_disponible) <= eauMax){
						set niveauTemp <- indiceCorrespondantALaPlageEauUtiliseeEnPlus;
					}
				}					
				put niveauTemp at: anneeCourante in: mapVerbalisationsLieesRespectVP;					
			}
		}			
	}


	/*
	 * *****************************************************************************************
	 * La police de l'eau va controler et verbaliser si besoin les agriculteurs ayant utilise plus que leur VP, une fois par an.
	 * Ce controle se fait a la fin de l'annee
	 */			
	action recapitulatifAnnuel{
		let anneeCourante type: int <- dateCour.annee;
		list<agriculteur> listeAgriculteursAyantUneParcelleIrrigableMinimum <- listeAgriculteurs where (each.nbParcellesIrriguees > 0);
		ask listeAgriculteursAyantUneParcelleIrrigableMinimum{
			// Remplissage de la map donnant le nombre d'agriculteur en fonction du nombre de verbalisation ils ont eu dans l'annee (nb de fois ou ils ont pas respecte la restriction et ou ils se sont fait prendre)
			if((mapVerbalisationsLieesRestriction at anneeCourante) != nil){
				int nombreFoisTemp <- (mapVerbalisationsLieesRestriction at anneeCourante);
	 			int nombreAgrRestrictionTemp <- 0;
	 			if(myself.mapNbAgriculteursIrriguantEnRestriction at nombreFoisTemp != nil){
	 				nombreAgrRestrictionTemp <- myself.mapNbAgriculteursIrriguantEnRestriction at nombreFoisTemp;
	 			}
				nombreAgrRestrictionTemp <- nombreAgrRestrictionTemp + 1;
				put nombreAgrRestrictionTemp at: nombreFoisTemp in: myself.mapNbAgriculteursIrriguantEnRestriction;			
			}
			
			// Remplissage de la map donnant le nombre d'agriculteur en fonction du niveau de verbalisation
			if((mapVerbalisationsLieesRespectVP at anneeCourante) != nil){
				let niveauVerbalisationTemp type: int <- (mapVerbalisationsLieesRespectVP at anneeCourante) ;
				let nombreAgrNivVerbalisationTemp type: int <- 0;
	 			if(myself.mapNbAgriculteursNiveauVerbalisation at niveauVerbalisationTemp != nil){
	 				set nombreAgrNivVerbalisationTemp <- myself.mapNbAgriculteursNiveauVerbalisation at niveauVerbalisationTemp;
	 			}
				set nombreAgrNivVerbalisationTemp <- nombreAgrNivVerbalisationTemp + 1;
				put nombreAgrNivVerbalisationTemp at: niveauVerbalisationTemp in: myself.mapNbAgriculteursNiveauVerbalisation;	
			}				
		}		
	}

			
	/*
	 * *****************************************************************************************
	 * Debug
	 */
	action toString{
		write "******* " + name + " *******"; 
		write "mapNbAgriculteursIrriguantEnRestriction = " + mapNbAgriculteursIrriguantEnRestriction; 
		write "mapNbAgriculteursNiveauVerbalisation = " + mapNbAgriculteursNiveauVerbalisation; 
	}			
}

