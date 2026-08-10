/**
 *  troupeau
 *  Author: Theo Bullat
 *  Description: Troupeau généré à partir du nombre de vêlage et de plusieurs taux de réference.
 */

model cheptelBovinViande

import "../../../modeleCommun/donneesGlobales.gaml"
import "veauxFemellesAvantSevrage.gaml"
import "femelles0_1an.gaml"
import "femelles1_2ans.gaml"
import "femelles2_3ans.gaml"
import "veauxMalesAvantSevrage.gaml"
import "males0_1an.gaml"
import "males1_2ans.gaml"
import "males2_3ans.gaml"
import "malesPlus3ans.gaml"
import "velagePrimi.gaml"

global {
	string cheminDescriptionElevage  <-  '' + cheminModeleVersDonnees +
	 'Aveyron/modeleAgricole/agriculteurs/descriptionElevage.csv' ;
	string cheminCalendrierVentes  <-  '' + cheminModeleVersDonnees +
	 'Aveyron/modeleAgricole/agriculteurs/calendrierVentes.csv' ;
	string cheminDescriptionVelagePrimi <-  '' + cheminModeleVersDonnees +
	 'Aveyron/modeleAgricole/agriculteurs/repartitionVelageBVPrimiV2.csv' ;
	 string cheminDescriptionSemainesVelages  <- cheminModeleVersDonnees +
	 'Aveyron/modeleAgricole/agriculteurs/distributionDesVelagesSemaines.csv' ;
	 
//	string cheminDescriptionElevage  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/descriptionElevage.csv' ;
//	string cheminCalendrierVentes  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/calendrierVentes.csv' ;
//	string cheminDescriptionVelagePrimi  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/repartitionVelageBVPrimiV2.csv' ;
//	string cheminDescriptionSemainesVelages  <- cheminModeleAvecUnSousRepertoireVersDonnees +
//	 '/Aveyron/modeleAgricole/agriculteurs/distributionDesVelagesSemaines.csv' ;
	 
	map<string,matrix<int>> calendrierVentes <- map([]);														
	map<string,matrix> calendrierEvolution <- map([]);
	map<string,map<string,float>> descriptionDuCheptelBV;
	map<string,list<int>> repartitionVelagePrimi <- map([]);
	map<string,map<int,matrix<int>>> tableauEffectifBV <- map([]);
	
	map<string,list> repartitionVelageMultiSemainesBV <- map([]);
	map<string,list> repartitionVelagePrimiSemainesBV <- map([]);

//	init{
//		do constructionCheptelBV;
//	}																		
						
	action constructionCheptelBV{
		do lectureFichierDescription(cheminDescriptionElevage,descriptionDuCheptelBV);
		do lectureCalendrierVenteBV(cheminCalendrierVentes,calendrierVentes);
		do lectureFichierRepartition(cheminDescriptionVelagePrimi,repartitionVelagePrimi);
		do lectureFichierRepartitionSemaines(cheminDescriptionSemainesVelages,repartitionVelageMultiSemainesBV,repartitionVelagePrimiSemainesBV);
		loop ID over:descriptionDuCheptelBV.keys {
			create cheptelBovinViandeV2 with:[IDexploitation::ID];
			ask last(cheptelBovinViandeV2) {
				map<string,float> descriptionTmp <- descriptionDuCheptelBV[ID];
				matrix<int> calendrierVentesTmp <- calendrierVentes[ID];
				list<int> repartitionVelageTmp <- repartitionVelagePrimi[ID];
				map<int,matrix<int>> tableauEffectifTmp <- tableauEffectifBV[ID];
				list<int> repartitionVelageMultiSemainesTmp <- repartitionVelageMultiSemainesBV[ID];
				list<int> repartitionVelagePrimiSemainesTmp <- repartitionVelagePrimiSemainesBV[ID];
//				write "\t\t--------------- "+ID+" ----------------";
				do mis_a_jour(descriptionTmp);
				do constructionEffectif(descriptionTmp,calendrierVentesTmp,repartitionVelageTmp,tableauEffectifTmp,repartitionVelageMultiSemainesTmp,repartitionVelagePrimiSemainesTmp);
			}	
		}
	}
	//			------------ Initialisation -----------------
	
	action lectureFichierDescription (string Chemin, map<string,map<string,float>>descriptionDuCheptel){
		matrix Init <- matrix(csv_file(Chemin,";",false));
		//matrix Init <- matrix(file(Chemin));
		list listCheptel <-  ( Init column_at 0 );
		list listDescriptionDuCheptel <- ( Init row_at 0);
		loop j from: 1 to: length(listCheptel)-1 {
			if string(Init at {0,j}) contains "BV"{
				map<string,float> descriptionDuCheptelTMP <- map<string,float>([]);
				list ligneCourante <-  ( Init row_at j );
				loop i from: 1 to: length(listDescriptionDuCheptel)-1{ 
					put float(ligneCourante at (i)) at: listDescriptionDuCheptel[i] in:descriptionDuCheptelTMP ; 
				}
				put descriptionDuCheptelTMP at: first(string(listCheptel[j]) split_with "BV") in: descriptionDuCheptel;
			}
		}
	}
	
	action lectureFichierRepartition (string Chemin, map<string,list> repartitionVelage){
		matrix Init <- matrix(csv_file(Chemin,";",false));		
		//matrix Init <- matrix(file(Chemin));
		int nbLigne <- length(Init column_at 0);
		string ID <- "";
		loop ligne from: 1 to: nbLigne -1{
			ID <- string(Init at {0,ligne});
			if descriptionDuCheptelBV[ID] != nil {
				list<int> repartition <- [];
				loop mois from:1 to:12{
					add Init at {mois,ligne} to: repartition;
				}
				put repartition at: ID in: repartitionVelage;
			}
		}
	} 
	
	action lectureCalendrierVenteBV (string Chemin, map<string,matrix> calendrierVentes){
		matrix Init <- matrix(csv_file(Chemin,";",false));		
		//matrix Init <- matrix(file(Chemin));
		int nbLigne <- length(Init column_at 0);
		loop ID over: descriptionDuCheptelBV.keys{
			matrix calendrierVentesTMP <- matrix([	[0,0,0,0,0,0,0,0,0,0,0,0],	//VeauxMâles avant sevrage
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Mâles 0-1 an
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Mâles 1-2 ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Mâles 2-3 ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Mâles +3 ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//VeauxFemelles avant sevrage
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Femelles 0-1 an
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Femelles 1-2 ans
													[0,0,0,0,0,0,0,0,0,0,0,0],	//Femelles 2-3 ans
													[0,0,0,0,0,0,0,0,0,0,0,0]	//Femelles +3 ans
												]);			
			put calendrierVentesTMP at: ID in: calendrierVentes;
		}
		loop j from: 1 to: nbLigne -1 step: 1 {			
			string ID <- first(string(Init at {0,j})split_with "BV");
			if descriptionDuCheptelBV[ID] != nil {
				loop i from: 2 to: 13 {
					int categorie <- positionDeCategorie(string(Init at {1,j}));
					put int(Init at {i,j}) at: {categorie,i-2} in: calendrierVentes[ID];
				}
			}
		}
	}
	
	action lectureFichierRepartitionSemaines(string chemin, map<string,list> repartitionVelageMultiSemaines, map<string,list> repartitionVelagePrimiSemaines){
		matrix Init <- matrix(csv_file(chemin,";",false));
		
		//matrix Init <- matrix(file(chemin));
		int nbLigne <- length(Init column_at 0);
//		loop ID over: descriptionDuCheptelBV.keys{
//			list repartitionSemaines <- list([[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]);			
//			put repartitionSemaines at: ID in: repartitionVelageMultiSemaines;
//			put repartitionSemaines at: ID in: repartitionVelagePrimiSemaines;
//		}

		loop j from: 0 to: nbLigne -1 step: 1{
//		loop j from: 1 to: nbLigne -1{
			
			string ID <- string(first(string(Init at {0,j})split_with "BV"));
			if descriptionDuCheptelBV[ID] != nil {
				string type <- string(Init at {1,j});
				list<int> repartitionSemaines <- list([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);			
				switch type{
					match "multi"{
						loop i from: 2 to: 49 { //4 semaine par mois
							put int(Init at {i,j}) at: i-2 in: repartitionSemaines;
						}
						put repartitionSemaines at: ID in: repartitionVelageMultiSemaines;
					}
					match "primi"{
						loop i from: 2 to: 49 {
							put int(Init at {i,j}) at: i-2 in: repartitionSemaines;
						}
						put repartitionSemaines at: ID in: repartitionVelagePrimiSemaines;
					}
				}
			}
		}
	}
	
	
	int positionDeCategorie(string nom){
		switch nom {
			match "VeauxMalesAvantSevrage" {
				return 0;
			}
			match "Males0-1an" {
				return 1;
			}
			match "Males1-2ans" {
				return 2;
			}
			match "Males2-3ans" {
				return 3;
			}
			match "Males+3ans" {
				return 4;
			}
			match "VeauxFemellesAvantSevrage" {
				return 5;
			}
			match "Femelles0-1an" {
				return 6;
			}
			match "Femelles1-2ans" {
				return 7;
			}
			match "Femelles2-3ans" {
				return 8;
			}
			match "Femelles+3ans" {
				return 9;
			}
		}
	}
}

species cheptelBovinViandeV2{
	string IDexploitation;
													
	int NBVELAGE;
	
	int NBV2REF;
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
	
	int NbTaureau;
		
	veauxMalesAvantSevrage sesVeauxMalesAvantSevrage;           
   	males01an sesMales01an;                    
    males12ans sesMales12ans;                       
    males23ans sesMales23ans;                   
    malesPlus3ans sesMalesPlus3ans;                     
    veauxFemellesAvantSevrage sesVeauxFemellesAvantSevrage;
    femelles01an sesFemelles01an;                  
    femelles12ans sesFemelles12ans;
    femelles23ans sesFemelles23ans;                  
    vachesAllaitantes sesVachesAllaitantes;     
	

	action naissance(map<string,float> descriptionDuCheptel) {
		NBVELAGE <- int(descriptionDuCheptel["Nbvelage"]);
		VeauxNes <- int (round(NBVELAGE * descriptionDuCheptel["TAUXPROLIFREF"] / 100));
		VeauxFNes <- int(VeauxNes*(100-descriptionDuCheptel["SEXERATIO"])/100);
		VeauxMNes <- VeauxNes - VeauxFNes;
	}
	
	action deces(map<string,float> descriptionDuCheptel) {
		VeauxMorts <- int(round(VeauxNes * (descriptionDuCheptel["TAUXMORTREF"]/100)));
		VeauxMMort <- round(VeauxMorts * (descriptionDuCheptel["SEXERATIO"])/100);
		VeauxFMort <- VeauxMorts - VeauxMMort;
	}
	
	action sevrage{
		VeauxSevresM <- int(VeauxMNes - VeauxMMort);
		VeauxSevresF <- int(VeauxFNes - VeauxFMort);
	}
	
	action calculCroisement(map<string,float> descriptionDuCheptel) {
		VeauxSevresCroisesM <- int(VeauxSevresM * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresCroisesF <- int(VeauxSevresF * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresPurM <- VeauxSevresM - VeauxSevresCroisesM;
		VeauxSevresPurF <- VeauxSevresF - VeauxSevresCroisesF;
	}
	
	//			------------ Vaches -------------
	
	action NombreVaches(map<string,float> descriptionDuCheptel) {
		if descriptionDuCheptel["TAUXGESTREF"]>0{
			NbVachesRepro <- int(round(NBVELAGE / (descriptionDuCheptel["TAUXGESTREF"]/100)));
		}
		if descriptionDuCheptel["TAUXREPROREF"]>0{
			NbVaches <- int(round(NbVachesRepro / (descriptionDuCheptel["TAUXREPROREF"]/100)));
		}		
		NbVachesRenouv <- int(round(NBVELAGE * (descriptionDuCheptel["TAUXRENOUVREF"]/100)));	
	}
	
	action velage(map<string,float> descriptionDuCheptel){
		NBV2REF <- int(round(NbVachesRenouv * (descriptionDuCheptel["TAUXVEL2REF"]/100)));
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
		do velage(descriptionDuCheptel);
		
		// -------- Taureau --------
		
		do NombreTaureau(descriptionDuCheptel);
	}
	
	action constructionEffectif(map<string,float> descriptionDuCheptel, matrix<int> local_calendrierVentes, list<int> repartitionVelage, map<int,matrix<int>> tableauEffectif, list<int> repartitionVelageMultiSemaines, list<int> repartitionVelagePrimiSemaines){
		int agePremierVelage <- int(descriptionDuCheptel["AGEPREMIREVELAGE"]);
		bool isVelagePrecoce <- true;
		if agePremierVelage=36{
			isVelagePrecoce <- false;
		}
		
		do initialiserTableauEffectif(tableauEffectif, repartitionVelage, local_calendrierVentes,descriptionDuCheptel["IVV"],isVelagePrecoce);
		do initialiserNaissance(tableauEffectif, descriptionDuCheptel);
		do sevrageDesNaissances(tableauEffectif[9],descriptionDuCheptel["SEVRAGE"]);
		do sevrageDesNaissances(tableauEffectif[4],descriptionDuCheptel["SEVRAGE"]);
		
		// changementCategorieDesBovins(matrix<int> tableauEffectifInferieur,matrix<int> tableauEffectifSuperieur,int tempsDeChangement,bool velagePrecoce )
		do changementCategorieDesBovins(tableauEffectif[9],tableauEffectif[8],descriptionDuCheptel["SEVRAGE"]);
		do changementCategorieDesBovins(tableauEffectif[8],tableauEffectif[7],12);

		do changementCategorieDesBovins(tableauEffectif[7],tableauEffectif[6],12);
		do changementCategorieDesBovins(tableauEffectif[4],tableauEffectif[3],descriptionDuCheptel["SEVRAGE"]);
		do changementCategorieDesBovins(tableauEffectif[3],tableauEffectif[2],12,isVelagePrecoce);
		if !isVelagePrecoce{
			do changementCategorieDesBovins(tableauEffectif[2],tableauEffectif[1],12,!isVelagePrecoce);
			do actualiserVelageA2Ans(tableauEffectif[1],NBV2REF);
		}
		loop categorie from: 1 to: 9{
			do genererEffectifBovin(tableauEffectif[categorie]);
		}
		do genererEffectifMultiPrimi(tableauEffectif[0]);
		loop categorie from: 0 to: 9{
			do choixAgents(tableauEffectif[categorie],categorie,descriptionDuCheptel["IVV"],repartitionVelageMultiSemaines,repartitionVelagePrimiSemaines);
		}
	}
	
	
	action initialiserTableauEffectif(map<int,matrix<int>> tableauEffectif, list<int> repartitionVelage, matrix<int> calendrierVentes,int IVV,bool velagePrecoce){
		int sommePrimi <- 0;
		int sommeVentes <-0;
		loop type from:0 to:9{
			matrix effectif <- matrix([	[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0],
										[0,0,0,0,0,0,0,0,0,0,0,0]
									]);
			loop mois from:0 to:11{
				put calendrierVentes at {9-type,mois} at: {1,mois} in:effectif;
				if type = 0 {
					sommePrimi <- sommePrimi + repartitionVelage at mois;
					sommeVentes <- sommeVentes + calendrierVentes at {9-type,mois};
					put repartitionVelage at mois at:{3,mois} in: effectif;
				}
			}
			put effectif at: type in: tableauEffectif;
		}
		if sommePrimi-sommeVentes != 0 {
			write "---- ATTENTION ----\n
				   Cycle impossible, le nombre de ventes de vaches \n
				   sur une année devrait être "+sommePrimi+" et non "+sommeVentes+".";
		}
		do genererVelageMulti(tableauEffectif[0],IVV);
		do genererSortiesPourPremierVelage(tableauEffectif,repartitionVelage,velagePrecoce);
	}
	
	// genere les velages multi à partir des velages de primi et de l'IVV
	action genererVelageMulti(matrix<int> tableauEffectif, int IVV){
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
				int ancienneValeur <- int(tableauEffectif at {2,(mois+annee*IVV/30.4)mod 12});
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
	action genererSortiesPourPremierVelage(map<int,matrix> tableauEffectif, list<int> repartitionVelage, bool velagePrecoce){
		int categorie <- 1;
		if velagePrecoce{
			categorie <- 2;
		}
		loop mois from:0 to: 11{
			put int(repartitionVelage at mois) at:{2,mois} in: tableauEffectif[categorie];
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
			put velageF at:{3,mois} in: tableauEffectif[4];
			sommeM <- sommeM + velageM;
			put velageM at:{3,mois} in: tableauEffectif[9];
		}
		do correctionNaissanceEtmortalite(tableauEffectif[4],sommeF,VeauxSevresF);
		do correctionNaissanceEtmortalite(tableauEffectif[9],sommeM,VeauxSevresM);
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
	
	//Changement de categorie en se basant sur le temps de sevrage
	action sevrageDesNaissances(matrix<int> tableauEffectif, int tempsSevrage){
		int sommeVentes <- 0;
		loop mois from: 0 to: 11{
			int naissance <- tableauEffectif at {3,mois};
			put naissance at: {2, (mois + tempsSevrage ) mod 12} in:tableauEffectif;
			sommeVentes <- sommeVentes + int(tableauEffectif at {1,mois});
		}
		do suppressionDesVentesAuxSorties(tableauEffectif,sommeVentes);
	}
	
	action suppressionDesVentesAuxSorties(matrix<int> tableauEffectif,int sommeVentes){
		
		int dernierMoisSevrage <- recupererDernierMois(tableauEffectif);
		int ancienneValeur <- tableauEffectif at {2,dernierMoisSevrage};
		put ancienneValeur - sommeVentes at: {2,dernierMoisSevrage} in: tableauEffectif;
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

	// FIXME : addition of default value for tempsDeChangement and velagePrecoce	
	action changementCategorieDesBovins(matrix<int> tableauEffectifInferieur,matrix<int> tableauEffectifSuperieur,int tempsDeChangement <- 0, bool velagePrecoce <- false){
		loop mois from:0 to: 11 {
			int sortieSevre <- tableauEffectifInferieur at {2,mois};
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
		
	action actualiserVelageA2Ans(matrix<int> tableauEffectif,int velageA2ans){
		int decalage <- 0;
		loop while: velageA2ans != 0{
			int premierMoiVelage <- recupererPremierMoisVelage(tableauEffectif);
			int ancienneValeurEntree <- tableauEffectif at {3,(premierMoiVelage + decalage)mod 12};
			int ancienneValeurSortie <- tableauEffectif at {2,(premierMoiVelage + decalage)mod 12};
			int velageRetire <- 0;
			if ancienneValeurSortie < ancienneValeurEntree{
				velageRetire <- ancienneValeurSortie;
			}else{
				velageRetire <- ancienneValeurEntree;
			}
			velageRetire <- min([velageRetire,velageA2ans]);
			velageA2ans <- velageA2ans - velageRetire;
			put ancienneValeurEntree - velageRetire at: {3,(premierMoiVelage+ decalage)mod 12} in: tableauEffectif;
			put ancienneValeurSortie - velageRetire at: {2,(premierMoiVelage+ decalage)mod 12} in: tableauEffectif;
			decalage <- decalage +1;			
		}
	}
	
	
	
	//Permet de recuperer le mois de velage où se trouve les vaches les plus jeunes
	int recupererPremierMoisVelage(matrix<int> tableauEffectif){
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
		return (moisDebutVelage+1)mod 12;
	}
	
	int recupererPremierMoisVentesSorties(matrix<int> tableauEffectif){
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

	//Permet de recuperer le mois où se trouve les vaches les plus agées qui vont être vendus afin de les enlever des sorties
	int recupererDernierMois(matrix<int> tableauEffectif){
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
	
	action genererEffectifBovin(matrix<int> tableauEffectif){
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
				int ancienneValeur <- tableauEffectif at {0,mois};
				put ancienneValeur + sommeEntree at: {0,mois} in: tableauEffectif;
			}
		}
	}
	
	action genererEffectifMultiPrimi(matrix<int> tableauEffectif){
		int plusGrandEffectif <- 0;
		loop mois from:0 to:11{
			int primi <- tableauEffectif at {3,mois};
			int ventes <- tableauEffectif at {1,mois};
			int effectifDuMois <- tableauEffectif at {0,mois};
			int prochainEffectif <- effectifDuMois + primi - ventes;
			put prochainEffectif at:{0,(mois +1)mod 12} in: tableauEffectif;
			if prochainEffectif > plusGrandEffectif{
				plusGrandEffectif <- prochainEffectif;
			} 
		}
		loop mois from:0 to:11{
			int ancienneValeur <- tableauEffectif at {0,mois};
			put ancienneValeur + NbVachesRepro - plusGrandEffectif at: {0,mois} in: tableauEffectif;
		}
	}
	
	

	action choixAgents(matrix tableauEffectif, int type, int IVV,list<int> repartitionVelageMultiSemaines,list<int> repartitionVelagePrimiSemaines){
		switch type{
        	match 0 {
                sesVachesAllaitantes <- genererVachesAllaitantes(tableauEffectif,IVV,repartitionVelageMultiSemaines,repartitionVelagePrimiSemaines);
            }        
        	match 1 {
                sesFemelles23ans <- genererAgents(femelles23ans,tableauEffectif); 
            }        
        	match 2 {
                sesFemelles12ans <- genererAgents(femelles12ans,tableauEffectif);
            }        
        	match 3 {
                sesFemelles01an <- genererAgents(femelles01an,tableauEffectif); 
            }        
        	match 4 {
                sesVeauxFemellesAvantSevrage <- genererAgents(veauxFemellesAvantSevrage,tableauEffectif);  
            }      
            match 5 {
                sesMalesPlus3ans <- genererAgents(malesPlus3ans,tableauEffectif); 
            }  
        	match 6 {
                sesMales23ans <- genererAgents(males23ans,tableauEffectif);
            }        
        	match 7 {
                sesMales12ans <- genererAgents(males12ans,tableauEffectif);  
            }        
        	match 8 {
                sesMales01an <- genererAgents(males01an,tableauEffectif);
            }        
        	match 9 {
                sesVeauxMalesAvantSevrage <- genererAgents(veauxMalesAvantSevrage,tableauEffectif);    
            }        
        }
	}
	
	vachesAllaitantes genererVachesAllaitantes(matrix effectif,int IVV,list<int> repartitionVelageMultiSemaines,list<int> repartitionVelagePrimiSemaines) {
		create vachesAllaitantes returns: instanceVachesAllaitantes with: [effectif::(effectif column_at 0) ,
										ventes_ou_engraissement::(effectif column_at 1),
										distributionVelageMul::(effectif column_at 2),
										distributionVelagePri::(effectif column_at 3),
										repartitionDeLeffectifEnSemaine::repartitionVelageMultiSemaines,
										repartitionDeLeffectifEnSemainePrimi::repartitionVelagePrimiSemaines,
										dureePrimi::IVV
		];
		return first(instanceVachesAllaitantes);
	}
	
	bovinGenerique genererAgents(species<bovinGenerique> typeBovin <- bovinGenerique, matrix tableauEff) {

		create typeBovin returns: instanceBovin with: [effectif::(tableauEff column_at 0),
								ventes_ou_engraissement::(tableauEff column_at 1),
								sortie::(tableauEff column_at 2),
								entree::(tableauEff column_at 3)			
		];
		return first(instanceBovin);
	}
	
	action presentation{
		write "\t\t------------ BovinViande --------------";	
        ask sesVachesAllaitantes{
			do presentation();
		}                       
        ask sesFemelles23ans{
        	write "\n\nfemelles 2-3ans";
        	do presentation();
        }                        
        ask sesFemelles12ans{
        	write "\n\nfemelles 1-2ans";
        	do presentation();
        }                         
        ask sesFemelles01an{
        	write "\n\nfemelles sevrage-1ans";
        	do presentation();
        }                        
        ask sesVeauxFemellesAvantSevrage{
        	write "\n\nfemelles avant Sevrage";
        	do presentation();
        }  
        ask sesMalesPlus3ans{
        	write "\n\nMales +3ans";
        	do presentation();
        }                        
        ask sesMales23ans{
        	write "\n\nMales 2-3ans";
        	do presentation();
        }                         
        ask sesMales12ans{
        	write "\n\nMales 1-2ans";
        	do presentation();
        }                       
        ask sesMales01an {
        	write "\n\nMales sevrage-1ans";
        	do presentation();
        }                       
		ask sesVeauxMalesAvantSevrage {
        	write "\n\nMales avant sevrage";
        	do presentation();
        }                 
	}
}

//experiment TestBovinViande type: gui{
//	
//}

	
