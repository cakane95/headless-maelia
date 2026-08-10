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
 *  pointDeReference
 *  Author: Maroussia Vavasseur
 *  Description: Entite qui represente un point ou est mesure le debit sur un cours d'eau. Il existe 3 types de point de reference :
 * 				 - Station hydro : station georeferencee ou sont mesures les debits
 * 				 - Point Nodal (ou DOE) : point de controle situe sur une station hydro
 * 				 - Point rocca : pour les zone non realimentee principalement, les points rocca reprentent les lieux (non references) surveilles par des agents de l'eau de maniere informelle.
 */

model pointDeReference

import "../modeleHydrographique/zoneHydrographique.gaml"

global{ 	
	string pointRefShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/pointsDeReference/pointsDeReference.shp';

	list<pointDeReference> listePointsRef <- [];
	int nbJoursMoyenPourCalculDebit <- 3 const: true;
	map<int,string> mapBesoinAgricole <- [0::'pas', 1::'un peu', 2::'beaucoup'] const: true; // niveau::estimationBesoinAgricole
	map<int,string> mapPalierDebit <- [0::'q>=doe', 1::'qa<q<doe', 2::'qar<q<=qa', 3::'dcr<q<=qar', 4::'q<=dcr'] const: true; 
			
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action creationPointsDeReference{		

		if !file_exists(pointRefShape) {do raiseWarning("fichier inexistant: " + pointRefShape);}
		//else if !is_shape(pointRefShape) {do raiseError("le fichier " + pointRefShape + " n'est pas un fichier shape");}
	
		if(file_exists(pointRefShape)){ // JV 250920
			create pointDeReference from: file(pointRefShape) with: [	idPointDeReference::string(read ( ID_STH )),
																doe::float(read(DOE)),
																dcr::float(read(DCR))]{			
				zoneHydrographiqueAssociee <- mapZH at string(shape get( ID_ZH ));
				if(zoneHydrographiqueAssociee = nil){
					ask self{
						do die();
					}	
				}else{
					name <- idPointDeReference;
					if(string(shape get( IS_NODAL )) = "O"){
						isNodal <- true;
						isRealimente <- true;
						couleurTypePoint <- couleurBleuClaire;
					}
					do initialisationPointDeReference();	
					listePointsRef << self;				
				}			
			}
		}

		// TODO : SUPPRIMER ET METTRE EN DATA ENTREE  : Creation dun point a lexu
		if((nomDecoupageZonePourLectureFichiers = DecoupageZoneMaelia)){					
			create pointDeReference number: 1{
				zoneHydrographiqueAssociee <- mapZH at "O098";
				idPointDeReference <- "O1900010";
				name <- idPointDeReference;
				doe <- 50.0;
				dcr <- 27.0;
	
				couleurTypePoint <- couleurVertClaire;
				do initialisationPointDeReference();	
				listePointsRef << self;													
			}
		}					
	}	
}

