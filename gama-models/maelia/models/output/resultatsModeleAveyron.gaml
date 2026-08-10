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
 *  Author: Maroussia Vavasseur
 *  Description: Cree 2 fichiers de resultats
 */


model resultatsModeleAveyron

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
	action initialisationEcritureFichiersModeleAveyron{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers Modele Aveyron...';		
		
		create resultatsModeleAveyron number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsModeleAveyron parent: ecritureResultats{
	float sommeETP <- 0.0;
	float sommeP <- 0.0;
	float sommeIrr <- 0.0;
	float sommeRuis <- 0.0;
	float sommeTM <- 0.0;
	float sommeTRr <- 0.0;
	float sommeEva <- 0.0;
	float sommeDrain <- 0.0;
	float sommeEvaPrime <- 0.0;
	float sommeCap <- 0.0;
	float sommeDeltaRH <- 0.0;

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
	 	string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + rotationForceeParcelle + '\nSol : ' + typeDeSolForceParcelle + '\n';
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detail + '\ndate;Lj;Frein;Tmoy;P;ETP;PIR;Ruiss;Drain;Cap;Ccap;echV;Kc;RUs;Hs;RUw;Hw;RUr;Hr;RUm;Hm;Eva;TM;TRw;TRr;TR_M;sommeDrain;sommeEva;Tmin';
		return dataJournaliere;
	 }
	 string initialisationFinAnnuel{			
		string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + rotationForceeParcelle + '\nSol : ' + typeDeSolForceParcelle + '\n';
		
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Annuel'+ nomDeLaSimulation + '.csv';
		let dataAnnuelle type: string value: '' + detail + '\nannee;Rendement;SommeETP;SommeP;SommeIrr;SommeRuis;SommeTM;SommeTRr;SommeEva;SommeDrain;SommeEvaPrime;SommeCap;SommedRH';
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
		if(verboseMode){
 			write "\t\t ecritureJournaliere de " + nomFichierJournalier + " parcelleAffichee=" + parcelleAffichee + " nomParcelleAffichee=" + nomParcelleAffichee;
 		}
 
	 	if(parcelleAffichee != nil /*and dateCour.indiceDate >= indiceDebut and dateCour.indiceDate <= indiceFin*/){
//		 	if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle != nil){
//		 	if(parcelleAffichee != nil){			 		
	 		sommeETP <- sommeETP + float(parcelleAqYield(parcelleAffichee).ilot_app.meteo.etp);
			sommeP <- sommeP + float(parcelleAqYield(parcelleAffichee).getPluie());
			sommeIrr <- sommeIrr + float(parcelleAqYield(parcelleAffichee).irrigationReelle);
			sommeRuis <- sommeRuis + float(parcelleAqYield(parcelleAffichee).quantiteEauDeRuissellement);
			sommeTM <- 0.0;
			sommeTRr <- sommeTRr + float(parcelleAqYield(parcelleAffichee).transpirationR);
			sommeEva <- sommeEva + float(parcelleAqYield(parcelleAffichee).evaporation);
			sommeDrain <- sommeDrain + float(parcelleAqYield(parcelleAffichee).drain); //mm
			sommeEvaPrime <- 0.0;
			sommeCap <- 0.0;
			sommeDeltaRH <- 0.0;
	
			string data <-  	string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
								';' + float(dateCour.longueurDuJour) +
								';' + float(parcelleAqYield(parcelleAffichee).getFrein()) +									
								';' + float(parcelleAqYield(parcelleAffichee).getTmoy()) +
								';' + float(parcelleAqYield(parcelleAffichee).getPluie()) +
								';' + float(parcelleAqYield(parcelleAffichee).ilot_app.meteo.etp) +
								';' + float(parcelleAqYield(parcelleAffichee).apportEnEauUtile) +
								';' + float(parcelleAqYield(parcelleAffichee).quantiteEauDeRuissellement) +
								';' + float(parcelleAqYield(parcelleAffichee).drain) +
								';' + float(parcelleAqYield(parcelleAffichee).capilarite) +								
								';' + float(parcelleAqYield(parcelleAffichee).Ccap) +
								';' + float(parcelleAqYield(parcelleAffichee).getEchelleVegetation()) +
								//';' + float(parcelleAqYield(parcelleAffichee).getDeltaKc()) +
								';' + float(parcelleAqYield(parcelleAffichee).getKc()) +
								';' + float(parcelleAqYield(parcelleAffichee).RUs) +
								';' + float(parcelleAqYield(parcelleAffichee).Hs) +
								';' + float(parcelleAqYield(parcelleAffichee).RUw) +
								';' + float(parcelleAqYield(parcelleAffichee).Hw) +
								';' + float(parcelleAqYield(parcelleAffichee).RUr) +
								';' + float(parcelleAqYield(parcelleAffichee).Hr) +
								';' + float(parcelleAqYield(parcelleAffichee).RUm) +
								';' + float(parcelleAqYield(parcelleAffichee).Hm) +
								';' + float(parcelleAqYield(parcelleAffichee).evaporation) +
								';'	+ float(parcelleAqYield(parcelleAffichee).getTranspirationMax()) +
								';' + float(parcelleAqYield(parcelleAffichee).transpirationW) +
								';' + float(parcelleAqYield(parcelleAffichee).transpirationR) +
								';' + float(parcelleAqYield(parcelleAffichee).getTR_M()) +
								';' + sommeDrain +
								';' + sommeEva +
								';' + float(parcelleAqYield(parcelleAffichee).getTmin());			
			return data;		 		
	 	}else{
	 		return "";	
	 	}		 		 	
	 }
	 
	/*
	 * @Overwrite
	 */
	 string ecritureFinAnnuelle{
//		 	if(parcelleAffichee != nil){
			string data <-  	'' + (dateCour.annee) +		
								';' + float(parcelleAqYield(parcelleAffichee).getRendementDerniereCulture()) +							
								';' + sommeETP +
								';' + sommeP +
								';' + sommeIrr +
								';' + sommeRuis +
								';' + sommeTM +
								';' + sommeTRr +
								';' + sommeEva +
								';' + sommeDrain +
								';' + sommeEvaPrime +
								';' + sommeCap +
								';' + sommeDeltaRH;			 		
	 		return data;	
//		 	}else{
//		 		return "";	
//		 	}		 			 		
	
		 		
	 }	

	/*
	 * @Private
	 */		 
	 action miseAzero{		
 		sommeETP <- 0.0;
		sommeP <- 0.0;
		sommeIrr <- 0.0;
		sommeRuis <- 0.0;
		sommeTM <- 0.0;
		sommeTRr <- 0.0;
		sommeEva <- 0.0;
		sommeDrain <- 0.0;
		sommeEvaPrime <- 0.0;
		sommeCap <- 0.0;
		sommeDeltaRH <- 0.0;		 	
	 }		 			 
}

