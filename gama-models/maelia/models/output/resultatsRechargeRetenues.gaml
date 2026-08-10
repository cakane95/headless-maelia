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
 *  resultatsPrelevements
 *  Author: Maelia
 *  Description: 
 */

model resultatsPrelevements

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/retenueCollinaire.gaml"
import "../modeleHydrographique/ressourceEnEau.gaml"

global{
	action initialisationEcritureFichiersRechargeRetenues{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers RechargeRetenues...';		
		
		create resultatsRechargeRetenues number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsRechargeRetenues parent: ecritureResultats{
	map<retenueCollinaire,float> mapRechargeEffective<- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,float> mapRemplissageDebutAnnee <- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,float> mapVolumePreleve <- map<retenueCollinaire,float>([]);
	map<retenueCollinaire,int> mapNbJoursSousCulot <- map<retenueCollinaire,int>([]);
	list<retenueCollinaire> listeRetenuesCollinairesAsuivre <- [];
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		string detail <- detailSimulation + '\n';			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/recharge_retenues'+ nomDeLaSimulation + '.csv';
		
		list<retenueCollinaire> listeRetenuesTemp <- listeRetenuesCollinaires where (each.typeOfRet = DECONNECTE) + 
																  listeRetenuesCollinaires where (each.typeOfRet = CONNECTE);
																  
		ask listeRetenuesTemp{
			if mapEquipementsCaptageAssocies[IRR]!=nil {
				if(length(mapEquipementsCaptageAssocies at IRR)> 0){ // Si RET a usage Agricole
					myself.listeRetenuesCollinairesAsuivre << self;
				}
			}
		}
		string dataAnnuelle <- 'annee;id';
		ask listeRetenuesCollinairesAsuivre{
			dataAnnuelle <- dataAnnuelle + ";" +self.id;
		}
		dataAnnuelle <- dataAnnuelle + '\nNA;Volume';
		ask listeRetenuesCollinairesAsuivre{
			dataAnnuelle <- dataAnnuelle + ";" +int(self.volumeMax);
		}
		dataAnnuelle <- dataAnnuelle + '\nNA;Surface';
		ask listeRetenuesCollinairesAsuivre{
			dataAnnuelle <- dataAnnuelle + ";" +int(self.surface);
		}
		dataAnnuelle <- dataAnnuelle + '\nNA;TypeRet';
		ask listeRetenuesCollinairesAsuivre{
			dataAnnuelle <- dataAnnuelle + ";" +self.typeOfRet;
		}
		return dataAnnuelle;	 	
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{	
		string data <-  	'' + (dateCour.annee) +";Remplissage";
		ask listeRetenuesCollinairesAsuivre{
			data <- data + ";" +int (myself.mapRechargeEffective at self);
		}
		data <-  data +	'\n' + (dateCour.annee)+";VolInit";
		ask listeRetenuesCollinairesAsuivre{
			data <- data + ";" + int (myself.mapRemplissageDebutAnnee at self);
		}
		data <-  data +	'\n' + (dateCour.annee)+";NbJoursSousCulot";
		ask listeRetenuesCollinairesAsuivre{
			data <- data + ";" +int (myself.mapNbJoursSousCulot at self) ;
		}
		data <-  data +	'\n' + (dateCour.annee)+";VolPreleve";
		ask listeRetenuesCollinairesAsuivre{
			data <- data + ";" +int (myself.mapVolumePreleve at self) ;
		}
		return data;			 					 				
	 }
	 
	 string ecritureDebutAnnuelle{	
		ask listeRetenuesCollinairesAsuivre{
			put self.volumeActuel at: self in: myself.mapRemplissageDebutAnnee ; 
		}		
		return "";			 					 				
	 }	


	string ecritureJournaliere{
		ask listeRetenuesCollinairesAsuivre{
			put ((myself.mapRechargeEffective at self) + self.volumeRechargeEffective) at: self in: myself.mapRechargeEffective ;
			if(self.volumeActuel <= volumeCulot){
				put ((myself.mapNbJoursSousCulot at self) + 1) at: self in: myself.mapNbJoursSousCulot ;
			}
			put ((myself.mapVolumePreleve at self) + (self.mapVolumePreleveReel at IRR)) at: self in: myself.mapVolumePreleve ;
		}
		return "";
	}
	/*
	 * @Overwrite
	 */		 
	 action miseAzero{	
	 	ask listeRetenuesCollinairesAsuivre{
			put 0.0 at: self in: myself.mapRechargeEffective ;
			put 0 at: self in: myself.mapNbJoursSousCulot ;
			put 0 at: self in: myself.mapVolumePreleve ;
		}
			
	 }		 			 
}

