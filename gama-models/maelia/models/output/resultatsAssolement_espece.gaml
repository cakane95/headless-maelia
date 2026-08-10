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

model resultatsAssolement_espece

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
	action initialisationEcritureFichiersAssolement_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers assolement agriculteurs...';		
		
		create resultatsAssolement_espece number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsAssolement_espece parent: ecritureResultats{
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/assolement_espece'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detailSimulation + '\nannee';
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			dataAnnuelle <- dataAnnuelle + ';' + espece.idEspeceCultivee + '_NB'+ ';' + espece.idEspeceCultivee + '_SURFACE(ha)';
		}
		dataAnnuelle <- dataAnnuelle + ';non_seme_nb;non_seme_surface' +
						 ';recolte_forcee_nb;recolte_forcee_surface'  ;
	    loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			dataAnnuelle <- dataAnnuelle + ';recolte_forcee_' + espece.idEspeceCultivee + '_NB'+ ';recolte_forcee_' + espece.idEspeceCultivee + '_SURFACE(ha)';
		}
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			dataAnnuelle <- dataAnnuelle + ';non_seme_' + espece.idEspeceCultivee + '_NB'+ ';non_seme_' + espece.idEspeceCultivee + '_SURFACE(ha)';
		}
//			loop parc over: listeParcellesUtiles{ // Toujours utile ?
//				parc.itkAnnePrec <- parc.getITKAnnee();
//		 	}
		return dataAnnuelle;
	 }

 	
	/*
	 * @Overwrite
	 *  JV 20022020: modified to fix bug #0002487
	 */		 
	 string ecritureFinAnnuelle{	 	
	 	string data <- '' + (dateCour.annee);	 					
	 	int nbParcellesNonSemeesTotal <- 0;
	 	float surfaceParcellesNonSemeesTotal <- 0.0; // [ha]
	 	int nbParcellesRecolteForceeTotal <- 0;
	 	float surfaceParcellesRecolteForceeTotal <- 0.0; // [ha]
	 	map<string,int> mapEspeceNbParcelleNonSemees <- map<string,int>([]);
	 	map<string,float> mapEspeceSurfParcelleNonSemees <- map<string,float>([]); // [ha]
	 	map<string,int> mapEspeceNbParcelleRecolteForcee <- map<string,int>([]);
	 	map<string,float> mapEspeceSurfParcelleRecolteForcee <- map<string,float>([]); // [ha]	 	
	 	
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ // for each species 
			int nbParcellesEspece <- 0;
			float surfaceParcellesEspece <- 0.0; // [ha]	
			mapEspeceNbParcelleNonSemees[espece.idEspeceCultivee] <- 0;
			mapEspeceSurfParcelleNonSemees[espece.idEspeceCultivee] <- 0.0;
			mapEspeceNbParcelleRecolteForcee[espece.idEspeceCultivee] <- 0;
			mapEspeceSurfParcelleRecolteForcee[espece.idEspeceCultivee] <- 0.0;
			
			loop agri over: listeAgriculteurs{ // for each farmer
				ask (agri.listMemoire) where (each.itkAssocie.especeCultiveeITK = espece){ // get memory object related to the current species
					nbParcellesEspece <- nbParcellesEspece + getNbParcellesAnneeEnCours();
					surfaceParcellesEspece <- surfaceParcellesEspece + getSurfaceAnneeEnCours()/nombreMeterCarreDansUnHectare;
					if(nbParcellesNonSemees[dateCour.annee]!=nil){ // fields not sown
						mapEspeceNbParcelleNonSemees[espece.idEspeceCultivee] <- mapEspeceNbParcelleNonSemees[espece.idEspeceCultivee] + nbParcellesNonSemees[dateCour.annee];
						mapEspeceSurfParcelleNonSemees[espece.idEspeceCultivee] <- mapEspeceSurfParcelleNonSemees[espece.idEspeceCultivee] + surfParcellesNonSemees[dateCour.annee]/nombreMeterCarreDansUnHectare;
					}
					if(nbParcellesRecolteForcee[dateCour.annee]!=nil){ // fields with forced havest
						mapEspeceNbParcelleRecolteForcee[espece.idEspeceCultivee] <- mapEspeceNbParcelleRecolteForcee[espece.idEspeceCultivee] +  nbParcellesRecolteForcee[dateCour.annee];
						mapEspeceSurfParcelleRecolteForcee[espece.idEspeceCultivee] <- mapEspeceSurfParcelleRecolteForcee[espece.idEspeceCultivee] + surfParcellesRecolteForcee[dateCour.annee]/nombreMeterCarreDansUnHectare;
					}
					
				}// memory object					
			}// for each farmer
			
			data <- data + ';' + nbParcellesEspece + ';' + surfaceParcellesEspece with_precision 2;
			
			// update total number/surface of not sown and forced harvest
			nbParcellesNonSemeesTotal <- nbParcellesNonSemeesTotal + mapEspeceNbParcelleNonSemees[espece.idEspeceCultivee];
			surfaceParcellesNonSemeesTotal <- surfaceParcellesNonSemeesTotal + mapEspeceSurfParcelleNonSemees[espece.idEspeceCultivee];						
			nbParcellesRecolteForceeTotal <- nbParcellesRecolteForceeTotal + mapEspeceNbParcelleRecolteForcee[espece.idEspeceCultivee];
			surfaceParcellesRecolteForceeTotal <- surfaceParcellesRecolteForceeTotal + mapEspeceSurfParcelleRecolteForcee[espece.idEspeceCultivee];					
				
		}// for each species
		
		// append data about total not sown and forced harvest
		data <- data + ';' + nbParcellesNonSemeesTotal + ';' +  surfaceParcellesNonSemeesTotal with_precision 2 + ';' +  nbParcellesRecolteForceeTotal + ';' + surfaceParcellesRecolteForceeTotal with_precision 2;
		
		// append data about not sown and forced harvest by species
	 	loop espece over: listeEspecesCultiveesParOrdreSaisie{
			data <- data + ';' + mapEspeceNbParcelleRecolteForcee[espece.idEspeceCultivee] + ';' + mapEspeceSurfParcelleRecolteForcee[espece.idEspeceCultivee] with_precision 2;		
		}
	 	loop espece over: listeEspecesCultiveesParOrdreSaisie{
			data <- data + ';' + mapEspeceNbParcelleNonSemees[espece.idEspeceCultivee] + ';' + mapEspeceSurfParcelleNonSemees[espece.idEspeceCultivee] with_precision 2;		
		}
		
		return data;
	}

	 string ecritureFinAnnuelle_old{	 	
	 	string data <- '' + (dateCour.annee);										
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			int NB<- 0;
			float Surface<- 0.0;
			loop agri over: listeAgriculteurs{
				write "legnth(agri.listMemoire)=" + length(agri.listMemoire);
				ask (agri.listMemoire) where (each.itkAssocie.especeCultiveeITK = espece){
					NB <- NB + getNbParcellesAnneeEnCours();
					Surface <- Surface + getSurfaceAnneeEnCours()/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2;
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
	 	data <- data + ';' + NbNonSeme + ';' + surfaceNonSeme with_precision 2 +
	 			';' + NbNonRecolte + ';' + surfaceNonRecolte with_precision 2 ;
	 			
	 	loop espece over: listeEspecesCultiveesParOrdreSaisie{
			int NB<- 0;
			float Surface<- 0.0;
			loop parc over: listeParcellesUtiles{			
				if ( (parc.recolteForcee) and (parc.itkAnnePrec.especeCultiveeITK = espece))
				{
					NB <- NB + 1;
					Surface <- Surface + parc.surface/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2;
		}
		
		loop espece over: listeEspecesCultiveesParOrdreSaisie{
			int NB<- 0;
			float Surface<- 0.0;
			loop parc over: listeParcellesUtiles{			
				if ((parc.semis_prevu_non_realise) and (parc.getITKAnnee().especeCultiveeITK = espece))
				{
					NB <- NB + 1;
					Surface <- Surface + parc.surface/nombreMeterCarreDansUnHectare;
				}
			}
			data <- data + ';' + NB + ';' + Surface with_precision 2;
		}
	 	
	 	
		return data;
	 }			 
	 			 
}

