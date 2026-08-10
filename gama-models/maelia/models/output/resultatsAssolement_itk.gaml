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
 *  resultatsAssolementAgri
 *  Author: Maelia
 *  Description: 
 */

model resultatsAssolement_itk

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	action initialisationEcritureFichiersAssolement_itk{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers assolement agriculteurs...';		
		
		create resultatsAssolement_itk number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsAssolement_itk parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/assolement_itk'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detailSimulation + '\nannee';
		loop it over: (itk as list){ 
			dataAnnuelle <- dataAnnuelle + ';' + it.nomPourAffichage + '_NB'+ ';' + it.nomPourAffichage + '_SURFACE(ha)';
		}
		dataAnnuelle <- dataAnnuelle + ';non_seme_nb;non_seme_surface' +
						 ';recolte_forcee_nb;recolte_forcee_surface'  ;
	    loop it over: (itk as list){
	    	dataAnnuelle <- dataAnnuelle + ';recolte_forcee_' + it.nomPourAffichage + '_NB'+ ';recolte_forcee_' + it.nomPourAffichage + '_SURFACE(ha)';
	    }
	    loop it over: (itk as list){
	    	dataAnnuelle <- dataAnnuelle + ';non_seme_' + it.nomPourAffichage + '_NB'+ ';non_seme_' + it.nomPourAffichage + '_SURFACE(ha)';
	    }
		return dataAnnuelle;
	 }

 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{	 	
	 	string data <- '' + (dateCour.annee);										
		loop it over: (itk as list){
			int NB<- 0;
			float Surface<- 0.0;
			loop agri over: listeAgriculteurs{
				ask (agri.listMemoire) where (each.itkAssocie = it){
					NB <- NB + getNbParcellesAnneeEnCours();
					Surface <- Surface + getSurfaceAnneeEnCours()/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2 ;
		}
		int NbNonSeme<- 0;
		float surfaceNonSeme<- 0.0;
		int NbNonRecolte<- 0;
		float surfaceNonRecolte<- 0.0;

		loop parc over: listeParcellesUtiles{
			if (parc.semis_prevu_non_realise){
				NbNonSeme <- NbNonSeme +1;
				surfaceNonSeme <- surfaceNonSeme + parc.surface/nombreMeterCarreDansUnHectare;
			}
			if (parc.recolteForcee){
				NbNonRecolte <- NbNonRecolte +1;
				surfaceNonRecolte <- surfaceNonRecolte + parc.surface/nombreMeterCarreDansUnHectare;
			}
	 	}
	 	data <- data + ';' + NbNonSeme + ';' + surfaceNonSeme with_precision 2+
	 			';' + NbNonRecolte + ';' + surfaceNonRecolte with_precision 2 ;
	 			
	 	loop it over: (itk as list){
			int NB<- 0;
			float Surface<- 0.0;
			loop parc over: listeParcellesUtiles{			
				if ( (parc.recolteForcee) and (parc.itkAnnePrec=it))
				{
					NB <- NB + 1;
					Surface <- Surface + parc.surface/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2 ;
		}
		
		loop it over: (itk as list){
			int NB<- 0;
			float Surface<- 0.0;
			loop parc over: listeParcellesUtiles{			
				if ((parc.semis_prevu_non_realise) and (parc.getITKAnnee()=it))
				{
					NB <- NB + 1;
					Surface <- Surface + parc.surface/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2 ;
		}
	 	
	 	
		return data;
	 }			 
	 			 
}

