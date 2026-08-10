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
 *  Engrais
 *  Author: Renaud Misslin
 *  Description: Les agents Engrais (engrais minéraux ou PRO (Produits Résiduaires Organiques)) sont caractérisés par plusieurs valeurs de paramètres susceptibles de changer d'un terrain à l'autre
 */

model Engrais

import "engraisForcageAnnuel.gaml"
import "../../modeleCommun/dateCourante.gaml"

global{
	string cheminTypeEngrais <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/Engrais/Engrais.csv';
	list<Engrais> listeEngraisParOrdreSaisie <- []; 
	map<string,Engrais> mapEngraisParId <- map([]); 
	map<string,float> quantites_engrais_annuelles;
	
	// nom de l'engrais => chemin vers le fichier de forçage
	map<string, string> cheminEngraisAForcer <- [
		//"digestat liquide":: '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + "/modeleAgricole/Engrais/digestat_liquide.csv"
	];
	map<string,EngraisForcageAnnuel> engraisAForcer;
	
	init {
		/* Instanciation des engrais dont la composition est forcée par année */
		loop nom_engrais over: cheminEngraisAForcer.keys {
			string chemin <- cheminEngraisAForcer[nom_engrais];
			create EngraisForcageAnnuel with: ["chemin_donnees"::chemin] returns: _engraisForcageAnnuel;
			engraisAForcer[nom_engrais] <- first(_engraisForcageAnnuel);
		} 
	}

	/*
	 * *****************************************************************************************
	 * Publique
	 * Lecture du fichier type_culture.csv pour initialiser tous les types de culures
	 * Inversion des lignes et des colones
	 */
	action constructionEngrais {	
		
		if !file_exists(cheminTypeEngrais) {do raiseError("fichier inexistant: " + cheminTypeEngrais);}
		
		matrix initDataTypeEngrais <- matrix(csv_file (cheminTypeEngrais,";",false)); 
		//matrix initDataTypeEngrais <- matrix(file (cheminTypeCulture)); 	
       	int nbColones <- length(initDataTypeEngrais row_at 0);
       	
		loop i from: 1 to: ( nbColones - 1 ) {
			list<string> coloneCourante <- (initDataTypeEngrais column_at i) as list<string>;
			if((coloneCourante at 1) != nil){
				create Engrais {
					nomEngrais <- coloneCourante at 0;
					listeEngraisParOrdreSaisie << self;
					put self at: nomEngrais in: mapEngraisParId;
					put 0.0 at: nomEngrais in: quantites_engrais_annuelles;
					name <- nomEngrais;	
					C <- float(coloneCourante at 1);
					N <- float(coloneCourante at 2);
					Norg <- float(coloneCourante at 3);
					Nmin <- float(coloneCourante at 4) ;	 					
					CNorg <- float(coloneCourante at 5) ;
					hum <- float(coloneCourante at 6) ;
					K1 <- float(coloneCourante at 7) ;
					C2 <- float(coloneCourante at 8) ; //proportions of organic amendment C in the recalcitrant pools (RES2 dans Levavasseur 2020)
					kres1 <- float(coloneCourante at 9) ;
					kres2 <- float(coloneCourante at 10) ;
					kbio <- float(coloneCourante at 11) ;
					CNbio <- float(coloneCourante at 12) ;
					aCN1 <- float(coloneCourante at 13) ;
					Y <- float(coloneCourante at 14) ;
					H <- float(coloneCourante at 15) ;
					ETM_Cd <- float(coloneCourante at 16) ;
					ETM_Cu <- float(coloneCourante at 17) ;
					ETM_Ni <- float(coloneCourante at 18) ;
					ETM_Pb <- float(coloneCourante at 19) ;
					ETM_Zn <- float(coloneCourante at 20) ;
					ETM_Hg <- float(coloneCourante at 21) ;
					ETM_Cr <- float(coloneCourante at 22) ;
					Fertilizer_type <- coloneCourante at 23 ;
					EF_normal_pH <- float(coloneCourante at 24) ;
					EF_high_pH <- float(coloneCourante at 25) ;
					EF <- float(coloneCourante at 26);
					Fertilizer_form <- coloneCourante at 27;
					eqCO2_N <- float(coloneCourante at 28);
					eqCO2_P <- float(coloneCourante at 29);
					eqCO2_K <- float(coloneCourante at 30);
					eqCO2_PRO <- float(coloneCourante at 31);
					coutT <- float(coloneCourante at 32);
					quantiteDispoAnnuelleKg <- float(coloneCourante at 33);//
					quantiteDispoKg <- quantiteDispoAnnuelleKg;
					concerneParPlanEpandage <- bool(coloneCourante at 34);//					
				}
			}			
		}
	}
}

