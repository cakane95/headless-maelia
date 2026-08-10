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
 *  parcelleAqYieldNC
 *  Authors: Renaud Misslin, Hugues Clivot
 *  Description: Les parcelles AqYield sont les parcelles creees dans le cas ou le modele de croissance des plante est le modele AqYield
 */

model parcelleAqYieldNC

import "../Cultures/cultureHerbSim.gaml"
 
global {
	action constructionParcellesAqYieldNC{
		listeParcelles <- lectureFichierParcelle(cheminEntree:parcellesShape, typeParcelle:parcelleAqYieldNC);
	}
	
	// Paramètres pour l'adaptation de la fertilisation Renaud 141022
	int profondeur_a_comparer <- 3; // Si cette valeur est n, la comparaison se fera au bout de n + 1 années. On comparera les n dernières années aux n prmières années de simulation
} 


species parcelleAqYieldNC parent: parcelleAqYield {
	float cumul_erreur_azote <- 0.0;
	float compteur_erreur_QNacq_pot <- 0.0;
	//*************************************************
	// Debug
	float repartN_cumul <- 0.0;
	float QNfinaleJ_w_init <- 20.0;
	float QNfinaleJ_r_init <- 0.0;
	float QNfinaleJ_p_init <- 15.0;
	float QNapport_ferti <- 0.0;
	float entrees_ferti <- 0.0;
	float fluxN_lixiviation_cumul <- 0.0; // Cumul sur 1 an remis à 0 chaque année pour calculer le bilan N annuel
	float fluxN_lixiviation_cumul_total <- 0.0; // Cumul d'année en année
	float sortie_acquisition <- 0.0;
	//*************************************************
	bool isTravailSolJourCourant_NC <- false;
	float HOw <- 0.0; // Taille du réservoir correpondant à l'horizon de travail (mm)
	float HOr <- 0.0; // Taille du réservoir correpondant à l'horizon de racinaire (mm)
	float HOp <- 0.0; // Taille du réservoir correpondant à l'horizon de profond (mm)
	float HOpPrec <- 0.0;	
	
	float RHOw <- 0.0; // Eau contenue par l'horizon de travail (mm)
	float RHOr <- 0.0; // Eau contenue par l'horizon de racinaire (mm)
	float RHOp <- 0.0; // Eau contenue par l'horizon de profond (mm)	
	
	float repart_HO <- 0.0; // Hauteur d'eau passant de HOp à HOr lorsque les racines gradissent --> à vérifier
	
	float profR <- 0.0;
	
	float flux_RHOwr <- 0.0; // Flux d'eau de RHOw à RHOr
	float flux_RHOrp <- 0.0; // Flux d'eau de RHOr à RHOp
	float drain_RHOp <- 0.0; // Drainage, flux d'eau sortant de HOp
	
	float HCCw <- 0.0;
	float HPFw_mm <- 0.0;
	float RHOw_cor <- 0.0;
	float QNinitialeJ_w <- 0.0; // Quantité d'azote initiale au jour J dans l'horizon w
	float QNinitialeJ_r <- 0.0;
	float QNinitialeJ_p <- 0.0;
	float QNapresConsoJ_w <- 0.0;
	float QNapresConsoJ_r <- 0.0;
	float QNfinaleJ_w <- 0.0; // Quantité d'azote finale au jour J dans l'horizon w
	float QNfinaleJ_r <- 0.0;
	float QNfinaleJ_p <- 0.0;
	float QNsol_tot <- 0.0;
	float QN_pot <- 0.0;
	float availN_w <- 0.0; // Quantité d'azote disponible pour la plante et les microorganismes dans W (QNinitialeJ_w + DNhum_MO_j)
	float availN_w_plant <- 0.0; // Quantité d'azote disponible pour la plante dans W (QNinitialeJ_w + DNhum_MO_j)
	
	
	// A supprimer
	float QNinitialeJ_wPrec <- 0.0;
	//
	float fluxN_wr <- 0.0;
	float fluxN_rp <- 0.0;
	float fluxN_lixiviation <- 0.0;
	float QNapport <- 0.0;
	float QNapport_min <- 0.0;
	float QNapport_min2 <- 0.0;
	float QNapport_min_cumul <- 0.0;
	float QNapport_min_calc <- 0.0;
	float QNapport_pro <- 0.0;
	float QNapport_pro2 <- 0.0;
	float QNapport_pro_cumul <- 0.0;
	float QNapport_pro_calc <- 0.0;
	float QNapport_min_direct <- 0.0;
	float QNapport_min_direct_calc <- 0.0;
	float QNapport_pro_direct <- 0.0;
	float QNapport_pro_direct_calc <- 0.0;
	float QNapport_after_volat <- 0.0;
	float QNapport_direct_after_volat <- 0.0;
	float QNapport_after_volat_j <- 0.0;
	float QNdispoFerti <- 0.0;
	float precipitationDepuisApportN <- 0.0;
	float Nmin_som_res_cumul <- 0.0;
	float NminMO_cumul <- 0.0;
	float NminMO_cumulPrec <- 0.0;
	float Jnorma <- 0.0;
	float JnormaPrec <- 0.0;
	
	// Variables totales résidus
	float NminRes <- 0.0;
	float NminRes_cumul <- 0.0;
	float Nmin_total <- 0.0;
	float Nmin_totalPrec <- 0.0;
	float Nmin_cumul <- 0.0; // Nmin_total cumulé
	
	// Données enregistrées pour arbre de régression NC
	map<string,int> nbSemisParCulture;
	map<string,int> nbApportsParProduit;
	map<string,int> quantitesApporteesParProduit;
	
	// JV 100522 variable DNhum_MO_cm_j locale à l'origine mais stockée comme attribut pour les sorties azote
	float DNhum_MO_cm_j_sortie <- 0.0;
	
	float MSA_exportee_parcelle <- 0.0; // Variable permettant d'enregistrer la biomasse aérienne exportée journalièrement de la parcelle (une fois par culture, au moment de la récolte)
	float MSA_restituee_parcelle <- 0.0; // Variable permettant d'enregistrer la biomasse aérienne restituée journalièrement de la parcelle (une fois par culture, au moment de la récolte)
	float MSR_restituee_parcelle <- 0.0; // Variable permettant d'enregistrer la biomasse racinaire restituée journalièrement de la parcelle (une fois par culture, au moment de la récolte)
	
	float QNHOw <- 0.0; // Aussi appelé QNfinal_w dans le doc word et QNfinal dans le mémoire
	float QNHOwPrec <- 0.0;
		
 // Variables and parameters for simulating OM pools***********************************************************************************************************
 //********************************************************************************************************************************
 	list<string> situation_res <- []; // "surface" or "incorpore"
 	list<string> nomproduit <- []; // organic residue type
 	list<float> prof_res <- [];// burial depth of the organic residue, which will be proportionnaly distributed in each cm over this depth
 	list<int> daysSinceCreation <- [];		
	list<string> pool_type <- [];// type of organic residue compartment "labile" or "recalcitrant"
	list<float> CNhuma <- []; // C:N ratio of active SOM at the burial depth of a residue at the day of incorporation, in order to define the C:N ratio used for its humification
	list<float> CNhum <- []; // C:N ratio of SOM at the burial depth of a residue at the day of incorporation, in order to define the C:N ratio used for its humification
	list<string> res_type <- []; // NR pool
	float Nlimiting_step <- 0.0;
	float fonction_hum_mo <- 0.0;
	float fonction_temp_mo <- 0.0;
	float fonction_hum_res <- 0.0;
	float fonction_temp_res <- 0.0;
	
	// Pools calculated at the scale of the whole w layer (layer with biological activity)
	float Chum <- 0.0;// Total amount of C in soil humus (active + inert fractions)
	float Chumi <-  0.0;// Amount of C in inert pool of humus
	float Chuma <- 0.0;// Amount of C in actif pool of humus
	float Nhum <- 0.0;// Total quantity of N humus (active + inert fractions) in the soil
	float Nhumi <-  0.0;// Amount of N in inert pool of humus
	float Nhuma <- 0.0;// Amount of active N in the humus pool

	float NhumRes <- 0.0;// Cumulative amount of N humified from organic residues
	float ChumRes <- 0.0;// Cumulative amount of C humified from organic residues
	float NMOmin <- 0.0;// Cumulative amount of N mineralized from active SOM
	float Nres_perdu <- 0.0; // To suppr ?
	float Nbio_perdu <- 0.0; // To suppr ?
	float Nres_recalcitrant_moved <- 0.0; // To suppr ?
	float Nbio_recalcitrant_moved <- 0.0; // To suppr ?	
	
	
	// Pools simulated at the cm scale
	list<float> Chum_cm <- [];// Total amount of C in soil humus (active + inert fractions)
	list<float> Chuma_cm <- [];// Amount of C in active pool of humus
	list<float> Chumi_cm <- [];// Amount of C in inert pool of humus
	list<float> Nhum_cm <- [];// Total quantity of N humus (active + inert fractions) in the soil
	list<float> Nhuma_cm <- [];// Amount of N in active pool of humus
	list<float> Nhumi_cm <- [];// Amount of N in inert pool of humus
	
	list<float> Nmin_cm <- [];
	
	// Pools for each residue
	list<float> Cres <- []; // Amount of C in residue (list of pools)
	list<float> Nres <- []; // Amount of N in residue (list of pools)
	list<float> NresPrec <- []; // Amount of N in residue at day-1	
	list<float> CNres <- []; // C:N ratio of organic residue
	
	list<float> Cbio <- []; // Amount of C in microbial biomass (list of pools)
	list<float> Nbio <- []; // Amount of N in microbial biomass (list of pools)
	list<float> NbioPrec <- [];	// Amount of N in microbial biomass at day-1
	list<float> CbioPrec <- [];	// Amount of N in microbial biomass at day-1	

	
	
	// Simulated fluxes -> lists	
	list<float> DNres <- [];
	list<float> DNbio <- [];
	list<float> DNhumRes_cm <- [];
	list<float> DChumRes_cm <- [];
	list<float> DNhumMO_cm <- [];
	list<float> DNhum <- [];
	list<float> DNminRes_j <- []; // Daily N demand from microbial biomass from a specific residue
	list<float> DNbio_in_j <- [];		
	float DNhumResr <- 0.0;
	float DChumResr <- 0.0;

	// Parameters for residue mineralization
	float AKres const: true <- 0.1; // parameter for calculating residue decomposition rate constant Kres
	float BKres const: true <- 0.76;// parameter for calculating residue decomposition rate constant Kres	
	float Awb <- 15.35;// parameter for calculating the C:N ratio of zymogenous microbial biomass
	float Bwb <- -76.0;// parameter for calculating the C:N ratio of zymogenous microbial biomass
	float Cwb <- 7.8;// parameter specifying the minimum C:N ratio of zymogenous microbial biomass			
	float AHres <- 0.73;// parameter for calculating the assimilation yield of microbial biomass into humified OM Hres
	float BHres <- 10.2;// parameter for calculating the assimilation yield of microbial biomass into humified OM Hres
	
	list<float> Kres_pool <- []; // organic residue decomposition rate constant
	list<float> Yres_pool <- []; // assimilation yield of organic residue into microbial biomass	
	float Yres_crop const: true <- 0.62; //assimilation yield of crop residue into microbial biomass
	list<float> CNbio_pool <- []; //C:N ratio of zymogenous microbial biomass
	float Kbio const: true <- 0.0076;// microbial biomass decomposition rate constant	
	list<float> Hres_pool <- []; //humification yield of microbial biomass into SOM
	
			
	// Additional variables and parameters for organic residue and SOM decomposition in case of N limitation
	float fmodK <- 1.0;// factor modulating residue decomposition rate Kres
	float fmodB <- 1.0;// factor modulating microbial biomass decomposition rate Kbio
	float fNCbio <- 1.0;// factor modulating biomass C:N ratio
	float fmodH <- 1.0;// factor modulating the C:N ratio of humified microbial biomass
	float fmodP <- 1.0;// factor modulating the priming effect on SOM mineralization
	float fmodY <- 1.0;// factor modulating the assimilation yield of organic residue into microbial biomass
	float azomin_cm <- 0.02;// minimal amount of mineral N (kg/ha) per 1 cm layer
	
	// Variables/parameters for N gaseous losses
	float N_n2o_nit <- 0.0;
	float N_n2o_denit <- 0.0;
	float N_n2o_tot <- 0.0;
	float N_denit <- 0.0;
	float N_n2_denit <- 0.0;
	float N_nh3_tot <- 0.0;
	float N_nh3_tot2 <- 0.0;
	float N_nh3 <- 0.0;
	float N_nh3_min <- 0.0;
	float N_nh3_min_calc <- 0.0;
	float N_nh3_pro <- 0.0;
	float N_nh3_min_dir <- 0.0;
	float N_nh3_min_dir_calc <- 0.0;
	float N_nh3_pro_dir <- 0.0;
	float N_nh3_pro_dir_calc <- 0.0;
	float N_nh3_pro_pot <- 0.0;
	float N_nh3_pro_pot_calc <- 0.0;
	float N_nh3_pro_pot_sol <- 0.0;
	float N_nh3_pro_hum_pot_sol <- 0.0;
	int nb_of_days_wo_tillage <- 0;
	int nb_of_days_wo_tillage_prec <- 0;
	string denit_pot_option <- "fCorg"; // option for denitrification potential : "fixed" or "fCorg" as a function of Corg percentage (idem Stics) HC 230524
	float profDenit <- 20.0; // maximum depth of soil affected by denitrification (in cm) HC 230524
	
	// Variables/parameters for GHG balance
	float eqCO2_synthesis <- 0.0;//kg eqCO2 per ha = fertilizer synthesis&transport
	float eqCO2_Nmineral_synthesis <- 0.0; //kg eqCO2 per ha = fertilizer synthesis&transport (for mineral fertilizers only)
	float eqCO2_emissions_NC <- 0.0;//kg eqCO2 per ha = C storage + N2O direct and indirect emissions
	float eqCO2_emissions_N <- 0.0;//kg eqCO2 per ha = N2O direct and indirect emissions
	float eqCO2_total <- 0.0;//kg eqCO2 per ha = fertilizer synthesis&transport + C storage + N2O direct and indirect emissions
	float eqCO2_total_sansC <- 0.0;//kg eqCO2 per ha = fertilizer synthesis&transport +N2O direct and indirect emissions

	float SOC_perc <- 0.0;// SOC content in %
	float OM_perc <- 0.0;// OM content in % (=1.72*SOC%)
	float SOC_Clay_ratio <- 0.0;// %SOC/%Clay ratio indicator of structure quality 1:8 = average for very good quality structure and 1:10=limit between good and medium, below 1:13 = degraded cf Johannes et al (2017, Geoderma 302:14-21)								 
	list<float> SOC_Clay_ratio_year;
	
	// Variables cumulées de pertes en N, d'émissions, prix et de stockage de C (utilisées en sortie)
	float eqCO2_total_cumul <- 0.0;
	float Nlosses_cumul <- 0.0;
	float N_nh3_tot_cumul <- 0.0;	
	float N_nh3_tot_cumul_tot <- 0.0;
	float C_stock_cumul <- 0.0;
	float prixFerti_cumul;
	float tps_travail_Ferti_cumul <- 0.0; // par hectare
	float N_n2o_cumul <- 0.0;
	float eqCO2_synthesis_cumul <- 0.0;
	float eqCO2_Nmineral_synthesis_cumul <- 0.0; // Annual sum of eco2 associated with mineral fertilizers production
	float eqCO2_emissions_NC_cumul <- 0.0;
	float QNfix_cumul <- 0.0; // Quantité de N fixée en kg sur l'année
	
	// Controle des bilans
	float Nlosses <- 0.0;
	float Ninputs <- 0.0;
	
	// Variables pour les opérations de fertilisation
	strategieFertiAlternative alternative_selectionnee;
	strategieFertiApport prochainApport;
	list<strategieFertiApport> apportsEffectues;
	list<strategieFertiApport> apportsAnnules;
	
	strategieFertiApport apport_courant; // RM 080221 Apport en cours de tentative (pour gestion des réallocations d'engrais aux stocks territoriaux si jamais ils ne sont pas épandus)
	int anneeDebutITKcourant;
	
	map<string,int> temps_retour <- []; // exemple: ['digestat brut'::1, 'boue urbaine epaissie chaulee'::1, 'fumier bovin'::1, 'fumier de cheval'::1, 'lisier bovin'::1, 'lisier de porc'::1];
	map<string,int> temps_retour_courant <- [];
	map<Engrais,float> engrais_reserves_parcelle; //dose T/ha
	//list<float> quantites_reservees_parcelle;
	
	// Variables pour l'adaptation de la fertilisation
	float Nmin_apports_pro; // N total apporté par les PRO
	float Nmin_apports_min; // N total apporté par les engrais miénraux
	float N_a_apporter_corrige_rdmtObs_NminSOM; // N total a apporter CORPEN -> corrigé sur la base des rendements et de la minéralisation observés 
	float coef_abattement_corpen <- 1.0; // Coefficient d'abattement corpen
	float N_dispo_semis <- 0.0; // N minéral dispo dans w au semis
	bool premier_apport_traite <- false; // Le premier apport a-t-il été traité ?
	especeCultivee espece_precedente;
	
	// JV 090522 variables pour les fichiers de sorties: 1 élément de liste par couvert pendant l'année, liste de couverts définie dans parcelle
	// sorties N
	list<float> sorties_N_lixivie; // [kgN/ha] cumul d'azote lixivié (fluxN_lixiviation)
	list<float> sorties_N_volatilise_NH3; // [kgN/ha] cumul d'azote volatilisé sous forme de NH3 (N_nh3_tot)
	list<float> sorties_N_mineralise_net_PRO; // [kgN/ha] cumul d'azote minéralisé net pour PRO (Nmin_total: à valider)
	list<float> sorties_N_mineralise_net_SOM; // [kgN/ha] cumul d'azote minéralisé net pour SOM (DNhum_MO_cm_j_sortie)
	list<float> sorties_N_mineralise_net_residus; // [kgN/ha] cumul d'azote minéralisé net pour résidus (NminRes)
	list<float> sorties_N_acquis_couvert; // [kgN/ha] cumul d'azote acquis par le couvert (cultureAqYieldNC.QN_acquis)
	list<float> sorties_N_mineral_debut; // [kgN/ha] azote minéral au début de la période (QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p)
	list<float> sorties_N_mineral_fin; // [kgN/ha] azote minéral à la fin de la période (QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p)
	list<float> sorties_emissions_N2O_directes; // [kgN/ha] cumul d'émissions de N2O directes (N_n2o_tot)
	list<float> sorties_emissions_N2; // [kgN/ha] cumul d'émissions de N2 (N_n2_denit)
	list<float> sorties_satisfactionAzote; // [%] effet stress azoté sur rendement (moyenne sur la période) (cultureAqYieldNC.getEffetStressAzoteSurRendement) ou moyenne de INN_periode_culture si CI
	list<float> sorties_N_fixe_legumineuses; // [kgN/ha] cumul d'azote fixé par les légumineuses (parcelleAqYieldNC(p).getQN_fix)
	list<float> sorties_satisfactionAzote_cult; // [%] effet stress azoté sur rendement (moyenne sur la période) (cultureAqYieldNC.getEffetStressAzoteSurRendement) ou moyenne de INN_periode_culture si CI
	list<float> sorties_satisfactionAzote_ci;
	// sorties GES et C
	list<float> sorties_delta_Corg; // [kg_C/ha] Delta de stock de carbone organique à la fin de la période (delta_Chum_sortie)
	list<float> sorties_tx_MO_fin; // [%] taux de matière organique sur le 1er horizon à la fin de la période (OM_perc)
	list<float> sorties_emissions_N2O_denit; // [kg_N-N2O/ha] cumul d'émissions de N2O dénitrification (N_n2o_denit)
	list<float> sorties_emissions_N2O_nit; // [kg_N-N2O/ha] cumul d'émissions de N2O nitrification (N_n2o_nit)
	list<float> sorties_emissions_N2O_N_volat; // [kg/N-N2O/ha] cumul d'émissions indirectes de N2O liées à l'azote volatilisé (N_n2o_tot)
	list<float> sorties_emissions_N2O_N_lixiv; // [kg/N-N2O/ha] cumul d'émissions indirectes de N2O liées à l'azote lixivié (fluxN_lixiviation)
	list<float> sorties_emissions_ferti; // [kg_eqCO2/ha] cumul d'émissions liées aux fertilisants (fabrication, stockage, transport) (eqCO2_synthesis)
	list<float> sorties_bilan_net_GES; // [kg_eqCO2/ha] bilan net de GES (éqCO2, émissions + stockage C) (eqCO2_total)	
	list<float> sorties_tx_Corg_Arg; // [%] rapport Corg/Arg (SOC_Clay_ratio)
	
	// JV 110522 copies de variables locales utilisées pour les sorties
	float delta_Chum_sortie <- 0.0;
	float N_nh3_tot_sortie <- 0.0;
	
	// NR pool : variables pour la sortie pool résidus (différent des listes pour le suivi de la dynamique des pools)
	list<float> sorties_CNres;
	list<string> sorties_situationRes;
	list<float> sorties_masseC;
	list<float> sorties_masseN;
	list<string> sorties_nomProduit;
	list<string> sorties_resType;
	list<string> sorties_poolType;
	list<float> sorties_Kres;
	list<float> sorties_Hres;
	list<float> sorties_CNbio;
	list<float> sorties_Yres;
	list<int> sorties_dateAjout;
	list<string> sorties_culture;
	 
	
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Initialisation
	 */
	action initialisationDonneesSol {
		// AQYIELD
		//coefRuissellement <- ((ilot_app.penteAssociee/ 100)^2) ; //RL 17/05/17 : correction de la formule pour que 
			//ce coeff soit compris entre 0 et 1 

		coefRuissellement <- (ilot_app.penteAssociee^2/ 100) ; // JV 06/11/17 retour à l'ancienne formule CR = Pente² / 100 suite à demande G. Obiang-Ndong (Mantis #1145)
		if(coefRuissellement>1){
			coefRuissellement <- 1.0;
		}

		RUm <- ilot_app.sol.reservePotentielleUtileMax;
		
		RUw <- (ilot_app.sol.HCCw - ilot_app.sol.HPFw)*ilot_app.sol.daH1*ilot_app.sol.profHum*(100-ilot_app.sol.tauxGravier)/100/10;
		RUr <- RUw; // ilot_app.sol.reservoirHorizonTravailProfond; -->  Modifié pour coller à AqYield excel (22/05/18)
		
		RUs <- RUw * 0.95; // RUw -1.0; --> Modifié pour coller à AqYield excel (18/05/18)
		RUsPrec <- RUw * 0.95; // Modif Renaud à cause de division par 0 dans "float sm" (cultureAqYieldNC) 290421
		Hm <- 0.8 * ilot_app.sol.reservePotentielleUtileMax;
		Hw <- 0.8 * RUw;//ilot_app.sol.reservoirHorizonTravailProfond -> RUw cor hugues
		
		Hr <- Hw;
		
		Hs <- Hw * RUs / RUw;//ilot_app.sol.reservoirHorizonTravailProfond -> RUw cor hugues
		HPFw_mm <- self.ilot_app.sol.HCCw_mm - RUw;

		
		RHOw_cor <- Hw + HPFw_mm;
		
		reserveUtileHorizonSurfaceW1 <- horizonDeTravailSuperficiel/10.0 * (1.0-self.ilot_app.sol.tauxGravier/100) *
		 (12.0+39.0*(self.ilot_app.sol.clay/100) - 64.0*((self.ilot_app.sol.clay/100)^2));
		
		//HerbSim
		AvailableSoilWater <- 2 * TotalTranspirableSoilWater / 3;
	    ActualEvapoTranspiration <- 0.0;
	    NutrientIndex <- ((2 * 0.75 * NitrogenIndex) + PhosphorusIndex) / 3;
		
		
		// Initialisation de la partie NC
		HOw <- RUw;
		HOr <- RUr - RUw;
		HOp <- RUm - RUr;
		
		RHOw <- Hw;
		RHOr <- min([RHOw, HOr]);
		RHOp <- max([0, Hm - Hr]);
		
		QNfinaleJ_w <- 20.0; // défaut = 20
		QNfinaleJ_r <- 0.0;
		QNfinaleJ_p <- 15.0; // défaut = 40
		QNsol_tot <- QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p;
		N_n2o_nit <- 0.0;
		N_n2o_denit <- 0.0;
		
		profR <- RUr / RUw * self.ilot_app.sol.profHum;
		float azomin_w <- azomin_cm * int(ilot_app.sol.profHum); //minimal amount of mineral N (kg/ha) in the layer w
		Nhuma <- ilot_app.sol.NHumInitActif; // SOM active N
		Chuma <- ilot_app.sol.CHumInitActif; // SOM active C
		Nhumi <- ilot_app.sol.NHumInitStable; // SOM active N
		Chumi <- ilot_app.sol.CHumInitStable; // SOM active C
				
		float Nhuma_cm_init <- Nhuma / ilot_app.sol.profHum;
		float Chuma_cm_init <- Chuma / ilot_app.sol.profHum;		
		float Nhumi_cm_init <- Nhumi / int(ilot_app.sol.profHum);
		float Chumi_cm_init <- Chumi / int(ilot_app.sol.profHum);
		float Nhum_cm_init <- (Nhuma+ Nhumi) / int(ilot_app.sol.profHum);
		float Chum_cm_init <- (Chuma+ Chumi) / int(ilot_app.sol.profHum);
																  
		
		// Listes azote centimétriques (Nhum et Chum au cm)
		Nhuma_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), Nhuma_cm_init));
		Chuma_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), Chuma_cm_init));
		Nhumi_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), Nhumi_cm_init));
		Chumi_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), Chumi_cm_init));
		Nhum_cm <- list_with(int(self.ilot_app.sol.profHum), Nhum_cm_init);
		Chum_cm <- list_with(int(self.ilot_app.sol.profHum), Chum_cm_init);		
				
		Nhum <- sum(Nhumi_cm) + sum(Nhuma_cm);
		Chum <- sum(Chumi_cm) + sum(Chuma_cm);
				
		DNhumRes_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), 0.0));
		DChumRes_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), 0.0));
		DNhumMO_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), 0.0));
		Nmin_cm <- list<float>(list_with(int(self.ilot_app.sol.profHum), 0.0));		
  
		// Variables pour les opérations de fertilisation
		anneeDebutITKcourant <-  dateCour.annee;
		
		/* debug
		write "fin parcelleAqYieldNC.initialisationDonneesSol: RUm=" + RUm + "\nilot_app.sol.reservePotentielleUtileMax=" + ilot_app.sol.reservePotentielleUtileMax; // JV debug fusion
		write "id sol: " + ilot_app.sol.idTypeDeSOl;
		write "mapProfondeurMinParCouche=" + ilot_app.sol.mapProfondeurMinParCouche;
		write "mapProfondeurMaxParCouche=" + ilot_app.sol.mapProfondeurMaxParCouche;
		write "mapEpaisseurParCouche=" + ilot_app.sol.mapEpaisseurParCouche;
		write "capaciteAuChamp=" + ilot_app.sol.capaciteAuChamp;
		write "pointFletrissementPermanent=" + ilot_app.sol.pointFletrissementPermanent;
		write "capaciteEauDisponible=" + ilot_app.sol.capaciteEauDisponible;
		write "saturation=" + ilot_app.sol.saturation;
		write "conductiviteHydroliqueSaturee=" + ilot_app.sol.conductiviteHydroliqueSaturee;
		write "densiteSol=" + ilot_app.sol.densiteSol;
		write "densiteArgile=" + ilot_app.sol.densiteArgile;
		*/
	}
	

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort sous le sol la croissance de la plante
	 */
	float calculEvapoTranspiration{
		do calculNutritionIndex();
		return calculEvapoTranspirationAqYield();
		
	}
	
	// Dynamiques journalières liées à l'azote dans la parcelle
	action maj_journ_NC {
		float Chum_prec <- Chum;		
		Chum <- sum(Chumi_cm) + sum(Chuma_cm);// actualisation du carbone organique
		float delta_Chum <- Chum - Chum_prec;
		delta_Chum_sortie <- delta_Chum; // JV 100522 copie car besoin de cette variable locale dans les sorties
		Nhum <- sum(Nhumi_cm) + sum(Nhuma_cm);
//		write "itk = " + getITKAnnee().nomPourAffichage;
//		write "Sol = " + ilot_app.sol.idTypeDeSOl;
//		write "Chuma_cm = " + Chuma_cm;
//		write "Nhuma_cm = " + Nhuma_cm;
//		write "N lixivié = " + fluxN_lixiviation_cumul_total  + " kg/ha";
//		write "Stock de C = " + (Chum) with_precision 2 + " kg/ha";
//		write "N min = " + Nmin_total + " kg/ha";
//		write "Nres_perdu = " + Nres_perdu;
//		write "Nbio_perdu = " + Nbio_perdu;
//		write "Nbio_recalcitrant_moved = " + Nbio_recalcitrant_moved;
//		write "Nres_recalcitrant_moved = " + Nres_recalcitrant_moved;

				
		// Programmation  manuelle de la fertilisation
		
//		if (first(dateCourante).mois = 5 and first(dateCourante).jour = 10) {
//			do fertilisationN(300.0);
//			do fertilisation("digestat solide", 30000.0);
//		}
		/********************************************************************************************/
		
		eqCO2_emissions_NC <- 0.0;
		eqCO2_emissions_N <- 0.0;
		eqCO2_total <- 0.0;
		eqCO2_total_sansC <- 0.0;

		
		do majEauHorizonsN;
		do majQNhorizons;

		N_nh3_tot <- N_nh3 + N_nh3_pro; // journalier
		float N_nh3_tot_cumul_old <- N_nh3_tot_cumul_tot;
		N_nh3_tot_cumul <- N_nh3_tot_cumul + N_nh3_tot;
		N_nh3_tot_cumul_tot <- N_nh3_tot_cumul_tot + N_nh3_tot;		
		N_nh3_tot2 <- N_nh3_tot_cumul_tot - N_nh3_tot_cumul_old;
		C_stock_cumul <- C_stock_cumul + delta_Chum;
		N_nh3_tot_sortie <- N_nh3_tot; // JV 250522 copie car besoin de cette variable locale dans les sorties
		
		// GHG balance		
		eqCO2_emissions_NC <- 296 * 44/28 * (N_n2o_tot + 0.01 * N_nh3_tot + 0.0075* fluxN_lixiviation) - 44/12 * delta_Chum;
		eqCO2_emissions_NC_cumul <- eqCO2_emissions_NC_cumul + eqCO2_emissions_NC;
		eqCO2_emissions_N <- 296 * 44/28 * (N_n2o_tot + 0.01 * N_nh3_tot + 0.0075* fluxN_lixiviation);
		eqCO2_total <- eqCO2_synthesis + eqCO2_emissions_NC;
		eqCO2_total_sansC <- eqCO2_synthesis + eqCO2_emissions_N;
		
		SOC_perc <- (Chum / (self.ilot_app.sol.daH1 * self.ilot_app.sol.profHum/100* (1-self.ilot_app.sol.tauxGravier/100)*10^4))/10;
		OM_perc <- SOC_perc*1.72;
		SOC_Clay_ratio <- SOC_perc/self.ilot_app.sol.clay;
		SOC_Clay_ratio_year <+ SOC_Clay_ratio;
		eqCO2_total_cumul <- eqCO2_total_cumul + eqCO2_total;
		
		Nlosses <- N_nh3_tot + N_n2o_tot + fluxN_lixiviation + N_n2_denit;
		Nlosses_cumul <- Nlosses_cumul + Nlosses;
		N_n2o_cumul <- N_n2o_cumul + N_n2o_tot;
		// MAJ du stress azoté (réalisée ici pour qu'elle est lieu une fois les flux d'azote mis à jour)
		if (cultureParcelle != nil) {
			ask(cultureParcelle.monModelDeCulture) {
				do calculStressN;
			}
		}
		
		/********************************************************************************************/
		// Daily update to 0 for N variables
		eqCO2_synthesis <- 0.0;

		N_nh3 <- 0.0;
		N_nh3_tot <- 0.0;
		N_nh3_min <- 0.0;
		N_nh3_min_calc <- 0.0;
		N_nh3_pro <- 0.0;
		N_nh3_pro_pot_calc <- 0.0;
		N_nh3_pro_pot <- 0.0;
		N_nh3_min_dir <- 0.0;
		N_nh3_min_dir_calc <- 0.0;
		N_nh3_pro_dir <- 0.0;
		N_nh3_pro_dir_calc <- 0.0;

		QNapport <- 0.0;
		QNapport_min <- 0.0;
		QNapport_min_calc <- 0.0;
		QNapport_pro <- 0.0;
		QNapport_pro_calc <- 0.0;
		QNapport_min_direct <- 0.0;
		QNapport_min_direct_calc <- 0.0;
		QNapport_pro_direct <- 0.0;
		QNapport_pro_direct_calc <- 0.0;
		QNapport_after_volat_j <- 0.0;

		/* JV debug
		if (cultureParcelle != nil) {
			ask(cultureAqYieldNC(cultureParcelle.monModelDeCulture)) {
				if espece.isCouvert {
					if !espece.isLEG {
						write "QN_acquis_cumul=" + QN_acquis_cumul;
					} else {
						write "QN_demande_cumul_stressH=" + QN_demande_cumul_stressH;
					}
				}
			}
		}
		*/
	
	}	
	
	// Mise à jour de l'eau dans les horizons azote
	action majEauHorizonsN {
		HOpPrec <- HOp;
		float RHOrPrec <- RHOr;
		float RHOpPrec <- RHOp;
		
		// Mise à jour de la hauteurs des réservoirs 
		HOr <- max([0, RUr - RUw]);
		HOp <- RUm - RUr;
				
		// Mise à jour des hauteurs d'eau contenues dans les réservoirs
		RHOw <- Hw;
		RHOw_cor <- RHOw + HPFw_mm;
		repart_HO <- min([HOp, max([0, HOpPrec - HOp])]);
		RHOr <- min([Hr - Hw, HOr]);
		RHOr <- max([0, RHOr]); // Modif Renaud pour que RHOr ne soit pas négatif 191221
		RHOp <- max([0, min([Hm - Hr, HOp])]); // Hm - Hr; // Modif Renaud + Hugues 161221 pour pas que RHOp soit négatif quand la prof max est trop proche de R (arrondis à la ***)
		
		// Flux
		flux_RHOwr <- max([0, max([0, HwPrec]) + apportEnEauUtile - evaporation - transpirationW - RUw]);
		flux_RHOrp <- max([0, RHOrPrec + flux_RHOwr - (transpirationR - transpirationW) - HOr + repart_HO]);
		if (HOr = 0) {
			drain_RHOp <- max([0, RHOpPrec + flux_RHOrp - HOp]);
		} else {
			drain_RHOp <- max([0, RHOp + flux_RHOrp - HOp]);
		}
		
		// Actualisation de la profondeur racinaire
		profR <-  RUr / RUw * self.ilot_app.sol.profHum;
	}

	// RESmin_results =  calculation of organic residue mineralization and humification, applied to each pool of residue when incorporated into the soil
	list RESmin_results { // les Nres results sont donnés sous la forme d'une liste contenant : Nres, NresPrec, DNres, situation_res
		
		// Les arguments sont les éléments du calcul qui changent en fonction des résidus
		arg situation_res_arg type: string default: ""; // situation_res = "surface" ou "incorpore"
		arg prof_res_arg type: float default: 0.0;
		arg CNres_arg type: float default: 0.0;
		arg NresPrec_arg type: float default: 0.0;
		arg Nres_arg type: float default: 0.0;
		arg CNbio_pool_arg type: float default: 0.0;
		arg NbioPrec_arg type: float default: 0.0;
		arg Nbio_arg type: float default: 0.0;		
		arg CbioPrec_arg type: float default: 0.0;
		arg Cbio_arg type: float default: 0.0;
		arg Kres_pool_arg type: float default: 0.0;
		arg Yres_pool_arg type: float default: 0.0;
		arg f_reduction_kres_arg type: float default: 1.0;
		arg Hres_pool_arg type: float default: 0.0;		
		arg CNhum_arg type: float default: 0.0;
		arg nomproduit_arg type: string default: "";
		arg res_type_arg type: string default: ""; // NR pool
		
		// Résultats en sortie de fonction
		string situation_res_result <- situation_res_arg;
		string nomproduit_result <- nomproduit_arg;
		string res_type_result <- res_type_arg; // NR pool
		float prof_res_result <- prof_res_arg;
		float NresPrec_result <- Nres_arg;
		float Nres_result <- Nres_arg;				
		float Cres_result <- 0.0;
		float DNres_result <- 0.0;
		float NbioPrec_result <- Nbio_arg;
		float CbioPrec_result <- Cbio_arg;
		float Nbio_result <- 0.0;
		float DNbio_result <- 0.0;
		float DNbio_in_result <- 0.0;
		float DNhumRes_result <- 0.0;
		float DChumRes_result <- 0.0;
		
		float CNbio <- CNbio_pool_arg;
		float CNbio_result <- CNbio;
		float Cbio_result <- 0.0;
		float DCbio_result <- 0.0;
		
		// STICS environmental functions : effects of temperature (fTemp) and moisture (fHum) on residue and zymogenous biomass decomposition
		float fctSTICS_res <- 0.0;


		
		if (situation_res_result != "surface") {
			float fTemp_res <- 0.0;
			if(getTmoy() >= 0) {
				fTemp_res <- 12 / (1 + 52 * exp(-0.103 * getTmoy()));
			}
			
			float fHum_res <- (RHOw_cor - (0.3 * self.ilot_app.sol.HCCw_mm)) / ((1-0.3) * (self.ilot_app.sol.HCCw_mm));
			fHum_res <- max([0, fHum_res]);
			fHum_res <- min([1, fHum_res]);			
			fonction_temp_res <- fTemp_res;
			fonction_hum_res <- fHum_res;
			fctSTICS_res <- fHum_res * fTemp_res;
		}
			
		// RESmin step 1 : organic residue decomposition when incorporated
		if (situation_res_result = "incorpore") {
			// Calcul ou récupération du Kres
			float Kres <- Kres_pool_arg; 
			if (Kres_pool_arg = 0.0 and res_type_result != "residus racinaires") { // NR pool
				Kres <- AKres + (BKres / CNres_arg);
			} else if (Kres_pool_arg = 0.0 and res_type_result = "residus racinaires")  { // NR pool
				Kres <- 0.030 + (1.17/CNres_arg);
			}
			
			DNres_result <- -Kres * fmodK * f_reduction_kres_arg * NresPrec_result * fctSTICS_res; // Toujours négatif			
			Nres_result <- NresPrec_result + DNres_result;
			Cres_result <- Nres_result * CNres_arg;
			
			// RESmin step 2 : zymogenous microbial biomass decomposing organic residues
			if (CNbio_pool_arg = 0.0 and res_type_result = "residus aeriens") { // NR pool
				CNbio <- max([Cwb, Awb + Bwb / CNres_arg]);
				CNbio_result <- CNbio;
			} else if (CNbio_pool_arg = 0.0 and res_type_result = "residus racinaires") { // NR pool
				CNbio <- max([Cwb, 15.4 + (-80) / CNres_arg]);
				CNbio_result <- CNbio;
			}
			
			// Récupération de Yres
			float Yres <- Yres_pool_arg; 
			if (Yres_pool_arg = 0.0) {
				Yres <- Yres_crop;
			}
						
			DNbio_result <- -(Yres * fmodY * DNres_result * CNres_arg / min([CNbio * fNCbio,25.0])) - Kbio * fmodB * NbioPrec_result * fctSTICS_res;
			DCbio_result <- -(Yres * fmodY * DNres_result * CNres_arg) - Kbio * fmodB * CbioPrec_result * fctSTICS_res;
			DNbio_in_result <- -(Yres * DNres_result * CNres_arg / min([CNbio * fNCbio,25.0]));
			Nbio_result <- NbioPrec_result + DNbio_result;
			Cbio_result <- CbioPrec_result + DCbio_result;
			
			if (Nbio_result > 0) {
				CNbio_result <- Cbio_result / Nbio_result;
			}
			
			// RESmin step 3 : humification of microbial biomass
			float Hres <- Hres_pool_arg;
			float CNhumus <- CNhum_arg;
			if (Hres_pool_arg = 0.0 and res_type_result != "residus racinaires"){ // NR pool
				Hres <- 1 - AHres * CNres_arg / (BHres + CNres_arg);
			} else if (Hres_pool_arg = 0.0 and res_type_result = "residus racinaires"){ // NR pool
				Hres <- 1 - 0.78 * CNres_arg / (25.9 + CNres_arg);
			}

			DNhumRes_result <- Kbio * Hres* fmodH * NbioPrec_result * CNbio * fctSTICS_res / CNhumus;
			DChumRes_result <- Kbio * Hres * NbioPrec_result * CNbio * fctSTICS_res;
						
			// RESmin results -> list
			list results <- [Nres_result, NresPrec_result, DNres_result, situation_res_result, prof_res_result, Nbio_result, NbioPrec_result, DNbio_result, DNhumRes_result, CNbio_result,DChumRes_result, Cres_result,Cbio_result, CbioPrec_result, DNbio_in_result];
			return(results);
		}
	}
	
	
	float QNmin_total { // TODO: mauvaise numérotation
		/*************************** CYCLE NC ***************************/
		// 1. Available mineral N at day-1 and mixing of Chum/Nhum if soil tillage 
		// 2. Mineralization of active SOM
		// 2. Microbial demand for mineral N
		// 3. Plant demand for mineral N in W layer
		// 4. Total N demand (microbial  + plant) and allocation of available N
		// 5. Situations with N limitation
		// 6. Residue decomposition and incorporation of residue into the soil
		// 7. Mineralization of active SOM and humification
		// 8. Calculation of variables related to N for figures
		/*************************************************************************** */
		
		// 1. Available mineral N at day-1 including fertilization and mixing of Chum/Nhum if soil tillage is performed at the current day
		QNdispoFerti <- fertilisation_efficace();
		
		if (parcelleAqYieldNC(self).isTravailSolJourCourant_NC and prof_w_sol > 0) {
//			write "prof_w_sol = " + prof_w_sol;
			float Nhuma_prof <- 0.0;
			float Chuma_prof <- 0.0;
			float Nhumi_prof <- 0.0;
			float Chumi_prof <- 0.0;						
			float Nhum_prof <- 0.0;
			float Chum_prof <- 0.0;	
					
//			write "prof redistribution C et N après Wsol ="+ prof_w_sol;
			loop k from: 0 to: int(prof_w_sol) - 1 {
				Nhuma_prof <- Nhuma_prof + Nhuma_cm[k];
				Chuma_prof <- Chuma_prof + Chuma_cm[k];
				Nhumi_prof <- Nhumi_prof + Nhumi_cm[k];
				Chumi_prof <- Chumi_prof + Chumi_cm[k];								
				Nhum_prof <- Nhuma_prof + Nhumi_prof;
				Chum_prof <- Chuma_prof + Chumi_prof;						
			}
			
			float new_Nhuma_prof_cm <- Nhuma_prof / int(prof_w_sol);
			float new_Chuma_prof_cm <- Chuma_prof / int(prof_w_sol);			
			float new_Nhumi_prof_cm <- Nhumi_prof / int(prof_w_sol);
			float new_Chumi_prof_cm <- Chumi_prof / int(prof_w_sol);				
			float new_Nhum_prof_cm <- Nhum_prof / int(prof_w_sol);
			float new_Chum_prof_cm <- Chum_prof / int(prof_w_sol);			
			
			loop k from: 0 to: int(prof_w_sol) - 1 {
				Nhuma_cm[k] <- new_Nhuma_prof_cm;
				Chuma_cm[k] <- new_Chuma_prof_cm;					
				Nhumi_cm[k] <- new_Nhumi_prof_cm;
				Chumi_cm[k] <- new_Chumi_prof_cm;									
				Nhum_cm[k] <- new_Nhum_prof_cm;
				Chum_cm[k] <- new_Chum_prof_cm;								
			}
			
		}
		// 2. Mineralization of active SOM
		// STICS environmental functions : effects of temperature (fTemp) and moisture (fHum) on active SOM decomposition
		float fctSTICS_MO <- 0.0;
		float fTemp_mo <- 0.0;
		if(getTmoy() >= 0) {
			fTemp_mo <- 25 / (1 + 145 * exp(-0.12 * getTmoy()));
		}
		float fHum_mo <- (RHOw_cor - (0.3 * self.ilot_app.sol.HCCw_mm)) / ((1-0.3) * (self.ilot_app.sol.HCCw_mm));
		fHum_mo <- max([0, fHum_mo]);
		fHum_mo <- min([1, fHum_mo]);
		fonction_temp_mo <- fTemp_mo;
		fonction_hum_mo <- fHum_mo;				
		fctSTICS_MO <- fHum_mo * fTemp_mo;
		//write "fHum ="+ fHum_mo;
			
		float gmin1 <- 0.7; // constant of mineralization potential rate day-1, setting similar to STICS
		float DNhum_MO_cm_j <- 0.0;
		float DNhum_MO_cm <- 0.0;
		float DChum_MO_cm <- 0.0;
		fmodP <- 1.0;// factor modulating the priming effect on SOM mineralization
		
		// Loop for each cm over profhum		
		loop i from: 0 to: length(DNhumRes_cm) - 1 {
			float K2pot <- gmin1 * exp(-2.519 * (self.ilot_app.sol.arg_deca * 10) / 1000) * 
				exp(-0.112 * (self.ilot_app.sol.pHsol - 8.5)^2) * (exp(-0.06 * (Chum_cm[i] / Nhum_cm[i] - 11)^2) * 0.8 + 0.2) * 1 /
				(1 + 1.5 * self.ilot_app.sol.calcaire * 10 / 1000);
			float K2 <- K2pot * fctSTICS_MO;
			float DNhum_MO_cm <- -K2 * Nhuma_cm[i]/1000 * fmodP;
			
			//write "DNhum_MO_cm = " + (DNhum_MO_cm) with_precision 8; 						
			DNhum_MO_cm_j <- DNhum_MO_cm_j - DNhum_MO_cm; // total mineral N from humus mineralization over profhum
		}
		DNhum_MO_cm_j_sortie <- DNhum_MO_cm_j; // JV 100522 stockage de la valeur de la variable locale pour la sortie azote
				
		// 2. Calculation of potential residue decomposistion (RESmin) to estimate the microbial demand for mineral N
		float somme_DNminRes <- 0.0;
		fmodK <- 1.0;// factor modulating residue decomposition rate Kres
		fmodB <- 1.0;// factor modulating microbial biomass decomposition rate Kbio
		fNCbio <- 1.0;// factor modulating biomass C:N ratio
		fmodH <- 1.0;// factor modulating the C:N ratio of humified microbial biomass
		fmodP <- 1.0;// factor modulating the priming effect on SOM mineralization
		fmodY <- 1.0;// factor modulating the assimilation yield of organic residue into microbial biomass
		
		
		if (length(Nres) >= 1) {
//			write self.idParcelle + " - mon nb de pools = " + length(Nres);
			loop i from: 0 to: length(Nres) - 1 { // loop applied on each pool of residue
				daysSinceCreation[i] <- daysSinceCreation[i] + 1;
				if(situation_res[i] = "incorpore"){
					list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: 1.0, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i], nomproduit_arg:nomproduit[i],res_type_arg:res_type[i], CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);
					float DNres_i <- float(results[2]);
					float DNbio_i <- float(results[7]);
					float DNhumRes_i <- float(results[8]);
					
					CNbio_pool[i] <- float(results[9]);

					DNminRes_j[i] <- -DNres_i - DNbio_i - DNhumRes_i;
					somme_DNminRes <- somme_DNminRes + DNminRes_j[i];							
				}
			}
		}
		
		// Calculation of potential microbial demand for mineral N = QN_demande_microOrga_
		float QN_demande_microOrga_j <- 0.0;
		if (somme_DNminRes < 0.0) {
			QN_demande_microOrga_j <- abs(somme_DNminRes);
		}
		
		// 3. Evaluating daily plant demand for mineral N in W layer = QNdemande_plante_W_j
		// JV 121224: correction Nirina, auparavant availN_w <- (QNinitialeJ_w + DNhum_MO_cm_j);, cf issue #9
		availN_w <- (QNfinaleJ_w + DNhum_MO_cm_j);
		float availN_w_mic <- 0.0;
		
		float QNdemande_plante_W_j <- 0.0; // demande potentielle de la plante
		if (cultureParcelle != nil) {
			QNdemande_plante_W_j <- cultureParcelle.monModelDeCulture.demande_plante_w(); // NR Herbsim 24/04/2024 - défini pour cultureAqYieldNC et cultureHerbsimNC
		}
		// 4. Calculation of total mineral N demand (microbial  + plant) and allocation of available N when limiting
		float QN_demande_totale_j <- QN_demande_microOrga_j + QNdemande_plante_W_j;			
		
		if (QN_demande_totale_j <= availN_w) {
			availN_w_mic <- QN_demande_microOrga_j;
			availN_w_plant <- availN_w - availN_w_mic;//old = availN_w_plant <- QNdemande_plante_W_j
		// 4.1. if demand is higher than supply, situation with no crop
		} else if (QN_demande_totale_j > availN_w and cultureParcelle = nil) { // 240124 Correction suite à mail Nirina 240124
			availN_w_mic <- availN_w;
		// 4.2. demand is higher than supply, situation with crop	
		} else { //if (QN_demande_totale_j != 0)
//			write "QN_demande_totale_j = " + QN_demande_totale_j;
//			write "QN_demande_microOrga_j = " + QN_demande_microOrga_j;
//			write "availN_w = " + availN_w;
//			write "QNdemande_plante_W_j = " + QNdemande_plante_W_j;
//			write cultureParcelle.espece.idEspeceCultivee;
			
			// Correction à vérifier avec Olivier - Renaud 22/10/2025
			if (QN_demande_totale_j = 0) {
				availN_w_mic <- availN_w * 0.5;
				availN_w_plant <- availN_w * 0.5;
			} else {
				availN_w_mic <- (QN_demande_microOrga_j / QN_demande_totale_j) * availN_w;
				availN_w_plant <- (QNdemande_plante_W_j / QN_demande_totale_j) * availN_w;				
			}

		}

		// 5. Situations with N limitation		
		float Nlim <- 0.0;
		if (QN_demande_microOrga_j > availN_w_mic){
			// 6.1. Step 1 : reduced decomposition rates kres and kbio
			Nlim <- 1.0;
			fmodK <- 0.25;
			fmodB <- 0.5;
			float somme_DNminRes <- 0.0;
			float somme_DNbio_in <- 0.0;
				
			if (length(Nres) >= 1) {
				loop i from: 0 to: length(Nres) - 1 { // loop applied on each pool of residue		
					daysSinceCreation[i] <- daysSinceCreation[i] + 1;
					if (situation_res[i] = "incorpore") {
						list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: 1.0, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i], nomproduit_arg:nomproduit[i],res_type_arg:res_type[i],CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);				
						float DNres_i <- float(results[2]);
						float DNbio_i <- float(results[7]);
						float DNhumRes_i <- float(results[8]);
						float DNbio_in_i <- float(results[14]);
						CNbio_pool[i] <- float(results[9]);
						DNminRes_j[i] <- -DNres_i - DNbio_i - DNhumRes_i;
						somme_DNminRes <- somme_DNminRes + DNminRes_j[i];
						DNbio_in_j[i] <- DNbio_in_i;
						somme_DNbio_in <- somme_DNbio_in + DNbio_in_j[i];
					}
				}
			}			
			float QN_demande_microOrga_j <- 0.0;
			if (somme_DNminRes < 0.0) {
				QN_demande_microOrga_j <- abs(somme_DNminRes);
			}
			
			if (QN_demande_microOrga_j > availN_w_mic and somme_DNbio_in > 10^-6){
				// 6.2. Step 2 : increased C:N ratio of microbial biomass
				Nlim <- 2.0;
				fNCbio <- somme_DNbio_in / (availN_w_mic + somme_DNminRes+somme_DNbio_in);
				
				float somme_DNminRes <- 0.0;
				float somme_DNbio_in <- 0.0;
				
				if (length(Nres) >= 1) {
					loop i from: 0 to: length(Nres) - 1 { // loop applied on each pool of residue		
						daysSinceCreation[i] <- daysSinceCreation[i] + 1;
						if( situation_res[i] = "incorpore") {
							list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: 1.0, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i], nomproduit_arg:nomproduit[i],res_type_arg:res_type[i],CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);				
							float DNres_i <- float(results[2]);
							float DNbio_i <- float(results[7]);
							float DNhumRes_i <- float(results[8]);
							CNbio_pool[i] <- float(results[9]);
							DNminRes_j[i] <- -DNres_i - DNbio_i - DNhumRes_i;
							somme_DNminRes <- somme_DNminRes + DNminRes_j[i];
						}
					}
				}
				float QN_demande_microOrga_j <- 0.0;
				if (somme_DNminRes < 0.0) {
					QN_demande_microOrga_j <- abs(somme_DNminRes);
				}
				
				if (QN_demande_microOrga_j > availN_w_mic){
					// 6.3. Step 3 : increased C:N ratio of humified OM
					Nlim <- 3.0;
					fmodH <- 0.5;
					float somme_DNminRes <- 0.0;
					float somme_DNbio_in <- 0.0;
				
					if (length(Nres) >= 1) {
						loop i from: 0 to: length(Nres) - 1 { // loop applied on each pool of residue		
							daysSinceCreation[i] <- daysSinceCreation[i] + 1;
							if(situation_res[i] = "incorpore"){
								list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: 1.0, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i], nomproduit_arg:nomproduit[i],res_type_arg:res_type[i],CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);				
								float DNres_i <- float(results[2]);
								float DNbio_i <- float(results[7]);
								float DNhumRes_i <- float(results[8]);
								CNbio_pool[i] <- float(results[9]);				
								DNminRes_j[i] <- -DNres_i - DNbio_i - DNhumRes_i;
								somme_DNminRes <- somme_DNminRes + DNminRes_j[i];
							}
						}
					}
					float QN_demande_microOrga_j <- 0.0;
					if (somme_DNminRes < 0.0) {
						QN_demande_microOrga_j <- abs(somme_DNminRes);
					}
					
					if (QN_demande_microOrga_j > availN_w_mic){
						// 6.4. Step 4 : priming effect on active SOM
						Nlim <- 4.0;
						fmodP <- min([(- DNhum_MO_cm_j + availN_w_mic + somme_DNminRes) /(-DNhum_MO_cm_j),3.0]);
						float DNhum_MO_cm_j_primed <- DNhum_MO_cm_j * fmodP;
						availN_w_mic <- availN_w_mic + DNhum_MO_cm_j_primed - DNhum_MO_cm_j;
						
						if (QN_demande_microOrga_j > availN_w_mic){
							// 6.5. Step 5 : decreased assimilation yield of residue into microbial biomass
							Nlim <- 5.0;
							fmodY <- 0.5;
							float somme_DNminRes <- 0.0;
							float somme_DNbio_in <- 0.0;
				
							if (length(Nres) >= 1) {
								loop i from: 0 to: length(Nres) - 1 { // loop applied on each pool of residue		
									daysSinceCreation[i] <- daysSinceCreation[i] + 1;
									if (situation_res[i] = "incorpore") {
										list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: 1.0, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i], nomproduit_arg:nomproduit[i],res_type_arg:res_type[i],CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);				
										float DNres_i <- float(results[2]);
										float DNbio_i <- float(results[7]);
										float DNhumRes_i <- float(results[8]);
										CNbio_pool[i] <- float(results[9]);
										DNminRes_j[i] <- -DNres_i - DNbio_i - DNhumRes_i;
										somme_DNminRes <- somme_DNminRes + DNminRes_j[i];
									}
								}
							}
							float QN_demande_microOrga_j <- 0.0;
							if (somme_DNminRes < 0.0) {
								QN_demande_microOrga_j <- abs(somme_DNminRes);
							}
														
							if (QN_demande_microOrga_j > availN_w_mic){
								// 66. Step 6 : no residue decomposition
								Nlim <- 6.0;
								fmodK <- 0.0;
							}
						}
					}				
				}									
			}		
		}		
		//write "N limiting step = " + Nlim;
		
		// Minéralisation des résidus et distribution des DNHumRes dans les cm de sol
		float DNres_somme <- 0.0;
		float DNbio_somme <- 0.0;

			
		// Remise à 0 du delta de minéralisation humus des résidus par cm
		DNhumRes_cm <- list<float>(list_with(length(DNhumRes_cm), 0.0));
		DChumRes_cm <- list<float>(list_with(length(DChumRes_cm), 0.0));
		DNhumResr <- 0.0;	
		DChumResr <- 0.0;		
		float f_reduction_kres <- 1.0; // suppr
		
		// 6. Calculation of residue decomposition (RESmin_results) and incorporation of residue into the soil
		if (length(Nres) >= 1) {
			loop i from: 0 to: length(Nres) - 1 {
				// Calculation of residue decomposition (RESmin_results) with updated parameters when N is limiting
				if(situation_res[i] = "incorpore"){
					//write "Pool n°" + i + ": " + nomproduit[i] + " --> " + "Prof. = " + (prof_res[i])with_precision 0 + " cm" + " | " + "C:N humifié = " + (CNhum[i])with_precision 4 + " | " +  "C:N res = " + (CNres[i])with_precision 4 + " | " +  "Corg = " + (Cres[i])with_precision 6  +  " & Norg = " + (Nres[i])with_precision 6;										
					// NR pool
					list results <- RESmin_results(CNres_arg: CNres[i], NresPrec_arg: NresPrec[i], Nres_arg: Nres[i], situation_res_arg: situation_res[i], prof_res_arg: prof_res[i], NbioPrec_arg: NbioPrec[i], Nbio_arg: Nbio[i], f_reduction_kres_arg: f_reduction_kres, Kres_pool_arg: Kres_pool[i], Hres_pool_arg: Hres_pool[i], CNbio_pool_arg: CNbio_pool[i], CNhum_arg: CNhum[i],nomproduit_arg:nomproduit[i],res_type_arg:res_type[i],CbioPrec_arg: CbioPrec[i], Cbio_arg: Cbio[i], Yres_pool_arg: Yres_pool[i]);
					//result 0 -> Nres_result
					//result 1 -> NresPrec_result
					//result 2 -> DNres_result
					//result 3 -> situation_res_result
					//result 4 -> prof_res_result
					//result 5 -> Nbio_result
					//result 6 -> NbioPrec_result
					//result 7 -> DNbio_result
					//result 8 -> DNhumRes_result
					//result 10 -> DChumRes_result					
					NresPrec[i] <- float(results[1]);
					Nbio[i] <- float(results[5]);
					NbioPrec[i] <- float(results[6]);
					Cbio[i] <- float(results[12]);
					CbioPrec[i] <- float(results[13]);
					
					
					if (situation_res[i] != "surface" and pool_type[i] = "labile") {
						//write "prof_res i pour DNhumres_par_cm = " +prof_res[i];
						float DNhumRes_par_cm <- float(results[8]) / prof_res[i];
						float DChumRes_par_cm <- float(results[10]) / prof_res[i];
						loop j from: 0 to: int(prof_res[i]) - 1 {
							DNhumRes_cm[j] <- DNhumRes_cm[j] + DNhumRes_par_cm;
							DChumRes_cm[j] <- DChumRes_cm[j] + DChumRes_par_cm;
						}
					}
					
					// Si travail du sol le jour courant --> actualisation de la profondeur d'enfouissement
					if(prof_res[i] < prof_w_sol and parcelleAqYieldNC(self).isTravailSolJourCourant_NC) {
						// Changement de la profondeur d'enfouissement
						prof_res[i] <- prof_w_sol;
					}
					
					// Update des sommes DN par pool (sur l'ensemble de profHum
					DNres_somme <- DNres_somme + float(results[2]);
					DNbio_somme <- DNbio_somme + float(results[7]);
					
					// MaJ des pools de résidu
					Nres[i] <- float(results[0]);
					Cres[i] <- float(results[11]);

					//write "Pool n°" + i + ": " + nomproduit[i] + " --> " + "Prof. = " + (prof_res[i])with_precision 0 + " cm" + " | " + "C:N humifié = " + (CNhum[i])with_precision 4 + " | " +  "C:N res = " + (CNres[i])with_precision 4 + " | " +  "Corg = " + (Cres[i])with_precision 6  +  " & Norg = " + (Nres[i])with_precision 6;					
				}

				//  Incorporation of residue into the soil at the end of the day if soil tillage is performed
				if(situation_res[i] = "surface" and isTravailSolJourCourant_NC) {
					if (pool_type[i] = "labile") {
						situation_res[i] <- "incorpore";
						prof_res[i] <- prof_w_sol;
						//write "prof residue labile = " + prof_w_sol;
						CNhum[i] <- calculCNhum(prof_res[i]);
					} else if (pool_type[i] = "recalcitrant") {
						situation_res[i] <- "incorpore";
						prof_res[i] <- prof_w_sol;
						//write "C PRO recalc = " + Cres[i];
						//write "N PRO recalc = " + Nres[i];
						//write "prof PRO recalc resi = " + prof_res[i];	
						loop j from: 0 to: prof_res[i] - 1 {
							// Recalcitrant pools of residues are directly moved into active SOM
							Nhuma_cm[j] <- Nhuma_cm[j] + (Nres[i] / prof_res[i]);
							Chuma_cm[j] <- Chuma_cm[j] + (Cres[i] / prof_res[i]);				
						}	
						DNhumResr <- Nres[i];
						DChumResr <- Cres[i];
						//write "DNhumResr = " + DNhumResr; // variation in humified N from recalcitrant part of  residue into active SOM
					}
				}			
			}
			
			// Removal of a pool of residue if:
			// - Nbio pool becomes too little for labile pool decomposing
			// - the recalcitrant pool has been moved into active SOM
			int resToSupr_Nbio <- Nbio count (each < 1);//0.01
			
			if (resToSupr_Nbio >= 1) {
				list<int> resToSupr <- [];
				loop i from: 0 to: length(Nres) - 1 {
//					write "Pool de résidus " + i + " Nres -> " + Nres[i];
//					write "Pool de résidus " + i + " Nbio -> " + Nbio[i];
//					write " Pool à supprimer -> " + (Nbio[i] < 1 and Nres[i] < 0.1);
					if (Nbio[i] < 1 and Nres[i] < 0.1) {//0.1
						resToSupr <+ i;
						Nres_perdu <- Nres_perdu + Nres[i]; // To suppr ?
						Nbio_perdu <- Nbio_perdu + Nbio[i]; // To suppr ?
						// Si le résidu est en surface, on considère qu'il est incorporé au premier cm du sol
						if (prof_res[i] = 0) {
							prof_res[i] <- 1;
						}
						loop j from: 0 to: prof_res[i] - 1 {
							// Remaining pools of residues are directly moved into active SOM
							Nhuma_cm[j] <- Nhuma_cm[j] + ((Nres[i] + Nbio[i]) / prof_res[i]);
							Chuma_cm[j] <- Chuma_cm[j] + ((Cres[i] + Cbio[i]) / prof_res[i]);		
						}
					}
					if (!(resToSupr contains i) and situation_res[i] = "incorpore" and pool_type[i] = "recalcitrant") {
						resToSupr <+ i;
//						Nres_recalcitrant_moved <- Nres_recalcitrant_moved + Nres[i]; // To suppr ?
//						Nbio_recalcitrant_moved <- Nbio_recalcitrant_moved + Nbio[i]; // To suppr ?					
					}					
				}
//				write "Il y a " + length(resToSupr) + " pool(s) à supprimer";
				if (length(resToSupr) > 0) {
					int nb_pools_suppr <- 0;
					loop num_pool over: resToSupr {
//						write 'Tentative de suppression du pool n° ' + resToSupr[0] + " " + nomproduit[resToSupr[0]] + " (reste " + length(situation_res) + " pools)";
						int nouveau_numero_pool <- num_pool - nb_pools_suppr;
						situation_res[] >>- nouveau_numero_pool;
						prof_res[] >>- nouveau_numero_pool;
						Cres[] >>- nouveau_numero_pool;
						Nres[] >>- nouveau_numero_pool;
						NresPrec[] >>- nouveau_numero_pool;
						DNres[] >>- nouveau_numero_pool;
						Nbio[] >>- nouveau_numero_pool;
						NbioPrec[] >>- nouveau_numero_pool;
						Cbio[] >>- nouveau_numero_pool;
						CbioPrec[] >>- nouveau_numero_pool;
						DNbio[] >>- nouveau_numero_pool;
						DNhum[] >>- nouveau_numero_pool;
						CNres[] >>- nouveau_numero_pool;
						DNminRes_j[] >>- nouveau_numero_pool;
						daysSinceCreation[] >>- nouveau_numero_pool;
						Kres_pool[] >>- nouveau_numero_pool;
						Hres_pool[] >>- nouveau_numero_pool;
						CNbio_pool[] >>- nouveau_numero_pool;
						pool_type[] >>- nouveau_numero_pool;
						CNhum[] >>- nouveau_numero_pool;
						nomproduit[] >>- nouveau_numero_pool;
						res_type[] >>- nouveau_numero_pool;
						DNbio_in_j[] >>- nouveau_numero_pool;
						
						nb_pools_suppr <- nb_pools_suppr + 1;
						
//						write 'Pool n° ' + nouveau_numero_pool + " supprimé (reste " + length(situation_res) + " pools)";
//						write "Déjà " + nb_pools_suppr + " pools supprimés";
					}
				}
			}
		}
		
