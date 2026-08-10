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
 *  marchesAgricole
 *  Author: Maroussia Vavasseur, Romain Lardy
 *  Description: Vends les semences et achetes les recoltes
 */

model marcheAgricole

import "exploitation.gaml"
import "../modeleCommun/donneesGlobales.gaml"

global{
	
	marcheAgricole leMarcheAgricole <- nil; //le marche agricole (cout de production et prix des recoltes)
	string cheminMarcheAgricole <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/marcheAgricole/';
										
	string cheminChargesOp  <-  '' + cheminMarcheAgricole + 'chargesOp.csv';
	string cheminChargesDePassage  <-  '' + cheminMarcheAgricole + 'chargesDePassage.csv';	 
	string cheminChargesFixesMaterielIrrigation  <-  '' + cheminMarcheAgricole + 'chargesFixesMaterielIrrigation.csv';
	string cheminChargesAccesRessourceIrrigation  <-  '' + cheminMarcheAgricole + 'chargesFixesAccesRessourceIrrigation.csv';	 
	string cheminPrimes  <-  '' + cheminMarcheAgricole + 'primes.csv';	 
	string cheminPrixEau  <-  '' + cheminMarcheAgricole + 'prixEau.csv';										 
	string cheminRedevanceEau  <-  '' + cheminMarcheAgricole + 'redevanceEau.csv';
	string cheminASAForfaitSurface  <-  '' + cheminMarcheAgricole + 'ASAForfaitSurface.csv';
	string cheminASAForfaitDebit  <-  '' + cheminMarcheAgricole + 'ASAForfaitDebit.csv';
	string cheminASAPrixEau  <-  '' + cheminMarcheAgricole + 'ASAPrixEau.csv';
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionMarcheAgricole{
		if folder_exists(cheminMarcheAgricole) { // JV 100821 si repertoire absent, pas de marche agricole et leMarcheAgricole reste à "nil"
			create marcheAgricole{
					//write "AVANT INIT type_of(prixEau_par_annee)= " + type_of(prixEau_par_annee);		
				do initialisationMarcheAgricole;
			}
			leMarcheAgricole <- first (marcheAgricole);
		}
		else {do raiseWarning("répertoire inexistant: " + cheminMarcheAgricole);}
	}	
	
}

