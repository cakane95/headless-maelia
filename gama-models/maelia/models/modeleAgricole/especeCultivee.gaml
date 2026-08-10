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
 *  EspecesCultivees
 *  Author: Maroussia Vavasseur
 *  Description: Dans Maelia, juste quelques types d'especes cultivees sont prises en compte ; celles qui sont le plus representatives de la zone d'etude.
 */

model especeCultivee

import "../modeleCommun/donneesGlobales.gaml"

global{
	string cheminTypeCulture <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/especesCultivees.csv';
	list<especeCultivee> listeEspecesCultiveesParOrdreSaisie <- []; 
	map<string,especeCultivee> mapEspecesCultiveesParId <- map([]); 
	
	/*
	 * *****************************************************************************************
	 * Publique
	 * Lecture du fichier type_culture.csv pour initialiser tous les types de culures
	 * Inversion des lignes et des colones
	 */
	action constructionEspeceCultivee{	
		
		if !file_exists(cheminTypeCulture) {do raiseError("fichier inexistant: " + cheminTypeCulture);}
		
		matrix initDataTypeCulture <- matrix(csv_file (cheminTypeCulture,";",false)); 
		//matrix initDataTypeCulture <- matrix(file (cheminTypeCulture)); 	
       	int nbColones <- length(initDataTypeCulture row_at 0);

		loop i from: 1 to: ( nbColones - 1 ) {
			list<string> coloneCourante <- (initDataTypeCulture column_at i) as list<string>;
			if((coloneCourante at 1) != nil){
				create especeCultivee{
					idEspeceCultivee <- coloneCourante at 0;
					listeEspecesCultiveesParOrdreSaisie << self;
					put self at: idEspeceCultivee in: mapEspecesCultiveesParId;
					name <- idEspeceCultivee;	
					rendementMoyen <- float(coloneCourante at 1);
					rendementMin <- float(coloneCourante at 2);
					rendementOptimal <- float(coloneCourante at 3);
					couleur <- rgb([coloneCourante at 4,coloneCourante at 5,coloneCourante at 6]) ;	 					

					// AQYIELD
					tbase <- float(coloneCourante at 7);
					tmax <- float(coloneCourante at 8);
					degresJourAfloraisonCult <- float(coloneCourante at 10);
					echelleVegetationStadeLevee <- float(coloneCourante at 9)/degresJourAfloraisonCult;
					echelleVegetationStadeMaturite <- float(coloneCourante at 11)/degresJourAfloraisonCult;
					
					freinCult <- float(coloneCourante at 12); //1 == pas de frein
					croissanceRacineCult <- float(coloneCourante at 13);
					coefVigueurVegetativeCult <- float(coloneCourante at 14);
					coefCulturalMax <- float(coloneCourante at 15);
					coefFermetureStomatesCult <- float(coloneCourante at 16);
					coeff_Fonction_Prod <- float(coloneCourante at 17);
					
					// AQYIELD N
					if nomChoixModeleCroissancePlante=AqYieldNC {Type_Nacq <- coloneCourante at 70;} // JV 100821: TODO: utiliser les noms de champs plutôt que les numéros de colonnes comme pour le fichier ITK
					degresJourLeveeCult <- float(coloneCourante at 9);
					degresJourMaturiteCult <- float(coloneCourante at 11);
					besoin_N <- float(coloneCourante at 45);
					besoin_N_total <- float(coloneCourante at 77); // Les besoins de la patate et de la betterave ne dépendent pas du rendement
					// Valeur QNmax donnée par le total des besoins pour la patate et la betterave
					if (besoin_N_total > 0) {
						QNmax <- besoin_N_total;
					} else {
						QNmax <- besoin_N * rendementOptimal; // Demande d'azote en t/Ha 
					}
					prof_max_racines <- float(coloneCourante at 78);
					
					debut_besoin_N <-  int(coloneCourante at 46);
					frein_besoin_N <- float(coloneCourante at 47);
					pre_floraison_besoin_N <- float(coloneCourante at 48);
					pre_maturite_besoin_N <- float(coloneCourante at 49);
					
					Tms <- float(coloneCourante at 50); // Le taux de MS des couverts intermédiaire est fixé à 1 car le rendement calculé dans cultureAqYieldNC est déjà donné en MS
					IRv <- float(coloneCourante at 51);
					aa <- float(coloneCourante at 52);
					bb <- float(coloneCourante at 53);
					ratio_R <- float(coloneCourante at 54);
					C_aer <- float(coloneCourante at 55);
					C_rac <- float(coloneCourante at 56);
					CN_aer <- float(coloneCourante at 57);
					CN_rac <- float(coloneCourante at 58);
					isLEG <- bool(coloneCourante at 59);
					abscission <- float(coloneCourante at 60);
										
					// JV 290920 ci-dessous commenté car concernent module NC pas encore intégré 
					// decommente lors de la fusion 020821
					if nomChoixModeleCroissancePlante=AqYieldNC {
						isCouvert <- bool(coloneCourante at 61); 
						
						HI <- float(coloneCourante at 62);
						Pse <- float(coloneCourante at 63);
						beta <- float(coloneCourante at 64);
						SR_ratio <- float(coloneCourante at 65);
						RootC_fixed <- float(coloneCourante at 66);
						CN_ratio <- float(coloneCourante at 67);
						N_grain <- float(coloneCourante at 75);
						
						// Paramètres des couverts intermédiaires
						adil <- float(coloneCourante at 68);
						bdil <- float(coloneCourante at 69);
						a_Ndemand_ci <- float(coloneCourante at 71);
						b_Ndemand_ci <- float(coloneCourante at 72);
						coef_500Mat <- float(coloneCourante at 73);
						Dde <- float(coloneCourante at 74);
						
						if isCI()!=isCouvert {
							string toto <- world.raiseWarning("espèce " + idEspeceCultivee + "\n\t\tstatut CI rotation: " + isCI() + "\n\t\tstatut CI AqYieldNC: " + isCouvert); 
						}
						
					}
					
					// Pramètres pour le stress climatique
					if (avecStressClimatique) {
						degresJourStadeJuvenile <- float(coloneCourante at 79) + degresJourLeveeCult;
						degresJourDureeFloraison <- float(coloneCourante at 80);
						if (degresJourDureeFloraison != 0) {
							degresJourDebutRemplissage <- degresJourAfloraisonCult + degresJourDureeFloraison;
						}
						tgelLev10 <- float(coloneCourante at 81);
						tgelLev90 <- float(coloneCourante at 82);
						tgelJuv10 <- float(coloneCourante at 83);
						tgelJuv90 <- float(coloneCourante at 84);
						tgelVeg10 <- float(coloneCourante at 85);
						tgelVeg90 <- float(coloneCourante at 86);
						tgelFlo10 <- float(coloneCourante at 87);
						tgelFlo90 <- float(coloneCourante at 88);
					}

					
					
					// SIMPLE
					loop indiceColone from: 18 to: 27{
						alphaParDecade << float(coloneCourante at indiceColone);
					}
					loop indiceColone from: 28 to: 43{
						kcParDecade << float(coloneCourante at indiceColone);
					}
					//ZoneClimatique
					list<string> listeTemp <- (coloneCourante at 44) tokenize SEPARATEUR;	
					listZoneClimatiquePossible <- listeTemp;
					if(length(listeTemp)=0){
						listZoneClimatiquePossible << "";
					}
				}
			}			
		}
		//Affectation du caractere cultures Derogatoires
		loop idCultDerog over: listCulturesDerogatoires{
			ask (especeCultivee as list) where (each.idEspeceCultivee = idCultDerog){
				isCulturesDerogatoires <- true;
			}
		}
	}	
}

