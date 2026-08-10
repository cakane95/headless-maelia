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
 *  vacheAdulte
 *  Author: Theo Bullat
 *  Description: Heritage mere des vaches allaitantes et laiti�res
 */

model vachesAdultes

import "velageMulti.gaml"

species vachesAdultes parent: bovinGenerique{
	list<int> distributionVelageMul;
	list<int> distributionVelagePri;
	list<int> besoinPrimi;
	int dureePrimi <- 365; // en jours
	velagePrimi sonVelagePrimi;
	velageMulti sonVelageMulti;
	
	action initialiser{
		int somme <- 0;
		list<int> effectifPrimi <- [];
		list<int> effectifMulti <- [];
		loop effectifParMoi over:effectif {
			somme <- somme + effectifParMoi;
		}
		effectifMoyen <- somme / length(effectif);
		loop rang_loop from: 0 to: 11{
			somme <- 0;
			loop i from: 0 to: round(dureePrimi/30.4)-1{ 
				int placement <- (rang_loop-i+24) mod 12;
				somme <- somme + distributionVelagePri[placement];
			}
			add somme to:effectifPrimi;
			add (effectif[rang_loop] - effectifPrimi[rang_loop]) to: effectifMulti;
		}	
		create velagePrimi with: [effectif::effectifPrimi] returns: velagePrim;
		sonVelagePrimi <- first(velagePrim);
		create velageMulti with: [effectif::effectifMulti] returns: velageMult;
		sonVelageMulti <- first(velageMult);
		isInitialise <- true;
		do calculerBesoinAnnuelPrimi;
		do calculerBesoinAnnuelMulti;
		do repartitionDeLEffectifParSemaine;
		do repartitionDesBesoinsParSemaines;
		do retraitBesoinApresVentes;
	}
	
	action presentation{
		if !isInitialise{
			do initialiser;
		}
		write "\n\neffectif: \t\t\t\t"+effectif;
		write "ventes_ou_engraissement:"+ventes_ou_engraissement;
		write "multi: \t\t\t\t\t"+distributionVelageMul;
		write "primi: \t\t\t\t\t"+distributionVelagePri;

		write "effectifMoyen: \t\t\t"+effectifMoyen;
		write "\nPrimi: ";
		ask sonVelagePrimi{
			do presentation;
		}
		write "\nMulti: ";
		ask sonVelageMulti{
			do presentation;
		}
		write "Besoin: "+ besoinsTotalFinal;
	}
	
	float besoinEnergetique <- 0.0;
	float besoinProteique <- 0.0;
	float IRace <- 0.95;
	int semaineDebutVelagesPrimi <- 4; // [semaines]
	int dureeVelageGroupe <- 10; //[semaines]
	int ageBroutardSevrage <- 7; //[mois]
	int poidsBroutardSevrage <- 280; //[kg]					 
	int semaineDebutPaturage <- 12; 
	int semaineFinPaturage <- 49;
	list<int> repartitionDeLeffectifEnSemaine <- [];
	list<int> repartitionDeLeffectifEnSemainePrimi <- [];
	list<int> repartitionBesoinAnnuelMultiSemaine1;
	list<int> repartitionBesoinAnnuelPrimiSemaine1;
	list<int> repartitionBesoinAnnuelMultiSemaine2;
	list<int> repartitionBesoinAnnuelPrimiSemaine2;
	list<int> repartitionBesoinAnnuelMultiSemaine3;
	list<int> repartitionBesoinAnnuelPrimiSemaine3;
	list<int> repartitionBesoinAnnuelMultiSemaine4;
	list<int> repartitionBesoinAnnuelPrimiSemaine4;
//	list<int> repartitionBesoinAnnuelMultiSemaine1 <- [1,1,1,1,1,1,1,1,1];
//	list<int> repartitionBesoinAnnuelPrimiSemaine1 <- [1,1,1,1,1,1,1,1,1];
//	list<int> repartitionBesoinAnnuelMultiSemaine2 <- [2,2,2,2,2,2,2,2,2];
//	list<int> repartitionBesoinAnnuelPrimiSemaine2 <- [2,2,2,2,2,2,2,2,2];
//	list<int> repartitionBesoinAnnuelMultiSemaine3 <- [3,3,3,3,3,3,3,3,3];
//	list<int> repartitionBesoinAnnuelPrimiSemaine3 <- [3,3,3,3,3,3,3,3,3];
//	list<int> repartitionBesoinAnnuelMultiSemaine4 <- [4,4,4,4,4,4,4,4,4];
//	list<int> repartitionBesoinAnnuelPrimiSemaine4 <- [4,4,4,4,4,4,4,4,4];
	matrix<int> besoinsParMoisMulti<- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
	matrix<int> besoinsParMoisPrimi<- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
	matrix<int> besoinsTotalFinal <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
	int IVV <- dureePrimi;
	
	
	action repartitionDesBesoinsParSemaines{
		matrix<int> besoinsPrimi <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
		matrix<int> besoinsMulti <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
		int semaines <- 0;
		loop local_effectif over: repartitionDeLeffectifEnSemaine{
			if local_effectif != 0 {
				int moisEffectif <- int(semaines/4);
				switch semaines mod 4{
					match 0{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelMultiSemaine1, besoinsMulti, local_effectif, moisEffectif);
					}
					match 1{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelMultiSemaine2, besoinsMulti, local_effectif, moisEffectif);
					}
					match 2{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelMultiSemaine3, besoinsMulti, local_effectif, moisEffectif);
					}
					match 3{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelMultiSemaine4, besoinsMulti, local_effectif, moisEffectif);
					}
				}
			}			
			semaines <- semaines+1;
		}
		semaines <- 0;
		loop local_effectif over: repartitionDeLeffectifEnSemainePrimi{
			if effectif != 0 {
				int moisEffectif <- int(semaines/4);
				switch semaines mod 4{
					match 0{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelPrimiSemaine1, besoinsPrimi, local_effectif, moisEffectif);
					}
					match 1{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelPrimiSemaine2, besoinsPrimi, local_effectif, moisEffectif);
					}
					match 2{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelPrimiSemaine3, besoinsPrimi, local_effectif, moisEffectif);
					}
					match 3{
						do repartitionCourbeBesoinSurAnnee( repartitionBesoinAnnuelPrimiSemaine4, besoinsPrimi, local_effectif, moisEffectif);
					}
				}
			}			
			semaines <- semaines+1;
		}
		loop mois from: 0 to: 11{
			put (besoinsPrimi at {mois,0}) + (besoinsMulti at {mois,0}) at:{mois,0} in:besoinsTotalFinal;
		}
	}
	
	action repartitionCourbeBesoinSurAnnee(list<int> besoinsParMois, matrix<int> besoinsRepartie, int local_effectif, int moisEffectif){
		loop moisParcours from:0 to: length(besoinsParMois)-1{
			int ancienneValeur <- besoinsRepartie at {(moisEffectif+moisParcours)mod 12,0};
			int nouveauxBesoin <- local_effectif * besoinsParMois[moisParcours];
			put ancienneValeur + nouveauxBesoin at: {(moisEffectif+moisParcours)mod 12,0} in:besoinsRepartie;
		}
	}	
	
	
	action repartitionDeLEffectifParSemaine{
		//Si la répartition n'est pas fournis et donc vide:
		if repartitionDeLeffectifEnSemaine = [] {
			repartitionDeLeffectifEnSemaine <- [0,0,0,0,	0,0,0,0,
												0,0,0,0,	0,0,0,0,				
												0,0,0,0,	0,0,0,0,
												0,0,0,0,	0,0,0,0,
												0,0,0,0,	0,0,0,0,
												0,0,0,0,	0,0,0,0];
			repartitionDeLeffectifEnSemainePrimi <- [0,0,0,0,	0,0,0,0,
												 	 0,0,0,0,	0,0,0,0,				
												 	 0,0,0,0,	0,0,0,0,
												 	 0,0,0,0,	0,0,0,0,
												 	 0,0,0,0,	0,0,0,0,
													 0,0,0,0,	0,0,0,0];
			int semaines <- 0;
			loop mois from: 0 to: 11{
				int sommeMul <- 0;
				int sommePri <- 0;
				//FIXME : variableInutile est une variable inutile ajoutée pour la compilation ... A vérifier que la boucle fait bien ce qu'elle est supposée faire ...
				loop variableInutile from: 0 to: 2{
					int effectifSemaineMul <- int(distributionVelageMul[mois]/4);
					int effectifSemainePri <- int(distributionVelagePri[mois]/4);
					// Utiliser l'arrondi uniquement au dessus de 4 permet d'éviter de se retrouver avec des effectifs négatifs.
					if distributionVelageMul[mois] >= 4{
						effectifSemaineMul <- round(distributionVelageMul[mois]/4);
					}
					if distributionVelagePri[mois] >= 4{
						effectifSemainePri <- round(distributionVelagePri[mois]/4);
					}
					sommeMul <- sommeMul + effectifSemaineMul;
					sommePri <- sommePri + effectifSemainePri;
					put effectifSemaineMul at: semaines in: repartitionDeLeffectifEnSemaine;
					put effectifSemainePri at: semaines in: repartitionDeLeffectifEnSemainePrimi;
					semaines <- semaines + 1;
				}
				put distributionVelageMul[mois] - sommeMul at: semaines in:repartitionDeLeffectifEnSemaine;
				put distributionVelagePri[mois] - sommePri at: semaines in:repartitionDeLeffectifEnSemainePrimi;
				semaines <- semaines + 1;
			}
			write "%%%%%%%%%%%%% Repartition généré %%%%%%%%%%%%%";
		}
		else {
			write "$$$$$$$$$$$$$$ Repartition donné $$$$$$$$$$$$$$";
			loop mois from:0 to:11 {
				int effectifDuMoisMulti <- distributionVelageMul[mois];
				int effectifDuMoisPrimi <- distributionVelagePri[mois];
				int sommeSemainesMulti <- 0;
				int sommeSemainesPrimi <- 0;
				loop semaines from: 0 to: 3{
					sommeSemainesMulti <- sommeSemainesMulti + repartitionDeLeffectifEnSemaine[mois*4+semaines];
					sommeSemainesPrimi <- sommeSemainesPrimi + repartitionDeLeffectifEnSemainePrimi[mois*4+semaines];
				}
				if sommeSemainesMulti != effectifDuMoisMulti or sommeSemainesPrimi != effectifDuMoisPrimi {
					write " ATTENTION --- La répartition des vêlages sur les semaines donné ne correspond pas aux vêlages par mois!";
				}
			}
		}
	}
	
	action retraitBesoinApresVentes{
		matrix<int> besoinsDeTrop <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
		matrix<int> copieEffectif <- matrix([[0,0,0,0,0,0,0,0,0,0,0,0],//ventes
											 [0,0,0,0,0,0,0,0,0,0,0,0]]);//velageMulti
		matrix<int> copieEffectifSemaines <- matrix([[0,0,0,0,0,0,0,0,0,0,0,0,
													  0,0,0,0,0,0,0,0,0,0,0,0,
													  0,0,0,0,0,0,0,0,0,0,0,0,
											          0,0,0,0,0,0,0,0,0,0,0,0]]);//velageMultiSemaines
		loop semaines from:0 to: 47{
			put repartitionDeLeffectifEnSemaine[semaines] at:{0,semaines} in: copieEffectifSemaines;
		}
		do retirerVachesSansVelage(copieEffectif);
		int moisFinVentes <- recupererDernierMois(copieEffectif,0);
		int moisFinVelage <- recupererDernierMois(copieEffectif,1);
		int nbVachesVendu <- copieEffectif at{0,moisFinVentes};
		loop while: nbVachesVendu != 0 {
			int semainesDuMois <- 3;
			int nbVachesVendable <- 0;
			loop while: nbVachesVendable = 0 and semainesDuMois != -1{
				nbVachesVendable <- copieEffectifSemaines at {0,(moisFinVelage*4)+semainesDuMois};
				semainesDuMois <- semainesDuMois - 1;
			}
			//On remet à niveau la dernière decrementation qui n'est pas voulu.
			semainesDuMois <- semainesDuMois + 1;
			int nbVachesTraite <- min([nbVachesVendable,nbVachesVendu]);
			int nbVachesRestantesSemaines <- nbVachesVendable-nbVachesTraite;
			int nbVachesRestantesMois <- copieEffectif at {1,moisFinVelage} - nbVachesTraite; 
			put nbVachesRestantesSemaines at: {0,(moisFinVelage*4)+semainesDuMois} in:copieEffectifSemaines;
			put nbVachesRestantesMois at: {1,moisFinVelage} in: copieEffectif;
			put nbVachesVendu - nbVachesTraite at:{0,moisFinVentes} in:copieEffectif;
			switch semainesDuMois{
				match 0{
					do genererBesoinARetirer(besoinsDeTrop,repartitionBesoinAnnuelMultiSemaine1,moisFinVelage,moisFinVentes,nbVachesTraite);
				}
				match 1{
					do genererBesoinARetirer(besoinsDeTrop,repartitionBesoinAnnuelMultiSemaine2,moisFinVelage,moisFinVentes,nbVachesTraite);
				}
				match 2{
					do genererBesoinARetirer(besoinsDeTrop,repartitionBesoinAnnuelMultiSemaine3,moisFinVelage,moisFinVentes,nbVachesTraite);
				}
				match 3{
					do genererBesoinARetirer(besoinsDeTrop,repartitionBesoinAnnuelMultiSemaine4,moisFinVelage,moisFinVentes,nbVachesTraite);
				}
			}
			moisFinVelage <- recupererDernierMois(copieEffectif,1);
			moisFinVentes <- recupererDernierMois(copieEffectif,0);
			nbVachesVendu <- copieEffectif at{0,moisFinVentes};
		}
		loop mois from: 0 to: 11{
			int ancienneValeur <- besoinsTotalFinal at {mois,0};
			put ancienneValeur - besoinsDeTrop at {mois,0} at:{mois,0} in:besoinsTotalFinal;
		}
	}
	
	//permet de calculer les besoins qui doivent être retirer. On simule les besoins d'un velage en commencant a la date de velage
	//puis on commence à stocker les besoins à partir du moment où le mois de ventes a été dépassé.
	action genererBesoinARetirer(matrix besoinDeTrop,list<int> repartitionBesoinAnnuel, int moisDeVelage,int moisVentes,int nbVachesVendu){
		int mois <- moisDeVelage;
		bool vachesVendues <- false;
		loop besoinDuMois over: repartitionBesoinAnnuel {
			if vachesVendues {
				int ancienneValeur <- besoinDeTrop at {mois,0};
				put besoinDuMois*nbVachesVendu + ancienneValeur at:{mois,0} in: besoinDeTrop;
			}
			if mois = moisVentes {
				vachesVendues <- true;
			}
			mois <- (mois + 1) mod 12;
		}
	}
	
	//Permet de supprimer les vaches qui ne vêlent pas des ventes. Afin de calculer 
	//les besoins à enlever pour les vaches qui vêlent mais qui sont vendus pendant l'année.
	action retirerVachesSansVelage(matrix<int> copieEffectif) {
		int nbVachesTotal <- 0;
		int nbVachesAvecVelage <- 0;
		loop mois from:0 to: 11 {
			put ventes_ou_engraissement[mois] at: {0,mois} in: copieEffectif;
			put distributionVelageMul[mois] at: {1,mois} in: copieEffectif;
			if effectif[mois]> nbVachesTotal{
				nbVachesTotal <- effectif[mois];
			}
			nbVachesAvecVelage <- nbVachesAvecVelage + distributionVelageMul[mois] + distributionVelagePri[mois];
		}
		int moisDebutVentes <- recupererPremierMois(copieEffectif,0);
		int nbVachesSansVelage <- nbVachesTotal - nbVachesAvecVelage;
		loop while: nbVachesSansVelage != 0 {
			int ancienneValeur <- copieEffectif at {0,moisDebutVentes};
			int nouvelleValeur <- ancienneValeur - nbVachesSansVelage;
			if nouvelleValeur >= 0 {
				put nouvelleValeur at: {0,moisDebutVentes} in:copieEffectif;
				nbVachesSansVelage <- 0;
			}else{
				put 0 at: {0,moisDebutVentes} in: copieEffectif;
				nbVachesSansVelage <- nouvelleValeur * (-1);
				moisDebutVentes <- (moisDebutVentes+1) mod 12;
			}
		}
	}
	
	
	
	action calculerBesoinAnnuelPrimi{
		int sommeBesoinVelageSemaine1 <- 0;
		int sommeBesoinVelageSemaine2 <- 0;
		int sommeBesoinVelageSemaine3 <- 0;
		int sommeBesoinVelageSemaine4 <- 0;
		loop jour from: 0 to:IVV {
			if jour mod 30 = 0 and jour != 0{
				//Permet d'obtenir un besoin plus cohérent
				// il y a en moyenne 30.4 jours par mois
				sommeBesoinVelageSemaine1 <- int(sommeBesoinVelageSemaine1*30.4/30);
				sommeBesoinVelageSemaine2 <- int(sommeBesoinVelageSemaine2*30.4/30);
				sommeBesoinVelageSemaine3 <- int(sommeBesoinVelageSemaine3*30.4/30);
				sommeBesoinVelageSemaine4 <- int(sommeBesoinVelageSemaine4*30.4/30);
				add sommeBesoinVelageSemaine1 to: repartitionBesoinAnnuelPrimiSemaine1;
				add sommeBesoinVelageSemaine2 to: repartitionBesoinAnnuelPrimiSemaine2;
				add sommeBesoinVelageSemaine3 to: repartitionBesoinAnnuelPrimiSemaine3;
				add sommeBesoinVelageSemaine4 to: repartitionBesoinAnnuelPrimiSemaine4;
				sommeBesoinVelageSemaine1 <- 0;
				sommeBesoinVelageSemaine2 <- 0;
				sommeBesoinVelageSemaine3 <- 0;
				sommeBesoinVelageSemaine4 <- 0;
			}
		  //if jour >= 0 
				semaineDepuis1erVelage <- jour/7;
				int besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine1 <- sommeBesoinVelageSemaine1 + besoin;
			if jour >= 7{
				semaineDepuis1erVelage <- (jour-7)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine2 <- sommeBesoinVelageSemaine2 + besoin;
			}
			if jour >= 14{
				semaineDepuis1erVelage <- (jour-14)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine3 <- sommeBesoinVelageSemaine3 + besoin;
			}
			if jour >= 21{
				semaineDepuis1erVelage <- (jour-21)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine4 <- sommeBesoinVelageSemaine4 + besoin;
			}
		}
	}
	
	action calculerBesoinAnnuelMulti{
		int sommeBesoinVelageSemaine1 <- 0;
		int sommeBesoinVelageSemaine2 <- 0;
		int sommeBesoinVelageSemaine3 <- 0;
		int sommeBesoinVelageSemaine4 <- 0;
		loop jour from: IVV to:2*IVV {
			if jour mod 30 = 0 and jour != IVV{
					//Permet d'obtenir un besoin plus cohérent
				// il y a en moyenne 30.4 jours par mois
				sommeBesoinVelageSemaine1 <- int(sommeBesoinVelageSemaine1*30.4/30);
				sommeBesoinVelageSemaine2 <- int(sommeBesoinVelageSemaine2*30.4/30);
				sommeBesoinVelageSemaine3 <- int(sommeBesoinVelageSemaine3*30.4/30);
				sommeBesoinVelageSemaine4 <- int(sommeBesoinVelageSemaine4*30.4/30);
				add sommeBesoinVelageSemaine1 to: repartitionBesoinAnnuelMultiSemaine1;
				add sommeBesoinVelageSemaine2 to: repartitionBesoinAnnuelMultiSemaine2;
				add sommeBesoinVelageSemaine3 to: repartitionBesoinAnnuelMultiSemaine3;
				add sommeBesoinVelageSemaine4 to: repartitionBesoinAnnuelMultiSemaine4;
				sommeBesoinVelageSemaine1 <- 0;
				sommeBesoinVelageSemaine2 <- 0;
				sommeBesoinVelageSemaine3 <- 0;
				sommeBesoinVelageSemaine4 <- 0;
			}
		  //if jour >= 0 
				semaineDepuis1erVelage <- jour/7;
				int besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine1 <- sommeBesoinVelageSemaine1 + besoin;
			if jour >= 7{
				semaineDepuis1erVelage <- (jour-7)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine2 <- sommeBesoinVelageSemaine2 + besoin;
			}
			if jour >= 14{
				semaineDepuis1erVelage <- (jour-14)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine3 <- sommeBesoinVelageSemaine3 + besoin;
			}
			if jour >= 21{
				semaineDepuis1erVelage <- (jour-21)/7;
				besoin <- demarrerCalcul();
				sommeBesoinVelageSemaine4 <- sommeBesoinVelageSemaine4 + besoin;
			}
		}
	}
	
	float demarrerCalcul {
		do calculerRang;
		do calculerAge;
		do calculerPoids;
		do calculerNoteEtat;
		do calculerSemaineLactation;
		do calculerSemaineGestation;
		do calculerProductionLaitiere;
		do calculerCapaciteIngestion;
		besoinProteique <- demarrerCalculProt();
		besoinEnergetique <- demarrerCalculEnerg();
		return besoinProteique + besoinEnergetique;
	}
	
	float demarrerCalculProt {
		do calculerBesoinProteiqueGestation;
		do calculerBesoinProteiqueEntretien;
		do calculerBesoinProteiqueProductionLaitiere;
		return (besoinProteiqueEntretien + besoinProteiqueGestation + besoinProteiqueProductionLaitiere);
	}
	
	float demarrerCalculEnerg{
		do calculerBesoinEnergetiqueGestation;
		do calculerBesoinEnergetiqueEntretien;
		do calculerBesoinEnergetiqueProductionLaitiere;
		return (besoinEnergetiqueEntretien + besoinEnergetiqueGestation + besoinEnergetiqueProductionLaitiere);
	}
	
	action calculerRang{
//		if int(age1erVelage + semaineDepuis1erVelage*7/30.4)
//			<=	age1erVelage + 1/tauxDeRenouvellement*IVV/30.4 - (IVV-dureeLactation)/30.4{
//			rang <- int(1 + semaineDepuis1erVelage*7/IVV);
//		}else{
//			rang <- 0;
//		}
	}
	
	action calculerAge{
//		if rang = 0 {
//			age <- 0;
//		}else{
//			age <- int(age1erVelage + semaineDepuis1erVelage*7/30.4);
//		}
	}
	
	action calculerPoids{
//		if rang = 0 {
//			poids <- 0.0;
//		}else if rang = 1{
//			poids <- 0.8*poidsAuVelage + (0.2*poidsAuVelage) * (semaineDepuis1erVelage-(rang-1)*51) / (IVV/7);
//		}else{
//			poids <- -0.0003503*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^3) 
//					 +0.0761841*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^2)
//					 -3.0493099*((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51) + poidsAuVelage +3; 
//		}
	}
	
	action calculerNoteEtat{
//		if rang = 0 {
//			noteEtat <- 0.0;
//		}else{
//			noteEtat <- -0.000067*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^3) 
//						+0.005985*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^2) 
//						-0.130742*((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51) + noteEtatVelage +0.1; 
//		}
	}
	
	action calculerSemaineLactation{
//		if rang = 0 or semaineDepuis1erVelage > ((rang-1)*IVV/7 + dureeLactation/7){
//			semaineLactation <- 0;
//		}else{
//			semaineLactation <- int(max([0 , semaineDepuis1erVelage - round((rang-1)*IVV/7)]));
//		}
	}

	action calculerSemaineGestation{
//		if rang = 0
//		or semaineDepuis1erVelage < IVV/7*rang-9*4.5
//		or semaineDepuis1erVelage > IVV/7*rang{
//			semaineGestation <- 0;
//		}else{
//			semaineGestation <- int(semaineDepuis1erVelage-semaineLactationAvecInsemFecond-round(IVV/7*(rang-1)));
//		}
	}
	
	action calculerProductionLaitiere{
//		float coeffRang <- 1.0;
//		if rang = 1 {
//			coeffRang <- 0.8;
//		}
//		if semaineLactation >0{
//			productionLaitiere <- coeffRang*prodMaxLaitTheorique*(0.885*semaineLactation^0.2)*exp(-0.04*semaineLactation);
//		}else{
//			productionLaitiere <- 0.0;
//		}
	}
	
	action calculerCapaciteIngestion{
//		float IStade <- 1.0;
//		float IPar <- 1.0;
//		float INote <- 0.0015;
//		if semaineGestation>=40 or semaineLactation <= 1{
//			IStade <- 0.9;
//		}else if semaineGestation >= 39 and semaineGestation <40 
//			 and semaineGestation <= 2  and semaineLactation <= 2 {
//			IStade <- 0.95;
//		}else if semaineGestation >=9 and semaineGestation <= 14{
//			IStade <- 1.02;
//		}
//		if rang = 1 and semaineGestation!=0{
//			IPar <- 0.88;
//		}else if rang = 1 and semaineLactation/4.5<=3{
//			IPar <- 0.03*int(semaineLactation/4.5)+0.9;
//		}		
//		if semaineGestation>0{
//			INote <- 0.002;
//		}
//		capaciteIngestion <- IRace*IStade*IPar*(3.2+0.015*poids+0.25*productionLaitiere-INote*poids*(noteEtat-2.5));
	}
	
	action calculerBesoinEnergetiqueGestation{
//		if semaineGestation > 0{
//			besoinEnergetiqueGestation <- 0.00072 * poidsVeauNaissance * exp(0.116*semaineGestation);
//		}else{
//			besoinEnergetiqueGestation <- 0.0;
//		}
	}
	
	action calculerBesoinEnergetiqueEntretien{
//		float coefEntretien <- 1.1;
//		float coefEntretienPoids <- 0.037;
////		if situation = "Pâturage"{
//		if true{
//			coefEntretien <- 1.2;
//		}
//		if semaineLactation > 0{
//			coefEntretienPoids <- 0.041;
//		}
//		besoinEnergetiqueEntretien <- (coefEntretien*coefEntretienPoids+0.0068*(noteEtat-2.5))*poids^0.75;
	}
	
	action calculerBesoinEnergetiqueProductionLaitiere{
//		if semaineLactation > 0{
//			besoinEnergetiqueProductionLaitiere <- 0.45*productionLaitiere;
//		}else{
//			besoinEnergetiqueProductionLaitiere <- 0.0;
//		}
	}
	
	action calculerBesoinProteiqueGestation{
//		if semaineGestation > 0{
//			besoinProteiqueGestation <- 0.07*poidsVeauNaissance*exp(0.111*semaineGestation);
//		}else{
//			besoinProteiqueGestation <- 0.0;
//		}
	}
	
	action calculerBesoinProteiqueEntretien{
//		besoinProteiqueEntretien <- 3.25*poids^0.75;
	}
	
	action calculerBesoinProteiqueProductionLaitiere{
//		if semaineLactation > 0{
//			besoinProteiqueProductionLaitiere <- 53*productionLaitiere;
//		}else{
//			besoinProteiqueProductionLaitiere <- 0.0;
//		}
	}
	
}





