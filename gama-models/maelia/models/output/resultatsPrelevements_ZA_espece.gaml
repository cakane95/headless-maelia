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

model resultatsPrelevements_za_espece

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "ecritureResultats.gaml"
import "../modeleNormatif/zoneAdministrative.gaml"
import "../modeleNormatif/secteurAdministratif.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"
import "../modeleHydrographique/equipement.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/Cultures/groupeIrrigationCulture.gaml"

global{
	action initialisationEcritureFichiersPrelevements_za_espece{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create resultatsPrelevements_za_espece number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsPrelevements_za_espece parent: ecritureResultats{
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de za __ idEspece
	map<string,float> volREEL <- map<string,float>([]);
	
	//list<string> listID <- [];
	list<parcelle> parcellesUtilesIrrigables <- []; //liste de parcelles par type de sol
	
	list<especeCultivee> listeEspeceIrrigables <- [];
	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevementsJournalier_za_espece'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- 'date';
					
		//liste des parcelles Irrigable et Utile
		ask listeParcellesUtiles{
			if(self.ilot_app.isIrrigable){
				myself.parcellesUtilesIrrigables << self;
			}
		}
		
		loop za over: (listZonesAdministratives){
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idZaVari <- string(za.idZoneAdministrative) +"_"+ vari.idEspeceCultivee;
				dataJournaliere <-dataJournaliere +';'
					 + string(idZaVari)+'_SOUHAIT;'
					 + string(idZaVari)+'_REEL';
			}
		}
		return dataJournaliere;	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultatsPrelevements_za_espece'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;za;espece;volSouhaite[m3];volReel[m3]';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	string dataJournaliere <- string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee);
	 	
	 	//parcellesUtilesIrrigables
	 	loop za over: listZonesAdministratives{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idZaVari <- string(za.idZoneAdministrative) +"_"+ vari.idEspeceCultivee;
				float volume_SOUHAIT <- 0.0;
				float volume_REEL <- 0.0;
				ask (parcellesUtilesIrrigables where ((each.getITKAnnee().especeCultiveeITK = vari) and
					 (length(each.listeGroupeIrrigationCulture) >0)
					)){	
					if (self.ilot_app.ppaCourant != nil){
						if (self.ilot_app.ppaCourant.getZaAssociee() = za){
							volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee/nombreMillimetreDansUnMetre) * self.surface;
							volume_REEL <- volume_REEL + (self.irrigationReelle/nombreMillimetreDansUnMetre) * self.surface;
						}
					}
				}
				dataJournaliere <-dataJournaliere +';'
					 + string(volume_SOUHAIT with_precision 0)+';'
					 + string(volume_REEL with_precision 0);
					 
				put (volume_SOUHAIT + (volSOUHAIT at idZaVari)) at: idZaVari in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at idZaVari)) at: idZaVari in: volREEL;
				
			}
		}	
	 	
	 	return dataJournaliere;		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	string data <- "";
	 	bool first <- true;
	 	loop za over:listZonesAdministratives{
			loop vari over: listeEspecesCultiveesParOrdreSaisie{
				string idZaVari <- string(za.idZoneAdministrative) +"_"+ vari.idEspeceCultivee;
				
				if ((volSOUHAIT at idZaVari) > 0){
					if(!first){
						data <-  data +"\n";
					}
					data <-  data + (dateCour.annee) +
						';'+string(za.idZoneAdministrative)+';'+vari.idEspeceCultivee+ ';' +
						 float(volSOUHAIT at idZaVari) with_precision 0 +';'+
						 float(volREEL at idZaVari) with_precision 0;
					first<- false;
				}
			}
		}
	 	return data;		
	 }

	/*
	 * @Overwrite
	 */		 
	 action miseAzero{		
		volSOUHAIT <- map<string,float>([]);
		volREEL <- map<string,float>([]);
	 }
 		 			 
}

