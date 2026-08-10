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
 *  Agriculteurs
 *  Author: Romain Lardy
 *  Description: Cet agent est directement lié au bloc de parcelles et à un itk et donc indirectement à l'agriculteur
 *  Il a pour but premier de mémoriser les informations nécessaires au calcul des critères du choix d'assolement
 *  par fonction de croyance. Il sert également à mémoriser les informations nécessaires pour gérer les sorties
 */

model memoire

import "../Ilots/ilot.gaml"

global{	
	string cheminInitRendement  <-  '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers +
	 								'/modeleAgricole/marcheAgricole/rendementsObservesAnterieur.csv' ;

	

	
	action constructionMemoires{
		// On lit les rendements observes sur les annes precedentes afin des les affecter a memoire
		// First we read previously observed yield in order to put them into the farmers memory
		map<itk, map<int,float>> rdtObs <- map([]);
		if (file_exists(cheminInitRendement)){
			matrix InitRendement <- matrix(csv_file(cheminInitRendement,";",false));
			//matrix InitRendement <- matrix(file(cheminInitRendement));
			
			int nbColones <- length(InitRendement row_at 0);
			int nbLignes <- length(InitRendement column_at 0);
			list annee <-  ( InitRendement row_at 0 );
			
			loop i from: 1 to: (nbLignes -1){ //boucle sur les itk
				list ligneCourante <-  ( InitRendement row_at i );
				itk it <- listeITKs[i-1];
				map<int,float> rdtObsEspece <- map<int,float>([]);
				loop j from: 2 to: (nbColones -1){ //boucle sur les annees
					put float(ligneCourante at (j)) at: int(annee at (j)) in:rdtObsEspece ;
				}
				put rdtObsEspece at: it in: rdtObs ;
				
			}
			
		}else{
			do raiseWarning("fichier inexistant: " + cheminInitRendement + " pas d'historique de rendement fourni");
			//write "Pas d'historique de rendement fourni";
		}
			
		ask listeAgriculteurs{
			string dept <- sonExploitation.id_departement; 
			loop bl over: listBloc{	
				list<itk> listItk <- [];
		    	if (nomChoixAssolement = 'Donnees') {
		    		if(!itkParPrecedent){
			    		systemeDeCultureDeReference sdcDuBloc <- mapSystemesDeCultureDeRef at bl.idSdcRefInitialDuBloc;
						listItk <- sdcDuBloc.listeITKsPossibles; //TODO a filtrer par nature de sol ?
					}else{
						// JV si ITK par précédent: listItk est l'union des ITK de chaque parcelle 
						ask bl.listeParcellesBloc{
							listItk <<+ systemeDeCultureParcelle.rotation;
							// write "bloc " + bl.idBloc + " parcelle " + idParcelle + " ajout ITK " + systemeDeCultureParcelle.rotation;  // JV debug
						}
						// write "bloc " + bl.idBloc + " listItk " + listItk; // JV debug
					}
					listItk <- remove_duplicates(listItk);
		    	}else{
		    		listItk <- (itk as list);
		    	}
				
				loop it over: listItk{
					//filtre pour mode AgriDonne
					
				    if ((bl.materielDuBloc != nil) or (!it.isIrriguee())
				    	and (bl.materielDuBloc = it.matITK)
				    ){
				    	
						create memoire returns: mem{
							itkAssocie <- it;
							blocMemoire <- bl;
							map<int,float> tmp <- (rdtObs at it) ;
							do setRendementObserveAnterieur(tmp);

							float surf <- float(nombreMeterCarreDansUnHectare);
							
							if leMarcheAgricole!=nil { // JV 100821
							
								tmp <- map<int,float>([]);
								loop y over: leMarcheAgricole.prix_recoltes_par_annee.keys{
									put ((leMarcheAgricole.prix_recoltes_par_annee at y) at it.especeCultiveeITK) at: y in: tmp;
								}
								do setPrixObserveAnterieur(tmp);
								
								tmp <- map<int,float>([]);
								loop annee_prime over: leMarcheAgricole.primes_par_annee_par_departement.keys{
	// TODO Ben : Inutile ??				put ((leMarcheAgricole.primes_par_annee_par_departement at annee_prime) at it.especeCultiveeITK) at: annee_prime in: tmp;
									map<especeCultivee, float> prime_par_espece <- ((leMarcheAgricole.primes_par_annee_par_departement at annee_prime) at dept);
									put (prime_par_espece at it.especeCultiveeITK) at: annee_prime in: tmp;
								} 
								do setPrimesObserveAnterieur(tmp);
	
								tmp <- map<int,float>([]);
								loop y over: leMarcheAgricole.chargesOp_par_annee.keys{
									put ((leMarcheAgricole.chargesOp_par_annee at y) at it) at: y in: tmp;
								}
								do setChargesOpAnterieur(tmp);
								
								tmp <- map<int,float>([]);
								loop y over: leMarcheAgricole.chargesPassage_par_annee.keys{
									put (leMarcheAgricole.chargesPassage_par_annee at y) at it at: y in: tmp;
								}
								do setChargesDePassageAnterieur(tmp);
								
							} // if leMarcheAgricole!=nil
														
							float tempsTravailReferenceEspece <- 0.0;
							
							if (it.strategieSemisITK != nil) {
								tempsTravailReferenceEspece <- surf / it.strategieSemisITK.tempsDexecution; //tempsDexecution est exprime en m2/h
							}
							if (it.strategieRecolteITK != nil ) {
								tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / it.strategieRecolteITK.tempsDexecution);
							}
							
							if (it.strategieBinageSolITK != nil ) {
								tempsTravailReferenceEspece <- tempsTravailReferenceEspece + surf / it.strategieBinageSolITK.tempsDexecution;
							}
							if (it.strategieTravailSolITK != nil ) {
								if !(plusieursTravauxDuSolParITK) { // Gestion Travail du sol multiples Renaud 18/03/2020
									tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / it.strategieTravailSolITK.tempsDexecution);
								} else {
									loop OTmultiple over: it.strategieTravailSolITK.mesStrategiesMultiples {
										tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / OTmultiple.tempsDexecution);
									}
								}
							}
							if (it.strategieIrrigationITK != nil ) {
								tempsTravailReferenceEspece <- tempsTravailReferenceEspece + 
								((surf / bl.materielDuBloc.surfaceIrrigableParJour) / it.strategieIrrigationITK.periodeTourEau 
									* it.strategieIrrigationITK.getNbJoursFenetreTemporelle() * bl.materielDuBloc.tempsDeTravailParJour
								);
							}
							if (it.strategieRepriseTravailSolITK != nil ) {
								tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / it.strategieRepriseTravailSolITK.tempsDexecution);
							}
							if (it.strategieFertiITK != nil ) {
								if !(plusieursFertilisationsParITK) { // Fertilisation PRO Renaud 20/03/2020
									tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / it.strategieFertiITK.tempsDexecution) * it.strategieFertiITK.nbSousPeriode;
								} else {
									//write "-ITKferti- apports_alternative_preferee -> " + it.strategieFertiITK.mesStrategiesFertiAlternative[0].mesApports ;
									loop apports_alternative_preferee over: it.strategieFertiITK.mesStrategiesFertiAlternative[0].mesApports {
										//write "-ITKferti- tempsTravailReferenceEspece -> " + tempsTravailReferenceEspece;
										//write "-ITKferti- surf -> " + surf;
										//write "-ITKferti- apports_alternative_preferee.tempsDexecution -> " + apports_alternative_preferee.tempsDexecution;
										tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / apports_alternative_preferee.tempsDexecution);
									}
								}
							}
							if (it.strategiePhytoITK != nil ) {
								if !(plusieursTraitementsPhytoParITK) { // Gestion Traitements phyto multiples Renaud 200323
									tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / it.strategiePhytoITK.tempsDexecution) * it.strategiePhytoITK.nbSousPeriode;
								} else {
									loop OTmultiple over: it.strategiePhytoITK.mesStrategiesMultiples {
										tempsTravailReferenceEspece <- tempsTravailReferenceEspece + (surf / OTmultiple.tempsDexecution);
									}
								}
							}
							do setTempsTravauxAnterieur(tempsTravailReferenceEspece);
							
						}
						listMemoire << first(mem);
				    }
				}
			}
		}
	}

}	

	
species memoire {
	itk itkAssocie <- nil; //we create an agent per itk //on va creer un agent par itk
	bloc blocMemoire <- nil;
	map<int,float> recolteObserves <- map<int,float>([]); //key will be years and value will be sum of yields 
	map<int,float> surfaceCumule <- map<int,float>([]); //and their associated surface //[m2]
	map<int,int> nbParcelles <- map<int,int>([]); // and the number of parcels
	map<int,float> prix <- map<int,float>([]); //and their price //TODO factoriser cette info ?
	map<int,float> chargesOp <- map<int,float>([]); //and their associated operating expences
	map<int,float> chargesFixes <- map<int,float>([]); //and the over field associated operating expences
	map<int,float> primes <- map<int,float>([]); //and their payments //TODO factoriser cette info ?
    map<int,float> tempsTravaux <- map<int,float>([]); //and their working time
    map<int,int> nbParcellesNonSemees <- map<int,int>([]); // JV 20022020  key: year value: nb of not sown fields, used in resultatsAssolement_espece (bug #0002487)
    map<int,float> surfParcellesNonSemees <- map<int,float>([]); // JV 20022020  key: year value: surface [m2] of not sown fields, used in resultatsAssolement_espece (bug #0002487)
    map<int,int> nbParcellesRecolteForcee <- map<int,int>([]); // JV 20022020  key: year value: nb of forced harvest fields, used in resultatsAssolement_espece (bug #0002487)
    map<int,float> surfParcellesRecolteForcee <- map<int,float>([]); // JV 20022020  key: year value: surface [m2] of forced harvest fields, used in resultatsAssolement_espece (bug #0002487)
    
    
    list<float> listeVariabiliteProfit <- []; //to avoid to calculate this liste more than once per year
    bool listeVariabiliteProfitDejaCalcule <- false;
	
	string toString {
		string res <- "Memoire : \n";
		res <- res + chargesOp + "\n";
		res <- res + chargesFixes + "\n";
		return res;
	}
	
	/*
	 * To get the second best observed yield for the species over the five last occurences
	 * Pour avoir le deuxieme meilleur rendement observe sur les cinq derniere occurences 
	 */
	float get2ERendementsObserves5ans{
		int i <-0;
		float meilleurRDT <- 0.0;
		float RDT2 <- 0.0; //deuxieme meilleur rendement
		int y<- dateCour.annee;
		loop while: ((i<5) and (y > anneeDebutSimulation-5)){ // tant que on a pas les 5 éléments
															 // où qu'on a parcouru toute la liste
			float rdt <- (recolteObserves at y);
			if (rdt >0.0){
				rdt <- rdt / (surfaceCumule at y) *nombreMeterCarreDansUnHectare; //t/ha
				if (rdt > RDT2){
					if (rdt > meilleurRDT){
						RDT2 <- meilleurRDT;
						meilleurRDT <- rdt;
					}else{
						RDT2 <- rdt;
					}
				}
				i <- i + 1;
			}
			y <- y - 1;
		}
		return RDT2;
	}
	
	float get2EPrixObserves3ans{ // l'algo est construit de manière générique pour pouvoir facilement être etendu
	// a une recherche sur N anne (ici 3)
		float secondPrix <- 0.0;
		int i <-0;
		float meilleurPrix <- (leMarcheAgricole.prix_recoltes at itkAssocie.especeCultiveeITK);
		int y<- dateCour.annee -1;
		loop while: ((i<2) and (y > anneeDebutSimulation-2)){ // tant que on a pas les 2 éléments supplémentaires
															 // où qu'on a parcouru toute la liste
			float prix_local <- (prix at y);
			if (prix_local >0.0){ //Si il y a un prix
				if (prix_local > secondPrix){
					if (prix_local > meilleurPrix){
						secondPrix <- meilleurPrix;
						meilleurPrix <- prix_local;
					}else{
						secondPrix <- prix_local;
					}
				}
				i <- i + 1;
			}
			y <- y - 1;
		}
		return secondPrix;
	}
	
	float get2EChargesOp3ans{ // l'algo est construit de manière générique pour pouvoir facilement être etendu
	// a une recherche sur N anne (ici 3)
		int nbAnneDeRecherche <- 3;
		float chargeOp2EME <- 0.0;
		int i <-0;
		float maxCharges <- 0.0;
		int y<- dateCour.annee -1;
		loop while: ((i<nbAnneDeRecherche) and (y > anneeDebutSimulation-nbAnneDeRecherche)){ // tant que on a pas les 3 éléments
															 // où qu'on a parcouru toute la liste
			float charges_local <- (chargesOp at y);
			if (charges_local >0.0){
				charges_local <- charges_local / (surfaceCumule at y) * nombreMeterCarreDansUnHectare;  //[€/ha]
				if (charges_local > chargeOp2EME){
					if (charges_local > maxCharges){
						chargeOp2EME <- maxCharges;
						maxCharges <- charges_local;
					}else{
						chargeOp2EME <- charges_local;
					}
				}
				i <- i + 1;
			}
			y <- y - 1;
		}
		return chargeOp2EME;
	}
	//
	
	float get2EChargesDePassage3ans{ // l'algo est construit de manière générique pour pouvoir facilement être etendu
	// a une recherche sur N anne (ici 3)
		int nbAnneDeRecherche <- 3;
		float chargeDePassage2EME <- 0.0;
		int i <-0;
		float maxCharges <- 0.0;
		int y<- dateCour.annee -1;
		loop while: ((i<nbAnneDeRecherche) and (y > anneeDebutSimulation-nbAnneDeRecherche)){ // tant que on a pas les 3 éléments
															 // où qu'on a parcouru toute la liste
			float charges_local <- (chargesFixes at y);
			if (charges_local >0.0){
				charges_local <- charges_local / (surfaceCumule at y) * nombreMeterCarreDansUnHectare; //[€/ha]
				if (charges_local > chargeDePassage2EME){
					if (charges_local > maxCharges){
						chargeDePassage2EME <- maxCharges;
						maxCharges <- charges_local;
					}else{
						chargeDePassage2EME <- charges_local;
					}
				}
				i <- i + 1;
			}
			y <- y - 1;
		} 
		return chargeDePassage2EME;
	}
	
	float getMoyenneRendementsAnneeEnCours{
		float rdt <- (recolteObserves at dateCour.annee);
		if (rdt > 0.0){
			return rdt/ (surfaceCumule at dateCour.annee); //t/m2
		}else{
			return 0.0;
		}	
	}
	float getTempsDeTravauxAnneeEnCours{
		float tps <- (tempsTravaux at dateCour.annee);
		if (tps > 0.0){
			return tps/ (surfaceCumule at dateCour.annee); //h/m2
		}else{
			return 0.0;
		}	
	}
	
	/* in Euro */
	float getChargesOp{ 
		return (chargesOp at dateCour.annee);
	}
	
	/* in Euro
	 * Charges fixes de passages + cahrges fixes d'irrigation
	 *
	 * TODO ajouter les charges fixes d'irrigation*/
	float getChargesFixes{ 
		return (chargesFixes at dateCour.annee) + 0.0;
	}
	
	/* in t */
	float getProduction{ 
		return (recolteObserves at dateCour.annee);
	}
	
	/* in Euro */
	float getPrimes{ 
		return (primes at dateCour.annee)  * (surfaceCumule at dateCour.annee) / nombreMeterCarreDansUnHectare;
	}
	
//			float getMargeBrute{
//				float margeBrute <- (primes at dateCour.annee) * (surfaceCumule at dateCour.annee) / nombreMeterCarreDansUnHectare ;
//				margeBrute <- margeBrute - (chargesOp at dateCour.annee)
//					+ (recolteObserves at dateCour.annee) *
//					(leMarcheAgricole.prix_recoltes at itkAssocie.especeCultiveeITK);
//				return margeBrute;
//			}
//			
//			float getMargeNette{
//				return getMargeBrute() - (chargesDePassage at dateCour.annee);
//			}
	
	int getNbParcellesAnneeEnCours{ return (nbParcelles at dateCour.annee) ;}
	float getSurfaceAnneeEnCours{ return (surfaceCumule at dateCour.annee) ;}
	
	float getTempsTravauxMoyen5ans{
		float tps<-0.0;
		int y<- dateCour.annee;
		int i<-0;
		loop while: ((i<5) and (y > anneeDebutSimulation-5)){ // tant que l'on n'a pas les 10 éléments
															 // où que l'on n'a pas parcouru toute la liste
			float temps <- (tempsTravaux at y);
			if (temps >0.0){
				tps <- tps + temps / (surfaceCumule at y); //h/m2
				i<- i +1;
			}
			y <- y - 1;
		}		
		return (tps/i*nombreMeterCarreDansUnHectare); //h /ha
	}
	
	/*
	 * Retourne un profitPercu
	 */
	list<float>  getProfitSur10ans{
		if (!listeVariabiliteProfitDejaCalcule){
			list<float> profit <- [];
			// 1°) recuperation d'une table de RDT sur les 5 dernieres occurences
			int nbRdt <-0;
			int y<- dateCour.annee;
			list<float> tabRdt <- [];
			loop while: ((nbRdt<5) and (y > anneeDebutSimulation-5)){ // tant que on a pas les 10 éléments
																 // où qu'on a parcouru toute la liste
				float rdt <- (recolteObserves at y);
				if (rdt >0.0){
					tabRdt << rdt / (surfaceCumule at y); //q/m2
					nbRdt<- nbRdt +1;
				}
				y <- y - 1;
			}
			if(nbRdt = 0){ // cas par exemple du gel
				tabRdt << 0.0; 
				nbRdt<- 1;
			}
			
			// 2°) recuperation d'une table de prix sur les 2 dernieres occurences
			int nbPrix <-0;
			y<- dateCour.annee;
			list<float> tabPrix <- [];
			loop while: ((nbPrix<2) and (y > anneeDebutSimulation-2)){ // tant que on a pas les 10 éléments
																 // où qu'on a parcouru toute la liste
				float p <- (prix at y);
				if (p >0.0){
					tabPrix<< p ; 
					nbPrix<- nbPrix +1;
				}
				y <- y - 1;
			}
			if(nbPrix = 0){ // cas par exemple du gel
				tabPrix << 0.0; 
				nbPrix<- 1;
			}
			
			// 3°) recuperation d'une table de charges op sur les 10 dernieres occurences
			int nbChargesOp <-0;
			y<- dateCour.annee;
			list<float> tabChargesOp <- [];
			loop while: ((nbChargesOp<2) and (y > anneeDebutSimulation-2)){ // tant que on a pas les 10 éléments
																 // où qu'on a parcouru toute la liste
				float c <- (chargesOp at y);
				if ((surfaceCumule at y) >0.0){
					tabChargesOp<< c / (surfaceCumule at y) * nombreMeterCarreDansUnHectare ; //€/ha ; 
					nbChargesOp<- nbChargesOp +1;
				}
				y <- y - 1;
			}
			
			float prime <- primes at (dateCour.annee -1);
			
			//combinaison des valeurs
			loop i from: 0 to:(nbPrix-1){
				loop j from: 0 to:(nbRdt -1){
					profit << tabRdt[j] * nombreMeterCarreDansUnHectare *tabPrix[i]  + prime; //- tabChargesOp[j]
				}
			}
			
			listeVariabiliteProfit <- profit;
			listeVariabiliteProfitDejaCalcule <- true;
		}
		return listeVariabiliteProfit;
	}
	
	
//			/*
//			 * Retourne une liste de 50 profits tires aleatoirement sur les prix, couts et rendements
//			 * des 10 dernieres occurences
//			 */
//			list<float> getProfitSur10ans{			
//				if (!listeVariabiliteProfitDejaCalcule){
//					list<float> profit <- [];
//					// 1°) recuperation d'une table de RDT sur les 10 dernieres occurences
//					int nbRdt <-0;
//					int y<- dateCour.annee;
//					list<float> tabRdt <- [];
//					loop while: ((nbRdt<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
//																		 // où qu'on a parcouru toute la liste
//						float rdt <- (recolteObserves at y);
//						if (rdt >0.0){
//							tabRdt << rdt / (surfaceCumule at y); //q/m2
//							nbRdt<- nbRdt +1;
//						}
//						y <- y - 1;
//					}
//					if(nbRdt = 0){ // cas par exemple du gel
//						tabRdt << 0.0; 
//						nbRdt<- 1;
//					}
//					
//					// 2°) recuperation d'une table de prix sur les 10 dernieres occurences
//					int nbPrix <-0;
//					y<- dateCour.annee;
//					list<float> tabPrix <- [];
//					loop while: ((nbPrix<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
//																		 // où qu'on a parcouru toute la liste
//						float p <- (prix at y);
//						if (p >0.0){
//							tabPrix<< p ; 
//							nbPrix<- nbPrix +1;
//						}
//						y <- y - 1;
//					}
//					if(nbPrix = 0){ // cas par exemple du gel
//						tabPrix << 0.0; 
//						nbPrix<- 1;
//					}
//					
//					// 3°) recuperation d'une table de charges op sur les 10 dernieres occurences
//					int nbChargesOp <-0;
//					y<- dateCour.annee;
//					list<float> tabChargesOp <- [];
//					loop while: ((nbChargesOp<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
//																		 // où qu'on a parcouru toute la liste
//						float c <- (chargesOp at y);
//						if ((surfaceCumule at y) >0.0){
//							tabChargesOp<< c / (surfaceCumule at y) * nombreMeterCarreDansUnHectare ; //€/ha ; 
//							nbChargesOp<- nbChargesOp +1;
//						}
//						y <- y - 1;
//					}
//					
//					
//					// 4°) recuperation d'une table de charges op sur les 10 dernieres occurences
//					int nbChargesDePassageOp <-0;
//					y<- dateCour.annee;
//					list<float> tabChargesDePassage <- [];
//					loop while: ((nbChargesDePassageOp<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
//																		 // où qu'on a parcouru toute la liste
//						float c <- (chargesDePassage at y);
//						if ((surfaceCumule at y) >0.0){
//							tabChargesDePassage<< c / (surfaceCumule at y) * nombreMeterCarreDansUnHectare ; //€/ha ; 
//							nbChargesDePassageOp<- nbChargesDePassageOp +1;
//						}
//						y <- y - 1;
//					}
//					
//					// 5°) recuperation d'une table de prime sur les 10 dernieres occurences
//					int nbprime <-0;
//					y<- dateCour.annee;
//					list<float> tabPrime <- [];
//					loop while: ((nbprime<10) and (y > anneeDebutSimulation-10)){ // tant que on a pas les 10 éléments
//																		 // où qu'on a parcouru toute la liste
//						float c <- (primes at y);
//						tabPrime<< c ; 
//						nbprime<- nbprime +1;
//						y <- y - 1;
//					}
//					
//					//6°) Construction du profit
//					loop i from: 0 to:49{
//						profit << tabRdt[rnd(nbRdt -1)] * nombreMeterCarreDansUnHectare *tabPrix[rnd(nbPrix -1)];
//									// - tabChargesOp[rnd(nbChargesOp -1)]
//									// - tabChargesDePassage[rnd(nbChargesDePassageOp -1)]
//									// + tabPrime[rnd(nbprime -1)];		
//					}
//					listeVariabiliteProfit <- profit;
//					listeVariabiliteProfitDejaCalcule <- true;
//				}
//				return listeVariabiliteProfit;
//			}
	
	action setRendementEtTempsWObserve (float rdt, float surf,
		float tps, float chargesOpToAdd,  float chargesFixesToAdd
	){ //rdt en q et surf en m2
		// tps en h et charges en €
		float ancienRdt<-(recolteObserves at dateCour.annee) ;
		put (rdt +ancienRdt) at: dateCour.annee in: recolteObserves;
		
		float ancienneSurface<-(surfaceCumule at dateCour.annee) ;
		put (surf + ancienneSurface) at: dateCour.annee in: surfaceCumule;
		
		float ancienTps<-(tempsTravaux at dateCour.annee) ;
		put (tps +ancienTps) at: dateCour.annee in: tempsTravaux;
		
		float anciennesChargesOp<-(chargesOp at dateCour.annee) ;
		put (chargesOpToAdd +anciennesChargesOp) at: dateCour.annee in: chargesOp;
		
		float anciennesChargesFixes<-(chargesFixes at dateCour.annee) ;
		put (chargesFixesToAdd +anciennesChargesFixes) at: dateCour.annee in: chargesFixes;
		
		// on incremente le nombre de parcelles
		int nb <- (nbParcelles at dateCour.annee) ;
		put (nb +1) at: dateCour.annee in: nbParcelles;
	}
	action setPrixObserve (float prixObs){put prixObs at: (dateCour.annee -1) in: prix;}
	action setPrimeObserve (float primeObs){put primeObs at: (dateCour.annee -1) in: primes;}
	
	action setPrixObserveAnterieur (map<int,float> prixObs){ 
		loop y over: prixObs.keys{
			put (prixObs at y) at: y in: prix;
		}
	}
	
	action setPrimesObserveAnterieur (map<int,float> primesObs){ 
		loop y over: primesObs.keys{
			put (primesObs at y) at: y in: primes;
		}
	}
	
	action setChargesOpAnterieur (map<int,float> chargesObsOp){ 
		loop y over: chargesObsOp.keys{
			if (y <= dateCour.annee){
				put (chargesObsOp at y) at: y in: chargesOp;
			}
		}
	}
	action setChargesDePassageAnterieur (map<int,float> chargesObsDePassage){ 
		loop y over: chargesObsDePassage.keys{
			if (y <= dateCour.annee){
				put (chargesObsDePassage at y) at: y in: chargesFixes;
			}
		}
	}
	action setRendementObserveAnterieur (map<int,float> rdtObs){ //rdt en q et surf en m2
		loop y over: rdtObs.keys{
			if (y <= dateCour.annee){
				put (rdtObs at y) at: y in: recolteObserves;
				put nombreMeterCarreDansUnHectare at: y in: surfaceCumule;
			}
		}
	}
	action setTempsTravauxAnterieur (float tps){ //h
		loop y from: (dateCour.annee -4) to: (dateCour.annee ){
			put tps at: y in: tempsTravaux;
			put nombreMeterCarreDansUnHectare at: y in: surfaceCumule;
		}
	}
}


