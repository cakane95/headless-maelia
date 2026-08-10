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
 *  main
 *  Author: Maroussia Vavasseur
 *  Description: 	Ce fichier est le chef d'orchestre du modele, c'est d'ici que se lance la creation et l'initialisation de tous les agents ainsi que l'appel
 *  				et l'ordonnancement des reflexs des differents agents.
 */

model main


import "../modeleCommun/zoneMeteoMoyenne.gaml"
import "../modeleCommun/bandeAltitude.gaml"

import "../modeleHydrographique/coursDeau.gaml"
import "../modeleHydrographique/lac.gaml"
import "../modeleHydrographique/nappePhreatique.gaml"
import "../modeleHydrographique/equipementDeCaptage.gaml"
import "../modeleHydrographique/equipementDeCaptageAEP.gaml"
import "../modeleHydrographique/equipementDeCaptageIND.gaml"
import "../modeleHydrographique/equipementDeCaptageCanaux.gaml"
import "../modeleHydrographique/equipementDeRejetAEP.gaml"
import "../modeleHydrographique/equipementDeRejetIND.gaml"
import "../modeleHydrographique/equipementDeRejetCanaux.gaml"
import "../modeleHydrographique/hru.gaml"
import "../modeleHydrographique/hruRPG.gaml"

import "../modeleAgricole/marcheAgricole.gaml"
import "../modeleAgricole/clcRPG.gaml"
import "../modeleAgricole/Agriculteurs/agriculteurDonneesEntrees.gaml"
import "../modeleAgricole/Agriculteurs/agriculteurFonctionsDeCroyances.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/Parcelles/parcelleAqYield.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/PlansAssolement/planAssolement.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/groupeIrrigation.gaml"
import "../modeleAgricole/bloc.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"
import "../modeleAgricole/Elevage/dynamiquesTroupeaux/exploitationElevage.gaml"
import "../modeleAgricole/Elevage/gestionElevage/lotAnimaux.gaml"
import "../modeleAgricole/Elevage/gestionElevage/batiment.gaml"
import "../modeleAgricole/Engrais/Engrais.gaml"

import "../modeleNormatif/pointDeReferenceCalibration.gaml"
import "../modeleNormatif/organismeUnique.gaml"
import "../modeleNormatif/uniteDeGestion.gaml"
import "../modeleNormatif/policeDeLeau.gaml"
import "../modeleNormatif/secteurAdministratif.gaml"
import "../modeleNormatif/barrage.gaml"

import "../output/ecritureResultats.gaml"
import "../processus/disparitionIlots.gaml"


