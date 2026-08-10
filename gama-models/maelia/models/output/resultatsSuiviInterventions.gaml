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

model resultatsSuiviInterventions

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Cultures/culture.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersSuiviInterventions{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers de suivi des interventions techniques ...';		
		
		create resultatsSuiviInterventions number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


	species resultatsSuiviInterventions parent: ecritureResultats{
		map<especeCultivee,map<int,int>> mapNbSemisEspeceParDate <- map([]); // espece::map(date,nb)   
		
		/*
		 * @Overwrite
		 */
		
			
		 string initialisationFinAnnuel{	
			nomFichierFinAnnuel <- 'log/suiviSemis.csv';
			string dataDerniereProd <- '' + detailSimulation + '\ncycle;annee';
			ask (especeCultivee){ 
				set dataDerniereProd value: dataDerniereProd +  '\ndate;'+ idEspeceCultivee + '_NB'+ ';';
			}
			return dataDerniereProd;
		 }

	 
		/*
		 * @Overwrite
		 */		 
		 string ecritureFinAnnuelle{		 	
		 	do miseAjourMapNombreInterventionsEspece;
		 	int jourJulien value: dateCour.nbJoursEcoulesDansAnnee;
			//int jourJulien value: calculNbJourEcouleDansAnnee(jourEntree:dateCour.jour ,moisEntree:dateCour.mois);
			string data <- '' + (jourJulien);										
			ask (especeCultivee){ 
				map tempmap <- (myself.mapNbSemisEspeceParDate at self);
				set data value: data + ';' + int(tempmap at jourJulien);
			}		
			return data;
		 }			 


		/*
		 * Fin annuel
		 *Pour le semis
		 * on regarde indexDateDeCreation qui memorise la date de creation de l espece (cree lors du semis)
		 */
    	action miseAjourMapNombreInterventionsEspece{	
    		ask(listeAgriculteurs accumulate each.listeParcelles){
    			if(getITKAnnee() != nil){						
					// Mise a jour map du nombre d interventions semis
					map<int,int> tempSemis <- (myself.mapNbSemisEspeceParDate) at  getITKAnnee().especeCultiveeITK;
					int nombreTemp <- tempSemis at cultureParcelle.indexDateDeCreation;
					put (nombreTemp + 1) at: self.cultureParcelle.indexDateDeCreation in: tempSemis;	
					put tempSemis at: first(especeCultivee where (each.idEspeceCultivee = getITKAnnee().especeCultiveeITK.idEspeceCultivee)) 
						in: myself.mapNbSemisEspeceParDate;	
    			}						    			
    		}
     	}   

     	/*
		 *  *****************************************************************************************
		 * Fin annuel
		 * Si je veux avoir les resultats sur un agri, il suffit de faire un "ask" sur lagri souhaite
		 */
		/*action calculRendementMoyenAnneePassee{	
			ask(listeAgriculteurs accumulate each.listeParcelles){	
				especeCultivee espece <- (mapRotationSimulee at dateCour.annee);			
				if(espece != nil){
					// Remplissage de la liste des rendements par espece						
					list<float> listRendement <- list(myself.mapRendementParEspeceZM at espece);
					add (rendementParJoursRecoltes at dateCour.idDate) to: listRendement;				
					put listRendement at: espece in: myself.mapRendementParEspeceZM;						   												
				}
			}
			
			if(!empty(mapRendementParEspeceZM)){	
				let rendementMoyenTemp type: float value: 0.0;
				loop especeCourante over: mapRendementParEspeceZM.keys{	
					loop rendementCourant over: list(mapRendementParEspeceZM at especeCourante){
						set rendementMoyenTemp value: rendementMoyenTemp + float(rendementCourant);
					}					
					set rendementMoyenTemp value: rendementMoyenTemp / length(list(mapRendementParEspeceZM at especeCourante));
					
					put rendementMoyenTemp at: especeCourante in: mapRendementMoyenZM;					
				}							
			}	
		} */ 	


		/*
		 * @Private
		 */		 
		 action miseAzero{		
		 	mapNbSemisEspeceParDate <- map([]);	   
		 }
	}		 			 