species pointDeReference{
	string idPointDeReference <- "";
	int taillePointRef <- 500;
	rgb couleurTypePoint <- couleurVertClaire;
	rgb couleurPalierDebit <- rgb('white');
	bool isNodal <- false; // isDOE
	float doe <- 0.0; // [m3/s]  debitObjetcifEtiage
	float qa <- 0.0; // [m3/s]  debit d'alerte
	float qi <- 0.0; // [m3/s]  debit intermediaire
	float qar <- 0.0; // [m3/s]  debit d'alerte renforce
	float dcr <- 0.0; // [m/3s]  debit de crise
	float qmj3 <- 0.0; // [m3/s]  debit moyen sur 3 jours
	float debitJournalier <- 0.0; //  [m3/s] 
	float seuilDeGestion <- 0.0;
	map<int,float> mapDebit <- map<int,float>([]); // indiceJour::debitSimule  -> utile uniquement pour calculer le debit moyen des 3 derniers jours
	map<int,float> mapDebitMaxParNiveauDeRestriction <- map<int,float>([]);
	float tendance <- 0.0; // moyenne sur les 7 derniers jours de la pente de la variation de debit dun jour sur lautre
	zoneHydrographique zoneHydrographiqueAssociee <- nil; 
	bool isRealimente <- true;

	map<int,float> mapDebitReel <- map<int,float>([]); // idDate::debitReel (lu dans fichier)
		
	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		do miseAJourDebit();
		do colorationEnFonctionDebitMoyen();
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action initialisationPointDeReference{
		// Changement unite : doe/dcr lu en m3/s
		qa <- doe * 0.8;	
		qar <- dcr + (1/3)*(doe - dcr);	
		qi <- qar + (qa - qar) / 2;
		
		// On associe a chaque niveau de restriction la valeur du debit max a partir duquel on est dans ce niveau de restriction 
		put doe at: 1 in: mapDebitMaxParNiveauDeRestriction;
		put qa at: 2 in: mapDebitMaxParNiveauDeRestriction;
		put qar at: 3 in: mapDebitMaxParNiveauDeRestriction;
		put dcr at: 4 in: mapDebitMaxParNiveauDeRestriction;								
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action miseAJourDebit{	
		qmj3 <- 0.0;			
		if(zoneHydrographiqueAssociee != nil){
			// debit courant
			ask zoneHydrographiqueAssociee{
				myself.debitJournalier <- debitCourant;
				put debitCourant at: dateCour.indiceDate in: myself.mapDebit;
			}
			
			// debit moyen les 3 derniers jours
			loop i from: dateCour.indiceDate - (nbJoursMoyenPourCalculDebit-1) to: dateCour.indiceDate{
				qmj3 <- qmj3 + (mapDebit at i);
			} 
			qmj3 <- qmj3 / nbJoursMoyenPourCalculDebit;	
		}
	}		

	/*
	 * *****************************************************************************************
	 */			
	bool surveillancePointDeReference{ // JV 260822 modif mineure, cf Mantis #0002937

		bool isEtiagePtRef <- false;							

		// détermination du seuil à considérer
		seuilDeGestion <- doe;
		if !lePrefet.isPeriodeEtiageCommencee() {
			// si on est au dessous du QA, faire un petit lache pour tenir le QA jusqu'au 15 mai...
			seuilDeGestion <- qa;
		}
		
		// si QMJ3 sous le seuil à considérer
		if qmj3 < seuilDeGestion {
			isEtiagePtRef <- true;
			if verboseMode {write "BARRAGES surveillance ptRef " + self + " " + idPointDeReference + " QMJ3=" + qmj3 + " m3/s seuilDeGestion=" + seuilDeGestion + " m3/s -> SOUS LE SEUIL";}				
		}					
		
		return isEtiagePtRef;
	}
		
	
	/*
	 * *****************************************************************************************
	 */
	action colorationEnFonctionDebitMoyen{
		if(qmj3 > doe){
			couleurPalierDebit <- rgb('white');
		}else if(qi < qmj3 and qmj3 <= doe){
			couleurPalierDebit <- rgb(paletteCouleursDebitsCrises at 0);			
		}else if(qa < qmj3 and qmj3 <= qi){
			couleurPalierDebit <- rgb(paletteCouleursDebitsCrises at 1);			
		}else if(qar < qmj3 and qmj3 <= qa){
			couleurPalierDebit <- rgb(paletteCouleursDebitsCrises at 2);		
		}else if(dcr < qmj3 and qmj3 <= qar){
			couleurPalierDebit <- rgb(paletteCouleursDebitsCrises at 3);		
		}else{
			couleurPalierDebit <- rgb(paletteCouleursDebitsCrises at 4);
		}
	}		
	
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw circle(taillePointRef) color: couleurTypePoint;
	}	
	aspect palierDebitAspect{
		draw circle(taillePointRef) color: couleurPalierDebit;
	}									
			
	/*
	 * *****************************************************************************************
	 */
	string toString{	
		return "" + self + name + " - doe = " + doe + " - dcr = " + dcr + " - qmj3 = "+ qmj3;						
	}			
}

