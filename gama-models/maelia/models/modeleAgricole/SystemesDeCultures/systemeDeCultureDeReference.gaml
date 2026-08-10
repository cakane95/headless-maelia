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
 *  systemeDeCultureDeReference
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model systemeDeCultureDeReference

import "../strategieRepriseTravailSol.gaml"
import "../strategiePature.gaml"
import "../strategiePatureMultiples.gaml"
import "../../main/main.gaml"

global{
	string cheminReglesDeDecision <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/' + nomFichierReglesDeDecision;
	string cheminReglesDeDecisionFerti <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/' + nomFichierReglesDeDecisionFerti;
	string cheminRotationsSystemeDeCulture <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/systemesDeCultureDeReference.csv';	
	string cheminMatriceDistanceCulturale <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/matriceDistanceCulturale.csv';
	map<string,systemeDeCultureDeReference> mapSystemesDeCultureDeRef <- map([]);
	matrix matriceDistanceCulturale <- nil;
	map<string,list<systemeDeCultureDeReference>> SDCRefParZonePedoClim <- map([]); // cle ZC _ SOL
	
	
	// Renaud 290922 Variables pour accélération du module agricole
	map<string, list<int>> accelerateur_agricole <- ["TRAVAIL_SOL"::nil, "BINAGE"::nil, "REPRISE"::nil, "SEMIS"::nil, "RECOLTE"::nil, "FERTI"::nil, "IRRIGATION"::nil, "PHYTO"::nil, "FAUCHE"::nil, "PATURE"::nil];
	
	action ajout_jours_accelerateur (string type_ot, string j_debut, string j_fin) {	
 		list<string> liste_debut <- j_debut tokenize SEPARATEUR;
		list<string> liste_fin <- j_fin tokenize SEPARATEUR;
		
		int debut_ot <- int(liste_debut[0]);
		int fin_ot <- int(liste_fin[length(liste_fin)-1]);
		
		loop i from: debut_ot to: fin_ot {
			accelerateur_agricole[type_ot] <<+ [i];
		}
		accelerateur_agricole[type_ot] <- remove_duplicates(accelerateur_agricole[type_ot]);
	}
	
	/*
	 * *****************************************************************************************
	 * Public
	 */
	 action constructionSystemeDeCultureDeReference{
	 	do lectureFichierReglesDeDecisions();
	 	do lectureFichierRotationsTypesSdcRef();
	 	do lectureFichierMatriceDistanceCulturale(); 	
	 	// JV 301123 si avecContrainteDeMainOeuvre, on peut rater des semis à cause de reports d'heures de travail qui font sortir de la fenêtre de semis sans avoir semé
	 	// on va donc explicitement identfier pour chaque jour les ITK dont c'est le dernier jour de semis pour pouvoir les forcer même en cas de report 
	 	if avecContrainteDeMainOeuvre and !activerITKalternatif {
			do computeMapItkLastSowingDay;	 		
	 	}	
	 }
	 
	 /*
	 * *****************************************************************************************
	 * Private
	 */
	 action lectureFichierReglesDeDecisions{
	 
	 	if !file_exists(cheminReglesDeDecision) {do raiseError("fichier inexistant: " + cheminReglesDeDecision);}
	 
	 	//write "mapMateriel: " + mapMateriel;  JV debug
		matrix initSystemeDeCulture <- matrix(csv_file(cheminReglesDeDecision,";",false));	
		//matrix initSystemeDeCulture <- matrix(file(cheminReglesDeDecision));		
		int nbColones <- length(initSystemeDeCulture row_at 0);		
		list<string> entetesLues <- (initSystemeDeCulture column_at 0) as list<string>;
		map<string,int> lignes <- remplissageMapEnteteFichier(entetesLues);
		do testCoherenceEntetes(lignes);

		// JV 280319 détection itk par précédent: présence de ID_PREC
		itkParPrecedent <- world.isEnteExite(ID_PREC,lignes);
		//write "itkParPrecedent = " + itkParPrecedent;
		
		// Lecture du fichier de rdd ferti
		matrix initSystemeDeCulture_ferti;
		int nbColones_ferti;
		list<string> entetesLues_ferti;	
		map<string,int> lignes_ferti;
		list<string> nom_itk_ferti;
		if plusieursFertilisationsParITK {
		 	if !file_exists(cheminReglesDeDecisionFerti) {do raiseError("fichier inexistant: " + cheminReglesDeDecisionFerti);}
			initSystemeDeCulture_ferti <- matrix(csv_file(cheminReglesDeDecisionFerti,";",false));
			nbColones_ferti <- length(initSystemeDeCulture_ferti row_at 0);
			entetesLues_ferti <- (initSystemeDeCulture_ferti column_at 0) as list<string>;	
			lignes_ferti <- remplissageMapEnteteFichier(entetesLues_ferti);
			nom_itk_ferti <- (initSystemeDeCulture_ferti row_at 0) as list<string>;
		}

	    	// Lecture du fichier exploitation pour construire la liste des types d'exploitation possibles
		if (file_exists(fichierCaracExploit)){
			matrix matrixSCaracExploit <- matrix(csv_file(fichierCaracExploit,";",true));
			int nbLignes <- length(matrixSCaracExploit column_at 0);
			//write "Nombre de lignes exploitation.csv = " + nbLignes;
			loop i from: 0 to: (nbLignes -1){ //boucle sur les exploitations
				listTypeExploit <+ string(matrixSCaracExploit[1,i]);
			}
			listTypeExploit <- remove_duplicates(listTypeExploit);
			write "\ttypes d'exploitation disponibles : " + listTypeExploit;
		}

		// On boucle par colone et on affecte les info par espece/sdc
		loop i from: 2 to: ( nbColones - 1 ) {
			list<string> colone <- (initSystemeDeCulture column_at i) as list<string>;
			especeCultivee espece <- nil;
			list<systemeDeCultureDeReference> sdcs <- [];
			list<especeCultivee> precedents <- [];
			itk itkCourant <- nil;

			// 1. Espece   
			if(world.isEnteExite(ID_ESPECE,lignes)){espece <- mapEspecesCultiveesParId at (colone at (lignes at ID_ESPECE));}
			if(espece != nil){    		
				if(itkParPrecedent){
					// 2. Par précedent: On récupère la liste des précédents								
					// JV 290622 si contient "*" on ajoute toutes les cultures
					if ((colone at (lignes at ID_PREC)) index_of "*")!=-1 {
						precedents <- listeEspecesCultiveesParOrdreSaisie;
					} else {
						list<string> listeIdPrec <- (colone at (lignes at ID_PREC) tokenize SEPARATEUR);
						if(empty(listeIdPrec)){
							listeIdPrec << colone at (lignes at ID_PREC);
						}					
						loop idPrec over: listeIdPrec{
							if(mapEspecesCultiveesParId at idPrec = nil){
								string toto <- world.raiseError("ITK " + (colone at (lignes at ID_ITK)) + ": " + espece.idEspeceCultivee + " sur précédent " + idPrec + "\n\t\tl'espèce " + idPrec + " n'existe pas !");
							}else{
								especeCultivee precedent <- mapEspecesCultiveesParId at idPrec; // récupération instance especeCultivee du précédent 
								precedents << precedent; // ajout à la liste des précédents
	//							string cle <- espece.name + "_apres_" + precedent.name; // définition de la clé pour la map: la clé contient: espece_apres_especePrec  
	//							mapITKparCultureEtPrecedent <+ cle::[]; // ajout d'une liste d'itk vide pour ce couple culture/précédent  // 180222 --> COmmenter car écrase les valeurs existantes si la clé existe déjà
							}
						}	
					}				
				}
				else{
					// 2. Par SdC: Creation SDC (un itk peut etre utilise dans 1 ou plusieurs sdc)			
					if(world.isEnteExite(IDS_SDCS,lignes)){sdcs <- creationSystemeDeCultureDeReference((colone at (lignes at IDS_SDCS)));}					
				}
			}else{
				string toto <- world.raiseError("ITK " + (colone at (lignes at ID_ITK)) + ": " + (colone at (lignes at ID_ESPECE)) + "\n\t\tl'espèce " + (colone at (lignes at ID_ESPECE)) + " n'existe pas !");
			}
			
			// 3. Creation ITK
	    	if(itkParPrecedent and espece != nil){
	    		itkCourant <- (world.creationITKparPrecedent(espece.idEspeceCultivee, precedents, (colone at (lignes at IS_CULTURE_HIVER))));
	    		//write "itkCree: " + itkCourant.name;  JV debug	
	    		//write "mapITKparCultureEtPrecedent: " + mapITKparCultureEtPrecedent;  JV debug
		    }
	    	else if(!itkParPrecedent and espece != nil and !empty(sdcs)){
	    		itkCourant <- (world.creationITK(espece.idEspeceCultivee, sdcs, (colone at (lignes at IS_CULTURE_HIVER))));	
//				itkCourant.especeCultiveeAlternative <- first((especeCultivee as list) where (each.idEspeceCultivee = (colone at (lignes at ITK_ALTERNATIF))));
		    }
	        if(world.isEnteExite(NOM_ITK_AFFICHAGE,lignes)){
	        	itkCourant.nomPourAffichage <- (colone at (lignes at NOM_ITK_AFFICHAGE));
	        }
	        // 4. Attribution des critères de spatialisation
	        
	        // 4.1 Affectation du matériel MATERIEL
	        string idMat <-  (colone at (lignes at MATERIEL));
	        itkCourant.matITK <- (mapMateriel at idMat);
	        //write "idMat: " + idMat + " mapMateriel at idMat: " + (mapMateriel at idMat); JV debug
	        itkCourant.name <- itkCourant.name + SEPARATEUR + idMat ;
	       	itkCourant.idITK  <-(colone at (lignes at ID_ITK));
	        
	        // write "itk prop: matITK: " + itkCourant.matITK + " name: " + itkCourant.name + " idITK: " + itkCourant.idITK; JV debug
	        
	        // 4.2 Affectation de la zone pédologique
	        if(world.isEnteExite(ZONE_PEDO,lignes)){
	        	if ((colone at (lignes at ZONE_PEDO)) = "*"){
	        		if(itkParPrecedent){
	        			itkCourant.listSolITK <- listNomZonePedo;
	        		}else{
		        		ask sdcs{itkCourant.listSolITK <- listNomZonePedo;}		        						        				       
			        }
	        	}else{
	        		if(itkParPrecedent){
			        	loop sol over: ((colone at (lignes at ZONE_PEDO)) tokenize SEPARATEUR) {
			       			put sol at: sol  in: itkCourant.listSolITK;
			        	}	        			
	        		}else{
		        		ask sdcs{
				        	loop sol over: ((colone at (lignes at ZONE_PEDO)) tokenize SEPARATEUR) {
				       			put sol at: sol  in: itkCourant.listSolITK;
				        	}
				        }				        
			        }
	        	}	        	
	        }else{ //meme gestion que *
        		if(itkParPrecedent){
					itkCourant.listSolITK <- listNomZonePedo;					
				}else{
					ask sdcs{itkCourant.listSolITK <- listNomZonePedo;}
			    }
	        }
    		// write "itk listSolITK: " + itkCourant.listSolITK; JV debug
	        
			// 4.3 Affectation du type d'exploitation
	        //write "Affectation des type expl aux ITK";
	        if (world.isEnteExite(TYPE_EXPL,lignes)) {
	        	//write "entete TYPE_EXPL présente";
	        	if ((colone at (lignes at TYPE_EXPL)) = "*") {
	        		if(itkParPrecedent){
						itkCourant.listTypeExploitITK <- listTypeExploit;
					} else {	
		        		ask sdcs{
				        	itkCourant.listTypeExploitITK <- listTypeExploit;
				        }
					}
	        	} else { // Ajout Renaud 180222
	        		if(itkParPrecedent){
						loop typeExp over: ((colone at (lignes at TYPE_EXPL)) tokenize SEPARATEUR) {
			       			itkCourant.listTypeExploitITK <+ typeExp;
			        	}				
					}else{
						ask sdcs{
				        	loop typeExp over: ((colone at (lignes at TYPE_EXPL)) tokenize SEPARATEUR) {
				       			itkCourant.listTypeExploitITK <+ typeExp;
				        	}
				        }
				    }
			        //write "ITK = " + itkCourant.nomPourAffichage + " --> " + itkCourant.listTypeExploitITK;
	        	}
	        	
	        } else { // JV 240821: si entete existe pas: on affecte le type par défaut (chaine vide)
				ask sdcs{
					itkCourant.listTypeExploitITK <+ "";
		        }
	        }

			// 4.4 Affectation du type de gestion de la prairie
	        //write "Affectation des type expl aux ITK";
	        if (world.isEnteExite(TYPE_GESTION_PRAIRIE,lignes)) {
	        	//write "entete TYPE_EXPL présente";
	        	if ((colone at (lignes at TYPE_GESTION_PRAIRIE)) = "*") {
	        		if(itkParPrecedent){
						itkCourant.listGestionPrairieITK <- listNomGestionPrairie;
					} else {	
		        		ask sdcs{
				        	itkCourant.listGestionPrairieITK <- listNomGestionPrairie;
				        }
					}
	        	} else { // Ajout Renaud 180222
	        		if(itkParPrecedent){
						loop typeGestionPrairie over: ((colone at (lignes at TYPE_GESTION_PRAIRIE)) tokenize SEPARATEUR_ET) {
			       			itkCourant.listGestionPrairieITK <+ typeGestionPrairie;
			        	}
					}else{
						ask sdcs{
				        	loop typeGestionPrairie over: ((colone at (lignes at TYPE_GESTION_PRAIRIE)) tokenize SEPARATEUR_ET) {
				       			itkCourant.listGestionPrairieITK <+ typeGestionPrairie;
				        	}
				        }
				    }
	        	}
	        	
	        } else { // JV 240821: si entete existe pas: on affecte le type par défaut (chaine vide)
				ask sdcs{
					itkCourant.listGestionPrairieITK <+ "";
		        }
	        }

			 
	        // 5. Creation des stategies
	        if(itkCourant != nil){
	        	// 5.1 Stategie Travail du sol
	        	if(world.isEnteExite(IS_PREPA,lignes)){
	        		if((colone at (lignes at IS_PREPA)) contains "O"){
					    if !(plusieursTravauxDuSolParITK) { // Gestion travaux du sol multiple Renaud 18/03/2020
						    create strategieTravailSol {
								tc <- espece;
								//if(world.isEnteExite(IS_REPRISE_SOL,lignes)){			isRepriseSol <- ((colone at (lignes at IS_REPRISE_SOL)) contains "O") ? true : false;}
								if(world.isEnteExite(PREPA_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at PREPA_NB_SOUS_PERIODES));}
								if(world.isEnteExite(PREPA_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at PREPA_TEMPS));}						
								if(world.isEnteExite(PREPA_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
								if(world.isEnteExite(PREPA_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
								if(world.isEnteExite(PREPA_JOURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_JOURS_PLUIE)), mapEntree:mapNbJoursPluieObsCumulee);}
								if(world.isEnteExite(PREPA_HAUTEURS_PLUIE_MAX,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_HAUTEURS_PLUIE_MAX)), mapEntree:mapHauteurPluieObsCumuleeMax);}
								if(world.isEnteExite(PREPA_JOURS_P_MOINS_ETP_MOY,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_JOURS_P_MOINS_ETP_MOY)), mapEntree:mapNbJoursEtpCumule);}
								if(world.isEnteExite(PREPA_P_MOINS_ETP_MIN,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_P_MOINS_ETP_MIN)), mapEntree:mapEtpCumuleMax);}
								if(world.isEnteExite(PREPA_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}
								if(world.isEnteExite(PREPA_EFFET_RUs,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at PREPA_EFFET_RUs)), mapEntree:mapEffetRUs);}
								do initialisationStrategie();
						    	matITK <- itkCourant.matITK;
						    	itkCourant.strategieTravailSolITK <- self;
						    	
						    }
						    do ajout_jours_accelerateur("TRAVAIL_SOL", (colone at (lignes at PREPA_DEBUT)), (colone at (lignes at PREPA_FIN)));
					    } else {
						    create strategieTravailSol returns: strategieTravailSolCourante {
								itkCourant.strategieTravailSolITK <- self;
						    }

						// 5.2 Stratégies de travail du sol supplémentaires
							bool moreOT <- true;
							int n <- 1;
							loop while: moreOT { // Tant que des OT supplémentaire sont trouvées pour l'ITK en cours, on continue la boucle
								string str_nWsol <- ''; // Chaine de caractères à ajouter derrière les noms des règles de décision à chercher dans le tbl (ex : "_2")
								if (n > 1)  {
									str_nWsol <- '_' + n;
								}
								
								if (entetesLues contains (IS_PREPA + str_nWsol)) {
									if((colone at (lignes at (IS_PREPA + str_nWsol))) contains "O"){				        				
										// Création d'une opération de travail du sol multiple
										create strategieTravailSolMultiples returns: strategieMultipleCourante {
												strategieTravailSol_parent <- strategieTravailSolCourante[0];
												tc <- espece;
												if(world.isEnteExite(PREPA_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at (PREPA_NB_SOUS_PERIODES + str_nWsol)));}
												if(world.isEnteExite(PREPA_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at (PREPA_TEMPS + str_nWsol)));}						
												if(world.isEnteExite(PREPA_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_DEBUT + str_nWsol))), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
												if(world.isEnteExite(PREPA_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_FIN + str_nWsol))), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
												if(world.isEnteExite(PREPA_JOURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_JOURS_PLUIE + str_nWsol))), mapEntree:mapNbJoursPluieObsCumulee);}
												if(world.isEnteExite(PREPA_HAUTEURS_PLUIE_MAX,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_HAUTEURS_PLUIE_MAX + str_nWsol))), mapEntree:mapHauteurPluieObsCumuleeMax);}
												if(world.isEnteExite(PREPA_JOURS_P_MOINS_ETP_MOY,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_JOURS_P_MOINS_ETP_MOY + str_nWsol))), mapEntree:mapNbJoursEtpCumule);}
												if(world.isEnteExite(PREPA_P_MOINS_ETP_MIN,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_P_MOINS_ETP_MIN + str_nWsol))), mapEntree:mapEtpCumuleMax);}
												if(world.isEnteExite(PREPA_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_HUMIDITE_SOL_MAX + str_nWsol))), mapEntree:mapHumiditeSolMax);}
												if(world.isEnteExite(PREPA_EFFET_RUs,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at (PREPA_EFFET_RUs + str_nWsol))), mapEntree:mapEffetRUs);}
												matITK <- itkCourant.matITK;
							   				}
							   				
							   				add strategieMultipleCourante[0] to: strategieTravailSolCourante[0].mesStrategiesMultiples;
										n <- n + 1;
										do ajout_jours_accelerateur("TRAVAIL_SOL", (colone at (lignes at (PREPA_DEBUT + str_nWsol))), (colone at (lignes at (PREPA_FIN + str_nWsol))));
									} else {
										moreOT <- false;
									}
								} else {
									moreOT <- false;
								}
							} // loop while
		        		} // else plusieursTravauxDuSolParITK
	        		} // if IS_PREPA=O
			} // if IS_PREPA existe
	        	
	        	// 6. Stategie Semis
	        	if((colone at (lignes at IS_SEMIS)) contains "O"){
				    create strategieSemis{
						tc <- espece;
						if(world.isEnteExite(SEMIS_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at SEMIS_NB_SOUS_PERIODES));}
						if(world.isEnteExite(SEMIS_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at SEMIS_TEMPS));}						
						if(world.isEnteExite(SEMIS_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
						if(world.isEnteExite(SEMIS_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
						if(world.isEnteExite(SEMIS_JOURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_JOURS_PLUIE)), mapEntree:mapNbJoursPluieObsCumulee);}
						if(world.isEnteExite(SEMIS_HAUTEURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_HAUTEURS_PLUIE)), mapEntree:mapHauteurPluieObsCumuleeMax);}
						if(world.isEnteExite(SEMIS_JOURS_TMIN,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_JOURS_TMIN)), mapEntree:mapNbJoursTminMoyennee);}
						if(world.isEnteExite(SEMIS_TMIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_TMIN)), mapEntree:mapTminMoyennee);}
						if(world.isEnteExite(SEMIS_JOURS_TMOY,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_JOURS_TMOY)), mapEntree:mapNbJoursTmoy);}
						if(world.isEnteExite(SEMIS_TMOY,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_TMOY)), mapEntree:mapTmoy);}
						if(world.isEnteExite(SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES)), mapEntree:mapNbJoursAuMoinsPluiePrevuesCumuleeMin);}
						if(world.isEnteExite(SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES)), mapEntree:mapHauteurAuMoinsPluiePrevuesCumuleeMin);}
						if(world.isEnteExite(SEMIS_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}
						if(world.isEnteExite(SEMIS_EFFET_RUs,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at SEMIS_EFFET_RUs)), mapEntree:mapEffetRUs);}
						do initialisationStrategie();
						
				    	matITK <- itkCourant.matITK;
				    	itkCourant.strategieSemisITK <- self;
				    }
				    do ajout_jours_accelerateur("SEMIS", (colone at (lignes at SEMIS_DEBUT)), (colone at (lignes at SEMIS_FIN)));
	        	}
	        	// 7. Stategie Binage
	        	if(world.isEnteExite(IS_BINAGE_SOL,lignes)){
	        		if((colone at (lignes at IS_BINAGE_SOL)) contains "O"){
					    create strategieBinageSol{
							tc <- espece;
							if(world.isEnteExite(BINAGE_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at BINAGE_NB_SOUS_PERIODES));}
							if(world.isEnteExite(BINAGE_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at BINAGE_TEMPS));}						
							if(world.isEnteExite(BINAGE_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at BINAGE_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
							if(world.isEnteExite(BINAGE_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at BINAGE_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
							if(world.isEnteExite(BINAGE_EchV_MIN,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at BINAGE_EchV_MIN)), mapEntree:mapEchelleVegetationMin);}
							if(world.isEnteExite(BINAGE_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at BINAGE_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}
							if(world.isEnteExite(BINAGE_EFFET_RUs,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at BINAGE_EFFET_RUs)), mapEntree:mapEffetRUs);}
							do initialisationStrategie();
							
					    	matITK <- itkCourant.matITK;
					    	itkCourant.strategieBinageSolITK <- self;
					    }
						do ajout_jours_accelerateur("BINAGE", (colone at (lignes at BINAGE_DEBUT)), (colone at (lignes at BINAGE_FIN)));
		        	}
	        	}
	        	   
	        	// 8. Stategie irrigation
	        	if((colone at (lignes at IS_IRRIGATION)) contains "O"){
				    create strategieIrrigation{
						tc <- espece;						
						if(world.isEnteExite(IRRIGATION_NB_SOUS_PERIODES,lignes)){				nbSousPeriode <- int(colone at (lignes at IRRIGATION_NB_SOUS_PERIODES));}
//						if(world.isEnteExite(IRRIGATION_TEMPS,lignes)){							tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at IRRIGATION_TEMPS));}
						if(world.isEnteExite(IRRIGATION_DEBUT,lignes)){							do initialisationMapsFenetreTemporelle(donnees:(colone at (lignes at IRRIGATION_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
						if(world.isEnteExite(IRRIGATION_FIN,lignes)){							do initialisationMapsFenetreTemporelle(donnees:(colone at (lignes at IRRIGATION_FIN)), mapEntree:mapFenetresTemporellesFin);}
						if(world.isEnteExite(IRRIGATION_JOURS_PLUIE_CUMUL,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_JOURS_PLUIE_CUMUL)), mapEntree:mapNbJoursPluieObsCumulee);}
						if(world.isEnteExite(IRRIGATION_HAUTEUR_PLUIE_CUMUL_ANNULATION,lignes)){do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_HAUTEUR_PLUIE_CUMUL_ANNULATION)), mapEntree:mapHauteurPluieObsCumuleeMax);}						
						if(world.isEnteExite(IRRIGATION_JOURS_PLUIE_SIGNIF,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_JOURS_PLUIE_SIGNIF)), mapEntree:mapNbJoursPluieSignif);}				
						if(world.isEnteExite(IRRIGATION_HAUTEUR_PLUIE_SIGNIF_REPORT,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_HAUTEUR_PLUIE_SIGNIF_REPORT)), mapEntree:mapHauteurPluieSignifReport);}						
						if(world.isEnteExite(IRRIGATION_ECHV_DEBUT,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_ECHV_DEBUT)), mapEntree:mapFenetreEchvDebut);}
						if(world.isEnteExite(IRRIGATION_ECHV_FIN,lignes)){						do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_ECHV_FIN)), mapEntree:mapFenetreEchvFin);}
						if(world.isEnteExite(IRRIGATION_JOURS_P_MOINS_ETP,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_JOURS_P_MOINS_ETP)), mapEntree:mapNbJoursEtpCumule);}
						if(world.isEnteExite(IRRIGATION_P_MOINS_ETP,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_P_MOINS_ETP)), mapEntree:mapEtpCumuleMax);}
						if(world.isEnteExite(IRRIGATION_JOURS_PLUIE_PREVUES,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_JOURS_PLUIE_PREVUES)), mapEntree:mapNbJoursPluiePrevuesCumulee);}
						if(world.isEnteExite(IRRIGATION_HAUTEURS_PLUIE_PREVUES,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_HAUTEURS_PLUIE_PREVUES)), mapEntree:mapHauteurPluiePrevuesCumuleeMin);}
						if(world.isEnteExite(IRRIGATION_HUMIDITE_SOL_MAX,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}
						if(world.isEnteExite(IRRIGATION_DOSE,lignes)){							do initialisationMapsStrategies(donnees:(colone at (lignes at IRRIGATION_DOSE)), mapEntree:mapQuantiteEau);}
						if(world.isEnteExite(IRRIGATION_NB_JOUR_TOUR_EAU,lignes)){				periodeTourEau <- int(colone at (lignes at IRRIGATION_NB_JOUR_TOUR_EAU));}				
						if(world.isEnteExite(IRRIGATION_REPORT_MAX,lignes)){					reportMAX <- int(colone at (lignes at IRRIGATION_REPORT_MAX));}	
						if(world.isEnteExite(IRRIGATION_IS_THEORIQUE,lignes)){					if((colone at (lignes at IRRIGATION_IS_THEORIQUE)) contains "O" ){irrSurTauxSatisfaction <- true;} }	
						if(world.isEnteExite(IRRIGATION_SIRR1,lignes)){							sirr1 <- float(colone at (lignes at IRRIGATION_SIRR1));}
						if(world.isEnteExite(IRRIGATION_SIRR2,lignes)){							sirr2 <- float(colone at (lignes at IRRIGATION_SIRR2));}
						if(world.isEnteExite(IRRIGATION_SIRR3,lignes)){							sirr3 <- float(colone at (lignes at IRRIGATION_SIRR3));}
						idGRP <- itkCourant.name;
						if(world.isEnteExite(IRRIGATION_GROUPE,lignes)){						idGRP <- colone at (lignes at IRRIGATION_GROUPE);}
						//
						do initialisationStrategie();
						
						matITK <- itkCourant.matITK;
						tempsDexecution <- matITK.surfaceIrrigableParJour;
				    	itkCourant.strategieIrrigationITK <- self;
				    	ask sdcs{
				    		parcelleIrrigableSdC <- true;
				    	}				    	
				    }
					do ajout_jours_accelerateur("IRRIGATION", (colone at (lignes at IRRIGATION_DEBUT)), (colone at (lignes at IRRIGATION_FIN)));
	        	}	        	
	        	// 9. Stategie recolte
	        	if((colone at (lignes at IS_RECOLTE)) contains "O"){
				    create strategieRecolte{
						tc <- espece;
						if(world.isEnteExite(RECOLTE_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at RECOLTE_NB_SOUS_PERIODES));}
						if(world.isEnteExite(RECOLTE_TEMPS,lignes)){			tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at RECOLTE_TEMPS));}
						if(world.isEnteExite(RECOLTE_DEBUT,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
						if(world.isEnteExite(RECOLTE_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_FIN)), mapEntree:mapFenetresTemporellesFin);}
						if(world.isEnteExite(RECOLTE_JOURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_JOURS_PLUIE)), mapEntree:mapNbJoursPluieObsCumulee);}
						if(world.isEnteExite(RECOLTE_HAUTEURS_PLUIE,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_HAUTEURS_PLUIE)), mapEntree:mapHauteurPluieObsCumuleeMax);}
						if(world.isEnteExite(RECOLTE_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}				
						if(world.isEnteExite(RECOLTE_EFFET_RUs,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_EFFET_RUs)), mapEntree:mapEffetRUs);}
						if(world.isEnteExite(RECOLTE_ECHV_MIN,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at RECOLTE_ECHV_MIN)), mapEntree:mapEchelleVegetationMin);}
						do initialisationStrategie();
				    	
				    	matITK <- itkCourant.matITK;
				    	itkCourant.strategieRecolteITK <- self;
				    }
				    if (espece.idEspeceCultivee != "gel") {
				    	do ajout_jours_accelerateur("RECOLTE", (colone at (lignes at RECOLTE_DEBUT)), (colone at (lignes at RECOLTE_FIN)));
				    }
				    
				    // Erreur si prairiep récoltée Renaud 301023 -> pas de récolte pour les prairies permanentes
