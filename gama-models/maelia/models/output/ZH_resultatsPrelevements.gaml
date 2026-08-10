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

model ZH_resultatsPrelevements

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"

global{
	action initialisationEcritureFichiersPrelevementsZH{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements par ZH...';		
		list<string> listTypeActeurPossibles <- [IRR, AEP, IND, CAN];
		loop acteur over: listTypeActeurPossibles{
			list<equipementDeCaptage> equipementsActeur <- mapEquipementsDeCaptage at acteur;
			if(length(equipementsActeur) > 0){
				create ZH_resultatsPrelevements number: 1{
					sonActeur <- acteur;
					do initialisation();
					add self to: listesFichiersAcreer;
				}
			}
		}
	}			
}


species ZH_resultatsPrelevements parent: ecritureResultats{
	map<zoneHydrographique,float> volSurf <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volNapp <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volRet <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volCan <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volSurfSOUHAIT <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volNappSOUHAIT <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volRetSOUHAIT <- map<zoneHydrographique,float>([]);
	map<zoneHydrographique,float> volCanSOUHAIT <- map<zoneHydrographique,float>([]);
	string sonActeur <- IRR;
	
			/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/ZH_resultatsPrelevements_'+sonActeur+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'idZH;annee;type;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/ZH_resultatsPrelevementsJournalier_'+sonActeur+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
		ask listeZonesHydrographiques{
			dataJournaliere <-dataJournaliere +';'+ 
			string(idZoneHydrographique)+'_'+SURF+'_SOUHAIT;'+
			string(idZoneHydrographique)+'_'+SURF+'_REEL;'+
			string(idZoneHydrographique)+'_'+NAPP+'_SOUHAIT;'+
			string(idZoneHydrographique)+'_'+NAPP+'_REEL;'+
			string(idZoneHydrographique)+'_'+RET+'_SOUHAIT;'+
			string(idZoneHydrographique)+'_'+RET+'_REEL;'+
			string(idZoneHydrographique)+'_'+CAN+'_SOUHAIT;'+
			string(idZoneHydrographique)+'_'+CAN+'_REEL';
		}			
		
		return dataJournaliere;	
	}

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	string sonActeurLoc <- self.sonActeur; // gestion bug GAMA 1.6 ? // si on ne cree pas une variable locale alors a cause du world, elle n'est pas passe correctement en argument
		loop zh over: listeZonesHydrographiques{
			// SURF
			float volumeSurfZhSOUHAIT <- float(volSurfSOUHAIT at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, SURF, zh);
			float volumeSurfZh <- float(volSurf at zh) +  world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, SURF, zh);	
			dataJournaliere <- dataJournaliere + ';' + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, SURF, zh) with_precision 0+ ';' 
													 + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, SURF, zh) with_precision 0;
			put volumeSurfZhSOUHAIT at: zh in: volSurfSOUHAIT;
			put volumeSurfZh at: zh in: volSurf;	
			// NAPP
			float volumeNappZhSOUHAIT <- float(volNappSOUHAIT at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, NAPP, zh);
			float volumeNappZh <- float(volNapp at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, NAPP, zh);	
			dataJournaliere <- dataJournaliere+ ';' + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, NAPP, zh) with_precision 0 +';' 
													+ world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, NAPP, zh) with_precision 0;
			put volumeNappZhSOUHAIT at: zh in: volNappSOUHAIT;
			put volumeNappZh at: zh in: volNapp;	
			// RET
			float volumeRetZhSOUHAIT <- float(volRetSOUHAIT at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, RET, zh);
			float volumeRetZh <- float(volRet at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, RET, zh);	
			dataJournaliere <- dataJournaliere+ ';'+ world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, RET, zh) with_precision 0+ ';'
												   + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, RET, zh) with_precision 0;
			put volumeRetZhSOUHAIT at: zh in: volRetSOUHAIT;	
			put volumeRetZh at: zh in: volRet;	
			// CAN
			float volumeCanZhSOUHAIT <- float(volCanSOUHAIT at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, CAN, zh);
			float volumeCanZh <- float(volCan at zh) + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, CAN, zh);	
			dataJournaliere <- dataJournaliere+ ';'+ world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, SOUHAITE, CAN, zh) with_precision 0+ ';'
												   + world.getVolumePreleve_ACTEUR_NATURE_ZH(sonActeurLoc, REEL, CAN, zh) with_precision 0;
			put volumeCanZhSOUHAIT at: zh in: volCanSOUHAIT;	
			put volumeCanZh at: zh in: volCan;				
		}		 	
	 	return dataJournaliere;		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	int numero <- 0;
	 	string data <- "";
	 	ask listeZonesHydrographiques{
	 		// Remplissage fichier		 		
	 		numero <- numero + 1;
		 	data <-  	data + ''  + idZoneHydrographique +	
						';' + (dateCour.annee) +
						';'+SURF+';' + float(myself.volSurfSOUHAIT at self) with_precision 0+';' 
						+ float(myself.volSurf at self) with_precision 0+"\n";
		 	data <-  	data + ''  + string(idZoneHydrographique) +	
						';' + (dateCour.annee) +
						';'+NAPP+';'+ float(myself.volNappSOUHAIT at self) with_precision 0+';'
						 +float(myself.volNapp at self) with_precision 0+"\n";
		 	data <-  	data + ''  + string(idZoneHydrographique) +	
						';' + (dateCour.annee) +
						';'+RET+';'+ float(myself.volRetSOUHAIT at self) with_precision 0+';'
						+ float(myself.volRet at self) with_precision 0; 			
			data <-  	data + ''  + string(idZoneHydrographique) +	
						';' + (dateCour.annee) +
						';'+CAN+';'+ float(myself.volCanSOUHAIT at self) with_precision 0+';'
						+ float(myself.volCan at self) with_precision 0; 			
			if(numero < length(listeZonesHydrographiques)){
				data <- data + '\n';
			}	
	 	}		 		
	 	return data;		
	 }

	/*
	 * @Overwrite
	 */		 
	 action miseAzero{		//
		volSurf <- map<zoneHydrographique,float>([]);
		volNapp <- map<zoneHydrographique,float>([]);
		volRet <- map<zoneHydrographique,float>([]);
		volSurfSOUHAIT <- map<zoneHydrographique,float>([]);
		volNappSOUHAIT <- map<zoneHydrographique,float>([]);
		volRetSOUHAIT <- map<zoneHydrographique,float>([]);
		volCanSOUHAIT <- map<zoneHydrographique,float>([]);
		volCan <- map<zoneHydrographique,float>([]);   	
	 }		 			 
}

