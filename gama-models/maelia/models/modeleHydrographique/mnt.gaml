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
 *  mnt
 *  Author: Maroussia Vavasseur
 *  Description: Le Modele Numerique de Terrain donne une indication sur l'altitude de la zone Maelia (a 50m ?).
 */

model mnt

import "zoneHydrographique.gaml"

global{

    int nb_rows <- 500;
    int nb_lines <- 500;
    file shape_file_river <- file('' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/mnt/majortribdskratie.shp');	
	file mntImageRaster <- file('' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/mnt/BGA_PNG.png');	 // DEM_VMD_rgb_100    BGA_PNG
//    file zh3Dshape <- file('../main/log/shpTest3D.shp');	
//    file zhs3Dshape <- file('../main/log/zoneMaeliaTest3DExport.shp');	
 

	string nomFichierRejet <- cheminRacineMaelia + 'models/main/log/zoneMaeliaTotale3D.shp';
    file zhTestShape <- file(nomFichierRejet);	

	
	init {		
		do constructionTimeStamp; 
 		do ecritureConsolePourDebug chaineAEcrire: 'DEBUT';
 		
		create zoneHydro from: file(zoneHydrographiqueShape) with: [idZoneHydrographique::string(read ( 'CODE_ZONE' )), idExutoire::string(read( 'ID_ND_EXUT' ))]{  // zh3Dshape    zoneHydrographiqueShape
			name <- idZoneHydrographique;
		}		

		matrix mat <-	mntImageRaster as_matrix {nb_rows, nb_lines};
		ask mnt as list {	
			color <- rgb(mat at {grid_x,grid_y}) ;
			if(color = rgb('black')){
				color <- rgb('white');
			}
			//write (color as list);
			z <- 255 - mean(list (color)) as float;
		}
		
		ask mnt as list {		
			list<mnt> cells_possibles <- (self neighbors_at 2) + self;
			loop i from: 0 to: length(shape.points) - 1{ 
				geometry geom <- square(1.0);
				geom <- geom translated_to (shape.points at i);
				list<mnt> myCells <-  cells_possibles where (each.shape intersects geom);
				z  <- mean (myCells collect (each.z));
			}
		}	
		
		int j <- 0;
		ask zoneHydro as list {	
			set j value: j+1;						
			loop i from: 0 to: length(shape.points) - 1{ 
				z <- (first((mnt as list) where (each.shape intersects (shape.points at i)))).z;
				
				write '   zoneHydro ' + j + ' = ' + self + '    i = ' + i  + '   z = ' + z;
			}		
		}

		// Export	
		save (zoneHydro) to: (nomFichierRejet) format: 'shp' attributes: [idZoneHydrographique:: "CODE_ZONE", idExutoire:: "ID_ND_EXUT"];	
		do ecritureConsolePourDebug chaineAEcrire: 'FIN';		
	}	
}

	grid mnt  width:nb_rows  height: nb_lines neighbors: 4 {
		float z; 
		list<mnt> voisins <- self neighbors_at 1;
	}



species zoneHydro{
	string idZoneHydrographique <- '';
	string idExutoire <- '';
	rgb couleurZH;
	float z; 
	
	aspect basic {
		set couleurZH value: rgb([rnd(255),rnd(255),rnd(255)]);
		draw shape color: couleurZH border: couleurZH; 
	}		
}
	
	
//	species mnt{
//		rgb couleurMnt  <- rgb('white');
//
//		/*
//		 * *****************************************************************************************
//		 */
//		action initialisationMnt{
//		}
//
//		/*
//		 * *****************************************************************************************
//		 */
//		action comportementJournalier{
//		}
//
//		/*
//		 * *****************************************************************************************
//		 */
//		action colorationMnt{
//		}
//		
//		/*
//		 * *****************************************************************************************
//		 */
//		aspect basic{
//			draw geometry color: couleurMnt;
//		}
//
//    	/*
//		 * *****************************************************************************************
//		 * Debug
//		 */
//		action toString{
//			do write message: "******* " + name + " *******"; 
//    	}
//	}


/*
experiment experiment_MNT  type: gui {
	output {
		display city_display  type: opengl {
			species zoneHydro aspect: basic; // refresh:true;
			image name: 'Background' file: mntImageRaster.path;
		}
	}
}
*/