//					if (espece.idEspeceCultivee = "prairiep" or nomChoixModeleCroissancePrairie = "HerbSim" or nomChoixModeleCroissancePrairie = "HerbSimNC") {
//						do raiseError("L'itk '" + itkCourant.idITK +"' comporte une opération de récolte pour une espèce 'prairiep'. Or, l'espèce 'prairiep' (prairie permanente) ne peut pas être récoltée.");
//					}
	        	}
	        	// 10. Reprise travail du sol 
	        	if(world.isEnteExite(IS_REPRISE_SOL,lignes)){
	        		if((colone at (lignes at IS_REPRISE_SOL)) contains "O"){
					    create strategieRepriseTravailSol{
							tc <- espece;
							if(world.isEnteExite(REPRISE_NB_SOUS_PERIODES,lignes)){		nbSousPeriode <- int(colone at (lignes at REPRISE_NB_SOUS_PERIODES));}
							if(world.isEnteExite(REPRISE_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at REPRISE_TEMPS));}						
							if(world.isEnteExite(REPRISE_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
							if(world.isEnteExite(REPRISE_FIN,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
							if(world.isEnteExite(REPRISE_JOURS_PLUIE,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_JOURS_PLUIE)), mapEntree:mapNbJoursPluieObsCumulee);}
							if(world.isEnteExite(REPRISE_HAUTEURS_PLUIE_MAX,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_HAUTEURS_PLUIE_MAX)), mapEntree:mapHauteurPluieObsCumuleeMax);}
							if(world.isEnteExite(REPRISE_JOURS_P_MOINS_ETP_MOY,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_JOURS_P_MOINS_ETP_MOY)), mapEntree:mapNbJoursEtpCumule);}
							if(world.isEnteExite(REPRISE_P_MOINS_ETP_MIN,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_P_MOINS_ETP_MIN)), mapEntree:mapEtpCumuleMax);}
							if(world.isEnteExite(REPRISE_HUMIDITE_SOL_MAX,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_HUMIDITE_SOL_MAX)), mapEntree:mapHumiditeSolMax);}
							if(world.isEnteExite(REPRISE_EFFET_RUs,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at REPRISE_EFFET_RUs)), mapEntree:mapEffetRUs);}
							do initialisationStrategie();
					    	
					    	matITK <- itkCourant.matITK;
					    	itkCourant.strategieRepriseTravailSolITK <- self;
					    }
					    do ajout_jours_accelerateur("REPRISE", (colone at (lignes at REPRISE_DEBUT)), (colone at (lignes at REPRISE_FIN)));
		        	}
	        	}
	        	
	        	// 11. Travail Phyto
	        	if(world.isEnteExite(IS_PHYTO,lignes)){
	        		if((colone at (lignes at IS_PHYTO)) contains "O"){
					    if !(plusieursTraitementsPhytoParITK) { // Gestion travaux du sol multiple Renaud 18/03/2020
						    create strategiePhyto{
								tc <- espece;
								if(world.isEnteExite(PHYTO_NB_SOUS_PERIODES,lignes)){		nbSousPeriode <- int(colone at (lignes at PHYTO_NB_SOUS_PERIODES));}
								if(world.isEnteExite(PHYTO_TEMPS,lignes)){					tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at PHYTO_TEMPS));}						
								if(world.isEnteExite(PHYTO_DEBUT,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
								if(world.isEnteExite(PHYTO_FIN,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
								if(world.isEnteExite(PHYTO_DOSE_HA,lignes)){				doseParHectare <- float(colone at (lignes at PHYTO_DOSE_HA));}
								if(world.isEnteExite(PHYTO_DOSE_UNITE,lignes)){				unite_dose <- string(colone at (lignes at PHYTO_DOSE_UNITE));}
								if(world.isEnteExite(PHYTO_TYPE,lignes)){					type_phyto <- string(colone at (lignes at PHYTO_TYPE));}
								if(world.isEnteExite(PHYTO_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_JOURS_PLUIE_OBS)), mapEntree:mapNbJoursPluieObsCumulee);}
								if(world.isEnteExite(PHYTO_HAUTEURS_PLUIE_OBS_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_HAUTEURS_PLUIE_OBS_MIN)), mapEntree:mapHauteurPluieObsCumuleeMax);}
								if(world.isEnteExite(PHYTO_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_JOURS_PLUIE_OBS)), mapEntree:mapNbJoursPluiePrevues);}
								if(world.isEnteExite(PHYTO_HAUTEURS_PLUIE_OBS_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PHYTO_HAUTEURS_PLUIE_OBS_MIN)), mapEntree:mapHauteurPluiePrevuesMin);}
								
								do initialisationStrategie();
						    	
						    	matITK <- itkCourant.matITK;
						    	itkCourant.strategiePhytoITK <- self;
						    }
					    	do ajout_jours_accelerateur("PHYTO", (colone at (lignes at PHYTO_DEBUT)), (colone at (lignes at PHYTO_FIN)));
					    } else {
						    create strategiePhyto returns: strategiePhytoCourante {
								itkCourant.strategiePhytoITK <- self;
						    }

						// 5.2 Stratégies phyto supplémentaires
							bool moreOT <- true;
							int n <- 1;
							loop while: moreOT { // Tant que des OT supplémentaire sont trouvées pour l'ITK en cours, on continue la boucle
								string str_nPhyto <- ''; // Chaine de caractères à ajouter derrière les noms des règles de décision à chercher dans le tbl (ex : "_2")
								if (n > 1)  {
									str_nPhyto <- '_' + n;
								}
								
								if (entetesLues contains (IS_PHYTO + str_nPhyto)) {
									if((colone at (lignes at (IS_PHYTO + str_nPhyto))) contains "O"){				        				
										// Création d'une opération phyto multiple
										create strategiePhytoMultiples returns: strategieMultipleCourante {
												strategiePhyto_parent <- strategiePhytoCourante[0];
												tc <- espece;
												if(world.isEnteExite(PHYTO_NB_SOUS_PERIODES,lignes)){		nbSousPeriode <- int(colone at (lignes at (PHYTO_NB_SOUS_PERIODES + str_nPhyto)));}
												if(world.isEnteExite(PHYTO_TEMPS,lignes)){					tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at (PHYTO_TEMPS + str_nPhyto)));}					
												if(world.isEnteExite(PHYTO_DEBUT,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_DEBUT + str_nPhyto))), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
												if(world.isEnteExite(PHYTO_FIN,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_FIN + str_nPhyto))), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
												if(world.isEnteExite(PHYTO_DOSE_HA,lignes)){				doseParHectare <- float(colone at (lignes at (PHYTO_DOSE_HA + str_nPhyto)));}
												if(world.isEnteExite(PHYTO_TYPE,lignes)){					type_phyto <- string(colone at (lignes at (PHYTO_TYPE + str_nPhyto)));}
												if(world.isEnteExite(PHYTO_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_JOURS_PLUIE_OBS + str_nPhyto))), mapEntree:mapNbJoursPluieObsCumulee);}
												if(world.isEnteExite(PHYTO_HAUTEURS_PLUIE_OBS_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_HAUTEURS_PLUIE_OBS_MIN + str_nPhyto))), mapEntree:mapHauteurPluieObsCumuleeMax);}
												if(world.isEnteExite(PHYTO_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_JOURS_PLUIE_OBS + str_nPhyto))), mapEntree:mapNbJoursPluiePrevues);}
												if(world.isEnteExite(PHYTO_HAUTEURS_PLUIE_OBS_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PHYTO_HAUTEURS_PLUIE_OBS_MIN + str_nPhyto))), mapEntree:mapHauteurPluiePrevuesMin);}
												
												matITK <- itkCourant.matITK;
							   				}
							   				
							   				add strategieMultipleCourante[0] to: strategiePhytoCourante[0].mesStrategiesMultiples;
										n <- n + 1;
										do ajout_jours_accelerateur("PHYTO", (colone at (lignes at (PHYTO_DEBUT + str_nPhyto))), (colone at (lignes at (PHYTO_FIN + str_nPhyto))));
									} else {
										moreOT <- false;
									}
								} else {
									moreOT <- false;
								}
							} // loop while
		        		}
		        	}
	        	}
	        	
	        	
	        	// 12. Travail Ferti
	        	if(world.isEnteExite(IS_FERTI,lignes)){
	        		if((colone at (lignes at IS_FERTI)) contains "O"){
					    create strategieFerti{
							tc <- espece;
							if(world.isEnteExite(FERTI_NB_SOUS_PERIODES,lignes)){		nbSousPeriode <- int(colone at (lignes at FERTI_NB_SOUS_PERIODES));}
							if(world.isEnteExite(FERTI_TEMPS,lignes)){					tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at FERTI_TEMPS));}						
							if(world.isEnteExite(FERTI_DEBUT,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_DEBUT)), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
							if(world.isEnteExite(FERTI_FIN,lignes)){					do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_FIN)), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
							if(world.isEnteExite(FERTI_DOSE_HA,lignes)){				doseParHectare <- float(colone at (lignes at FERTI_DOSE_HA));}
							if(world.isEnteExite(FERTI_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_JOURS_PLUIE_OBS)), mapEntree:mapNbJoursPluieObsCumulee);}
							if(world.isEnteExite(FERTI_HAUTEURS_PLUIE_OBS_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_HAUTEURS_PLUIE_OBS_MIN)), mapEntree:mapHauteurPluieObsCumuleeMax);}
							if(world.isEnteExite(FERTI_ECHV_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_ECHV_DEBUT)), mapEntree:mapFenetreEchvDebut);}
							if(world.isEnteExite(FERTI_ECHV_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at FERTI_ECHV_FIN)), mapEntree:mapFenetreEchvFin);}
							
							do initialisationStrategie();
					    	
					    	matITK <- itkCourant.matITK;
					    	itkCourant.strategieFertiITK <- self;
					    }
					    do ajout_jours_accelerateur("FERTI", (colone at (lignes at FERTI_DEBUT)), (colone at (lignes at FERTI_FIN)));
		        	} else if (plusieursFertilisationsParITK) { // Création d'alternatives de fertiliation et d'apports
	        			if (nom_itk_ferti contains itkCourant.idITK) { // Est-ce que l'itk existe dans le fichier rdd_fertilisation ?
	        				if(world.isEnteExite(IS_CORPEN,lignes)){itkCourant.optimisation_corpen <- (colone at (lignes at IS_CORPEN)) contains "O" ? true : false;}
//	        				 write "---------";
//	        				 write "-ITKFERTi- Construction ITK FERTILISATION de --> " + itkCourant.idITK;
	        				// Création de la stratégie fertilisation générale
	        				create strategieFerti returns: strategieFertiCourante {
	        					itkCourant.strategieFertiITK <- self;
	        				}
	        				itkCourant.contientStrategiesFerti <- true;
	        				
	        				// Création des alternatives de fertilisation et des apports
	        				list<string> alternatives_ajoutees <- nil;
	        				loop j from: 2 to: ( nbColones_ferti - 1 ) { // Boucle sur les colonnes du fichier rdd ferti
	        					list<string> colone_ferti <- (initSystemeDeCulture_ferti column_at j) as list<string>;
	        					
	        					string nom_alternative_courante <- string(colone_ferti at (lignes_ferti at "FERTIALT_NOM_ALTERNATIVE"));
	        					if (nom_itk_ferti[j] = itkCourant.idITK) { // Si l'itk ferti correspond à l'itk courant
			        				// Création des alternatives de fertilisation (lorsqu'elle n'existe pas)
			        				if (!(alternatives_ajoutees contains nom_alternative_courante)) {
				        				create strategieFertiAlternative returns: alternative_courante {
				        					nom_alternative <- nom_alternative_courante;
											ordre_alternative <- int(colone_ferti at (lignes_ferti at "FERTIALT_ORDRE_ALTERNATIVE"));
											alternatives_ajoutees <+ nom_alternative_courante;
//											write "-ITKFERTi- Nom alternative --> " + nom_alternative + " ------ Ordre alternative --> " + ordre_alternative;
//											write "-ITKFERTi- ordre alternative --> " + ordre_alternative;
				        				}
				        				itkCourant.strategieFertiITK.mesStrategiesFertiAlternative <+ alternative_courante[0];
										//write "-ITKFERTi- Liste alternatives --> " + itkCourant.strategieFertiITK.mesStrategiesFertiAlternative;	        					
			        				}

			        				// Création des apports (chaque colonne correspondant à un apport)
			        				strategieFertiAlternative maSrategieAlternative <- first(itkCourant.strategieFertiITK.mesStrategiesFertiAlternative where (each.nom_alternative = nom_alternative_courante));
			        				create strategieFertiApport {
			        					// Affectation des apports à une stratégie alternative
			        					maSrategieAlternative.mesApports <+ self;
			        					// Caractéristiques générales de l'apport
			        					nbSousPeriode <- int(colone_ferti at (lignes_ferti at FERTIALT_N_SOUS_PERIODES));
			        					tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone_ferti at (lignes_ferti at FERTIALT_TPS_TRAVAIL));
			        					doseParHectare <- float(colone_ferti at (lignes_ferti at FERTIALT_DOSE));
			        					dosePParHectare <- float(colone_ferti at (lignes_ferti at FERTIALT_DOSE_P));
			        					doseKParHectare <- float(colone_ferti at (lignes_ferti at FERTIALT_DOSE_K));
			        					nom_produit <- string(colone_ferti at (lignes_ferti at FERTIALT_NOM_PRODUIT));
										agriw <- bool(colone_ferti at (lignes_ferti at FERTIALT_AGRIW));
										outil <- string(colone_ferti at (lignes_ferti at FERTIALT_OUTIL));
										n_passages <- int(colone_ferti at (lignes_ferti at FERTIALT_N_PASSAGES));
										ordre_apport <- int(colone_ferti at (lignes_ferti at FERTIALT_ORDRE_APPORT));
			        					// Caractéristiques des sous-périodes de l'apport
			        					// TODO ajouter la vérification que la contrainte existe dans le fichier rdd_ferti (renaud 161023)
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_DEBUT)), mapEntree:mapFenetresTemporellesDebut);
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_FIN)), mapEntree:mapFenetresTemporellesFin);
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_N_J_CUMUL_PLUIE)), mapEntree:mapNbJoursPluieObsCumulee);
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_CUMUL_PLUIE)), mapEntree:mapHauteurPluieObsCumuleeMax);
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_HUM_MAX_SOL)), mapEntree:mapHumiditeSolMax);
			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_SEUIL_VEGE)), mapEntree:mapEchelleVegetationMin);
