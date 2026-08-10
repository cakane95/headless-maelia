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
 *  StrategiesRecolte
 *  Author: Maroussia Vavasseur
 *  Description: La strategie de recolte est l'entite qui va etre utilise par l'agriculteur pour determiner par exemple a quel moment il va pouvoir commencer a recolter.
 * 				 Il est possible de definir plusieurs strategies de recolte differentes, qui sera alors choisie lors du parametrage de la simulation.
 */

model strategieRecolte

import "../../modeleHydrographique/ressourceEnEau.gaml"

global{ }


species strategieRecolte parent: strategieOT{
		
	/*
	 * *****************************************************************************************
	 */		
	bool isActivitePossible(parcelle parcelleEntree, int idGroupe, int deltaTemporel){
		bool estOk <- false;
		
		if(parcelleEntree.cultureParcelle != nil){

			// si c'est une culture biannuelle (ex: colza qui est récolte plus d'un an après le semis), et qu'on est pas l'année suivante du semis, on ne récolte pas (cf Mantis #2905)
			if parcelleEntree.getITKAnnee().isCultureSup365 and (dateCour.annee < parcelleEntree.cultureParcelle.anneeSemis + 1) {
				return false;
			}

			// si c'est un gel on récolte le jour prévu et uniquement ce jour là
			if parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee="gel" {
				return dateCour.nbJoursEcoulesDansAnnee=parcelleEntree.jourProchaineRecolteGel;
			}

			/* code RM avant 021123
			// si c'est une prairie temporaire sans prairie temporaire derrière, on récolte le jour prévu et uniquement ce jour là
			if (nomChoixModeleCroissancePrairie="HerbSim") and (parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee="prairiet" and parcelleEntree.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee!="prairiet") {
				return dateCour.nbJoursEcoulesDansAnnee=parcelleEntree.jourProchaineRecoltePrairie;
			}
			*/
			// TODO ci-dessous code RM du 021123 (à vérifier)
			// si c'est une prairie temporaire sans prairie temporaire derrière, on récolte le jour prévu et uniquement ce jour là
//			if (parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee="prairiet" and parcelleEntree.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee!="prairiet") {
			// TODO Renaud 170524 Vérifier si ca marche avec des PP
			
			
			// -------------------------------------------------------------------------- //
			// Conditions de récolte pour la PRAIRIE TEMPORAIRE
//			if ((listeNomsEspecesHerbSim contains parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee) and // si l'espèce cultivée est une espèce HerbSim
//				(!parcelleEntree.isPrairiePermanente) and  // si ce n'est pas une prairie permanente (pas de récolte)
//				((nomChoixModeleCroissancePrairie = "HerbSim") or (nomChoixModeleCroissancePrairie = "HerbSimNC") or (nomChoixModeleCroissancePrairie = "HerbSimSystN")) and // si le modèle de culture est bien une variante de HerbSim
//				parcelleEntree.recoltePrairieAnneeOK and // si le 1er janvier est bien passé
//				!(listeNomsEspecesHerbSim contains parcelleEntree.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee) and// si la prochaine culture dans la séquence n'est pas la même (deux fois la même espèce HerbSim -> prairie temporaire de 2 ans)
//				dateCour.nbJoursEcoulesDansAnnee=parcelleEntree.jourProchaineRecoltePrairie  // si la date du jour est la date de récolte prévue
//			) {
//				return true;
//			}
			// ancienne version
			// JV 191225 exclusion des noms d'espèce commençant par le préfixe PREFIXE_CI #44
			string motif_ci <- "^" + PREFIXE_CI + ".*";
			if ((listeNomsEspecesHerbSim contains parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee) and // si l'espèce cultivée est une espèce HerbSim
				(!parcelleEntree.isPrairiePermanente) and  // si ce n'est pas une prairie permanente (pas de récolte)
				((nomChoixModeleCroissancePrairie = "HerbSim") or (nomChoixModeleCroissancePrairie = "HerbSimNC")) and // si on simule avec HerbSim
				(length(regex_matches(parcelleEntree.getITKAnnee().especeCultiveeITK.idEspeceCultivee, motif_ci))=0) // si l'espèce n'est pas une CI JV 191225 #44
			)
			{
				return parcelleEntree.recoltePrairieAnneeOK and dateCour.nbJoursEcoulesDansAnnee=parcelleEntree.jourProchaineRecoltePrairie;
			} else if (parcelleEntree.isPrairiePermanente) {
				return false;
			}
			// -------------------------------------------------------------------------- //
			
			// JV 020622 age ok si >30
			// JV 200725 fonction dans parcelle cf issue #26
			bool conditionAgeOk <- parcelleEntree.isConditionAgeOk();
			
			// JV 231121 ajout condition sur age culture pour gérer le cas du colza qui peut rester un place plus de 12 mois (MAJ 020622 finalement géré autrement: cf Mantis #2905)
			if isDelaiRecolteDepasse(parcelleEntree,deltaTemporel) and conditionAgeOk { //Attention laisser le test dans cet ordre
				// sinon on va rentrer dans la fenêtre temporelle a cause du forcage
				// et de de la surcharge de getIndiceSousPeriode
				parcelleEntree.recolteForcee <- true;
				parcelleEntree.getAgriculteur().listeParcellesEnRecolteForcee << parcelleEntree;
			}else if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				
				parcelleEntree.recolteForcee <- false;//basculera a true si la recolte est forcee
				estOk <- isEchelleVegetationOK(parcelleEntree,deltaTemporel) 
								and isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel) 
								and isHumiditeSolOK(parcelleEntree,deltaTemporel)
								and isMaturiteAqYieldOK(parcelleEntree)
								and conditionAgeOk;
//				write "isEchelleVegetationOK -> " + isEchelleVegetationOK(parcelleEntree,deltaTemporel);
//				write "isCumuleHauteurPluieOK -> " + isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel);
//				write "isHumiditeSolOK -> " + isHumiditeSolOK(parcelleEntree,deltaTemporel);
//				write "isMaturiteAqYieldOK -> " + isMaturiteAqYieldOK(parcelleEntree);
//				write "conditionAgeOk -> " + conditionAgeOk;
				
				parcelleEntree.critereRecolteOk_echV <- parcelleEntree.critereRecolteOk_echV + int( isEchelleVegetationOK(parcelleEntree,deltaTemporel)) ;
				parcelleEntree.critereRecolteOk_HumiditeSol <- parcelleEntree.critereRecolteOk_HumiditeSol + int( isHumiditeSolOK(parcelleEntree,deltaTemporel)) ;
				parcelleEntree.critereRecolteOk_Pluie <- parcelleEntree.critereRecolteOk_Pluie + int( isCumuleHauteurPluieOK(parcelleEntree,deltaTemporel)) ;
				
				if (!estOk) and (dateCour.nbJoursEcoulesDansAnnee = getJourJulienFinMax(deltaTemporel)){
					write "Recolte non realise a la fin de la periode prevue. echV = " +parcelleEntree.critereRecolteOk_echV +
					 " Hum = " + parcelleEntree.critereRecolteOk_HumiditeSol+
					  " Pluie = " +  parcelleEntree.critereRecolteOk_Pluie+
					  " pour la culture "+ (parcelleEntree.getITKAnnee()).idITK +
					  " pour culture "+tc.idEspeceCultivee + " sur " + parcelleEntree.idParcelle +
					  " age culture: " + parcelleEntree.cultureParcelle.age_culture;
					parcelleEntree.critereRecolteOk_echV <- 0 ;
					parcelleEntree.critereRecolteOk_HumiditeSol <- 0 ;
					parcelleEntree.critereRecolteOk_Pluie <- 0 ;
				}
//					write toString(parcelleEntree) + " - estOk = " + estOk;							
			}
		}
		return estOk;
	}

	/*
	 * *****************************************************************************************
	 */	
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		
		if(verboseMode){write "RECOLTE " + parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee + " ITK " + parc.getITKAnnee().idITK + " sur " + parc.idParcelle + " le " + dateCour.nbJoursEcoulesDansAnnee + "/" + dateCour.annee;} // JV debug 
		especeCultivee type_cult <- (parc.cultureParcelle).espece;		
		// -------------------------------------------------------------------------- //
		// 1. Calcul du rendement et des résidus si nécessaire (sauf gel et prairie)
		float rendement <- 0.0; // RM 080221 --> si l'especeCultivee est un gel ou une prairie alors pas de rendement à calculer (sinon bug dans le calcul de l'N acquis retourné au sol)
		if (type_cult.idEspeceCultivee != "gel" and !(listeNomsEspecesHerbSim contains type_cult.idEspeceCultivee)) {
			rendement <- parc.calculRendement(); //Attention renvoie un RDT en q/ha!!! JV 010420 en fait renvoie un rendement de la même unité que les rendements optimaux déclarés dans le fichier especes
		}

		//write "Calcul des résidus dans la culture " + parc.cultureParcelle.monModelDeCulture;
		
		if (species(parc.cultureParcelle.monModelDeCulture) = cultureAqYieldNC) {
			// Si grande culture
			if (parc.cultureParcelle.espece.idEspeceCultivee != "gel") { // Calcul des résidus // NR Herbsim 07/05/2024 // RM 210624 supression de la condition suivante species(parc.cultureParcelle.monModelDeCulture) = cultureAqYieldNC and 
				ask parc.cultureParcelle.monModelDeCulture { // NR Herbsim 19/04/2024
					 if (rendement > 0) {
//					 	write "intégration des résidus --> rendement = " + rendement;
					 	do N_entrant_postrecolte(rendement); // Le calcul de N entrant est réalisé seulement lorsqu'il y a un rendement > 0 
					 } else {
//					 	write "Pas de création de pool de résidus malgré la récolte";
					 }
					 
					 parcelleAqYieldNC(parc).apportsEffectues <- nil;
					 parcelleAqYieldNC(parc).apportsAnnules <- nil;
				}
			}
			
			if (adaptationFertilisation = 'corpen') {
				parcelleAqYieldNC(parc).coef_abattement_corpen <- 1.0;
				parcelleAqYieldNC(parc).N_a_apporter_corrige_rdmtObs_NminSOM <- nil;
				parcelleAqYieldNC(parc).N_dispo_semis <- 0.0;
			}
		}

		
		
		// 2. Modele filiere : Exportation de biomasse : grain, ensilage, légume racine, paille

		
		// -------------------------------------------------------------------------- //
		// 3. Remise à 0 de la parcelleAqYieldNC (si plusieursFertilisationsParITK)
		if (plusieursFertilisationsParITK) {
			parcelleAqYieldNC(parc).alternative_selectionnee <- nil; // Supression de l'alternative selectionnee
			parcelleAqYieldNC(parc).anneeDebutITKcourant <- dateCour.annee; // Réinitialisation de l'année de début de l'ITK suivant
			parcelleAqYieldNC(parc).apportsEffectues <- nil;
			parcelleAqYieldNC(parc).apportsAnnules <- nil;
		}

		// -------------------------------------------------------------------------- //
		// 4. Actions réalisées pour toutes les cultures qui ne sont pas des prairiet suivies de prairiet. Comme les prairies permanentes ne peuvent pas être récoltées le cas n'est pas prévu ci-dessous.
		// JV 150724 cf issue #5 si prariet simulée par AqYield on réalise les actions car prairet erst alors considérée comme une culture lambda
		if !((listeNomsEspecesHerbSim contains type_cult.idEspeceCultivee // Est-ce que la culture actuelle est une prairie ?
			and listeNomsEspecesHerbSim contains parc.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee // Est-ce que la culture suivante est une prairie ?
			and type_cult.idEspeceCultivee = parc.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee // Est-ce que la culture actuelle est la même que la culture suivante ?
			)
			or (type_cult.idEspeceCultivee="prairiet" and parc.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee="prairiet")) {
			
			// Actions si retournement de la prairie temporaire NR 090824
			if (species(parc.cultureParcelle.monModelDeCulture) = cultureHerbSimNC){ // NR Herbsim 13/05/2024
				ask parc.cultureParcelle.monModelDeCulture {
					do incorporation_retournement();
					do incorporation_BM_racines();
					do incorporation_BM_senescent();
					parcelleAqYieldNC(parc).apportsEffectues <- nil;
					parcelleAqYieldNC(parc).apportsAnnules <- nil; // Renaud 120624 -> doublons au dessus et en dessous
				}
				
				//
				if (executerModelePaturage) {
					if (parc.lotAnimauxCourant != nil) {
						ask parc.lotAnimauxCourant {
							write "Sortie du lot " + idLotAnimaux + " pour retournement (" + tempsPatureParcelleCourante + " j paturés)";
							do sortieDeParcelle(besoinJourCourant);
						}
					}
				}
			}
			
			// Variables ibio à compter pour toutes les cultures sauf les prairiet suivie d'une prairiet
			if (sorties_iBio) {
				parc.n_coupes_fauches <- parc.n_coupes_fauches + 1;
			}
			
			// ------------------------------ //
			// 4.1 Enregistrement du rendement pour sorties
			ask parc{					
				// JV 140121 stocke uniquement si utile
				if parc.memoireOTsurParcelle.keys contains RECOLTE {				 
					put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at RECOLTE);
					float profondeur <- nil;
					if myself.isDonnee(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) {				
						profondeur <- myself.getDonneeCourante(myself.mapEffetRUs, self, ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite);
					}				
					map<string,string> complements <- ["rendement"::string(rendement), "prof"::string(profondeur)];
					
					// TODO Renaud 160724 A redéfinir propremenet avec des add au lieu d'écraser la variable complements
					if (avecStressClimatique and !(listeNomsEspecesHerbSim contains type_cult.idEspeceCultivee)) {
				 		complements <- ["rendement"::string(rendement), "prof"::string(profondeur), "risqueEchaudage"::string(cultureAqYield(parc.cultureParcelle.monModelDeCulture).risqueEchaudage), "impactGel"::string(cultureAqYield(parc.cultureParcelle.monModelDeCulture).partDestructionGel)];
					}
					
					// MD 290923 variables complémentaires si AqYieldNC
					if (nomChoixModeleCroissancePlante = AqYieldNC and parc.cultureParcelle.espece.idEspeceCultivee != "gel") {
						float exportations <- parcelleAqYieldNC(parc).MSA_exportee_parcelle;
						float restitutions <- parcelleAqYieldNC(parc).MSA_restituee_parcelle;
						float racines <- parcelleAqYieldNC(parc).MSR_restituee_parcelle;
						complements <- ["rendement"::string(rendement with_precision nb_decimales_sorties), "prof"::string(profondeur with_precision nb_decimales_sorties), "exportations"::string(exportations with_precision nb_decimales_sorties), "restitutions"::string(restitutions with_precision nb_decimales_sorties), "racines"::string(racines with_precision nb_decimales_sorties)];
						if (avecStressClimatique and !(listeNomsEspecesHerbSim contains type_cult.idEspeceCultivee)) {
							complements <- ["rendement"::string(rendement with_precision nb_decimales_sorties), "prof"::string(profondeur with_precision nb_decimales_sorties), "exportations"::string(exportations with_precision nb_decimales_sorties), "restitutions"::string(restitutions with_precision nb_decimales_sorties), "racines"::string(racines with_precision nb_decimales_sorties), "risqueEchaudage"::string(cultureAqYieldNC(parc.cultureParcelle.monModelDeCulture).risqueEchaudage with_precision nb_decimales_sorties), "impactGel"::string(cultureAqYieldNC(parc.cultureParcelle.monModelDeCulture).partDestructionGel with_precision nb_decimales_sorties)];
						}
					}				

					put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at RECOLTE);				
				}
				
				idJourDerniereRecolte <- dateCour.idDate;  // Pour les sorties pour du fichier Aveyron
				put rendement at: dateCour.idDate in: rendementParJoursRecoltes; // Pour les sorties pour du fichier Aveyron
												
				// Dans le cas ou la parcelle est dans la ZM on calcule le rendement normalement, sinon on prend celui de la parcelle la plus proche
				if(!isParcelleHorsZone){
					float rendementMoy <- agri.mapRendementMoyenParCulture at getITKAnnee().especeCultiveeITK;
					rendementMoy <- (rendementMoy + rendement) / 2; // on calcule le rendement moyen (pas exactement, car on ne somme pas tous les rendements puisque quon ne connait quau compte goute ces derniers)
					put rendementMoy at: getITKAnnee().especeCultiveeITK in: agri.mapRendementMoyenParCulture;	
				}
			}
			
			// ------------------------------ //
			// 4.2 Actualisation de variables pour obtenir le rendement par culture et par exploitation (cf resultatsRDT_exploitation_espece.gaml et resultatRecolteParcelle) - Les récoltes de couverts ne sont pas enregistrées
			if (!parc.cultureParcelle.espece.isCouvert) {
				parc.derniere_culture_recoltee <- parc.cultureParcelle.espece.idEspeceCultivee;
				parc.dernier_rendement <- rendement;
				parc.dateSemiDerniereCultureRecoltee <- parc.dateDernierSemi;
				parc.culture_recoltee_dans_lannee <- parc.cultureParcelle.espece.idEspeceCultivee; // cf resultatRecolteParcelle.gaml
			}
			
			// ------------------------------ //
			// 4.3 Calculs économique (dont charges irrigation)
			//rendement <- rendement * (100.0 - rendement_malus) / 100.0; 
			float production <- parc.surface/nombreMeterCarreDansUnHectare * rendement ;
			
			// JV 100821 uniquement si marche agricole defini
			if leMarcheAgricole!=nil {
				agri.capital <- agri.capital + production * (leMarcheAgricole.prix_recoltes at type_cult);
			}
			/*
			 * Equations d'arvalis en partie issue de la calculette irrigation
			 * Contact : MARSAC Sylvain <s.marsac@arvalisinstitutduvegetal.fr>
			 */
			
			// TODO Renaud 301023 Les parties sur le calcul des charges irrigation sont à sortir du 3. si les prairies peuvent être irriguées 
			// JV 100821 variables ci-dessous initialisées à 0 et modifiées uniquement si le marché agricole existe
			float coutChargesFixesIrrigation <- 0.0;
			float chargesOpLoc <- 0.0;
			float chargesDePassage <- 0.0;
			
			if(parc.getITKAnnee().isIrriguee() and parc.ilot_app.isIrrigable){				
				//Calcul de la surface reellement irrigue de l ilot ;
				// donnee necessaire pour les calculs economiques
				ask parc.ilot_app{
					do calculSurfaceRellementIrriguableSurAnnee;
				}
				//charges fixes materiel
	
				// JV 100821 uniquement si marche agricole defini
				if leMarcheAgricole!=nil {
					float chargesPour1Materiel <- leMarcheAgricole.chargesFixesMaterielIrrigation at parc.ilot_app.materielIlot.idMateriel;
					float fractionMaterielInputeeAlaParcelle <- 0.0;
					loop grpCult over:parc.listeGroupeIrrigationCulture{
						loop grpIrr over: agri.listeGroupesIrrigation where (each.id = grpCult.indiceGroupe){
							fractionMaterielInputeeAlaParcelle <- fractionMaterielInputeeAlaParcelle +
														 (grpIrr.parcellesIrrigable at parc)/grpCult.surface;
						}
					}
					coutChargesFixesIrrigation <- coutChargesFixesIrrigation + fractionMaterielInputeeAlaParcelle * //fraction du grp lie a la parcelle
										chargesPour1Materiel;	
		
					//charges OP ASA ou charges fixes adduction + charges fixes ressources								
					ask parc.ilot_app.listeEquipementsCaptagesAssocies.keys{
						if (self.isASA){
							if((leMarcheAgricole.ASAForfaitSurface at self.idASA) != nil){
								parc.cumulCoutIrrigationSurUnITK <- parc.cumulCoutIrrigationSurUnITK + 
											(leMarcheAgricole.ASAForfaitSurface at self.idASA)* (parc.surface/nombreMeterCarreDansUnHectare)  +
											
											(leMarcheAgricole.ASAForfaitDebit at self.idASA) * fractionMaterielInputeeAlaParcelle 
											*  parc.ilot_app.materielIlot.surfaceIrrigableParJour /nombreMeterCarreDansUnHectare// * SIR  -> ha irrigue /jour
											* max(parc.getITKAnnee().strategieIrrigationITK.mapQuantiteEau.values) * 10  //ha * mm/j *10 -> m3/j  
											/16.0 //  /16h -> m3/h
											/3.6 ;	// 	/3600*1000 -> L/s
							}else{ //Cas Collectif non existant
								parc.cumulCoutIrrigationSurUnITK <- parc.cumulCoutIrrigationSurUnITK + 
											(leMarcheAgricole.ASAForfaitSurface at "NA")* (parc.surface/nombreMeterCarreDansUnHectare) +
											
											(leMarcheAgricole.ASAForfaitDebit at "NA") * fractionMaterielInputeeAlaParcelle 
											*  parc.ilot_app.materielIlot.surfaceIrrigableParJour /nombreMeterCarreDansUnHectare// * SIR  -> ha irrigue /jour
											* max(parc.getITKAnnee().strategieIrrigationITK.mapQuantiteEau.values) * 10  //ha * mm/j *10 -> m3/j  
											/16.0 //  /16h -> m3/h
											/3.6 ;	// 	/3600*1000 -> L/s
							}
						}else{
							
							//Charges fixes ressource pour irrigation
							
							//Charges acces a l OUGC
							coutChargesFixesIrrigation <- coutChargesFixesIrrigation + (leMarcheAgricole.chargesFixesRessource at OUGC) * parc.surface / parc.ilot_app.agriculteurAssocie.surfaceIrriguee ;
							if(self.natureRessourcePrelevee = SURF){
								coutChargesFixesIrrigation <- coutChargesFixesIrrigation +
									(leMarcheAgricole.chargesFixesRessource at SURF)* (parc.surface/nombreMeterCarreDansUnHectare) ;
							}else if(self.natureRessourcePrelevee = CAN){
								coutChargesFixesIrrigation <- coutChargesFixesIrrigation +
									(leMarcheAgricole.chargesFixesRessource at CAN)* (parc.surface/nombreMeterCarreDansUnHectare) ;
							}else{
								list<ilot> listeIlotsRelieeAmemeRessource <- []; 
								loop p over:parc.ilot_app.agriculteurAssocie.listeParcelles{
									if(p.ilot_app.isIrrigable){
										loop eq over:p.ilot_app.listeEquipementsCaptagesAssocies.keys{
											if(eq.ressourceAssociee = self.ressourceAssociee){
												listeIlotsRelieeAmemeRessource << p.ilot_app;
											}
										}
									}
								}
								listeIlotsRelieeAmemeRessource <- remove_duplicates(listeIlotsRelieeAmemeRessource);
								float frac <-  0.0;
								loop il over:listeIlotsRelieeAmemeRessource{
									frac <- frac + il.surfaceIlotAvecCultureIrriguee;
								}
								frac <- parc.surface /frac;
								if(self.natureRessourcePrelevee = NAPP){
									coutChargesFixesIrrigation <- coutChargesFixesIrrigation +
										(leMarcheAgricole.chargesFixesRessource at NAPP)* profondeurParDefautDesPrelevementEnNappe * frac ;
								}else { // RET
									coutChargesFixesIrrigation <- coutChargesFixesIrrigation +
										(leMarcheAgricole.chargesFixesRessource at RET)* retenueCollinaire(self.ressourceAssociee).volumeMax * frac ;
								}
							} 
						}
					}
					parc.chargesFixes <- parc.chargesFixes + coutChargesFixesIrrigation;
					parc.coutIrrigationSurAnnee <- parc.coutIrrigationSurAnnee + parc.cumulCoutIrrigationSurUnITK + coutChargesFixesIrrigation;					
					
					
					chargesOpLoc <- parc.cumulCoutIrrigationSurUnITK + 
						parc.surface /nombreMeterCarreDansUnHectare* (leMarcheAgricole.chargesOperationelles at  parc.getITKAnnee()) ;
			
					/* JV 190820: pre-1.8.1 versions of GAMA has compiled despite the following bug:
					* "leMarcheAgricole.chargesPassage at itk" -> itk is not defined
					* changed to  "leMarcheAgricole.chargesPassage at parc.getITKAnnee()" */
					chargesDePassage <- (leMarcheAgricole.chargesPassage at parc.getITKAnnee()) * parc.surface /nombreMeterCarreDansUnHectare;
					
					agri.capital <- agri.capital - chargesOpLoc - chargesDePassage - parc.chargesFixes;
					
					agri.capital <- agri.capital 
						+ parc.surface /nombreMeterCarreDansUnHectare* ((leMarcheAgricole.prime_par_departement at agri.sonExploitation.id_departement) at type_cult);
					
					//TODO Ajouter cout séchage maïs
				
				} // if leMarcheAgricole!=nil {
			}
		
							
			// ------------------------------ //
			// 4.4 Sauvegarde effective du rendement et remise à 0 travail + charges
			ask agri.listMemoire where ((each.itkAssocie = parc.getITKAnnee()) and (each.blocMemoire = parc.bloc_app)){
				do setRendementEtTempsWObserve(production,  parc.surface, 
					parc.tempsDeTravail, chargesOpLoc, chargesDePassage + parc.chargesFixes
				);
			}
			parc.tempsDeTravail <- 0.0;
			parc.cumulCoutIrrigationSurUnITK <- 0.0;
			parc.chargesFixes <- 0.0;
			
			// Conserver les 5 dernieres valeurs
			list<float> listProd <- copy_between(parc.derniereProduction at parc.getITKAnnee(), 1, memoireAgriculteur);			
			add production to: listProd;
			put listProd at: parc.getITKAnnee() in: parc.derniereProduction;
			
			parc.itkRecolteSurAnnee << parc.getITKAnnee() ;
			parc.rdtRecolteSurAnnee << production;
			
			// Sauvegarde rendement culture x sol au niveau exploitation sur les trois dernières années de simulation // Renaud 250625 à voir avec Jean si on réutilise ce qu'il y a au-dessus en le modifiant ou si on garde qqch à part
			if (adaptationFertilisation = 'corpen' and !(listeNomsEspecesHerbSim contains type_cult.idEspeceCultivee)) {
				ask agri {
					do memorisationRendementNminAnneeSolCulture(parc, dateCour.annee, rendement, cultureAqYieldNC(parc.cultureParcelle.monModelDeCulture).Nmin_cumul_corpen, parc.ilot_app.sol.nom, type_cult, parcelleAqYieldNC(parc).espece_precedente, agri.sonExploitation.type);					
				}
				
				// Réinitialisation des paramètres corpen
				parcelleAqYieldNC(parc).Nmin_apports_pro <- 0.0;
				parcelleAqYieldNC(parc).Nmin_apports_min <- 0.0;
				parcelleAqYieldNC(parc).N_a_apporter_corrige_rdmtObs_NminSOM <- 0.0;
				parcelleAqYieldNC(parc).coef_abattement_corpen <- 1.0;
				parcelleAqYieldNC(parc).N_dispo_semis <- 0.0;
				parcelleAqYieldNC(parc).premier_apport_traite <- false;
				parcelleAqYieldNC(parc).espece_precedente <- type_cult;
			}
			
	//			if(length(parc.rdtRecolteSurAnnee)>1){
	//				write "deuxieme recolte de l annee"+ parc;
	//			}
			
			
			// ------------------------------ //
			// 4.5 Destruction effective de la culture (si on est sur une prairie permanente OU une prairie temp. suivie d'une prairie temp., la culture n'est pas détruite)
			ask parc.cultureParcelle {										
				remove self from: listeCultures;
				
				// Suppression de l'espece herbsim concrète // TODO Nirina 090724 Ne marche que si une seule espèce herbsim
				if species(self.monModelDeCulture.espece) = especeHerbSim {
					ask self.monModelDeCulture.espece {
						do die();
					}
				}
				
				ask self.monModelDeCulture{
					do die();
				}
				do die();
			}
			parc.cultureParcelle <- nil ; 
		
			
			// ------------------------------ //
			// 4.6 JV 17022020 memorize if field has not been sown or harvest has been forced
			ask agri.listMemoire where (each.itkAssocie = parc.getITKAnnee() and each.blocMemoire = parc.bloc_app){ // JV 131220 added condition on blocMemoire otherwise counted multiple times in assolement_espece output 
				if(parc.recolteForcee){
					if(nbParcellesRecolteForcee[dateCour.annee]=nil){
						nbParcellesRecolteForcee[dateCour.annee] <- 1;
						surfParcellesRecolteForcee[dateCour.annee] <- parc.surface;						
					}else{
						nbParcellesRecolteForcee[dateCour.annee] <- nbParcellesRecolteForcee[dateCour.annee] + 1;
						surfParcellesRecolteForcee[dateCour.annee] <- surfParcellesRecolteForcee[dateCour.annee] + parc.surface;					
					}
				}
				if(parc.semis_prevu_non_realise){
					if(nbParcellesNonSemees[dateCour.annee]=nil){
						nbParcellesNonSemees[dateCour.annee] <- 1;
						surfParcellesNonSemees[dateCour.annee] <- parc.surface;
					}else{
						nbParcellesNonSemees[dateCour.annee] <- nbParcellesNonSemees[dateCour.annee] + 1;
						surfParcellesNonSemees[dateCour.annee] <- surfParcellesRecolteForcee[dateCour.annee] + parc.surface;						
					}
				}			
			}
		}
		
		// -------------------------------------------------------------------------- //
		// 5. Remise à faux isRepriseTravailSolEffectue 160420
		parc.isRepriseTravailSolEffectue <- false; // TODO Renaud Pourquoi c'est là et pas en-dessous avec les autres variables de ce type ?
		
		// -------------------------------------------------------------------------- //
		// 6. MAJ variables irrigation (auparavant dans agriculteur.miseAJourVariables voir Mantis 0002510) JV 150420
		// on décrémente les variables incrémentées lors du semis
		if(parc.isIrrigueeAnneeCourante()){
			if(parc.isParcelleIrrigable()){
				agri.surfaceIrriguee <- agri.surfaceIrriguee - parc.surface;
				agri.nbParcellesIrriguees <- agri.nbParcellesIrriguees - 1;
			}
		} 
			
		// -------------------------------------------------------------------------- //
		// 7. Changement d'ITK 
		
		//int dateDeControleDeSemisRatee <- getJourJulienDebutMin(parc.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite); // date de debut plage recolte
	
		ask parc.ilot_app.agriculteurAssocie{
			if (parc.systemeDeCultureParcelle.isSdcTermine() or nomChoixAssolement = Donnees) { //cas fin de rotation OU dans le cas ou assolement base sur les donnees dentree car alors il faut recalculer tous les ans (par expl) les tx de mais ensilage (mais les SDC restent les memes)
				/* JV 020321 mantis #0002773 affectation maïs ensilage désormais instruit le 01/08 (auparavant ci-dessous à la première récolte d'une parcelle de l'exploitation)
				 * 		- dans la fonction agriculteurDonneesEntree.affectationMaisEnsilage (auparavant dans agriculteurDonneesEntree.choixAssolement)
				 * 		- je laisse ci-dessous l'appel à choixAssolement() lors de la première récolte de l'exploitation car nécessaire pour l'assolement par fonctions de croyance
				 * 	donc:
				 * 		- agriculteurDonneesEntrees.choixAssolement: vide (affectation maïs ensilage déplacé dans agriculteurDonneesEntree.affectationMaisEnsilage appelée le 01/08)
				 * 		- agriculteurFonctionsDeCroyances.choixAssolement: non vide mais ne concerne pas (que) le maïs ensilage
				*/ 
				if (premierChoixAssolementAnnee){
					do choixAssolement();
					premierChoixAssolementAnnee <- false;
				}				
				do getAssolement1parcelle(parc);		
			}
			else{
				ask parc.systemeDeCultureParcelle{
					do changementITK();
					if(activerITKalternatif){
						parc.itkAlternatif <-false;
					}
				}
			}
		}

		// -------------------------------------------------------------------------- //
		// 8. Définition du jour de récolte pour le gel et la prairie