species Engrais {
	string nomEngrais <- "";
	rgb couleur <- rgb("white");		
	float C <- 0.0; // Part de carbone (% Matière brute)
	float N <- 0.0; // Part d'azote (% Matière brute)
	float Norg <- 0.0; // Part d'azote organique (% Matière brute)
	float Nmin <- 0.0; // Part d'azote minéral (% Matière brute)
	float CNorg <- 0.0; // C/N de l'azote organique (% Matière brute)
	float hum <- 0.0; // ??
	float K1 <- 0.0;
	float C2 <- 0.0; 
	float kres1 <- 0.0; 
	float kres2 <- 0.0; 
	float kbio <- 0.0;
	float CNbio <- 0.0; 
	float aCN1 <- 0.0;
	float Y <- 0.0; // Hres
	float H <- 0.0; // Yres
	float ETM_Cd <- 0.0; // Cadmium
	float ETM_Cu <- 0.0; // Cuivre
	float ETM_Ni <- 0.0; // Nickel
	float ETM_Pb <- 0.0; // Plomb
	float ETM_Zn <- 0.0; // Zinc
	float ETM_Hg <- 0.0; // Mercure
	float ETM_Cr <- 0.0; // Chrome
	string Fertilizer_type <- "";// mineral or organic
	string Fertilizer_form <- ""; // solid or liquid
	float EF_normal_pH <- 0.0; // NH3 emission factor for mineral fertilizers at pH <= 7.0
	float EF_high_pH <- 0.0; // NH3 emission factor for mineral fertilizers at pH > 7.0
	float EF <- 0.0; // NH3 emission factor for organic fertilizer
	float eqCO2_N <- 0.0; // kg CO2 equivalent per kg of element for fertilizer synthesis and transport
	float eqCO2_P <- 0.0; // kg CO2 equivalent per kg of element for fertilizer synthesis and transport
	float eqCO2_K <- 0.0; // kg CO2 equivalent per kg of element for fertilizer synthesis and transport
	float eqCO2_PRO <- 0.0; // kg CO2 equivalent per t of EOM product for storage and transport
	float quantiteDispoAnnuelleKg <- 0.0;// Kg
	float quantiteDispoKg <- 0.0;// Kg
	float coutT <- 0.0;
	bool concerneParPlanEpandage;
	
	reflex MAJ_annuelle_stocks when: (first(dateCourante).mois = 1 and first(dateCourante).jour = 1) {
//    	write "Mise à jour des stocks d'engrais";
//    	write nomEngrais + " --> Ancien stock = " + quantiteDispoKg;

		// RM 040425 Forcage des engrais à partir d'un fichier d'entrée (formation dev 03/2025, proposition d'Hadrien et Elsa)
    	if (nomEngrais in engraisAForcer.keys) {
    		write "Forcage de " + nomEngrais + " --> Ancien stock = " + quantiteDispoKg;
    		ask engraisAForcer[nomEngrais] {
    			write composition[dateCour.annee];
    			myself.quantiteDispoKg <- composition[dateCour.annee]["quantiteDispoKgParAnnee"];
    			myself.C <- composition[dateCour.annee]["C"];
    			myself.N <- composition[dateCour.annee]["N"];
    			myself.Norg <- composition[dateCour.annee]["Norg"];
    			myself.Nmin <- composition[dateCour.annee]["Nmin"];
    			myself.CNorg <- composition[dateCour.annee]["CNorg"];
    		}
    		
    	} else {
    		quantiteDispoKg <- quantiteDispoAnnuelleKg;
    	}
    	if verboseMode {write nomEngrais + " --> Nouveau stock = " + quantiteDispoKg;}    		
	}
	
/*	reflex ecriture_console_quantites {
		if (nomEngrais = "lisier bovin") {
			write "---------";
			write "Stocks lisier bov = " + quantiteDispoKg + " sur " + quantiteDispoAnnuelleKg;
			write "Quantités utilisée = " + quantites_engrais_annuelles[nomEngrais];
		}

	}
*/
}
