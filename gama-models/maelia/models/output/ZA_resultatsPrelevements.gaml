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
 *  ZHresultatsPrelevements
 *  Author: Maroussia
 *  Description: 
 */

model ZA_resultatsPrelevements

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleNormatif/secteurAdministratif.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleHydrographique/equipement.gaml"

global{
	action initialisationEcritureFichiersPrelevementsZA{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create ZA_resultatsPrelevements number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species ZA_resultatsPrelevements parent: ecritureResultats{
	map<zoneAdministrative,float> volSurfSOUHAIT <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volNappSOUHAIT <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volRetSOUHAIT <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volCanSOUHAIT <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volSurfREEL <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volNappREEL <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volRetREEL <- map<zoneAdministrative,float>([]);
	map<zoneAdministrative,float> volCanREEL <- map<zoneAdministrative,float>([]);
	
			/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/ZA_resultatsPrelevements'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'idZA;annee;type;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/ZA_resultatsPrelevementsJournalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
		ask listZonesAdministratives{
			dataJournaliere <-dataJournaliere +';'
			 + string(idZoneAdministrative)+'_'+SURF+'_SOUHAIT;'
			 + string(idZoneAdministrative)+'_'+SURF+'_REEL;'
			 + string(idZoneAdministrative)+'_'+NAPP+'_SOUHAIT;'
			 + string(idZoneAdministrative)+'_'+NAPP+'_REEL;'
			 + string(idZoneAdministrative)+'_'+RET+'_SOUHAIT;'
			 + string(idZoneAdministrative)+'_'+RET+'_REEL;'
			 + string(idZoneAdministrative)+'_'+CAN+'_SOUHAIT;'
			 + string(idZoneAdministrative)+'_'+CAN+'_REEL';
		}
		
		
		return dataJournaliere;	
	}

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	loop za over: listZonesAdministratives{
			float volumeSurfZh_SOUHAIT <- 0.0;
			float volumeSurfZh_REEL <- 0.0;
			float volumeNappZh_SOUHAIT <- 0.0;
			float volumeNappZh_REEL <- 0.0;
			float volumeRetZh_SOUHAIT <- 0.0;
			float volumeRetZh_REEL <- 0.0;
			float volumeCanZh_SOUHAIT <- 0.0;
			float volumeCanZh_REEL <- 0.0;
	 		loop sa over: za.secteursAdministratifsAssocies{
	 			ask sa.listePPAassocies{
	 				if(acteurAssocie="IRR"){
		 				switch self.natureRessourcePrelevee{
		 					match SURF {	
	 							volumeSurfZh_SOUHAIT <- volumeSurfZh_SOUHAIT + getVolume(SOUHAITE);
	 							volumeSurfZh_REEL <- volumeSurfZh_REEL + getVolume(REEL);                      
				            }
				            match NAPP {
				                volumeNappZh_SOUHAIT <- volumeNappZh_SOUHAIT + getVolume(SOUHAITE);
		 						volumeNappZh_REEL <- volumeNappZh_REEL + getVolume(REEL);                      
				            }
				            match RET {
				                volumeRetZh_SOUHAIT <- volumeRetZh_SOUHAIT + getVolume(SOUHAITE);
		 						volumeRetZh_REEL <- volumeRetZh_REEL + getVolume(REEL);                      
				            }
				            match CAN {
				                volumeCanZh_SOUHAIT <- volumeCanZh_SOUHAIT + getVolume(SOUHAITE);
		 						volumeCanZh_REEL <- volumeCanZh_SOUHAIT + getVolume(REEL);                      
				            }
		 				}
	 				}
	 				
	 			}
	 		}
	 		put (volumeSurfZh_SOUHAIT + (volSurfSOUHAIT at za)) at: za in: volSurfSOUHAIT;
	 		put (volumeSurfZh_REEL +(volSurfREEL at za)) at: za in: volSurfREEL;
	 		put (volumeNappZh_SOUHAIT +(volNappSOUHAIT at za)) at: za in: volNappSOUHAIT;
	 		put (volumeNappZh_REEL +(volNappREEL at za)) at: za in: volNappREEL;
	 		put (volumeRetZh_SOUHAIT +(volRetSOUHAIT at za)) at: za in: volRetSOUHAIT;
	 		put (volumeRetZh_REEL +(volRetREEL at za)) at: za in: volRetREEL;
	 		put (volumeCanZh_SOUHAIT +(volCanSOUHAIT at za)) at: za in: volCanSOUHAIT;
	 		put (volumeCanZh_REEL +(volCanREEL at za)) at: za in: volCanREEL;
	 		
	 		dataJournaliere <-dataJournaliere +';'+
			 volumeSurfZh_SOUHAIT with_precision 0+';' +
			 volumeSurfZh_REEL with_precision 0+';' +
			 volumeNappZh_SOUHAIT with_precision 0+';' +
			 volumeNappZh_REEL with_precision 0+';' +
			 volumeRetZh_SOUHAIT with_precision 0+';' +
			 volumeRetZh_REEL with_precision 0+';'+
			 volumeCanZh_SOUHAIT with_precision 0+';' +
			 volumeCanZh_REEL with_precision 0;
	 	}
	 	return dataJournaliere;		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	string data <- "";
	 	ask listZonesAdministratives{
	 		// Remplissage fichier		 		
		 	data <-  	data + ''  + string(idZoneAdministrative) +	
						';' + (dateCour.annee) +
						';'+SURF+';' + float(myself.volSurfSOUHAIT at self) with_precision 0 +';'+ float(myself.volSurfREEL at self) with_precision 0 +"\n";
		 	data <-  	data + ''  + string(idZoneAdministrative) +	
						';' + (dateCour.annee) +
						';'+NAPP+';' + float(myself.volNappSOUHAIT at self) with_precision 0 +';'+float(myself.volNappREEL at self) with_precision 0 +"\n";
		 	data <-  	data + ''  + string(idZoneAdministrative) +	
						';' + (dateCour.annee) +
						';'+RET+';' + float(myself.volRetSOUHAIT at self) with_precision 0 +';'+ float(myself.volRetREEL at self) with_precision 0+"\n"; 
			data <-  	data + ''  + string(idZoneAdministrative) +	
						';' + (dateCour.annee) +
						';'+CAN+';' + float(myself.volCanSOUHAIT at self) with_precision 0 +';'+ float(myself.volCanREEL at self) with_precision 0+"\n"; 						
				
	 	}		 		
	 	return data;		
	 }

	/*
	 * @Overwrite
	 */		 
	 action miseAzero{		
		volSurfSOUHAIT <- map<zoneAdministrative,float>([]);
		volSurfREEL <- map<zoneAdministrative,float>([]);
		volNappSOUHAIT <- map<zoneAdministrative,float>([]);
		volNappREEL <- map<zoneAdministrative,float>([]);
		volRetSOUHAIT <- map<zoneAdministrative,float>([]);
		volRetREEL <- map<zoneAdministrative,float>([]);
		volCanSOUHAIT <- map<zoneAdministrative,float>([]);
		volCanREEL <- map<zoneAdministrative,float>([]); 	
	 }		 			 
}

