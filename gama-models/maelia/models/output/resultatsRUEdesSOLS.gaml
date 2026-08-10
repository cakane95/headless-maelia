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

model resultatsRUEdesSOLS

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
import "../modeleHydrographique/equipement.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"

global{
	action initialisationEcritureFichiersRUEdesSOLS{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichier RUEdesSOLS...';		
		
		create resultatsRUEdesSOLS number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}




species resultatsRUEdesSOLS parent: ecritureResultats{
	
	map<string,float> volSOUHAIT <- map<string,float>([]); //l'id se compose de sol __ idITK
	map<string,float> volREEL <- map<string,float>([]);
	map<string,float> drainCumITK <- map<string,float>([]);
	map<parcelle,float> drainCumParcelle <- map<parcelle,float>([]);
	
	//list<string> listID <- [];	
	map<string,list<parcelle>> mapGroupe <- map<string,list<parcelle>>([]); //liste de parcelles en fonction du typeDeSol x materiel x BVe x SDC
	
	/*
	 * @Overwrite
	 */
	string initialisationJournalier{		
		
		ask listeParcellesUtiles{		
			string idMap <- self.ilot_app.sol.idTypeDeSOl + "%";
				if(self.ilot_app.materielIlot !=nil){
					idMap <- idMap + "%"+ self.ilot_app.materielIlot.idMateriel;
				}else{
					idMap <- idMap + "%NA";
				}
				idMap <- idMap + "%"+
					self.ilot_app.zoneHydroAssociee.idZoneHydrographique + "%"+
					self.idSdcRef;
			list<parcelle> listTemp <- myself.mapGroupe at idMap;
			listTemp << self;
			put listTemp at:idMap in:myself.mapGroupe;
		}
		
		return "";	
	}
	
	
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/RUEdesSOLS'+ nomDeLaSimulation + '.csv';
		
		string dataAnnuelle <- 'annee;sol;typeDeSol;RU[mm];BVe;SDCref;Culture;itk;materielIrrigation;surface[ha];nbParcelles;RDT[t/ha]'+
								';irrigue?;volSouhaite[mm];volReel[mm];drainageSousCult[mm];drainageAnnee[mm];dateDebutIrrgation;DateFinIrrigation';
		return dataAnnuelle;
	 }

	
	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{

		loop idMap over: mapGroupe.keys{
			list<parcelle> tmp <- (mapGroupe at idMap);
			loop it over: listeITKs{
				string idMapITK <- idMap +"_"+ it.idITK; // cle unique
				float volume_SOUHAIT <- 0.0;
				float volume_REEL <- 0.0;
				float volumeDrain <- 0.0;
				ask (tmp where (each.getITKAnnee() = it)){
					volume_SOUHAIT <- volume_SOUHAIT + (self.irrigationSouhaitee) * self.surface;
					volume_REEL <- volume_REEL + (self.irrigationReelle) * self.surface;
					if(self.cultureParcelle !=nil){ // si parcelle deja seme
						volumeDrain <- volumeDrain + self.drain* self.surface; //Attention Drain en mm //[mm]*[m2]
					}
					
				}
					 
				put (volume_SOUHAIT + (volSOUHAIT at idMapITK)) at: idMapITK in: volSOUHAIT;
	 			put (volume_REEL +(volREEL at idMapITK)) at: idMapITK in: volREEL;
	 			put (volumeDrain +(drainCumITK at idMapITK)) at: idMapITK in: drainCumITK;
			}
			// memoriser le drain / parcelle
			ask (tmp){
				put (self.drain* self.surface +( myself.drainCumParcelle at self)) at: self in: myself.drainCumParcelle;
			}
		}
	 			 	
	 	return "";		 			 	
	 }
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	string data <- "";
	 	bool first <- true;
	 	loop idMap over: mapGroupe.keys{
	 		list<string> tmp <- idMap split_with '%';
	 		string idSol <- tmp[0];
	 		float RU <- first((typeDeSol as list) where (each.idTypeDeSOl=idSol)).reservePotentielleUtileMax;
	 		string idMateriel <- tmp[1];
	 		string idBVe <- tmp[2];
	 		string idSDC <- tmp[3];
	 		
	 		loop it over:listeITKs{
	 			float RDT <- 0.0;
		 		float surf <- 0.0;
		 		int nbParc <- 0;
		 		float volume_SOUHAIT <- 0.0;
		 		float volume_REEL <- 0.0;
		 		float drainCult <- 0.0;
		 		float drainAnnee <- 0.0;
		 		float dateDebutIrr <- 0.0;
		 		float dateFinIrr <- 0.0;
		 		float surfaceIrr <- 0.0;
	 			
	 			string idMapITK <- idMap +"_"+ it.idITK; // cle unique
	 			loop parc over: ((mapGroupe at idMap) as list<parcelle>){
	 				if (length(parc.itkRecolteSurAnnee) > 0){ // si au moins une récolte sur l'annee
	 					loop i from: 0 to: (length(parc.itkRecolteSurAnnee) -1){//parcours des differentes recolte
	 						if(parc.itkRecolteSurAnnee[i]=it){
	 							RDT <- RDT + parc.rdtRecolteSurAnnee[i];
	 							surf <- surf + parc.surface;
	 							nbParc <- nbParc +1;
	 							drainAnnee <- drainAnnee + (drainCumParcelle at parc);
	 						}
	 					}
	 					//put getITKAnnee() at:date.nbJoursEcoulesDansAnnee  in :(memoireOTsurParcelle at IRRIGATION);
	 					map<int,itk> mapIrr <-  parc.memoireOTsurParcelle  at IRRIGATION ;
	 					int di <- 367;
	 					int df <- 0;  
	 					loop j over: mapIrr.keys{
	 						if((mapIrr at j)= it){
	 							if(di > j){
	 								di <-j;
	 							}
	 							if(df < j){
	 								df <-j;
	 							}
	 						}
	 					}
	 					if(di<367){
	 						dateDebutIrr <- dateDebutIrr + di * parc.surface;
	 						dateFinIrr <- dateFinIrr + df * parc.surface;
	 						surfaceIrr <- surfaceIrr + parc.surface;
	 					}
	 					
	 				}
	 			}
				if (nbParc>0){
					if (first){
						first <- false;
					}else{
						data <- data + '\n';
					}
					data <- data + dateCour.annee+';'+
							idSol+";" +
							first((typeDeSol as list) where (each.idTypeDeSOl=idSol)).nom+ ";" +
							RU with_precision 2+";" + 
							idBVe+";" + 
							idSDC+";" + 
							it.especeCultiveeITK.idEspeceCultivee+";" + 
							it.nomPourAffichage+";" +
							idMateriel+";" + 
							(surf/nombreMeterCarreDansUnHectare) with_precision 2 +";" + 
							nbParc +";" + 
							(RDT/surf*nombreMeterCarreDansUnHectare) with_precision 2 +";" + //pour avoir un rdt en t/ha
							(it.strategieIrrigationITK != nil) +";" + 
							((volSOUHAIT at idMapITK)/surf) with_precision 2 +";" +
							((volREEL at idMapITK)/surf) with_precision 2  +";" +
							((drainCumITK at idMapITK)/surf) with_precision 2 +";" +
							(drainAnnee/surf) with_precision 2; 
							if(surfaceIrr > 0){
								data <- data +";" +(dateDebutIrr/surfaceIrr) with_precision 1 +";" +
								(dateFinIrr/surfaceIrr) with_precision 1;
							}else{
								data <- data +";NA;NA";
							}
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
		drainCumParcelle <- map<parcelle,float>([]);
		drainCumITK <- map<string,float>([]);
	 }
 		 			 
}