//		write "N limiting step = " + Nlim;
//		write "fmodK = " + fmodK;
//		write "fmodB = " + fmodB;
//		write "fNCbio = " + fNCbio;
//		write "fmodH = " + fmodH;
//		write "fmodP = " + fmodP;
//		write "fmodY = " + fmodY;
		
		Nlimiting_step <- Nlim;
		
		parcelleAqYieldNC(self).isTravailSolJourCourant_NC <- false;
		
		// 7. Mineralization of active SOM and humification
		NminMO_cumulPrec <- NminMO_cumul;
		loop i from: 0 to: length(DNhumRes_cm) - 1 {
			float K2pot <- gmin1 * exp(-2.519 * (self.ilot_app.sol.arg_deca * 10) / 1000) * 
				exp(-0.112 * (self.ilot_app.sol.pHsol - 8.5)^2) * (exp(-0.06 * (Chum_cm[i] / Nhum_cm[i] - 11)^2) * 0.8 + 0.2) * 1 /
				(1 + 1.5 * self.ilot_app.sol.calcaire * 10 / 1000);
			float K2 <- K2pot * fctSTICS_MO;
			float DNhum_MO_cm <- -K2 * Nhuma_cm[i]/1000 * fmodP;
			
			NminMO_cumul <- - DNhum_MO_cm + NminMO_cumulPrec;
			
			float DChum_MO_cm <- DNhum_MO_cm * Chuma_cm[i] / Nhuma_cm[i];
			float DNhuma_cm <- DNhumRes_cm[i] + DNhum_MO_cm;
			float DChuma_cm <- DChumRes_cm[i] + DChum_MO_cm;// a modifier avec calcul de DChumRes
			
			Nhuma_cm[i] <- Nhuma_cm[i] + DNhuma_cm;
			Chuma_cm[i] <- Chuma_cm[i] + DChuma_cm ;						
		}
		
		// 8. Calculation of variables related to N for figures
		NhumRes <- NhumRes + sum(DNhumRes_cm)+DNhumResr;		//+DNhumResr
		ChumRes <- ChumRes + sum(DChumRes_cm)+DChumResr;
		NMOmin <- NMOmin + DNhum_MO_cm_j;
		NminRes <- - DNres_somme - DNbio_somme - sum(DNhumRes_cm);
		NminRes_cumul <- NminRes_cumul + NminRes;
		Nmin_som_res_cumul <- NminRes_cumul + NMOmin;
		Nmin_total <- NminRes + DNhum_MO_cm_j;
		Nmin_cumul <- Nmin_cumul + Nmin_total;
