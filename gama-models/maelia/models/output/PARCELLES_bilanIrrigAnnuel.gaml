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
 *  PARCELLESbilanIrrigAnnuel
 *  Author: cmurgue
 *  Description: calcul la quantite d'eau apport� par an sur chaque parcelle
 */

model PARCELLESbilanIrrigAnnuel




import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/StrategiesIrrigation/strategieIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Cultures/groupeIrrigationCulture.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleCommun/typeDeSol.gaml"

global{
	action initialisationEcritureFichiersPARCELLESbilanIrrigAnnuel{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers prelevements...';		
		
		create PARCELLESbilanIrrigAnnuel number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species PARCELLESbilanIrrigAnnuel parent: ecritureResultats{
	parcelle parcelleEcriture <- nil;
	list<parcelle> listeTemp <- [];
	map<parcelle,itk> ITKparcelle <- map([]);	
	map<parcelle,float> volIrr <- map<parcelle,float>([]);
	map<parcelle,list<int>> datesIrrigationParcelles <- map([]); //parcelle;datesIrrigations
//		map<parcelle,float> volSouhaite <- map([]);
//		map<parcelle,list<int>> datesIrrigationSouhaiteesParcelles <- map([]); //parcelle;datesIrrigations
	
	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/PARCELLESbilanIrrigJournalier'+ nomDeLaSimulation + '.csv'; 
		listeTemp <- listeAgriculteurs accumulate each.listeParcelles;
		parcelleEcriture <- first (listeTemp where (each.getITKAnnee().isIrriguee()));
		
		string dataJournaliere <- 'date;idParcelle;surface[m3];cult;ITK;CaracIrr;hautREELLE[mm];volREELLE[m3];nbGroupeIrrREEL;nbPassages;surfMaxGroupes;surfTotGroupes;surfJourTotGroupes';
//			;hautSOUHAITEE[mm];volSOUHAITEE[m3];nbPassageTotSOUHAITEE;nbGroupeIrrSOUHAITEE;nbTourEauSOUHAITEE;JJPremiereIrrSOUHAITEE;JJDerniereIrrSOUHAITEE
		return dataJournaliere;
	 }
	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/PARCELLESbilanIrrigAnnuel'+ nomDeLaSimulation + '.csv'; 

		string dataAnnuelle <- 'annee;idParcelle;surface[Ha];cult;ITK;CaracIrr;hautREELLE[mm];volREELLE[m3];nbPassageTotREEL;nbGroupeIrrREEL;nbTourEauREEL;JJPremiereIrrREEL;JJDerniereIrrREEL;IDExploit;Sol;Materiel';
//			;hautSOUHAITEE[mm];volSOUHAITEE[m3];nbPassageTotSOUHAITEE;nbGroupeIrrSOUHAITEE;nbTourEauSOUHAITEE;JJPremiereIrrSOUHAITEE;JJDerniereIrrSOUHAITEE
		return dataAnnuelle;
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
	 	// Mise a jour pour la fin de lannee
		loop parcelleCourante over: listeTemp{
			// ITK (a faire une seule fois dans l'annee par parcelle)
			if((ITKparcelle at parcelleCourante) = nil){
				put parcelleCourante.getITKAnnee() at: parcelleCourante in: ITKparcelle;	
			}	
				
//				do majQuotidienne(parcelleCourante, SOUHAITE, volSouhaite, datesIrrigationSouhaiteesParcelles);
			do majQuotidienne(parcelleCourante, REEL, volIrr, datesIrrigationParcelles);													
		}	 	
	 	
	 	// Ecriture journaliere
	 	string data <- "";
	 	ask parcelleEcriture{
 			string surfMax <- "";
 			string surfTot <- "";
 			string surfJourTot <- "";
 			ask listeGroupeIrrigationCulture{
 				ask groupeAssocie{
 					string separateur <- "|";
 					if(surfMax = ""){
 						separateur <- "";
 					}
 					surfMax <- surfMax + separateur + surfaceMax;
 					surfTot <- surfTot + separateur + surfaceTotale;
 					surfJourTot <- surfJourTot + separateur + surfaceJournaliereTotale;
 				}		 				
 			}
 			
	 		// Remplissage fichier	 		
		 	data <-  	data + '' + (dateCour.getNom()) +
						';' + string(idParcelle) +
						';' + float(surface) +
						';' + string(itk(getITKAnnee()).especeCultiveeITK.idEspeceCultivee) +
						';' + string(itk(getITKAnnee()).nomPourAffichage)+
						';' + string(isParcelleIrrigable())+
						';' + float(getVolumeIrrigation(REEL))*nombreMillimetreDansUnMetre/surface	+
						';' + float(getVolumeIrrigation(REEL)) +
						';' + int(length(listeGroupeIrrigationCulture)) +
						';' + int(length(myself.datesIrrigationParcelles at self)) +
						';' + string(surfMax) +
						';' + string(surfTot) +
						';' + string(surfJourTot); 			
	 	}		 		
	 	return data;	 			 	
	 }
	 
	 action majQuotidienne(parcelle parcEntree, string type, map<parcelle,float> vol, map<parcelle,list<int>> dates){
	 	// REELLE
		if(parcEntree.getVolumeIrrigation(type) > 0.0){				
			// Volume tot irr
			float volumeParcelle <- float(vol at parcEntree) + parcEntree.getVolumeIrrigation(type);	
			put volumeParcelle at: parcEntree in: vol;					

			// Date irr
			list<int> listeDates <- (dates at parcEntree);	
			listeDates << dateCour.calculNbJourEcouleDansAnneeAlaDateCourante();
			put listeDates at: parcEntree in: dates;					
		}
	 }
	 
 
	/*
	 * @Overwrite
	 */		 
	 string ecritureFinAnnuelle{
	 	int numero <- 0;
	 	string data <- "";
	 	ask listeTemp{
//		 		if((myself.ITKparcelle at self) != nil){
		 		// Donnees int		 		
		 		numero <- numero + 1;
		 		list<int> temp <- myself.datesIrrigationParcelles at self;
//			 		list<int> tempSouhaitee <- myself.datesIrrigationSouhaiteesParcelles at self;
		 		float nbTourEau <- 0.0;
//			 		float nbTourEauSouhaite <- 0.0;
		 		if(length(listeGroupeIrrigationCulture) > 0){
		 			nbTourEau <- float(myself.volIrr at self)*nombreMillimetreDansUnMetre/surface;
		 			//nbTourEau <- float(length(temp) / length(listeGroupeIrrigationCulture));
//			 			nbTourEauSouhaite <- float(length(tempSouhaitee) / length(listeGroupeIrrigationCulture));
		 		}
		 		// Remplissage fichier	
		 		string idMat <- "Aucun";
		 		if (ilot_app.materielIlot !=nil){
		 			idMat <- ilot_app.materielIlot.idMateriel;
		 		}
		 		string itkRellementIrr <- "Aucun";
		 		string especeRellementIrr <- "Aucun";
		 		if (itkIrrigue !=nil){
		 			especeRellementIrr <- itkIrrigue.especeCultiveeITK.idEspeceCultivee;
		 			itkRellementIrr <- itkIrrigue.nomPourAffichage;
		 			nbTourEau <- nbTourEau / mean(itkIrrigue.strategieIrrigationITK.mapQuantiteEau.values);
			 	}		
			 	data <-  	data + '' + (dateCour.annee) +
							';' + string(idParcelle) +
							';' + float(surface/nombreMeterCarreDansUnHectare) +
							';' + especeRellementIrr +
							';' + itkRellementIrr+
							';' + string(isParcelleIrrigable())+
							';' + float(myself.volIrr at self)*nombreMillimetreDansUnMetre/surface	+
							';' + float(myself.volIrr at self)	+
							';' + int(length(temp))	+
							';' + int(length(listeGroupeIrrigationCulture))	+
							';' + float(nbTourEau with_precision 1) +
							';' + int(min(temp))	+
							';' + int(max(temp)) +
							';' + string(ilot_app.codeExploitationAssociee)+
							';' + string(ilot_app.getNomZonePedo())+
							';' + idMat ;
//								';' + float(myself.volSouhaite at self)*nombreMillimetreDansUnMetre/surface	+
//								';' + float(myself.volSouhaite at self)	+
//								';' + int(length(tempSouhaitee))	+
//								';' + int(length(listeGroupeIrrigationCulture))	+
//								';' + float(nbTourEauSouhaite) +
//								';' + int(min(tempSouhaitee))	+
//								';' + int(max(tempSouhaitee));
				if(numero < length(myself.listeTemp)){
					data <- data + '\n';
				}			 			
//		 		}			
	 	}		 		
	 	return data;		
	 }


	/*
	 * @Overwrite
	 */		 
	 action miseAzero{	
		parcelleEcriture <- first (listeTemp where (each.getITKAnnee().isIrriguee()));
		volIrr <- map<parcelle,float>([]);
		ITKparcelle <- map([]);	
		datesIrrigationParcelles <- map([]);
	 }		 			 
}

