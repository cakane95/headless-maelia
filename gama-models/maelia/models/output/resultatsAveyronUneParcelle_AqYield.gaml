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


model resultatsAveyronUneParcelle_AqYield

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
import "../modeleAgricole/Cultures/cultureAqYield.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"  
import "../modeleNormatif/pointDeReference.gaml"
import "ecritureResultats.gaml"

global{
	action initialisationEcritureFichiersUneParcelle_AqYield{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichier de résultats pour une Parcelle (AqYield )';		
		
		create resultatsAveyronUneParcelle_AqYield number: 1{
			do initialisation();
			add self to: listesFichiersAcreer;
		}
	}			
}


species resultatsAveyronUneParcelle_AqYield parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationJournalier{
	 	string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + rotationForceeParcelle + '\nSol : ' + typeDeSolForceParcelle + '\nCoordonées : ' + centroid(parcelleAqYield(first(listeParcelles))) + '\nProfondeur du sol : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.profondeurMax + '\nTaux argile : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.tauxArgile + '\nTaux graviers : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.tauxGravier + '\nPIRm : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.permeabiliteSol + '\nCstru : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.noteQualiteStructureSol + '\nRUt : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.reservePotentielleUtileMax + '\nPente : ' + parcelleAqYield(first(listeParcelles)).ilot_app.penteAssociee + '\n\n';
		
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Journalier'+ nomDeLaSimulation + '.csv';
		string dataJournaliere <- '' + detail + '\ndate;temp_moy;pluie;irrigation;etp;RUw;RUm;RUr;RUs;drain;Hw;Hm;Hr;Hs;Ccap;capilarite;apportEnEauUtile;evaporation;transpirationW;transpirationR;coefRuissellement;HOw;HOr;HOp;RHOw;RHOr;RHOp;repart_HO;profR;flux_RHOwr;flux_RHOrp;drain_RHOp;QNinitialeJ_w;QNinitialeJ_r;QNinitialeJ_p;QNapresConsoJ_w;QNapresConsoJ_r;QNfinaleJ_w;QNfinaleJ_r;QNfinaleJ_p;QNsol_tot;fluxN_wr;fluxN_rp;fluxN_lixiviation;QNapport;QNdispoFerti;precipitationDepuisApportN;NminMO_cumul;NminMO;Jnorma;NHum;Nres;DNres;Nbio;DNbio;DNhum;NminRes;NminRes_cumul;Nbio;Nmin_total;Nmin_totalPrec;frein;rendement;sommeTranspirationR;sommeTranspirationMax;sommeDegresJourCulture;sommeDegresJourCulturePrec;sommeDegresJourCultureFinFrein;QN_demande;QN_acquis_cumul;QN_demande_cumul_prec;QN_acquis_fin_frein;cas_demande_azote;espece;dKc;Kc;echV;satisf_hydrique;travail_sol;Semi;LJ';
		return dataJournaliere;
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
		// variable ITK
		bool isSemi <- false;
		if (first(list(cultureAqYield)) != nil) {
			isSemi <- true;
		}
		
		
		// Variables cultureAqYield
		float cultureAqYield_frein <- 0.0;
		float cultureAqYield_sommeTranspirationR <- 0.0;
		float cultureAqYield_sommeTranspirationMax <- 0.0;
		float cultureAqYield_sommeDegresJourCulture <- 0.0;
		float cultureAqYield_sommeDegresJourCulturePrec <- 0.0;
		float cultureAqYield_sommeDegresJourCultureFinFrein <- 0.0;
		float cultureAqYield_QN_demande_jour <- 0.0;
		float cultureAqYield_QN_acquis_cumul <- 0.0;
		float cultureAqYield_QN_demande_cumul_prec <- 0.0;
		float cultureAqYield_QN_acquis_fin_frein <- 0.0;
		int cultureAqYield_cas_demande_azote <- 0;
		string cultureAqYield_espece <- 'none';
		float cultureAqYield_dKc <- 0.0;
		float cultureAqYield_Kc <- 0.0;
		float cultureAqYield_echV <- 0.0;
		float cultureAqYield_indiceSatifactionHydrique <- 0.0;
		
		if (first(list(cultureAqYield)) != nil) {
			cultureAqYield_frein <- first(list(cultureAqYield)).frein;
			cultureAqYield_sommeTranspirationR <- first(list(cultureAqYield)).sommeTranspirationR;
			cultureAqYield_sommeTranspirationMax <- first(list(cultureAqYield)).sommeTranspirationMax;
			cultureAqYield_sommeDegresJourCulture <- first(list(cultureAqYield)).sommeDegresJourCulture;
			cultureAqYield_sommeDegresJourCulturePrec <- first(list(cultureAqYield)).sommeDegresJourCulturePrec;
			cultureAqYield_sommeDegresJourCultureFinFrein <- first(list(cultureAqYieldNC)).sommeDegresJourCultureFinFrein;
			cultureAqYield_QN_demande_jour <- 0.0;
			cultureAqYield_QN_acquis_cumul <- 0.0;
			cultureAqYield_QN_demande_cumul_prec <- 0.0;
			cultureAqYield_QN_acquis_fin_frein <- 0.0;
			cultureAqYield_cas_demande_azote <- 0;
			
			// Plante
			cultureAqYield_espece <- first(list(cultureAqYield)).espece.idEspeceCultivee;
			cultureAqYield_dKc <- first(list(cultureAqYield)).dKc_save;
			cultureAqYield_Kc <- first(list(cultureAqYield)).kc;
			cultureAqYield_echV <- first(list(cultureAqYield)).echV;
			cultureAqYield_indiceSatifactionHydrique <- first(list(cultureAqYield)).indiceSatifactionHydrique;
		}
//	 	if(parcelleAffichee != nil /*and dateCour.indiceDate >= indiceDebut and dateCour.indiceDate <= indiceFin*/){
//		 	if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle != nil){
//		 	if(parcelleAffichee != nil){
			
			
			
			string data <-  	string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
								
								// Variables météo et irrigation
								';' + parcelleAqYield(first(listeParcelles)).getTmoy() +
								';' + parcelleAqYield(first(listeParcelles)).getPluie() +
								';' + parcelleAqYield(first(listeParcelles)).getVolumeIrrigueReel() +
								';' + parcelleAqYield(first(listeParcelles)).ilot_app.meteo.etp +
								
//								// Variables parcelleAqYield
//								';' + dateCour.longueurDuJour +
								';' + parcelleAqYield(first(listeParcelles)).RUw +
								';' + parcelleAqYield(first(listeParcelles)).RUm +
								';' + parcelleAqYield(first(listeParcelles)).RUr +
								';' + parcelleAqYield(first(listeParcelles)).RUs +
								';' + parcelleAqYield(first(listeParcelles)).calculEcoulementEauSouterraine() +
								';' + parcelleAqYield(first(listeParcelles)).Hw +
								';' + parcelleAqYield(first(listeParcelles)).Hm +
								';' + parcelleAqYield(first(listeParcelles)).Hr +
								';' + parcelleAqYield(first(listeParcelles)).Hs +
								';' + parcelleAqYield(first(listeParcelles)).Ccap +
								';' + parcelleAqYield(first(listeParcelles)).capilarite +
								
								';' + parcelleAqYield(first(listeParcelles)).apportEnEauUtile +
								';' + parcelleAqYield(first(listeParcelles)).evaporation +
								';' + parcelleAqYield(first(listeParcelles)).transpirationW +
								';' + parcelleAqYield(first(listeParcelles)).transpirationR +
								';' + parcelleAqYield(first(listeParcelles)).coefRuissellement +
								
								';' + 0.0 + //parcelleAqYield(first(listeParcelles)).HOw +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).HOr +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).HOp +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).RHOw +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).RHOr +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).RHOp +
								
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).repart_HO +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).profR +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).flux_RHOwr +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).flux_RHOrp +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).drain_RHOp +
								
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNinitialeJ_w +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNinitialeJ_r +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNinitialeJ_p +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNapresConsoJ_w +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNapresConsoJ_r +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNfinaleJ_w +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNfinaleJ_r +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNfinaleJ_p +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNsol_tot +
								
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).fluxN_wr +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).fluxN_rp +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).fluxN_lixiviation +
								
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNapport +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).QNdispoFerti +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).precipitationDepuisApportN +								

								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).NminMO_cumul +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).NminMO +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Jnorma +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).NHum +
								
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Nres +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).DNres +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Nbio +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).DNbio +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).DNhum +

								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).NminRes +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).NminRes_cumul +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Nbio +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Nmin_total +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).Nmin_totalPrec +
								';' + 0.0 + // parcelleAqYield(first(listeParcelles)).calculRendement() +
								
								// Variables cultureAqYield
								';' + cultureAqYield_frein +
								';' + cultureAqYield_sommeTranspirationR +
								';' + cultureAqYield_sommeTranspirationMax +
								';' + cultureAqYield_sommeDegresJourCulture +
								';' + cultureAqYield_sommeDegresJourCulturePrec +
								';' + cultureAqYield_sommeDegresJourCultureFinFrein +
								';' + cultureAqYield_QN_demande_jour +
								';' + cultureAqYield_QN_acquis_cumul +
								';' + cultureAqYield_QN_demande_cumul_prec +
								';' + cultureAqYield_QN_acquis_fin_frein +
								';' + cultureAqYield_cas_demande_azote +
								
								// Plante
								';' + cultureAqYield_espece +
								';' + cultureAqYield_dKc +
								';' + cultureAqYield_Kc +
								';' + cultureAqYield_echV +
								';' + cultureAqYield_indiceSatifactionHydrique +
								
								// ITK
								';' + first(listeParcelles).prof_w_sol + 
								';' + isSemi +
								
								// Date
								';' + first(dateCourante).longueurDuJour;

			return data;		 		
//	 	}else{
//	 		return "pas de parcelle";	
//	 	}		 		 	
	 }			 
}