//			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_N_J_CUMUL_PLUIE_PREVUE)), mapEntree:mapNbJoursPluiePrevues);
//			        					do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_CUMUL_PLUIE_PREVUE)), mapEntree:mapHauteurPluiePrevuesMin);
										do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_PROF_WSOL)), mapEntree:mapEffetRUs);
										do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_NJ_AU_MOINS_CUMUL_PLUIES_PREVUES)), mapEntree:mapNbJoursAuMoinsPluiePrevuesCumuleeMin);
										do initialisationMapsStrategies(donnees:(colone_ferti at (lignes_ferti at FERTIALT_HAUTEUR_AU_MOINS_CUMUL_PLUIES_PREVUES)), mapEntree:mapHauteurAuMoinsPluiePrevuesCumuleeMin);			        					
										do initialisationStrategie();
										
//										write 'Apport n° ' + ordre_apport + " - dose = " + doseParHectare;
										
										if (ordre_apport = 1) { // Si c'est le premier apport, on garde la date en mémoire dans la stratégie 
			        						maSrategieAlternative.jourChoixStrategie <- dateCour.soustractionDate(mapFenetresTemporellesDebut[0], 15); // 15 -> le choix de la strategie est effectué 15j avant le premier apport
			        					}
									
					    				matITK <- itkCourant.matITK;
			        				}
								    do ajout_jours_accelerateur("FERTI", (colone_ferti at (lignes_ferti at FERTIALT_DEBUT)), (colone_ferti at (lignes_ferti at FERTIALT_FIN)));
	        					}
	        				}
	        			} else { // Pas de stratégie de ferti disponible pour l'ITK en cours
	        				do raiseWarning("Pas de stratégie de ferti disponible pour l'ITK " + itkCourant.idITK);
	        			}
	        			
						// Si adaptation ferti par corpen --> on on parcourt les alternatives de ferti pour trouver le premier apport minéral (si il y en a un) et pour enregistrer la valeur du N minéral total des autres apports
						if (adaptationFertilisation = 'corpen') {
							if (itkCourant.strategieFertiITK != nil) {
								loop alt_ferti_courante over: itkCourant.strategieFertiITK.mesStrategiesFertiAlternative {
									
									int n_apports <- length(alt_ferti_courante.mesApports);
									bool premier_apport_min_trouve <- false;
									//write "strat = " + alt_ferti_courante + " -- nombre d'apports = " + n_apports;
									loop k from: 1 to: n_apports {
										// Si le premier apport min n'a pa été trouvé et que l'apport en question est minéral
										strategieFertiApport apport_courant <- alt_ferti_courante.mesApports first_with(each.ordre_apport = k);
										Engrais produit_apport <- Engrais first_with (each.nomEngrais = apport_courant.nom_produit);
										if (!premier_apport_min_trouve and produit_apport.Fertilizer_type = 'mineral' and !(["P", "K", "PK"] contains produit_apport.nomEngrais)) {
											(alt_ferti_courante.mesApports first_with(each.ordre_apport = k)).premier_apport_mineral <- true;
											premier_apport_min_trouve <- true;
											//write "Premier apport mineral --> " + apport_courant.nom_produit + " (dose = " + apport_courant.doseParHectare + ")";
										} else if (premier_apport_min_trouve and produit_apport.Fertilizer_type = 'mineral') {
											alt_ferti_courante.apport_Nmin_total_sans1erApport <- alt_ferti_courante.apport_Nmin_total_sans1erApport + apport_courant.doseParHectare;
											//write "Cumul apports suivants --> " + alt_ferti_courante.apport_Nmin_total_sans1erApport;
										}
									}
								}
							}
						}
	        			
	        		} // else if (plusieursFertilisationsParITK)

	        	} // if IS_FERTI existe

	        	// 13. Fauche des prairies
	        	if(world.isEnteExite(IS_FAUCHE,lignes)){
	        		if((colone at (lignes at IS_FAUCHE)) contains "O"){
					    create strategieFauche returns: strategieFaucheCourante {
							itkCourant.strategieFaucheITK <- self;
					    }

					// Stratégies de fauche supplémentaires
						bool moreOT <- true;
						int n <- 1;
						loop while: moreOT { // Tant que des OT supplémentaire sont trouvées pour l'ITK en cours, on continue la boucle
							string str_nFauche <- ''; // Chaine de caractères à ajouter derrière les noms des règles de décision à chercher dans le tbl (ex : "_2")
							if (n > 1)  {
								str_nFauche <- '_' + n;
							}
							
							if (entetesLues contains (IS_FAUCHE + str_nFauche)) {
								if((colone at (lignes at (IS_FAUCHE + str_nFauche))) contains "O"){		
									create strategieFaucheMultiples returns: strategieMultipleCourante {
										strategieFauche_parent <- strategieFaucheCourante[0];
										tc <- espece;
										if(world.isEnteExite(FAUCHE_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at (FAUCHE_NB_SOUS_PERIODES + str_nFauche)));}
										if(world.isEnteExite(FAUCHE_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at (FAUCHE_TEMPS + str_nFauche)));}						
										if(world.isEnteExite(FAUCHE_DEBUT,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_DEBUT + str_nFauche))), mapEntree:mapFenetresTemporellesDebut);} // TODO : pb de cast ??
										if(world.isEnteExite(FAUCHE_FIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_FIN + str_nFauche))), mapEntree:mapFenetresTemporellesFin);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_JOURS_PLUIE,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_JOURS_PLUIE + str_nFauche))), mapEntree:mapNbJoursPluieObsCumulee);}
										if(world.isEnteExite(FAUCHE_HAUTEURS_PLUIE_MAX,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_HAUTEURS_PLUIE_MAX + str_nFauche))), mapEntree:mapHauteurPluieObsCumuleeMax);}
										// if(world.isEnteExite(FAUCHE_JOURS_PLUIE_PREVUES,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at FAUCHE_JOURS_PLUIE_PREVUES)), mapEntree:mapNbJoursPluiePrevuesCumulee);}
										// if(world.isEnteExite(FAUCHE_HAUTEURS_PLUIE_PREVUES,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at FAUCHE_HAUTEURS_PLUIE_PREVUES)), mapEntree:mapHauteurPluiePrevuesCumuleeMin);}
										if(world.isEnteExite(FAUCHE_DELAI_COUPE,lignes)){				delaiCoupe <- int(colone at (lignes at (FAUCHE_DELAI_COUPE + str_nFauche)));}	 // TODO : pb de cast ??	
										if(world.isEnteExite(FAUCHE_HAUTEUR_COUPE,lignes)){				hauteurCoupe <- float(colone at (lignes at (FAUCHE_HAUTEUR_COUPE + str_nFauche)));}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_VOLUME,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_VOLUME + str_nFauche))), mapEntree:mapVolumeHerbe);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_TMIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_TMIN + str_nFauche))), mapEntree:mapTminMoyennee);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_JOURS_TMIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_JOURS_TMIN + str_nFauche))), mapEntree:mapNbJoursTminMoyennee);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_HAUTEUR_MIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_HAUTEUR_MIN + str_nFauche))), mapEntree:mapHauteurHerbeMin);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_QUANTITE_BIOMASSE_MIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_QUANTITE_BIOMASSE_MIN + str_nFauche))), mapEntree:mapQuantiteBiomasseMin);}	 // TODO : pb de cast ??					
										if(world.isEnteExite(FAUCHE_DIGESTABILITE_MIN,lignes)){				do initialisationMapsStrategies(donnees:(colone at (lignes at (FAUCHE_DIGESTABILITE_MIN + str_nFauche))), mapEntree:mapDigestabiliteMin);}	 // TODO : pb de cast ??					
										matITK <- itkCourant.matITK;
					   				}
						   				
						   			add strategieMultipleCourante[0] to: strategieFaucheCourante[0].mesStrategiesMultiples;
									n <- n + 1;
									do ajout_jours_accelerateur("FAUCHE", (colone at (lignes at (FAUCHE_DEBUT + str_nFauche))), (colone at (lignes at (FAUCHE_FIN + str_nFauche))));
								
									// Erreur si Fauche alors que AqYield est activé
									if (nomChoixModeleCroissancePrairie = "AqYield" or nomChoixModeleCroissancePrairie = "AqYieldNC") {
										do raiseError("L'itk '" + itkCourant.idITK +"' comporte une opération de fauche alors que " + nomChoixModeleCroissancePrairie + " est activé pour simuler la croissance des prairies. Veuillez désactiver les fauches dans le fichier regleDeDecisions.csv ou activer Herbsim dans le launcher.");
									}
								} else {
									moreOT <- false;
								}
							} else {
								moreOT <- false;
							}
						} // loop while
	        		} // if IS_PREPA=O
			} // if IS_PREPA existe

        	// 14. Pature des prairies (si module élevage activé)
        	if(executerModelePaturage and world.isEnteExite(IS_PATURE,lignes)){
        		if((colone at (lignes at IS_PATURE)) contains "O"){
					create strategiePature returns: strategiePatureCourante {
						itkCourant.strategiePatureITK <- self;
					}
					
					// Stratégies de Pature supplémentaires
					bool moreOT <- true;
					int n <- 1;
					loop while: moreOT { // Tant que des OT supplémentaire sont trouvées pour l'ITK en cours, on continue la boucle
						string str_nPature <- ''; // Chaine de caractères à ajouter derrière les noms des règles de décision à chercher dans le tbl (ex : "_2")
						if (n > 1)  {
							str_nPature <- '_' + n;
						}	    
					    
						if (entetesLues contains (IS_PATURE + str_nPature)) {
							if((colone at (lignes at (IS_PATURE + str_nPature))) contains "O"){		
								create strategiePatureMultiples returns: strategieMultipleCourante {
									strategiePature_parent <- strategiePatureCourante[0];					    
									tc <- espece;
									if(world.isEnteExite(PATURE_TEMPS,lignes)){				tempsDexecution <- nombreMeterCarreDansUnHectare * float(colone at (lignes at (PATURE_TEMPS + str_nPature)));}
									if(world.isEnteExite(PATURE_TEMPS_PATURE,lignes)){		tempsPature <- int(colone at (lignes at (PATURE_TEMPS_PATURE + str_nPature)));}
									if(world.isEnteExite(PATURE_TEMPS_REPOS,lignes)){		tempsReposParcelle <- int(colone at (lignes at (PATURE_TEMPS_REPOS + str_nPature)));}
										if(world.isEnteExite(PATURE_NB_SOUS_PERIODES,lignes)){	nbSousPeriode <- int(colone at (lignes at (PATURE_NB_SOUS_PERIODES + str_nPature)));}
									if(world.isEnteExite(PATURE_COEF_HERBE_ACCESSIBLE,lignes)){	coefHerbeAccessible <- float(colone at (lignes at (PATURE_COEF_HERBE_ACCESSIBLE + str_nPature)));}
									
									if(world.isEnteExite(PATURE_DEBUT,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_DEBUT + str_nPature))), mapEntree:mapFenetresTemporellesDebut);}
									if(world.isEnteExite(PATURE_FIN,lignes)){			do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_FIN + str_nPature))), mapEntree:mapFenetresTemporellesFin);}
									
									if(world.isEnteExite(PATURE_SI_FAUCHE_BIOMASSE,lignes)){	SeuilBiomasseLimiteSiFauche <- float(colone at (lignes at (PATURE_SI_FAUCHE_BIOMASSE + str_nPature)));}
									if(world.isEnteExite(PATURE_HAUTEUR_HERBE_ENTREE,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_HAUTEUR_HERBE_ENTREE + str_nPature))), mapEntree:mapFenetresTemporellesHauteurHerbeMinEntree);}//HauteurHerbeMinEntree <- float(colone at (lignes at PATURE_HAUTEUR_HERBE_ENTREE));}
									if(world.isEnteExite(PATURE_HAUTEUR_HERBE_SORTIE,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_HAUTEUR_HERBE_SORTIE + str_nPature))), mapEntree:mapFenetresTemporellesHauteurHerbeMaxSortie);}//HauteurHerbeMinEntree <- float(colone at (lignes at PATURE_HAUTEUR_HERBE_ENTREE));}
									if(world.isEnteExite(PATURE_VOLUME_MIN,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_VOLUME_MIN + str_nPature))), mapEntree:mapFenetresTemporellesPatureVolumeMin);}//HauteurHerbeMinEntree <- float(colone at (lignes at PATURE_HAUTEUR_HERBE_ENTREE));}
									if(world.isEnteExite(PATURE_DIGESTABILITE_MIN,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_DIGESTABILITE_MIN + str_nPature))), mapEntree:mapFenetresTemporellesPatureDigestabiliteMin);}
									if(world.isEnteExite(PATURE_HUMIDITE_SOL_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_HUMIDITE_SOL_MAX + str_nPature))), mapEntree:mapHumiditeSolMax);}
									if(world.isEnteExite(PATURE_SOMME_DEGRESJ,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at (PATURE_SOMME_DEGRESJ + str_nPature))), mapEntree:mapFenetresTemporellesPatureSommeDegresJ);}
									if(world.isEnteExite(PATURE_JOURS_PLUIE_OBS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PATURE_JOURS_PLUIE_OBS)), mapEntree:mapNbJoursPluieObsCumulee);}
									if(world.isEnteExite(PATURE_HAUTEURS_PLUIE_OBS_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PATURE_HAUTEURS_PLUIE_OBS_MAX)), mapEntree:mapHauteurPluieObsCumuleeMax);}
									if(world.isEnteExite(PATURE_JOURS_PLUIE_PREVUS,lignes)){		do initialisationMapsStrategies(donnees:(colone at (lignes at PATURE_JOURS_PLUIE_PREVUS)), mapEntree:mapNbJoursPluiePrevues);}
									if(world.isEnteExite(PATURE_HAUTEURS_PLUIE_PREVUES_MAX,lignes)){	do initialisationMapsStrategies(donnees:(colone at (lignes at PATURE_HAUTEURS_PLUIE_PREVUES_MAX)), mapEntree:mapHauteurPluiePrevuesMax);}
									do initialisationStrategie();
									matITK <- itkCourant.matITK;
									
									// Détection du mode de gestion des prairies (doit être toujours le même)
									string mode_gestion_detecte;
									if ((mapFenetresTemporellesPatureVolumeMin[0] != -888) and (mapFenetresTemporellesHauteurHerbeMinEntree[0] = -888 and mapFenetresTemporellesHauteurHerbeMaxSortie[0] = -888)) {
										mode_gestion_detecte <- "quantiteBiomasse";
									} else if (mapFenetresTemporellesPatureVolumeMin[0] = -888 and (mapFenetresTemporellesHauteurHerbeMinEntree[0] != -888 or mapFenetresTemporellesHauteurHerbeMaxSortie[0] != -888)) {
										mode_gestion_detecte <- "hauteurHerbe";
									} else {
										ask myself {
											do raiseError("Les opérations de pature doivent être gérée par des contraintes de hauteur d'herbe OU de quantité de biomasse. Or, dans le cas présent:
															\n  - PATURE_VOLUME_MIN = " + myself.mapFenetresTemporellesPatureVolumeMin
															+ "\n  - PATURE_HAUTEUR_HERBE_ENTREE = " + myself.mapFenetresTemporellesHauteurHerbeMinEntree
															+ "\n  - PATURE_HAUTEUR_HERBE_SORTIE = " + myself.mapFenetresTemporellesHauteurHerbeMaxSortie
															);
														
										}
									}
									
									if (modeGestionprairie = nil) {
										modeGestionprairie <- mode_gestion_detecte;
									} else {
										if (modeGestionprairie != mode_gestion_detecte) {
											ask myself {
												do raiseError("Les opérations de fauche et de pature doivent être gérées par des contraintes de hauteur d'herbe OU de quantité de biomasse. Or, dans le cas présent deux opérations (fauche ou pature) sont gérées différement");
											}
										}
									}
								}
								
								add strategieMultipleCourante[0] to: strategiePatureCourante[0].mesStrategiesMultiples;