species marcheAgricole {
	map<especeCultivee, float> prix_recoltes  init: map<especeCultivee, float>([]); //prix pour l'annee en cours [€/t]
	map<string,map<especeCultivee, float>> prime_par_departement init: map([]); //primes pour l'annee en cours [€/ha]
	map<itk, float> chargesOperationelles <- map<itk, float>([]); //charges operationelle pour l'annee en cours [€/ha]

	//Cout de l'irrigation : se compose du prix de l'eau, de la taxe eau + cout énergie 
	// nature (SURF, RET, NAPP, CAN) :: prix
	//Attention fichiers d'entrée a renseigner en €/m3
	map<string, float> prixEau <- map<string, float>([]); //prix de leau pour l'annee en cours [€/m3]
	map<string, float> redevanceEau <- map<string, float>([]); //redevance de leau pour l'annee en cours [€/m3]
	map<string, float> chargesFixesRessource <- map<string, float>([]); //NAPP : €/m de profondeur
	
	map<string, float> chargesFixesMaterielIrrigation <- map<string, float>([]); //Prix par type de materiel d irrigation pour l'annee en cours [€/type de materiel]

	//tables de charges de passage :i.e. cout de toutes les opérations de passage sur une parcelle //map par annee
	map<itk, float> chargesPassage <- map<itk, float>([]);
	// TABLES DE CHARGES DE PASSAGES, TABLES PAR AN :
	map<int,map<itk, float>> chargesPassage_par_annee <- map([]);
	
	//Table de prix principale
	map<int,map<especeCultivee, float>> prix_recoltes_par_annee  <- map([]); //map par annee
	// Tables de prix secondaire utilisee pour les sorties de simulations
	map<string, map<int, map<especeCultivee, float>>> prix_recoltes_par_scenario_par_annee  <- map([]); // map par annee, par nomDeScenrarion de prix 
	
	map<int,map<itk, float>> chargesOp_par_annee <- map([]); //map par annee
	map<int,map<string,map<especeCultivee, float>>> primes_par_annee_par_departement <- map([]); //map par annee par departement
	map<int,map<string, float>> prixEau_par_annee <- map([]); //map par annee
	map<int,map<string, float>> redevanceEau_par_annee <- map([]); //map par annee
	map<int,map<string, float>> chargesFixesRessource_par_annee <- map([]); //map par annee
	
//		map<int,map<itk, float>> coutIrrObs_par_annee <- map([]);
	
	
	map<int, map<string, float>> chargesFixesMaterielIrrigation_par_annee <- map([]); //Prix par type de materiel d irrigation par annee [€/type de materiel]
	
	map<string, float> ASAForfaitSurface <- map<string, float>([]); //[€/ha]
	map<string, float> ASAForfaitDebit <- map<string, float>([]); //[€/(L/s)]
	map<string, float> ASAPrixEau <- map<string, float>([]); //[€/m3]
	
	map<int, map<string, float>>ASAForfaitSurface_par_annee <- map([]); //map par annee
	map<int, map<string, float>> ASAForfaitDebit_par_annee <- map([]); //map par annee
	map<int, map<string, float>> ASAPrixEau_par_annee <- map([]); //map par annee
	
	// JV 280222 si au moins une année de prix est manquante, on reconstitue la séquence de prix, sinon on prend les prix fournis (cf Mantis 0002884)
	
	
	/*
	* *****************************************************************************************
 	*/	
	action comportementAnnuel{
		do majMarcheAgricole();
	}
	
	/*
	* *****************************************************************************************
 	*/	
	action initialisationMarcheAgricole{
		
		loop scenario over: listScenarioPrix{
			string cheminPrix  <-  '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +
				 '/modeleAgricole/marcheAgricole/prixVentes'+ scenario+'.csv';
			map<int,map<especeCultivee, float>> prix_recoltes_par_annee_1_scenario  <- map([]); //map par annee
			do lectureDonneEcoParEspece(cheminPrix, prix_recoltes_par_annee_1_scenario);
			put prix_recoltes_par_annee_1_scenario at: scenario in: prix_recoltes_par_scenario_par_annee;
		}
		prix_recoltes_par_annee <-prix_recoltes_par_scenario_par_annee at scenarioDePrixPrincipal;
		
		do lectureDonneEcoParItk(cheminChargesOp, chargesOp_par_annee);
		do lectureDonneEcoParEspeceParDepartement(cheminPrimes, primes_par_annee_par_departement);
		do lectureDonneEcoParNatureDeRessource(cheminPrixEau, prixEau_par_annee);
		do lectureDonneEcoParNatureDeRessource(cheminRedevanceEau, redevanceEau_par_annee);
		do lectureDonneEcoParNatureDeRessource(cheminChargesAccesRessourceIrrigation, chargesFixesRessource_par_annee);
		
		do lectureDonneEcoParItk(cheminChargesDePassage, chargesPassage_par_annee);
		
		do lectureDonneEcoParNatureDeRessource(cheminChargesFixesMaterielIrrigation, chargesFixesMaterielIrrigation_par_annee);
		
		do lectureDonneEcoParNatureDeRessource(cheminASAForfaitSurface, ASAForfaitSurface_par_annee);
		do lectureDonneEcoParNatureDeRessource(cheminASAForfaitDebit, ASAForfaitDebit_par_annee);
		do lectureDonneEcoParNatureDeRessource(cheminASAPrixEau, ASAPrixEau_par_annee);
		
//			if (file_exists(cheminInitIrrigation)){
//				do lectureDonneEcoParItk(cheminInitIrrigation, coutIrrObs_par_annee);
//			}

		//Maintenant on affecte les valeurs initiales de début de simulation
		
		loop scenario over: listScenarioPrix{
			map<int,map<especeCultivee,float>> prix_recoltes_par_annee_1_scenario <- prix_recoltes_par_scenario_par_annee at scenario;
			map<especeCultivee,float> prix_recoltes_pour_1_annee_1_scenario <- InitUneVariable(prix_recoltes_par_annee_1_scenario, "prixVentes" + scenario) as map<especeCultivee,float>;
			put prix_recoltes_pour_1_annee_1_scenario at: dateCour.annee in: prix_recoltes_par_annee_1_scenario;		
			put prix_recoltes_par_annee_1_scenario at: scenario in: prix_recoltes_par_scenario_par_annee;
		}
		prix_recoltes_par_annee <-prix_recoltes_par_scenario_par_annee at scenarioDePrixPrincipal;
		prix_recoltes <- prix_recoltes_par_annee at dateCour.annee;	
		//prix_recoltes 			<-  InitUneVariable(prix_recoltes_par_annee,	"Prix Ventes Espece");
		chargesOperationelles 	<-  InitUneVariable(chargesOp_par_annee, "chargesOp") as map<itk, float>;
		prime_par_departement 	<- InitUneVariable(primes_par_annee_par_departement, "primes");
		prixEau 				<- InitUneVariable(prixEau_par_annee, "prixEau") as map<string,float>;
		redevanceEau 			<- InitUneVariable(redevanceEau_par_annee, "redevanceEau") as map<string,float>;
		chargesFixesRessource 	<- InitUneVariable(chargesFixesRessource_par_annee, "chargesFixesAccesRessourceIrrigation") as map<string,float>;
		chargesPassage 			<- InitUneVariable(chargesPassage_par_annee, "chargesDePassage") as map<itk,float>;
		chargesFixesMaterielIrrigation 	<- InitUneVariable(chargesFixesMaterielIrrigation_par_annee, "chargesFixesMaterielIrrigation") as map<string,float>;
		ASAForfaitSurface 		<- InitUneVariable(ASAForfaitSurface_par_annee, "ASAForfaitSurface") as map<string,float>;
		ASAForfaitDebit 		<- InitUneVariable(ASAForfaitDebit_par_annee, 	"ASAForfaitDebit") as map<string,float>;
		ASAPrixEau       		<- InitUneVariable(ASAPrixEau_par_annee, 		"ASAPrixEau") as map<string,float>;		
	}
	
	/*
	* *****************************************************************************************
 	*/
 	
 	map InitUneVariable(map<int,map> varEco_par_annee, string nomVariable ){
 		
 		// JV 280222 si au moins une année simulée manque, on reconstitue la séquence entièrement
 		bool toutesAnneesFournies <- true;
 		list<int> anneesSimulation <- [];
 		loop uneAnnee from: anneeDebutSimulation to: (anneeDebutSimulation + nbAnneesSimulation - 1) {
 			anneesSimulation <+ uneAnnee;
 			toutesAnneesFournies <- toutesAnneesFournies and (varEco_par_annee.keys contains uneAnnee);
 		}
 		// si toutes années présentes, on renvoie l'année courante
 		if toutesAnneesFournies {
 			return varEco_par_annee[dateCour.annee];
 		}
 		else{
 			
 			// on recherche les années communes (année simulée et dont les données sont dispo)
 			list<int> anneesCommunes <- (anneesSimulation inter varEco_par_annee.keys) sort_by each;
 			int anneeDeReference <- -1;
 			if !empty(anneesCommunes) { 
	 			// on prend la première année commune (à discuter, cf Mantis #2884)
	 			anneeDeReference <- first(anneesCommunes);
			}else{
				if min(anneesSimulation)>max(varEco_par_annee.keys) {anneeDeReference <- max(varEco_par_annee.keys);} // années connues toutes antérieures
				else {anneeDeReference <- min(varEco_par_annee.keys);} // années connues toutes postérieures
			} 			

			// peut pas appeler raiseWarning à partir d'une méthode non globale
			string ch <- nomVariable + " non spécifié(e) pour les années " + (anneesSimulation-varEco_par_annee.keys) + ", imputation à partir de l'année de référence " + anneeDeReference + " voir valeurs imputées dans répertoire de sortie";
			write "\t\u2757 WARNING " + ch color:#orange;
			initLogWarning <- initLogWarning + "- " + ch + "\n"; 			
 			
 			if nomVariable!="primes" { // primes est spécial car étage supplémentaire (par département)
	 			// on reconstitue les valeurs de toutes les années postérieures à l'année de référence en incrémentant de l'inflation
	 			int uneAnnee <- anneeDeReference + 1;		
	 			loop while:uneAnnee < (anneeDebutSimulation + nbAnneesSimulation) {
	 				varEco_par_annee[uneAnnee] <- map([]); // vide les éventuelles valeurs
	 				loop uneCle over: varEco_par_annee[anneeDeReference].keys {
	 					if varEco_par_annee[uneAnnee-1][uneCle]!=nil {
	 						varEco_par_annee[uneAnnee][uneCle] <- float(varEco_par_annee[uneAnnee-1][uneCle]) * inflation;
	 					}else{
	 						varEco_par_annee[uneAnnee][uneCle] <- float(nil);
	 					}
	 				}
					uneAnnee <- uneAnnee + 1;
	 			}
	 			// on reconstitue les valeurs de toutes les années antérieures à l'année de référence en décrémentant de l'inflation
	 			uneAnnee <- anneeDeReference - 1;		
	 			loop while:uneAnnee >= anneeDebutSimulation {
	 				varEco_par_annee[uneAnnee] <- map([]); // vide les éventuelles valeurs
	 				loop uneCle over: varEco_par_annee[anneeDeReference].keys {
	 					if varEco_par_annee[uneAnnee+1][uneCle]!=nil {
	 						varEco_par_annee[uneAnnee][uneCle] <- float(varEco_par_annee[uneAnnee+1][uneCle]) / inflation;
 						}else{
	 						varEco_par_annee[uneAnnee][uneCle] <- float(nil);
	 					}
	 				}
					uneAnnee <- uneAnnee - 1;
	 			}
			}
			else{ // primes: clé = espece + département: map<int(annee),map<string(dpt),map<especeCultivee,float>>>	
	 			varEco_par_annee <- map<int,map<string,map<especeCultivee,float>>>(varEco_par_annee);
	 			list<string> listeDpt <- varEco_par_annee[anneeDeReference].keys; 	
	 			list<especeCultivee> listeEsp <- map(first(varEco_par_annee[anneeDeReference])).keys;
	 			
	 			// on reconstitue les valeurs de toutes les années postérieures à l'année de référence en incrémentant de l'inflation
	 			int uneAnnee <- anneeDeReference + 1;		
	 			loop while:uneAnnee < (anneeDebutSimulation + nbAnneesSimulation) {
	 				varEco_par_annee[uneAnnee] <- map([]); // vide les éventuelles valeurs
	 				loop unDepartement over: listeDpt {
	 					map<especeCultivee,float> dptAnneePrec <- varEco_par_annee[uneAnnee-1][unDepartement];
	 					map<especeCultivee,float> dptAnneeCour <- map<especeCultivee,float>([]);
	 					loop uneEspece over: listeEsp {
		 					if dptAnneePrec[uneEspece]!=nil {
		 						dptAnneeCour[uneEspece] <- dptAnneePrec[uneEspece] * inflation;
		 					}else{
		 						dptAnneeCour[uneEspece] <- float(nil);
		 					}
						}
						varEco_par_annee[uneAnnee][unDepartement] <- dptAnneeCour;
	 				}
					uneAnnee <- uneAnnee + 1;
	 			}
	 			// on reconstitue les valeurs de toutes les années antérieures à l'année de référence en décrémentant de l'inflation
	 			uneAnnee <- anneeDeReference - 1;		
	 			loop while:uneAnnee >= anneeDebutSimulation {
	 				varEco_par_annee[uneAnnee] <- map([]); // vide les éventuelles valeurs
	 				loop unDepartement over: listeDpt {
	 					map<especeCultivee,float> dptAnneeSuiv <- varEco_par_annee[uneAnnee+1][unDepartement];
	 					map<especeCultivee,float> dptAnneeCour <- map<especeCultivee,float>([]);
	 					loop uneEspece over: listeEsp {
		 					if dptAnneeSuiv[uneEspece]!=nil {
		 						dptAnneeCour[uneEspece] <- dptAnneeSuiv[uneEspece] / inflation;
		 					}else{
		 						dptAnneeCour[uneEspece] <- float(nil);
		 					}
						}
						varEco_par_annee[uneAnnee][unDepartement] <- dptAnneeCour;
	 				}
					uneAnnee <- uneAnnee - 1;
	 			}
			}
								
			// on supprime les années en dehors de la simulation
			// JV 100524 operator >>- doesn't function properly in GAMA 1.9.3 (see https://github.com/gama-platform/gama/issues/166)
			// use the patch function removeAtIndices definedMap in donneesGlobales
			//varEco_par_annee[] >>- (varEco_par_annee.keys-anneesSimulation);
			varEco_par_annee <- world.removeAtIndicesMap(varEco_par_annee, varEco_par_annee.keys-anneesSimulation);
								
			switch nomVariable {
				match_one ["prixEau","redevanceEau","chargesFixesAccesRessourceIrrigation","chargesFixesMaterielIrrigation","ASAForfaitSurface","ASAForfaitDebit","ASAPrixEau"] {
					do sauvegardeFichierReconstitueParNatureDeRessource(varEco_par_annee,nomVariable);
				}
				match_one ["chargesOp","chargesDePassage"] {
					do sauvegardeFichierReconstitueParItk(varEco_par_annee,nomVariable);
				}
				match "primes" {
					do sauvegardeFichierReconstitueParEspeceParDepartement(map<int,map<string,map<especeCultivee,float>>>(varEco_par_annee),nomVariable);
				}
				default {do sauvegardeFichierReconstitueParEspece(varEco_par_annee,nomVariable);}
			}
						
 			return varEco_par_annee[dateCour.annee];
 		}
 		
 	}
 	
 		
	action lectureDonneEcoParEspece (string Chemin, 
			map<int,map<especeCultivee, float>> prix_par_annee,
			float facteurConversion <- 1.0
	){
		if (file_exists(Chemin)){
			matrix Init <- matrix(csv_file(Chemin,";",false));
			//matrix Init <- matrix(file(Chemin));
			int nbColones <- length(Init row_at 0);
			int nbLignes <- length(Init column_at 0);
			list listannee <-  ( Init row_at 0 );
			
			loop j from: 2 to: (nbColones -1){ //boucle sur les annees
				map<especeCultivee, float> prix1Annee <- map<especeCultivee, float>([]);
				loop i from: 1 to: (nbLignes -1){ //boucle sur les especes
					list ligneCourante <-  ( Init row_at i );
					especeCultivee espece <- mapEspecesCultiveesParId at (ligneCourante at 0);
					if (espece = nil){
						//write "l espece "+ (ligneCourante at 0)+ " lue dans "+ Chemin + " n a pas ete defini ";
					}else{
						put (float(ligneCourante at (j)) * facteurConversion) at: espece in:prix1Annee ; //convertir les prix de vente en €/q
					}
				}
				put prix1Annee at: (int(listannee at j)) in: prix_par_annee;
			}
		}else{
			write "le fichier "+Chemin+" est manquant";
		}
		
		
	}
	
	/*
	* *****************************************************************************************
 	*/	//map<int,map<string,map<especeCultivee, float>>> primes_par_annee_par_departement 
	action lectureDonneEcoParEspeceParDepartement (string Chemin, 
			map<int,map<string,map<especeCultivee, float>>> prix_par_annee_par_departement_par_espece
	){
		if (file_exists(Chemin)){
			matrix Init <- matrix(csv_file(Chemin,";",false));
			//matrix Init <- matrix(file(Chemin));
			int nbColones <- length(Init row_at 0);
			int nbLignes <- length(Init column_at 0);
			list listannee <-  ( Init row_at 0 );
			
			loop j from: 3 to: (nbColones -1){ //boucle sur les annees
				map<string,map<especeCultivee, float>> prix_par_departement_par_espece  <- map([]);
				loop i from: 1 to: (nbLignes -1){ //boucle sur les especes et les departements
					list ligneCourante <-  ( Init row_at i );
					especeCultivee espece <- mapEspecesCultiveesParId at (ligneCourante at 0);
					string dept <- (ligneCourante at 2);
					if (espece = nil){
						string ch <- "l'espèce "+ (ligneCourante at 0)+ " lue dans "+ Chemin + " n'a pas été définie";
						write "\t\u2757 WARNING " + ch color:#orange;
						initLogWarning <- initLogWarning + "- " + ch + "\n";						
					}else{
						//Si le departement lu est 'all' alors on affecte la valeur a tout ces de listDepartements
						// mais seulement s'il n'y a pas deja une valeur
						if(dept = 'all'){
							loop dept2 over: listIDDepartements{
								map<especeCultivee, float> primesParEspece_1dept <- prix_par_departement_par_espece at dept2;
								if(primesParEspece_1dept = nil){
									primesParEspece_1dept  <- map<especeCultivee, float>([]); 
								}
								if(primesParEspece_1dept at espece <=0.0){ // si il n y a pas deja une valeur
									put float(ligneCourante at (j)) at: espece in:primesParEspece_1dept ;
								}
								put primesParEspece_1dept at: dept2 in: prix_par_departement_par_espece;
							}
						}else{
							map<especeCultivee, float> prixParEspece_1dept <- prix_par_departement_par_espece at dept;
							if(prixParEspece_1dept = nil){
								prixParEspece_1dept  <- map<especeCultivee, float>([]); 
							} 
							put float(ligneCourante at (j)) at: espece in:prixParEspece_1dept ;
							put prixParEspece_1dept at: dept in: prix_par_departement_par_espece;
						}
					}
				}
				put prix_par_departement_par_espece at: (int(listannee at j)) in: prix_par_annee_par_departement_par_espece;
			}
		}else{
			write "le fichier "+Chemin+" est manquant";
		}
	}
	
	/*
	* *****************************************************************************************
 	*/	
	action lectureDonneEcoParItk (string Chemin, 
			map<int,map<itk, float>> prix_par_annee
	){
		if (file_exists(Chemin)){
			matrix Init <- matrix(csv_file(Chemin,";",false));
			//matrix Init <- matrix(file(Chemin));
			int nbColones <- length(Init row_at 0);
			int nbLignes <- length(Init column_at 0);
			list listannee <-  ( Init row_at 0 );
			
			loop j from: 2 to: (nbColones -1){ //boucle sur les annees
				map<itk, float> prix1Annee <- map<itk, float>([]);
				loop i from: 1 to: (nbLignes -1){ //boucle sur les itk
					list ligneCourante <-  ( Init row_at i );
					ask itk where (each.idITK = (ligneCourante at 0)){
						put (float(ligneCourante at (j)) ) at: self in:prix1Annee ;	
					}
				}
				put prix1Annee at: (int(listannee at j)) in: prix_par_annee;
			}
		}else{
			write "le fichier "+Chemin+" est manquant";
		}
		
		
	}
	
	/*
	* *****************************************************************************************
 	*/	
	action lectureDonneEcoParNatureDeRessource (string Chemin, 
			map<int,map<string, float>> prix_par_annee
	){
		//write "chemin=" + Chemin + " type_of(prix_par_annee)= " + type_of(prix_par_annee);
		if (file_exists(Chemin)){
			matrix Init <- matrix(csv_file(Chemin,";",false));
			//matrix Init <- matrix(file(Chemin));
			int nbColones <- length(Init row_at 0);
			int nbLignes <- length(Init column_at 0);
			list listannee <-  ( Init row_at 0 );
			loop j from: 1 to: (nbColones -1){ //boucle sur les annees
				map<string, float> prix1Annee <- map<string, float>([]);
				loop i from: 1 to: (nbLignes -1){ //boucle sur les natures de ressources
					list ligneCourante <-  ( Init row_at i );
					string typeRessource <- string(ligneCourante at 0);
					put float(ligneCourante at (j)) at: typeRessource in:prix1Annee ;
				}
				put prix1Annee at: (int(listannee at j)) in: prix_par_annee;
			}
		}else{
			write "le fichier "+Chemin+" est manquant";
		}
		
	}
	
	/*
	* *****************************************************************************************
 	*/	
	action lectureDonneEcoSimple (string Chemin, 
			map<int, float> prix_par_annee,
			int numeroDelaColonneAconsiderer
	){
		if (file_exists(Chemin)){
			matrix Init <- matrix(csv_file(Chemin,";",false));
			//matrix Init <- matrix(file(Chemin));
			int nbLignes <- length(Init column_at 0);

			loop i from: 1 to: (nbLignes -1){ //boucle sur les annees
				list<float> ligneCourante <-  ( Init row_at i ) as list<float>;
				put (ligneCourante at numeroDelaColonneAconsiderer) at: (ligneCourante at 0) in: prix_par_annee;
			}
		}else{
			write "le fichier "+Chemin+" est manquant";
		}

	}
	
	/*
	* *****************************************************************************************
 	* renvoie un prix tirée aléatoirement parmis les 10 derniers prixs observés et l'ajuste 
 	* de l'inflation
 	*/
 	float getNewPriceFrom10LastObs (especeCultivee especeDemande){
 		float nouveauPrix <- 0.0;
 		
 		// 1 - Recuperer une table des 10 dernieres observations
 		int nbPrix <-0;
		int y<- dateCour.annee -1;
		int derniereAnneeObs <- 0;
		list<float> tabPrix <- [];
		loop while: ((nbPrix<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
																	 // où qu'on a parcouru toute la liste
			
			float p <- ((prix_recoltes_par_annee at y) at especeDemande);
			if (p >0.0){
				tabPrix<< p ; 
				nbPrix<- nbPrix +1;
				derniereAnneeObs <- max ([derniereAnneeObs, y]);
			}
			y <- y - 1;
			}
			if (nbPrix < 1){
				if (length(prix_recoltes_par_annee) > 0){
					derniereAnneeObs <- min(prix_recoltes_par_annee.keys);
					tabPrix << ((prix_recoltes_par_annee at derniereAnneeObs) at especeDemande);
					write "The price for the species " + especeDemande + " were extropolated from year " + derniereAnneeObs;
				}else{
					write "There are no observed price for the species " + especeDemande;
					tabPrix<< 0.0 ; 
					derniereAnneeObs <- dateCour.annee;
				}
				nbPrix<-1;
			}
			// on tire aléatoirement dans cette table
			nouveauPrix <- tabPrix[rnd(nbPrix -1)];
			
			// 3 - ajustement de l'inflation
			nouveauPrix <- nouveauPrix * ((inflation)^(dateCour.annee - derniereAnneeObs)) ;
			
	 		return nouveauPrix;
	 	}
		
		/*
		* *****************************************************************************************
	 	*/	
		action majMarcheAgricole{
			
			loop scenario over: listScenarioPrix{
				map<int,map<especeCultivee,float>> prix_recoltes_par_annee_1_scenario <- prix_recoltes_par_scenario_par_annee at scenario;
				assert((prix_recoltes_par_annee_1_scenario at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation
				if ((prix_recoltes_par_annee_1_scenario at dateCour.annee)= nil){
					map<especeCultivee, float> prix_recoltes_pour_1_annee_1_scenario <-  prix_recoltes_par_annee_1_scenario at (dateCour.annee -1);
					loop esp over:listeEspecesCultiveesParOrdreSaisie{ //evolution des prix et cout en absence de donnees en entree
						put ((prix_recoltes_pour_1_annee_1_scenario at esp) * inflation) at: esp in: prix_recoltes_pour_1_annee_1_scenario;
						//put getNewPriceFrom10LastObs(esp) at: esp in: prix_recoltes_pour_1_annee_1_scenario;
					}
					put prix_recoltes_pour_1_annee_1_scenario at: dateCour.annee in: prix_recoltes_par_annee_1_scenario;		
					put prix_recoltes_par_annee_1_scenario at: scenario in: prix_recoltes_par_scenario_par_annee;
				}
			}
			prix_recoltes_par_annee <-prix_recoltes_par_scenario_par_annee at scenarioDePrixPrincipal;
			prix_recoltes <- prix_recoltes_par_annee at dateCour.annee;	
			
						
			assert((primes_par_annee_par_departement at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation
			if ((primes_par_annee_par_departement at dateCour.annee)!= nil){
				prime_par_departement         <- (primes_par_annee_par_departement at dateCour.annee);
				
			}else{
				loop dep over: prime_par_departement.keys{ //evolution des prix et cout en absence de donnees en entree
					map<especeCultivee, float> primesDuDepartement <- (prime_par_departement at dep);
					
					loop esp over:(prime_par_departement at dep).keys {
						put ((primesDuDepartement at esp)  *inflation) at: esp in: primesDuDepartement;
					}
					put primesDuDepartement at: dep in: prime_par_departement;
				}
			}
			
			assert((chargesOp_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((chargesOp_par_annee at dateCour.annee)!= nil){
				chargesOperationelles    <- (chargesOp_par_annee at dateCour.annee);
			}else{
				ask (itk as list){
					put (myself.chargesOperationelles at self) * inflation at: self in: myself.chargesOperationelles;
				} 
			}

			assert((chargesPassage_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((chargesPassage_par_annee at dateCour.annee)!= nil){
					chargesPassage        	<- (chargesPassage_par_annee at dateCour.annee);
			}else{
				ask (itk as list){
					put (myself.chargesPassage at self) * inflation at: self in: myself.chargesPassage;
				} 
			}
			
			assert((prixEau_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((prixEau_par_annee at dateCour.annee)!= nil){
				prixEau <- (prixEau_par_annee at dateCour.annee);
			}else{
				loop typeRes over: prixEau.keys{ //evolution des prix et cout en absence de donnees en entree
					put ((prixEau at typeRes)*inflation) at: typeRes in: prixEau;
				}
			}

			assert((redevanceEau_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((redevanceEau_par_annee at dateCour.annee)!= nil){
				redevanceEau <- (redevanceEau_par_annee at dateCour.annee);
			}else{
				loop typeRes over: redevanceEau.keys{ //evolution des prix et cout en absence de donnees en entree
					put ((redevanceEau at typeRes)*inflation) at: typeRes in: redevanceEau;
				} 
			}
			
			assert((chargesFixesMaterielIrrigation_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((chargesFixesMaterielIrrigation_par_annee at dateCour.annee)!= nil){
				chargesFixesMaterielIrrigation <- (chargesFixesMaterielIrrigation_par_annee at dateCour.annee);
			}else{
				loop typeMat over: chargesFixesMaterielIrrigation.keys{ //evolution des prix et cout en absence de donnees en entree
					put ((chargesFixesMaterielIrrigation at typeMat)*inflation) at: typeMat in: chargesFixesMaterielIrrigation;
				} 
			}
			
			assert((chargesFixesRessource_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((chargesFixesRessource_par_annee at dateCour.annee)!= nil){
				chargesFixesRessource <- (chargesFixesRessource_par_annee at dateCour.annee);
			}else{
				loop typeRes over: chargesFixesRessource.keys{ //evolution des prix et cout en absence de donnees en entree
					put ((chargesFixesRessource at typeRes)*inflation) at: typeRes in: chargesFixesRessource;
				} 
			}
			
			assert((ASAForfaitSurface_par_annee at dateCour.annee)!=nil); // JV 160322 on ne devrait jamais rentrer dans le if ci-dessous car désormais les années manquantes sont imputées à l'initialisation			
			if ((ASAForfaitSurface_par_annee at dateCour.annee)!= nil){
				ASAForfaitSurface 			<- (ASAForfaitSurface_par_annee at dateCour.annee);
				ASAForfaitDebit 			<- (ASAForfaitDebit_par_annee at dateCour.annee);
				ASAPrixEau 					<- (ASAPrixEau_par_annee at dateCour.annee);
			}else{
				loop collectif over: ASAForfaitSurface.keys{
					put ((ASAForfaitSurface at collectif) * inflation) at: collectif in: ASAForfaitSurface;
					put ((ASAForfaitDebit at collectif) * inflation) at: collectif in: ASAForfaitDebit;
					put ((ASAPrixEau at collectif) * inflation) at: collectif in: ASAPrixEau;
				}
			}
			
			
		}
		
	// JV 120322 sauvegarde dans le répertoire de sortie des valeurs reconstituées
	action sauvegardeFichierReconstitueParEspece(map<int,map> varEco_par_annee, string nomVariable) {
		
		// fichier de sortie à écrire
		string nomFicOut <- nomVariable + ".csv";
		string cheminFicOut <- cheminRelatifDuDossierDeSortieDeSimulation + "/" + nomFicOut;
		
		// fichier de données original à lire pour récupérer les 2 premières colonnes
		string nomFicIn <- "";
		string cheminFicIn <- cheminMarcheAgricole + nomVariable + ".csv";
		matrix matIn <- matrix(csv_file(cheminFicIn,";",false));
		
		string ligne <- "";
		// ligne d'entête: 2 premières colonnes
		ligne <- ligne + (matIn row_at 0)[0] + ";" + (matIn row_at 0)[1] + ";";
		loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
			ligne <- ligne + uneAnnee + ";"; // puis chaque année
		}
		save ligne to:cheminFicOut format:"text" rewrite:false;
		
		// pour chaque ligne du fichier d'origine
		loop i from:1 to:length(matIn column_at 0)-1 {
			ligne <- "" + (matIn row_at i)[0] + ";" + (matIn row_at i)[1] + ";";
			especeCultivee uneEspece <- first(especeCultivee where (each.idEspeceCultivee=matIn[0,i]));
			// pour chaque année
			loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
				ligne <- ligne + varEco_par_annee[uneAnnee][uneEspece] + ";";
			}		
			save ligne to:cheminFicOut format:"text" rewrite:false;
		}
	}

	// JV 120322 sauvegarde dans le répertoire de sortie des valeurs reconstituées
	action sauvegardeFichierReconstitueParItk(map<int,map> varEco_par_annee, string nomVariable) {
		
		// fichier de sortie à écrire
		string nomFicOut <- nomVariable + ".csv";
		string cheminFicOut <- cheminRelatifDuDossierDeSortieDeSimulation + "/" + nomFicOut;
		
		// fichier de données original à lire pour récupérer les 2 premières colonnes
		string nomFicIn <- "";
		string cheminFicIn <- cheminMarcheAgricole + nomVariable + ".csv";
		matrix matIn <- matrix(csv_file(cheminFicIn,";",false));
		
		string ligne <- "";
		// ligne d'entête: 2 premières colonnes
		ligne <- ligne + (matIn row_at 0)[0] + ";" + (matIn row_at 0)[1] + ";";
		loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
			ligne <- ligne + uneAnnee + ";"; // puis chaque année
		}
		save ligne to:cheminFicOut format:"text" rewrite:false;
		
		// pour chaque ligne du fichier d'origine
		loop i from:1 to:length(matIn column_at 0)-1 {
			ligne <- "" + (matIn row_at i)[0] + ";" + (matIn row_at i)[1] + ";";
			itk unItk <- first(itk where (each.idITK=(matIn row_at i)[0]));
			// pour chaque année
			loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
				ligne <- ligne + varEco_par_annee[uneAnnee][unItk] + ";";
			}		
			save ligne to:cheminFicOut format:"text" rewrite:false;
		}
	}
		
	// JV 120322 sauvegarde dans le répertoire de sortie des valeurs reconstituées
	action sauvegardeFichierReconstitueParEspeceParDepartement(map<int,map<string,map<especeCultivee,float>>> varEco_par_annee, string nomVariable) {
		
		// fichier de sortie à écrire
		string nomFicOut <- nomVariable + ".csv";
		string cheminFicOut <- cheminRelatifDuDossierDeSortieDeSimulation + "/" + nomFicOut;
		
		// fichier de données original à lire pour récupérer les 3 premières colonnes
		string nomFicIn <- "";
		string cheminFicIn <- cheminMarcheAgricole + nomVariable + ".csv";
		matrix matIn <- matrix(csv_file(cheminFicIn,";",false));
		
		string ligne <- "";
		// ligne d'entête: 3 premières colonnes
		ligne <- ligne + (matIn row_at 0)[0] + ";" + (matIn row_at 0)[1] + ";" + (matIn row_at 0)[2] + ";";
		loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
			ligne <- ligne + uneAnnee + ";"; // puis chaque année
		}
		save ligne to:cheminFicOut format:"text" rewrite:false;
		
		// pour chaque ligne du fichier d'origine
		loop i from:1 to:length(matIn column_at 0)-1 {
			ligne <- "" + (matIn row_at i)[0] + ";" + (matIn row_at i)[1] + ";" + (matIn row_at i)[2] + ";";
			string unDpt <- (matIn row_at i)[2];
			especeCultivee uneEspece <- first(especeCultivee where (each.idEspeceCultivee=(matIn row_at i)[0]));			
			// pour chaque année
			loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
				map<string,map<especeCultivee,float>> mapUneAnnee <- varEco_par_annee[uneAnnee];
				
				ligne <- ligne + mapUneAnnee[unDpt][uneEspece] + ";";
			}		
			save ligne to:cheminFicOut format:"text" rewrite:false;
		}
	}

	// JV 120322 sauvegarde dans le répertoire de sortie des valeurs reconstituées
	action sauvegardeFichierReconstitueParNatureDeRessource(map<int,map> varEco_par_annee, string nomVariable) {
		
		// fichier de sortie à écrire
		string nomFicOut <- nomVariable + ".csv";
		string cheminFicOut <- cheminRelatifDuDossierDeSortieDeSimulation + "/" + nomFicOut;
		
		// fichier de données original à lire pour récupérer la première colonne
		string nomFicIn <- "";
		string cheminFicIn <- cheminMarcheAgricole + nomVariable + ".csv";
		matrix matIn <- matrix(csv_file(cheminFicIn,";",false));
		
		string ligne <- "";
		// ligne d'entête: première colonne
		ligne <- ligne + (matIn row_at 0)[0] + ";";
		loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
			ligne <- ligne + uneAnnee + ";"; // puis chaque année
		}
		save ligne to:cheminFicOut format:"text" rewrite:false;
		
		// pour chaque ligne du fichier d'origine
		loop i from:1 to:length(matIn column_at 0)-1 {
			ligne <- "" + (matIn row_at i)[0] + ";";
			string uneCle <- matIn[0,i];
			// pour chaque année
			loop uneAnnee over:(varEco_par_annee.keys sort_by (each)) {
				ligne <- ligne + varEco_par_annee[uneAnnee][uneCle] + ";";
			}		
			save ligne to:cheminFicOut format:"text" rewrite:false;
		}
	}
}
