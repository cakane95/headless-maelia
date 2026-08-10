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
 *  NoeudsHydrographiques
 *  Author: Maroussia Vavasseur
 *  Description: Le noeud ne fait pas parti du DAR, mais il represente neanmoins une entite clef du modele hydro. C'est grace a lui qu'il est possible de relier les troncons unitaires ou les ZH entre eux.
 */

model noeudHydrographique

import "../modeleCommun/contourZoneMaelia.gaml"

global{ 
	string noeudsHydrographiquesShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/troncons/noeudsExutoireZH.shp';  // noeudsHydrographiques
	
	/*
	 * *****************************************************************************************
	 * Publique 
	 */
	action constructionNoeudHydrographique{
		if(file_exists(noeudsHydrographiquesShape)){
			create noeudHydrographique from: file(noeudsHydrographiquesShape) with: [idNoeudHydrographique::int(read ( ID_BDCARTH ))]{
				// Suppression des polygones nappartenant pas a la zone detude
				if(executerModeleSurUneZH and contourZoneEtude != nil and !(shape intersects contourZoneEtude.shape)){
					ask self{
						do die;	
					}						
				}else{
					do initialisation();
				}
			}
		}				
	}
}

species noeudHydrographique{
	rgb couleur <- rgb('green');
	int idNoeudHydrographique;
	bool isNoeudPrincipal <- false;
	//bool appartientAcoursDeauNaturel  <- false; // utile pour savoir si le noeud appartient a un cours deau naturel (meme si il peut egalement appartenir a un canal). Car certain appartiennent qu'aux canaux et ca pose un pb pour la determination des noeuds de la zone hydro
	
	
	action initialisation{			
		// Affectation du point d'entree et de l'exutoire de la ZH hydro			 
		list<zoneHydrographique> zhsTemp <- listeZonesHydrographiques where (each.shape.contour intersects (shape+5)); // de taille 1 min ou 2 max
		ask zhsTemp{
	 		// Exutoire
	 		if idExutoire = myself.idNoeudHydrographique{
			 	 exutoire <- myself;
			// Point dentree
	 		}else{
			 	 pointDentree <- myself;
		 	}			 		
		}
	}
	
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw circle(taillePointsMax) color: couleur;
	}
}
