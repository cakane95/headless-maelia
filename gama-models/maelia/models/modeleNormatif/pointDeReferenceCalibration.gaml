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
 *  pointDeReferenceCalibration
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model pointDeReferenceCalibration
 
import "pointDeReference.gaml"
 
global{
	string cheminDebitReelStationHydrographique <-  '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/pointsDeReference/matriceDebitReelPointDOE.csv';
	
	/* 
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionPointDeReferenceCalibration{	
		if(file_exists(cheminDebitReelStationHydrographique)){
			do initialisationMatriceDebitStationHydrographiqueReellePourCalibration();	
		}					
	}
			 
	 /*
	  * *****************************************************************************************
	  * Private
	  * CALIBRAGE
	  */
	  action initialisationMatriceDebitStationHydrographiqueReellePourCalibration{
		matrix initDataDebitReelStationHydrographique <- matrix((csv_file(cheminDebitReelStationHydrographique,";",false)));
		// let initDataDebitReelStationHydrographique type: matrix value: matrix((file(cheminDebitReelStationHydrographique)));
		int nbLignes <- length(initDataDebitReelStationHydrographique column_at 0);
		int nbColones <- length(initDataDebitReelStationHydrographique row_at 0);			
		list ligneDate <- (initDataDebitReelStationHydrographique row_at 0);	
						
		loop indiceLigne from: 0 to: ( nbLignes - 1 ) {
			list ligneI <- (initDataDebitReelStationHydrographique row_at indiceLigne);
			string idLigneCourante <- string(ligneI at 0);		
			
			pointDeReference pointDeRef <- first(pointDeReference where (each.idPointDeReference = idLigneCourante));
			
			if(pointDeRef != nil){
				loop indiceColone from: 1 to: ( nbColones - 1 ) {					
					/*
					 * Parsing date
					 */
					list dateCouranteTemporaire <- string(ligneDate at indiceColone) tokenize '/,';					
					int jourCourant <- int(dateCouranteTemporaire at 0);
					int moisCourant <- int(dateCouranteTemporaire at 1);
					int anneeCourant <- int('20' + dateCouranteTemporaire at 2);
					if(int(dateCouranteTemporaire at 2) > 100){
						anneeCourant <- int(dateCouranteTemporaire at 2) ;
					}
					int indiceDateCourante <- 0;
					ask dateCour{
						indiceDateCourante <- convertirDateEnIndice(jourAConvertir:jourCourant, moisAConvertir:moisCourant, anneeAConvertir:anneeCourant);						
					}
					
					float conversionUniteDebit <- 0.0;
					// TODO : supprimer et mettre bonne unite donnees entree !!
					if(pointDeRef.idPointDeReference = "O1900010"){
						conversionUniteDebit <- (float(ligneI at indiceColone));	
					}else{
						conversionUniteDebit <-  (float(ligneI at indiceColone)) / nbLDansM3;	// [L/s] * NbLitreDansM3 = [m3]/s	
					}

					put conversionUniteDebit at: indiceDateCourante in: pointDeRef.mapDebitReel;
				}				
			}
	  	}	
	}
}
