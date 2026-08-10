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
 *  ecritureResultats
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model ecritureResultats

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleNormatif/uniteDeDefinitionDuVP.gaml"
import "../modeleHydrographique/canaux.gaml"
import "resultatsTempsSimulation.gaml"
import "resultatsModeleAveyron.gaml"
import "resultatsPrelevements.gaml"
import "resultatsAssolement_itk.gaml"
import "resultatsAssolement_espece.gaml"
import "resultatsAssolement_SDC.gaml"
import "resultatsFractionSolNu.gaml"
import "resultatsRDT_itk.gaml"
import "resultatsRDT_sol_itk.gaml"
import "resultatsRDT_espece.gaml"
import "resultatsRDT_parcelle_espece.gaml"
import "resultatsRDT_exploitation_espece.gaml"
import "resultatsAssolementParcelles.gaml"
import "resultatsDebistSTH.gaml"
import "resultatsDebitPourCalibration.gaml"
import "inputSwatGw.gaml"
import "inputSwatHru.gaml"
import "inputSwatRte.gaml"
import "inputSwatSol.gaml"
import "inputSwatSub.gaml"
import "resultatsSwatHRU.gaml"
import "resultatsSwatSW.gaml"
import "resultatsSwatPhaseSolZH.gaml"
import "resultatsSwatPhaseRoutageZH.gaml"
import "resultatsSwatNeigeHRU.gaml"
import "resultatsSwatBandeAltitude.gaml"
import "resultatsSIR.gaml"
import "resultatsAS.gaml"
import "resultatsAS_HRU.gaml"
import "resultatsAS_HRU_RPG.gaml"
import "resultatsAS_debit.gaml"
import "resultatsRetenuesPrelevementReelsJour.gaml"
import "resultatsRetenuesVolumeActuelJour.gaml"
import "resultatsPrelevements_AS.gaml"
import "resultats_IrrParAgri.gaml"
import "resultatsTravail.gaml"
import "resultatsTravailParTypeExploitation.gaml"
import "resultatsTravail_itk.gaml"
import "resultatsTravail_espece.gaml"
import "resultatsTravail_Labour.gaml"
import "resultatsTravail_RepriseLabour.gaml"
import "resultatsTravail_Semis.gaml"
import "resultatsTravail_Recolte.gaml"
import "resultatsTravail_Binage.gaml"
import "resultatsTravail_Irrigation.gaml"
import "resultatsTravail_Ferti.gaml"
import "resultatsTravail_Phyto.gaml"
import "resultatsStrategieTemp.gaml"
import "resultatsBilanExploitation.gaml"
import "ZH_resultatsMaisEnsilage.gaml"
import "ZH_resultatsPrelevements.gaml"
import "resultatsPrelevements_sol_itk.gaml"
import "resultatsPrelevements_sol_espece.gaml"
import "resultatsPrelevements_ZA_espece.gaml"
import "resultatsPrelevements_ZA_sol_espece.gaml"
import "resultatsPrelevements_espece.gaml"
import "ZA_resultatsPrelevements.gaml"
import "PARCELLES_bilanIrrigAnnuel.gaml"
import "resultatsRestrictions.gaml"
import "resultatsPrelevementsDetails.gaml"
import "resultatsPrelevementsDetails_onList.gaml"
import "resultatsDrainIlot.gaml"
import "resultatsDrainIlotMensuel.gaml"
import "resultatsDrainIlotBimensuel.gaml"
import "resultatsDrainIlot_ITK_ZH.gaml"
import "resultatsCanaux.gaml"
import "resultatsGestionnaireDeBarrage.gaml"
import "resultatsECO_espece.gaml"
import "resultatsECO_itk.gaml"
import "resultatsECO_exploitationTypes.gaml"
import "resultatsECO_exploitationDetail.gaml" //
import "resultatsECO_SDCRef_Donnee.gaml"
import "resultatsECO_SDCRef_FonctionCroyances.gaml"
import "resultatsECO_coutIrrigationIlot.gaml"
import "getClimatParZH.gaml"
import "resultatsValidationHerbSim.gaml"
import "resultatsValidationHerbSimNC.gaml"
import "resultatsHauteurNappes.gaml"
import "resultatsDrainHRU.gaml"
import "resultatsDrainIlotDetail.gaml"
import "resultatsDrainIlotDetailMensuel.gaml"
import "resultatsDrainIlotDetailBimensuel.gaml"
import "resultatsRechargeRetenues.gaml"
import "resultatsDetailsGroupeIrrigation.gaml"
import "resultatsPrelevements_decoupage_itk.gaml"
import "resultatsPrelevements_decoupage_typePPA.gaml"
import "resultatsUtilisationQuota.gaml"
import "resultatsUtilisationQuotaParAgri.gaml"
import "resultatsDebitBVe.gaml"
import "selectionOutput.gaml"
import "resultatsSuiviITK.gaml"
import "resultatsSuiviITKParParcelle.gaml"
import "resultatsSuiviITKParParcelleTemps.gaml"
import "resultatsSuiviITKParParcelle_humidite.gaml"
import "resultatsSuiviSemisRecolteParParcelle.gaml"
import "resultatsSuivi_ajout_pools_residus.gaml" // NR pools residus
import "resultatsRUEdesSOLS.gaml"
import "resultatsDebugSortieZH.gaml"
import "resultatsAS_m3.gaml"
import "resultatsDemoChambreAlsace.gaml"
import "resultatsIrrigation_parcelle.gaml"
import "resultatsModeleAqYield.gaml"
import "resultatsModeleAqYield_light.gaml"
import "resultatsModeleAqYield_ITK_ZH.gaml"
import "resultatsSuiviMemoireAgri.gaml"
import "resultatsIrrigation_debug.gaml"
import "resultatsAveyronUneParcelle_AqYield_N.gaml"
import "resultatsAveyronUneParcelle_AqYield.gaml"
import "resultatsRecolteParcelles.gaml"
import "resultats_N_lixi_typeExploitation.gaml"
import "resultats_N_total_eqC02_typeExploitation.gaml"
import "resultats_N_lixi_Parcelles.gaml"
import "resultats_N_GES_Parcelles.gaml"
import "resultats_N_NH3_Parcelles.gaml"
import "resultats_N_Cstock_Parcelles.gaml"
import "resultats_prixFerti_Parcelles.gaml"
import "resultats_tpsWFerti_Parcelles.gaml"
import "resultats_N_SOC_Parcelles.gaml"
import "resultats_N_N2O_Parcelles.gaml"
import "resultats_N_eqCO2_synthesis_Parcelles.gaml"
import "resultats_N_eqCO2_Nmineral_synthesis.gaml"
import "resultats_N_eqCO2_emissions_NC_Parcelles.gaml"
import "resultats_N_engrais_utilises_territoire.gaml"
import "resultats_N_engrais_utilises_exploitation.gaml"
import "resultats_N_Nmin_som_res_Parcelles.gaml"
import "resultats_N_nSemisCultures_Parcelles.gaml"
import "resultats_N_nApportProduits_Parcelles.gaml"
import "resultats_N_quantitesProduits_Parcelles.gaml"
import "resultats_N_QNfix_Parcelles.gaml"
import "inputs_sol_Parcelles.gaml"
import "resultats_N_exportation_pailles.gaml"
import "resultats_N_Nmin_total_Parcelles.gaml"
import "sortiesEau.gaml"
import "sortiesAzote.gaml"
import "sortiesCarboneGES.gaml"
import "sortiesRetenues.gaml"
import "sortiesBarrages.gaml"
import "resultats_iBIO.gaml"