global {
	
	bool init <- true;	
	date startTime <- nil;
	
	bool simulationTerminee <- false;
/*
 * ******************************************** ORDRE DE CREATION DES DIFFERENTS MODELES ********************************************
 */		
	action initGlobal{

		timestamp <- replace( #now as string,' ','_');
						
		do majChemins; // JV 100820 update paths, not functional now but will later be used to manage local/cluster paths
		write "cheminRacineMaelia: " + cheminRacineMaelia;
		write "cheminModeleVersDonnees: " + cheminModeleVersDonnees;
		write "cheminRelatifDuDossierDeSortieDeSimulation: " + cheminRelatifDuDossierDeSortieDeSimulation;
		
		if !folder_exists(cheminModeleVersDonnees) {do raiseError("répertoire inexistant: " + cheminModeleVersDonnees);}
			
		if(executerModele){	
			do ecritureConsolePourDebug(false, '\n********************** DEBUT INITIALISATION **********************\n');	
			
			do initialisationModeleCommun();
			if(executerModeleHydrographique){
				do initialistationModeleHydrographique();
			}else{
				isNeige <- false;
			}
			if(executerModeleAgricole){
				do initialisationModeleAgricole();
			}
			if(executerModeleHydrographique and nomChoixModeleHydrographique = SWAT){
				do initialisationModeleSWAT();									
			}
			if(executerModeleNormatif){
				do initialisationModeleNormatif();	
			}
			
			do initialisationZonesMeteoMoyennes();
			do initialisationProcessus();

			do affichageDetailsSimulation();		
			if(executerEcritureFichiers){
				do initialisationEcritureFichiers();
			}			
						
			do ecritureConsolePourDebug(true, 'Temps total initialisation');	
			do ecritureConsolePourDebug(false, '\n********************** FIN INITIALISATION **********************\n');	
			write detailSimulation;		
		}else{
			write 'Aucune simulation n\'a ete selectionnee';
		}
		init <- false;
		do writeSimulationParameterFile;  // JV 100820 write simulationParameters.txt				
		//do writeInitLogFile; // JV 080921 append warnings // JV 231121 already appended in DonneesGlobales.writeSimulationParameterFile	
			
	}	
	
// ---------------------------------------------------------------------------------------------------------------- //
	
	action affichageDetailsSimulation{
		if(afficherDetailSimilation){
			// INFO HYDRO
			if(utiliserMemeDonnesMeteoPartout){
				detailSimulation <- detailSimulation + 'POINT_METEO_UNIQUE' + idPointMeteoUnique  + '\n';
			}
			if(executerModeleHydrographique){
				if(nomChoixModeleHydrographique = SWAT){					
					if(isNeige){
						detailSimulation <- detailSimulation + 'SWAT_AVEC_NEIGE\n';
					}else{
						detailSimulation <- detailSimulation + 'SWAT_SANS_NEIGE\n';
					}
				}else if(nomChoixModeleHydrographique = Simple){
					detailSimulation <- detailSimulation + 'HYDRO_SIMPLE\n';
				}				
			}else{
				detailSimulation <- detailSimulation + 'PAS_HYDRO\n';
			}
			// INFO AGRO
			if(executerModeleAgricole){
				if(nomChoixAssolement = FonctionsDeCroyances){
					detailSimulation <- detailSimulation + 'AGRI_FONCTION_DE_CROYANCE\n';
				}else if(nomChoixAssolement = Donnees){
					detailSimulation <- detailSimulation + 'AGRI_ASSOLEMEMNT_PAR_DONNEES\n';
				}
				if(nomChoixModeleCroissancePlante = Simple){
					detailSimulation <- detailSimulation + 'PLANTE_SIMPLE\n';
				}else if(nomChoixModeleCroissancePlante = AqYield){
					detailSimulation <- detailSimulation + 'PLANTE_OC\n';
				}
				if(nomChoixModeleIrrigation = Simple){
					detailSimulation <- detailSimulation + 'IRR_SIMPLE\n';
				}else if(nomChoixModeleIrrigation = GROUPE_IRRIGATION){
					detailSimulation <- detailSimulation + 'IRR_COMPLEXE\n';
				}
				if(executerModeleAgricoleIrrigationUniquement){
					detailSimulation <- detailSimulation + 'QUE_ILOTS_IRR\n';
				}
				if(activerITKalternatif){
					detailSimulation <- detailSimulation + 'ITK_ALTERNATIF_ACTIVE\n';					
				}	
				else{
					detailSimulation <- detailSimulation + 'ITK_ALTERNATIF_DESACTIVE\n';
				}
				detailSimulation <- detailSimulation + length(listeIlots) + '_ILOTS_' + length(listeIlotsHorsZone) + '_ILOT_HORS_ZONE\n';
				//detailSimulation <- detailSimulation + listeIlots collect (each.id) + "\n";			
			}else{
				detailSimulation <- detailSimulation + 'PAS_AGRO\n';
			}
			// INFO NORMATIF
			if(executerModeleNormatif){
				detailSimulation <- detailSimulation + 'NORMATIF\n';
			}else{
				detailSimulation <- detailSimulation + 'PAS_NORMATIF\n';
			}
			// INFO ZH (zone detude)
			if(!executerModeleSurUneZH){
				detailSimulation <- detailSimulation + nomDecoupageZonePourLectureFichiers +'\n';
			}else{
				string nomsZHs <- 'ZH_';
				ask (listeZonesHydrographiques){
					nomsZHs <- nomsZHs + name + '_';
				}
				detailSimulation <- detailSimulation + nomsZHs + '\n';
			}
			// INFO DATE			
			detailSimulation <- detailSimulation + ("" + dateCour.jour + "/" + dateCour.mois + "/" + dateCour.annee) + '\n';
			// INFO TEMPS INIT				
			int tempsInit <- 0;
			ask first(timeStamp as list){
				tempsInit <- gettimeStampLocale();
			}
			if(not(testRegressionMode)) {
				detailSimulation <- detailSimulation + int(tempsInit / 1000) + '_sINIT\n';			
			}
		}
	}



/*
 * *********************************************** CREATION ET INITIALISATION ***********************************************
 */	
	action initialisationModeleCommun{
		
		// Si quun seul agri alors la variable "executerModeleSurUneZH" doit etre a false, car il est possible que lagri choisi nappartienne pas a la ZH definie
		if(executerUnSeulAgriculteur or executerUneSeuleParcelle){
			executerModeleSurUneZH <- false;
			do raiseWarning("désactivation exécution sur une seule ZH car exécution sur une seule exploitation ou une seule parcelle sélectionnée");
		}
		if(executerModeleNormatif and !executerModeleHydrographique){
			executerModeleNormatif <- false;
			do raiseWarning("impossible d'exécuter le module normatif si le module hydrologique n'est pas activé \u2192 désactivation du module normatif");
		}
		
		if(!reajusterSurfaceParIlot and executerModeleHydrographique){
			reajusterSurfaceParIlot <- true;
			do raiseWarning("impossible de désactiver l'ajustement des surfaces des parcelles pour qu'elles soient cohérentes avec les surfaces des îlots si le module hydrologique est activé \u2192 activation de l'ajustement des surfaces des parcelles"); 
		}
				
		bool isOk <- true; // JV 300821 passera à faux si pb
		
		do ecritureConsolePourDebug(false, '\n*********** MODELE COMMUN ***********');	

		// TIME STAMP POUR DEBUG
		do constructionTimeStamp();
		
		// PALETTE COULEUR
		do ecritureConsolePourDebug(false, 'Initialisation des palettes couleur');
		do constructionPalettesCouleurs();
		do printOk("OK");			
	
		// DATE	
		do ecritureConsolePourDebug(false, 'Création et initialisation de la date courante');
		do constructionDateCourante(); 
		if dateCour!= nil {do printOk("OK");}

		// ZH
		do ecritureConsolePourDebug(false, 'Création des zones hydrographiques');
		do creationZoneHydrographique();
		do printOk("OK " + length(listeZonesHydrographiques) + " zone(s) hydrographique(s) créée(s)");
		
		// CONTOUR ZM
		do ecritureConsolePourDebug(false, "Création du contour de la zone d'étude...");
		do constructionContourZoneMaelia();
		do printOk("OK");			
		
		// METEO	
		do ecritureConsolePourDebug(false, 'Création des données météo');
		do constructionZoneMeteo();	
		do printOk("OK " + length(zoneMeteo) + " point(s) météo créé(s)");			
								 
		// TYPE DE SOL
		do ecritureConsolePourDebug(false, 'Création des types de sol');
		do constructionTypeDeSol();
		do printOk("OK " + length(typeDeSol) + " type(s) de sol créé(s)");			

		 // COMMUNES
		do ecritureConsolePourDebug(false, 'Création et initialisation des communes');
		do constructionCommunes();	
		do printOk("OK " + length(commune) + " commune(s) créée(s)");			
					
		// CLC
		if executerModeleHydrographique {
			do ecritureConsolePourDebug(false, 'Création et initialisation du Corine Land Cover');
			do constructionCLC();
			do printOk("OK " + length(clc) + " couvert(s) créé(s)");			
		}
	}
	
// ---------------------------------------------------------------------------------------------------------------- //

	action initialisationZonesMeteoMoyennes{
		// ZONE METEO MOYENNE : doit etre fait apres la creation zh et celle des ilots
		do ecritureConsolePourDebug(false, 'Création zone(s) météo moyenne(s)...');	
		do creationZoneMeteoMoyenne();	
		do printOk("OK " + length(zoneMeteoMoyenne) + " zone(s) créée(s)");					
	}
	
// ---------------------------------------------------------------------------------------------------------------- //
	
	action initialistationModeleHydrographique{
		do ecritureConsolePourDebug(false, '\n*********** MODELE HYDROGRAPHIQUE ***********');	

		// do getParamHydro(); // si calibration montagne

		// NOEUDS HYDROGRAPHIQUES: JV 060921: pour versions includes  avant 2015, à supprimer
		do ecritureConsolePourDebug(false, 'Creation des noeuds...');			
		do constructionNoeudHydrographique();

		// COURS DEAU
		do ecritureConsolePourDebug(false, "Création des cours d'eau...");			
		do constructionCoursDeau();
		do printOk("OK " + length(coursDeau) + " cours d'eau créé(s)");					
						
		// ZONES HYDRO
		do ecritureConsolePourDebug(false, "Initialisation des zones hydro...");	
		do printOk("OK");
		do initialisationZonesHydrographiques();
				
		// RETENUES COLLINAIRES
		do ecritureConsolePourDebug(false, 'Création et initialisation des retenues collinaires');
		do constructionRetenueCollinaire();
		do printOk("OK " + length(retenueCollinaire) + " retenue(s) collinaire(s) créée(s)");					
			
		/* JV 060921 desactive: fonction constructionLac vide
		// LACS 
		do ecritureConsolePourDebug(true, 'Creation des lacs...');
		do constructionLac();
		do ecritureConsolePourDebug(false, '\t\t\t\t\t\t\t(' + length(lac as list) + ' lacs crees)');
		*/
		
		// NAPPES
		do ecritureConsolePourDebug(false, 'Création des nappes...');
		do constructionNappePhreatique();
		do printOk("OK " + length(nappePhreatique) + " nappe(s) phréatique(s) créée(s)");					
		
		// POINTS DE REFERENCES
		do ecritureConsolePourDebug(false, 'Création des points de référence...');	
		do creationPointsDeReference();
		do constructionPointDeReferenceCalibration();
		do printOk("OK " + length(pointDeReference) + " point(s) de référence créé(s)");					
		
		//CANAUX //constructionCanaux
		if(isCanaux){
			if(file_exists(canauxShape)){
				do ecritureConsolePourDebug(false, 'Création des canaux...');
				do constructionCanaux();
				do ecritureConsolePourDebug(false, '\t\t\t\t\t\t\t(' + length(canal as list) + ' canaux creees)');
			}else{
				isCanaux <- false;
				do raiseWarning("les canaux sont activés mais le fichier shape " + canauxShape + " est inexistant \u2192 désactivation des canaux");
				//write "Canaux active mais le fichier shape des canaux absent -> canaux desactive";
			}
			
		}
		// EQUIPEMENT
		if(isPrelevementEtRejetSimules){
			do ecritureConsolePourDebug(false, 'Création des equipements...');
			do constructionEquipements();
			do printOk("OK " + length(listeEquipements) + " équipement(s) créé(s): " + length(equipementDeCaptageAEP) + " CAPT AEP, " + length(equipementDeCaptageIND) + " CAPT IND, " + length(equipementDeCaptageIRR) + " CAPT IRR, " + length(equipementDeCaptageCanaux) + " CAPT CAN, " + length(equipementDeRejetAEP) + " REJ AEP, " + length(equipementDeRejetIND) + " REJ IND, " + length(equipementDeRejetCAN) + " REJ CAN, ");
		}

	}
	
// ---------------------------------------------------------------------------------------------------------------- //

	action initialisationModeleAgricole{
		do ecritureConsolePourDebug(false, '\n*********** MODELE AGRICOLE ***********');	
					
		// ESPCECES CULTIVEES
		do ecritureConsolePourDebug(false, 'Création des espèces cultivées...');	
		do constructionEspeceCultivee();
		do printOk("OK " + length(especeCultivee) + " espèces cultivées créées");
		if (nomChoixModeleCroissancePrairie = "HerbSim" or nomChoixModeleCroissancePrairie = "HerbSimNC") {
			write "Les prairies seront simulées avec " + nomChoixModeleCroissancePrairie;
			do constructionEspeceHerbSim();
			do printOk("OK " + length(especeHerbSim) + " espèces HerbSim créées");
		}
		

        // MATERIEL IRRIGATION
        do ecritureConsolePourDebug(false, "Création du materiel d'irrigation...");
		do initialisationMateriel();
		do printOk("OK " + length(materielIrrigation) + " matériel(s) créé(s)");
	
		// CREATION ILOTS
		do ecritureConsolePourDebug(false, 'Création des îlots...');
		do creationIlots();
		do printOk("OK " + length(listeIlots) + " îlot(s) créé(s)");
		
		// CREATION ILOTS HORS ZONE
		if(avecIlotsHorsZone){
			do ecritureConsolePourDebug(false, 'Création des îlots hors zone...');
			do creationIlotHorsZone();
			do printOk("OK " + length(ilotHorsZone) + " îlot(s) hors zone créé(s)");
		}

		// PRO
		if (nomChoixModeleCroissancePlante = "AqYieldNC") {
			do ecritureConsolePourDebug(false, 'Création des engrais...');
			do constructionEngrais();			
		}

		// SYSTEME DE CULTURE REF		
		do ecritureConsolePourDebug(false, 'Création des itinéraires techniques...');	
		if itkParPrecedent {write "\tdéclaration des ITK par précédent cultural";}
		else {write "\tdéclaration des ITK par système de culture de référence";}
		do constructionSystemeDeCultureDeReference();	
		if !itkParPrecedent {
			do printOk("OK " + length(mapSystemesDeCultureDeRef.values) + " système(s)s de culture de référence créé(s)");		
		}
		do printOk("OK " + length(listeITKs) + " ITK créé(s)");		
		
		// CREATION PARCELLES		
		do ecritureConsolePourDebug(false, 'Création des parcelles...');	
		do creationParcelles();
		do printOk("OK " + length(listeParcelles) + " parcelle(s) créée(s)");		
 
		// CREATION PARCELLES HORS ZONE		
		if(avecIlotsHorsZone){
			do ecritureConsolePourDebug(false, 'Création des parcelles hors zone...');	
			do creationParcelleHorsZone();
			do printOk("OK " + length(listeParcellesHorsZone) + " parcelle(s) hors zone créée(s)");		
		}
			
		// INITIALISATION ILOTS
		do ecritureConsolePourDebug(false, 'Initialisation des îlots...');
		do initialisationIlot();		
		do printOk("OK " + length(listeIlots) + " îlot(s) restant(s)");		
		
		// EXPLOITATION
		do ecritureConsolePourDebug(false, 'Création des exploitations...');
		if (constructionExploitationElevage){
			do constructionExploitationsElevage();
		}
		do constructionExploitations();
		do printOk("OK " + length(exploitation) + " exploitation(s) créée(s)");
		if (gestionStocksEngrais = 'exploitation') {
			do initialisationStocksEngraisExploitation;
			do printOk("OK " + " à modifier" + " stock(s) d'engrais affecté(s) par exploitation");	
		} else if (gestionStocksEngrais = 'territoire') {
			do printOk("Les stock(s) d'engrais sont gérés à l'échelle du territoire (via engrais.csv)");
		} else {
			do raiseError("Le paramètre gestionStocksEngrais (launcher) doit être instancié avec une des valeurs suivantes : ['exploitation', 'territoire']");
		}
	
		// AGRICULTEUR
		do ecritureConsolePourDebug(false, 'Création des agriculteurs...');	
		do constructionAgriculteur();
		do printOk("OK " + length(listeAgriculteurs) + " agriculteur(s) créé(s)");		
		
		// SYSTEME DE CULTURE
		do ecritureConsolePourDebug(false, 'Création des systèmes de cultures...');	
		do constructionSystemeDeCulture();		
		if length(mapITKmanquantEtParcelle)>0 {
			do raiseWarning(initLogITKmanquants(""));
			do raiseError("certains ITK sont manquants, voir le fichier " + nomFichierITKmanquants + ".csv");
		}
		do printOk("OK " + length(listeSystemesDeCulture) + " système(s) de culture créé(s)");		

		// BLOC
		do ecritureConsolePourDebug(false, 'Création des blocs de parcelles...');
		do constructionBlocs();
		do printOk("OK " + length(bloc) + " bloc(s) créé(s)");				

		// MARCHE AGRICOLE
		do ecritureConsolePourDebug(false, 'Création du marché agricole...');
		do constructionMarcheAgricole(); 
		do printOk("OK " + length(marcheAgricole) + " marché agricole créé");

		// MEMOIRE AGRI
		do ecritureConsolePourDebug(false, 'Création des mémoires des agriculteurs...');
		if nomChoixAssolement!="Donnees" { // JV 121221 pas d'agents mémoire si assolement par données d'entrée (cf. Mantis #0002878)
			do constructionMemoires();			
		}
		do printOk("OK " + length(memoire) + " mémoire(s) créée(s)");				
		
		// PLAN ASSOLEMENT
		do ecritureConsolePourDebug(false, 'Création des plans dassolement...');
		do constructionPlanAssolement();
		do printOk("OK " + length(listePlansAssolement) + " plan(s) créé(s)");				
		
		// CLC RPG
		if (nomChoixAssolement != Donnees){
			do ecritureConsolePourDebug(true, 'Creation des clc RPG par ZH...');
			do constructionClcRPG();	
		}
		
		// Ateliers d'élevage et lots d'animaux (spécifique module gestion des élevages)
		if (executerModelePaturage){
			do ecritureConsolePourDebug(false, "Creation des ateliers d'élevage et des lots d'animaux");
			do constructionBatimentElevage();
			do printOk("OK " + length(batiment) + " batiment(s) d'élevage créé(s)");				
			do constructionLotAnimaux();
			do printOk("OK " + length(atelierElevage) + " atelier(s) d'élevage et " + length(lotAnimaux) + " lot(s) d'animaux créé(s)");	
		}
	}



// ---------------------------------------------------------------------------------------------------------------- //

	action initialisationModeleSWAT{	
		do ecritureConsolePourDebug(false, '\n*********** MODELE SWAT ***********');	

		// BANDE DALTITUDE
		do ecritureConsolePourDebug(false, "Création des bandes d'altitudes...");
		do constructionBandeAltitude();
		do printOk("OK " + length(bandeAltitude) + " bande(s) d'altitude créée(s)");		
		
		// HRU HYDRO
		do ecritureConsolePourDebug(false, 'Création des HRU non agricoles...');
		do constructionHRUs();
		do printOk("OK " + length(hru) + " HRU non agricole(s) créée(s)");		
		
		// HRU RPG
		do ecritureConsolePourDebug(false, 'Création des HRU agricoles...');
		do constructionHRUsRPG();
		do printOk("OK " + length(hruRPG) + " HRU agricole(s) créée(s)");		
		
	}

// ---------------------------------------------------------------------------------------------------------------- //
	
	action initialisationModeleNormatif{
		do ecritureConsolePourDebug(false, '\n*********** MODELE NORMATIF ***********');	
		
		// BARRAGE
		if(executerBarrage){
			do ecritureConsolePourDebug(false, 'Création des barrages...');
			do constructionBarrage();
			do printOk("OK " + length(barrage) + " barrage(s) et " + length(gestionnaireDeBarrage) + " gestionnaires de barrage créé(s)");		
		}
		
		// ZONES ADMINISTRATIVES
		do ecritureConsolePourDebug(false, 'Création des zones administratives...');			
		do constructionZonesAdministratives();
		do printOk("OK " + length(listZonesAdministratives) + " zone(s) administriative(s) créée(s)");		
		
		// SECTEURS ADMINISTRATIFS
		do ecritureConsolePourDebug(false, 'Création des secteurs administratifs...');	
		do constructionSecteursAdministratif();
		do printOk("OK " + length(secteurAdministratif) + " secteur(s) administriatif(s) créé(s)");		
		
		//PREFET
		do ecritureConsolePourDebug(false, 'Création et initialisation du prefet...');
		do constructionPrefet();
		do printOk("OK " + length(prefet) + " préfet créé");		

		//UNITE DE GESTION
		do ecritureConsolePourDebug(false, 'Création et initialisation des unités de gestion...');
		do constructionUnitesDeGestion();	
		do initialisationUGCommunes();
		do printOk("OK " + length(uniteDeGestion) + " unité(s) de gestion créée(s)");		

		//UNITE DE DEFINITION DU VP
		do ecritureConsolePourDebug(false, "Création et initialisation de l'unité de definition du VP...");
		do constructionUniteDeDefinitionDuVP();	
		do printOk("OK " + length(uniteDeDefinitionDuVP) + " unité(s) de deinition créée(s), il reste " + length(equipementDeCaptageIRR) + " équipements de captage pour l'irrigation");		

		//ORGANISME UNIQUE
		do ecritureConsolePourDebug(false, "Création et initialisation de l'organisme unique...");
		do constructionOrganismeUnique();	
		do printOk("OK " + length(organismeUnique) + " organisme unique créé");		
		
		// POLICE DE LEAU
		do ecritureConsolePourDebug(false, "Création et initialisation de la police de l'eau...");
		do constructionPoliceDeLeau();
		do printOk("OK " + length(policeDeLeau) + " police de l'eau créée");		
	}
	
// ---------------------------------------------------------------------------------------------------------------- //
	
//	action initialisationModelePourCalibrage{
//		do ecritureConsolePourDebug(false, '\n*********** CALIBRATION ***********');	
//	}

	action initialisationProcessus{		
		do ecritureConsolePourDebug(false, '\n*********** PROCESSUS ***********');	
				
		// DISPARITION DES ILOTS
		if(executerModeleAgricole and executerModeleHydrographique and executerDisparitionIlots){
			do constructionDisparitionIlots();		
		}
	}
		
/*
 * ********************************************************* DYNAMIQUE *********************************************************
 */	
// ---------------------------------------------------------------------------------------------------------------- //		
	action schedulerGlobal{	
		if(dateCour.indiceDate < indiceDateFinSimulation){
			if startTime=nil {
				startTime <- #now;
			}
			string nbAgents <- "" + dateCour.nbJoursEcoulesDansAnnee + "," + length(world.agents);
			string ficNbAgents <- cheminRelatifDuDossierDeSortieDeSimulation + "/nbAgentsPerDay.csv";
			//save nbAgents to: ficNbAgents type: text rewrite: false;
			
			/*
			map<string,int> nbAgentsPerSpecies;
			ask world.agents{
				string monEspece <- string(species(self));
				if !(nbAgentsPerSpecies.keys contains monEspece) {
					nbAgentsPerSpecies[monEspece] <- 1;
				}else{
					nbAgentsPerSpecies[monEspece] <- nbAgentsPerSpecies[monEspece]+1;
				}
			}
			loop spec over:nbAgentsPerSpecies.keys {
				write "" + spec + "\t" + nbAgentsPerSpecies[spec];
			}
			*/	
			
			// Simulation		
			do schedulerJournalierDate();
			do remiseAzeroGlobale();
			if(dateCour.jour = 1 and dateCour.mois = 1){
				do schedulerDebutAnnuel();
			}
			if(dateCour.jour = 31 and dateCour.mois = 12){
				do schedulerFinAnnuel();
			}			
			if(dateCour.jour = 15 and dateCour.mois = 6){
				do scheduler15Juin();
			}

			do schedulerJournalier();

			// Output
			if(executerEcritureFichiers){
				do ecritureFichiers(); 
			}				
			// Debug		
			do toStringGlobale();	
			if(afficheDateJournaliere){
				ask dateCour {
					write self.toString();
				}				
			}					
		}else{
			do ecritureConsolePourDebug(false, '*********** FIN DE SIMULATION ***********');
			string simDuration <- "temps de simulation: " + (#now-startTime);
			write simDuration;
			string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/simulationDuration.txt";
			save simDuration to: fileName format: 'text' rewrite:true;
			
			do pause; //halt(); // pause   halt
			
			simulationTerminee <- true;
		}
	}

// ---------------------------------------------------------------------------------------------------------------- //		
	action schedulerJournalierDate{	
		ask dateCour{
			do comportementJournalier();
			if (afficheDateJournaliere) {
				write self.toString();				
			}
		}			
	}

	
// ---------------------------------------------------------------------------------------------------------------- //		
	action schedulerDebutAnnuel{	
		do chargementDataMeteoAnneeCourante();
		ask (listeAgriculteurs){
			do comportementAnnuel();
		}				
		ask (marcheAgricole as list){
			do comportementAnnuel();
		}
		ask (commune as list){
			do comportementAnnuel();
		}
		if(isPrelevementEtRejetSimules){
			// Doit etre fait apres le calcul du volume a preleve par commune et sa somme sur la zone Maelia
			do calculVolumeAEPconsomeAnnuelZM();			
		}
		ask (organismeUnique as list){ // apres l'agriculteur car il doit avoir defini son plan pour connaitre les surfaces irriguees de lannee a venir
			do comportementAnnuel();
		}
		ask (listeParcellesUtiles){
			do comportementAnnuel();
		}
		ask (listZonesAdministratives){
			do comportementAnnuel();
		}
		ask (gestionnaireDeBarrage as list){
			do comportementAnnuel();
		}	
	}

// ---------------------------------------------------------------------------------------------------------------- //	
	action schedulerFinAnnuel{		
		
		ask (policeDeLeau as list){
			do comportementAnnuel();
		}
			
		if(executerModeleAgricole and executerModeleHydrographique and executerDisparitionIlots){
			ask(disparitionIlots as list){
				do comportementAnnuel();
			}		
		}
		
		ask (listeParcellesUtiles){ 
			do comportementFinAnnuel(); // JV 130422 MAJ des variables de sorties
		}			
		
	}

// ---------------------------------------------------------------------------------------------------------------- //	
	action remiseAzeroGlobale{	
		// Doit remettre a zero le volume journalier qui va etre mit a jour dans la strategie d'irrigation de l'agri
		ask(equipementDeCaptageIRR as list){
			do miseAzeroVolumeJouralier();
		}
		ask listeZonesHydrographiquesHierarchisees{
			do miseAzeroVolume();
		}
		ask (listeCoursDeau + listeNappesPhreatiques + listeRetenuesCollinaires + listeCanaux){
			do miseAzero();
		}
	}
			
// ---------------------------------------------------------------------------------------------------------------- //	
	action schedulerJournalier{		 
		/*
		 * MODELE COMMUN  --------------------------------------
		 */
		ask (zoneMeteo as list){
			do comportementJournalier();			
		}
		ask (zoneMeteoMoyenne as list){
			do comportementJournalier();		
		}
		/*
		 * MODELE AGRICOLE  --------------------------------------
		 */
		// MAJ age des cultures: JV 160322 cf Mantis #0002889
		ask (culture as list) union (cultureIrrigable as list){	
			age_culture <- age_culture + 1;	
		}
		// Il faut faire pleuvoir sur les ilots puis faire pousser la plante et ensuite ruisseler
		ask (listeIlots){
			do comportenmentJournalier();
		}

		ask (listeAgriculteurs){
			do comportementJournalier();
		}

		ask (listeParcellesUtiles){
			do comportementJournalier(); // JV 130422 MAJ des variables de sorties
		}			
		// On fait croitre la plante ici que si on a pas le modele SWAT (sinon on le fait depuis les ZH)
		if(!executerModeleHydrographique){
			ask (listeIlots){
				do croissancePlante();
			}
		}

		// Dynamiques de gestion d'élevage
		if(executerModelePaturage){
			ask (lotAnimaux){
				do comportementJournalier();
			}	
		}
		/*
		 * MODELE HYDRO  --------------------------------------
		 */
		// On calcule la demande en prelevemennt avant la phase ecoulement eau des ZH (le volume effectivement preleve va etre mis a jour dans la ZH lors de la phase SWAT)
		if(isPrelevementEtRejetSimules){
			do calculVolumeAEPconsomeJournalierSouhaiteZM();	
			ask((equipementDeCaptageAEP as list) + (equipementDeCaptageCanaux as list) + (equipementDeCaptageIND as list)){
				do comportementJournalier();
			}
			if(isCanaux){
				ask (equipementDeCaptageCanaux as list){
					do miseAJourVolumeSouhaite(calculVolumeSouhaite());
				}
			}	
			
		}		
		// On doit calculer le debit des ZH amonts a aval (on calcule aussi les rejets et la croissance des plantes a ce moment)
		ask listeZonesHydrographiquesHierarchisees{
			do comportementJournalier();
//			do toString;
		}
		// On peut ensuite mettre a jour les rejets pour le jour suivant
		do calculVolumeConsommeReel_ZM();
		if(isCanaux){
			ask (canal as list){
				do gestionRejetHZ(); 
			}
		}	
			
		// Une fois que les volumes preleves pour lirrigation sont determines, on met a jour la quantite deau de lagri
		ask listeAgriculteurs{
			do miseAJourEauDisponible();
		}
		/*
		 * MODELE NORMATIF  --------------------------------------
		 */		
		ask (listePointsRef){
			do comportementJournalier();			
		}	
		ask (gestionnaireDeBarrage as list){
			do comportementHebdomadaire();
		}		
		ask (listeZAparOrdreAvalVersAmont){ // doit etre apres l'agriculteur sinon la maj des cultureIrr dans les communes se fait avec un jour de retard (et donc erreur)
			do comportementJournalier();		
		}	
		if(lePrefet!=nil){ // JV 18/08/20 depuis GAMA_1.8_stable on ne peut plus faire de ask sur un agent nul -> on pourrait mettre tout ce passage dans un if(modeleNormatif) ?
		ask (lePrefet){
			do comportementJournalier();		
		}	
		}
		ask (gestionnaireDeBarrage as list){
			do comportementJournalier(); 
		}
		ask (organismeUnique as list){ // il faut le faire apres le point de ref pour stocker le debit journalier
			do comportementJournalier();
		}			
		ask (policeDeLeau as list){
			do comportementJournalier();
		}
		// Pour savoir si la est en restriction ou non pour le jour dapres
		ask (cultureIrrigable as list){		
			do majDerniereIrrigation();
		}
		// Affichage
		ask (groupeIrrigation as list){		
			do colorationGroupe();		
		}		
	}


	action scheduler15Juin{		 
		ask (listeIlots){
			do calculSurfaceRellementIrriguableSurAnnee();				
		}
		ask (gestionnaireDeBarrage as list){
			do estimationPrelevementsJournalier();
		}
		
	}


	action getParamHydro{
		if(parametrageHydro = "montagne"){ //parametrage issue de la calibration en amont de Valentine (maximum de vraissemblance)
			seuilRevapAquiferePeuProfond <- 174.31; // aqShthr,rvp
			put 71.0045 at: FORET in: CN;  //CN2_FRST
			coefPercolationVersAquifereProfondGlobal <- 0.0900; //BetaDeep
			retardEntreSortiSolEtEntreeAquifereGlobal <- 46.4860;  //deltaGW
			eauStockeeAquiferePeuProfondInit <- 1984.7;  //SHALLST
			coefficientManningTerrain <- 0.2406; //nterrain
			coefficientSurfaceRuissellementLag <- 1.1793;  //surlag
			coefRevapEauSouterraineGlobal <- 0.07658; //BetaRev
			write  "Affectation du jeu de paramètres hydrologiques "+ parametrageHydro;	
		}
	}

	// JV 240821 écriture du fichier log avec les problèmes identifiés lors de l'initialisation
	action writeInitLogFile{
		
		string chaine <- initLogWarning;
		
		// si il y a des ITK manquants
		if length(mapITKmanquantEtParcelle)>0 {
			chaine <- chaine + initLogITKmanquants(chaine);
		}
		
		string fileName <- cheminRelatifDuDossierDeSortieDeSimulation + "/simulationParameters.txt";
		save chaine to:fileName rewrite:false;
		
	}

	// JV 240821 écriture des ITK manquants dans la chaine du log et dans le fichier spécifique
	string initLogITKmanquants(string chaine){
		
		// pour la console
		chaine <- chaine + length(mapITKmanquantEtParcelle) + " ITK manquants ont été identifiés\n";
		
		// pour le fichier des ITK manquants
		string ligne <- "";
		// l'entête dépend du mode de déclaration (ITK par précédent ou SdC ref)
		if itkParPrecedent {
			ligne <- "culture;culturePrecedente;materiel;zonePedo;typeExloitation;parcelles\n";
		}else{
			ligne <- "SdC_ref;culture;materiel;zonePedo;typeExloitation;parcelles\n";
		}
		
		// parcourt des ITK manquants
		loop s over: mapITKmanquantEtParcelle.keys{
			// les premières colonnes de la ligne sont remplies avec la clé qui contient les critères séparés par des ;
			ligne <- ligne + s;
			// puis la liste des parcelles concernées par l'ITK manquant
			list<string> parcelles <- mapITKmanquantEtParcelle[s];
			loop p over: parcelles{
				ligne <- ligne + ";" + p;
			}
			ligne <- ligne + "\n";
		}
		
		save ligne to: cheminRelatifDuDossierDeSortieDeSimulation + "/" + nomFichierITKmanquants format:"text" rewrite:false;
		
		return chaine;
	}


/*
 * ********************************************************* DEBUG *********************************************************
 */	
 	float aSupprimer <- 0.0;
	action toStringGlobale{	
		
//		ask (zoneMeteo as list){
//			write toString();
//		}
			
//		int nbSURF <- 0;
//		int nbRET <- 0;
//		int nbNAPP <- 0;
//		int nbIlot <- 0;
//		ask listeIlots{
//			ask(listeEquipementsCaptagesAssocies.keys){
//				if(natureRessourcePrelevee = SURF){
//					nbSURF <- nbSURF +1;
//				}else if(natureRessourcePrelevee = NAPP){
//					nbNAPP <- nbNAPP +1;
//				}else if(natureRessourcePrelevee = RET){
//					nbRET <- nbRET +1;
//				}
//				nbIlot <- nbIlot +1;
//			}
//		}
//		
//		write "nbIlots = " + nbIlot;
//		write "nbSURF = " + nbSURF + " - nbNAPP = " + nbNAPP + " - nbRET = " + nbRET;
		
//		ask listeAgriculteurs{
//			ask listeParcelles{
//				write idParcelle + " - " + getITKAnnee().especeCultiveeITK.idEspeceCultivee;			
//			}
//		}
		
//		write 					'IRR_EQU_ZM_SOUHAITE = ' + world.getVolumePreleve_EQU_ZM(acteur:IRR, type:SOUHAITE) +
//								' - IRR_EQU_ZM_REEL = ' + world.getVolumePreleve_EQU_ZM(acteur:IRR, type:REEL) +
//								' - IRR_PARCELLE_ZM_SOUHAITE = ' + world.getVolumeIrrigationSouhaitee_Parcelles_ZM() +
//								' - IRR_PARCELLE_ZM_REEL = ' + world.getVolumeIrrigationReelle_Parcelles_ZM();	
//		write 					'AEP_EQU_ZM_SOUHAITE = ' + world.getVolumePreleve_EQU_ZM(acteur:AEP, type:SOUHAITE) +
//								' - AEP_EQU_ZM_REEL = ' + world.getVolumePreleve_EQU_ZM(acteur:AEP, type:REEL) +
//								' - IND_EQU_ZM_SOUHAITE = ' + world.getVolumePreleve_EQU_ZM(acteur:IND, type:SOUHAITE) +
//								' - IND_EQU_ZM_REEL = ' + world.getVolumePreleve_EQU_ZM(acteur:IND, type:REEL);	
				
	}	
}


