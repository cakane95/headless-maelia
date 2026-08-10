/***************************************************************************
 * MAELIA - http://maelia-platform.inra.fr/
 *    Copyright (C) 2014-2015 
 *    INRA - UMR 1248 AGIR ;
 *    Universite Toulouse 1 Capitole - IRIT 
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
 *  selectionOutput
 *  Author: Romain Lardy
 *  Description: Booleens pour activer les sorties de MAELIA
 */

model selectionOutput

global{
	
	// l'information sur les sorties est structure de la maniere suivante :
	// theme de la sortie ; nom du csv de sortie ; [pas de temps][resolution] Description de la sortie 
	// bool sortie <- true;
	
	/* Sorties de fonctionnement "classique" */
	bool sorties_eau <- true;
	bool sorties_azote <- false;
	bool sorties_carboneGES <- false;
	bool sorties_retenues <- false;
	bool sorties_barrages <- false;
	
	
	/* ---------------------------------- ASSOLEMENT ---------------------------------------------------------------- */
		// Assolement ; assolement_SDC ; [annee][SDC] Surface (ha) et nombre de parcelles par systeme de culture (ITK x rotation x sol x …)  
		bool Assolement_SDC <- false;
		
		// Assolement ; assolement_itk ; [annee][itk] Surface (ha) et nombre de parcelles par ITK. Peut contenir des information de debogage,
										// tel que les information sur les recoltes forcees et semis non realises 
		bool Assolement_itk <-false;
		
		// Assolement ; assolement_espece ; [annee][espece] Surface (ha) et nombre de parcelles par espece cultivee 
		bool Assolement_espece <- false;
		
		// Assolement ; assolement_parcelles ; [annee][espece] et nombre de parcelles par espece cultivee 
		bool Assolement_parcelle <- false;
		
		// Assolement ; recolteParcelles // Permet de déterminer pour quaque année et pour chaque parcelle l'espece récoltée leur rendement (attention, les couverts ne sont pas pris en compte)
		bool recolteParcelles <- false;
		
		// Assolement ; fractionSolNuAnnuel, fractionSolNuJournalier et solNuIlots; [annee ou jour][Territoire] fraction de la surfaces des parcelles utiles
		//  en sol nus et fraction annuelle de recoltes forcees
		bool FractionSolNu <- false;
		
	
	/* ---------------------------------- BILAN HYDRIQUE ------------------------------------------------------------ */
		// Bilan hydrique ; DrainIlot ; [jour][territoire] bilan hydrique journalier (mm) des ilots geres par le modele de cultures (drain,
										// ruissellement, ETR)
		bool DrainIlot <- false;
		bool DrainIlot_mois <- false;
		bool DrainIlot_quinzaine <- false;
	
	/* ---------------------------------- ECONOMIE ------------------------------------------------------------------ */
		// Economie ; rendements_itk ; [annee][ITK] Rendements (q/ha) par ITK 
		bool RDT_itk <- false;
		
		// Economie ; rendements_sol_itk ; [annee][type de sol x ITK] Rendements (q/ha) et surface associee par ITK et par type de sol
		bool RDT_sol_itk <- false;
		
		// Economie ; rendements_espece ; [annee][espece] Rendements (q/ha) par espece cultivee
		bool RDT_espece <- false;

		// Economie ; [annee][espece][exploitation][parcelle][RDT [t/ha]];[surface [ha]]
		bool RDT_parcelle_espece <- false;
		
		// Economie ; rendements_exploitation_espece ; [annee][exploitation x espece] Rendements (q/ha) par espece cultivee et par exploitation
		bool RDT_exploitation_espece <- false; // Ne fonctionne que avec Aquield et AqYieldNC

		// Economie ; eco_espece ; [annee][espece et Territoire] Marge brute et marge semi-nette (€/ha) par culture 
		bool ECO_espece <- false;
		
		// Economie ; eco_itk ; [annee][ITK et Territoire] Marge brute et marge semi-nette (€/ha) par ITK 
		bool ECO_itk <- false;
		
		// Economie ; eco_exploitationType ; [annee][exploitations types] Marge brute et marge semi-nette (€/ha) par type d'exploitations. 
											// Un fichier de type d'exploitations est a renseigner en entree et a placer dans 
											//   modeleAgricole/agriculteurs/exploitations.csv. Il est structure de maniere simple :
											//  1 ligne d'entete. Puis ID exploitation , ID_Type_Exploitation 
		bool ECO_exploitationType <- false;
		
		// Economie ; eco_exploitationDetail ; [annee][exploitation x ITK] Marge brute et marge nette (€/ha) par ITK par exploitation a 
											// suivre (liste fournie en entree). La liste des exploitations a suivre est precisee dans la
											// variable listAgriASuivre 
		bool ECO_exploitationDetail <- false;
		
		// Economie ; eco_SDC ; [annee][SDC] Moyenne ponderee des surfaces des marges brutes et marges nettes (€/ha) par systeme de culture 
		// Economie ; eco_SDC ; [annee][SDCref x type materiel irrigation x type de sol] Moyenne ponderee des surfaces des marges brutes et 
											// marges nettes (€/ha) pour la sequence de culture de reference pour un type de sol et un type 
											// de materiel d'irrigation
		bool ECO_SDCRef <- false;
	
	/* ---------------------------------- HYDROLOGIE ---------------------------------------------------------------- */
		// Hydrologie, debits ; DebistSTH ; [jour][stations de mesures de debit] Debits simule, mesure, DOE, QA, Qi, QAR et DCR aux 
											// differents points de reference (dont points DOE) renseignes en entree et a comparer 
											// (listeIdSthAcomparer) 
		bool DebistSTH <- false;
		
		// Hydrologie, debits ; debit ; [jour][stations de mesures de debit] Debits (m3/s) au differents points de reference (dont 
											// points DOE) renseignes en entree ; Partiellement redondant avec DebistSTH
		bool Debit <- false;
	
	/* ---------------------------------- PRELEVEMENTS -------------------------------------------------------------- */
		// Prelevements ; prelevements_Annuel_IRR et prelevements_Journalier_IRR ; [jour et annee][territoire] volume souhaite et 
											// volume reellement preleve [m3] . Pour la sortie journaliere on distingue le volume ressources
											// et le volume parcelle (la difference = perte + evaporation) 
		bool Prelevements <- false;
		
		// Prelevements ; ZH_resultatsPrelevements et ZH_resultatsPrelevementsJournalier ; [jour et annee][Bve x nature de ressource (RET,
													// SURF, NAPP)] volume souhaite et volume reellement preleve dans la ressource [m3] 
													// par Bve et type de ressource (SURF, NAPP, RET) 
		bool PrelevementsZH <- false;
		
		// Prelevements ; ZA_resultatsPrelevements  et ZA_resultatsPrelevementsJournalier ; [jour et annee][zone administrative 
													// x nature de ressource (RET, SURF, NAPP)] volume souhaite et volume reellement 
													// preleve dans la ressource [m3] par zone administrative et type de ressource (SURF,
													// NAPP, RET)
		bool PrelevementsZA <- false;
		
		// Prelevements ; resultatsPrelevementsJournalier_sol_itk et resultatsPrelevementsJournalier_sol_itk ; [jour et annee][sol 
													// x ITK x materiel irrigation] volume souhaite et volume reellement apporte a la 
													// parcelle [m3] par types de sol, ITK et materiel d'irrigation 
		bool Prelevements_sol_itk <- false;
		
		// Prelevements ; resultatsPrelevementsJournalier_sol_espece et resultatsPrelevementsJournalier_sol_espece ; [jour et annee][sol
													// x espece x materiel irrigation] volume souhaite et volume reellement apporte a la
													// parcelle [m3] par types de sol, culture et materiel d'irrigation
		bool Prelevements_sol_espece <- false;
		
		// Prelevements ; resultatsPrelevements_espece et resultatsPrelevementsJournalier_espece ; [jour et annee][espece] volume souhaite
													// et volume reellement apporte a la parcelle [m3] par especee 
		bool Prelevements_espece <- false;
		
		// Prelevements ; resultatsPrelevements_za_espece et resultatsPrelevementsJournalier_za_espece ; [jour et annee][espece
													// x zone administrative] volume souhaite et volume reellement apporte a la parcelle [m3]
													// par espece cultivee et par zone adminstrative (du point de prelevement en cours)
		bool Prelevements_za_espece <- false;
		
		// Prelevements ; resultatsPrelevements_za_sol_espece et resultatsPrelevementsJournalier_za_sol_espece ; [jour et annee]
													// [espece x zone administrative x type de sol] volume souhaite et volume reellement
													// apporte a la parcelle [m3] par espece cultivee, par type de sol et par zone
													// adminstrative (du point de prelevement en cours) 
		bool Prelevements_za_sol_espece <- false;
		
		// Prelevements ; resultatsPrelevements_decoupage_itk et resultatsPrelevementsJournalier_decoupage_itk ; [jour et annee]
													// [ITK x materiel d'irrigation x zonage utilisateur] volume souhaite et volume
													// reellement apporte a la parcelle [m3] par ITK, materiel d'irrigation et par
													// element du zonage fourni en entree (par exemple les communes). Le decoupage
													// geographique est fait sur l'appartemenance de l'îlot au zonage.
		// TO USE : nom du fichier de zonage : filePrelevement_decoupage_itk;
		// 			variable a considerer dans le shape : VariableDecoupagePrelevement_decoupage_itk 
		bool Prelevements_decoupage_itk <- false;
		
		// Prelevements ; resultatsPrelevements_decoupage_PPA et resultatsPrelevementsJournalier_decoupage_PPA ; [jour et annee]
													// [ITK x materiel d'irrigation x zonage utilisateur] volume souhaite et volume 
													// reellement preleve dans la ressource [m3] par nature de ressource (RET, NAPP, SURF)
													// et par element du zonage fourni en entree (par exemple les communes).
													// Le decoupage geographique est fait sur l'appartemenance du point de prelevement
													// au zonage.
		// TO USE : nom du fichier de zonage : filePrelevement_decoupagePPA;
		//	 		variable a considerer dans le shape : VariableDecoupagePrelevement_decoupagePPA 
		bool Prelevements_decoupage_typePPA <- false;
		
		// Prelevements et hydrologie ; Canaux_Annuel et Canaux_Journalier ; [jour et annee][canal] Debit preleve pour alimenter les
													// canaux (volume souhaite et volume reellement preleve) 
		bool Canaux <- false;
	
	/* ---------------------------------- NORMATIF ------------------------------------------------------------------ */
		// Prelevements, Normatif ; Restrictions_Annuel et Restrictions_Journalier ; [jour et annee][zone administrative] Niveaux de
													// restrictions par zone administatives pour chaque jour ou cumul annuel
		bool Restrictions <- false;

	// Prelevements, Normatif ; Quota_Annuel ; [annee][ppa] Quota utilise (m3) et quota attribue par PPA, par an
		bool UtilisationQuota <- false;

	
// ---------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------
	
	/* Sorties en cours de debogage ou de module en cours de developpement - a utiliser avec precaution! */
	
		/* ---------------------------------- GESTION BARRAGE ------------------------------------------------------------- */
	
		// Gestion des barrages : Barrage_Journalier ; 	[jour][barrage] Volume restant (m3) et debit aval (m3/s), par ouvrage
		// Gestion des barrages : Barrage_Annuel; 		[annee][barrage] Volume destocke (m3) et  nombre de jour 
														// ou le destockage etait insuffisant et impossible (deficit), par ouvrage 
		bool GestionnaireDeBarrage <- false;
	

// ---------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------------------------		
	/* Sorties de debogage - a utiliser avec precaution! */
	
		/* ---------------------------------- ITK ------------------------------------------------------------- */
		// ITK ; suiviITK_[OT] ; [jour][parcelle x OT] Cumul des surfaces ou du nombre de parcelles ayant subit une operation technique pour un ITK
		// pour le jour julien donnee
		// Attention fichier probablement lourd a creer pour un territoire entier
		// La liste des OT a suivre est definie dans listOTASuivreEnSortie
		// Valeur par défaut :
		// ["IRRIGATION", "RECOLTE", "SEMIS", "BINAGE_SOL", "FERTI", "PHYTO", "REPRISE_TRAVAIL_SOL", "TRAVAIL_SOL"]
	    bool suiviOT <- true;
	    bool suiviOTParParcelle <- true; // date ; parcelle ; ITK ; OT -> suivi exhaustif de toutes les opérations effectuées -> très lourd
	    bool suiviOTParParcelleTemps <- false; // idem avec en plus le temps par OT
	    bool suiviSemisRecolteParParcelle <- false; // idem mais uniquement pour les OT SEMIS et RECOLTE
	
		/* ---------------------------------- AqYield ------------------------------------------------------------- */
		bool debugSortie1parcelleAqYield <- false;
		bool debugSortie1parcelleAqYield_N <- false; // Sorties journalières Aqyield N
		bool variablesAqYieldSurParcellesSpecifiees <- false; // JV 050820 idem que précédent mais sur plusieurs parcelles
		bool variablesAqYieldSurParcellesSpecifiees_light <- false; // JV 190121 idem que précédent mais sur moins de variables et transposé (pour Myriam) 	
		bool aqYield_eva_trmax_trr_ITK_ZH <- false; // JV 300621 evaporation, transpi max, transpi reelle agrégées sur ITK et ZH (pour Myriam)
		bool suiviOTParParcelle_humidite <- false; // JV 190121 idem suiviOTParParcelle mais que pour semis, irrigation, récolte et avec humiditéSol avant/après l'OT

		//Bilan parcelle; RUEdesSOLS; [annee][sol x BVe x itk x SDCref x materiel Irrigation] Fournit par annee l'information du rendement
		// des volumes et de la plage d'irrigation, du drainage 
		//Sortie crée pour le projet RUEdesSOLs
		bool RUEdesSOLs <- false;
		bool debug_fusion_AqYieldNC <- false; // JV 110821
		bool sortiesAqYieldNC <- false; // JV 140222 met a vrai les sorties ci-dessous relatives au module NC
		bool N_lixi_typeExploitation <- false; // Lixiviation par exploitation (kg de N / ha)
		bool N_total_eqC02_typeExploitation <- false; // Bilan GES total par exploitation (kg CO2 / ha)
		bool N_lixi_Parcelles <- false; // Lixiviation par parcelle (kg de N / ha)
		bool N_GES_Parcelles <- false; // Bilan GES total par parcelle (kg CO2 / ha)
		bool N_NH3_Parcelles <- false; // Emissions de NH3 (???)
		bool N_Cstock_Parcelles <- false; // Carbone stocké (???)
		bool N_SOC_Parcelles <- false; // Niveau d'indice SOC au 31/12
		bool prixFerti_Parcelles <- false; // Coûts de fertilisation à la parcelle (€/ha)
		bool tpsWFerti_Parcelles <- false; // Temps de travail de fertilisation par parcelle (h/ha)
		bool N_N2O_Parcelles <- false; // Emissions de N2O par parcelle (???)
		bool eqCO2_synthesis_Parcelles <- false; // Emissions de CO2 dues à la production, au transport et au stockage des engrais (kg)
		bool eqCO2_Nmineral_synthesis_Parcelles <- false;  // Emissions de CO2 dues à la production, au transport et au stockage des engrais MINERAUX (kg)
		bool engrais_utilises_territoire <- false; // Quantité d'engrais utilisée annuellement (par type d'engrais)
		bool engrais_utilises_exploitation <- false; // Quantité d'engrais utilisée annuellement dans chaque exploitation (par type d'engrais)
		bool eqCO2_emissions_NC_Parcelles <- false; // Emissions de CO2 à la parcelle (kg/ha)
		bool N_Nmin_som_res_Parcelles <- false; // ???
		bool N_varArbreRegression_nSemisCultures_Parcelles <- false; // Nombre de semis par type de culture sur chaque parcelle
		bool N_varArbreRegression_nApportProduits_Parcelles <- false; // Nombre d'apport par type d'engrais sur chaque parcelle
		bool N_varArbreRegression_quantitesProduits_Parcelles <- false; // Quantités apportées par type d'engrais sur chaque parcelle
		bool inputs_sols <- false; // Enregistrement des données sols de chaque parcelle (pour arbre de régression)
		bool lien_ilots_zoneMeteo <- true; // Enregistrement de l'id zoneMeteo de chaque ilot (pour le script d'analyse de sorties de Nirina) 080322
		bool N_QNfix_Parcelles <- false; // Quantité annuelle de N fixée pour chaque parcelle (kg/ha)
		bool N_exportation_pailles_Parcelles <- false; // ATTENTION --> sortie journalière ---- T de MS exportée / ha / jour
		bool N_Nmin_total_Parcelles <- false; // Net mineralized N
		
		/* ---------------------------------- HerbSimNC ------------------------------------------------------------- */
		bool suivi_journalier_1parc_HerbSimNC <- false;
		/* ---------------------------------- BILAN NC ------------------------------------------------------------- */
		bool suivi_ajout_pools_residus <- false; // Enregistrement de chaque ajour de pool de résidus (nature, quantité d'azote et de carbone)  // NR sortie pool
		/* ---------------------------------- BILAN HYDRIQUE ------------------------------------------------------------- */
		
		// Bilan hydrique : DrainIlot ; [jour][ilot RPG] Drain journalier moyen (mm)  par ilot
		// ATTENTION : fichier lourd en sortie
		bool DrainIlotDetail <- false;
		bool DrainIlotDetail_mois <- false;
		bool DrainIlotDetail_quinzaine <- false;
				
		// Bilan hydrique : DrainIlot_ITK_ZH ; [jour][Bve x ITK] Moyenne ponderee des surfaces du bilan hydrique journalier (drain, ruissellement,
										// pluie, Irrigation, surface, humiditeSol) par ITK et par Bve
		bool DrainIlot_ITK_ZH <- false;
		
		// Bilan hydrique : recharge_retenues ; [annee][retenues] 1 ligne pour le remplissage effectif de la retenue, pour le volume en début 
						// d'année et une ligne pour le nombre de jours dans l'année où le volume est sous le culot
						// par retenues connectées et deconnectees; La premiere section du fichier rappelle l'identifiant, le volume(m3) et la surface (m2)
		bool RechargeRetenues <- false;
		bool RetenuesVolumeActuelJour <- false; // JV 130618 volume actuel journalier pour chaque retenue		
		
		// Bilan hydrique : resAS ; [jour][Bve] Valeur journaliere par Bve de : Surface (km2); ET(mm); teneur en eau du sol SW  (mm)
		// percolation (mm); entree d'eau dans l'aquifere peu profond (mm); flux vers aquiferes profond(mm); remontee capilaire (aqui -> sol) (mm);
		// eau dans aquifere peu profond (mm); ruissellement de surface (sur HRU gere par SWAT) (mm); ecoulement subsurface(mm); 
		// ecoulement souterrain (mm); pluie (mm);
		// ATTENTION : fichier lourd en sortie
		bool FluxSWAT_BVe <- false;
		
		// Bilan hydrique ; validationSWAT_PhaseRoutage_ZH ; [jour][BVe] Pluie (m); debit entrant (mm) ; debit sortant (mm) ; Evaporation (mm)
		bool SWAT_PhaseRoutage <- false;
		
		
		// Bilan hydrique ; debitBVe ; [jour][BVe] debit sortant (mm) 
		bool debitBVe <- false;	
		
		// Bilan hydrique ; hauteurDeNappe ; [jour][BVe] Hauteur de nappes (mm) par BVe
		// Attention la fonction d'estimation des hauteurs de nappes par SWAT est empiriquement base sur le flux d'eau souterrain
		bool hauteurNappes <- false;	
	
		
		/* ---------------------------------- CLIMAT -------------------------------------------------------------------- */
		
		// Climat : climatParZH ; [jour][Bve] Surface (km2), Tmoy (°C), Tmoy du mais (mode de calcul Arvalis)(°C), ETP(mm) et Precipitations (mm)
		bool GetClimatParZH <- false ;
		
		/* ----------------------------------- ECONOMIE ----------------------------------------------------------------- */
		
		// Economie ; bilanExploitation ; [annee][exploitation] Cumul interannuel par agriculteur de la marge semi-nette; marges semi-nette exploitation (€) 
																// et marges semi-nette exploitation (€/ha) de l'exploitation
		bool BilanExploitation <- false;
		
		// Economie ; coutIrrigationIlot ; [annee][Ilot] cout de l'irrigation sur l'ilot pour les surfaces irriguées (€/ha)
		bool ECO_coutIrrigationIlot <- false;

		// charges et temps de travail: annee;agri;ITK;recolteObserves;surfaceCumule;chargesOp;chargesFixes;primes;tempsTravaux
		bool suiviMemoireAgri <- false; 
		
		
		/* ---------------------------------- PRELEVEMENT --------------------------------------------------------------- */
		
		// Prelevements ; groupesIrrigation ; [annee][Exploitation x materiel irrigation x zone administrative] Ecrit a chaque debut d'annee 
											// la structure des groupes d'irrigation prevues : Information pour chaque agri x type de materiel
											// d'irrigation x zone adminsitrative, de la taille du tour d'eau (frequence de retour prevu),
											// l'ID groupe irrigation tel que defini dans la table d'ITK, la surface totale du groupe d'irrigation
											// et le nombre de parcelles
		bool DetailsGroupeIrrigation <- false;
		
		// Prelevements ; IrrParAgri ; [jour][Agri] Irrigation par Agri (m3) 
		bool IrrigationParAgri <- false;
	
		// Prelevements ; prelevements_Journalier_IRR_AS ; [jour][PPA] Irrigation par ppa (m3) 
		bool prelevementParPPA <- false;
		
		// Irrigation par parcelle: [jour][exploitation][parcelle][culture][min temp][max temp][pluie][irrigation] (irrigation en mm/m2)
		bool IrrigationParcelle <- false;
		
		// Irrigation debug JV 220321
		bool irrigationDebug <- false;

		/* ---------------------------------- TRAVAIL ------------------------------------------------------------------ */
		// travail ; Travail_Annuel et Agri_heuresEffectueesActivite ; [jour et anne][Type d'Agri] temps de travail par agri (h) par jour ou par an
		// et nombre de jour travaille (i.e. avec au moins une tâche sur la journee) par agri par an 
		bool travailParAgri <- false;
		
		// travail ; travail_itk  ; [annee][ITK] temps de travail par ITK (h/ha)  par an
		bool travailParITK <- false;
		
		// travail ; travail_espece  ; [annee][espece] temps de travail par espece (h/ha)  par an
		bool travailParEspece <- false;
		
		// travail ; Travail_TypeExploit_Annuel et Agri_heuresEffectueesParTypeExploit  ; [jour et annee][Type d'exploitation] temps de travail, nombre moyen de jour travaille
		// nombre moyen de jour a plus de 80% du temps de travail disponible, par type d'exploitations (h) , par jour  ou par an
		// et nombre de jour travaille (i.e. avec au moins une tâche sur la journee) par agri par an 
		bool travailParTypeExploitation <- false;
		
		// travail ; Agri_heuresRecolte ; [jour][Agri] temps de travail par agri (h) par jour pour la recolte
		bool travailParAgri_Recolte <- false;
		
		// travail ; Agri_heuresLabour ; [jour][Agri] temps de travail par agri (h) par jour pour le labour
		bool travailParAgri_Labour <- false;
		
		// travail ; RepriseLabour ; [jour][Agri] temps de travail par agri (h) par jour pour la reprise de labour
		bool travailParAgri_RepriseLabour <- false;
		
		// travail ; Agri_heuresSemis ; [jour][Agri] temps de travail par agri (h) par jour pour le semis
		bool travailParAgri_Semis <- false;
		
		// travail ; Agri_heuresBinage ; [jour][Agri] temps de travail par agri (h) par jour pour le binage
		bool travailParAgri_Binage <- false;
		
		// travail ; Agri_heuresIrrigation ; [jour][Agri] temps de travail par agri (h) par jour pour l'irrigation
		bool travailParAgri_Irrigation <- false;
		
		// travail ; Agri_heuresFerti ; [jour][Agri] temps de travail par agri (h) par jour pour la fertilisation
		bool travailParAgri_Ferti <- false;
		
		// travail ; Agri_heuresPhyto ; [jour][Agri] temps de travail par agri (h) par jour pour les traitements phyto
		bool travailParAgri_Phyto <- false;

		/* ---------------------------------- BIODIVERSITE -------------------------------------------------------------------- */
		bool sorties_iBio <- false;

		/* ---------------------------------- SYSTEME ------------------------------------------------------------------ */
		// Systeme ; tempsSimulation ; [jour][pas de simulation] Temps de simulation par cycle 
		 bool TempsSimulation <- false;
		 
		/* ---------------------------------- CALIBRATION ------------------------------------------------------------------ */
		// débit simulé: [jour][DOE][debit]
		bool sortieCalibration <- false;
		 
		/* ---------------------------------- DIVERS ------------------------------------------------------------------ */
		bool demoChambreAlsace <- false;


		 
		bool plan_epandage_actif <- false;
}