import "inputs_ilot_zoneMeteo.gaml"

global{
	list<ecritureResultats> listesFichiersAcreer <- [];
	
	//string fichierTypeExploitation <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/exploitations.csv';
	
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Permet de mettre des entetes a chaque colone du fichier csv
	 */
	action initialisationEcritureFichiers{	
		do ecritureConsolePourDebug isAfficherTemps: false chaineAEcrire: '\n*********** OUTPUT ***********';	
// 		if(TempsSimulation){do initialisationEcritureFichiersTempsSimulation();	}
		if(nomDecoupageZonePourLectureFichiers = DecoupageAveyron){			
//			do initialisationEcritureFichiersSIR();
//			do initialisationEcritureFichiersStrategieTemp();
//			do initialisationEcritureFichiersMaisEnsilage();
//			do initialisationEcritureFichiersPARCELLESbilanIrrigAnnuel();
//          		do initialisationEcritureFichiersPrelevementsDetails();
//          		do initialisationEcritureFichiersPrelevementsDetail_onList();
//			do initialisationEcritureFichiersValidationHerbSim();
		}
			
		
		if(executerModeleHydrographique){
			if (DebistSTH){do initialisationEcritureFichiersDebistSTH();}
			if (Debit){do initialisationEcritureFichiersAS_debit();} //Debits au differents points DOE
			if(executerModeleNormatif){
				if(Restrictions){do initialisationEcritureFichiersRestrictions();}
			}
			if(RechargeRetenues){ do initialisationEcritureFichiersRechargeRetenues();}
			if(RetenuesVolumeActuelJour) {do initialisationEcritureFichiersRetenuesVolActuelJour(); do initialisationEcritureFichiersRetenuesPrelevementsReelsJour();}
			if(FluxSWAT_BVe){ 
				do initialisationEcritureFichiersAS();  // resAS pour HRU agricoles et HRU non agricoles, en [mm], pondéré par les surfaces des HRU  
				do initialisationEcritureFichiersAS_m3();  // idem en [m3], non pondéré
				//do initialisationEcritureFichiersAS_HRU();  // resAS pour HRU non agricoles [mm]
				//do initialisationEcritureFichiersAS_HRU_RPG(); // resAS pour HRU non agricoles [mm]
				//do initialisationEcritureFichiersDebugSortieZH();
			} //Fichier des valeurs de processus hydro/ZH
			if(hauteurNappes){ do initialisationEcritureFichiersHauteurNappes();}
			if (GetClimatParZH){do initialisationEcritureFichiersGetClimatParZH();}	
			if(isPrelevementEtRejetSimules and isCanaux and length(listeCanaux) > 0){
				if(Canaux){do initialisationEcritureFichiersCanaux();}
			}
			
		}
		if(executerModeleHydrographique and nomChoixModeleHydrographique = 'SWAT'){
//			do initialisationEcritureFichiersDrainHRU();
//			do initialisationEcritureFichiersInputSwatGW();
//			do initialisationEcritureFichiersInputSwatHRU();
//			do initialisationEcritureFichiersInputSwatRte();
//			do initialisationEcritureFichiersInputSwatSol();
//			do initialisationEcritureFichiersInputSwatSub();			
//			do initialisationEcritureFichiersSwatHRU();
//			do initialisationEcritureFichiersSwatSW();
//			do initialisationEcritureFichiersSwatPhaseSolZH();
			if (SWAT_PhaseRoutage){ do initialisationEcritureFichiersSwatPhaseRoutageZH();}
//			do initialisationEcritureFichiersSwatNeigeHRU();
//			do initialisationEcritureFichiersSwatBandeAltitude();
			if (debitBVe){ do initialisationEcritureFichiersDebitBVe();}
			if(sortieCalibration){do initialisationEcritureFichiersDebitPourCalibration();}
		}
									
//		
		if(isPrelevementEtRejetSimules and executerModeleAgricole){
			if(Prelevements){do initialisationEcritureFichiersPrelevements();}
			if(PrelevementsZH){do initialisationEcritureFichiersPrelevementsZH();}
			if(PrelevementsZA){do initialisationEcritureFichiersPrelevementsZA();}
			if(Prelevements_sol_itk){do initialisationEcritureFichiersPrelevements_sol_itk();}
			if(Prelevements_sol_espece){do initialisationEcritureFichiersPrelevements_sol_espece();}
			if(Prelevements_espece){do initialisationEcritureFichiersPrelevements_espece();}
			if(Prelevements_za_espece){do initialisationEcritureFichiersPrelevements_za_espece();}
			if(Prelevements_za_sol_espece){do initialisationEcritureFichiersPrelevements_za_sol_espece();}
			if(Prelevements_decoupage_itk){do initialisationEcritureFichiersPrelevements_decoupage_itk();}
			if(Prelevements_decoupage_typePPA){do initialisationEcritureFichiersPrelevements_decoupage_typePPA();}
			
			if (DetailsGroupeIrrigation){ do initialisationEcritureFichiersDetailsGroupeIrrigation(); } // debogage
			if irrigationDebug {do initialisationEcritureFichiersIrrigation_debug();} // debug JV 220321
			
			if(executerModeleNormatif){
				if(UtilisationQuota and !isEauDisponibleAgriInfinie ){
					do initialisationEcritureFichiersUtilisationQuota();
					do initialisationEcritureFichiersUtilisationQuotaParAgri();
				}
			}
		}
			
		
		if(IrrigationParAgri){ do initialisationEcritureFichiers_IrrParAgri();}
		if(prelevementParPPA){ do initialisationEcritureFichiersPrelevementsAS();}
		if(travailParAgri){ do initialisationEcritureFichiersTravail();}
		if(travailParTypeExploitation){ do initialisationEcritureFichiersTravailParTypeExploitation();}
		if(travailParAgri_Recolte){ do initialisationEcritureFichiersTravail_Recolte();}
		if(travailParAgri_Labour){ do initialisationEcritureFichiersTravail_Labour();}
		if(travailParAgri_RepriseLabour){ do initialisationEcritureFichiersTravail_RepriseLabour();}	
		if(travailParAgri_Semis){ do initialisationEcritureFichiersTravail_Semis();}	
		if(travailParAgri_Binage){ do initialisationEcritureFichiersTravail_Binage();}
		if(travailParAgri_Irrigation){ do initialisationEcritureFichiersTravail_Irrigation();}	
		if(travailParAgri_Ferti){ do initialisationEcritureFichiersTravail_Ferti();}
		if(travailParAgri_Phyto){ do initialisationEcritureFichiersTravail_Phyto();}
		if(travailParITK){ do initialisationEcritureFichiersTravail_itk();}
		if(travailParEspece){ do initialisationEcritureFichiersTravail_espece();}

		if(executerModeleAgricole){
			if (recolteParcelles){do initialisationEcritureFichiersresultatsRecolteParcelles();}
			if (Assolement_SDC){do initialisationEcritureFichiersAssolement_SDC();}
			if (Assolement_itk){do initialisationEcritureFichiersAssolement_itk();}
			if (Assolement_espece){do initialisationEcritureFichiersAssolement_espece();}
			if (Assolement_parcelle){do initialisationEcritureFichiersAssolementParcelles();}			
			if (FractionSolNu){do initialisationEcritureFichiersFractionSolNu();}
			if (RDT_itk){do initialisationEcritureFichiersRDT_itk();}
			if (RDT_sol_itk){do initialisationEcritureFichiersRDT_sol_itk();}
			if (RDT_espece){do initialisationEcritureFichiersRDT_espece();}
			if (RDT_parcelle_espece){do initialisationEcritureFichiersRDT_parcelle_espece();}
			if (RDT_exploitation_espece){do initialisationEcritureFichiersRDT_exploitation_espece();}
			if (ECO_espece){do initialisationEcritureFichiersECO_espece();}
			if (ECO_itk){do initialisationEcritureFichiersECO_itk();}
			if (ECO_exploitationType){do initialisationEcritureFichiersECO_exploitationType();}
			if (ECO_exploitationDetail){do initialisationEcritureFichiersECO_exploitationDetail();}
			if (nomChoixAssolement = 'Donnees') {
				if(ECO_SDCRef){do initialisationEcritureFichiersECO_SDCRef_Donnee();}
			}else{
				if(ECO_SDCRef){do initialisationEcritureFichiersECO_SDCRef_FonctionsCroyances();}
			}
			if (ECO_coutIrrigationIlot){do initialisationEcritureECO_coutIrrigationIlot();}
			if (DrainIlot){do initialisationEcritureFichiersDrainIlot();}
			if (DrainIlot_mois){do initialisationEcritureFichiersDrainIlotMensuel();}
			if (DrainIlot_quinzaine){do initialisationEcritureFichiersDrainIlotBimensuel();}
			if (DrainIlotDetail) {do initialisationEcritureFichiersDrainIlotDetail();}
			if (DrainIlotDetail_mois) {do initialisationEcritureFichiersDrainIlotDetailMensuel();}
			if (DrainIlotDetail_quinzaine) {do initialisationEcritureFichiersDrainIlotDetailBimensuel();}
			if (DrainIlot_ITK_ZH) {do initialisationEcritureFichiersDrainIlot_ITK_ZH();}
			if (BilanExploitation) { do initialisationEcritureFichiersBilanExploitation();}
			if (suiviOT){do initialisationEcritureFichiersSuiviITK();}
			if (suiviOTParParcelle){do initialisationEcritureFichiersSuiviITKParParcelle();}
			if (suiviOTParParcelleTemps){do initialisationEcritureFichiersSuiviITKParParcelleTemps();}
			if (suiviOTParParcelle_humidite){do initialisationEcritureFichiersSuiviITKParParcelle_humidite();}
			if (suiviSemisRecolteParParcelle){do initialisationEcritureFichiersSuiviSemisRecolteParParcelle();}
			if (suiviMemoireAgri){ do initialisationEcritureFichiersSuiviMemoireAgri();}
			if (variablesAqYieldSurParcellesSpecifiees){ do initialisationEcritureFichiersModeleAqYield();}
			if (variablesAqYieldSurParcellesSpecifiees_light){ do initialisationEcritureFichiersModeleAqYield_light();}
			if (aqYield_eva_trmax_trr_ITK_ZH){ do initialisationEcritureFichiersModeleAqYield_ITK_ZH();}			

			if (debugSortie1parcelleAqYield){ do initialisationEcritureFichiersUneParcelle_AqYield();}
			if (debugSortie1parcelleAqYield_N){ do initialisationEcritureFichiersUneParcelle_AqYield_N();}
			if (suivi_journalier_1parc_HerbSimNC){do initialisationEcritureFichiersValidationHerbSimNC();}
			
			if sortiesAqYieldNC {
				if (N_lixi_typeExploitation) { do initialisationEcritureFichiers_resultats_N_lixi_typeExploitation();}
				if (N_lixi_Parcelles) { do initialisationEcritureFichiersresultats_N_lixi_Parcelles();}
				if (N_total_eqC02_typeExploitation) { do initialisationEcritureFichiers_resultats_N_total_eqC02_typeExploitation();}
				if (N_GES_Parcelles) { do initialisationEcritureFichiersresultats_N_GES_Parcelles();}
				if (N_NH3_Parcelles) { do initialisationEcritureFichiersresultats_N_NH3_Parcelles();}
				if (N_Cstock_Parcelles) { do initialisationEcritureFichiersresultats_N_Cstock_Parcelles();}
				if (prixFerti_Parcelles) { do initialisationEcritureFichiersresultats_prixFerti_Parcelles();}
				if (tpsWFerti_Parcelles) { do initialisationEcritureFichiersresultats_tpsWFerti_Parcelles();}
				if (N_SOC_Parcelles) { do initialisationEcritureFichiersresultats_N_SOC_Parcelles();}
				if (N_N2O_Parcelles) { do initialisationEcritureFichiersresultats_N_N2O_Parcelles();}
				if (eqCO2_synthesis_Parcelles) { do initialisationEcritureFichierresultats_N_eqCO2_synthesis_Parcelles();}
				if (eqCO2_Nmineral_synthesis_Parcelles) { do initialisationEcritureFichierresultats_N_eqCO2_Nmineral_synthesis_Parcelles();}
				if(N_Nmin_total_Parcelles) { do initialisationEcritureFichiersresultats_N_Nmin_total_Parcelles();}
				
				if (engrais_utilises_territoire) { do initialisationEcritureFichierresultats_N_engrais_utilises_territoire();}
				if (engrais_utilises_exploitation) { do initialisationEcritureFichierresultats_N_engrais_utilises_exploitation();}
				if (eqCO2_emissions_NC_Parcelles) { do initialisationEcritureFichierresultats_N_eqCO2_emissions_NC_Parcelles();}
				if (N_Nmin_som_res_Parcelles) { do initialisationEcritureFichiersresultats_N_Nmin_som_res_Parcelles();}
				if (N_QNfix_Parcelles) { do initialisationEcritureFichiersresultats_N_QNfix_Parcelles();}
				if (N_varArbreRegression_nSemisCultures_Parcelles) { do initialisationEcritureFichiersresultats_N_nSemisCultures_Parcelles();}
				if (N_varArbreRegression_nApportProduits_Parcelles) { do initialisationEcritureFichiersresultats_N_nApportProduits_Parcelles();}
				if (N_varArbreRegression_quantitesProduits_Parcelles) { do initialisationEcritureFichiersresultats_N_quantitesProduits_Parcelles();}
				if (inputs_sols) { do initialisationEcritureFichiersinputs_sol_Parcelles();}
				if (lien_ilots_zoneMeteo) { do initialisationEcritureFichiersinputs_ilot_zoneMeteo();}
				if (N_exportation_pailles_Parcelles) { do initialisationEcritureFichiersresultats_N_exportation_pailles_Parcelles();} // Attention --> sortie journalière
			}

			if (RUEdesSOLs){ do initialisationEcritureFichiersRUEdesSOLS();}
			if(IrrigationParcelle){do initialisationEcritureFichiersIrrigation_parcelle();}
		}
		if(executerBarrage and executerModeleNormatif){
		 	if (GestionnaireDeBarrage)	{ do initialisationEcritureFichiersGestionnaireDeBarrage();}
		}
		if(demoChambreAlsace){
			do initialisationEcritureFichiersDemoChambreAlsace();
		}
		
		// JV 140422 nouvelles sorties
		if sorties_eau and (nomChoixModeleCroissancePlante=AqYield or nomChoixModeleCroissancePlante=AqYieldNC) {
			do initialisationEcritureFichiersSortiesEau();			
		}
		if nomChoixModeleCroissancePlante=AqYieldNC {
			if sorties_azote {do initialisationEcritureFichiersSortiesAzote();}
			if sorties_carboneGES {do initialisationEcritureFichiersSortiesCarboneGES();}
		}
		if sorties_retenues and executerModeleHydrographique {
			do initialisationEcritureFichiersSortiesRetenues();
		}
		if sorties_barrages and executerModeleNormatif {
			do initialisationEcritureFichiersSortiesBarrages();
		}
		
		if sorties_iBio {
			do initialisationEcritureFichiersresultats_iBIO();
		}
		
		if (nomChoixModeleCroissancePlante = "AqYieldNC") or (nomChoixModeleCroissancePlante = "HerbSimNC") {
			if suivi_ajout_pools_residus{
				do initialisationSuivi_ajouts_pools_residus();
			}
		}
	}

	/*
	 * *****************************************************************************************
	 * Publique
	 * Rempli journalierement les donnees indiquees dans le fichier csv
	 */	
	action ecritureFichiers{			
		ask listesFichiersAcreer{
			if (dateCour.annee >= anneeDebutSimulation){ // JV 090121: >= pour afficher dès le premier jour de simulation (01/08/anneeDebut)
				/*if(verboseMode){
					if(nomFichierJournalier!=""){write "appel ecriture sur " + nomFichierJournalier;}
					if(nomFichierDebutAnnuel!=""){write "appel ecriture sur " + nomFichierDebutAnnuel;}
					if(nomFichierFinAnnuel!=""){write "appel ecriture sur " + nomFichierFinAnnuel;}
				}*/
				do ecriture();
			} 
		}
	}	
}

