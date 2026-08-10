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
 *  SystemesDeCultures
 *  Author: Maroussia Vavasseur
 *  Description: Classe mere des systeme de culture. Il est possible de definir un SdC plus ou moins simplement, mais a chaque fois on aura le meme schema.
 * 				 Par exemple, on peut se baser sur des donnes reelles, ou alors on definr une liste finies.
 */

model systemeDeCulture

import "../../modeleCommun/typeDeSol.gaml"

global{
	string sequences_a_optimiser; // Renaud 051022 Optimisation ad hoc du module agricole (ex: Seille)
	
	list<systemeDeCulture> listeSystemesDeCulture <- [];
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionSystemeDeCulture{
		
		switch nomChoixAssolement {
        	match Donnees {
               do constructionSystemeDeCultureParDonneesEntrees();  
            }
        	match FonctionsDeCroyances {
               do constructionSystemeDeCultureParSdcRef();    
            }            
        }	
	}
	
	/*
	 * Si choix assoelemtn donnee : et affectation de 1 SDC par parcelle (qui ne changera plus au cours de la simu)
	 * Dans ce cas, on ne vérifie pas si le sdc est possible dans cette zone climatique
	 */
	action constructionSystemeDeCultureParDonneesEntrees{
		//write mapITKparCultureEtPrecedent; // JV debug
		ask(listeAgriculteurs){
			ask(listeParcelles){
				//if verboseMode {write "creation SdC parcelle: " + idParcelle + " " + rotationReelle;} // JV debug
				materielIrrigation mat <- ilot_app.materielIlot;
				/*if(mat!=nil){
					write"\tmateriel " + mat.idMateriel; // JV debug
				}else{
					write"\tmateriel NA";  // JV debug
				}*/
				
				// Renaud 051022 Optimisation ad hoc du module agricole (ex: Seille)
				if (rotationReelle = sequences_a_optimiser) {
					myself.parcelles_a_optimiser <+ self;
				} else {
					myself.parcelles_non_optimisees <+ self;
				}
				
				if (self.rotationReelle tokenize "_" contains "gel") {
					myself.parcelles_contenant_gel <+ self;
				}
			
				create systemeDeCulture{
					if(!itkParPrecedent) {sdcRefAssocie <- mapSystemesDeCultureDeRef at myself.idSdcRef;} 
					
					// On cree la liste ditk a partir des donnees lues (rotationReelle)
					list<string> liste <- [];
					liste <- myself.rotationReelle tokenize "_";	
					string precedent <- last(liste);										
					loop idCult over: liste{
						itk itkRes;
						string nomZonePedo <- myself.ilot_app.getNomZonePedo();
						string typeExploit <- myself.ilot_app.agriculteurAssocie.sonExploitation.type;
						list<string> typeGestionPrairie <- myself.gestionPrairie;
						if(itkParPrecedent){
							// critères de spatialisation: culture - culture précédente - matériel - zone pédo - type exploitation
							itkRes <- world.getITKparPrecedent(especeEntree:idCult,especePrecedent:precedent,materielEntree:mat, zonePedo:nomZonePedo, type_exploitation:typeExploit, type_gestion_prairie:typeGestionPrairie);
							//write "Recherche itk pour --> espece = " + idCult + " - precedent = " + precedent + " - mat = " + mat.idMateriel + " - nomZonePedo = " + nomZonePedo + " - typeExploit = " + typeExploit;
						}else{
							// critères de spatialisation: SDC ref - culture - matériel - zone pédo - type exploitation
							itkRes <- sdcRefAssocie.getITK(especeEntree:idCult,materielEntree:mat, zonePedo:nomZonePedo, type_exploitation:typeExploit, type_gestion_prairie:typeGestionPrairie);
							//write "Recherche itk pour --> espece = " + idCult + " - mat = " + mat.idMateriel + " - nomZonePedo = " + nomZonePedo + " - typeExploit = " + typeExploit;						
						}
						if itkRes=nil {
							// JV ne peut pas appeler world.memorisationITKmanquant sans type de retour...!
							int toto <- world.memorisationITKmanquant(sdcRefAssocie, idCult, precedent, mat, nomZonePedo, typeExploit, myself.idParcelle, myself.gestionPrairie);
						}
						if itkParPrecedent {
							precedent <- idCult;																					
						}
						rotation << itkRes; // on ajoute itkRes même s'il est nul
					}				
					myself.systemeDeCultureParcelle <- self;
					listeSystemesDeCulture << self;
					if (myself.indexDepart < 0){
						
					}else{
						indiceItkCourant <- myself.indexDepart;
					}
					
					// JV 140121 modification calcul indice de départ dans la rotation pour tenir compte des couverts intermédiaires voir Mantis #0002770
					indiceItkCourant <- calculIndiceITKcourant(liste); 
					/* ancienne version
					indiceItkCourant <- ((anneeDebutSimulation -  anneeDeReferenceRPG -1) mod length(rotation)); // le moins un est necessaire, car a la fin de la boucle on affectera un nouvel ITK
					if (indiceItkCourant < 0){
						indiceItkCourant <- indiceItkCourant + length(rotation);
					}					
					*/
					//write "+++++++ rotation=" + (rotation collect each.especeCultiveeITK.idEspeceCultivee) + " " + length(rotation) + " indiceItkCourant=" + indiceItkCourant; // JV debug
					
					do initialisation(myself);
					
					// Création de la liste exportation/restitution
					rotationGestionPailles <- myself.gestionPailles tokenize "_";

				}
				//write "\tle sdc: " + systemeDeCultureParcelle.rotation collect (each.idITK); // JV debug				
			}
			
			/* JV 020321 mantis #0002773
			 * 	si assolement par données: on traite ici l'affectation du maïs ensilage
			 *	si assolement par fonctions de croyances: on traite ici le choix d'assolement
			 *  default: au cas où on introduit d'autres choix d'assolement
			 */
			switch nomChoixAssolement {
				match 'Donnees' {
					//do affectationMaisEnsilage(); // JV 240821 plus d'affectation automatique du maïs ensilage, il est lu directement dans les séquences RPG
				}
				match 'FonctionsDeCroyances' {do choixAssolement();}
				default {do choixAssolement();}
			}

			loop parc over: listeParcelles{
				do getAssolement1parcelle(parc);
				// JV 101224 pour ne pas démarrer par une CI, issue #7 
				loop while: parc.getITKAnnee().especeCultiveeITK.isCI() {
					do getAssolement1parcelle(parc);
 				}
			}
			
		}
	}
	
	/*
	 * TODO : supprimer !
	 * A linitialisation, on va mettre des sdc dans chaque parcelle sinon le choix dassolement ne marche pas...
	 */
	action constructionSystemeDeCultureParSdcRef{
		ask(listeAgriculteurs){
			ask(listeParcelles){
				systemeDeCultureDeReference sdcRefTemp <- (mapSystemesDeCultureDeRef at idSdcRef);
				if(sdcRefTemp != nil){
					ask world{ // ATTENTION : si on fait : world.creationSystemeDeCultureParSdcRef(parcelleEntree:parcelle(myself)) -> le self sera celui du world!!)
						myself.systemeDeCultureParcelle <- creationSystemeDeCultureParSdcRef(sdcRefEntree:sdcRefTemp, parcelleEntree:myself);
					}
				}					
			}		
		}
	}
	
	/*
	 * Cree lors du choix dassoslement avec fonction de croyance!
	 */
	systemeDeCulture creationSystemeDeCultureParSdcRef{
		arg sdcRefEntree type: systemeDeCultureDeReference default: nil;
		arg parcelleEntree type: parcelle default: nil;

		systemeDeCulture sdcRes <- nil;
		create systemeDeCulture{
			sdcRefAssocie <- sdcRefEntree;			
			if (parcelleEntree.ilot_app.materielIlot = nil){
				rotation <- sdcRefAssocie.mapRotationType at ("NA" +"_" + parcelleEntree.ilot_app.getNomZonePedo());
			}else{
				rotation <- sdcRefAssocie.mapRotationType at (parcelleEntree.ilot_app.materielIlot.idMateriel +"_" + parcelleEntree.ilot_app.getNomZonePedo());
			}
			
			//TODO inserer ici la matrice de precedence pour determiner l'indice de depart de la rotation
			indiceItkCourant <- parcelleEntree.mapIndiceDepartRotation at length(rotation);
			sdcRes <- self;
			listeSystemesDeCulture << self;
			do initialisation(parcelleEntree);
		}
		
		return sdcRes;		
	}
	
	/* JV 240821 appelée depuis systemeDeCulture.constructionSystemeDeCultureParDonneesEntrees lorsque l'ITK recherché est manquant
	 * 		si ITK par précédent: 	on remplit la map mapITKmanquantEtParcelle avec pour clé: cult;cultPrec;idMat;zonePedo;typeExploit
	 * 		sinon 					on remplit la map mapITKmanquantEtParcelle avec pour clé: idSdcRef;cult;idMat;zonePedo;typeExploit
	 */
	int memorisationITKmanquant(systemeDeCultureDeReference sdcRef, string cult, string cultPrec, materielIrrigation matIrr, string zonePedo, string typeExploit, string idParc, list<string> gestionPrairie){
		string cle;
		string idMat <- "NA";
		if matIrr!=nil {idMat <- matIrr.idMateriel;}
		if itkParPrecedent {
			cle <- cult + ';' + cultPrec + ';' + idMat + ';' + zonePedo + ';' + typeExploit + ";" + gestionPrairie;
		}
		else{
			cle <- sdcRef.idSdc + ';' + cult + ';' + idMat + ';' + zonePedo + ';' + typeExploit + ";" + gestionPrairie;
		}
		if mapITKmanquantEtParcelle contains_key cle {
			mapITKmanquantEtParcelle[cle] <+ idParc; // ITK déjà identifié comme manquant: on ajoute la parcelle à la liste des parcelles
		}else{
			mapITKmanquantEtParcelle[cle] <- [idParc]; // permière fois qu'on identifie cet ITK comme manquant
		}
		return 0;
	}
	
}