species especeCultivee {
	string idEspeceCultivee <- "";
	bool isEspeceHerbSim <- false;
	rgb couleur <- rgb("white");		
	float rendementMoyen <- 0.0;
	float rendementMin <- 0.0;	
	float rendementOptimal <- 0.0;
// ----------------------------------------- VARIABLES CROISSANCE SIMPLE -----------------------------------------		
	list<float> alphaParDecade <- [];
	list<float> kcParDecade <- [];
// ----------------------------------------- VARIABLES AQYIELD -----------------------------------------
	float degresJourLeveeCult <- 0.0;
	float degresJourAfloraisonCult <- 1.0; // degres Jflo,cult
	float degresJourMaturiteCult <- 0.0;
	
	float freinCult <- 1.0; // evolue pour les cultures dhivers uniquement TODO Renaud : la valeur du frein n'a pas l'air "d'évoluer". En revanche elle change en fonctio des espèces
	float croissanceRacineCult <- 1.0; // Cracine,cult // °C/mm temperature necessaire pour faire croitre les racines de 1 mm
	float coefVigueurVegetativeCult <- 0.0; // Cvig,cult  (Kvig ???)				
	float coefCulturalMax <- 0.0; // Kmax	
	float coefFermetureStomatesCult <- 0.0; // Csto,cult
	float echelleVegetationStadeMaturite <- 1.55;
	float echelleVegetationStadeFloraison <- 1.0;
	float echelleVegetationStadeLevee <- 0.11;
	float tbase <- 0.0;
	float tmax <- 22.0;
	float coeff_Fonction_Prod <- 3.0; //Coefficient de la fonction de production ; aussi nomé a //TODO à lire
	list<string> listZoneClimatiquePossible <- [];
	bool isCulturesDerogatoires <- false;
	float prof_max_racines <- 200.0; //cm // Renaud 30052023
// ----------------------------------------- VARIABLES AQYIELD N -----------------------------------------
	string Type_Nacq <- "";// type de formalisme pour l'acquisition d'azote : Cst, FloMat, CstFloMat, 500Mat, CI, CI_frein (ref AqYieldN)
	float besoin_N <- 0.0; 
	float besoin_N_total <- 0.0; // Besoin total en N pour la betterave et la pomme de terre, ces besoins ne dependent pas du rendement
	float QNmax <- 0.0;
	bool point_inflexion_N <- false; // Décrit la forme de la courbe de besoin en N. True signifie qu'il y a un point d'inflexion
	int debut_besoin_N <- 0;
	float frein_besoin_N <- 0.0;
	float pre_floraison_besoin_N <- 0.0;
	float pre_maturite_besoin_N <- 0.0;
	
	float Tms <- 0.0; // Teneur en matière sèche (AMG)
	float IRv <- 0.0; // MS grain / MS (chaumes + pailles + balle +rachis + grain) OU MS racine récoltée / MS (feuilles + collets) (AMG)
	float aa <- 0.0; // MS collets / MS (feuilles + collets) (AMG)
	float bb <- 0.0; // MS racinaire non récolté sur 0-30 cm / MS racinaire totale (AMG)
	float ratio_R <- 0.0; // MS racinaire non récoltée / MS totale (AMG)
	float C_aer <- 0.0;
	float C_rac;
	float CN_aer <- 0.0;
	float CN_rac <- 0.0;
	bool isLEG <- false; // espèce is légumineuse ?
	bool isCouvert <- false; // L'espèce est-elle un couvert intermédiaire ?
	float abscission <- 0.0;
	bool isCultureRacine <- false; // TODO Renaud 180624 - couplage filiere/agricole --> A voir si on garde ou pas
	
	// Parameters from AMG  for calculating C and N inputs from crop residues
	float HI <- 0.0;
	float Pse <- 0.0;
	float beta <- 0.0;
	float SR_ratio <- 0.0;
	float RootC_fixed <- 0.0;
	float CN_ratio <- 0.0;
	
	// Paramètres pour l'estimation de la biomasse des couverts (cf "20191126_CR.docx" p. 15-16 - compte rendu de Laurène)
	float adil <- 0.0;// parameter a for N to biomass conversion of cover crops (ref STICS)
	float bdil <- 0.0;// parameter b for N to biomass conversion of cover crops (ref STICS)	
	float a_Ndemand_ci <- 0.0;// parameter a for N acquisition, only apply to 'CI' type
	float b_Ndemand_ci <- 0.0;// parameter b for N acquisition, only for 'CI' type
	float coef_500Mat <- 0.0;// parameter for N acquisition, only for '500Mat' type
	float Dde <- 0.0;// parameter for calculating emergence duration of cover crops, applies only for 'CI' or 'CIfrein' types
	float N_grain <- 0.0;// N content of grain in % of DM

// ----------------------------------------- stressClimatique -----------------------------------------
	float degresJourStadeJuvenile <- 0.0;
	float degresJourDureeFloraison <- 0.0;
	float degresJourDebutRemplissage;
	float tgelLev10;
	float tgelLev90;
	float tgelJuv10;
	float tgelJuv90;
	float tgelVeg10;
	float tgelVeg90;
	float tgelFlo10;
	float tgelFlo90;
	
	
// ----------------------------------------- YieldSafe -----------------------------------------

	bool isCI{
		return ((idEspeceCultivee index_of PREFIXE_CI)=0);
	}	

	bool isGel {
		return (idEspeceCultivee="gel");
	}

}
