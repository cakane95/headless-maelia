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
 *  pointDeReferenceNonRealimente
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model pointDeReferenceNonRealimente

import "../modeleCommun/idVariablesShapfile.gaml"
import "../modeleCommun/palettesCouleures.gaml" 
import "../modeleHydrographique/zoneHydrographique.gaml"

global{ 	
	/*
	 * Appellee a la creation des ZA
	 */
	pointDeReferenceNonRealimente creationPointDeReferenceNonRealimente(geometry zaGeoEntree){		
		pointDeReferenceNonRealimente res <- nil;
		create pointDeReferenceNonRealimente {
			// Association ZHs
			list<zoneHydrographique> listeZonesHydrographiquesTemp <- listeZonesHydrographiques;
			if(executerModeleAgricole){
				listeZonesHydrographiquesTemp <- listeZonesHydrographiques where (!empty(each.listeIlotsAssocies));
			}
			ask(listeZonesHydrographiquesTemp){
				if(location intersects zaGeoEntree){
					myself.zhsControlees << self;
				}
			}			
			doe <- 0.01; 
			dcr <- 0.003; 
			isRealimente <- false;
			do initialisationPointDeReference();					
			res <- self;
			listePointsRef << self;			
		}
		return res;					
	}	
}


/*
 * Remarques Donnees non pertinantes:
 * qmj3 <- dans le cas des non realimentes, le qmj3 est en fait le debit courant car pas pertinants de prendre le debit des 3 derniers jours quand on regarde une liste de zh
 * zoneHydrographiqueAssociee 
 * mapDebitReel 	 
 */
species pointDeReferenceNonRealimente parent: pointDeReference{
	list<zoneHydrographique> zhsControlees <- [];
	
	/*
	 * *****************************************************************************************
	 * Prend le debit le plus faible de lensemble des ZH associees
	 */	
	action miseAJourDebit{	
		qmj3 <- 0.0;	
//			float debitMin <- 0.0;
//			ask(zhsControlees){
//				if(debitMin = 0.0 or debitMin > debitCourant){
//					debitMin <- debitCourant;
//				}
//			}
//			debitJournalier <- debitMin;
		if(length(zhsControlees) > 0){
			debitJournalier <-  median(zhsControlees collect (each.debitCourant));
		}else{
			if(!executerModeleSurUneZH){
				write "probleme de definition du territoire, au moins une ZA n'est pas " +
				"rattache a des BVe du territoires";
			}
		}
			
		
//			qmj3 <- debitMin;	
		qmj3 <- debitJournalier;
	}		
}