species systemeDeCulture{
	systemeDeCultureDeReference sdcRefAssocie <- nil;
	list<itk> rotation <- []; // ITK dans lordre de la rotation simulee
	list<string> rotationGestionPailles <- [];
	int compteurAnnee <- 1;
	int indiceItkCourant <- 0;
	itk itkAnneeCourante <- nil;
	map<int,itk> mapITKaModifierDansLaRotation <- []; // clé: indice dans la rotation, valeur: ITK à substituer à celui prevu dans la rotation (utilisé dans agriculteurDonneesEntrees.affectationMaisEnsilage pour passer certains ITK en maïs ensilage)

	action initialisation (parcelle maParcelle) {

		itkAnneeCourante <- (rotation at indiceItkCourant);
		
		// Si prairie permanente alors on modifie la date de semis pour que la culture soit semée au premier jour de simulation RM 280524
		if (maParcelle.isPrairiePermanente) {
			itkAnneeCourante.strategieSemisITK.mapFenetresTemporellesDebut[0] <- 1;
			itkAnneeCourante.strategieSemisITK.mapFenetresTemporellesFin[0] <- 366;
			// Il faudra penser à forcer le semis quelque soit les conditions si pp
		}
	}
	
	string getId{
		return sdcRefAssocie.idSdc;
	}

	// Appelee une fois apres chaque recolte (dans getITKalternatifAnneeCourante)
	action changementITK{
		compteurAnnee <- (compteurAnnee + 1);
		indiceItkCourant <- (indiceItkCourant + 1)  mod length(rotation);
		if mapITKaModifierDansLaRotation.keys contains indiceItkCourant{ // si cet ITK est à modifier
		//if(itkAnneeSuivante != nil){			
			itkAnneeCourante <- mapITKaModifierDansLaRotation[indiceItkCourant];
			mapITKaModifierDansLaRotation[] >- indiceItkCourant; // retire la clé indiceItkCourant de la map
		}else{
			itkAnneeCourante <- (rotation at indiceItkCourant);
		}			
	}

	itk getITKanneeCourante{
		return itkAnneeCourante;
	}
	
	itk getITKanneeSuivante{
		int indiceItkSuivant <- (indiceItkCourant + 1)  mod length(rotation);
		return (rotation at indiceItkSuivant);
	}
	
	itk getITKanneePrecedente{
		int indiceItkPrecedent <- (indiceItkCourant - 1 + length(rotation)) mod length(rotation); // <-- décalage +n
		return (rotation at indiceItkPrecedent);
	}
	
	itk getProchainITKnonCI{ // JV 090321 renvoie le prochain ITK de la rotation dont la culture n'est pas une culture intermédiaire
		int indiceItkSuivant <- (indiceItkCourant + 1)  mod length(rotation);
		itk itkSuivant <- rotation at indiceItkSuivant;
		if itkSuivant=nil{ // JV debug
			write "========= itkSuivant null indiceItkSuivant=" + indiceItkSuivant + "\n\trotation=" + rotation;
		}
		assert(itkSuivant!=nil);
		bool trouve <- itkSuivant.especeCultiveeITK.isCI();
		loop while: !trouve {
			indiceItkSuivant <- (indiceItkSuivant+1) mod length(rotation);
			itkSuivant <- rotation at indiceItkSuivant;
			trouve <- itkSuivant.especeCultiveeITK.isCI();
		}
		return itkSuivant;
	}

	int getIndiceProchainITKnonCI{ // JV 090321 renvoie l'indice du prochain ITK de la rotation dont la culture n'est pas une culture intermédiaire
		int indiceItkSuivant <- (indiceItkCourant + 1)  mod length(rotation);
		itk itkSuivant <- rotation at indiceItkSuivant;
		bool trouve <- itkSuivant.especeCultiveeITK.isCI();
		loop while: !trouve {
			indiceItkSuivant <- (indiceItkSuivant+1) mod length(rotation);
			itkSuivant <- rotation at indiceItkSuivant;
			trouve <- itkSuivant.especeCultiveeITK.isCI();
		}
		return indiceItkSuivant;
	}
	
	itk getITKDeSaisonSuivante(bool isCultureRechercheHivernale){
		itk itkSuivant <- nil;
		int i <- 1;
		loop while: (i < length(rotation)) and (itkSuivant = nil){
			itk itkfutur <- (rotation at ((indiceItkCourant + i)  mod length(rotation)));
			if(itkfutur.isCultureHiver = isCultureRechercheHivernale){
				itkSuivant <- itkfutur;
			}
			i <- i +1;
		}
		return itkSuivant ;
	}
	
	/* JV 090920 appelé dans strategieRecolte.miseEnOeuvreActivite après le changement d'ITK lorsque le nouvel ITK est un gel
	 * permet de déterminer le jour de récolte du gel (cf Mantis #0002670)
	 * - si ITK suivant est aussi un gel -> date récolte = dans un an
	 * - sinon -> date récolte = veille de la première OT de l'ITK suivant
	 */	 
	action setJourRecolteGel(parcelle p){		
		itk itkSuivant <- getITKanneeSuivante();
		if(itkSuivant.especeCultiveeITK.idEspeceCultivee="gel"){
			p.jourProchaineRecolteGel <- (dateCour.nbJoursEcoulesDansAnnee + 365) mod 365; // le gel va etre recolte dans un an exactement
		} else{
			// récupération du nbJoursDeDecalageActivite (deltaTemporel) de l'agriculteur
			int deltaTemp <- p.getAgriculteur().nbJoursDeDecalageActivite;
			p.jourProchaineRecolteGel <- itkSuivant.getJourJulienMinToutesOT(deltaTemp);
		}	
		// ajout à la liste des jours de récolte (cf issue #4)
		accelerateur_agricole["RECOLTE"] <+ p.jourProchaineRecolteGel;
		accelerateur_agricole["RECOLTE"] <- remove_duplicates(accelerateur_agricole["RECOLTE"]);
	}

	// RM 170823 Les prairies temporaires sont récoltées au premier jour possible de l'itk suivant si l'itk suivant n'est pas une prairie temp.
	// JV 150724 appelé depuis getAssolement1parcelle uniquement si prairies simulées avec HerbSim (cf issue #5]
	action setJourRecoltePrairie(parcelle p){
		itk itkSuivant <- getITKanneeSuivante();
		int deltaTemp <- p.getAgriculteur().nbJoursDeDecalageActivite; // récupération du nbJoursDeDecalageActivite (deltaTemporel) de l'agriculteur
		
		//if(itkSuivant.especeCultiveeITK.idEspeceCultivee != "prairiet"){
		//if ((listeNomsEspecesHerbSim contains itkAnneeCourante.especeCultiveeITK.idEspeceCultivee) and (itkSuivant.especeCultiveeITK.idEspeceCultivee != itkAnneeCourante.especeCultiveeITK.idEspeceCultivee)) {
		if (itkSuivant.especeCultiveeITK.idEspeceCultivee != itkAnneeCourante.especeCultiveeITK.idEspeceCultivee) {
			p.jourProchaineRecoltePrairie <- itkSuivant.getJourJulienMinToutesOTPrairies(deltaTemp);
		} else {
			//p.jourProchaineRecoltePrairie <- itkSuivant.strategieSemisITK.getJourJulienDebutMin(deltaTemp);
			p.jourProchaineRecoltePrairie <- max([itkSuivant.strategieSemisITK.getJourJulienDebutMin(deltaTemp) - 1,1]); // Modif Renaud 041024
		}
//		write "parcelle " + p.idParcelle + " set récolte prairie jour " + p.jourProchaineRecoltePrairie + "(" + itkAnneeCourante.nomPourAffichage + " - " + itkSuivant.nomPourAffichage + ")";
		// ajout à la liste des jours de récolte (cf issue #4)
		accelerateur_agricole["RECOLTE"] <+ p.jourProchaineRecoltePrairie;
		accelerateur_agricole["RECOLTE"] <- remove_duplicates(accelerateur_agricole["RECOLTE"]);
		
		p.recoltePrairieAnneeOK <- false; // Récolte prairie non autorisée pour l'année en cours (à vérifier depuis le 251023) TODO Renaud
	}	
	
	action setITKAlternatif(itk itkDeRemplacement){
		itkAnneeCourante <- itkDeRemplacement;
	}

	// force l'ITK de la prochaine culture non CI: typiquement dans agriculteurDonneesEntrees.affectationMaisEnsilage
	action forcerITKprochaineCultureNonCI(especeCultivee especeDuNouvelITK, materielIrrigation mat, string zonePedo, string typeExp, list<string> typeGestionPrairie){
		int indiceProchainITKnonCI <- getIndiceProchainITKnonCI();
		itk itkForce <- sdcRefAssocie.getITK(especeDuNouvelITK.idEspeceCultivee, mat, zonePedo, typeExp, typeGestionPrairie);		
		if(itkForce = nil){
			write "[SdC.forcerITKprochaineCultureNonCI] Attention Pb l'itk "+especeDuNouvelITK.idEspeceCultivee+" pour materiel "+mat+" ne peut pas entre cree car pas definie pour cet idSDC_ref " + sdcRefAssocie.idSdc;
		}
		mapITKaModifierDansLaRotation[indiceProchainITKnonCI] <- itkForce; // l'ITK d'indice indiceProchainITKnonCI dans la rotation sera remplacé par itkForce (juste pour une fois)
		if verboseMode {write "parcelle " + " ITK indice " + (indiceProchainITKnonCI+1) + " devient " + itkForce.idITK;}
	}				

	// Si le Sdc existe depuis plus dannee quil na de culture dans sa rotation
	bool isSdcTermine{			
		if(compteurAnnee >= length(rotation)){
			return true;
		}else{
			return false;
		}
	}
	
	/* JV 140121 nouvelle façon de calculer l'indice de démarrage dans la rotation pour tenir compte de la présence de couverts intermédiaires (CI), voir Mantis #0002770
	 * auparavant:
	 * int indiceDansSequenceSansCI <- ((anneeDebutSimulation -  anneeDeReferenceRPG -1) mod length(sequenceSansCI));
	 *	if (indiceDansSequenceSansCI < 0){
	 *		indiceDansSequenceSansCI <- indiceDansSequenceSansCI + length(sequenceSansCI);
	 *	}		
	 * problème: il ne faut pas tenir compte des CI dans le calcul: lorsqu'on remonte dans la séquence pour se caler sur l'année de référence RPG, il faut "sauter" les CI
	 * 
	 * principe du nouvel algo:
	 *  - on applique la même formule sur la séquence sans les CI -> on trouve l'indice de démarrage qu'on utiliserait si on n'avait pas de CI
	 *  - on retrouve cet indice dans la séquence avec CI via une map qui fait correspondre à l'indice de chaque culture dans la séquence sans CI son indice dans la séquence avec CI
	 * 
	 * les noms des cultures CI sont supposées commencer par la valeur de PREFIXE_CI (définie dans donneesGlobales)  
	 */	
	int calculIndiceITKcourant(list<string> sequenceAvecCI){
		
		list<string> sequenceSansCI;
		map<int,int> mapSansCIToAvecCI;
		
		// calcul sequence sans CI
		int iAvecCI <- 0;
		int iSansCI <- 0;		
		loop while: (iAvecCI < length(sequenceAvecCI)) {
			// si commence pas par CI						
			if (sequenceAvecCI[iAvecCI] index_of PREFIXE_CI)!=0 {
				sequenceSansCI << sequenceAvecCI[iAvecCI];
				mapSansCIToAvecCI[iSansCI] <- iAvecCI;
				iSansCI <- iSansCI+1;
			}
			iAvecCI <- iAvecCI+1;										
		}
		// JV 290424 cas sequence uniquement en CI
		if length(sequenceSansCI)=0 {
			return(0);
		}
		int indiceDansSequenceSansCI <- ((anneeDebutSimulation -  anneeDeReferenceRPG -1) mod length(sequenceSansCI));
		if (indiceDansSequenceSansCI < 0){
			indiceDansSequenceSansCI <- indiceDansSequenceSansCI + length(sequenceSansCI);
		}		 
		return mapSansCIToAvecCI[indiceDansSequenceSansCI];
	}
}