//								write "strategiePatureCourante[0].mesStrategiesMultiples -> " + strategiePatureCourante[0].mesStrategiesMultiples;
								n <- n + 1;
								do ajout_jours_accelerateur("PATURE", (colone at (lignes at (PATURE_DEBUT + str_nPature))), (colone at (lignes at (PATURE_FIN + str_nPature))));
							} else {
								moreOT <- false;
							}
						} else {
							moreOT <- false;
						}
						
//					    write "OT pature créée --> " + itkCourant.strategiePatureITK;
//					    write "fenetre début = " + fenetre_debut;
//					    write "fenetre fin = " + fenetre_fin;
//						write "HauteurHerbeMinEntree = " + HauteurHerbeMinEntree + " | HauteurHerbeMaxSortie = " + HauteurHerbeMaxSortie + " | mapHumiditeSolMax = " + mapHumiditeSolMax + " | mapDegresJMin = " + mapDegresJMin;
				    }
	        	}
        	}

	        	// JV 020420 on détermine si la récolte est la même année que le semis à partir des fenêtres temporelles de semis et recolte, voir mantis 0002510
	        	ask(itkCourant){
	        		do setSemisAnneeNrecolteAnneeNplusUn();
	        		do setIsCultureSup365();  // ex: colza cf Mantis #2905
	        		// JV debug test ci-dessous permet de tester si SdC cohérent
	        		if(semisAnneeNrecolteAnneeNplusUn!=isCultureHiver){
	        			
	        			// JV 231121 peut être normal si la culture n'est pas récoltée (prairie)
	        			if strategieRecolteITK!=nil {		        			
		        			string ch <- "ITK " + idITK + " incohérence entre dates semis/récolte et booléen isCultureHiver du fichier ITK\n\t\tsemisAnneeNrecolteAnneeNplusUn=" + semisAnneeNrecolteAnneeNplusUn + " car dernier jour récolte=" + strategieRecolteITK.getJourJulienFinMax(0) + " et premier jour semis=" + strategieSemisITK.getJourJulienDebutMin(0);
							ch <- ch + "\n\t\talors que isCultureHiver=" + isCultureHiver;
							ch <- ch + "\n\t\tjuste pour info car le booléen isCultureHiver du fichier ITK n'est plus utilisé";
		        			write "\t\u2757 WARNING " + ch color:#orange;
							initLogWarning <- initLogWarning + "- " + ch + "\n";	        			
		        			//write "µµµµµµµµµµµµµ pb ITK " + idITK + " semisAnneeNrecolteAnneeNplusUn=" +  semisAnneeNrecolteAnneeNplusUn + " isCultureHiver=" + isCultureHiver; // JV debug
		        			//write "\tR1="+strategieRecolteITK.getJourJulienFinMax(0)+ " S0=" + strategieSemisITK.getJourJulienDebutMin(0);
		        			isCultureHiver<-semisAnneeNrecolteAnneeNplusUn;
		        		}		        			
	        		}	        		
	        		
	        		if(espece.idEspeceCultivee="gel"){ // JV 200920 fenetres semis et recolte forcees a [1,365] pour le gel, cf Mantis 0002670
	        			do forceFenetresSemisRecolteITKGel();
	        		}
	        	}      	
	        }   // if(itkCourant!=nil)  			
		} // boucle colonnes
		//write  getInfoListITK();
	 	//write "********** fin lectureFichierReglesDeDecisions **********";
		
	}	
	
	bool isEnteExite{
		arg enteteEntree type: string;
		arg ligneEntree type: map<string,int>;
		
		return ((ligneEntree at enteteEntree) != nil);
				
		/* JV 231121 test cohérence des entetes dans testCoherenceEntetes
		if((ligneEntree at enteteEntree) != nil){
			return true;
		}else{			
			if enteteEntree!=ID_PREC {write "[SDCREF] Attention lentete nexiste pas !! = " + enteteEntree;} // JV ID_PREC peut etre absent, ce n'est pas une erreur
			return false;
		}
		*/
	}
	
	/*
	 * Private
	 * Prend en entree la liste des entetes lues dans le fichier, et leur affecte un numero de ligne
	 */
	map<string,int> remplissageMapEnteteFichier(list<string> entetesLues <- []){
	//	arg entetesLues type: list<string> default: [];
		
		// JV 240821 si d'anciens libellés sont détectés, on les remplace par leur nouvelle version
		entetesLues <- remplaceAnciensLibelles(entetesLues);	
		
		map<string,int> mapResultat <- map<string,int>([]);
		int numLigne <- 0;
		loop entete over: entetesLues{
			put numLigne at: entete in: mapResultat;
	        numLigne <- numLigne + 1;		
		}			
			
		return mapResultat;
	}
	
	/*
	 *  JV 231121: test cohérence des entêtes: vérification que les entêtes nécessaires sont présentes, à compléter
	 */ 	
	action testCoherenceEntetes(map<string,int> lesEntetes){
		if plusieursFertilisationsParITK and !(lesEntetes.keys contains "TYPE_EXPL"){
			do raiseWarning("TYPE_EXPL absent alors que plusieursFertilisationsParITK vrai");
		}
	}
	
	
	
	list<systemeDeCultureDeReference> creationSystemeDeCultureDeReference{
		arg idsEntree type: string;
		
		list<systemeDeCultureDeReference> liste <- [];
		list<string> listeIdSdc <- (idsEntree tokenize SEPARATEUR);
		if(empty(listeIdSdc)){
			listeIdSdc << idsEntree;
		}
		loop idSdcLu over: listeIdSdc{
			if(mapSystemesDeCultureDeRef at idSdcLu = nil){
				create systemeDeCultureDeReference{
					idSdc <- idSdcLu;
					name <- idSdc;
					liste << self;
					put self at: idSdc in: mapSystemesDeCultureDeRef;
				}				
			}else{
				liste << (mapSystemesDeCultureDeRef at idSdcLu);
			}
		}

		return liste;
	}
	
	/*
	 * Public
	 * Lit un fichier avec les rotations type des sdc
	 */
	 action lectureFichierRotationsTypesSdcRef{
	 	if(file_exists(cheminRotationsSystemeDeCulture)){
		 	matrix initSystemeDeCulture <- matrix(csv_file(cheminRotationsSystemeDeCulture,";",false));
		 	//matrix initSystemeDeCulture <- matrix(file(cheminRotationsSystemeDeCulture));
		 	int nbLignes <- length(initSystemeDeCulture column_at 0);	
			 	
			loop i from: 1 to: ( nbLignes - 1 ) {
				list<string> ligneI <- (initSystemeDeCulture row_at i) as list<string>;	
				systemeDeCultureDeReference sdcRef <- mapSystemesDeCultureDeRef at (ligneI at 0);
				// On cree la liste ditk a partir des donnees lues (rotationReelle)
				list<string> liste <- (ligneI at 1) tokenize SEPARATEUR;
				if(empty(liste)){
					liste << (ligneI at 1);
				}
				
				list<string> listIDMat <- ["NA"];
				//if (sdcRef.parcelleIrrigableSdC){
					loop mat over: mapMateriel.keys {
						listIDMat << mat;
					}
				//}
				
				loop mat over: listIDMat{
					loop SOL over: listNomZonePedo{
						list<itk> rotationType <-[];
						// Si le type d'exploitation n'est pas un critère de spatialisation
						loop idCulture over: liste{
							rotationType << sdcRef.getITK(especeEntree:(idCulture), materielEntree:(mapMateriel at mat), zonePedo:SOL, type_exploitation:"", type_gestion_prairie:[""]);
						}
						if (length(rotationType)=length(liste)){ //Si il existe bien un itk pour chaque element du sdc
							put rotationType at: (mat +"_" + SOL) in: sdcRef.mapRotationType ;
						}else{
							write 'itks manquants pour :' + (mat +"_" + SOL);
						}
					}
				}
				
				
				//on va maintenant chercher a savoir a quelle zone climatique ce sdc de 
				// reference appartient
				map<string, int> compteurParZC <- map<string, int>([]);
				loop SOL over: listNomZonePedo{
					loop it over: (sdcRef.mapRotationType at ("NA_"+SOL)){
						loop ZC over: it.especeCultiveeITK.listZoneClimatiquePossible{
							put (1 + (compteurParZC at (ZC+"_"+SOL))) in: compteurParZC at: (ZC+"_"+SOL);
						}
					}
				}
				loop ZONE_PEDO_CLIM over: compteurParZC.keys{
				
					if((compteurParZC at ZONE_PEDO_CLIM) = length(first(sdcRef.mapRotationType))){
						list<systemeDeCultureDeReference> temp <- SDCRefParZonePedoClim at ZONE_PEDO_CLIM;
						temp << sdcRef;
						put temp  at: ZONE_PEDO_CLIM in: SDCRefParZonePedoClim;
					}
					
					
				}
					 				
			} 		
	 	}else{
	 		//write  "Attention aucuns système de culture de référence avec rotation type n'a ete fourni";
	 	}
	}
	
	/*
	 * Public
	 * Lit un fichier avec les correspondances entre rotations type des sdc
	 */
	 action lectureFichierMatriceDistanceCulturale{
	 	if(file_exists(cheminMatriceDistanceCulturale)){
		 	matriceDistanceCulturale <- matrix(csv_file(cheminMatriceDistanceCulturale,";",string,false));
		 	//matriceDistanceCulturale <- matrix(file(cheminMatriceDistanceCulturale));
		}
	}
	
	// JV 240821 si d'anciens libellés sont détectés, on les remplace par leur nouvelle version	
	list<string> remplaceAnciensLibelles(list<string> listeLibelles){
		
		// clé: ancien libellé, valeur: nouveau libellé		
		map<string,string> traduction <- [
			"SEMIS_JOURS_TMIN" :: "SEMIS_JOURS_TEMP_MIN",
			"SEMIS_TMIN_MIN" :: "SEMIS_TEMPERATURE_MIN",
			"IRRIGATION_HAUTEURS_PLUIE_PREVUES" :: "IRRIGATION_HAUTEURS_PLUIE_PREVUES_MIN",
			"IS_PREPA_SOL" :: "IS_PREPA",
			"PREPA_JOURS_P-ETP_MOY" :: "PREPA_JOURS_P-ETP_MIN",
			"IS_BINAGE_SOL" :: "IS_BINAGE",
			"IS_REPRISE_SOL" :: "IS_REPRISE",
			"isPHYTO" :: "IS_PHYTO"];
		
		// remplace anciens par nouveaux dans listeLibelles
		loop ancien over: traduction.keys {
			int indice <- listeLibelles index_of ancien;
			if indice!=-1 {
				listeLibelles[indice] <- traduction[ancien];
			}
		}
		
		return listeLibelles;
	}
}