//		write 'HERBSIM Renaud - test pour set jour récolte';
//		write 'parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee = ' + parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee;
//		write 'nomChoixModeleCroissancePrairie = ' + nomChoixModeleCroissancePrairie;
		// JV 090920 cas particulier gel (cf Mantis 0002670): on recherche le jour de recolte
		if(parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee="gel"){
			ask(parc.systemeDeCultureParcelle){
				do setJourRecolteGel(parc);
			}
		} else if((listeNomsEspecesHerbSim contains parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee) and (nomChoixModeleCroissancePrairie = "HerbSim" or nomChoixModeleCroissancePrairie = "HerbSimNC" or nomChoixModeleCroissancePrairie = "HerbSimSystN" or nomChoixModeleCroissancePrairie = "HerbSimHOR")) { // RM 170823 à vérifier avec jean --> on cherche un jour de récolte à la prairiet si on a pas de prairiet derrière
			
			ask(parc.systemeDeCultureParcelle){
				do setJourRecoltePrairie(parc);
			}
		}
	
		
		/* JV disabled july 2019
		//Determination de la possibilite de semer cette annee 
		if (!parc.getITKAnnee().isCultureHiver){
			parc.isSowingAllowed <- false;
		}
		*/
		
		//Gestion du cas particulier des recoltes retarde entrainant le depassement de la periode de semis  de la culture suivante!
		/* JV 260820 ne doit pas arriver si ITK cohérents au sens de https://sourcesup.renater.fr/mantisbt/view.php?id=2510#c3064
		if (parc.isSowingAllowed){
			if(parc.getStrategie(SEMIS).getJourJulienFinMax(parc.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite) <= dateCour.nbJoursEcoulesDansAnnee) {
				parc.semis_prevu_non_realise <- true;
				if(activerITKalternatif){
					parc.itkAlternatifAchercher <- true;
					write "itk alternatif pour cause de recolte tardive: fenetre semis depassee pour ITK " + parc.getITKAnnee().idITK;
				}
			}		
		}
		*/
		
		// -------------------------------------------------------------------------- //
		// 9. Remise à 0 de la parcelle (contraintes et opérations techniques)		
		parc.critereRecolteOk_echV <- 0 ;
		parc.critereRecolteOk_HumiditeSol <- 0 ;
		parc.critereRecolteOk_Pluie <- 0 ;
		
		parc.isTravailSolEffectue <- false;
		parc.OTTravailSolMultiplesEffectuee <- nil;
		parc.OTPhytoMultiplesEffectuee <- nil;
		parc.OTFaucheMultiplesEffectuee <- nil;
		parc.isBinagesSolEffectue <- false; 
		parc.isPhytoDeLaPeriodeEffectue <- map<int,bool>([]);	
		parc.isFertiDeLaPeriodeEffectue <- map<int,bool>([]);

		// -------------------------------------------------------------------------- //
		// 10. Travail du sol associé à l'opération de récolte
		do applicationEffetRUs(parc, agri.nbJoursDeDecalageActivite);
		
		// -------------------------------------------------------------------------- //
		// 11. MAJ des variables de sortie JV 140422
		if (parc.cultureParcelle = nil) {
			ask parc{
				do changementCouvertSortiesParcelle(RECOLTE);
			}
		}
		do ecritureDebugActivite(parc);		
	}				

	int getIndiceSousPeriode(parcelle parcelleEntree, int deltaTemporel){
 		int id <- -1;
 		int tjulian <- dateCour.nbJoursEcoulesDansAnnee;
 		if (parcelleEntree.recolteForcee){
 			tjulian <- getJourJulienFinMax(deltaTemporel);
 		}
 		
 		loop idMap over: mapFenetresTemporellesDebut.keys{
 			if(fenetreTempOkLocal(jourC:tjulian - deltaTemporel, jourJulienFenetreMin:(mapFenetresTemporellesDebut at idMap), jourJulienFenetreMax:(mapFenetresTemporellesFin at idMap))){
 				id <- idMap;
 			}
 		}
 		return id;
 	}

 	bool isDelaiRecolteDepasse(parcelle parc, int deltaTemporel) {
 		bool semisEtRecolteAnneesDifferentes <- parc.getITKAnnee().semisAnneeNrecolteAnneeNplusUn;
 		int dateJour <- dateCour.nbJoursEcoulesDansAnnee;
 		int jourSemisMin <- parc.getITKAnnee().strategieSemisITK.getJourJulienDebutMin(deltaTemporel);
 		int jourRecolteMax <- parc.getITKAnnee().strategieRecolteITK.getJourJulienFinMax(deltaTemporel);
 		bool res <- false;
 
 		if parc.getITKAnnee().isCultureSup365 {
 			if (dateCour.annee = (parc.cultureParcelle.anneeSemis + 1)) and dateJour >= jourRecolteMax {
 				res <- true;
 			}
 		} else {	 		
	 		if(!(semisEtRecolteAnneesDifferentes) and (dateJour >= jourRecolteMax)){
	 			res <- true;
			}else if((dateJour >= jourRecolteMax) and (dateJour < jourSemisMin)){
				res <- true;
			}		 		 		 		
		}
 		return res;
 	}	

}
		
