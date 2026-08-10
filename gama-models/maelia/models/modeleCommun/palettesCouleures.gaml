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
 *  PalettesCouleures
 *  Author: Maroussia Vavasseur
 *  Description:Initialise les map contenant les degrades de couleur en fonction de la valeur potentielle que va prendre une entites de la simulation grace a des images d'entree. 
 */

model palettesCouleures

import "donneesGlobales.gaml"

global{
	map<int,rgb> paletteCouleursTemperature <- map([]);
	map paletteCouleursTypeCulture <- map([]);
	map<int,rgb> paletteCouleursDebitZoneHydro <- map([]);
	map paletteCouleursPrecipitationsZoneHydro <- map([]);
	map<int,rgb> paletteCouleursCoefficientCultural <- map([]);
	map paletteCouleursDebitsCrises <- map([]);
	map paletteCouleursNbJourRestriction <- map([]);
	
	string echelleTemperatueImageShape <- cheminRacineMaelia + 'images/paletteCouleurTemperature-altern.png'; // image donnant la pallette de couleur pout la temperature
	string echelleCultureImageShape <- cheminRacineMaelia + 'images/paletteCouleurCulture.png';
	string echelleCoursDeauImageShape <- cheminRacineMaelia + 'images/paletteCouleurCoursDeau.png';
	string echellePrecipiationsImageShape <- cheminRacineMaelia + 'images/paletteCouleurPrecipiations.png';
	string echelleCoefficientCulturalImageShape <- cheminRacineMaelia + 'images/paletteCouleurCoefficientCultural.png';
	string echelleCouleurDebitCriseShape <- cheminRacineMaelia + 'images/paletteCouleurDebitCrise.png';
	string echelleCouleurNbJourRestrictionShape <- cheminRacineMaelia + 'images/paletteCouleurNbJourRestriction.png';
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionPalettesCouleurs{
		
		if(executerSurCluster){ // update paths
		        echelleTemperatueImageShape <- cheminRacineMaelia + 'images/paletteCouleurTemperature-altern.png';
		        echelleCultureImageShape <- cheminRacineMaelia + 'images/paletteCouleurCulture.png';
		        echelleCoursDeauImageShape <- cheminRacineMaelia + 'images/paletteCouleurCoursDeau.png';
		        echellePrecipiationsImageShape <- cheminRacineMaelia + 'images/paletteCouleurPrecipiations.png';
		        echelleCoefficientCulturalImageShape <- cheminRacineMaelia + 'images/paletteCouleurCoefficientCultural.png';
		        echelleCouleurDebitCriseShape <- cheminRacineMaelia + 'images/paletteCouleurDebitCrise.png';
		        echelleCouleurNbJourRestrictionShape <- cheminRacineMaelia + 'images/paletteCouleurNbJourRestriction.png';
		}
		
		list<string> listeFichiers <- [echelleTemperatueImageShape, echelleCultureImageShape, echelleCoursDeauImageShape, echellePrecipiationsImageShape, echelleCoefficientCulturalImageShape, echelleCouleurDebitCriseShape, echelleCouleurNbJourRestrictionShape];
		// vérification existence des fichiers
		loop fic over: listeFichiers {
			if !file_exists(fic) {
				do raiseError("fichier inexistant: " + fic);
			}
		}

		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleTemperatueImageShape, 
			largeur: 70, 
			hauteur: 1, 
			ajustementIndiceDepart: -20, // (-20) pour dire que la gamme de temperature ne va pas de 0 a 70 mais de -20 a 50
			paletteCouleurs: paletteCouleursTemperature
		);
		
		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleCultureImageShape, 
			largeur: 8, 
			hauteur: 1, 
			ajustementIndiceDepart: 1,  // le (+1) car les id des types de culture vont de 1 a 8 (sans la prairie et autre)
			paletteCouleurs: paletteCouleursTypeCulture
		);		
	
		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleCoursDeauImageShape, 
			largeur: 8, 
			hauteur: 1, 
			ajustementIndiceDepart: 0, 
			paletteCouleurs: paletteCouleursDebitZoneHydro
		);		
		
		do action: initialisationPaletteCouleur(
			echelleImageShape: echellePrecipiationsImageShape, 
			largeur: 60, 
			hauteur: 1, 
			ajustementIndiceDepart: 0, 
			paletteCouleurs: paletteCouleursPrecipitationsZoneHydro
		);		
		
		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleCoefficientCulturalImageShape, 
			largeur: 13, 
			hauteur: 1, 
			ajustementIndiceDepart: 0, 
			paletteCouleurs: paletteCouleursCoefficientCultural
		);		
		
		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleCouleurDebitCriseShape, 
			largeur: 5, 
			hauteur: 1, 
			ajustementIndiceDepart: 0, 
			paletteCouleurs: paletteCouleursDebitsCrises
		);		
		
		do action: initialisationPaletteCouleur(
			echelleImageShape: echelleCouleurNbJourRestrictionShape, 
			largeur: 8, 
			hauteur: 1, 
			ajustementIndiceDepart: 0, 
			paletteCouleurs: paletteCouleursNbJourRestriction
		);
	}
	
	/*
	 * *****************************************************************************************
	 * Private
	 * Cree la palette donnant la correspondance entre la temperature et une couleur
	 */
	action initialisationPaletteCouleur(
		string echelleImageShape, 
		int largeur, 
		int hauteur, 
		int ajustementIndiceDepart, 
		map paletteCouleurs
	) {
	//	arg echelleImageShape type: string;
	//	arg largeur type: int;
	//	arg hauteur type: int;
	//	arg ajustementIndiceDepart type: int;
	//	arg paletteCouleurs type: map;

		matrix matriceEchelle <- file(echelleImageShape) as_matrix {largeur,hauteur} ;
				
		int nbColones <- length(matriceEchelle row_at 0);		
		list ligne0 <- (matriceEchelle row_at 0);

		loop indiceColone from: 0 to: ( nbColones - 1 ) {
			put rgb(ligne0 at indiceColone) at: (indiceColone + ajustementIndiceDepart) in: paletteCouleurs;
		}	
	}
}