species ecritureResultats{
	string nomFichierJournalier <- '';
	string nomFichierDebutAnnuel <- '';
	string nomFichierFinAnnuel <- '';
	string nomFichierMensuel <- '';
	string nomFichierBimensuel <- '';
	
	/*
	 * Publique
	 */
	 action initialisation{
	 	string dataJ <- initialisationJournalier();
	 	if(!empty(dataJ)){
	 		save dataJ to: nomFichierJournalier format: 'text' rewrite:true;
	 	}		 	
	 	string dataDA <- initialisationDebutAnnuel();
	 	if(!empty(dataDA)){
	 		save dataDA to: nomFichierDebutAnnuel format: 'text' rewrite:true;
	 	}
	 	string dataFA <- initialisationFinAnnuel();
	 	if(!empty(dataFA)){
	 		save dataFA to: nomFichierFinAnnuel format: 'text' rewrite:true;
	 	}		 	
	 	string dataM <- initialisationMensuelle();
	 	if(!empty(dataM)){
	 		save dataM to: nomFichierMensuel format: 'text' rewrite:true;
	 	}		 	
	 	string dataBM <- initialisationBimensuelle();
	 	if(!empty(dataBM)){
	 		save dataBM to: nomFichierBimensuel format: 'text' rewrite:true;
	 	}		 	
	 }
	 string initialisationJournalier{return "";}
	 string initialisationDebutAnnuel{return "";}
	 string initialisationFinAnnuel{return "";}
	 string initialisationMensuelle{return "";}
	 string initialisationBimensuelle{return "";}


	/*
	 * Publique
	 */
	 action ecriture{
	 	/*
	 	if(verboseMode){	 	
			if(nomFichierJournalier!=""){write "\tappel ecriture sur " + nomFichierJournalier;}
			if(nomFichierDebutAnnuel!=""){write "\tappel ecriture sur " + nomFichierDebutAnnuel;}
			if(nomFichierFinAnnuel!=""){write "\tappel ecriture sur " + nomFichierFinAnnuel;}
 		} 		
 		*/
	 	
 		// TODO: once all ecritureJournaliere return a list<string>, remove the cast
	 	string dataJ <- concatenate(list<string>(ecritureJournaliere()));
	 	if(!empty(dataJ)){
	 		save dataJ to: nomFichierJournalier format: 'text' rewrite: false;
	 	}
	 	
	 	if((dateCour).jour = 1 and (dateCour).mois = 1){
	 		string dataDA <- ecritureDebutAnnuelle();
		 	if(!empty(dataDA)){
		 		save dataDA to: nomFichierDebutAnnuel format: 'text' rewrite: false;
		 	}		 		
	 	}
	 	
	 	if (dateCour.jour = 31 and dateCour.mois in [1,3,5,7,8,10,12])
	 		or (dateCour.jour = 30 and dateCour.mois in [4,6,9,11])
	 		or (dateCour.jour = 28 and dateCour.mois = 2 and !dateCour.isAnneeBissextile(dateCour.annee))
	 		or (dateCour.jour = 29 and dateCour.mois = 2 and dateCour.isAnneeBissextile(dateCour.annee))	 		
	 	{
	 		string dataM <- ecritureMensuelle();
		 	if(!empty(dataM)){
		 		save dataM to: nomFichierMensuel format: 'text' rewrite: false;
		 		do miseAzero();
		 	}
	 	}
	 	
	 	if (dateCour.jour = 15
	 		or (dateCour.jour = 31 and dateCour.mois in [1,3,5,7,8,10,12])
	 		or (dateCour.jour = 30 and dateCour.mois in [4,6,9,11])
	 		or (dateCour.jour = 28 and dateCour.mois = 2 and !dateCour.isAnneeBissextile(dateCour.annee))
	 		or (dateCour.jour = 29 and dateCour.mois = 2 and dateCour.isAnneeBissextile(dateCour.annee)))	 		
	 	{
	 		string dataBM <- ecritureBimensuelle();
		 	if(!empty(dataBM)){
		 		save dataBM to: nomFichierBimensuel format: 'text' rewrite: false;
		 		do miseAzero();
		 	}
	 	}

	 	if((dateCour).jour = 31 and (dateCour).mois = 12){
	 		// TODO: once all ecritureJournaliere return a list<string>, remove the cast
	 		string dataFA <- concatenate(list<string>(ecritureFinAnnuelle()));
		 	if(!empty(dataFA)){
		 		save dataFA to: nomFichierFinAnnuel format: 'text' rewrite: false;
		 	}
	 		do miseAzero();
	 	}
	 	

	 }		 
	 action ecritureJournaliere{return "";}		
	 action ecritureDebutAnnuelle{return "";}		 
	 action ecritureFinAnnuelle{return "";}			 
	 action ecritureMensuelle{return "";}			 
	 action ecritureBimensuelle{return "";}			 
	 action miseAzero{}		
}
species decoupageSortie{
	string name;
}