//		write "NMOmin = " + (NMOmin) with_precision 8;
//		write "Argile = " + self.ilot_app.sol.clay;
//		write "Taux de cailloux = " + self.ilot_app.sol.tauxGravier;
//		write "Finert = " + self.ilot_app.sol.Finert;
//		write "Calcaire = " + self.ilot_app.sol.calcaire;
//		write "Profhum = " + self.ilot_app.sol.profHum;
				
		// Nitrous oxide emissions = by nitrification (SystN formalisms)
		if (Nmin_total > 0){
			N_n2o_nit <- Nmin_total * 0.0006;
		} else {
			N_n2o_nit <- 0.0;
		}
						
		float QNtotal <- QNdispoFerti + Nmin_total-N_n2o_nit;
		iBio_QNapport_min <- iBio_QNapport_min + QNdispoFerti;
		QNdispoFerti <- 0.0;
		
		if (first(dateCourante).mois = 1 and first(dateCourante).jour = 1) { // Jours normalisés forcés à 0 
			//Nmin_total_cumul <- 0.0;
		} else {
			//Nmin_total_cumul <- Nmin_total;
		}
		return QNtotal; 
	}
	// End QNmin_total


//********************************************************************************************************************************************	
	// Calcul de la fertilisation efficace
	float fertilisation_efficace {
		float fertilisation_efficace_j <- 0.0;
		// direct N inputs from liquid fertilizers (organic + mineral)
		if (QNapport_direct_after_volat > 0.0){
			fertilisation_efficace_j <- QNapport_direct_after_volat;
			QNapport_direct_after_volat <- 0.0;
		}
		// N inputs from solid fertilizers (organic and mineral) remaining at soil surface
		if (QNapport_after_volat_j > 0.0){
			QNapport_after_volat <- QNapport_after_volat + QNapport_after_volat_j;
		}
		// Volatilization of N inputs from solid fertilizers (organic)
		// For organic residues with %hum >= 80, if soil tillage -> moved directly to soil N mineral pool
		if (N_nh3_pro_hum_pot_sol > 0.0){
			if(parcelleAqYieldNC(self).isTravailSolJourCourant_NC){
				nb_of_days_wo_tillage <- nb_of_days_wo_tillage + 0;
				nb_of_days_wo_tillage_prec <- nb_of_days_wo_tillage;				
			} else {
				nb_of_days_wo_tillage <- nb_of_days_wo_tillage + 1;
				nb_of_days_wo_tillage_prec <- nb_of_days_wo_tillage - 1;
			}
			if(nb_of_days_wo_tillage = 0) {
				N_nh3_pro <- N_nh3_pro + 0.2*N_nh3_pro_hum_pot_sol;			
				fertilisation_efficace_j <- fertilisation_efficace_j +  N_nh3_pro_hum_pot_sol*0.8;
				N_nh3_pro_hum_pot_sol <- 0.0;
			} else if (nb_of_days_wo_tillage = 1){
				if (nb_of_days_wo_tillage_prec = 0){
					N_nh3_pro <- N_nh3_pro + 0.2 * N_nh3_pro_hum_pot_sol;
					N_nh3_pro_hum_pot_sol <- 0.8 * N_nh3_pro_hum_pot_sol;						
				}
				if (nb_of_days_wo_tillage_prec = 1){
					N_nh3_pro <- N_nh3_pro + 0.5*N_nh3_pro_hum_pot_sol/0.8 - 0.2*N_nh3_pro_hum_pot_sol/0.8;
					fertilisation_efficace_j <- fertilisation_efficace_j + 0.5*N_nh3_pro_hum_pot_sol/0.8;
					N_nh3_pro_hum_pot_sol <- 0.0;
					nb_of_days_wo_tillage <- 0;								
				}			
			} else if (nb_of_days_wo_tillage > 1){
				N_nh3_pro <- N_nh3_pro + (1.0-0.2) * N_nh3_pro_hum_pot_sol/0.8;
				N_nh3_pro_hum_pot_sol <- 0.0;
				nb_of_days_wo_tillage <- 0;				
			}	
		}
		// For organic residues with %hum < 80, if soil tillage -> moved to N pool "protected from volat" at soil surface (QNapport_after_volat) awaiting a significant water input		
		if (N_nh3_pro_pot_sol > 0.0){
			if(parcelleAqYieldNC(self).isTravailSolJourCourant_NC){
				nb_of_days_wo_tillage <- nb_of_days_wo_tillage + 0;
				nb_of_days_wo_tillage_prec <- nb_of_days_wo_tillage;				
			} else {
				nb_of_days_wo_tillage <- nb_of_days_wo_tillage + 1;
				nb_of_days_wo_tillage_prec <- nb_of_days_wo_tillage - 1;
			}
			if(nb_of_days_wo_tillage = 0) {
				N_nh3_pro <- N_nh3_pro + 0.2*N_nh3_pro_pot_sol;			
				QNapport_after_volat <- QNapport_after_volat + N_nh3_pro_pot_sol*0.8;
				N_nh3_pro_pot_sol <- 0.0;
			} else if (nb_of_days_wo_tillage = 1){
				if (nb_of_days_wo_tillage_prec = 0){
					N_nh3_pro <- N_nh3_pro +  0.2 * N_nh3_pro_pot_sol;
					N_nh3_pro_pot_sol <- 0.8 * N_nh3_pro_pot_sol;						
				}
				if (nb_of_days_wo_tillage_prec = 1){
					N_nh3_pro <- N_nh3_pro + 0.5*N_nh3_pro_pot_sol/0.8- 0.2*N_nh3_pro_pot_sol/0.8;
					QNapport_after_volat <- QNapport_after_volat + 0.5*N_nh3_pro_pot_sol/0.8- 0.2*N_nh3_pro_pot_sol/0.8;
					N_nh3_pro_pot_sol <- 0.0;
					nb_of_days_wo_tillage <- 0;								
				}			
			} else if (nb_of_days_wo_tillage > 1){
				N_nh3_pro <- N_nh3_pro + (1.0-0.2) * N_nh3_pro_pot_sol/0.8;
				N_nh3_pro_pot_sol <- 0.0;
				nb_of_days_wo_tillage <- 0;				
			}	
		}
		// N inputs from solid fertilizer are dissolved and available as mineral N in soil when a significant amount of water is added		
		if (QNapport_after_volat > 0.0 and precipitationDepuisApportN >= seuilDispoN){
			fertilisation_efficace_j <- fertilisation_efficace_j + QNapport_after_volat * CAU;
			QNapport_after_volat <- 0.0;
			precipitationDepuisApportN <- 0.0;
		} else if(QNapport_after_volat > 0.0 and precipitationDepuisApportN < seuilDispoN) {
			precipitationDepuisApportN <- precipitationDepuisApportN + apportEnEauUtile;
		}									
		return fertilisation_efficace_j;
	}
	
	// Mise à jour de l'azote dans les horizons NC
	action majQNhorizons {
				
		// Mise à 0 des variables de cumul pour bilan N et pour les sorties
		if (first(dateCourante).mois = 1 and first(dateCourante).jour = 1) { // Jours normalisés forcés à 0 
			fluxN_lixiviation_cumul <- 0.0;
			eqCO2_total_cumul <- 0.0;
			N_nh3_tot_cumul <- 0.0;
			tps_travail_Ferti_cumul <- 0.0;
			prixFerti_cumul <- 0.0;
			N_n2o_cumul <- 0.0;
			C_stock_cumul <- 0.0;
			eqCO2_synthesis_cumul <- 0.0;
			eqCO2_Nmineral_synthesis_cumul <- 0.0;
			eqCO2_emissions_NC_cumul <- 0.0;
			Nmin_som_res_cumul <- 0.0;
		}
		
		//  1. Calcul de la quantité d'azote intiale au jour J dans chaque horizon
		// 1.1 Quantité d'N initiale de l'horizon W
		QNinitialeJ_wPrec <- QNinitialeJ_w;
		QNinitialeJ_w <- max([0, QNfinaleJ_w + QNmin_total()]);		
		//write "Delta QNinitialeJ_w = " + (QNinitialeJ_w - QNinitialeJ_wPrec);
		
		// 1.2 Quantité d'N initiale de l'horizon R
		float repartN <- 0.0; // Azote récupéré par R lorsque P diminue
		if (HOr > 0){
			if(HOp > 0 and HOpPrec > 0) {
				repartN <- repart_HO * QNfinaleJ_p / HOpPrec;
			}
			QNinitialeJ_r <- QNfinaleJ_r + repartN;
		} 
//		else if (HOr =le 0 and QNfinaJ_r > 0) {
//			QNfinaleJ_p <- QNfinaleJ_p + QNfinaleJ_r;
//			QNfinaleJ_r <- 0.0;
//		}
		repartN_cumul <- repartN;
		
		// 1.3 Quantité d'N initiale de l'horizon P
		if (HOp > 0){
			if(HOr = 0){
				QNinitialeJ_p <- max([0, QNfinaleJ_p]);
				if (QNinitialeJ_r > 0) {
					QNinitialeJ_p <- QNinitialeJ_p + QNinitialeJ_r;
					QNinitialeJ_r <- 0.0;
					QNfinaleJ_r <- 0.0;
				} 
			} else {
				QNinitialeJ_p <- max([0, QNfinaleJ_p - repartN]);
			} 
		}
		// 2. Consommation de l'Azote par la plante dans les horizons w et r
		if(cultureParcelle != nil) {
			// Consommation de l'azote par la plante
			// POur culture HerbSimNC : incorporation des pools liés à la sénescence des feuilles et à la rhizodéposition
			ask(cultureParcelle.monModelDeCulture) {
				do consommationN;
				if (self.dates_incorporation_BM_senescent contains dateCour.nbJoursEcoulesDansAnnee and species(self) = cultureHerbSimNC){
					do incorporation_BM_senescent;
				}
				if (self.dates_incorporation_BM_racines contains dateCour.nbJoursEcoulesDansAnnee and species(self) = cultureHerbSimNC){
					do incorporation_BM_racines;
				}
			}
			
			// Acquisition dans les horizons
			float QNacquis_w <- cultureParcelle.monModelDeCulture.QNacq_w(profR: profR, profW: self.ilot_app.sol.profHum, QNinitialeJ_w_arg: QNinitialeJ_w, QNfinaleJ_r_arg: QNfinaleJ_r, QN_acquis_arg: cultureParcelle.monModelDeCulture.QN_acquis); // NR Herbsim 16/05/2024 - Défini pour tout les types de modèle de culture (valable uniquement pour les NC, mais ne sera appelé que si AcqYieldNC est actif)
			float QNacquis_r <- cultureParcelle.monModelDeCulture.QNacq_r(profR: profR, profW: self.ilot_app.sol.profHum, QNinitialeJ_w_arg: QNinitialeJ_w, QNfinaleJ_r_arg: QNfinaleJ_r,  QN_acquis_arg: cultureParcelle.monModelDeCulture.QN_acquis); // NR Herbsim 16/05/2024 - Défini pour tout les types de modèle de culture (valable uniquement pour les NC, mais ne sera appelé que si AcqYieldNC est actif)

			QNapresConsoJ_w <- QNinitialeJ_w - QNacquis_w;
			QNapresConsoJ_r <- QNinitialeJ_r -	QNacquis_r;
		} else {
			QNapresConsoJ_w <- QNinitialeJ_w;
			QNapresConsoJ_r <- QNinitialeJ_r;
		}

		// 2.bis Nitrous oxide emissions : denitrification (SystN formalisms)
		
		float soil_mass_profDenit <- profDenit / 100 * self.ilot_app.sol.daH1 * 10000 * (100 - self.ilot_app.sol.tauxGravier) / 100 * 1000; // soil mass affected by denitrification (in kg/ha) HC 230524
		float Dp <- 0.0; // denitrification potential (in kg N-N2O/ha/day) HC 230524
		
		if (denit_pot_option = "fixed"){
			Dp <- 0.1 * profDenit; //potential denitrification parameter 0.1 kg N/ha per cm HC 230524				
		}
		if (denit_pot_option = "fCorg"){
			Dp <- max([1,min([1+(20-1) * ((self.ilot_app.sol.OM_perc/1.72)-1)/(6-1),20])]) * soil_mass_profDenit * 10^-6; //HC 230524 --> formalisme STICS Leonard 2016 (doc STICS)
		}
		
		//float Dp <- 0.1 * 20; //ilot_app.sol.profHum; // potential denitrification parameter 0.1 kg N/ha per cm -> 20 cm max for denitrification in STICS, profHum here //HC 230524
		
		float Da <- 0.0;
		float ratiodenit <- 0.0;// Modif ratio dénit hugues 220115 --> ratio de dénitrification		
		
		if (QNapresConsoJ_w >= Dp){
			float Fn <- (QNapresConsoJ_w*10^6/ilot_app.sol.Soil_mass_profHum)/(QNapresConsoJ_w*10^6/ilot_app.sol.Soil_mass_profHum+22);
			float porosity <- 1-((2.65*ilot_app.sol.tauxGravier + ilot_app.sol.daH1*(100-ilot_app.sol.tauxGravier))/100)/2.65; // 2.65 = densité des éléments minéraux

			// float wfps <- (RHOw_cor/ilot_app.sol.profHum/10)/porosity; // remplacer par la ligne ci-dessous 220115 
			float wfps <- ((RHOw_cor+flux_RHOwr)/ilot_app.sol.profHum/10)/porosity;// test hugues 220115 ajout de flux_RHOwr pour saturer en eau au delà de HCC l'horizon w 
			wfps <- min([wfps,1.0]);
			
			float Fw <-0.0;
			if (wfps < 0.62){
				Fw <- 0.0;
			} else {
				Fw <- ((wfps-0.62)/(1-0.62))^1.74;
			}
			Fw <- min([Fw,1.0]);	   
			
			float Ft <- 0.0;
			if (denit_fTemp_option = "SystN"){
				if (getTmoy() < 11.0){
					Ft <- exp(((getTmoy()-11)*ln(89)-9*ln(2.1))/10);
				} else {
					Ft <- exp((getTmoy()-20)*ln(2.1)/10);
				}	
			}
			if (denit_fTemp_option = "Stics"){
				Ft <- exp(-((getTmoy()-47)^2/(25^2)));			
			}
			
			float FpH <- 0.0;
			if (self.ilot_app.sol.pHsol < 4.0){
				FpH <- 0.0;
			} else {
				FpH <- 1.0;
			}		
			Da <- Dp*Fn*Fw*Ft*FpH;// denitrification rate
			
			// Modif ratio dénit 220115 : Calcul du ratio de dénitrification (N2O / Ndénitrifié total) en fonction du ph, du traux de saturation en eau du sol (wfps) et des concentrations en nitrate (N minéral ici)
			float ratiodenit_FpH <- 1.0;
			if (ilot_app.sol.pHsol < 5.6) { // Fonction valable à un wfps à 85 %
				ratiodenit_FpH <- 1.0;
			} else if (ilot_app.sol.pHsol > 9.2) {
				ratiodenit_FpH <- 0.0;
			} else {
				ratiodenit_FpH <- -1 / (9.2 - 5.6) * ilot_app.sol.pHsol + 2.556;
			}
			
			float Fwfps_ratiodenit_0815 <- 1 - (0.815-0.62)/(1-0.62);
			float Fwfps_ratiodenit <- 1.0;
			
			if (wfps < 0.62){
				Fwfps_ratiodenit <- 1.0;
			} else {
				Fwfps_ratiodenit <- 1 - (wfps-0.62)/(1-0.62);
			}
			
			float Fn_ratiodenit <-  (QNapresConsoJ_w*10^6/ilot_app.sol.Soil_mass_profHum)/(QNapresConsoJ_w*10^6/ilot_app.sol.Soil_mass_profHum+1);//test hugues 220115
			float ratiodenit_cor <- ratiodenit_FpH/(Fwfps_ratiodenit_0815);
			ratiodenit <- ratiodenit_cor * Fwfps_ratiodenit * Fn_ratiodenit;
			ratiodenit <- min([ratiodenit, 1]); // Correction Hugues et Renaud 23052023 
			
	
		} else {
			Da <- 0.0;
		}

		N_n2o_denit <- Da * ratiodenit;// Modif ratio dénit hugues 220115 ratiodenit au lieu de 0.2
		N_n2_denit <- Da - N_n2o_denit;
		N_n2o_tot <- N_n2o_nit+N_n2o_denit;

		//write "N-N2O nitrification (kg/ha) = " + N_n2o_nit;
		//write "N-N2O denit kg.ha = " +N_n2o_denit;
		//write "N-N2 denit kg.ha = " +N_n2_denit;
		//write "N denitrification = " +Da;													 
		// update QNapresConsoJ_w with N losses by denitrification (N2 + N2O)
		QNapresConsoJ_w <- QNapresConsoJ_w - Da;

		// 3.  Flux d'azote entre les horizons

		if(RHOw = 0) {//hugues -> rajout condition car si RHOw = 0 -> erreur car division par 0
			fluxN_wr <- 0.0;
		} else {
			fluxN_wr <- min([QNapresConsoJ_w, QNapresConsoJ_w * flux_RHOwr  * ((flux_RHOwr  / (flux_RHOwr  + (self.ilot_app.sol.HCCw * self.ilot_app.sol.daH1 / 100)))^25) / RHOw]);
		}		
	
		if(HOr = 0 or RHOr = 0) {//hugues -> ajout (HOr or RHOr) car le calcul suivant dépend de la hauteur d'eau RHOr et pas de la RU (= HOr)
			fluxN_rp <- 0.0;
		} else {
			if(cultureParcelle != nil) {
				fluxN_rp <- min([QNapresConsoJ_r, QNapresConsoJ_r * flux_RHOrp * ((flux_RHOrp  /( flux_RHOrp  +(self.ilot_app.sol.HCCw * self.ilot_app.sol.daH1/100)))^25) / RHOr]);
			}
		}
		
		if((self.ilot_app.sol.profondeurMax - profR <= 0 or HOp = 0 or RHOp = 0) and RHOr > 0) { // Ajout 12/02/19 -->  "or RHOp = 0" à checker avec Julie
			fluxN_lixiviation <- fluxN_rp;
		} else if (RHOp = 0 and RHOr = 0) {
			fluxN_lixiviation <- fluxN_wr; // Ajout 161221 Renaud + Hugues pour régler le problème entrainé par l'absence d'horizon R ET P
		} else {
			fluxN_lixiviation <- min([QNinitialeJ_p, QNinitialeJ_p * drain_RHOp  * ((drain_RHOp  /( drain_RHOp  +(self.ilot_app.sol.HCCw * self.ilot_app.sol.daH1/100)))^25) / RHOp]);
		}
		
		
		fluxN_lixiviation_cumul <- fluxN_lixiviation_cumul + fluxN_lixiviation;
		fluxN_lixiviation_cumul_total <- fluxN_lixiviation_cumul_total + fluxN_lixiviation;
		
		// 4. Calcul de la quantité d'azote finale dans chaque horizon
		// 4.1 Azote de l'horizon de surface
		QNfinaleJ_w <- QNapresConsoJ_w - fluxN_wr;

		// Azote de l'horizon racinaire et azote de l'horizon profond
		if(HOr = 0) {
			QNfinaleJ_r <- 0.0;
			QNfinaleJ_p <- QNinitialeJ_p + fluxN_wr + fluxN_rp - fluxN_lixiviation;
		} else {
			QNfinaleJ_r <- QNapresConsoJ_r - fluxN_rp + fluxN_wr;
			QNfinaleJ_p <- QNinitialeJ_p + fluxN_rp - fluxN_lixiviation;
		}
		
		// Réinitialisation de l'azote pour comparaison avec excel
//		if (first(dateCourante).mois = 9 and first(dateCourante).jour = 1) { // Jours normalisés forcés à 0 
//			QNfinaleJ_w <- 20.0;
//			QNfinaleJ_r <- 0.0;
//			QNfinaleJ_p <- 40.0;
//		}
		
		// A supprimer TODO
		// Réinitialisation au premier janvier pour comparaison avec Excel
//		if (first(dateCourante).mois = 7 and first(dateCourante).jour = 15) { // Jours normalisés forcés à 0 
//			// Bilan d'azote annuel
//			float entreesN <- QNfinaleJ_w_init + QNfinaleJ_r_init + QNfinaleJ_p_init + Nmin_total;
//			float sortiesN <-  QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p + sortie_acquisition + fluxN_lixiviation_cumul-N_n2o_nit; // + sum(Nbio) = hug normalement non car le prélévement par la biomasse mic est intégré à Nmin_total
//			float bilanN <- entreesN - sortiesN;
//		}
	}

	float QNacq_pot {
		arg availN_w_arg type: float default: 1.0; 
		
		float resultat <- 0.0;
		if ((availN_w_arg + QNfinaleJ_r) > 1.5) {
			
			resultat <- 1.5 + transpirationR * (availN_w_arg + QNfinaleJ_r - 1.5) / (max([0.01, RHOw]) + RHOr); // Correction HC OT NR RM 290124
		} else {
			resultat <- transpirationR * (availN_w_arg + QNfinaleJ_r) / (max([0.01, RHOw]) + RHOr);
		}
		
		//resultat <- max([(QNinitialeJ_w + QNfinaleJ_r), 1.5]) + transpirationR * (QNinitialeJ_w + QNfinaleJ_r) / (max([0.01, RHOw]) + RHOr); // Corrigé par Hugues et Renaud le 14/05/2020
		QN_pot <- resultat;
		
		return resultat;
	}
	
	float calculCNhum (float prof) {
		float Nhum_prof_res <- 0.0;
		float Chum_prof_res <- 0.0;
		loop k from: 0 to: int(prof) - 1 {
			Nhum_prof_res <- Nhum_prof_res + Nhum_cm[k];
			Chum_prof_res <- Chum_prof_res + Chum_cm[k];
		}
		float CNhum_result <- Chum_prof_res / Nhum_prof_res;
		
		return(CNhum_result);
	}
	
	// Ajout d'un pool de résidus
	// TODO documenter les variables de AddPoolResidus
	// res_type : soit "residus racinaires" soit "residus aeriens"
	action AddPoolResidus (float CNres_arg, string situationres_arg, float masse_carbone_arg, float masse_azote_arg, string nom_produit,string res_type_arg, string pool_type_arg, float Kres_pool_arg, float Hres_pool_arg, float CNbio_pool_arg, float Yres_pool_arg) { // NR pool	
		if (!(res_type_arg in ["residus racinaires","residus aeriens","PRO"])){
			warn "ERREUR ! L'argument res_type_arg de AddPoolResidus doit être au choix 'residus aeriens','residus racinaires' ou 'PRO'.";
		}
		//write "!! add pool résidus !! CNres_arg: " + CNres_arg + "// situationres_arg: " + situationres_arg + "// masse_azote_arg: " + masse_azote_arg + "// mass_carbone_arg = " + masse_carbone_arg;
		//write "!! add pool résidus !! nom produit: " + nom_produit + "// res_type_arg: " + res_type_arg + "// pool_type_arg: " + pool_type_arg;
		//write "!! add pool résidus !! Kres_pool_arg: " + Kres_pool_arg + "// Hres_pool_arg: " + Hres_pool_arg + "// CNbio_pool_arg: " + CNbio_pool_arg + "// Yres_pool_arg = " + Yres_pool_arg;
//		write "add pool résidus = " + nom_produit + " -- " + situationres_arg + " -- masse N = " + masse_azote_arg + " -- masse C = " + masse_carbone_arg;

		// Situation du pool de résidus ou de PRO
		situation_res <+ situationres_arg; // "incorpore" ou "surface"		

		// Résidus incorporés (soit racine, soit incorporation directe --> pour l'instant, juste racines)
		if (situationres_arg = "incorpore") {
			prof_res <+ ilot_app.sol.profHum;
			// Calcul de la valeur de CN entrant dans le calcul de DNhum_res
			// Somme de Nhum et Chum pour le calcul de CNhum au moment de l'enfouissement du pool
			CNhum <+ calculCNhum(ilot_app.sol.profHum);// ajouté en dessous sortie de la boucle
		} else if (situationres_arg = "restitution_animale") {
			prof_res <+ 5.0; // Enfouissement des restitutions animales à 5 cm
			situationres_arg <- "incorpore";
			CNhum <+ calculCNhum(5.0);// ajouté en dessous sortie de la boucle	
		} else { // Résidus situés en surface
			prof_res <+ 0.0;
			CNhum <+ 0.0; // Le CN sera calculé au moment de l'incorporation
		}

		nomproduit <+ nom_produit;
		res_type <+ res_type_arg; // NR pool
		Cres <+ masse_carbone_arg;
		Nres <+ masse_azote_arg; // N décomposable
		daysSinceCreation <+ 0;
		CNres <+ CNres_arg; // CN du pool
		NresPrec <+ 0.0;
		DNres <+ 0.0;
		Nbio <+ 0.0;
		NbioPrec <+ 0.0;
		Cbio <+ 0.0;
		CbioPrec <+ 0.0;
		DNbio <+ 0.0;
		DNhum <+ 0.0;
		DNminRes_j <+ 0.0;
		Kres_pool <+ Kres_pool_arg;
		Yres_pool <+ Yres_pool_arg;
		Hres_pool <+ Hres_pool_arg;
		CNbio_pool <+ CNbio_pool_arg;
		pool_type <+ pool_type_arg;
		DNbio_in_j <+ 0.0;	
		
		// Ecriture dans un vecteur de stockage pour écriture dans la sortie à la fin de l'année (sortie = resultatsSuivi_ajout_pools_residus.gaml)
		//if(suivi_ajout_pools_residus){
			sorties_CNres <+ CNres_arg;
			sorties_situationRes <+ situationres_arg;
			sorties_masseC <+ masse_carbone_arg;
			sorties_masseN <+ masse_azote_arg;
			sorties_nomProduit <+ nom_produit;
			sorties_resType <+ res_type_arg;
			sorties_poolType <+ pool_type_arg;
			sorties_Kres <+ Kres_pool_arg;
			sorties_Hres <+ Hres_pool_arg;
			sorties_CNbio <+ CNbio_pool_arg;
			sorties_Yres <+ Yres_pool_arg;
			sorties_dateAjout <+ dateCour.nbJoursEcoulesDansAnnee;
					
			string cult_temp <- "none";
			if(cultureParcelle!= nil){ // ajout du nom de la culture en cours, si il y en a une
			 	cult_temp <- cultureParcelle.monModelDeCulture.espece.idEspeceCultivee;
			 } 
			 sorties_culture <+ cult_temp;
			 
		//}
		
	}
	
	
	// Fertilization Action : fertilizer inputs (org or min) + N volatilization
	action fertilisation (string nom_produit, float dose, float doseP, float doseK, string outil, float dose_forcee_C) {
		  
		Engrais produit <- Engrais first_with (each.nomEngrais = nom_produit); // Dose per Ha		
		
		// Mineral fertilizers
		if (produit.Fertilizer_type = "mineral") {
			
			float dosePRO <- 0.0;// tons of fresh EOM product per ha
			float doseN <- dose; // For minral fertilizer the dose is fiven in units of N
			
			float eqCO2_MinN <- doseN * produit.eqCO2_N;
			float eqCO2_MinP <- doseP * produit.eqCO2_P;
			float eqCO2_MinK <- doseK * produit.eqCO2_K;
			
			eqCO2_synthesis <- eqCO2_synthesis + eqCO2_MinN + eqCO2_MinP + eqCO2_MinK;
			eqCO2_synthesis_cumul <- eqCO2_synthesis_cumul + eqCO2_synthesis;
			eqCO2_Nmineral_synthesis_cumul <- eqCO2_Nmineral_synthesis_cumul + eqCO2_synthesis;
			
			float EF_min <- 0.0;
			if(produit.Fertilizer_form = "solid") {
				QNapport_min_calc <- doseN ;
				QNapport_min <- QNapport_min + QNapport_min_calc ;
				
				if (self.ilot_app.sol.pHsol > 7.0){
					EF_min <- produit.EF_high_pH;
				} else {
					EF_min <- produit.EF_normal_pH;
				}
				N_nh3_min_calc <- QNapport_min_calc*EF_min * 14/17;
				N_nh3_min <- N_nh3_min + N_nh3_min_calc;
			} else {
				QNapport_min_direct_calc <- doseN ;
				QNapport_min_direct <- QNapport_min_direct + QNapport_min_direct_calc ;
				if (self.ilot_app.sol.pHsol > 7.0){
					EF_min <- produit.EF_high_pH;
				} else {
					EF_min <- produit.EF_normal_pH;
				}
				N_nh3_min_dir_calc <- QNapport_min_direct_calc*EF_min * 14/17;	
				N_nh3_min_dir <- N_nh3_min_dir + N_nh3_min_dir_calc;				
			}			

		// organic fertilizers											
		} else {
//			write "épandage de " + produit.nomEngrais + " sur " + idParcelle;
			float dosePRO <- dose; // For organic fertilizers, the dose is given in tons 
			dose <- dose * 1000; // Dose must be converted from T to kg (given as T in the decision rules)
			eqCO2_synthesis <- eqCO2_synthesis + dosePRO * produit.eqCO2_PRO;
			eqCO2_synthesis_cumul <- eqCO2_synthesis_cumul + eqCO2_synthesis;
			
			// 1. Apport d'azote minéral (les PRO contiennent une part d'azote minéral + N volatilization
			if (produit.Fertilizer_form = "liquid"){
				QNapport_pro_direct_calc <- dose * produit.Nmin / 100;
				QNapport_pro_direct <- QNapport_pro_direct + QNapport_pro_direct_calc;		
				float EF_pro <- produit.EF;
				float EF_pro_cor_spread <- 1.0;
									  
				if (outil = "buse palette"){
					EF_pro_cor_spread <- 1.0;
				} else if (outil = "pendillard"){
					EF_pro_cor_spread <- 0.5;
//					write "application pendillard";
				} else if (outil = "enfouisseur" or outil = "injecteur" or outil = "paturage"){
					EF_pro_cor_spread <- 0.25;
//					write "application enfouisseur ou injecteur";
				} else {
					EF_pro_cor_spread <- 1.0;
				}
				
				N_nh3_pro_dir_calc <- QNapport_pro_direct_calc*EF_pro*EF_pro_cor_spread;
				N_nh3_pro_dir <- N_nh3_pro_dir + N_nh3_pro_dir_calc;
			} else {
				float EF_pro <- produit.EF;
				QNapport_pro_calc <- dose * produit.Nmin / 100;
				QNapport_pro <- QNapport_pro + QNapport_pro_calc;				
				N_nh3_pro_pot_calc <- QNapport_pro_calc* EF_pro;
				N_nh3_pro_pot <- N_nh3_pro_pot + N_nh3_pro_pot_calc;
				if (produit.hum >= 80){
					N_nh3_pro_hum_pot_sol <- N_nh3_pro_hum_pot_sol + N_nh3_pro_pot_calc;
				}
				if (produit.hum < 80){
					N_nh3_pro_pot_sol <- N_nh3_pro_pot_sol + N_nh3_pro_pot_calc; 
				}				
			}
			// 2. Apport d'azote organique à minéraliser
			float C_recalcitrant; // Quantité de carbone dans le pool récalcitrant; sans self.surface / 10000
			float C_labile; // Quantité de carbone dans le pool labile; sans self.surface / 10000
			float CNres_labile;
			float CNres_recalcitrant;
			float N_labile; // Quantité d'azote dans le pool labile
			float N_recalcitrant;			
			
			if (outil != "paturage") { // Dans le cas de ferti épandues par agri (PRO)
				C_recalcitrant <- dose * produit.C / 100 * produit.C2;
				C_labile <- dose * produit.C / 100 * (1 - produit.C2);
				CNres_labile <- produit.CNorg * produit.aCN1;
				CNres_recalcitrant <- produit.C2 * produit.CNorg * produit.aCN1 * produit.CNorg / (produit.aCN1 * produit.CNorg - (1 - produit.C2) * produit.CNorg);
			} else { // Dans le cas de ferti liées aux restitutions par les animaux
				
//				write "nom produit restitué = " + nom_produit;
//				write "dose = " + dose;
				if (dose_forcee_C = 0.0 and nom_produit = "urine") {
					dose_forcee_C <- dose * produit.C / 100;
				}
				float N_apport <- dose * produit.N / 100;
				
				float CNorg_force <- dose_forcee_C / N_apport;
//				write 'N apporté = ' +  N_apport;
//				write "C apporté = " + dose_forcee_C;
//				write "CNorg = " + CNorg_force ;
				
				C_recalcitrant <- dose_forcee_C * produit.C2;
				C_labile <- dose_forcee_C * (1 - produit.C2);
				CNres_labile <- CNorg_force * produit.aCN1;
				if !(nom_produit = "urine") {
					CNres_recalcitrant <- produit.C2 * CNorg_force * produit.aCN1 * CNorg_force / (produit.aCN1 * CNorg_force - (1 - produit.C2) * CNorg_force);
					N_recalcitrant <- C_recalcitrant / CNres_recalcitrant;	
				}
			}

			N_labile <- C_labile / CNres_labile;
						
			// 2.1 Pool labile :
			string sit_res <- "surface";
			if (outil = "paturage") {
				sit_res <- "restitution_animale";
			}
			
			do AddPoolResidus(CNres_labile, sit_res, C_labile, N_labile, nom_produit,"PRO", "labile", produit.kres1, produit.H, produit.CNbio, produit.Y);			

			// A garder en mémoire : pour l'instant les pools de PRO sont déposés en surface (pas de prise en compte d'un travail du sol s'il y en a un en simultanné)
			
			// 2.2  Pool recalcitrant (si il existe dans le PRO en question) alimente directement Nhum actif
			if (produit.C2 > 0) {
				do AddPoolResidus(CNres_recalcitrant, sit_res, C_recalcitrant, N_recalcitrant, nom_produit,"PRO","recalcitrant", 0.0, 0.0, 0.0, 0.0);				
			}
		}
		// mineral N inputs from fertilizers and N volatilization
//		write "N_nh3_min_dir --> " + N_nh3_min_dir;
//		write "N_nh3_pro_dir --> " + N_nh3_pro_dir;
//		write "N_nh3_min --> " + N_nh3_min;
		N_nh3 <- N_nh3_min_dir + N_nh3_pro_dir + N_nh3_min;
		QNapport <- QNapport_min_direct + QNapport_pro_direct + QNapport_min + QNapport_pro;
		QNapport_min2 <- QNapport_min+QNapport_min_direct;
		QNapport_pro2 <- QNapport_pro_direct+QNapport_pro;	
//		write "Apport réalisé : QNapport --> " + QNapport;
		QNapport_direct_after_volat <- (QNapport_min_direct + QNapport_pro_direct)-(N_nh3_min_dir + N_nh3_pro_dir);
		QNapport_after_volat_j <- (QNapport_min + QNapport_pro)-(N_nh3_min + N_nh3_pro_pot);
	}

	// TODO: à supprimer  car non utilisé ? JV et RM 050925
	action calculPrix(string nom_produit, float dose, float doseP, float doseK, string outil, float tempsW) {
		// Update du temps de travail par Ha
		tps_travail_Ferti_cumul <- tps_travail_Ferti_cumul + tempsW; // ha/h
		
		Engrais produit <- Engrais first_with (each.nomEngrais = nom_produit);
		// mineral fertilizers		
					
		float prix_engrais <- 0.0; // €/ha
		float prix_application <- 0.0; // Main d'oeuvre + fuel / ha
								
		if (produit.Fertilizer_type = "mineral") {
			prix_engrais <- dose * 0.9 + doseP * 0.95 + doseK * 0.65;
			prix_application <- 11.5;
		} else { // Attention : seules les catégories de PRO de Versailles ont été intégrées. Cf table_interventions.xlsx pour les couts (envoyé par Manon --> Barème cuma 2019 des trois régions hauts de France, bourgogne franche comté et Rhône Alpes)
			prix_engrais <- produit.coutT * dose;
			if (produit.nomEngrais contains_any ["fumier de cheval","fumier bovin", "boue urbaine epaissie chaulee"]) { // 
				prix_application <- 63.4; // Epandeur à fumier
			} else if (produit.nomEngrais contains_any ["lisier bovin"]) {
				prix_application <- 79.0; // Epandeur à lisier
			} else if (produit.nomEngrais contains_any ["compost dechets verts et biodechets", "fertilys", "compost dechets verts","compost de fumier porcin","refus lisier de porc"]) {
				prix_application <- 19.4; // Epandeur à compost 
			} else {
				//write "!! ATTENTION : Le PRO appliqué n'a pas de prix associé --> " + produit.nomEngrais;
			}
		}
		
		//write "Produit -> " + produit.nomEngrais + " ---- Prix de l'engrais = " + prix_engrais + " - Prix de l'application = " + prix_application;
		prixFerti_cumul <- prixFerti_cumul + prix_engrais + prix_application; // €/ha
	}

	// Sélection de la stratégie a appliquer
	action selection_alternative_ferti {
		//write "||||||||||||||||||||||||||||||||";
//		write "Choix d'une alternative";
		list<strategieFertiAlternative> alternatives_possibles <- self.getITKAnnee().strategieFertiITK.mesStrategiesFertiAlternative;
		bool alternativeOK <- false;
		bool tempsDeRetourOK <- false;
		strategieFertiAlternative alternative_choisie;
		
		loop priorite from: 1 to: length(alternatives_possibles) {
//			write "Test Alternative " + priorite;
			strategieFertiAlternative alternative_courante <- first(alternatives_possibles where (each.ordre_alternative = priorite));
//			write "-> alternative_courante testée = " + alternative_courante.nom_alternative;
			alternativeOK <- alternative_courante.isMesProduitsDisponibles(self);
			tempsDeRetourOK <- alternative_courante.isTempsRetourOk(self);
//			write "-> isMesProduitsDisponibles = " + alternativeOK + " --- tempsDeRetourOK = " + tempsDeRetourOK;

			// Si une alternative est trouvée, la boucle est stoppée. Les alternatives sont lues selon leur ordre de priorité
			if (alternativeOK and tempsDeRetourOK) {
				alternative_choisie <- alternative_courante;
				break;
			}
		}
		
//		write "-ITKFERTi- alternative_choisie --> " + alternative_choisie.nom_alternative;
		// Lorsqu'une alternative est choisie, il faut récupérer les produits (soustraire aux stocks la quantité nécéssaire pour les apports)
		if alternative_choisie !=nil {
			ask alternative_choisie {
				do prelevementProduits(myself);
			}
		}		
		alternative_selectionnee <- alternative_choisie;
		
		//write "fin du choix";
		//write "||||||||||||||||||||||||||||||||";
	}
	/*********************************************************************************************************************************/
	//  ACTIONS A SUPPRIMER (remplacées par l'action fertilisation ci-dessus
		
