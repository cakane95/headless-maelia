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
 *  CLC
 *  Author: Maroussia Vavasseur
 *  Description: CLC, ou Corinne Land Cover, est une base de donnees europeenne d'occupation biophysique des sols. Elle s'organise autour de 5 grandes classes (elles memes subdivisees en n classes):
 * 				 Territoires artificialises, Territoires agricoles, Forets et milieux semi-naturels,  Zones humides, Surfaces en eau
 * 				 Pour Maelia, les classes du CLC sont remaniees pour mieux coller a notre proplematique.
 * 			     On ne peut pas rassembler tous les polygones du clc de la meme classe en un car alors la disparition des ilots serait fausse. Si on precalcul la disparition des ilots : ok !!
 */

model clc

import "contourZoneMaelia.gaml"

global{
	string clcAllShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/clc/clcParZH.shp';  // CLC2006    clc2006AgregerParClasses    clc2006AgregerParClassesParZH
	string cheminCouleurClc <- cheminRacineMaelia + 'images/CLC_RGB.csv';

	action constructionCLC{
		if !file_exists(clcAllShape) 	{do raiseError("fichier inexistant: " + clcAllShape);}
		//if !is_shape(clcAllShape)		{do raiseError("le fichier " + clcAllShape + " n'est pas un fichier shape valide");}
        do constructionCouvert(clc, clcAllShape, true);                        
	}
		
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionCouvert(species<clc> typeCouvert, string cheminShp, bool isCLCclassique){
		// arg typeCouvert type: species default: clc;
		// arg cheminShp type: string default: "";
		// arg isCLCclassique type: bool default: true;
		
		create typeCouvert from: file(cheminShp) with: [ idClc::string(read( ID_CLC )), idClasse::int(read( INDICE_CLC )), typeClasse::string(read( TYPE_CLC ))]{
			zoneHydrographiqueAssocie <- mapZH at string(shape get(ID_ZH));		
			
			// Suppression des polygones nappartenant pas a la zone detude
			if(zoneHydrographiqueAssocie = nil){
				ask self{
					do die;	
				}						
			}else{	
				if(isCLCclassique){
					ask (zoneHydrographiqueAssocie){					
						add myself to: landCoverAssocie;
					}					
				}					

				name <- idClc;			
				do initialisationClc();			
			} 
		}			
	}
}

species clc{
	string idClc <- "";
	zoneHydrographique zoneHydrographiqueAssocie <- nil;
	bool isRemplissage <- true;
	int idClasse <- -1;
	string typeClasse <- "";
// ----------------------------------------- VARIABLES SWAT -----------------------------------------		
	float lai <- 1.0; // LAI
	float curveNumber2 <- 0.0; // CN2

	/*
	 * *****************************************************************************************
	 */
	action initialisationClc{	
		lai <- LAI_GRASSLAND;
		if typeClasse in [BATI, SURFACE_EN_EAU] { // JV 230822 ajout SURFACE_EN_EAU cf Mantis #0002933
			lai <- 0.0;
		}					
		if typeClasse = FORET {
			lai <- LAI_FORET;
		}
		curveNumber2 <- CN at typeClasse;
		if(curveNumber2 = 0.0){ //Surface en eau
			curveNumber2 <- curveNumberGlobal;
		}
	}

	/*
	 * *****************************************************************************************
	 */
	rgb getCouleurClassesPrincipalesClc{
		if((mapCouleurLandCoverParIdClasse at idClasse) != nil){
			return (mapCouleurLandCoverParIdClasse at idClasse);
		}else{
			return rgb('white');	
		}			
	}
	rgb getCouleurClassesForteEtBati{
		if(typeClasse = BATI){
			return rgb([204,0,0]);
		}else if(typeClasse = FORET){
			return rgb([51,204,51]);
		}else{
			return rgb('white');	
		}			
	}
	bool getIsAffichage{
		if(typeClasse = BATI or typeClasse = FORET){
			return true;
		}else{
			return false;
		}			
	}
	
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw shape color: getCouleurClassesPrincipalesClc() border: getCouleurClassesPrincipalesClc();
	}
	aspect foretEtBatiAspect{
		if(getIsAffichage()){
			draw shape color: getCouleurClassesForteEtBati() border: getCouleurClassesForteEtBati();
		}			
	}

	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string chaine <- "******* " + name + " *******"; 
		chaine <- chaine + ' \t/idClasse  : ' + idClasse;
		chaine <- chaine + ' \t/typeClasse  : ' + typeClasse;
 		return chaine;
		}
}
