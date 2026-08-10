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
 *  fractionCulture
 *  Author: david
 *  Description: 
 */

model groupeIrrigationCulture

import "../Ilots/ilot.gaml"
	
global{
	groupeIrrigationCulture creationGroupeIrrigationCulture(int idGroupe, float surfaceGroupe, parcelle parcelleEntree, groupeIrrigation groupe){
		groupeIrrigationCulture res <- nil;
		create groupeIrrigationCulture{
			indiceGroupe <- idGroupe;
			surface <- surfaceGroupe;
			parcelleAssociee <- parcelleEntree;
			parcelleEntree.listeGroupeIrrigationCulture << self;
			groupeAssocie <- groupe;
			res <- self;
		}
		
		return res;
	}
}	
	
species groupeIrrigationCulture{
	int indiceGroupe <- 0;
	groupeIrrigation groupeAssocie <- nil;
	float surface <- 0.0;
	parcelle parcelleAssociee <- nil;
	map<int,float> mapDerniereIrrigation <- map<int,float>([]); // nbJourRestantJusquaNouveauTourEau::surfaceIrrigueeDuGroupe		

	int getPeriodeTourEau{
		return parcelleAssociee.getITKAnnee().strategieIrrigationITK.periodeTourEau;
	}
	float getFraction{
		return surface/parcelleAssociee.surface;
	}
	// Renvoie la surface ayant ete irrigue ce jour (et donc ne pouvant plus etre irriguee)	
	float getSurfaceIrrigueeJourCourant{
		return (mapDerniereIrrigation at (getPeriodeTourEau()));// au moment ou on lit ça, la map a deja ete decrementee de 1 jour			
	}
	// renvoie la surface pouvant etre irrigue ce jour
	float getSurfaceIrrigableJourCourant{
		return (surface - sum(mapDerniereIrrigation.values));
	}		
	action ajoutRetardIrrigation(int nbJourRetard){		
		float surfaceNePouvantEtreIrrigueEncoreNbJourEntree <- mapDerniereIrrigation at nbJourRetard;
		put (surfaceNePouvantEtreIrrigueEncoreNbJourEntree + getSurfaceIrrigableJourCourant()) at: nbJourRetard in: mapDerniereIrrigation;
	}
	action ajoutSurfaceIrriguee(float surfaceIrriguee){			
		put surfaceIrriguee at: getPeriodeTourEau() in: mapDerniereIrrigation;
	}		
	/*
	 * Doit etre appele en debut de jour!
	 * On enleve tout ce qui a atteint 0 jours
	 */ 
	action miseAjourMapDerniereIrrigation{
		map<int,float> mapCopie <- mapDerniereIrrigation;	
		mapDerniereIrrigation <- map<int,float>([]);		
		loop nbJours over: mapCopie.keys{
			int nbJourRecalcule <- nbJours - 1;
			if(nbJourRecalcule > 0){
				put (mapCopie at nbJours) at: nbJourRecalcule in: mapDerniereIrrigation;
			}				
		}
	}
	
	string toString{
		return "parcelleAssociee = " + parcelleAssociee +
				"| indiceGroupe = " + indiceGroupe +
				"| groupeAssocie = " + groupeAssocie +
				"| fraction = " + getFraction() +
				"| surface = " + surface +
				"| getSurfaceIrrigableJourCourant = " + getSurfaceIrrigableJourCourant() +
				"| getSurfaceIrrigueeJourCourant = " + getSurfaceIrrigueeJourCourant() +
				"| mapDerniereIrrigation = " + mapDerniereIrrigation;
	}			
}
