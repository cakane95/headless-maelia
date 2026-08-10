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
 *  prefet
 *  Author: Maroussia Vavasseur
 *  Description: Le principal acteur du modele normatif est le prefet. Il n'y en a qu'un pour toute la zone MAELIA. 
 * 				 C'est lui qui decide de faire un arrete ou de de faire des laches de barrage pour l'etiage.
 * 				 Les laches pour l'electricite sont simules a travers le gestionnaire de barrage. 
 */

model prefet

import "zoneAdministrative.gaml"
 
global{
	prefet lePrefet <- nil;
	
	action constructionPrefet{
		create prefet number: 1{
			lePrefet <- self;
			do initialisationPrefet();
		}
	}
}

species prefet{		
	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		do surveillance();
		do gestionEtiage();
	}

	/*
	 * *****************************************************************************************
	 */	
	action initialisationPrefet{	
		ask dateCour{
			premierJourDeLaPeriodeDetiage <- calculNbJourEcouleDansAnnee(premierJourEtiage,  premierMoisEtiage);
		}
	}		

	bool isPeriodeEtiageCommencee{
		if(dateCour.nbJoursEcoulesDansAnnee >= premierJourDeLaPeriodeDetiage){
			return true;
		}else{
			return false;
		}		
	}

	/*
	 * *****************************************************************************************
	 * Surveillance des points de references et choix des points qui vont etre en etiage
	 */			
	action surveillance{
		ask (listZonesAdministratives){
			do surveillanceZoneAdministrative();
		}
	}

	/*
	 * *****************************************************************************************
	 */			
	action gestionEtiage{
		// doit etre executer des ZA aval a amont
		ask (listeZAparOrdreAvalVersAmont){
			if(isEnCampagneEtiage){
				do gestionEtiage();									
			}
		}			
	}
	
	/*
	 * *****************************************************************************************
	 */
	string toString{			
		return "******* " + name + " *******"; 
	}			
}
