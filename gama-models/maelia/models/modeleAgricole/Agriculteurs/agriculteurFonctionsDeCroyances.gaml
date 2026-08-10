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
 *  agriculteurFonctionsDeCroyances
 *  Author: Patrick Taillandier et Maroussia Vavasseur
 *  Description: L'agriculteur complexe a un comportement rationel qui se base sur le paradigme BDI (Plan-Desirs-Croyances-Intention).
 * 				 Les croyances de l'agriculteur sont predefinies des fonctions de croyances.
 */

model agriculteurFonctionsDeCroyances

import "../StrategiesSemis/strategieSemi.gaml"
import "../StrategiesRecolte/strategieRecolte.gaml"
import "../strategieBinageSol.gaml"

global{
	string cheminProfilesAgriculteurs <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/profilesAgriculteurs.csv';
	//constantes liees a la decision des agriculteurs
	map mapProfilesAgriculteurs <- map([]); //definie les differents profiles d'agriculteurs (parametre fct de croyance)
	map<string,float> mapProportionsProfiles <-map<string,float>([]); //proportion d'agriculteurs de chaque type (pourcentage)	

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionAgriculteursFonctionsDeCroyances{		
		do creationProfilesAgriculteursComplexes();
		do creationAgriculteurs(agriculteurFonctionsDeCroyances);
		do initialisationAgriculteursComplexes();
	}
	
	/*
	 * *****************************************************************************************
	 * Private
	 */
	action creationProfilesAgriculteursComplexes {
    		matrix initProfilesAgriculteurs <- matrix(csv_file (cheminProfilesAgriculteurs,';',false));
    		//	matrix initProfilesAgriculteurs <- matrix(file (cheminProfilesAgriculteurs));
		int nbLignes <- length(initProfilesAgriculteurs column_at 0);
		
		loop i from: 1 to: ( nbLignes - 1 ) {
			list<string> ligneCourante <- ( initProfilesAgriculteurs row_at i ) as list<string>;
			list<map> profile <- [];
			int nbDonneesCrit <- 9;
			loop j from: 0 to: int((length(ligneCourante) - 2) / nbDonneesCrit) {
				map critereC <- map([]);
				put (ligneCourante at ((j * (nbDonneesCrit-1)) + 2)) in: critereC at:'name';
				put (ligneCourante at ((j * (nbDonneesCrit-1)) + 3)) = 'oui' in: critereC at:'maximize'; //Utile a GAMA pour filtrer les candidats
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 4)) in: critereC at:'s1';
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 5)) in: critereC at:'s2';
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 6)) in: critereC at:'v1p';
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 7)) in: critereC at:'v2p';
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 8)) in: critereC at:'v1c';
				put float(ligneCourante at ((j * (nbDonneesCrit-1)) + 9)) in: critereC at:'v2c';
				add item:critereC to: profile;
			}
			put profile at: (ligneCourante at 0) in: mapProfilesAgriculteurs;
			put float(ligneCourante at 1) at: (ligneCourante at 0) in: mapProportionsProfiles;
		}
	}
	
	/*
	 * *****************************************************************************************
	 * Private
	 */
	action initialisationAgriculteursComplexes{			
		int idx <- 0;
		int cpt <- 0;
		int nbAgri <- length(listeAgriculteurs);
		list<string> listeProfile <- mapProportionsProfiles.keys;
		string profileC <- listeProfile at idx;
		float seuilC <- mapProportionsProfiles at profileC;
		ask shuffle(listeAgriculteurs) {
			profile <- profileC;
			cpt <- cpt + 1;
			if cpt/nbAgri * 100.0 > seuilC and (idx < length(listeProfile) - 1){
				idx <- idx + 1;
				profileC <- (listeProfile at idx);
				seuilC <- seuilC + (mapProportionsProfiles at (listeProfile at idx));	
			}
		}
	}
	
}

