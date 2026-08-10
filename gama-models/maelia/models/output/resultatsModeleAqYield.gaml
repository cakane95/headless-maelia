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
 *  ecritureFichiers
 *  Author: JV
 *  Description: idem resultatsModeleAveyron.gaml (qui devrait être renommé car pas spécifique à Aveyron) mais sur plusieurs parcelles
 */


model resultatsModeleAqYield

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/zoneMeteo.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Cultures/culture.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"  
import "../modeleNormatif/pointDeReference.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersModeleAqYield{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Modele AqYield...';		
		
		create resultatsModeleAqYield number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsModeleAqYield parent: ecritureResultats{
	map<string,float> sommeETP <- []; // clé: idParcelle, valeur: sommeETP
	map<string,float> sommeP <- [];
	map<string,float> sommeIrr <- [];
	map<string,float> sommeRuis <- [];
	map<string,float> sommeTM <- [];
	map<string,float> sommeTRr <- [];
	map<string,float> sommeEva <- [];
	map<string,float> sommeDrain <- [];
	map<string,float> sommeEvaPrime <- [];
	map<string,float> sommeCap <- [];
	map<string,float> sommeDeltaRH <- [];

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
	 	string detail <- 'Annee : ' + anneeDebutSimulation + '\n';
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detail + '\ndate;Lj';

		loop idParcelle over: listParcellesPourSortiesAqYield{
			dataJournaliere <- dataJournaliere + ';Frein_' + idParcelle + ';Tmoy_' + idParcelle + ';P_' + idParcelle + ';ETP_' + idParcelle + ';PIR_' + idParcelle + ';Ruiss_' + idParcelle + ';Drain_' + idParcelle + ';Cap_' + idParcelle + ';Ccap_' + idParcelle + ';echV_' + idParcelle + ';Kc_' + idParcelle + ';RUs_' + idParcelle + ';Hs_' + idParcelle + ';RUw_' + idParcelle + ';Hw_' + idParcelle + ';RUr_' + idParcelle + ';Hr_' + idParcelle + ';RUm_' + idParcelle + ';Hm_' + idParcelle + ';Eva_' + idParcelle + ';TM_' + idParcelle + ';TRw_' + idParcelle + ';TRr_' + idParcelle + ';TR_M_' + idParcelle + ';sommeDrain_' + idParcelle + ';sommeEva_' + idParcelle + ';Tmin_' + idParcelle; 
		}
		do miseAzero(); // pour initialiser les maps à 0

		return dataJournaliere;
	 }

	 string initialisationFinAnnuel{			
		string detail <- 'Annee : ' + anneeDebutSimulation + '\n';
		
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Annuel'+ nomDeLaSimulation + '.csv';
		string dataAnnuelle <- '' + detail + '\nannee';

		loop idParcelle over: listParcellesPourSortiesAqYield{
			dataAnnuelle <- dataAnnuelle + ';Rendement_' + idParcelle + ';SommeETP_' + idParcelle + ';SommeP_' + idParcelle + ';SommeIrr_' + idParcelle + ';SommeRuis_' + idParcelle + ';SommeTM_'+ idParcelle + ';SommeTRr_' + idParcelle + ';SommeEva_' + idParcelle + ';SommeDrain_' + idParcelle + ';SommeEvaPrime_' + idParcelle + ';SommeCap_' + idParcelle + ';SommedRH_' + idParcelle;
		}

		return dataAnnuelle;	 	
	 }

	/*
	 * @Overwrite
	 */
	 string ecritureJournaliere{
//		 	int indiceDebut <- 0;
//		 	int indiceFin <- 0;
//		 	ask(date){
//		 		indiceDebut <- convertirDateEnIndice(jourAConvertir:25, moisAConvertir:10, anneeAConvertir: 2000);
//		 		indiceFin <- convertirDateEnIndice(jourAConvertir:31, moisAConvertir:12, anneeAConvertir: 2001);
//		 	}
	 	
	 	string data <- "" + string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) + ';' + float(dateCour.longueurDuJour);
	 		 	
		loop idParcelle over: listParcellesPourSortiesAqYield{
	 		parcelle uneParcelle <- first(listeParcelles where (each.idParcelle = idParcelle));
	 		parcelleAqYield uneParcelleAqYield <- parcelleAqYield(uneParcelle);
//		 	if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle != nil){
//		 	if(parcelleAffichee != nil){			 		
			
	 		sommeETP[idParcelle] <- sommeETP[idParcelle] + float(uneParcelleAqYield.ilot_app.meteo.etp);
			sommeP[idParcelle] <- sommeP[idParcelle] + float(uneParcelleAqYield.getPluie());
			sommeIrr[idParcelle] <- sommeIrr[idParcelle] + float(uneParcelleAqYield.irrigationReelle);
			sommeRuis[idParcelle] <- sommeRuis[idParcelle] + float(uneParcelleAqYield.quantiteEauDeRuissellement);
			sommeTM[idParcelle] <- 0.0;
			sommeTRr[idParcelle] <- sommeTRr[idParcelle] + float(uneParcelleAqYield.transpirationR);
			sommeEva[idParcelle] <- sommeEva[idParcelle] + float(uneParcelleAqYield.evaporation);
			sommeDrain[idParcelle] <- sommeDrain[idParcelle] + float(uneParcelleAqYield.drain); //mm
			sommeEvaPrime[idParcelle] <- 0.0;
			sommeCap[idParcelle] <- 0.0;
			sommeDeltaRH[idParcelle] <- 0.0;
	
			data <- data +								
								';' + float(uneParcelleAqYield.getFrein()) +									
								';' + float(uneParcelleAqYield.getTmoy()) +
								';' + float(uneParcelleAqYield.getPluie()) +
								';' + float(uneParcelleAqYield.ilot_app.meteo.etp) +
								';' + float(uneParcelleAqYield.apportEnEauUtile) +
								';' + float(uneParcelleAqYield.quantiteEauDeRuissellement) +
								';' + float(uneParcelleAqYield.drain) +
								';' + float(uneParcelleAqYield.capilarite) +								
								';' + float(uneParcelleAqYield.Ccap) +
								';' + float(uneParcelleAqYield.getEchelleVegetation()) +
								//';' + float(uneParcelleAqYield.getDeltaKc()) +
								';' + float(uneParcelleAqYield.getKc()) +
								';' + float(uneParcelleAqYield.RUs) +
								';' + float(uneParcelleAqYield.Hs) +
								';' + float(uneParcelleAqYield.RUw) +
								';' + float(uneParcelleAqYield.Hw) +
								';' + float(uneParcelleAqYield.RUr) +
								';' + float(uneParcelleAqYield.Hr) +
								';' + float(uneParcelleAqYield.RUm) +
								';' + float(uneParcelleAqYield.Hm) +
								';' + float(uneParcelleAqYield.evaporation) +
								';'	+ float(uneParcelleAqYield.getTranspirationMax()) +
								';' + float(uneParcelleAqYield.transpirationW) +
								';' + float(uneParcelleAqYield.transpirationR) +
								';' + float(uneParcelleAqYield.getTR_M()) +
								';' + sommeDrain[idParcelle] +
								';' + sommeEva[idParcelle] +
								';' + float(uneParcelleAqYield.getTmin());
		}			
		return data;
	 }
	 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{
//		 	if(parcelleAffichee != nil){
			string data <-  '' + (dateCour.annee);
			
		loop idParcelle over: listParcellesPourSortiesAqYield{
	 		parcelle uneParcelle <- first(listeParcelles where (each.idParcelle = idParcelle));
	 		parcelleAqYield uneParcelleAqYield <- parcelleAqYield(uneParcelle);
			
			data <- data +
								//';' + float(uneParcelleAqYield.getRendementDerniereCulture()) +
								';' + float(sum(uneParcelleAqYield.rdtRecolteSurAnnee)) +							
								';' + sommeETP[idParcelle] +
								';' + sommeP[idParcelle] +
								';' + sommeIrr[idParcelle] +
								';' + sommeRuis[idParcelle] +
								';' + sommeTM[idParcelle] +
								';' + sommeTRr[idParcelle] +
								';' + sommeEva[idParcelle] +
								';' + sommeDrain[idParcelle] +
								';' + sommeEvaPrime[idParcelle] +
								';' + sommeCap[idParcelle] +
								';' + sommeDeltaRH[idParcelle];
		}			 		
 		return data;	
	 }	

	/*
	 * @Private
	 */		 
	 action miseAzero{		
		loop idParcelle over: listParcellesPourSortiesAqYield{
	 		sommeETP[idParcelle] <- 0.0;
			sommeP[idParcelle] <- 0.0;
			sommeIrr[idParcelle] <- 0.0;
			sommeRuis[idParcelle] <- 0.0;
			sommeTM[idParcelle] <- 0.0;
			sommeTRr[idParcelle] <- 0.0;
			sommeEva[idParcelle] <- 0.0;
			sommeDrain[idParcelle] <- 0.0;
			sommeEvaPrime[idParcelle] <- 0.0;
			sommeCap[idParcelle] <- 0.0;
			sommeDeltaRH[idParcelle] <- 0.0;
		}		 	
	 }		 			 
}

