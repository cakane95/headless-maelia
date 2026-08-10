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
	 '/Aveyron/modeleAgricole/agriculteurs/descriptionElevage.csv' ;
	string cheminCalendrierVentes  <-  '' + cheminModeleVersDonnees +
	 '/Aveyron/modeleAgricole/agriculteurs/calendrierVentes.csv' ;
//	string cheminDescriptionElevage  <-  '../../../../TestCheptel/includes/referenceElevage.csv' ;
//	string cheminCalendrierVentes  <-  '../../../../TestCheptel/includes/calendrierVentes.csv' ;

	map<string,matrix> calendrierVentes <- map([]);														
	map<string,matrix> calendrierEvolution <- map([]);
	map<string,map<string,float>> descriptionDuCheptelBV;
	
	int moiMoyenVelage; // de 0 à 11;							
																			
	list<int> etalementVelage <- [5,25,40,25,5];									
	matrix matrice <- matrix([	[0,0,0,0,0,0,0,0,0,0,0,0],
								[0,0,0,0,0,0,0,0,0,0,0,0],
								[0,0,0,0,0,0,0,0,0,0,0,0],
								[0,0,0,0,0,0,0,0,0,0,0,0]
							]);
						
	action constructionCheptelBV{
		do lectureFichierDescription(cheminDescriptionElevage,descriptionDuCheptelBV);
		do lectureCalendrierVenteBV(cheminCalendrierVentes);
		loop ID over:descriptionDuCheptelBV.keys {
			create cheptelBovinViande with:[IDexploitation::ID];
			ask last(cheptelBovinViande) {
				map<string,int> tmp <- descriptionDuCheptelBV[ID];
				do mis_a_jour(tmp);
				do genererChangementCategorie(calendrierEvolution,ID,moiMoyenVelage);
				do initialiserMatrice(matrice,calendrierVentes[ID],calendrierEvolution[ID]);	
			}	
		}
	}
	//			------------ Initialisation -----------------
	
	action lectureFichierDescription (string Chemin, map<string,map<string,float>>descriptionDuCheptel){
		matrix Init <- matrix(csv_file(Chemin,";"));
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
				put descriptionDuCheptelTMP at: string(first(string(listCheptel[j]) split_with "BV")) in: descriptionDuCheptel;
			}
		}
	}
	
	action lectureCalendrierVenteBV (string Chemin){
		matrix Init <- matrix(csv_file(Chemin,";"));
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
		loop j from: 1 to: nbLigne -1 {
			string ID <- string(first(string(Init at {0,j})split_with "BV"));
			if descriptionDuCheptelBV[ID] != nil {
				loop i from: 2 to: 13 {
					int categorie <- positionDeCategorie(string(Init at {1,j}));
					put int(Init at {i,j}) at: {categorie,i-2} in: calendrierVentes[ID];
				}
			}
		}
	}
	
	action positionDeCategorie(string nom){
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

species cheptelBovinViande{
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
		VeauxNes <- round(NBVELAGE * descriptionDuCheptel["TAUXPROLIFREF"] / 100);
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
		VeauxSevresCroisesM <- int(VeauxSevresM * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresCroisesF <- int(VeauxSevresF * descriptionDuCheptel["TAUXCROISREF"]/100);
		VeauxSevresPurM <- VeauxSevresM - VeauxSevresCroisesM;
		VeauxSevresPurF <- VeauxSevresF - VeauxSevresCroisesF;
	}
	
	//			------------ Vaches -------------
	
	action NombreVaches(map<string,float> descriptionDuCheptel) {
		if descriptionDuCheptel["TAUXGESTREF"]>0{
			NbVachesRepro <- round(NBVELAGE / (descriptionDuCheptel["TAUXGESTREF"]/100));
		}
		if descriptionDuCheptel["TAUXREPROREF"]>0{
			NbVaches <- round(NbVachesRepro / (descriptionDuCheptel["TAUXREPROREF"]/100));
		}		
		NbVachesRenouv <- round(NBVELAGE * (descriptionDuCheptel["TAUXRENOUVREF"]/100));	
	}
	
	action velage(map<string,float> descriptionDuCheptel){
		NBV2REF <- round(NbVachesRenouv * (descriptionDuCheptel["TAUXVEL2REF"]/100));
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
		moiMoyenVelage <- int(descriptionDuCheptel["MOIMOYENVELAGE"]-1);
	}
	
	
	action genererEffectifVaches(matrix matrice){
		int effectifPlusGrand <- matrice at {0,0};
		loop i from:1 to:12{
			int entree <- matrice at {3,i-1};
			int ventes <- matrice at {1,i-1};
			int precedent <- matrice at {0,i-1};
			int result <- entree - ventes + precedent;
			put result at:{0,(i mod 12)} in: matrice;
			if (result>effectifPlusGrand){
				effectifPlusGrand <- result;
			}
		}	
		loop i from:0 to:11{
			int ancienneValeur <- matrice at {0,i};
			int correction <- NbVachesRepro - effectifPlusGrand;
			put ancienneValeur + correction at: {0,i} in: matrice;
		}	
	}
	
	action genererEffectif (matrix matrice){
		int effectifPlusPetit <- matrice at {0,0};
		int correction <- 0;
		int correctionSortie <- 0;
		loop i from:1 to:12{
			int entree <- matrice at {3,i-1};
			int sortie <- matrice at {2,i-1};
			int ventes <- matrice at {1,i-1};
			int precedent <- matrice at {0,i-1};
			int result <- entree - ventes -sortie + precedent;
			put result at:{0,(i mod 12)} in: matrice;
			if (result<effectifPlusPetit){
				effectifPlusPetit <- result;
			}
		}
		correction <- -effectifPlusPetit;
		loop i from: 0 to: 11{
			int ancienneValeur <- int(matrice at {0,i});
			int nouvelleValeur <- ancienneValeur + correction;
			put nouvelleValeur at:{0,i} in: matrice;
			
			int sortie <- int(matrice at {2,i}) + int(matrice at {1,i});
			if (nouvelleValeur< sortie ){
				int tmp <- sortie - nouvelleValeur;
				if correctionSortie < tmp {
					correctionSortie <- tmp;
				} 
			}
		}
		loop i from: 0 to: 11{
			int ancienneValeur <- int(matrice at {0,i});
			put ancienneValeur + correctionSortie at:{0,i} in: matrice;
		}		
	}
	
	action genererChangementCategorie(map<string,matrix> calendrier, string ID, int local_moiMoyenVelage){
		int sortie <- VeauxSevresM;
		int ventes <- 0;
		int rang <- 0;
		int j <-0;
		matrix<int> local_matrice <- matrix<int>([	
									[0,0,0,0,0,0,0,0,0,0,0,0],	//VeauxMâles avant sevrage
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
		loop i from:0 to:9 {
			if i=5 {
				j <- 1;
				sortie <- VeauxSevresF;
				ventes <- 0;
				rang <- 0;
			}
			if i=0 or i=5{
				do repartitionVelage(local_matrice,local_moiMoyenVelage,sortie,i);
			}
			if i=1 or i=6{
				rang <- (local_moiMoyenVelage+8) mod 12;
			}
			if i=2 or i=7{
				rang <- (rang + 4) mod 12;
			}
			ventes <- 0;					
			loop j from:0 to:11{
				ventes <- ventes + int(calendrierVentes[ID] at {i,j});
			}
			if (i!=0 and i!=5 and i!=9) {
				put sortie at: {i,rang} in:local_matrice;
			}
			if (i=7){
				sortie <- sortie - NBV2REF;
			}
			sortie <- sortie - ventes;
		}
		put local_matrice at: ID in: calendrier;
	}
	
	action genererEffectifMulti(matrix matrice){
		int somme <-0;
		int value <-0;
		int rang <- 0;
		int primi <- 0;
		loop i from:-2 to: 2{
			rang<- (moiMoyenVelage+i+12) mod 12;
			primi <- int(matrice at {3,rang});
			value <- int(round(NBVELAGE*etalementVelage[i+2]/100));
			somme <- somme + value;
			put value - primi at:{2,rang} in: matrice;
		}
		if somme != NBVELAGE {
			value <- matrice at {2,moiMoyenVelage};
			put int(value + NBVELAGE - somme) at:{2,moiMoyenVelage} in: matrice ;
		}
	}
	
	action repartitionPrimi(matrix matrice, int moiMoyenVel, int ligne, int effectif, list repartition){
		loop i from: -2 to:2{
			if effectif > 0{
				int value <- int(round(NBVELAGE*etalementVelage[i+2]/100) - int(repartition[i+2]) );
				if int(etalementVelage[i+2]) != 0 {
					effectif <- effectif - value;
				}
				if effectif<0{
					value <- value + effectif;
					effectif <- 0;					
				}
				int rang <- (moiMoyenVel+i+12) mod 12;
				put value + int(matrice at {ligne,rang}) at: {ligne,rang} in: matrice;
				repartition[i+2] <- value; 
			}
		}
	}	
	
	action repartitionVelage(matrix matrice, int moiMoyenVelage, int effectif, int categorie){
		int somme <-0;
		int value <-0;
		int rang <- 0;
		loop i from:-2 to: 2{
			value <- round(effectif*etalementVelage[i+2]/100);
			put value at:{categorie,(moiMoyenVelage+i+12) mod 12} in: matrice;
			somme <- somme + value;
		}
		if somme != effectif {
			value <- matrice at {categorie,moiMoyenVelage};
			put (value + effectif - somme) at:{categorie,moiMoyenVelage} in: matrice ;
		}
	}
	
	action initialiserMatrice (matrix matrice, matrix calendrierVentes,matrix calendrierEvolution){
		list repartition <- [0,0,0,0,0];
		loop categorie from: 0 to: 9{
			int etalage <- -2;
			loop while: etalementVelage[etalage+2]=0 {
				etalage <- etalage +1;
			} 			
			loop moi from: 0 to: 11 {
				put 0 at: {0,moi} in: matrice;
				put calendrierVentes at {categorie,moi} at: {1,moi} in: matrice;
				if (categorie!=4 and categorie!= 9 and categorie!= 8){
					put calendrierEvolution at {categorie+1,moi} at: {2,moi} in: matrice;
				}else{
					put 0 at:{2,moi} in: matrice;
				}
				put calendrierEvolution at {categorie,moi} at: {3,moi} in: matrice;
			}
			if categorie=7 {
				do repartitionPrimi(matrice, moiMoyenVelage, 2, NBV2REF,repartition);
			}
			if categorie=8{
				do repartitionPrimi(matrice,moiMoyenVelage,2,(NbVachesRenouv - NBV2REF),repartition);
			}
			if categorie=9 {
				repartition <- [0,0,0,0,0];
				do repartitionPrimi(matrice, moiMoyenVelage, 3, NbVachesRenouv, repartition);
				do genererEffectifMulti(matrice);
				do genererEffectifVaches(matrice);
				
			}
			else{
				do genererEffectif(matrice);
			}
			do choixAgents(categorie);		
		}
	}
	
	
	action choixAgents(int type){
		switch type{
        	match 0 {
                sesVeauxMalesAvantSevrage <- genererAgents(veauxMalesAvantSevrage);    
            }        
        	match 1 {
                sesMales01an <- genererAgents(males01an);
            }        
        	match 2 {
                sesMales12ans <- genererAgents(males12ans);  
            }        
        	match 3 {
                sesMales23ans <- genererAgents(males23ans);
            }        
        	match 4 {
                sesMalesPlus3ans <- genererAgents(malesPlus3ans); 
            }      
            match 5 {
                sesVeauxFemellesAvantSevrage <- genererAgents(veauxFemellesAvantSevrage);  
            }  
        	match 6 {
                sesFemelles01an <- genererAgents(femelles01an); 
            }        
        	match 7 {
                sesFemelles12ans <- genererAgents(femelles12ans);
            }        
        	match 8 {
                sesFemelles23ans <- genererAgents(femelles23ans); 
            }        
        	match 9 {
                sesVachesAllaitantes <- genererVachesAllaitantes();
            }        
        }
	}
	
	action genererVachesAllaitantes {
		create vachesAllaitantes returns: instanceVachesAllaitantes with: [effectif::(matrice column_at 0) ,
										ventes_ou_engraissement::(matrice column_at 1),
										distributionVelageMul::(matrice column_at 2),
										distributionVelagePri::(matrice column_at 3)
		];
		return first(instanceVachesAllaitantes);
	}
	action genererAgents(species<bovinGenerique> typeBovin <- bovinGenerique ) {

		create typeBovin returns: instanceBovin with: [effectif::(matrice column_at 0),
								ventes_ou_engraissement::(matrice column_at 1),
								sortie::(matrice column_at 2),
								entree::(matrice column_at 3)			
		];
		return first(instanceBovin);
	}
	
	action presentation{
		write "\t\t------------ BovinViande --------------";		            
		ask sesVeauxMalesAvantSevrage {
        	do presentation();
        }                 
        ask sesMales01an {
        	do presentation();
        }                       
        ask sesMales12ans{
        	do presentation();
        }                       
        ask sesMales23ans{
        	do presentation();
        }                         
        ask sesMalesPlus3ans{
        	do presentation();
        }                        
        ask sesVeauxFemellesAvantSevrage{
        	do presentation();
        }  
        ask sesFemelles01an{
        	do presentation();
        }                        
        ask sesFemelles12ans{
        	do presentation();
        }                         
        ask sesFemelles23ans{
        	do presentation();
        }                        
        ask sesVachesAllaitantes{
			do presentation();
		}                       
	}
}

	
