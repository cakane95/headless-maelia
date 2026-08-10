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
 *  cheptelBovinLait
 *  Author: Theo Bullat
 *  Description: 
 */

model cheptelBovinLait
import "../../../modeleCommun/donneesGlobales.gaml"
import "femelles0_1an.gaml"
import "femelles1_2ans.gaml"
import "femelles2_3ans.gaml"
import "vachesLaitiere.gaml"
import "males0_1an.gaml"

global {
	string cheminDescriptionElevage  <- cheminModeleVersDonnees +
	 '/Aveyron/modeleAgricole/agriculteurs/descriptionElevage.csv' ;
	string cheminCalendrierVentes  <- cheminModeleVersDonnees +
	 '/Aveyron/modeleAgricole/agriculteurs/calendrierVentes.csv' ;
	string cheminRepartitionVelage  <- cheminModeleVersDonnees +
	 '/Aveyron/modeleAgricole/agriculteurs/repartitionVelageBL.csv' ;
	string cheminDescriptionSemainesVelages  <- cheminModeleVersDonnees +
	 '/Aveyron/modeleAgricole/agriculteurs/distributionDesVelagesSemaines.csv' ;

//	string cheminDescriptionElevage  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/descriptionElevage.csv' ;
//	string cheminCalendrierVentes  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/calendrierVentes.csv' ;
//	string cheminRepartitionVelage  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/repartitionVelageBL.csv' ;
//	string cheminDescriptionSemainesVelages  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/distributionDesVelagesSemaines.csv' ;
	
	map<string,matrix> calendrierVentesBL <- map([]);
	map<string,matrix> calendrierEvolutionBL <- map([]);
	map<string,map<string,float>> descriptionDuCheptelBL;
	map<string,list> repartitionVelage <- map([]);
	map<string,map<int,matrix>> tableauEffectifBL <- map([]);

	map<string,list> repartitionVelageMultiSemainesBL <- map([]);
	map<string,list> repartitionVelagePrimiSemainesBL <- map([]);
	
//	init{
//		do constructionCheptelBL;
//	}
	
	action constructionCheptelBL{
		do lectureFichierDescriptionBL(cheminDescriptionElevage,descriptionDuCheptelBL);
		do lectureCalendrierVenteBL(cheminCalendrierVentes,calendrierVentesBL);
		do lectureFichierRepartitionBL(cheminRepartitionVelage, repartitionVelage);
		do lectureFichierRepartitionSemainesBL(cheminDescriptionSemainesVelages,repartitionVelageMultiSemainesBL,repartitionVelagePrimiSemainesBL);
		loop ID over:descriptionDuCheptelBL.keys {
			create cheptelBovinLait with:[IDexploitation::ID];
			ask last(cheptelBovinLait) {
				write "\t\t--------------- "+ID+" ----------------";
				map<string,float> descriptionTmp <- descriptionDuCheptelBL[ID];
				matrix calendrierVentesTmp <- calendrierVentesBL[ID];
				list<int> repartitionVelageTmp <- repartitionVelage[ID];
				map<int,matrix> tableauEffectifTmp <- tableauEffectifBL[ID];
				list<int> repartitionVelageMultiSemainesTmp <- repartitionVelageMultiSemainesBL[ID];
				list<int> repartitionVelagePrimiSemainesTmp <- repartitionVelagePrimiSemainesBL[ID];
				do mis_a_jour(descriptionTmp);
				do constructionEffectif(descriptionTmp, calendrierVentesTmp, repartitionVelageTmp, tableauEffectifTmp,repartitionVelageMultiSemainesTmp,repartitionVelagePrimiSemainesTmp);
				do presentation;
			}	
		}
	}
	
	
	action lectureFichierRepartitionBL (string Chemin, map<string,list> repartitionVelage){
		matrix Init <- matrix(csv_file(Chemin,";",false));
		//matrix Init <- matrix(file(Chemin));
		int nbLigne <- length(Init column_at 0);
		string ID <- "";
		loop ligne from: 1 to: nbLigne -1 step: 1{
			ID <- string(Init at {0,ligne});
			if descriptionDuCheptelBL[ID] != nil {
				list repartition <- [];
				loop mois from:1 to:12{
					add Init at {mois,ligne} to: repartition;
				}
				put repartition at: ID in: repartitionVelage;
			}
		}
	} 
	
	action lectureFichierDescriptionBL (string Chemin, map<string,map<string,float>>descriptionDuCheptel){
		matrix Init <- matrix(csv_file(Chemin,";",false));
		write "Init constructionCheptelBL : " + Init;		
		//matrix Init <- matrix(file(Chemin));
		//BEN write "lectureFichierDescriptionBL : Init \n" + Init;
		list listCheptel <-  ( Init column_at 0 );
		list listDescriptionDuCheptel <- ( Init row_at 0);
		loop j from: 1 to: length(listCheptel)-1 step: 1 {
			if string(Init at {0,j}) contains "BL"{
				map<string,float> descriptionDuCheptelTMP <- map<string,float>([]);
				list ligneCourante <-  ( Init row_at j );
				loop i from: 1 to: length(listDescriptionDuCheptel)-1 step: 1 { 
					put float(ligneCourante at (i)) at: listDescriptionDuCheptel[i] in:descriptionDuCheptelTMP ; 
				}
				put descriptionDuCheptelTMP at: first(string(listCheptel[j]) split_with "BL") in: descriptionDuCheptel;
			}
		}
		write "descriptionDuCheptel : " + descriptionDuCheptel;		
	}
	
	action lectureCalendrierVenteBL (string Chemin,map<string,matrix> calendrierVentes){
		matrix Init <- matrix(csv_file(Chemin,";",false));
		//matrix Init <- matrix(file(Chemin));
		write "lectureCalendrierVenteBL : Init \n" + Init;		
		int nbLigne <- length(Init column_at 0);
		loop ID over: descriptionDuCheptelBL.keys{
			matrix calendrierVentesTMP <- matrix([	[0,0,0,0,0,0,0,0,0,0,0,0],	//VachesLaitieres
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Genisses+2ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Genisses1-2ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Genisses0-1an
													[0,0,0,0,0,0,0,0,0,0,0,0]	//Males0-3mois
												]);			
			put calendrierVentesTMP at: ID in: calendrierVentes;
		}
		loop j from: 1 to: nbLigne -1 step: 1 {
			string ID <- first(string(Init at {0,j})split_with "BL");
			if descriptionDuCheptelBL[ID] != nil {
				loop i from: 2 to: 13{
					int categorie <- positionDeCategorieBL(string(Init at {1,j}));
					put int(Init at {i,j}) at: {categorie,i-2} in: calendrierVentes[ID];
				}
			}
		}
		write "repartitionVelage  " + repartitionVelage;		
	}
	
		
	action lectureFichierRepartitionSemainesBL(string chemin, map<string,list> repartitionVelageMultiSemaines, map<string,list> repartitionVelagePrimiSemaines){
		matrix Init <- matrix(csv_file(chemin,";",false));
		//matrix Init <- matrix(file(chemin));
		// BEN 
		write "lectureFichierRepartitionSemainesBL : Init \n" + Init;	
					
		int nbLigne <- length(Init column_at 0);
		loop j from: 1 to: nbLigne -1 step: 1 {
			string ID <- first(string(Init at {0,j}) split_with "BL");
			if descriptionDuCheptelBL[ID] != nil {
				string type <- string(Init at {1,j});
				list<int> repartitionSemaines <- [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];			
				switch type{
					match "multi"{
						loop i from: 2 to: 49{
							put int(Init at {i,j}) at: i-2 in: repartitionSemaines;
						}
						put repartitionSemaines at: ID in: repartitionVelageMultiSemaines;
					}
					match "primi"{
						loop i from: 2 to: 49{
							put int(Init at {i,j}) at: i-2 in: repartitionSemaines;
						}
						put repartitionSemaines at: ID in: repartitionVelagePrimiSemaines;
					}
				}
			}
		}
		write "repartitionVelagePrimiSemaines : " + repartitionVelagePrimiSemaines;	
		write "repartitionVelageMultiSemaines : " + repartitionVelageMultiSemaines;	
	}
	
	int positionDeCategorieBL(string nom){
		switch nom {
			match "VachesLaitieres" {
				return 0;
			}
			match "Genisses+2ans" {
				return 1;
			}
			match "Genisses1-2ans" {
				return 2;
			}
			match "Genisses0-1an" {
				return 3;
			}
			match "Males0-3mois" {
				return 4;
			}
		}
	}
	
}

