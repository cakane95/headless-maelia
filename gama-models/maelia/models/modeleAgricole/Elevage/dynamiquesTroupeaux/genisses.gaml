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
 *  Vaches Laitiere
 *  Author: Theo Bullat
 *  Description: 
 */

model genisses
import "bovinGenerique.gaml"


species genisses parent: bovinGenerique{
	
	float besoinEnergetique <- 0.0;
	float besoinProteique <- 0.0;
	int semaineDebutNaissance <- 12;
	int poidsNaissance <- 35;			// kg
	int ageAuSevrage <- 3;				// mois
	int ageAu1erVelage <- 36;			// mois
	int dureeVelageGroupe <- 5;			// semaines
	int poidsAuVelage <- 600; 			// kg	
	float semaineDepuisNaissance <- 0.0;
	
	list<int> besoinPourChaqueMois;
	matrix<int> besoinRepartie <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);

	action presentation{
		if !isInitialise{
			do initialiser;
		}
		write "\neffectif: \t\t\t\t"+effectif;
		write "ventes_ou_engraissement:"+ventes_ou_engraissement;
		write "sortie: \t\t\t\t"+sortie;
		write "entree: \t\t\t\t"+entree;

		write "Besoin: "+besoinRepartie;
	}

	action initialiser{
		int somme <- 0;
		loop effectifParMoi over:effectif {
			somme <- somme + int(effectifParMoi);
		}
		effectifMoyen <- somme / length(effectif);
		isInitialise <- true;
		
		do calculerBesoinAnnuel;
		do genererBesoinAnnuel;
		do supprimerBesoinApresVente;
	}
	
	action genererBesoinAnnuel{
		loop mois from: 0 to:11{
			int effectifDuMois <- entree[mois];
			do repartitionCourbeBesoinSurAnnee(effectifDuMois,mois);
		}
	}

	action repartitionCourbeBesoinSurAnnee(int local_effectif, int moisEffectif){
		loop mois from:0 to:11{
			int ancienneValeur <- besoinRepartie at{(mois+moisEffectif)mod 12,0};
			int nouveauxBesoin <- local_effectif*besoinPourChaqueMois[mois];
			put ancienneValeur + nouveauxBesoin at: {(mois+moisEffectif)mod 12,0} in:besoinRepartie;
		}
	}	
	
	action supprimerBesoinApresVente{
		matrix<int> besoinsDeTrop <- matrix([0,0,0,0,0,0,0,0,0,0,0,0]);
		matrix<int> copieEffectif <- matrix([[0,0,0,0,0,0,0,0,0,0,0,0],//ventes
											 [0,0,0,0,0,0,0,0,0,0,0,0]]);//entree
		 loop mois from:0 to: 11 {
			put ventes_ou_engraissement[mois] at: {0,mois} in: copieEffectif;
			put entree[mois] at: {1,mois} in: copieEffectif;
		}
		int moisFinVentes <- recupererDernierMois(copieEffectif,0);
		int moisFinEntree <- recupererDernierMois(copieEffectif,1);
		int nbGenisseVendu <- copieEffectif at{0,moisFinVentes};
		loop while: nbGenisseVendu != 0 {
			int nbGenisseVendable <- copieEffectif at {1,moisFinEntree};
			int nbGenisseTraite <- min([nbGenisseVendable,nbGenisseVendu]);
			int nbGenisseRestantes <- nbGenisseVendable-nbGenisseTraite;
			put nbGenisseVendu - nbGenisseTraite at:{0,moisFinVentes} in:copieEffectif;
			put nbGenisseRestantes at: {1,moisFinEntree} in:copieEffectif;
			do genererBesoinARetirer(besoinsDeTrop,besoinPourChaqueMois,moisFinEntree,moisFinVentes,nbGenisseTraite);
			moisFinEntree <- recupererDernierMois(copieEffectif,1);
			moisFinVentes <- recupererDernierMois(copieEffectif,0);
			nbGenisseVendu <- copieEffectif at{0,moisFinVentes};
		}
		loop mois from: 0 to: 11{
			int ancienneValeur <- besoinRepartie at {mois,0};
			put ancienneValeur - besoinsDeTrop at {mois,0} at:{mois,0} in:besoinRepartie;
		}
	}
	
	action genererBesoinARetirer(matrix besoinDeTrop,list<int> repartitionBesoinAnnuel, int moisDeVelage,int moisVentes,int nbVachesVendu){
		int mois <- moisDeVelage;
		bool genissesVendues <- false;
		loop besoinDuMois over: repartitionBesoinAnnuel {
			if genissesVendues {
				int ancienneValeur <- besoinDeTrop at {mois,0};
				put besoinDuMois*nbVachesVendu + ancienneValeur at:{mois,0} in: besoinDeTrop;
			}
			if mois = moisVentes {
				genissesVendues <- true;
			}
			mois <- (mois + 1) mod 12;
		}
	}

	action calculerBesoinAnnuel{
		int sommeBesoin <- 0;
		int annee <- choisirAnnee();
		loop jour from: 0 to: 360{
			if jour mod 30 = 0 and jour != 0{
				sommeBesoin <- int(sommeBesoin*30.4/30);
				add sommeBesoin to: besoinPourChaqueMois;
				sommeBesoin <- 0;
			}
			semaineDepuisNaissance <- (annee*360+jour)/7;
			int besoin <- demarrerCalcul();
			sommeBesoin <- sommeBesoin + besoin;
		}
	}
	
	action choisirAnnee{
		//Polymorphisme: On réécris l'action dans les classes filles afin de modifier l'année en fonction
	}
	
	
	
	action demarrerCalcul{
		do calculerPoids;
		do calculerSemaineGestation;
		do calculerCapaciteIngestion;
		do calculerBesoinEnergetique;
		do calculerBesoinProteique;
		return besoinEnergetique + besoinProteique;
	}

	action calculerPoids{
		poids <- poidsNaissance + (( poidsAuVelage - poidsNaissance)/(ageAu1erVelage*30.4/7))*semaineDepuisNaissance;
	}
	
	action calculerSemaineGestation{
		if semaineDepuisNaissance*7/30.4 >= age1erVelage - 9{
			semaineGestation <- semaineDepuisNaissance - round((age1erVelage-9)*30.4/7);
		}else{
			semaineGestation <- 0;
		}
	}
	
	action calculerCapaciteIngestion{
		if age1erVelage = 24 {
			capaciteIngestion <- 0.0168*semaineDepuisNaissance*7+1.0247;
		}else if age1erVelage = 29{
			capaciteIngestion <- 0.000005*((semaineDepuisNaissance*7)^2)+0.0091*(semaineDepuisNaissance*7)+1.9354;
		}else{
			capaciteIngestion <- 0.000000003*((semaineDepuisNaissance*7)^3)-0.000006*((semaineDebutNaissance*7)^2)+0.0135*(semaineDepuisNaissance*7)+1.4026;
		}
	}
	
	action calculerBesoinEnergetique{
		if age1erVelage = 24{
			besoinEnergetique <- 0.0119*semaineDepuisNaissance*7+1.8528;
		}else if age1erVelage = 29{
			besoinEnergetique <- 0.00004*((semaineDepuisNaissance*7)^2)+0.005*(semaineDepuisNaissance*7)+2.5679;
		}else{
			besoinEnergetique <- 0.00000003*((semaineDepuisNaissance*7)^3)-0.00004*(semaineDepuisNaissance*7)^2+0.0178*(semaineDepuisNaissance*7)+1.7251;
		}
	}
	
	action calculerBesoinProteique{
		if age1erVelage = 24{
			besoinProteique <- 0.975*semaineDepuisNaissance*7+276.31;
		}else if age1erVelage = 29{
			besoinProteique <- 0.0003*((semaineDepuisNaissance*7)^2)+0.3589*(semaineDepuisNaissance*7)+328.35;
		}else{
			besoinProteique <- 0.000003*((semaineDepuisNaissance*7)^3)-0.0039*(semaineDepuisNaissance*7)^2+1.4426*(semaineDepuisNaissance*7)+256.83;
		}
	}
}


