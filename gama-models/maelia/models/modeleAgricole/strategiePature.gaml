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
 *  strategiePature
 *  Author: Renaud Misslin
 *  Description: pature des prairies, fonctionne avec herbsim
 */

model strategiePature

import "Ilots/ilot.gaml"
import "strategieOT.gaml"

global{
	string modeGestionprairie <- nil; // Peut être égal à "hauteurHerbe" ou "quantiteBiomasse"
}

species strategiePature parent: strategieOT {
	list<strategiePatureMultiples> mesStrategiesMultiples; 

	// La pature fonctionne avec une fenêtre large et une fenêtre ressérée :
	// - La fenêtre large (ex : du jour 60 au jour 305) est une fenêtre dans laquelle les contraintes peuvent être élevées
	// - La fenêtre ressérée (ex : du jour 75 au jour 290) est une fenêtre dans laquelle les contraintes peuvent être plus lâches (pour être certain que les animaux soient en pature). La fenêtre ressérée est toujours comprise dans la fenêtre large
	map<int,int> fenetre_debut; // Premier élément de la map = Debut fenêtre large | Deuxième élément de la map = début fenêtre ressérée
	map<int,int> fenetre_fin; // Premier élément de la map = Fin fenêtre large | Deuxième élément de la map = Fin fenêtre ressérée

	// Caractéristiques et contraintes générales de la pature (indépendantes des fenêtres large / ressérée)
	int tempsPature; // Nombre de joursmax durant lesquels un lot peut rester sur une parcelle
	int tempsReposParcelle; // Temps de repos de la parcelle avant paturage à nouveau possible
	float coefHerbeAccessible; // Coefficient d'herbe utilisable par les animaux sur une parcelle
	float HauteurHerbeMinEntree; // Au moins x cm de hauteur d'herbe pour faire entrer les animaux sur la parcelle
	float HauteurHerbeMaxSortie; // Si hauteur d'herbe est en-dessous de x cm alors on fait sortir les animaux de la parcelle
	float QuantiteBiomasseMin;
	float DigestabiliteMin;
	float SeuilBiomasseLimiteSiFauche; // Seuil de biomasse à partir duquel la pature n'est plus possible (après le 1er août)
	
	map<int,int> mapFenetresTemporellesHauteurHerbeMinEntree <- map<int,int>([]);
	map<int,int> mapFenetresTemporellesHauteurHerbeMaxSortie <- map<int,int>([]);
	map<int,int> mapFenetresTemporellesPatureVolumeMin <- map<int,int>([]);
	map<int,int> mapFenetresTemporellesPatureDigestabiliteMin <- map<int,int>([]);
	//map<int,int> mapFenetresTemporellesHumiditeSolMax <- map<int,int>([]);
	map<int,int> mapFenetresTemporellesPatureSommeDegresJ <- map<int,int>([]);

	map<int,float> mapNbJoursPluiePrevues <- map<int,float>([]);
	map<int,float> mapHauteurPluiePrevuesMax <- map<int,float>([]);
	
	// Dans les contraintes spécifique à chaque période, le premier élément se rapporte à la fenêtre large, le deuxième élément se rapporte à la fenêtre ressérée
	//map<int,float> mapHumiditeSolMax <- map<int,float>([]);
	map<int,float> mapDegresJMin <- map<int,float>([]);

	/*
	 * *****************************************************************************************
	 */	


	/*
	 * *****************************************************************************************
	 */
	
	// 
 	
 	// Test d'entrée d'un lot sur une parcelle
	bool isPaturable(parcelle parcelleEntree, int deltaTemporel, float besoinsHerbeJ){
		bool estOk <- false;
//		write 'HERBSIM Renaud - test d entrée sur une parcelle';
		if(parcelleEntree.cultureParcelle != nil){ // Il faut qu'il y ait une prairie qui pousse
			// Test des contraintes
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				estOk <- isHauteurHerbeEntreeOk(parcelleEntree, deltaTemporel)
								and isHumiditeSolOK(parcelleEntree, deltaTemporel)
								and isQuantiteHerbeSortieOk(parcelleEntree, deltaTemporel, 0.0, besoinsHerbeJ)
								and isCumuleHauteurPluieOK(parcelleEntree, deltaTemporel)
								and isCumuleHauteurPluiePrevuesOK(parcelleEntree.ilot_app.meteo, parcelleEntree,deltaTemporel)
								and isPaturableSiFauchable(parcelleEntree);
			}
//			write "--";	
//			write "HERBSIM Renaud - isPaturable - parcelleEntree : " +  parcelleEntree
//				+ " -- culture : " + parcelleEntree.cultureParcelle.espece.idEspeceCultivee
//				+ " -- fenetre : " +  isFenetreTemporelleOk(parcelleEntree, deltaTemporel)
//				+ " -- hauteur d'herbe entrée : " +  isHauteurHerbeEntreeOk(parcelleEntree, deltaTemporel)
//				+ " -- humidité sol : " +  isHumiditeSolOK(parcelleEntree, deltaTemporel)
//				+ " -- OK : " +  estOk;
		}
		

		
		// Si toutes les contraintes sont remplie, la sortie n'est pas obligaoire, sinon elle l'est (on inverse estOk pour avoir le résultat)
		return estOk;
	}

	bool isCumuleHauteurPluiePrevuesOK(zoneMeteo zoneMeteoIlotAssocie, parcelle parcelleEntree, int deltaTemporel){
		bool res <- true;			
		if(isDonnee(mapNbJoursPluiePrevues, parcelleEntree, deltaTemporel) and
			isDonnee(mapHauteurPluiePrevuesMax, parcelleEntree, deltaTemporel)
		){		
			int nbJour <- int(getDonneeCourante(mapNbJoursPluiePrevues,parcelleEntree, deltaTemporel));
			float hauteur <- getDonneeCourante(mapHauteurPluiePrevuesMax,parcelleEntree, deltaTemporel);
			ask zoneMeteoIlotAssocie {
				res <- (getMaxPluiesPrevues(nb_jours:nbJour) * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= hauteur);
			}				
		}		
		return res;
	}
	
	// isNonPaturable SI l'itk en cours est fauchable ET paturable (au printemps à partir du 1er avril, en automne à partir d'un seuil de biomasse) il peut être considéré comme non paturable
	bool isPaturableSiFauchable(parcelle parcelleEntree) {
		bool result <- true;
		// D'abord on teste si l'itk est également fauchable
		if (parcelleEntree.getITKAnnee().strategieFaucheITK != nil) {
//			write "Paturage -> test d'une parcelle à la fois fauchée et paturée";
			if (dateCour.nbJoursEcoulesDansAnnee < 213) { // Si on est avant le 1er aout
				// Si on est après le 1er avril, le paturage n'est plus permis sur les parcelles fauchable
				if (dateCour.nbJoursEcoulesDansAnnee >= 91) {
					result <- false;
				}
//				write "Paturage de fin de printemps possible (après j 91)-> " + result;
			} else { // Si on est le 1er aout ou après et qu'il y a une valeur seuil renseignée en rdd
				if (SeuilBiomasseLimiteSiFauche != 0.0) {
					if (parcelleAqYield(parcelleEntree).getQuantiteHerbe() >= SeuilBiomasseLimiteSiFauche * 1000) { // On récupèrele seuil de biomasse à partir duquel le paturage est interdit après le 1er aout (seuil donné en t dans les rdd, converti en kg ici)
						result <- false;
					}
//					write "Paturage de fin d'été possible (après j 213) -> " + result;
				}
			}
		} else {
//			write "Paturage -> test d'une parcelle seulement paturée";
		}
		
		return result;
	}

 	// Test d'entrée d'un lot sur une parcelle entre le 15 mai et le 15 aout et entre le 15 octobre et le 15 décembre : on ne regarde que les contraintes de dates
	bool isPaturableFinSaison(parcelle parcelleEntree, int deltaTemporel, float besoinsHerbeJ){
		bool estOk <- false;
		if(parcelleEntree.cultureParcelle != nil){ // Il faut qu'il y ait une prairie qui pousse
			// Test des contraintes
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				estOk <- isQuantiteHerbeSortieOk(parcelleEntree, deltaTemporel, 0.0, besoinsHerbeJ);
				
			}
				
//			write "HERBSIM Renaud - isPaturableFinSaison - parcelleEntree : " +  parcelleEntree
//				+ " -- culture : " + parcelleEntree.cultureParcelle.espece.idEspeceCultivee
//				+ " -- fenetre : " +  isFenetreTemporelleOk(parcelleEntree, deltaTemporel)
//				+ " -- OK : " +  isQuantiteHerbeSortieOk(parcelleEntree, deltaTemporel, 0.0, besoinsHerbeJ);
		}
		

		
		// Si toutes les contraintes sont remplie, la sortie n'est pas obligaoire, sinon elle l'est (on inverse estOk pour avoir le résultat)
		return estOk;
	}
 	
 	// Test de sortie de pature
	bool isSortieObligatoire(parcelle parcelleEntree, int deltaTemporel, float herbeDejaConso, float besoinsHerbeJ){
		bool neDoitPasSortir <- false;
		if(parcelleEntree.cultureParcelle != nil){ // Il faut qu'il y ait une prairie qui pousse
//		write "herbeDejaConso sur la parcelle = " + herbeDejaConso;
			// Test des contraintes
			if(isFenetreTemporelleOk(parcelleEntree, deltaTemporel)){
				neDoitPasSortir <- // isDureePaturageParcelleOk(parcelleEntree, dureePaturageEffectuee) // si vrai alors ne doit pas sortir
								// and 
								isHauteurHerbeSortieOk(parcelleEntree, deltaTemporel) // si vrai alors ne doit pas sortir
								and isHumiditeSolOK(parcelleEntree, deltaTemporel)
								and isQuantiteHerbeSortieOk(parcelleEntree, deltaTemporel, herbeDejaConso, besoinsHerbeJ)
								and isPaturableSiFauchable(parcelleEntree); // si vrai alors ne doit pas sortir
								
			}
		}
		
//		write "HERBSIM Renaud - isSortieObligatoire - parcelleEntree : " +  parcelleEntree
//			+ " -- hauteur d'herbe sortie : " +  isHauteurHerbeSortieOk(parcelleEntree, deltaTemporel) 
//			+ " -- humidité sol : " +  isHumiditeSolOK(parcelleEntree, deltaTemporel)
//			+ " -- qte herbe : " + isQuantiteHerbeSortieOk(parcelleEntree, deltaTemporel, herbeDejaConso, besoinsHerbeJ) + "(conso = " + herbeDejaConso + " -- conso+j = " + (herbeDejaConso+besoinsHerbeJ) + " - dispo = " + (parcelleAqYield(parcelleEntree).getQuantiteHerbe() * coefHerbeAccessible) +  ")"
//			+ " -- Sortie obligatoire: " +  !neDoitPasSortir;
//		
		
		// Si toutes les contraintes sont remplie, la sortie n'est pas obligaoire, sinon elle l'est (on inverse estOk pour avoir le résultat)
		return !neDoitPasSortir; // On inverse car si neDoitPasSortir est faux alors sortie est obligatoire
	}
	

	// Durée de paturage sur la parcelle courante 
	bool isDureePaturageParcelleOk (parcelle parcelleEntree, int dureeRealisee) { // si vrai alors ne doit pas sortir
		bool res <- true;
		if (parcelleEntree.isParcelleHorsZone){
			res <- false; 
		}else{
			if(tempsPature != nil){
				res <- dureeRealisee <= tempsPature;
			}else{
				res <- false;
			}				
		}
//		write "dureeRealisee = " + dureeRealisee + " -- tempsPature = " + tempsPature;
		return res;
	}

	// La hauteur de l'herbe sur la parcelle est-elle suffisante pour accueillir un lot ? //verif
	bool isHauteurHerbeEntreeOk (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;			
		if(isDonnee(mapFenetresTemporellesHauteurHerbeMinEntree, parcelleEntree, deltaTemporel)){
			res <- parcelleAqYield(parcelleEntree).getHauteurHerbe() >= getDonneeCourante(mapFenetresTemporellesHauteurHerbeMinEntree, parcelleEntree, deltaTemporel) * 0.8; // On prend 80 % de la valeur de hauteur donnée en entrée
		}else{
			res <- false;
		}		
		return res;
	}

	// La hauteur d'herbe de la parcelle courant est-elle inférieure à la hauteur d'herbe à partir de laquelle le lot doit sortir ? //verif
	bool isHauteurHerbeSortieOk (parcelle parcelleEntree, int deltaTemporel) { // si vrai alors ne doit pas sortir
		bool res <- false;			
		if(isDonnee(mapFenetresTemporellesHauteurHerbeMaxSortie, parcelleEntree, deltaTemporel)){
			res <- parcelleAqYield(parcelleEntree).getHauteurHerbe() >= getDonneeCourante(mapFenetresTemporellesHauteurHerbeMaxSortie, parcelleEntree, deltaTemporel); 
		}else{
			res <- parcelleAqYield(parcelleEntree).getHauteurHerbe() >= 3; // Par défaut on prend 3 cm comme valeur de sortie
		}

//		write "hauteur courante = " + parcelleAqYield(parcelleEntree).getHauteurHerbe() + " >= hauteur de sortie = " + getDonneeCourante(mapFenetresTemporellesHauteurHerbeMaxSortie, parcelleEntree, deltaTemporel);
		return res;
	}
	
	// La quantité d'herbe disponible sur la parcelle est-elle supérieure à la qte d'herbe déjà consommée + la d'herbe nécessaire aujourd'hui
	bool isQuantiteHerbeSortieOk (parcelle parcelleEntree, int deltaTemporel, float herbeDejaConso, float besoinsHerbeJ) { // si vrai alors ne doit pas sortir
		bool res <- false;			
		res <- parcelleAqYield(parcelleEntree).getQuantiteHerbe() * coefHerbeAccessible >= herbeDejaConso + besoinsHerbeJ;

//		write "" + parcelleEntree + " Quantité herbe courante (abbatue coef) = " + (parcelleAqYield(parcelleEntree).getQuantiteHerbe() * coefHerbeAccessible) + " >= besoins cumulés = " + (herbeDejaConso + besoinsHerbeJ);
		return res;
	}	
	
	// Test humidité du sol (fenêtre large / fenêtre resserée) //verif
