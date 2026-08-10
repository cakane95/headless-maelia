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
 *  Author:  Renaud Misslin
 *  Description: Cree 2 fichiers de resultats
 */


model resultatsAveyronUneParcelle_AqYield_N

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
    action initialisationEcritureFichiersUneParcelle_AqYield_N{
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichier de résultats pour une Parcelle (AqYield N)';        
        
        create resultatsAveyronUneParcelle_AqYield_N number: 1{
            do initialisation();
            add self to: listesFichiersAcreer;
        }
    }            
}


species resultatsAveyronUneParcelle_AqYield_N parent: ecritureResultats{

    /*
     * @Overwrite
     */
     string initialisationJournalier{
         string detail <- 'Annee : ' + anneeDebutSimulation + '\nCulture : ' + rotationForceeParcelle + '\nSol : ' + typeDeSolForceParcelle + '\nCoordonées : ' + centroid(parcelleAqYield(first(listeParcelles))) + '\nProfondeur du sol : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.profondeurMax + '\nTaux argile : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.tauxArgile + '\nTaux graviers : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.tauxGravier + '\nPIRm : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.permeabiliteSol + '\nCstru : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.noteQualiteStructureSol + '\nRUt : ' + parcelleAqYield(first(listeParcelles)).ilot_app.sol.reservePotentielleUtileMax + '\nPente : ' + parcelleAqYield(first(listeParcelles)).ilot_app.penteAssociee + '\n\n';
        
        nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/modeleAqYield_Journalier'+ nomDeLaSimulation + '.csv';
        string dataJournaliere <- '\ndate;temp_moy;pluie;irrigation;etp;RUw;RUm;RUr;RUs;drain;Hw;Hm;Hr;Hs;Ccap;capilarite;apportEnEauUtile;evaporation;transpirationW;transpirationR;coefRuissellement;HOw;HOr;HOp;RHOw;RHOr;RHOp;repart_HO;profR;flux_RHOwr;flux_RHOrp;drain_RHOp;QNinitialeJ_w;QNinitialeJ_r;QNinitialeJ_p;QNapresConsoJ_w;QNapresConsoJ_r;QNfinaleJ_w;QNfinaleJ_r;QNfinaleJ_p;QNsol_tot;fluxN_wr;fluxN_rp;fluxN_lixiviation;QNapport;QNdispoFerti;precipitationDepuisApportN;NminMO_cumul;Jnorma;Nhuma_cm;Nres;DNres;Nbio;DNbio;NminRes;NminRes_cumul;Nmin_total;Nmin_totalPrec;frein;sommeTranspirationR;sommeTranspirationMax;sommeDegresJourCulture;sommeDegresJourCulturePrec;sommeDegresJourCultureFinFrein;QN_demande_prec;QN_demande_cumul_prec;QN_acquis_fin_frein;QN_demande_fin_frein;cas_demande_azote;dKc;Kc;echV;satisf_hydrique;travail_sol;LJ;QN_pot;QN_demande;QN_demande_cumul;QN_demande_stressH;QN_demande_stressH_cumul;QN_acquis;QN_acquis_cumul;meanINN10j;effetN_kc;Chum;Nhum;Semi;espece;fHum_mo;fTemp_mo;fHum_res;fTemp_res;ISH10;N_N2_denit;N_N2O_nit;N_N2O_denit;N_N2O_tot;N_NH3_direct;N_NH4_au_sol;N_NH3_sol;N_NH3_tot;days_notillage;QNapport_surface_sol;eqCO2_synth;eqCO2_emNC;eqCO2_emN;eqCO2_tot;eqCO2_tot_sansC;SOC_perc;OM_perc;SOC_Clay_ratio;N_losses;N_lixiv_cumul;NNH3tot_cumul;QNapp_min;QNapp_pro;NNH3tot_d;tps_travail_Ferti_cumul\n';
        return dataJournaliere;
     }

    /*
     * @Overwrite
     */
     string ecritureJournaliere{
//             int indiceDebut <- 0;
//             int indiceFin <- 0;
//             ask(date){
//                 indiceDebut <- convertirDateEnIndice(jourAConvertir:25, moisAConvertir:10, anneeAConvertir: 2000);
//                 indiceFin <- convertirDateEnIndice(jourAConvertir:31, moisAConvertir:12, anneeAConvertir: 2001);
//             }
        // variable ITK
        bool isSemi <- false;
        if (first(list(cultureAqYieldNC)) != nil) {
            isSemi <- true;
        }
        
        
        // Variables cultureAqYield
        float cultureAqYield_frein <- 0.0;
        float cultureAqYield_sommeTranspirationR <- 0.0;
        float cultureAqYield_sommeTranspirationMax <- 0.0;
        float cultureAqYield_sommeDegresJourCulture <- 0.0;
        float cultureAqYield_sommeDegresJourCulturePrec <- 0.0;
        float cultureAqYield_sommeDegresJourCultureFinFrein <- 0.0;
        float cultureAqYield_QN_demande_prec <- 0.0;
        float cultureAqYield_QN_demande_cumul_prec <- 0.0;
        float cultureAqYield_QN_acquis_fin_frein <- 0.0;
        float cultureAqYield_QN_demande_fin_frein <- 0.0;
        int cultureAqYield_cas_demande_azote <- 0;
        string cultureAqYield_espece <- 'none';
        float cultureAqYield_dKc <- 0.0;
        float cultureAqYield_Kc <- 0.0;
        float cultureAqYield_echV <- 0.0;
        float cultureAqYield_indiceSatifactionHydrique <- 0.0;
        
        float cultureAqYield_QN_demande_jour <- 0.0;
        float cultureAqYield_QN_demande_cumul <- 0.0;
        float cultureAqYield_QN_demande_stressH_jour <- 0.0;
        float cultureAqYield_QN_demande_stressH_cumul <- 0.0;               
        float cultureAqYield_QN_acquis <- 0.0;
        float cultureAqYield_QN_acquis_cumul <- 0.0;
        float cultureAqYield_meanINN10j <- 0.0;
        float cultureAqYield_effetN_kc <- 0.0;
        float cultureAqYield_dkcMAX_to_suppr <- 0.0;
        float cultureAqYield_ISH10 <- 0.0;
        
        if (first(list(cultureAqYieldNC)) != nil) {
            cultureAqYield_frein <- first(list(cultureAqYieldNC)).frein;
            cultureAqYield_sommeTranspirationR <- first(list(cultureAqYieldNC)).sommeTranspirationR;
            cultureAqYield_sommeTranspirationMax <- first(list(cultureAqYieldNC)).sommeTranspirationMax;            
            cultureAqYield_sommeDegresJourCulture <- first(list(cultureAqYieldNC)).sommeDegresJourCulture;
            cultureAqYield_sommeDegresJourCulturePrec <- first(list(cultureAqYieldNC)).sommeDegresJourCulturePrec;
            cultureAqYield_sommeDegresJourCultureFinFrein <- first(list(cultureAqYieldNC)).sommeDegresJourCultureFinFrein;
            
            cultureAqYield_QN_demande_jour <- first(cultureAqYieldNC).QN_demande_jour;
            cultureAqYield_QN_demande_cumul <- first(cultureAqYieldNC).QN_demande_cumul;
            cultureAqYield_QN_demande_stressH_jour <- first(cultureAqYieldNC).QN_demande_jour_stressH;
            cultureAqYield_QN_demande_stressH_cumul <- first(cultureAqYieldNC).QN_demande_cumul_stressH;            
            
            cultureAqYield_QN_acquis <- first(cultureAqYieldNC).QN_acquis;
            cultureAqYield_QN_acquis_cumul <- first(cultureAqYieldNC).QN_acquis_cumul;
            cultureAqYield_meanINN10j <- first(cultureAqYieldNC).meanINN10j;
            cultureAqYield_effetN_kc <- first(cultureAqYieldNC).effetN_kc;
            
            cultureAqYield_QN_demande_prec <- 0.0;
            cultureAqYield_QN_demande_cumul_prec <- first(cultureAqYieldNC).QN_demande_cumul_prec;
            cultureAqYield_QN_acquis_fin_frein <- first(cultureAqYieldNC).QN_acquis_fin_frein;
            cultureAqYield_QN_demande_fin_frein <- first(cultureAqYieldNC).QN_demande_fin_frein;
            cultureAqYield_cas_demande_azote <- 0;
            
            
            // Plante
            cultureAqYield_espece <- first(list(cultureAqYieldNC)).espece.idEspeceCultivee;
            cultureAqYield_dKc <- first(list(cultureAqYieldNC)).dKc_save;
            cultureAqYield_Kc <- first(list(cultureAqYieldNC)).kc;
            cultureAqYield_echV <- first(list(cultureAqYieldNC)).echV;
            cultureAqYield_indiceSatifactionHydrique <- first(list(cultureAqYieldNC)).indiceSatifactionHydrique;
            cultureAqYield_dkcMAX_to_suppr <- first(cultureAqYieldNC).dkcMAX_to_suppr;
            cultureAqYield_ISH10 <- first(cultureAqYieldNC).ISH10;
            
        }
//         if(parcelleAffichee != nil /*and dateCour.indiceDate >= indiceDebut and dateCour.indiceDate <= indiceFin*/){
//             if(parcelleAffichee != nil and parcelleAffichee.cultureParcelle != nil){
//             if(parcelleAffichee != nil){
            
            
            
            string data <-      string(dateCour.jour) + '/' + (dateCour.mois) + '/' + (dateCour.annee) +
                                
                                // Variables météo et irrigation
                                ';' + parcelleAqYield(first(listeParcelles)).getTmoy() +
                                ';' + parcelleAqYield(first(listeParcelles)).getPluie() +
                                ';' + parcelleAqYield(first(listeParcelles)).getVolumeIrrigueReel() +
                                ';' + parcelleAqYield(first(listeParcelles)).ilot_app.meteo.etp +
                                
//                                // Variables parcelleAqYield
//                                ';' + dateCour.longueurDuJour +
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
                                
                                ';' + parcelleAqYieldNC(first(listeParcelles)).HOw +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).HOr +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).HOp +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).RHOw +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).RHOr +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).RHOp +
                                
                                ';' + parcelleAqYieldNC(first(listeParcelles)).repart_HO +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).profR +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).flux_RHOwr +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).flux_RHOrp +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).drain_RHOp +
                                
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNinitialeJ_w +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNinitialeJ_r +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNinitialeJ_p +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapresConsoJ_w +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapresConsoJ_r +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNfinaleJ_w +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNfinaleJ_r +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNfinaleJ_p +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNsol_tot +
                                
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fluxN_wr +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fluxN_rp +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fluxN_lixiviation +
                                
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapport +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNdispoFerti +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).precipitationDepuisApportN +                                

                                ';' + parcelleAqYieldNC(first(listeParcelles)).NMOmin +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Jnorma +
                                ';' + sum(parcelleAqYieldNC(first(listeParcelles)).Nhuma_cm) +  ///--- ajouter sum
                                
                                ';' + sum(parcelleAqYieldNC(first(listeParcelles)).Nres) + ///--- ajouter sum
                                ';' + sum(parcelleAqYieldNC(first(listeParcelles)).DNres) + ///--- ajouter sum
                                ';' + sum(parcelleAqYieldNC(first(listeParcelles)).Nbio) + ///--- ajouter sum
                                ';' + sum(parcelleAqYieldNC(first(listeParcelles)).DNbio) + ///--- ajouter sum

                                ';' + parcelleAqYieldNC(first(listeParcelles)).NminRes +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).NminRes_cumul +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Nmin_total +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Nmin_totalPrec +
                                
                                // Variables cultureAqYield
                                ';' + cultureAqYield_frein +
                                ';' + cultureAqYield_sommeTranspirationR +
                                ';' + cultureAqYield_sommeTranspirationMax +
                                ';' + cultureAqYield_sommeDegresJourCulture +
                                ';' + cultureAqYield_sommeDegresJourCulturePrec +
                                ';' + cultureAqYield_sommeDegresJourCultureFinFrein +
                                ';' + cultureAqYield_QN_demande_prec +
                                ';' + cultureAqYield_QN_demande_cumul_prec +
                                ';' + cultureAqYield_QN_acquis_fin_frein +
                                ';' + cultureAqYield_QN_demande_fin_frein +
                                ';' + cultureAqYield_cas_demande_azote +
                                
                                // Plante
                                ';' + cultureAqYield_dKc +
                                ';' + cultureAqYield_Kc +
                                ';' + cultureAqYield_echV +
                                ';' + cultureAqYield_indiceSatifactionHydrique +
                                
                                // ITK
                                ';' + first(listeParcelles).prof_w_sol + 
                                
                                // Date
                                ';' + first(dateCourante).longueurDuJour +
                                
                                // Acquisition de N par la plante
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QN_pot +
                                ';' + cultureAqYield_QN_demande_jour +
                                ';' + cultureAqYield_QN_demande_cumul +
                                ';' + cultureAqYield_QN_demande_stressH_jour +
                                ';' + cultureAqYield_QN_demande_stressH_cumul +                                                                
                                ';' + cultureAqYield_QN_acquis +
                                ';' + cultureAqYield_QN_acquis_cumul +
                                ';' + cultureAqYield_meanINN10j +
                                ';' + cultureAqYield_effetN_kc +
                                // SOC variables
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Chum +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Nhum +
                                // String (pour faciliter le traitement sur R, les strings sont mises à la fin)
                                ';' + isSemi +
                                ';' + cultureAqYield_espece +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fonction_hum_mo +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fonction_temp_mo +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fonction_hum_res +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fonction_temp_res +
                                ';' + cultureAqYield_ISH10 +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_n2_denit +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_n2o_nit +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_n2o_denit +
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_n2o_tot+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3_pro_pot_sol+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3_pro+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3_tot+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).nb_of_days_wo_tillage+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapport_after_volat+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).eqCO2_synthesis+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).eqCO2_emissions_NC+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).eqCO2_emissions_N+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).eqCO2_total+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).eqCO2_total_sansC+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).SOC_perc+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).OM_perc+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).SOC_Clay_ratio+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).Nlosses+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).fluxN_lixiviation_cumul_total+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3_tot_cumul_tot+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapport_min2+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).QNapport_pro2+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).N_nh3_tot2+
                                ';' + parcelleAqYieldNC(first(listeParcelles)).tps_travail_Ferti_cumul + "\n";                                   
            return data;                 
//         }else{
//             return "pas de parcelle";    
//         }                      
     }             
}


 