species agriculteurFonctionsDeCroyances parent: agriculteur {  	
	planAssolementFonctionsCroyances dernierPlan <- nil;

	/*
	 *  *****************************************************************************************
	 *  @Overwrite :
	 *  Reflex effectue juste avant l'evolution des cours du marche agricole
	 */				
	action choixAssolement{
		list<bloc> listeBlocsNvChoix <- [];
		list<bloc> listeBlocsANePasChanger <- [];
					
		//Creation de la liste blocs nouveau choix et de la liste bloc a ne pas changer
		loop b over: listBloc{
			
			bool toChange <- false;
			int i <- 0;
			loop while: (!toChange and (i < length(b.listeParcellesBloc))){
				systemeDeCulture sd <- (b.listeParcellesBloc[i]).systemeDeCultureParcelle; //cultureParcelle
				if (sd.isSdcTermine() and ((b.listeParcellesBloc[i]).cultureParcelle !=nil)) or (sd = nil){
					toChange <- true;
				}else{
					i <- i + 1;
				}
			}
			if (toChange){
				listeBlocsNvChoix << b;
			}else{
				listeBlocsANePasChanger << b;
			}
		}
		//TODO trier par esperance de profit sur les 3 dernieres annees
		listeBlocsNvChoix <- listeBlocsNvChoix sort_by (each.surfaceBloc); //Attention la liste est triee par surface croissance
		
		list<bloc> listeBlocsANePasChangerTemp <- listeBlocsANePasChanger;
		list<bloc> listeBlocsNvChoixTemp <- listeBlocsNvChoix;
			
		int idx <- 0;
		loop while: (idx < length(listeBlocsNvChoix)) {
			
			//dans le cas où on ne veut les traiter que 2 par deux
			listeBlocsANePasChangerTemp <- copy(listBloc);
			listeBlocsNvChoixTemp <- [];
			listeBlocsNvChoixTemp << listeBlocsNvChoix[length(listeBlocsNvChoix) -1 -idx];
			listeBlocsANePasChangerTemp >> listeBlocsNvChoix[length(listeBlocsNvChoix) -1 -idx];
			if ((length(listeBlocsNvChoix) -1 -idx) > 0){
				listeBlocsNvChoixTemp << listeBlocsNvChoix[length(listeBlocsNvChoix) -2 -idx];
				listeBlocsANePasChangerTemp >> listeBlocsNvChoix[length(listeBlocsNvChoix) -2 -idx];
			}
			idx <- idx +2;
		
		
			// Choix du plan
			list<planAssolementFonctionsCroyances> plans <- [];
			list<map<bloc,systemeDeCultureDeReference>> plansAEvaluer <- [];
			list<planAssolementFonctionsCroyances> listePlansAConsiderer <- [];
			
			list<int> sdcEnCoursBloc <- length(listeBlocsNvChoixTemp) list_with(0);							
	
			int indEnCours <- -1; //pour forcer a rentrer dans la boucle 
			loop while: (indEnCours <length(listeBlocsNvChoixTemp)) { 
				indEnCours <- 0;
				//Inserer ici la creation du plan (i.e. avant increment)
				map<bloc,systemeDeCultureDeReference> planParBloc <- map([]);//va contenir un assolement possible
				
				loop iBloc from: 0 to: (length(listeBlocsNvChoixTemp)-1){
					systemeDeCultureDeReference sdcToAdd <- (listeBlocsNvChoixTemp[iBloc]).sdcBloc[sdcEnCoursBloc[iBloc]];
					put sdcToAdd at:(listeBlocsNvChoixTemp[iBloc]) in: planParBloc;
				}
				
				// Gestion de la partie fixe
				loop bl over: listeBlocsANePasChangerTemp {
					put (dernierPlan.SdCParBlocs at bl) at:bl in: planParBloc;
				}
				// on crée le plan candidat
				plansAEvaluer << planParBloc ;				
				
				//Increment des sdc

				sdcEnCoursBloc[indEnCours] <- sdcEnCoursBloc[indEnCours] +1 ;
				
				loop while: ((indEnCours < length(listeBlocsNvChoixTemp)) and 
					(sdcEnCoursBloc[indEnCours]=length((listeBlocsNvChoixTemp[indEnCours]).sdcBloc))) 
				{
			    	sdcEnCoursBloc[indEnCours] <- 0 ;
			    	indEnCours <- indEnCours +1 ;
			    	if(indEnCours < length(listeBlocsNvChoixTemp)){
			    		sdcEnCoursBloc[indEnCours] <- sdcEnCoursBloc[indEnCours] +1 ;
			    	}
			    }
			}
			planAssolementFonctionsCroyances plan <- choixPlan(plansAEvaluer);
			ask dernierPlan { //suppression du dernier plan (qui n'est pas un de ceux cree à l'initialisation)
				listePlansAssolement >> self;
				myself.listePlans >> self;	
				do die();
			}
			dernierPlan <- plan;
			
			// Attribution du nouveau SDC aux parcelles vides
			loop b over: listeBlocsNvChoixTemp{
				loop parc over: b.listeParcellesBloc{
					//write "Affectation d une nouvelle rotation "+ (dernierPlan.SdCParBlocs at parc.bloc_app) + " a la parcelle " + parc + " a la date du "+ string(dateCour.annee) + "/"+ dateCour.mois + "/" + dateCour.jour;
					if(parc.systemeDeCultureParcelle = nil){
						do getAssolement1parcelle(parc);
					}
				}
			}		
		}
	}


	/*
	 *  *****************************************************************************************
	 * Evaluation du front de Pareto puis evaluation du choix de Plan
	 */			
	planAssolementFonctionsCroyances choixPlan (list<map<bloc,systemeDeCultureDeReference>> plansAEvaluer) {

		list<list<float>> candidats <- [];
		list<list<float>> candidatsPareto <- [];
		list<list> candidatsEtIndices <- [];
		list<int> listIndiceCandidat <- [];
		loop i from: 0 to: (length(plansAEvaluer) -1) {
			map<bloc,systemeDeCultureDeReference> SdCParBlocsAEvaluer <- plansAEvaluer[i];
			list<float> liste <- evaluationCandidat(SdCParBlocsAEvaluer);
			if!empty(liste){
				candidats << liste;
			}				
		}
		//construction du front de Pareto
		int i <- 0;
		// on va supprimer les éléments qui ne sont pas sur l'optimum
		// de Pareto, i.e. ceux pour lesquels il existe un candidat meilleurs
		// pour les 4 criteres 
		loop while: (i < length(candidats)){
			int j <- 0;
			float profitI <- (candidats[i])[0];
			float varProfitI <- (candidats[i])[1];
			float similariteI <- (candidats[i])[2];
			float travailI <- (candidats[i])[3];
			bool candidatOk <- true;
			loop while: ((j < length(candidats)) and (candidatOk)){
				float profitJ <- (candidats[j])[0];
				float varProfitJ <- (candidats[j])[1];
				float similariteJ <- (candidats[j])[2];
				float travailJ <- (candidats[j])[3];
				if ((j != i) and (profitI <= profitJ) and (varProfitI >= varProfitJ) 
					and (similariteI >= similariteJ) and (travailI <= travailJ))
				{
					candidatOk <- false;
				}
				j <- j + 1;
			}
			if (candidatOk){
				i <- i +1;
			}else{ //Let's remove plan and candidats that are not optimal
				candidats >> candidats[i] ;
				plansAEvaluer >> plansAEvaluer[i] ;
			}
		}
		if (length(candidats)<(nombrePlansOptimauxUtilise +1)){
			candidatsPareto <- candidats;
			loop j from:0 to: length(candidats)-1 {
				listIndiceCandidat << j;
			}
		}else{
			//Si plus 20 de candidats sur le front de Pareto
			//On construit une sctructure contenant candidats + indice de plansAEvaluer
			
			//If more than 20 candidates on the Pareto front
			 //We build a sctructure that holds candidats + the index of plansAEvaluer
			 loop j from: 0 to: length(candidats)-1 {
                list tmp <- candidats[j];
                tmp << j;
                candidatsEtIndices << tmp;
            }
            candidatsEtIndices <- candidatsEtIndices sort_by (each[2] as float);

			 loop j from: 0 to: int (nombrePlansOptimauxUtilise/2 -1){ //ajout des 10 candidats les plus proches //add the 10 nearest (in conformity) candidates
                    candidatsPareto << candidats[int(candidatsEtIndices[j][4])];
                    listIndiceCandidat << int(candidatsEtIndices[j][4]);
            }
            loop j from: 0 to: (nombrePlansOptimauxUtilise/2 -1){ //ajout de 10 candidats aleatoirement parmis les autres //add randomly 10 candidates from the other group
                    int indice <- 10 + rnd(length(candidats) -11);
                    listIndiceCandidat << int(candidatsEtIndices[indice][4]);
                    candidatsPareto << candidats[int(candidatsEtIndices[indice][4])];
            }

		}
		
		int idx <- -1;
		idx <- evidence_theory_DM(candidatsPareto,list(mapProfilesAgriculteurs at profile), true);		
			
		create planAssolementFonctionsCroyances returns: nvP{
			SdCParBlocs <- plansAEvaluer[listIndiceCandidat[idx]];
			agri <- myself;				
			listePlansAssolement << self;
			myself.listePlans << self;	
		}
		return first(nvP);
	}
	
	/* A travers la variable candidat, cette fonction va renvoyer
	 * le profit
	 * la variabilite du profit
	 * la similarite au plan precedent
	 * et le nombre de jours de travail libres
	 * 
	 */
	list<float> evaluationCandidat (map<bloc,systemeDeCultureDeReference> SdCParBlocsAEvaluer){
		
		list<float> candidat <- []; // ce que l'on va renvoyer
		list<float> profits_annees <- [];
		loop i from: 0 to:9{ profits_annees<< 0.0;}
		int joursLibres <- 0;
		float ecartType <- 0.0;
		float tempsTravail <- 0.0;
		float profit <- 0.0;				
		
		loop bl over: SdCParBlocsAEvaluer.keys{ 
			float profit_rotation <- 0.0;
			list<float> profits_annees_rotation <- [];
			loop i from: 0 to:9{ profits_annees_rotation<< 0.0;}
			float tempsTravail_rotation <- 0.0;
			
			systemeDeCultureDeReference SdC <- (SdCParBlocsAEvaluer at bl);
			//bloucle sur les elements de la rotation 
			// materielDuBloc
			list<itk> rotationType <- nil;
			if (bl.materielDuBloc = nil){
				rotationType <- (SdC.mapRotationType at ("NA" +"_" + bl.zonePedo) );
			}else{
				rotationType <- (SdC.mapRotationType at (bl.materielDuBloc.idMateriel +"_" + bl.zonePedo) );
			}
			
			loop it over: rotationType{

				//critere de profit
				// On prend la prime actuelle et non la prime observee dans la memoire
				float prime <- (leMarcheAgricole.prime_par_departement at sonExploitation.id_departement) at it.especeCultiveeITK; 
				ask (listMemoire) where ((each.itkAssocie = it) and (each.blocMemoire = bl)){
					profit_rotation <- profit_rotation + get2ERendementsObserves5ans() *
									get2EPrixObserves3ans() - get2EChargesOp3ans() - get2EChargesDePassage3ans()+ prime; //[€/ha]
					
					//On considère une variabilité composée des cinq derniers rendements observés et des prix et charges des deux dernières années 
					list<float> unProfit <- getProfitSur10ans();
					loop i from: 0 to:9{
						profits_annees_rotation[i]<- profits_annees_rotation[i] + unProfit[i];
					}
					
					//critere de temps de travail
					tempsTravail_rotation <- tempsTravail_rotation + getTempsTravauxMoyen5ans();
				}
										
			}
			profit <- profit + profit_rotation/length(rotationType)*bl.surfaceBloc / nombreMeterCarreDansUnHectare;
			loop i from: 0 to:9{
				profits_annees[i]<- profits_annees[i] + profits_annees_rotation[i] /length(rotationType)*bl.surfaceBloc / nombreMeterCarreDansUnHectare;
			}
			tempsTravail <- tempsTravail + tempsTravail_rotation/length(rotationType)*bl.surfaceBloc/nombreMeterCarreDansUnHectare;
			
		}
		
		int nbJoursTravails <- max ([1, int(tempsTravail / (travail_jour * sonExploitation.umo))]);
		joursLibres <- 365 - nbJoursTravails;								
		
		
		//Evaluation du critere de similarite
		float evalsimilarite <- 0.0;
		if (dernierPlan = nil) {
			evalsimilarite <- 0.0;
		}else{
			ask dernierPlan {
				evalsimilarite <- self.similaritePlan(SdCParBlocsAEvaluer);
			}	
		}
		candidat << profit /sonExploitation.surfaceUtileExploitation;
		if (abs(mean(profits_annees)) > 1.0){
			float tmp <- standard_deviation(profits_annees) / abs(mean(profits_annees)) ; ///sonExploitation.surfaceUtileExploitation
			candidat << tmp;
		}else{	
			candidat << 1.0;
		}
		
		candidat << evalsimilarite;
		candidat << joursLibres;
		
//			write ""+ profit/sonExploitation.surfaceUtileExploitation +" " + standard_deviation(profits_annees)/sonExploitation.surfaceUtileExploitation+
//			" "+evalsimilarite+" " +joursLibres;

		return candidat;
	} 
	
	action getAssolement1parcelle(parcelle parc){
		
		if(parc.systemeDeCultureParcelle != nil){ //Suppression de l'ancien systeme de culture
			ask(parc.systemeDeCultureParcelle){
				listeSystemesDeCulture >> self; //Suppresion de la liste globale
				do die();
			}
			parc.systemeDeCultureParcelle <- nil;
		}
		
		if((dernierPlan.SdCParBlocs at parc.bloc_app) != nil){ //Si on a bien prevu d'affecter un systeme de culture a cette parcelle
			ask world{
				//TODO gerer ici la question de la conservation de l'assolement (i.e. debut de rotation) si même rotation ou affection proportionelle
				parc.systemeDeCultureParcelle <- world.creationSystemeDeCultureParSdcRef(sdcRefEntree:(myself.dernierPlan.SdCParBlocs at parc.bloc_app),
					parcelleEntree:parc);
			}						
		}
		if(parc.systemeDeCultureParcelle = nil){						
			write "" + idAgriculteur + " - [AGRI/choixAssolement] Pb 2 !!! le systemeDeCultureParcelle est null : " + parc.toString() + " --- " + dernierPlan.SdCParBlocs;
		}				
	}
	
	/*
	 * Dans le cas des agent Agri fonction de croyance , il est important que les blocs commencent avec la meme rotation
	 */
	action uniformisationBloc(parcelle parc, systemeDeCultureDeReference sdcDuBloc){
		if (parc.systemeDeCultureParcelle.sdcRefAssocie != sdcDuBloc){
			if(parc.systemeDeCultureParcelle != nil){ //Suppression de l'ancien systeme de culture
				ask(parc.systemeDeCultureParcelle){
					listeSystemesDeCulture >> self; //Suppresion de la liste globale
					do die();
				}
				parc.systemeDeCultureParcelle <- nil;
			}
			ask world{
				parc.systemeDeCultureParcelle <- world.creationSystemeDeCultureParSdcRef(sdcRefEntree:sdcDuBloc,
					parcelleEntree:parc);	
			}
		}
		//do initRotation(parc);	
	}
			 
}