//	bool isHumiditeSolOK (parcelle parcelleEntree, int deltaTemporel) {
//		bool res <- false;			
//		if(isDonnee(mapFenetresTemporellesHumiditeSolMax, parcelleEntree, deltaTemporel)){
//			res <- parcelleEntree.getHumiditeSol() * parcelleEntree.ilot_app.agriculteurAssocie.biaisPerceptionEau <= getDonneeCourante(mapFenetresTemporellesHumiditeSolMax, parcelleEntree, deltaTemporel); // JV 121220 suppression correction tauxArgile cf Mantis #0002747
//			
//			if (getDonneeCourante(mapFenetresTemporellesHumiditeSolMax, parcelleEntree, deltaTemporel) = 1) { // HumiditéOK forcée si la valeur de la sous-période est égale à 1 (puisque la valeur est fixée à 1 dans l'objectif de forcer l'opé)
//				res <- true;
//			}
//			
//		} else {
//			res <- false;
//		}
//		return res;
//	}
	
	// Test degrés jour de la prairie      cultureHerbSim(parcelleEntree.cultureParcelle).ThermalAge >= mapDegresJMin[num_fenetre];
	bool isDegresJourOk (parcelle parcelleEntree, int deltaTemporel) {
		bool res <- false;			
		if(isDonnee(mapFenetresTemporellesHauteurHerbeMinEntree, parcelleEntree, deltaTemporel)){
			res <- parcelleAqYield(parcelleEntree).getHauteurHerbe() < getDonneeCourante(mapFenetresTemporellesHauteurHerbeMaxSortie, parcelleEntree, deltaTemporel);
		}else{
			res <- true;
		}		
		return res;
		
	}
	
	action ecrituresSortiesPature(parcelle parcelle_courante, lotAnimaux lot_courant) {
		if parcelle_courante.memoireOTsurParcelle.keys contains PATURE {
			ask parcelle_courante{
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at PATURE);
				
				string id_lot_courant <- lot_courant.idLotAnimaux;
				float nb_ugb <- lot_courant.nb_UGB;
				float herbe_conso <- lot_courant.herbeConsoParcelleCourante; //[t/ha]
				int duree_pature <-  lot_courant.tempsPatureParcelleCourante; 
				
				map<string,string> complements <- [];
				complements <- ["id_lot"::string(id_lot_courant),"nb_ugb"::string(nb_ugb),"duree_pature"::string(duree_pature),"herbe_consommee"::string(herbe_conso with_precision nb_decimales_sorties)];
				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at PATURE);	
			}
		}
	}

}	

