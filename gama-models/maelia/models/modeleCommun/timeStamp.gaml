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
 *  TimeStamp
 *  Author: Maroussia Vavasseur
 *  Description: Methode globale qui va afficher dans la console une information supplementaire : le tems en secondes depuis le lancement de la simulation.
 * 				 Utile si on veut connaitre automatiquement les temps d'initialisation qui peuvent etre tres longs.
 */

model timeStamp

import "donneesGlobales.gaml"

global{
	float timeStampPremierJourSimulation <- 0.0;
	int increment <- 0; 
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionTimeStamp{
		create timeStamp number: 1;
		ask (timeStamp as list){
			do initialisationtimeStamp();
		}		
	}
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Va ecrire principalement dans la console
	 */
	action ecritureConsolePourDebug(bool isAfficherTemps <- true, string chaineAEcrire <- "") {
		
		if(afficherDetailInitialisation){
			if(isAfficherTemps and not(testRegressionMode)){
				int tempsMillisecondes <- 0;	
				string heureDebug <- '';	
				
				ask first(timeStamp as list){
					tempsMillisecondes <- gettimeStampLocale();
				}
				
				heureDebug <- string(tempsMillisecondes / 1000);	
//				write heureDebug + ' s\t\t\t' + increment + ' - ' + chaineAEcrire;
				write heureDebug + ' s ----------------' + increment + ' - ' + chaineAEcrire;
				increment <- increment + 1;						
			}else{
				write chaineAEcrire;
			}
			isAfficherTemps <- true;		
		}
	}
		
	float getTempsEcouleDepuisPremierJourSimulation{			
		float timeStampTemp <- 0.0;
		ask first(timeStamp){
			timeStampTemp <- getTimeStamp();
		}			
		return (timeStampTemp-timeStampPremierJourSimulation);
	}
}


species timeStamp {			
	float timeStampInitiale <- 0.0;
	float timeStampLocale <- 0.0;
	
	/*
	 * *****************************************************************************************
	 */		
	action initialisationtimeStamp{
		timeStampInitiale <- gama.machine_time;
	}

	/*
	 * *****************************************************************************************
	 */			
	int gettimeStampLocale{
		timeStampLocale <- gama.machine_time - timeStampInitiale;
		return int(timeStampLocale);
	}
	

	/*
	 * *****************************************************************************************
	 * Publique
	 * Renvoi le time stamp
	 */
	float getTimeStamp {
		int tempsMillisecondes <- 0;	
		float heureDebug <- 0.0;			
		
		tempsMillisecondes <- gettimeStampLocale();					
		heureDebug <- tempsMillisecondes / 1000;	
		
		return heureDebug;
	}		
}	

