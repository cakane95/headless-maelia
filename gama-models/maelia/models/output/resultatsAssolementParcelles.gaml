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
 *  resultatsAssolementParcelles
 *  Author: Maelia
 *  Description: 
 */

model resultatsAssolementParcelles

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "ecritureResultats.gaml"


global{
	action initialisationEcritureFichiersAssolementParcelles{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers assolement parcelles...';		
		
		create resultatsAssolementParcelles number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsAssolementParcelles parent: ecritureResultats{
	map<especeCultivee,int> mapNbTypeCultureSimuleZM <- map<especeCultivee,int>([]);  // culture::nb
	map<especeCultivee,int> mapNbTypeCultureReelZM <- map<especeCultivee,int>([]);  // {culture::nb}
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/assolementParcelles'+ nomDeLaSimulation + '.csv';
		let dataAnnuelle type: string value: '' + detailSimulation + '\nannee';
		ask (especeCultivee as list){ 
			set dataAnnuelle value: dataAnnuelle + ';' + idEspeceCultivee + '_REEL'+ ';' + idEspeceCultivee + '_SIMULE';
		}			
		do initialisationRotationReellesLues();			
		return dataAnnuelle;
	 }
	
	/*
	 * @Overwrite
	 */		 
	 string ecritureDebutAnnuelle{
	 	do miseAjourMapNbCulturesZM();
	 	return "";
	 }	
	 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{	
		//do comparaisonAssolementReelleVSsimuleParParcelle();
		//do comparaisonRotationReelleVSsimuleParParcelle();
		//do comparaisonRotationReelleVSsimuleZM();
				 		 			 		
		string data <- '' + (dateCour.annee);										
		ask (especeCultivee as list){ 
			set data value: data + ';' + int(myself.mapNbTypeCultureReelZM at self) ;
			set data value: data + ';' + int(myself.mapNbTypeCultureSimuleZM at self) ;
		}		
		return data;			 		
	 }	
	 

	action initialisationRotationReellesLues{
		// On met a jour la map globale
		ask listeParcellesUtiles{
			let mapTemp type: map value: ([0::2006, 1::2007, 2::2008, 3::2009]);
			mapRotationDonneesEntrees <- map([]); // annee::cultureReelle
			list<string> rotation <- rotationReelle  tokenize '_';
			int i <- 0;
			
			loop nomCulture over: rotation {
				especeCultivee espece <- first((especeCultivee as list) where (each.idEspeceCultivee = nomCulture));
				if espece != nil {						
					put espece at: (mapTemp at i) in: mapRotationDonneesEntrees;		
					i <- i + 1;					
				}
			}	
					
			// On complete la map de ratation reelle pour avoir une culture pour chaque annee
			if(!empty(mapRotationDonneesEntrees)){
				if(length(mapRotationDonneesEntrees.keys) = 1){
					put (mapRotationDonneesEntrees at 2006) at: 2007 in: mapRotationDonneesEntrees;
					put (mapRotationDonneesEntrees at 2006) at: 2008 in: mapRotationDonneesEntrees;
					put (mapRotationDonneesEntrees at 2006) at: 2009 in: mapRotationDonneesEntrees;
				}else if(length(mapRotationDonneesEntrees.keys) = 2){
					put (mapRotationDonneesEntrees at 2006) at: 2008 in: mapRotationDonneesEntrees;
					put (mapRotationDonneesEntrees at 2007) at: 2009 in: mapRotationDonneesEntrees;
				}else if(length(mapRotationDonneesEntrees.keys) = 3){
					put (mapRotationDonneesEntrees at 2006) at: 2009 in: mapRotationDonneesEntrees;
				}						
			}		
				
			// On met a jour la map globale
			loop annee over: mapRotationDonneesEntrees.keys{		
				especeCultivee cultureReelle <- mapRotationDonneesEntrees at annee;
				
				int nb <- 1 + int(myself.mapNbTypeCultureReelZM at cultureReelle);
				put nb at: cultureReelle in: myself.mapNbTypeCultureReelZM;													
			}				
		}			
	}
	
	action miseAjourMapNbCulturesZM{	
	 	ask listeParcellesUtiles{
 			// Mise a jour map du nombre de type de culture
			int nombreTemp <- myself.mapNbTypeCultureSimuleZM at getITKAnnee().especeCultiveeITK;				
			put (nombreTemp + 1) at: getITKAnnee().especeCultiveeITK in: myself.mapNbTypeCultureSimuleZM;		 			
	 	}			
	}
	

	/*
	 * *****************************************************************************************
	 * Publique
	 * Compare les cultures chaque annee (a la fin de l'annee)
	 */
	action comparaisonAssolementReelleVSsimuleParParcelle{		
		float pourcentageConcordenceAssolement <- 0.0;
		int nbParcellesAvecCulture <- 0;
		
		if(dateCour.annee >= 2006 and dateCour.annee <= 2009){
			ask listeParcellesUtiles{
				if(mapRotationSimulee at dateCour.annee != nil){
					set nbParcellesAvecCulture value: nbParcellesAvecCulture + 1;
					if(especeCultivee(mapRotationDonneesEntrees at dateCour.annee) = especeCultivee(mapRotationSimulee at dateCour.annee)){
						set pourcentageConcordenceAssolement value: pourcentageConcordenceAssolement + 1;
					}				
				}			
			}
			set pourcentageConcordenceAssolement value: pourcentageConcordenceAssolement / nbParcellesAvecCulture;	
			
			write '[PARCELLE/comparaisonAssolementReelleVSsimule] pourcentageConcordenceAssolement = ' + pourcentageConcordenceAssolement;			
		}			
	}	

	/*
	 * *****************************************************************************************
	 * Publique
	 * Compare les rotations en 2009 (a la fin de l'annee)
	 */
	action comparaisonRotationReelleVSsimuleParParcelle{		
		float pourcentageConcordenceRotation <- 0.0;
		int nbParcellesAvecCulture <- 0;
		
		if(dateCour.annee = 2009){
			ask listeParcellesUtiles{			
				if(mapRotationSimulee at dateCour.annee != nil){
					nbParcellesAvecCulture <- nbParcellesAvecCulture + 1;
				
					if(!empty(mapRotationDonneesEntrees)){
						let mapReelle type: map value: map([]);	// espece::nbDeCetteCulturePourLassolement		
						loop cultureReelle over: mapRotationDonneesEntrees.values{				
							int nb <- 1;
							if(mapReelle at cultureReelle != nil){
								nb <- nb + int(mapReelle at cultureReelle);
							}
							put nb at: cultureReelle in: mapReelle;					
						}
						let mapSimulee type: map value: map([]);	// espece::nbDeCetteCulturePourLassolement		
						loop cultureSimulee over: mapRotationSimulee.values{					
							int nb <- 1;
							if(mapSimulee at cultureSimulee != nil){
								nb <- nb + int(mapSimulee at cultureSimulee);
							}
							put nb at: cultureSimulee in: mapSimulee;					
						}			
						
						// Calcul correspondance entre le nombre des memes cultures	les 4 dernieres anness (2006-2009)
						float pourcetageParcelle <- 0.0;
						loop cultureReelle over: mapReelle.keys{	
							if(mapSimulee at cultureReelle != nil){
								pourcetageParcelle <- pourcetageParcelle + min([int(mapReelle at cultureReelle), int(mapSimulee at cultureReelle)]);
							}									
						}
						pourcetageParcelle <- (pourcetageParcelle / length(mapRotationDonneesEntrees.keys)); // /4						
						pourcentageConcordenceRotation <- pourcentageConcordenceRotation + pourcetageParcelle;
					}	
				}
			}
			pourcentageConcordenceRotation <- pourcentageConcordenceRotation / nbParcellesAvecCulture;	
			write '[PARCELLE/comparaisonAssolementReelleVSsimule] pourcentageConcordenceRotation = ' + pourcentageConcordenceRotation;
		}			
	}

	/*
	 * *****************************************************************************************
	 * Publique
	 * Compare les cultures chaque annee (a la fin de l'annee)
	 */
	action comparaisonRotationReelleVSsimuleZM{		
		float pourcentageConcordenceAssolementZM <- 0.0;
		int nbParcellesAvecCulture <- sum(mapNbTypeCultureSimuleZM.values); 
		
		if(dateCour.annee >= 2006 and dateCour.annee <= 2009){
			// Calcul correspondance entre le nombre des memes cultures	les 4 dernieres anness (2006-2009)
			loop cultureReelle over: mapNbTypeCultureReelZM.keys{	
				if(int(mapNbTypeCultureSimuleZM at especeCultivee(cultureReelle)) != nil){
					set pourcentageConcordenceAssolementZM value: pourcentageConcordenceAssolementZM + min([int(mapNbTypeCultureReelZM at cultureReelle), int(mapNbTypeCultureSimuleZM at especeCultivee(cultureReelle))]);
				}									
			}						
			set pourcentageConcordenceAssolementZM value: pourcentageConcordenceAssolementZM / nbParcellesAvecCulture;
			write '[PARCELLE/comparaisonRotationReelleVSsimuleZM] comparaisonRotationReelleVSsimuleZM = ' + pourcentageConcordenceAssolementZM;
		}			
	}		

	/*
	 * @Private
	 */		 
	 action miseAzero{		
	 	
	 }		 			 
}