species systemeDeCultureDeReference{
	string idSdc <- "-1";
	list<itk> listeITKsPossibles <- []; //variable intermediaire neccesaire pour la creation des SDC par lecture de fichier
	map<string,list<itk>> mapRotationType<-map([]); //definition de la list itk ci-dessous //map : cle materiel +"_"+ zonePedo
	bool parcelleIrrigableSdC <- false ; // Si au moins un ITK est irrigable	
			
	/*
	 * *****************************************************************************************
	 */
	itk getITK(string especeEntree, materielIrrigation materielEntree, string zonePedo, string type_exploitation, list type_gestion_prairie) {
		
		especeCultivee espece <- first(((especeCultivee as list) + (especeHerbSim as list)) where (each.idEspeceCultivee = especeEntree)); // TODO : revoir idEspece en String !!!
		//write "Recherche ITK --- espece = " + espece;
		itk itkRes <- first(listeITKsPossibles where ((each.especeCultiveeITK = espece)
			and (each.matITK = materielEntree) 
			and ((each.listSolITK at zonePedo)!=nil)
			and (each.listTypeExploitITK contains type_exploitation)
			and (each.listGestionPrairieITK contains_all type_gestion_prairie)
			));
		
		// JV 030821 si ITK non defini, on ne cherche plus un ITK similaire, on le signale (sauf cas des ilots hors-zone sans zone pedo)
		// JV 231121 controlé par un booléen du launcher pour compatibilité avec les précédentes versions, mais à supprimer définitivement à terme
		if remplacerItkManquants {
			if (itkRes = nil) and !(materielEntree = nil){ 
				if(length(listeITKsPossibles where ((each.especeCultiveeITK = espece) and ((each.listSolITK at zonePedo)!=nil))) = 1){ // il s'agit d'un itk non irrigue
					itkRes <- first(listeITKsPossibles where ((each.especeCultiveeITK = espece) and 
						(each.matITK = nil) and ((each.listSolITK at zonePedo)!=nil)));
				}else{
					if (!init){
						write "Probleme on veux affecter un itk irrigue avec un "+ materielEntree.idMateriel +
						 " pour l'espece " + espece +" et la zone pedo "+zonePedo +". Cependant un tel itk n'a pas ete defini => affectation aleatoire d'un itk";
						
					}
					 itkRes <- any(listeITKsPossibles where (each.especeCultiveeITK = espece));
				}		
			}
		}
		
		if(itkRes = nil){
			//write "listeITKsPossibles=" + listeITKsPossibles collect (each.idITK + " " + each.matITK + each.listTypeExploitITK); // JV debug
			if(listNomZonePedo at zonePedo = nil){ // gestion cas particuliers parcelles HZ dont sol n'est pas dans la liste
				itkRes <-first (listeITKsPossibles where ((each.especeCultiveeITK = espece) and (each.matITK = nil) and (each.listTypeExploitITK contains type_exploitation) and (each.listGestionPrairieITK contains_all type_gestion_prairie)));
				put zonePedo at: zonePedo in: itkRes.listSolITK ;
				write "Cas particulier parcelles HZ : sol "+ zonePedo +" non existant dans la zone";
			}
			else{
				if remplacerItkManquants {
					string chaineConsole;
					list<string> chaineFichier <- [];
					if(materielEntree!=nil){
						chaineConsole <- "" + idSdc + " - [systemeDeCultureDeReference/getITK] Pb ITK nul !!! especeEntree = " + especeEntree + " - espece " + espece + " materielIrrigation "+ materielEntree.idMateriel + " -zonePedo "+ zonePedo + " typeExp " + type_exploitation;
						chaineFichier <- [idSdc, especeEntree, materielEntree.idMateriel, zonePedo, type_exploitation, type_gestion_prairie];
					}else{
						chaineConsole <- "" + idSdc + " - [systemeDeCultureDeReference/getITK] Pb ITK nul !!! especeEntree = " + especeEntree + " - espece " + espece + " materielIrrigation NA " + " -zonePedo "+ zonePedo + " typeExp " + type_exploitation + " gestionPrairie " + type_gestion_prairie;
						//chaineFichier <- idSdc + ";" + especeEntree + ";NA;" + zonePedo + ";" + type_exploitation;
						//write "materielEntree=" + materielEntree + " irrigue=" + irrigue + "\nlisteITKsPossibles=" + listeITKsPossibles collect (each.idITK + " " + each.matITK);
					}
					write chaineConsole;
					string cheminFic <- cheminRelatifDuDossierDeSortieDeSimulation + "/missingITK.csv";
					if !file_exists(cheminFic) {
						list<string> enteteITKmanquants <- ["SdC","espece","materiel","zonePedo","typeExploit"];
						save enteteITKmanquants to: cheminFic format:'csv' header:false;
					}
					save chaineFichier to: cheminFic format:'csv' rewrite:false;
				}
			}
			
			// JV 030821 pas de remplacement en cas d'ITK non defini
			// JV 231121 controle par booléen du launcher
			if remplacerItkManquants {				
				if (materielEntree = nil){
					itkRes <- any(listeITKsPossibles where (each.especeCultiveeITK = espece));
				}
			}
		}
		
		return itkRes;
	}	
}	