//	action fertilisationN (float dose) { // TODO A supprimer
//		/* Changement de la fertilisation en fonction de la culture (tests préliminaires module NC)  */
//		QNapport_ferti <- dose;
//		
//		QNapport <- QNapport_ferti; // Quantité d'azote apporté en kg/ha
//		entrees_ferti <- entrees_ferti + QNapport_ferti;
//	}
	
/*********************************************************************************************************************************/

	// JV 130422 MAJ des variables de sortie, redéfinie de parcelle
	action comportementJournalier{		
		
		if !desactivationMAJsorties {
			// MAJ variables sorties
			do majSortiesEau;
			do majSortiesAzote;
			do majSortiesCarboneGES;
		} else {desactivationMAJsorties <- false;} // réactivation pour le lendemain
	}
	
	// RM 040425 issue #15 Problème de maj des apports déjà réalisés sur prairie permanente -> remise à 0 au 1er janvier (formation dev 03/2025, modif proposée par Kevin Chapuis)
	action comportementFinAnnuel{
        invoke comportementFinAnnuel();
        if isPrairiePermanente { apportsEffectues <- nil; apportsAnnules <- nil; }
    }
	
	// JV 090522 RAZ variables sortie azote, appelee le 1er janvier par parcelle.remiseAZeroSortiesParcelle, elle-meme appelée parcelle.comportementAnnuel	
	action remiseAZeroSortiesAzote {
		sorties_N_lixivie <- [0.0];		
		sorties_N_volatilise_NH3 <- [0.0];
		sorties_N_mineralise_net_PRO <- [0.0];
		sorties_N_mineralise_net_SOM <- [0.0];
		sorties_N_mineralise_net_residus <- [0.0];
		sorties_emissions_N2O_directes <- [0.0];
		sorties_emissions_N2 <- [0.0];
		sorties_N_acquis_couvert <- [0.0];
		sorties_satisfactionAzote_cult <- [0.0];
		sorties_satisfactionAzote_ci <- [0.0];
		sorties_N_fixe_legumineuses <- [0.0];
		sorties_N_mineral_debut <- [QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p]; // valeur au 1er jour de la période
		sorties_N_mineral_fin <- [0.0];		
	}
	
	// JV 090522 RAZ variables sortie C et GEST, appelee le 1er janvier par parcelle.remiseAZeroSortiesParcelle, elle-meme appelée parcelle.comportementAnnuel	
	action remiseAZeroSortiesCarboneGES {
		sorties_delta_Corg <- [0.0];		
		sorties_tx_MO_fin <- [0.0];
		sorties_emissions_N2O_denit <- [0.0];
		sorties_emissions_N2O_nit <- [0.0];
		sorties_emissions_N2O_N_volat <- [0.0];
		sorties_emissions_N2O_N_lixiv <- [0.0];
		sorties_emissions_ferti <- [0.0];
		sorties_bilan_net_GES <- [0.0];
		sorties_tx_Corg_Arg <- [0.0];
	}
	
	// JV 090622 MAJ sorties azote, appelé dans comportementJournalier
	action majSortiesAzote {
		// on MAJ les variables du dernier élément des listes (correspond au couvert courant)
		int indiceCouvertCourant <- length(sorties_jDebutCouvert)-1; // commence à 0
		sorties_N_lixivie[indiceCouvertCourant] <- sorties_N_lixivie[indiceCouvertCourant] + fluxN_lixiviation;		
		sorties_N_volatilise_NH3[indiceCouvertCourant] <- sorties_N_volatilise_NH3[indiceCouvertCourant] + N_nh3_tot_sortie;		
		sorties_N_mineralise_net_PRO[indiceCouvertCourant] <- sorties_N_mineralise_net_PRO[indiceCouvertCourant] + Nmin_total; // JV: à valider		
		sorties_N_mineralise_net_SOM[indiceCouvertCourant] <- sorties_N_mineralise_net_SOM[indiceCouvertCourant] + DNhum_MO_cm_j_sortie;		
		sorties_N_mineralise_net_residus[indiceCouvertCourant] <- sorties_N_mineralise_net_residus[indiceCouvertCourant] + NminRes;	
		sorties_emissions_N2O_directes[indiceCouvertCourant] <- sorties_emissions_N2O_directes[indiceCouvertCourant] + N_n2o_tot;	
		sorties_emissions_N2[indiceCouvertCourant] <- sorties_emissions_N2[indiceCouvertCourant] + N_n2_denit;			
		sorties_N_mineral_fin[indiceCouvertCourant] <- QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p;	// pas de cumul car on veut récupérer la valeur le dernier jour du couvert	
		
		// Satisfaction azotée : Version NR 07102025
		if (cultureParcelle != nil) {
			ask(cultureParcelle.monModelDeCulture) {
				if(!espece.isGel()){ // pas de mesure de la satis. azotée calculée si le couvert est un gel
					if(espece.isLEG){ // Lég.
						if(string(species(self))="cultureAqYieldNC" and !espece.isCouvert){ // Lég. AqYieldNC en mode Cult. Princ.
							myself.sorties_satisfactionAzote_cult[indiceCouvertCourant] <- 1;
							myself.sorties_N_fixe_legumineuses[indiceCouvertCourant] <- myself.sorties_N_fixe_legumineuses[indiceCouvertCourant] + getQN_fix();
						} else { // Lég. ; AqYieldNC en mode CI ou HerbSimNC
							myself.sorties_satisfactionAzote_ci[indiceCouvertCourant] <- myself.sorties_satisfactionAzote_ci[indiceCouvertCourant] + 1;
							myself.sorties_N_fixe_legumineuses[indiceCouvertCourant] <- myself.sorties_N_fixe_legumineuses[indiceCouvertCourant] + getQN_fix();
						} 
					} else { // Non-lég.
						if string(species(self))="cultureAqYieldNC" and !espece.isCouvert{ // Non-lég. AqYield en mode Cult. Princ.
							myself.sorties_satisfactionAzote_cult[indiceCouvertCourant] <- QN_acquis_cumul/espece.QNmax;
						} else { // Non-Leg. Autres options = HerbSimNC OU AqYield en mode CI
							myself.sorties_satisfactionAzote_ci[indiceCouvertCourant] <-  myself.sorties_satisfactionAzote_ci[indiceCouvertCourant] + meanINN10j;
						} 
					
					} // fin non-leg
				} // fin condition gel
				myself.sorties_N_acquis_couvert[indiceCouvertCourant] <- myself.sorties_N_acquis_couvert[indiceCouvertCourant] + QN_acquis;	
				myself.sorties_sommeDegresJourCulture[indiceCouvertCourant] <- sommeDegresJourCulture_depuisSemis; // pas de cumul pour les degrés-jour car ce sont déjà des cumuls: on récupérera la valeur du dernier jour du semis							
			}
		} 
		
		
	}

	// JV 090622 MAJ sorties carbine et GES, appelé dans comportementJournalier
	action majSortiesCarboneGES {
		// on MAJ les variables du dernier élément des listes (correspond au couvert courant)
		int indiceCouvertCourant <- length(sorties_jDebutCouvert)-1; // commence à 0
		//float poid_mol_N2O_prg <- 296 * 44/28;
		//float poid_mol_C <- 44/12;
		
		// Corrections OT RM 111024 -> tout est maintenant en eqCO2
		// JV 050625 plus maintenant: on garde dans l'unite d'origine ici et on convertit dans le fichier de sortie (cf issue #10)
		sorties_emissions_N2O_denit[indiceCouvertCourant] <- sorties_emissions_N2O_denit[indiceCouvertCourant] + N_n2o_denit;
		// sorties_emissions_N2O_denit[indiceCouvertCourant] <- sorties_emissions_N2O_denit[indiceCouvertCourant] + poid_mol_N2O_prg * N_n2o_denit;
		sorties_emissions_N2O_nit[indiceCouvertCourant] <- sorties_emissions_N2O_nit[indiceCouvertCourant] + N_n2o_nit;
		// sorties_emissions_N2O_nit[indiceCouvertCourant] <- sorties_emissions_N2O_nit[indiceCouvertCourant] + poid_mol_N2O_prg * N_n2o_nit;
		sorties_emissions_N2O_N_volat[indiceCouvertCourant] <- sorties_emissions_N2O_N_volat[indiceCouvertCourant] + N_nh3_tot_sortie; //  MD 141223
		// sorties_emissions_N2O_N_volat[indiceCouvertCourant] <- sorties_emissions_N2O_N_volat[indiceCouvertCourant] + poid_mol_N2O_prg * 0.01 * N_nh3_tot_sortie; //  MD 141223
		sorties_emissions_N2O_N_lixiv[indiceCouvertCourant] <- sorties_emissions_N2O_N_lixiv[indiceCouvertCourant] + fluxN_lixiviation;
		// sorties_emissions_N2O_N_lixiv[indiceCouvertCourant] <- sorties_emissions_N2O_N_lixiv[indiceCouvertCourant] + poid_mol_N2O_prg * 0.0075 * fluxN_lixiviation;
		sorties_emissions_ferti[indiceCouvertCourant] <- sorties_emissions_ferti[indiceCouvertCourant] + eqCO2_synthesis;
		sorties_bilan_net_GES[indiceCouvertCourant] <- sorties_bilan_net_GES[indiceCouvertCourant] + eqCO2_total;
		sorties_tx_Corg_Arg[indiceCouvertCourant] <- sorties_tx_Corg_Arg[indiceCouvertCourant] + SOC_Clay_ratio;
		//sorties_delta_Corg[indiceCouvertCourant] <- sorties_delta_Corg[indiceCouvertCourant] + (poid_mol_C * delta_Chum_sortie) * -1; // OTRM 111024 - 1 pour traduction en eqCO2 : si stockage de C alors valeur négative
		sorties_delta_Corg[indiceCouvertCourant] <- sorties_delta_Corg[indiceCouvertCourant] + delta_Chum_sortie;
		sorties_tx_MO_fin[indiceCouvertCourant] <- OM_perc;	// pas de cumul car on veut récupérer la valeur le dernier jour du couvert
	}

	// Data for figures
	
	rgb getCouleurChum_cm {
		arg Chuma_cm_arg type: float default: 0.0;
		arg Chumi_cm_arg type: float default: 0.0;
		
		float max_Chum_cm <- 200000 / parcelleAqYieldNC(first(listeParcelles)).ilot_app.sol.profHum; // C max par cm et par ha par rapport auquel on calcule la couleur
		float C_total_cm <- min([max_Chum_cm, Chumi_cm_arg + Chuma_cm_arg]);
				
		int r <- 255 - int((255 - 28) * C_total_cm / max_Chum_cm);
		int g <- 250 - int((250 - 22) * C_total_cm / max_Chum_cm);
		int b <- 220 - int((220 - 21) * C_total_cm / max_Chum_cm);
		
		return rgb(r,g,b);
	}
	
	rgb getCouleurRHOw{
		float remplissage <- RHOw / HOw; 
		int r <- 255 - int((230 - 40) * remplissage);
		int g <- 230 - int((230 - 40) * remplissage);
		int b <- 255;
		
		return rgb(r,g,b);
	}
	
	rgb getCouleurRHOr{
		int r <- 255;
		int g <- 255;
		int b <- 255;
		if (HOr > 0){
			float remplissage <- RHOr / HOr; 
			r <- 230 - int((230 - 40) * remplissage);
			g <- 230 - int((230 - 40) * remplissage);
			b <- 255;
		}
		
		return rgb(r,g,b);
	}
	rgb getCouleurRHOp{
		float remplissage <- RHOp / HOp; 
		int r <- 230 - int((230 - 40) * remplissage);
		int g <- 230 - int((230 - 40) * remplissage);
		int b <- 255;
		
		return rgb(r,g,b);
	}
	
	float getSizeHOw{
		float size <- HOw / (HOw + HOr + HOp);
		
		return size;
	}
	float getSizeHOr{
		float size <- 0.0;
		if (HOr > 0){
			size <- HOr / (HOw + HOr + HOp);
		}
		return size;
	}
	float getSizeHOp{
		float size <- HOp / (HOw + HOr + HOp);
		
		return size;
	}

	float getPositionHOr{
		float position <- 0.0;
		if (HOr > 0){
			position <- getSizeHOw();
		}
		return position;
	}
	float getPositionHOp{
		float position <- getSizeHOw() + getSizeHOr();
		
		return position;
	}	
}
