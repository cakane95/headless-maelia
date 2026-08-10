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
 *  bovinGenerique
 *  Author: Theo Bullat
 *  Description: agents generique, representant toutes les caracteristiques communes a tous les bovins.
 */

model bovinGenerique


species bovinGenerique{
	list<int> effectif;
	list<int> ventes_ou_engraissement;
	list<int> sortie;
	list<int> entree;
	
	int rang;
	int age;
	float poids;
	float noteEtat;
	int semaineLactation;
	int semaineGestation;
	float productionLaitiere;
	float capaciteIngestion;
	float besoinEnergetiqueCroissance;
	float besoinEnergetiqueGestation;
	float besoinEnergetiqueEntretien;
	float besoinEnergetiqueProductionLaitiere;
	
	float besoinProteiqueCroissance;
	float besoinProteiqueGestation;
	float besoinProteiqueEntretien;
	float besoinProteiqueProductionLaitiere;
	
//	bool isVelageGroupes <- true;
//	int semaineDebutVelagesPrimi <- 4; // [semaines]    Non utilisé
//	int dureeVelageGroupe <- 10; //[semaines]

	float tauxDeRenouvellement <- 0.20;
	int age1erVelage <- 24; //[mois]
	int poidsAuVelage <- 750; //[kg]
	float noteEtatVelage <- 2.5;
	int prodLaitTheorique <- 9000; // [kg/an]
	float prodMaxLaitTheorique <- 6.5; // [kg/jour]
	int dureeLactation <- 305; //[jours]
	int poidsVeauNaissance <- 42; //[kg]

	float semaineDepuis1erVelage <- 0.0;
	int semaineLactationAvecInsemFecond <- 18;
	
	float effectifMoyen <- 0.0;
	float UGB;
	bool isInitialise <- false;
	
	
	
	action initialiser{
		int somme <- 0;
		loop effectifParMoi over:effectif {
			somme <- somme + effectifParMoi;
		}
		effectifMoyen <- somme / length(effectif);
		isInitialise <- true;
	}
	
	action presentation{
		if !isInitialise{
			do initialiser;
		}
		write "\neffectif: \t\t\t\t"+effectif;
		write "ventes_ou_engraissement:"+ventes_ou_engraissement;
		write "sortie: \t\t\t\t"+sortie;
		write "entree: \t\t\t\t"+entree;

		write "effectifMoyen: \t\t\t"+effectifMoyen;
	}
	
	//Permet de recuperer le mois de velage où se trouve les vaches les plus jeunes
	int recupererPremierMois(matrix<int> tableauEffectif,int ligne){
		int moisDebut <- 0;
		int protectionInfini <- 0;
		int valueTest <- tableauEffectif at {ligne,moisDebut mod 12};
		// On avance jusqu'a ce qu'on tombe sur un mois de velage
		loop while: valueTest = 0 {
			moisDebut <- moisDebut + 1;
			valueTest <- tableauEffectif at {ligne,moisDebut mod 12};
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 1;
			}
		}
		valueTest <- 1;
		// On recul jusqu'au dernier mois sans velage
		loop while: valueTest != 0 {
			// correspond à mois <- mois - 1
			moisDebut <- (moisDebut + 11) mod 12 ;
			valueTest <- tableauEffectif at {ligne,(moisDebut+12)mod 12};
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 0;
			}
		}
		// On ajoute un pour obtenir le premier mois de velage.
		return (moisDebut+1)mod 12;
	}
	
	//Permet de recuperer le mois où se trouve les vaches les plus agées qui vont être vendus afin de les enlever des sorties
	int recupererDernierMois(matrix<int> tableauEffectif,int ligne){
		int dernierMois <- 0;
		int protectionInfini <- 0;
		int valueTest <- tableauEffectif at {ligne,(dernierMois+12)mod 12};
		// On recul jusqu'au dernier mois sans velage
		loop while: valueTest = 0 {
			// correspond à mois <- mois - 1
			dernierMois <- (dernierMois + 11) mod 12 ;
			valueTest <- tableauEffectif at {ligne,(dernierMois+12)mod 12};
			//Permet de sortir de la boucle si l'effectif est vide.
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 1;
			}
		}
		protectionInfini <- 1;
		// On avance jusqu'a ce qu'on tombe sur un mois de velage
		loop while: valueTest != 0 {
			dernierMois <- dernierMois + 1;
			valueTest <- tableauEffectif at {2,dernierMois mod 12};
			protectionInfini <- protectionInfini +1;
			if protectionInfini > 13 {
				valueTest <- 0;
			}
		}
		// On enleve un pour obtenir le dernier mois de velage.
		return (dernierMois+11)mod 12;
		}
}