species cheptelBovinLait {
	string IDexploitation;
													
	int NBVELAGE;
	
	int VeauxSevresM;
	int VeauxSevresPurM;
	int VeauxSevresCroisesM;
	int VeauxSevresF;
	int VeauxSevresPurF;
	int VeauxSevresCroisesF;

	int VeauxNes;
	int VeauxMorts;
	int VeauxFNes;
	int VeauxMNes;
	int VeauxMMort;
	int VeauxFMort;
	
	int NbVaches;
	int NbVachesRepro;
	int NbVachesRenouv;
	int NbVachesLL;
	
	int NbTaureau;    
	
	femelles01an sesFemelles01an;                  
    femelles12ans sesFemelles12ans;
    femelles23ans sesFemelles23ans;                  
    vachesLaitiere sesVachesLaitiere; 
	males01an sesMales01an;
	

	action naissance(map<string,float> descriptionDuCheptel) {
		NBVELAGE <- int(descriptionDuCheptel["Nbvelage"]);
		VeauxNes <- round(NBVELAGE * descriptionDuCheptel["TAUXPROLIFREF"]/100);
		VeauxFNes <- int(VeauxNes*(100-descriptionDuCheptel["SEXERATIO"])/100);
		VeauxMNes <- VeauxNes - VeauxFNes;
	}
	
	action deces(map<string,float> descriptionDuCheptel) {
		VeauxMorts <- round(VeauxNes * (descriptionDuCheptel["TAUXMORTREF"]/100));
		VeauxMMort <- round(VeauxMorts * (descriptionDuCheptel["SEXERATIO"])/100);
		VeauxFMort <- VeauxMorts - VeauxMMort;
	}
	
	action sevrage{
		VeauxSevresM <- (VeauxMNes - VeauxMMort);
		VeauxSevresF <- (VeauxFNes - VeauxFMort);
	}
	
	action calculCroisement(map<string,float> descriptionDuCheptel) {
		VeauxSevresCroisesM <- round(VeauxSevresM * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresCroisesF <- round(VeauxSevresF * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresPurM <- VeauxSevresM - VeauxSevresCroisesM;
		VeauxSevresPurF <- VeauxSevresF - VeauxSevresCroisesF;
	}
	
	//			------------ Vaches -------------
	
	action NombreVaches(map<string,float> descriptionDuCheptel) {
		if descriptionDuCheptel["TAUXGESTREF"]>0{
			NbVachesRepro <- round(NBVELAGE / (descriptionDuCheptel["TAUXGESTREF"]/100));
		}
		if descriptionDuCheptel["TAUXREPROREF"]>0{
			NbVaches <- round(NbVachesRepro / (descriptionDuCheptel["TAUXREPROREF"]/100)*(descriptionDuCheptel["IVV"]/12));
		}
		NbVachesRenouv <- round(NBVELAGE * (descriptionDuCheptel["TAUXRENOUVREF"]/100));
		NbVachesLL <- NbVaches - NBVELAGE;	
	}
	
	//			------------ Taureau -------------
	
	action NombreTaureau(map<string,float> descriptionDuCheptel) {		
		if (descriptionDuCheptel["NBVACHETAUREF"] > 0){
			NbTaureau <- int(round(NbVachesRepro / descriptionDuCheptel["NBVACHETAUREF"]) * (1-(descriptionDuCheptel["POURCIAREF"]/100)));			
		}else {
			NbTaureau <- 0;
		}
		if (NbTaureau > 0 and descriptionDuCheptel["TAUXGESTREF"] > 0 and descriptionDuCheptel["POURCIAREF"] < 100.0){
			descriptionDuCheptel["NBVACHETAUREF"] <- int(round(NBVELAGE / descriptionDuCheptel["TAUXGESTREF"] * 100.0)/(NbTaureau/(1-descriptionDuCheptel["POURCIAREF"]/100)));
		}else {
			descriptionDuCheptel["NBVACHETAUREF"] <- 0;
		}
	}
	
	
	action mis_a_jour(map<string,float> descriptionDuCheptel){
		
		// -------- Veaux ---------
		
		do naissance(descriptionDuCheptel);
		do deces(descriptionDuCheptel);
		do sevrage();
		do calculCroisement(descriptionDuCheptel);
			
		// -------- Vaches ---------
		
		do NombreVaches(descriptionDuCheptel);
		
		// -------- Taureau --------
		
		do NombreTaureau(descriptionDuCheptel);
	}
	
	action constructionEffectif(map<string,float> descriptionDuCheptel, matrix calendrierVentes, list<int> repartitionVelage, map<int,matrix> tableauEffectif, list<int> repartitionVelageMultiSemaines, list<int> repartitionVelagePrimiSemaines){
		int agePremierVelage <- int(descriptionDuCheptel["AGEPREMIREVELAGE"]);
		bool isVelagePrecoce <- true;
		if agePremierVelage=36{
			isVelagePrecoce <- false;
		}
		do initialiserTableauEffectif(tableauEffectif, repartitionVelage, calendrierVentes, descriptionDuCheptel["IVV"],isVelagePrecoce);
		do initialiserNaissance(tableauEffectif,descriptionDuCheptel);
		do changementCategorieNaissance(tableauEffectif[3]);
		do changementCategorieNaissance(tableauEffectif[4]);
		do changementCategorieDesBovins(tableauEffectif[3],tableauEffectif[2],12,isVelagePrecoce);
		if !isVelagePrecoce{
			do changementCategorieDesBovins(tableauEffectif[2],tableauEffectif[1],12,!isVelagePrecoce);
		}
		loop categorie from: 1 to: 4{
			do genererEffectifBovin(tableauEffectif[categorie]);
		}
		do genererEffectifMultiPrimi(tableauEffectif[0]);
		do genererAgents(tableauEffectif,descriptionDuCheptel["IVV"],repartitionVelageMultiSemaines,repartitionVelagePrimiSemaines);
	}
	
	
	action initialiserTableauEffectif(map<int,matrix> tableauEffectif, list<int> repartitionVelage,matrix calendrierVentes,int IVV,bool velagePrecoce){
		loop type from:0 to:4{
			matrix effectif <- matrix([	[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0]
									]);
			loop mois from:0 to:11{
				put int(calendrierVentes at {type,mois}) at: {1,mois} in:effectif;
				if type = 0 {
					put (repartitionVelage at mois) at:{3,mois} in: effectif;
				}
			}
			put effectif at: type in: tableauEffectif;
		}
		do genererVelageMulti(tableauEffectif[0],IVV);
		do genererSortiesPourPremierVelage(tableauEffectif,repartitionVelage,velagePrecoce);
	}
	
	// genere les velages multi à partir des velages de primi et de l'IVV
	action genererVelageMulti(matrix tableauEffectif, int IVV){
		int moisDebutVelage <- recupererPremierMoisVelage(tableauEffectif);
		int velageRestant <- NBVELAGE;
		int nbVelagePrimi <- 0;
		int taille <- length(tableauEffectif column_at 3);
		int annee <- 0;
		loop mois from: 0 to: taille{
			nbVelagePrimi <- nbVelagePrimi + int(tableauEffectif at {3,mois});
		}
		velageRestant <- velageRestant - nbVelagePrimi;
		loop while: velageRestant > 0 {
			annee <- annee +1;
			loop mois from: moisDebutVelage to: taille + moisDebutVelage{
				int effectifVelagePrimi <- int(tableauEffectif at {3,mois});
				int ancienneValeur <- (tableauEffectif at {2,(mois+annee*IVV/30.4)mod 12});
				velageRestant <- velageRestant - effectifVelagePrimi;
				if velageRestant < 0 {
					put ancienneValeur + effectifVelagePrimi + velageRestant at: {2,(mois+annee*IVV/30.4)mod 12} in: tableauEffectif;
					velageRestant <- 0;					
				}else{
					put ancienneValeur + effectifVelagePrimi at: {2,(mois+annee*IVV/30.4)mod 12} in: tableauEffectif;
				}
			}
		}
	}
	
	// genere le passage des génisses en primi, sur la ligne "sortie" correspondante
	action genererSortiesPourPremierVelage(map<int,matrix> tableauEffectif, list<int> local_repartitionVelage, bool velagePrecoce){
		int categorie <- 1;
		if velagePrecoce{
			categorie <- 2;
		}
		loop mois from:0 to: 11{
			put (local_repartitionVelage at mois) at:{2,mois} in: tableauEffectif[categorie];
		}
	}
	
	action initialiserNaissance(map<int,matrix> tableauEffectif, map<string,float> descriptionDuCheptel){
		int sommeF <- 0;
		int sommeM <- 0;
		loop mois from:0 to:11{
			int velageMul <- int(tableauEffectif[0] at {2,mois});
			int velagePri <- int(tableauEffectif[0] at {3,mois});
			int velageF <- int((velageMul+velagePri)*descriptionDuCheptel["SEXERATIO"]/100);
			int velageM <- int((velageMul+velagePri)*(100-descriptionDuCheptel["SEXERATIO"])/100);
			sommeF <- sommeF + velageF;
			put velageF at:{3,mois} in: tableauEffectif[3];
			sommeM <- sommeM + velageM;
			put velageM at:{3,mois} in: tableauEffectif[4];
		}
		do correctionNaissanceEtmortalite(tableauEffectif[3],sommeF,VeauxSevresF);
		do correctionNaissanceEtmortalite(tableauEffectif[4],sommeM,VeauxSevresM);
	}
	
	// Ajout des naissances manquantes,  sur le debut des velages.
	action correctionNaissanceEtmortalite(matrix tableauEffectif,int somme,int veauxSevres){
		int veauxMort <- somme-veauxSevres;
		loop while: veauxMort != 0{
			int mois <- any([0,1,2,3,4,5,6,7,8,9,10,11]);
			int ancienneValeur <- tableauEffectif at {3,mois};
			if ancienneValeur != 0{
				if veauxMort < 0 {
					put ancienneValeur + 1 at: {3,mois} in: tableauEffectif;
					veauxMort <- veauxMort + 1;
				}else{
					put ancienneValeur - 1 at: {3,mois} in: tableauEffectif;
					veauxMort <- veauxMort - 1;
				}
			}
		}
	}
	
	//Permet de recuperer le mois de velage où se trouve les vaches les plus jeunes
	int recupererPremierMoisVelage(matrix tableauEffectif){
		int moisDebutVelage <- 0;
		int protectionInfini <- 0;
		int valueTest <- tableauEffectif at {3,moisDebutVelage mod 12};
		// On avance jusqu'a ce qu'on tombe sur un mois de velage
		loop while: valueTest = 0 {
			moisDebutVelage <- moisDebutVelage + 1;
			valueTest <- tableauEffectif at {3,moisDebutVelage mod 12};
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 1;
			}
		}
		// On recul jusqu'au dernier mois sans velage
		loop while: tableauEffectif at {3,(moisDebutVelage+12)mod 12} != 0 {
			// correspond à mois <- mois - 1
			moisDebutVelage <- (moisDebutVelage + 11) mod 12 ;
		}
		// On ajoute un pour obtenir le premier mois de velage.
		return (moisDebutVelage+1) mod 12;
	}
	
	//Changement de categorie en se basant sur le temps de sevrage
	action changementCategorieNaissance(matrix tableauEffectif){
		int sommeVentes <- 0;
		loop mois from: 0 to: 11{
			int naissance <- tableauEffectif at {3,mois};
			put naissance at: {2, mois mod 12} in:tableauEffectif;
			sommeVentes <- sommeVentes + int(tableauEffectif at {1,mois});
		}
		do suppressionDesVentesAuxSorties(tableauEffectif,sommeVentes);
	}
	
	action suppressionDesVentesAuxSorties(matrix tableauEffectif,int sommeVentes){
		int dernierMoisSevrage <- recupererDernierMois(tableauEffectif);
		int ancienneValeur <- tableauEffectif at {2,dernierMoisSevrage};
		put ancienneValeur - sommeVentes at: {2,dernierMoisSevrage} in:tableauEffectif;
		int nouvelleValeur <- tableauEffectif at {2,dernierMoisSevrage};
		int decalage <- 0;
		loop while: nouvelleValeur < 0 {
			decalage <- decalage + 1;
			put 0 at: {2,(dernierMoisSevrage+13-decalage)mod 12} in:tableauEffectif;
			ancienneValeur <- tableauEffectif at {2,(dernierMoisSevrage+12-decalage)mod 12};
			put ancienneValeur + nouvelleValeur at: {2,(dernierMoisSevrage+12-decalage)mod 12} in:tableauEffectif;
			nouvelleValeur <- tableauEffectif at {2,(dernierMoisSevrage+12-decalage)mod 12};
		}
	}
	
	//Permet de recuperer le mois où se trouve les vaches les plus agées qui vont être vendus afin de les enlever des sorties
	int recupererDernierMois(matrix tableauEffectif){
		int moisDebutVelage <- 0;
		int protectionInfini <- 0;
		int valueTest <- tableauEffectif at {2,(moisDebutVelage+12)mod 12};
		// On recul jusqu'au dernier mois sans velage
		loop while: valueTest = 0 {
			// correspond à mois <- mois - 1
			moisDebutVelage <- (moisDebutVelage + 11) mod 12 ;
			valueTest <- tableauEffectif at {2,(moisDebutVelage+12)mod 12};
			//Permet de sortir de la boucle si l'effectif est vide.
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 1;
			}
		}
		// On avance jusqu'a ce qu'on tombe sur un mois de velage
		loop while: tableauEffectif at {2,moisDebutVelage mod 12} != 0 {
			moisDebutVelage <- moisDebutVelage + 1;
		}
		// On enleve un pour obtenir le premier mois de velage.
		return (moisDebutVelage+11)mod 12;
	}
	
	action changementCategorieDesBovins(matrix tableauEffectifInferieur,matrix tableauEffectifSuperieur,int tempsDeChangement,bool velagePrecoce ){
		loop mois from:0 to: 11 {
			int sortieSevre <- int(tableauEffectifInferieur at {2,mois});
			put sortieSevre at: {3,mois} in: tableauEffectifSuperieur;
		}
		if !velagePrecoce {
			int sommeVentes <- 0;
			loop mois from: 0 to: 11{
				put (tableauEffectifSuperieur at {3,mois}) at: {2,(mois+12-tempsDeChangement)mod 12} in:tableauEffectifSuperieur;
				sommeVentes <- sommeVentes + int(tableauEffectifSuperieur at {1,mois});
			}
			do suppressionDesVentesAuxSorties(tableauEffectifSuperieur,sommeVentes);
		}
	}
	
	
	action genererEffectifMultiPrimi(matrix tableauEffectif){
		int plusGrandEffectif <- 0;
		loop mois from:0 to:11{
			int primi <- int(tableauEffectif at {3,mois});
			int ventes <- int(tableauEffectif at {1,mois});
			int effectifDuMois <- int(tableauEffectif at {0,mois});
			int prochainEffectif <- effectifDuMois + primi - ventes;
			put prochainEffectif at:{0,(mois +1)mod 12} in: tableauEffectif;
			if prochainEffectif > plusGrandEffectif{
				plusGrandEffectif <- prochainEffectif;
			} 
		}
		loop mois from:0 to:11{
			int ancienneValeur <- int(tableauEffectif at {0,mois});
			put ancienneValeur + NbVachesRepro - plusGrandEffectif at: {0,mois} in: tableauEffectif;
		}
	}
	
	action genererEffectifBovin(matrix tableauEffectif){
		int sommeEntree <- 0;
		int plusPetitEffectif <- 0;
		int plusGrandEffectif <- 0;
		int moisDebutVelage <- recupererPremierMoisVelage(tableauEffectif);
		int moisDebutVentesSorties <- recupererPremierMoisVentesSorties(tableauEffectif);
		// On démarre la génération lorsque les ventes ou les entrée débutent
		int moisDepart <- min([moisDebutVelage,moisDebutVentesSorties]);
		loop mois from:0 to:11{
			int entree <- tableauEffectif at {3,(mois+moisDepart)mod 12};
			int sortie <- tableauEffectif at {2,(mois+moisDepart)mod 12};
			int ventes <- tableauEffectif at {1,(mois+moisDepart)mod 12};
			int effectifDuMois <- tableauEffectif at {0,(mois+moisDepart)mod 12};
			int prochainEffectif <- effectifDuMois + entree - sortie - ventes;
			put prochainEffectif at:{0,(mois+moisDepart+1)mod 12} in: tableauEffectif;
			sommeEntree <- sommeEntree + entree;
			if prochainEffectif < plusPetitEffectif{
				plusPetitEffectif <- prochainEffectif;
			} 
			if prochainEffectif > plusGrandEffectif{
				plusGrandEffectif <- prochainEffectif;
			} 
		}
		//Si, les effectifs de deux années successive se croisent, alors on rajoute l'effectif manquant
		if plusPetitEffectif < 0 or plusGrandEffectif = 0 and sommeEntree != 0 or moisDebutVelage = moisDebutVentesSorties{
			loop mois from:0 to:11{
				int ancienneValeur <- int(tableauEffectif at {0,mois});
				put ancienneValeur + sommeEntree at: {0,mois} in: tableauEffectif;
			}
		}
	}
	
	int recupererPremierMoisVentesSorties(matrix tableauEffectif){
		int moisDebutVelage <- 0;
		int protectionInfini <- 0;
		int valueTest <- int(tableauEffectif at {2,moisDebutVelage mod 12}) + int(tableauEffectif at {1,moisDebutVelage mod 12});
		// On avance jusqu'a ce qu'on tombe sur un mois de velage
		loop while: valueTest = 0 {
			moisDebutVelage <- moisDebutVelage + 1;
			valueTest <- int(tableauEffectif at {2,moisDebutVelage mod 12}) + int(tableauEffectif at {1,moisDebutVelage mod 12});
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 1;
			}
		}
		// On recul jusqu'au dernier mois sans velage
		loop while: int(tableauEffectif at {2,(moisDebutVelage+12)mod 12}) + int(tableauEffectif at {1,(moisDebutVelage+12)mod 12}) != 0 {
			// correspond à mois <- mois - 1
			moisDebutVelage <- (moisDebutVelage + 11) mod 12 ;
		}
		// On ajoute un pour obtenir le premier mois de velage.
		return (moisDebutVelage+1)mod 12;
	}
	
	
	action genererAgents(map<int,matrix> tableauEffectif,int IVV,list<int> repartitionVelageMultiSemaines,list<int> repartitionVelagePrimiSemaines){
		matrix<int> matrice <- tableauEffectif[0] as matrix<int>;
		create vachesLaitiere returns: instanceVachesLaitiere with: [effectif::(matrice column_at 0) ,
										ventes_ou_engraissement::(matrice column_at 1),
										distributionVelageMul::(matrice column_at 2),
										distributionVelagePri::(matrice column_at 3),
										repartitionDeLeffectifEnSemaine::repartitionVelageMultiSemaines,
										repartitionDeLeffectifEnSemainePrimi::repartitionVelagePrimiSemaines,
										dureePrimi::IVV			
		];
		sesVachesLaitiere <- first(instanceVachesLaitiere);
		
		matrice <- tableauEffectif[1] as matrix<int>;
		create femelles23ans returns: instanceBovin23ans with: [effectif::(matrice column_at 0),
								ventes_ou_engraissement::(matrice column_at 1),
								sortie::(matrice column_at 2),
								entree::(matrice column_at 3)			
		];
		sesFemelles23ans <- first(instanceBovin23ans);
		
		matrice <- tableauEffectif[2] as matrix<int>;
		create femelles12ans returns: instanceBovin12ans with: [effectif::(matrice column_at 0),
								ventes_ou_engraissement::(matrice column_at 1),
								sortie::(matrice column_at 2),
								entree::(matrice column_at 3)			
		];
		sesFemelles12ans <- first(instanceBovin12ans);
		
		matrice <- tableauEffectif[3] as matrix<int>;
		create femelles01an returns: instanceBovin01an with: [effectif::(matrice column_at 0),
								ventes_ou_engraissement::(matrice column_at 1),
								sortie::(matrice column_at 2),
								entree::(matrice column_at 3)			
		];
		sesFemelles01an <- first(instanceBovin01an);
		
		matrice <- tableauEffectif[4] as matrix<int>;
		create males01an returns: instanceBovinM01an with: [effectif::(matrice column_at 0),
								ventes_ou_engraissement::(matrice column_at 1),
								sortie::(matrice column_at 2),
								entree::(matrice column_at 3)			
		];
		sesMales01an <- first(instanceBovinM01an);
	}	
	
	action presentation{
//		write "IDexploitation "+IDexploitation;
//		write "NBVELAGE "+NBVELAGE;
//			write "\n";	
//		write "VeauxSevresM "+VeauxSevresM;
//		write "VeauxSevresPurM "+VeauxSevresPurM;
//		write "VeauxSevresCroisesM "+VeauxSevresCroisesM;
//		write "VeauxSevresF "+VeauxSevresF;
//		write "VeauxSevresPurF "+VeauxSevresPurF;
//		write "VeauxSevresCroisesF "+VeauxSevresCroisesF;
//			write "\n";
//		write "VeauxNes "+VeauxNes;
//		write "VeauxMorts "+VeauxMorts;
//		write "VeauxFNes "+VeauxFNes;
//		write "VeauxMNes "+VeauxMNes;
//		write "VeauxMMort "+VeauxMMort;
//		write "VeauxFMort "+VeauxFMort;
//			write "\n";
//		write "NbVaches "+NbVaches;
//		write "NbVachesRepro "+NbVachesRepro;
//		write "NbVachesRenouv "+NbVachesRenouv;
//		write "NbVachesLL "+NbVachesLL;
//			write "\n";
//		write "NbTaureau "+ NbTaureau;
//		write "\n--------------------------\n";
		write "\t\t------------ BovinLait --------------";		            
        ask sesVachesLaitiere{
			do presentation();
        }                         
        ask sesFemelles23ans{
        	do presentation();
        }                        
        ask sesFemelles12ans{
        	do presentation();
		}                       
        ask sesFemelles01an{
        	do presentation();
        }                        
        ask sesMales01an {
        	do presentation();
        }                       
	
	}
}

//experiment TestBovinLait type: gui{
//	
//}
