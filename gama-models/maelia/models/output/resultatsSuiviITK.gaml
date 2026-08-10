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
 *  resultatsSuiviITK
 *  Author: R. Lardy
 *  Description: 
 */

model resultatsSuiviITK

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersSuiviITK{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suivi OT...';		
		
		loop idOT over: listOTASuivreEnSortie{

			create resultatsSuiviITK number: 1 {
				sonidOT <- idOT;
				do initialisation();
				add self to: listesFichiersAcreer;
			}

		}
	}			
}


species resultatsSuiviITK parent: ecritureResultats{
	string sonidOT <- "";	

	/*
	 * @Overwrite
	 */
	string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviITK_'+sonidOT+ nomDeLaSimulation + '.csv'; //nom de l operation technique
		string dataFinAnnee <- 'annee;itk;espece|materiel;type';
		loop j from: 1 to: 366 {
			dataFinAnnee <- dataFinAnnee + ";"+ j;		
		}
		return dataFinAnnee;	
	}

	 /*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{
		string data <-  "";			
	 	bool premiereEcritureDeLAnnee <- true;
	 	
		loop it over: listeITKs {
			map<int, int> nbParcellesParJour <- map<int, int>([]);
			map<int, float> SurfacesParJour <- map<int, float>([]);
			ask listeParcellesUtiles{
				map<int, itk> OPParDate <- memoireOTsurParcelle at myself.sonidOT;
				loop d over: OPParDate.keys{
					if((OPParDate at d) = it){
						put (1 + (nbParcellesParJour at d)) at: d in: nbParcellesParJour;
						if(myself.sonidOT = IRRIGATION){
							put ((self.memoireSurfaceIrriguee at d) + (SurfacesParJour at d)) at: d in: SurfacesParJour;
						}else{
							put (self.surface + (SurfacesParJour at d)) at: d in: SurfacesParJour;	
						}
					}	
				}
			}
			if(length(nbParcellesParJour.keys) > 0){ // si on a des données à écrire
				if(premiereEcritureDeLAnnee){
					premiereEcritureDeLAnnee <- false;
				}else{	
					data <- data + '\n';
				}
				string nomEspeceEtMaterielIrrigation <- it.especeCultiveeITK.idEspeceCultivee;
				if(it.matITK = nil){
					nomEspeceEtMaterielIrrigation <- nomEspeceEtMaterielIrrigation +"|NA";
				}else{
					nomEspeceEtMaterielIrrigation <- nomEspeceEtMaterielIrrigation + "|" + it.matITK.idMateriel ;
				}
				
				data <- data + dateCour.annee + ";" + it.nomPourAffichage + ";"  + nomEspeceEtMaterielIrrigation+ ";nbParcelles";
				loop  j from: 1 to: 366 {
					if((nbParcellesParJour at j) != nil){
						data <- data + ";" + nbParcellesParJour at j;
					}else{
						data <- data + ";" ;
					}
					
				}
				data <- data +  '\n'+ dateCour.annee + ";" + it.nomPourAffichage + ";"  + nomEspeceEtMaterielIrrigation + ";Surfaces(ha)";
				loop  j from: 1 to: 366 {
					if((SurfacesParJour at j) != nil){
						data <- data + ";" + ((SurfacesParJour  at j)/nombreMeterCarreDansUnHectare) with_precision 1;
					}else{
						data <- data + ";" ;
					}
				}
				
			}
		}
	 	return data;		 			 	
	 }

}

