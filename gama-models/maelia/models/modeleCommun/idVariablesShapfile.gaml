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
 *  idVariablesShapfile
 *  Author: david
 *  Description: 
 */

model idVariablesShapfile

global{
 	// Comun
	string ID_ZH <- "ID_ZH" const: true;	
	string ID_CLC <- "ID_CLC" const: true;
	string TYPE_CLC <- "TYPE_CLC" const: true;
	string INDICE_CLC <- "INDICE_CLC" const: true;
	string ID_PAYSAGE <- "ID_PAYSAGE" const: true;	
	string TAUX <- "TAUX" const: true;	
	string CODE_INSEE <- "CODE_INSEE" const: true;	
	string NOM <- "NOM" const: true;	
	string CODE_DEPT <- "CODE_DEPT" const: true;	
	string ID_PDG <- "ID_PDG" const: true;	
	string ALTI_MOY <- "ALTI_MOY" const: true;	
	string PENTE_MOY <- "PENTE_MOY" const: true; 
	string PENTE_SWAT <- "PENTE_SWAT" const: true; 	
	string ID_PENTE <- "ID_PENTE" const: true; 
	string ID_ALTI <- "ID_ALTI" const: true;
		// SOL
	string ID_SOL <- "ID_SOL" const: true;	
	string STU_DOM <- "STU_DOM" const: true;	
	string ZONE_PEDO <- "ZONE_PEDO" const: true;
			
	// AqYield / OC
	// voir signification ici: https://bul.univ-lorraine.fr/index.php/s/g95zEAFoewFc6PJ (TODO: à déplacer sur site MAELIA)
	string P1 <- "P1" const: true;
	string PRO_OC <- "PRO_OC" const: true;	
	string W3 <- "W3" const: true;	
	string ARG_OC <- "ARG_OC" const: true;	
	string DAH_OC <- "DAH_OC" const: true;
	string ARG1 <- "ARG1" const: true;
	string ARG_DECA1 <- "ARG_DECA1" const: true;
	string DAH1 <- "DAH1" const: true;
	string CSTRU <- "CSTRU" const: true;	
//	string RUm <- "RUm" const: true;	
//	string RUw <- "RUw" const: true;	
	string PIRm <- "PIRM" const: true;	
//	string MIN_NA <- "MIN_NA" const: true;	
//	string DOS_IMAX <- "DOS_IMAX" const: true;	
//	string EFN <- "EFN" const: true;
	string KSAT1 <- "KSAT1" const: true;	
	string RUPRH1 <- "RUPRH1" const: true;	
	// supplémentaires AqYieldNC
	string CAL1 <- "CAL1" const:true;
	string CN1 <- "CN1" const:true;
	string EG1 <- "EG1" const: true;
	string HCC1 <- "HCC1" const: true;
	string HPFP1 <- "HPFP1" const: true;
	string MO1 <- "MO1" const: true;	
	string PH1 <- "PH1" const: true;	
	string SAB1 <- "SAB1" const: true;	
		
	// Hydro	
	string ID_RESS_ZH <- "ID_RESS_ZH" const: true;	
	string ID_RESSOUR <- "ID_RESSOUR" const: true;	
	string ID_EQU <- "ID_EQU" const: true;	
	string LIEN_NAPPE <- "LIEN_NAPPE" const: true;	
	string ID_ZONE_PR <- "ID_ZONE_PR" const: true;	
	string SECT_PRELE <- "SECT_PRELE" const: true;	
	string ZONE_PRELE <- "ZONE_PRELE" const: true;	
	string ID_ND_EXUT <- "ID_ND_EXUT" const: true;	
	string ID_BDCARTH <- "ID_BDCARTH" const: true;	
	string ID_ND_INI <- "ID_ND_INI" const: true;	
	string ID_ND_FIN <- "ID_ND_FIN" const: true;	
	string NATURE <- "NATURE" const: true;	
	//string CODE_HYDRO <- "CODE_HYDRO" const: true;	//RL 14/04/2015 Not used anymore
	string USAGE <- "USAGE" const: true;	
	string CLASSE <- "CLASSE" const: true;	
	string TROU_EAU <- "TROU_EAU" const: true;
	string ID_HRU <- "ID_HRU" const: true;	
	string FRACTION <- "FRACTION" const: true;
	string ZONECLIM <- "ZONECLIM" const: true;
	//Pour les retenues collinaires
	string FRACTIONDRAIN <- "FRACTIONDR" const: true;
	string TYPEOFRET <- "TYPEOFRET" const: true;
	string SURFACERET <- "SURFACERET" const: true;	
	string VOLMAX <- "VOLMAX" const: true;			
	string Q_RESERVE <- "Q_RESERVE" const: true;	
	string ORDREDRAIN <- "ORDREDRAIN" const: true;
	// pour les ppIRR
	string CODE_IRRIG <- "CODE_IRRIG" const: true;
		
	// Agro	
	string ID_ILOT <- "ID_ILOT" const: true;	
	string PAE_ID_EXP <- "PAE_ID_EXP" const: true;	
	string ID_EXPL <- "ID_EXPL" const: true;	
	string CARACT_IRR <- "CARACT_IRR" const: true;	
	string ID_PARCELLE <- "ID_PARCELL" const: true;	
	string ID_SDC <- "ID_SDC" const: true;	
	string SEQUENCE <- "SEQUENCE" const: true;	
	string SURFACE <- "SURFACE" const: true;
	string EXPREST <- "EXPREST" const: true;
	string POURCENTAGE <- "POURCENTAG" const: true;	
	string CULT_REF <- "CULT_REF" const: true;	
	string INDEX_DEP <- "INDEX_DEP" const: true;
	string TYPE_EXPL <- "TYPE_EXPL" const: true;
	string TYPE_GESTION_PRAIRIE <- "TYPE_GESTION_PRAIRIE" const: true;
	string IS_PATURAGE <- "IS_PATURAG" const: true;
	string ID_BATIMENT <- "ID_BATIMEN" const: true;
	
	// iBio (parcelles.shp)
	string IBIO_LCD <- "IBIO_LCD" const: true;
	string IBIO_HSN <- "IBIO_HSN" const: true;
	string IBIO_CONN <- "IBIO_CONN" const: true;
	string REDUC_ENGR <- "REDUC_ENGR" const: true;
	
		// Lien Agro / hydro	
	string LISTE_EQUS <- "LISTE_EQUS" const: true;	
	string ID_ASA <- "ID_ASA" const: true;	
	string NOM_ASA <- "NOM_ASA" const: true;	
	string REALIME <- "REALIME" const: true;	
	string RISQUE <- "RISQUE" const: true;	
	string TEMPS_IMPA <- "TEMPS_IMPA" const: true;	
	string COEF_ABATT <- "COEF_ABATT" const: true;

	// Normatif	
	string ID_ZA <- "ID_ZA" const: true;	
	string ID_SECTEU <- "ID_SECTEU" const: true;	
	string ID_STH <- "ID_STH" const: true;  
	string DOE <- "DOE" const: true; 
	string DCR <- "DCR" const: true; 
	string IS_NODAL <- "IS_NODAL" const: true; 	
	string ID_UG <- "ID_UG"	 const: true; 	
		
	// CSV 
	string ID_ESPECE <- "ID_ESPECE" const: true; 
	string IDS_SDCS <- "IDS_SDCS" const: true;
	string ID_ITK <- "ID_ITK" const: true;
	string NOM_ITK_AFFICHAGE <- "NOM_ITK_AFFICHAGE" const: true;
	string IS_CULTURE_HIVER <- "IS_CULTURE_HIVER" const: true;
	string ID_PREC <- "ID_PREC" const: true;
	string IS_CI <- "IS_CI" const: true;
	
	string IS_SEMIS <- "IS_SEMIS" const: true;	
	string SEMIS_NB_SOUS_PERIODES <- "SEMIS_NB_SOUS_PERIODES" const: true;
	string SEMIS_DEBUT <- "SEMIS_DEBUT" const: true;
	string SEMIS_FIN <- "SEMIS_FIN" const: true;
	string SEMIS_TEMPS <- "SEMIS_TEMPS" const: true;
	string SEMIS_JOURS_PLUIE <- "SEMIS_JOURS_PLUIE" const: true;
	string SEMIS_HAUTEURS_PLUIE <- "SEMIS_HAUTEURS_PLUIE_MAX" const: true;
	string SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES <- "SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES" const: true;
	string SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES <- "SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES" const: true;
	string SEMIS_JOURS_TMIN <- "SEMIS_JOURS_TEMP_MIN" const: true; // JV 240821 modif suite fusion RM, auparavant SEMIS_JOURS_TMIN
	string SEMIS_TMIN <- "SEMIS_TEMPERATURE_MIN" const: true;  // JV 240821 modif suite fusion RM, auparavant SEMIS_TMIN_MIN
	string SEMIS_JOURS_TMOY <- "SEMIS_NJ_AU_MOINS_TEMP_MOY" const: true; 
	string SEMIS_TMOY <- "SEMIS_AU_MOINS_TEMP_MOY" const: true;  // JV 240821 modif suite fusion RM, auparavant SEMIS_TMIN_MIN	
	string SEMIS_HUMIDITE_SOL_MAX <- "SEMIS_HUMIDITE_SOL_MAX" const: true;
	string SEMIS_EFFET_RUs <- "SEMIS_EFFET_RUs" const: true;	
	string SEMIS_OPERATEUR <- "SEMIS_OPERATEUR" const: true;	
	
	string MATERIEL <- "MATERIEL" const:true;
	string IS_IRRIGATION <- "IS_IRRIGATION" const: true;
	string IRRIGATION_NB_SOUS_PERIODES <- "IRRIGATION_NB_SOUS_PERIODES" const: true;
	string IRRIGATION_DEBUT <- "IRRIGATION_DEBUT" const: true;
	string IRRIGATION_FIN <- "IRRIGATION_FIN" const: true;
	//string IRRIGATION_TEMPS <- "IRRIGATION_TEMPS" const: true;
	string IRRIGATION_DOSE <- "IRRIGATION_DOSE" const: true;
	string IRRIGATION_NB_JOUR_TOUR_EAU <- "IRRIGATION_TD" const: true;
	string IRRIGATION_JOURS_PLUIE_CUMUL <- "IRRIGATION_JOURS_PLUIE_CUMUL" const: true;
	string IRRIGATION_HAUTEUR_PLUIE_CUMUL_ANNULATION <- "IRRIGATION_HAUTEUR_PLUIE_CUMUL_ANNULATION" const: true;
	string IRRIGATION_JOURS_PLUIE_SIGNIF <- "IRRIGATION_JOURS_PLUIE_SIGNIF" const: true;
	string IRRIGATION_HAUTEUR_PLUIE_SIGNIF_REPORT <- "IRRIGATION_HAUTEUR_PLUIE_SIGNIF_REPORT" const: true;
	string IRRIGATION_HAUTEUR_PLUIE_SIGNIF_ANNULATION <- "IRRIGATION_HAUTEUR_PLUIE_SIGNIF_ANNULATION" const: true;
	string IRRIGATION_ECHV_DEBUT <- "IRRIGATION_ECHV_DEBUT" const: true;
	string IRRIGATION_ECHV_FIN <- "IRRIGATION_ECHV_FIN" const: true;
	string IRRIGATION_JOURS_P_MOINS_ETP <- "IRRIGATION_JOURS_P-ETP" const: true;
	string IRRIGATION_P_MOINS_ETP <- "IRRIGATION_P-ETP_MAX" const: true;
	string IRRIGATION_JOURS_PLUIE_PREVUES <- "IRRIGATION_JOURS_PLUIE_PREVUES" const: true;
	string IRRIGATION_HAUTEURS_PLUIE_PREVUES <- "IRRIGATION_HAUTEURS_PLUIE_PREVUES_MIN" const: true;  // JV 240821 modif suite fusion RM, auparavant IRRIGATION_HAUTEURS_PLUIE_PREVUES // 230421 Renaud Ajout de "_MIN" pour que la forme soit la même que pour les autres OT ayant un attribut HAUTEURS_PLUIE_PREVUES_MIN
	string IRRIGATION_HUMIDITE_SOL_MAX <- "IRRIGATION_HUMIDITE_SOL_MAX" const: true;
	string IRRIGATION_REPORT_MAX <- "IRRIGATION_REPORT_MAX" const: true;
	string IRRIGATION_IS_THEORIQUE <- "IRRIGATION_IS_THEORIQUE" const: true;
	string IRRIGATION_SIRR1 <- "IRRIGATION_SIRR1" const: true;
	string IRRIGATION_SIRR2 <- "IRRIGATION_SIRR2" const: true;
	string IRRIGATION_SIRR3 <- "IRRIGATION_SIRR3" const: true;
	string IRRIGATION_GROUPE <- "IRRIGATION_GROUPE" const: true;
	
	
	string IS_RECOLTE <- "IS_RECOLTE" const: true;
	string RECOLTE_NB_SOUS_PERIODES <- "RECOLTE_NB_SOUS_PERIODES" const: true;
	string RECOLTE_DEBUT <- "RECOLTE_DEBUT" const: true;
	string RECOLTE_FIN <- "RECOLTE_FIN" const: true;
	string RECOLTE_TEMPS <- "RECOLTE_TEMPS" const: true;
	string RECOLTE_JOURS_PLUIE <- "RECOLTE_JOURS_PLUIE" const: true;
	string RECOLTE_HAUTEURS_PLUIE <- "RECOLTE_HAUTEURS_PLUIE_MAX" const: true;
	string RECOLTE_HUMIDITE_SOL_MAX <- "RECOLTE_HUMIDITE_SOL_MAX" const: true;
	string RECOLTE_ECHV_MIN <- "RECOLTE_ECHV_MIN" const: true;
	string RECOLTE_EFFET_RUs <- "RECOLTE_EFFET_RUs" const: true;	
	string RECOLTE_OPERATEUR <- "RECOLTE_OPERATEUR" const: true;	
		
	string IS_PREPA <- "IS_PREPA" const: true; // JV 240821 modif suite fusion RM, auparavant IS_PREPA_SOL
	string PREPA_NB_SOUS_PERIODES <- "PREPA_NB_SOUS_PERIODES" const: true;
	string PREPA_TEMPS <- "PREPA_TEMPS" const: true;
	string PREPA_DEBUT <- "PREPA_DEBUT" const: true;
	string PREPA_FIN <- "PREPA_FIN" const: true;
	string PREPA_JOURS_PLUIE <- "PREPA_JOURS_PLUIE" const: true;
	string PREPA_HAUTEURS_PLUIE_MAX <- "PREPA_HAUTEURS_PLUIE_MAX" const: true;
	string PREPA_JOURS_P_MOINS_ETP_MOY <- "PREPA_JOURS_P-ETP_MIN" const: true; // JV 240821 modif suite fusion RM, auparavant PREPA_JOURS_P_MOINS_ETP_MOY
	string PREPA_P_MOINS_ETP_MIN <- "PREPA_P-ETP_MIN" const: true;
	string PREPA_HUMIDITE_SOL_MAX <- "PREPA_HUMIDITE_SOL_MAX" const: true;
	string PREPA_EFFET_RUs <- "PREPA_EFFET_RUs" const: true;
		
	string IS_BINAGE_SOL <- "IS_BINAGE" const: true; // JV 240821 modif suite fusion RM, auparavant IS_BINAGE_SOL
	string BINAGE_NB_SOUS_PERIODES <- "BINAGE_NB_SOUS_PERIODES" const: true;
	string BINAGE_TEMPS <- "BINAGE_TEMPS" const: true;
	string BINAGE_DEBUT <- "BINAGE_DEBUT" const: true;
	string BINAGE_FIN <- "BINAGE_FIN" const: true;
	string BINAGE_EchV_MIN <- "BINAGE_ECHV_MIN" const: true;
	string BINAGE_HUMIDITE_SOL_MAX <- "BINAGE_HUMIDITE_SOL_MAX" const: true;
	string BINAGE_EFFET_RUs <- "BINAGE_EFFET_RUs" const: true;
	
	string IS_REPRISE_SOL <- "IS_REPRISE" const: true; // JV 240821 modif suite fusion RM, auparavant IS_REPRISE_SOL
	string REPRISE_NB_SOUS_PERIODES <- "REPRISE_NB_SOUS_PERIODES" const: true;
	string REPRISE_TEMPS <- "REPRISE_TEMPS" const: true;
	string REPRISE_DEBUT <- "REPRISE_DEBUT" const: true;
	string REPRISE_FIN <- "REPRISE_FIN" const: true;
	string REPRISE_JOURS_PLUIE <- "REPRISE_JOURS_PLUIE" const: true;
	string REPRISE_HAUTEURS_PLUIE_MAX <- "REPRISE_HAUTEURS_PLUIE_MAX" const: true;
	string REPRISE_JOURS_P_MOINS_ETP_MOY <- "REPRISE_JOURS_P-ETP_MOY" const: true;
	string REPRISE_P_MOINS_ETP_MIN <- "REPRISE_P-ETP_MIN" const: true;
	string REPRISE_HUMIDITE_SOL_MAX <- "REPRISE_HUMIDITE_SOL_MAX" const: true;
	string REPRISE_EFFET_RUs <- "REPRISE_EFFET_RUs" const: true;
	
	string IS_PHYTO <- "IS_PHYTO" const: true;
	string PHYTO_NB_SOUS_PERIODES <- "PHYTO_NB_SOUS_PERIODES" const: true;
	string PHYTO_TEMPS <- "PHYTO_TEMPS" const: true;
	string PHYTO_DEBUT <- "PHYTO_DEBUT" const: true;
	string PHYTO_FIN <- "PHYTO_FIN" const: true;
	string PHYTO_DOSE_HA <- "PHYTO_DOSE/Ha" const: true;
	string PHYTO_DOSE_UNITE <- "PHYTO_DOSE_UNITE" const: true;
	string PHYTO_TYPE <- "PHYTO_TYPE" const: true;
	string PHYTO_JOURS_PLUIE_OBS <- "PHYTO_JOURS_PLUIE_OBS" const: true;
	string PHYTO_HAUTEURS_PLUIE_OBS_MIN <- "PHYTO_HAUTEURS_PLUIE_OBS_MIN" const: true;
	string PHYTO_JOURS_PLUIE_PREVUES <- "PHYTO_JOURS_PLUIE_PREVUES" const: true;
	string PHYTO_HAUTEURS_PLUIE_PREVUES_MIN <- "PHYTO_HAUTEURS_PLUIE_PREVUES_MIN" const: true;

	string IS_FERTI <- "IS_FERTI" const: true;
	string FERTI_NB_SOUS_PERIODES <- "FERTI_NB_SOUS_PERIODES" const: true;
	string FERTI_TEMPS <- "FERTI_TEMPS" const: true;
	string FERTI_DEBUT <- "FERTI_DEBUT" const: true;
	string FERTI_FIN <- "FERTI_FIN" const: true;
	string FERTI_DOSE_HA <- "FERTI_DOSE/Ha" const: true;
	string FERTI_JOURS_PLUIE_OBS <- "FERTI_JOURS_PLUIE_OBS" const: true;
	string FERTI_HAUTEURS_PLUIE_OBS_MIN <- "FERTI_HAUTEURS_PLUIE_OBS_MIN" const: true;
	string FERTI_ECHV_DEBUT <- "FERTI_ECHV_DEBUT" const: true;
	string FERTI_ECHV_FIN <- "FERTI_ECHV_FIN" const: true;
	string IS_CORPEN <- "IS_CORPEN" const: true;

	// Variables noms de lignes pour les règles de décision de fertilisation (Ajouté par Renaud 20/03/20)
	string FERTIALT_NOM_ITK <- "FERTIALT_NOM_ITK" const: true;
	string FERTIALT_NOM_ALTERNATIVE <- "FERTIALT_NOM_ALTERNATIVE" const: true;
	string FERTIALT_ORDRE_ALTERNATIVE <- "FERTIALT_ORDRE_ALTERNATIVE" const: true;
	string FERTIALT_ORDRE_APPORT <- "FERTIALT_ORDRE_APPORT" const: true;
	string FERTIALT_NOM_PRODUIT <- "FERTIALT_NOM_PRODUIT" const: true;
	string FERTIALT_DOSE <- "FERTIALT_DOSE" const: true;
	string FERTIALT_DOSE_P <- "FERTIALT_DOSE_P" const: true;
	string FERTIALT_DOSE_K <- "FERTIALT_DOSE_K" const: true;
	string FERTIALT_PROF_WSOL <- "FERTIALT_PROF_WSOL" const: true;
	string FERTIALT_AGRIW <- "FERTIALT_AGRIW" const: true;
	string FERTIALT_OUTIL <- "FERTIALT_OUTIL" const: true;
	string FERTIALT_TPS_TRAVAIL <- "FERTIALT_TPS_TRAVAIL" const: true;
	string FERTIALT_N_PASSAGES <- "FERTIALT_N_PASSAGES" const: true;
	string FERTIALT_OT_SIMULTANNEE <- "FERTIALT_OT_SIMULTANNEE" const: true;
	string FERTIALT_N_SOUS_PERIODES <- "FERTIALT_N_SOUS_PERIODES" const: true;
	string FERTIALT_DEBUT <- "FERTIALT_DEBUT" const: true;
	string FERTIALT_FIN <- "FERTIALT_FIN" const: true;
	string FERTIALT_HUM_MAX_SOL <- "FERTIALT_HUM_MAX_SOL" const: true;
	string FERTIALT_N_J_CUMUL_PLUIE <- "FERTIALT_N_J_CUMUL_PLUIE" const: true;
	string FERTIALT_CUMUL_PLUIE <- "FERTIALT_CUMUL_PLUIE" const: true;
	string FERTIALT_N_J_CUMUL_PLUIE_EVA <- "FERTIALT_N_J_CUMUL_PLUIE_EVA" const: true;
	string FERTIALT_CUMUL_PLUIE_EVA <- "FERTIALT_CUMUL_PLUIE_EVA" const: true;
	string FERTIALT_N_J_CUMUL_TEMP_MIN <- "FERTIALT_N_J_CUMUL_TEMP_MIN" const: true;
	string FERTIALT_TEMP_MIN <- "FERTIALT_TEMP_MIN" const: true;
	string FERTIALT_N_J_CUMUL_TEMP_MAX <- "FERTIALT_N_J_CUMUL_TEMP_MAX" const: true;
	string FERTIALT_TEMP_MAX <- "FERTIALT_TEMP_MAX" const: true;
	string FERTIALT_N_J_CUMUL_TEMP_MAX_INF <- "FERTIALT_N_J_CUMUL_TEMP_MAX_INF" const: true;
	string FERTIALT_TEMP_MAX_INF <- "FERTIALT_TEMP_MAX_INF" const: true;
	string FERTIALT_SEUIL_VEGE <- "FERTIALT_SEUIL_VEGE" const: true;
	string FERTIALT_SEUIL_VEGE_PRE <- "FERTIALT_SEUIL_VEGE_PRE" const: true;
	string FERTIALT_SEUIL_VEGE_POST <- "FERTIALT_SEUIL_VEGE_POST" const: true;
//	string FERTIALT_N_J_CUMUL_PLUIE_PREVUE <- "FERTIALT_N_J_CUMUL_PLUIE_PREVUE" const: true;
//	string FERTIALT_CUMUL_PLUIE_PREVUE <- "FERTIALT_CUMUL_PLUIE_PREVUE" const: true;
	string FERTIALT_N_J_CUMUL_HYGROMETRIE_MIN  <- "FERTIALT_N_J_CUMUL_HYGROMETRIE_MIN " const: true;
	string FERTIALT_HYGROMETRIE_MIN <- "FERTIALT_HYGROMETRIE_MIN" const: true;
	string FERTIALT_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES <- "FERTIALT_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES" const: true;
	string FERTIALT_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES <- "FERTIALT_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES" const: true;
	
	string IS_FAUCHE <- "IS_FAUCHE" const: true;
	string FAUCHE_NB_SOUS_PERIODES <- "FAUCHE_NB_SOUS_PERIODES" const: true;
	string FAUCHE_TEMPS <- "FAUCHE_TEMPS" const: true;
	string FAUCHE_DEBUT <- "FAUCHE_DEBUT" const: true;
	string FAUCHE_FIN <- "FAUCHE_FIN" const: true;
	string FAUCHE_JOURS_PLUIE <- "FAUCHE_JOURS_PLUIE" const: true;
	string FAUCHE_HAUTEURS_PLUIE_MAX <- "FAUCHE_HAUTEURS_PLUIE_MAX" const: true;
	string FAUCHE_DELAI_COUPE <- "FAUCHE_DELAI_COUPE" const: true;
	string FAUCHE_HAUTEUR_COUPE <- "FAUCHE_HAUTEUR_COUPE" const: true;
	string FAUCHE_VOLUME <- "FAUCHE_VOLUME" const: true;
	string FAUCHE_JOURS_TMIN <- "FAUCHE_JOURS_TEMP_MIN" const: true; 
	string FAUCHE_TMIN <- "FAUCHE_TEMPERATURE_MIN" const: true;
	string FAUCHE_HAUTEUR_MIN <- "FAUCHE_HAUTEUR_MIN" const: true;
	string FAUCHE_QUANTITE_BIOMASSE_MIN <- "FAUCHE_QUANTITE_BIOMASSE_MIN" const: true;
	string FAUCHE_DIGESTABILITE_MIN <- "FAUCHE_DIGESTABILITE_MIN" const: true;
	
	string IS_PATURE <- "IS_PATURE" const: true;
	string PATURE_NB_SOUS_PERIODES <- "PATURE_NB_SOUS_PERIODES" const: true;
	string PATURE_TEMPS <- "PATURE_TEMPS" const: true;
	string PATURE_TEMPS_PATURE <- "PATURE_TEMPS_PATURE" const: true;
	string PATURE_TEMPS_REPOS <- "PATURE_TEMPS_REPOS" const: true;
	string PATURE_COEF_HERBE_ACCESSIBLE <- "PATURE_COEF_HERBE_ACCESSIBLE" const: true;
	string PATURE_DEBUT <- "PATURE_DEBUT" const: true;
	string PATURE_FIN <- "PATURE_FIN" const: true;
	string PATURE_SI_FAUCHE_BIOMASSE <- "PATURE_SI_FAUCHE_BIOMASSE" const: true;
	string PATURE_HAUTEUR_HERBE_ENTREE <- "PATURE_HAUTEUR_HERBE_ENTREE" const: true;
	string PATURE_HAUTEUR_HERBE_SORTIE <- "PATURE_HAUTEUR_HERBE_SORTIE" const: true;
	string PATURE_VOLUME_MIN <- "PATURE_VOLUME_MIN" const: true;
	string PATURE_DIGESTABILITE_MIN <- "PATURE_DIGESTABILITE_MIN" const: true;
	string PATURE_HUMIDITE_SOL_MAX <- "PATURE_HUMIDITE_SOL_MAX" const: true;
	string PATURE_SOMME_DEGRESJ <- "PATURE_SOMME_DEGRESJ" const: true;
	string PATURE_JOURS_PLUIE_OBS <- "PATURE_JOURS_PLUIE_OBS" const: true;
	string PATURE_HAUTEURS_PLUIE_OBS_MAX <- "PATURE_HAUTEURS_PLUIE_OBS_MAX" const: true;
	string PATURE_JOURS_PLUIE_PREVUS <- "PATURE_JOURS_PLUIE_PREVUS" const: true;
	string PATURE_HAUTEURS_PLUIE_PREVUES_MAX <- "PATURE_HAUTEURS_PLUIE_PREVUES_MAX" const: true;
}
