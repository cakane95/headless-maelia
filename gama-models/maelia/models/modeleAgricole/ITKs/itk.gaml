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
 *  ITK
 *  Author: Maroussia Vavasseur
 *  Description: L'ITK ou strategie de culture correspond l'enssemble des strategies de l'agriculteur, differente selon le type de culture.
 * 				 L'ITK comprend 3 types de strategies : Semi, Irrigation, Recolte
 */

model itk

import "../SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../strategieTravailSolMultiples.gaml"
import "../strategiePhyto.gaml"
import "../strategiePhytoMultiples.gaml"
import "../strategieFerti.gaml"
import "../strategieFertiAlternative.gaml"
import "../strategieFauche.gaml"
import "../strategieFaucheMultiples.gaml"

global{
	
	list<itk> listeITKs <- [];
	
	// JV 280319 pour itk par précédent:  clé = culture_apres_culturePrec, valeur = la liste des itk possibles. exemple de clé: "soja_apres_blé"
	map<string,list<itk>> mapITKparCultureEtPrecedent <- [];
	
	/* JV 240821 map des ITK manquants
	 * si ITK par précédent:	clé = culture|culturePrec|materiel|zonePedo|typeExploit (concaténation par des | et typeExploit pouvant être string vide)
	 * sinon					clé = SdCRef|culture|materiel|zonePedo|typeExploit
	 * valeur = liste de parcelles concernées par l'ITK manquant
	 */
	map<string,list<string>> mapITKmanquantEtParcelle <- [];
	
	// JV 301123 map des derniers jours de semis: clé: jour [1-366], valeur: liste d'ITK pour lesquels c'est le dernier jour de la fenêtre de semis
	map<int,list<itk>> mapItkDernierJourSemis <- [];
	
	/*
	 * Action appellee a linitialisation depuis la maethode de creation des SDC 
	 * On cree litk si il nexiste pas
	 */
	itk creationITK(string nomEspece, list<systemeDeCultureDeReference> sdcsRefEntree, string isCulHiver){
		// write("creation ITK: " + nomEspece + " , " + sdcsRefEntree + " , " + isCulHiver); // JV debug
		especeCultivee especeTemp <- first((especeCultivee as list) where (each.idEspeceCultivee = nomEspece));
		itk itkRes <- nil;
		create itk {
	        especeCultiveeITK <- especeTemp;	        	
	        listeITKs << self;
	        itkRes <- self;
	        name <- especeCultiveeITK.idEspeceCultivee;
	        nomPourAffichage <- name;
	        if(isCulHiver contains "O"){
	        	isCultureHiver <- true;
	        }	        
	        ask sdcsRefEntree{
	        	listeITKsPossibles << myself;
	        	myself.name <- myself.name + SEPARATEUR + idSdc;
	        }
	    } 		
		return itkRes;
	}
	
	itk creationITKparPrecedent(string nomEspece, list<especeCultivee> precedents, string isCulHiver){
//		write("creation ITK: " + nomEspece + " , " + precedents + " , " + isCulHiver); // JV debug
		especeCultivee especeTemp <- first(((especeCultivee as list) + (especeHerbSim as list)) where (each.idEspeceCultivee = nomEspece));
		
//		write " ----------------------- nomEspece = " + nomEspece;
//		if (especeTemp = nil) { // AJout Renaud 
//			especeTemp <- first((especeHerbSim as list) where (each.idEspeceCultivee = nomEspece));
//		}
		
//		loop esp over: especeHerbSim {
//			write "espece = " + esp.idEspeceCultivee;
//		}
		
		
		itk itkRes <- nil;
		create itk {
	        especeCultiveeITK <- especeTemp;	        	
	        listeITKs << self;
	        itkRes <- self;
	        name <- especeCultiveeITK.idEspeceCultivee + SEPARATEUR + "apres";
	        loop espPrec over: precedents{
	        	name <- name + SEPARATEUR + espPrec.name;
	        	string cle <- especeTemp.name + "_apres_" + espPrec.name; // définition de la clé pour la map 
	        	list temp_list <- mapITKparCultureEtPrecedent[cle]; // Ajout Renaud 180222 -> si on ajoute self dans "mapITKparCultureEtPrecedent[cle]" ca écrase le contenu de "mapITKparCultureEtPrecedent[cle]"
	        	temp_list <+ self;
	        	mapITKparCultureEtPrecedent[cle] <- temp_list;
	        	//add self to: mapITKparCultureEtPrecedent[cle];  // ajout de cet itk à la liste des itk de ce couple culture/précédent (devrait fonctionner mais ne marche pas) //180222
	        	//write "cle = " + cle;
	        	//write "mapITKparCultureEtPrecedent = " + mapITKparCultureEtPrecedent;
	        }
	        nomPourAffichage <- name;
	        if(isCulHiver contains "O"){
	        	isCultureHiver <- true;
	        }	        	        	        
        }
		return itkRes;
	}

	string getInfoListITK{
			string data <- "";
			loop i from: 1 to: length(listeITKs){
				itk it <- listeITKs[i-1];
				data <- data + "Element "+ i + " de nom "+ it.name +
				 ' - espece = ' + it.especeCultiveeITK + 
				 " - nomPourAffichage = " + it.nomPourAffichage ;
				 if (it.matITK != nil){
				 	 data <- data + " - matITK : "+ it.matITK.idMateriel + '\n' ;
				 }else{
				 	 data <- data + " - matITK : sans \n" ;
				 }
				
			}
			return data;
	}
	
	itk getITKparPrecedent(string especeEntree, string especePrecedent, materielIrrigation materielEntree, string zonePedo, string type_exploitation, list<string> type_gestion_prairie) {

		especeCultivee espece <- first(((especeCultivee as list) + (especeHerbSim as list)) where (each.idEspeceCultivee = especeEntree)); // TODO : revoir idEspece en String !!!
		especeCultivee precedent <- first(((especeCultivee as list) + (especeHerbSim as list)) where (each.idEspeceCultivee = especePrecedent)); // TODO : revoir idEspece en String !!!

		string cle <- especeEntree + "_apres_" + especePrecedent;

		list<itk> listeITKPourCoupleCulturePrecedent <- mapITKparCultureEtPrecedent[cle];
		
		/* JV debug		 
		write "getITKparPrecedent: cle= " + cle + " liste itk: " + listeITKPourCoupleCulturePrecedent; 
		ask listeITKPourCoupleCulturePrecedent{
			write "\tespeceCultiveeITK: " + especeCultiveeITK.idEspeceCultivee + " matITK: " + matITK + " listSolITK: " + listSolITK;
			write "\tmaterielEntree: " + materielEntree + " zonePedo: " + zonePedo;
		}		
		*/
		//if verboseMode {write "itk possibles " + first(listeITKPourCoupleCulturePrecedent).nomPourAffichage;}
		itk itkRes;
		if (!executerModelePaturage or (!espece.isEspeceHerbSim or !(espece.idEspeceCultivee index_of PREFIXE_CI != 0))) {
			itkRes <- first(listeITKPourCoupleCulturePrecedent where ((each.especeCultiveeITK = espece)
				and (each.matITK = materielEntree)
				and ((each.listSolITK at zonePedo)!=nil)
				and (each.listTypeExploitITK contains type_exploitation)
				));
				
//			write "type expl possibles--> " + listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK != nil);
//			write "type expl courant --> " + type_exploitation;
//			write "ITK correspondant à l'espèce --> " + espece.idEspeceCultivee + " " + (listeITKPourCoupleCulturePrecedent where (each.especeCultiveeITK = espece)) collect each.idITK;
//			write "ITK correspondant au materiel --> " + listeITKPourCoupleCulturePrecedent where (each.matITK = materielEntree);
//			write "ITK correspondant au sol --> " + listeITKPourCoupleCulturePrecedent where ((each.listSolITK at zonePedo)!=nil);
//			write "ITK correspondant type expl " + type_exploitation + " --> " +  listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK contains type_exploitation);	
//			
//			write "ITK trouvé -------> "  + itkRes;
		} else {
			 itkRes <- first(listeITKPourCoupleCulturePrecedent where ((each.especeCultiveeITK = espece)
				and (each.matITK = materielEntree)
				and ((each.listSolITK at zonePedo)!=nil)
				and (each.listTypeExploitITK contains type_exploitation)
				and (each.listGestionPrairieITK contains_all type_gestion_prairie)	
				));	
				
//			write "type expl possibles--> " + listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK != nil);
//			write "type expl courant --> " + type_exploitation;
//			write "ITK correspondant à l'espèce --> " + espece.idEspeceCultivee + " " + (listeITKPourCoupleCulturePrecedent where (each.especeCultiveeITK = espece)) collect each.idITK;
//			write "ITK correspondant au materiel --> " + listeITKPourCoupleCulturePrecedent where (each.matITK = materielEntree);
//			write "ITK correspondant au sol --> " + listeITKPourCoupleCulturePrecedent where ((each.listSolITK at zonePedo)!=nil);
//			write "ITK correspondant type expl " + type_exploitation + " --> " +  listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK contains type_exploitation);	
//			write "ITK correspondant type_gestion_prairie " + type_gestion_prairie + " --> " +  listeITKPourCoupleCulturePrecedent where (each.listGestionPrairieITK contains_all type_gestion_prairie);	
//			
//			write "ITK trouvé -------> "  + itkRes;
		}
			
		/*if verboseMode {	
			write "type expl possibles--> " + listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK != nil);
				
			write "ITK correspondant à l'espèce --> " + espece.idEspeceCultivee + " " + (listeITKPourCoupleCulturePrecedent where (each.especeCultiveeITK = espece)) collect each.idITK;
			write "ITK correspondant au materiel --> " + listeITKPourCoupleCulturePrecedent where (each.matITK = materielEntree);
			write "ITK correspondant au sol --> " + listeITKPourCoupleCulturePrecedent where ((each.listSolITK at zonePedo)!=nil);
			write "ITK correspondant type expl " + type_exploitation + " --> " +  listeITKPourCoupleCulturePrecedent where (each.listTypeExploitITK contains type_exploitation);	
			
			write "ITK trouvé -------> "  + itkRes;
		}*/
				
			
		// write "getITKparPrecedent: itkRes= " + itkRes + " " + (materielEntree = nil); JV debug

		// JV 030821 si ITK non defini, on ne cherche plus un ITK similaire, on le signale (sauf cas des ilots hors-zone sans zone pedo)
		/*			
		if (itkRes = nil) and !(materielEntree = nil){ 
			if(length(listeITKPourCoupleCulturePrecedent where ((each.especeCultiveeITK = espece) and ((each.listSolITK at zonePedo)!=nil))) = 1){ // il s'agit d'un itk non irrigue
				itkRes <- first(listeITKPourCoupleCulturePrecedent where ((each.especeCultiveeITK = espece) and 
					(each.matITK = nil) and ((each.listSolITK at zonePedo)!=nil)));
			}else{
				if (!init){
					write "Probleme on veux affecter un itk irrigue avec un "+ materielEntree.idMateriel +
					 " pour l'espece " + espece +" et la zone pedo "+zonePedo +". Cependant un tel itk n'a pas ete defini => affectation aleatoire d'un itk";
					
				}
				itkRes <- any(listeITKPourCoupleCulturePrecedent where (each.especeCultiveeITK = espece));
			}			
		}
		*/
		
		if(itkRes = nil){
			if(listNomZonePedo at zonePedo = nil){ // gestion cas particuliers parcelles HZ dont sol n'est pas dans la liste
				itkRes <-first (listeITKPourCoupleCulturePrecedent where ((each.especeCultiveeITK = espece) and (each.matITK = nil) and (each.listTypeExploitITK contains type_exploitation) and (each.listGestionPrairieITK contains type_gestion_prairie)));
				put zonePedo at: zonePedo in: itkRes.listSolITK ;
				write "Cas particulier parcelles HZ : sol "+ zonePedo+" non existant dans la zone";
			}
			/*else{
				string chaineConsole;
				string chaineFichier;
				if(materielEntree!=nil){				
					chaineConsole <- "[itk/getITKParPrecedent] Pb ITK nul !!! especeEntree = " + especeEntree + " - especePrecedent " + especePrecedent + " materielIrrigation "+ materielEntree.idMateriel + " -zonePedo "+ zonePedo + " typeExp " + type_exploitation;
					chaineFichier <- especeEntree + ";" + especePrecedent + ";" + materielEntree.idMateriel + ";" + zonePedo + ";" + type_exploitation;
				}else{
					chaineConsole <- "[itk/getITKParPrecedent] Pb ITK nul !!! especeEntree = " + especeEntree + " - especePrecendet " + especePrecedent + " materielIrrigation NA " + " -zonePedo "+ zonePedo + " typeExp " + type_exploitation;
					chaineFichier <- especeEntree + ";" + especePrecedent + ";NA;" + zonePedo + ";" + type_exploitation;
				}
				write chaineConsole;
				string cheminFic <- cheminRelatifDuDossierDeSortieDeSimulation + "/missingITK.csv";
				if !file_exists(cheminFic) {
					save "espece;especePrec;materiel;zonePedo;typeExploit" to: cheminFic type:'csv' rewrite:false;
				}
				save chaineFichier to: cheminFic type:'csv' rewrite:false;
			}
			* 
			*/
	
			/* JV 030821 pas de remplacement en cas d'ITK non defini
			if (materielEntree = nil){
				itkRes <- any(listeITKPourCoupleCulturePrecedent where (each.especeCultiveeITK = espece));
			} 
			*/
		}		
		return itkRes;
	}
		
	// JV 260321 utilisé dans le cadre de la création des groupes d'irrigation
	itk getItkAvecLaPlusLongueFenetreIrrigation(list<itk> listeItkCandidats){
		
		int plusLongueFenetre <- 0;
		itk itkAssocie <- nil;
		
		loop unItk over: listeItkCandidats{
			if unItk.strategieIrrigationITK.getNbJoursFenetreTemporelle() > plusLongueFenetre{
				plusLongueFenetre <- unItk.strategieIrrigationITK.getNbJoursFenetreTemporelle();
				itkAssocie <- unItk;
			}
		}
		return itkAssocie;
	}

	 	
 	// JV 301123 si avecContrainteDeMainOeuvre, on peut rater des semis à cause de reports d'heures de travail qui font sortir de la fenêtre de semis sans avoir semé
 	// on va donc explicitement identfier pour chaque jour les ITK dont c'est le dernier jour de semis pour pouvoir les forcer même en cas de report 
 	action computeMapItkLastSowingDay {
 		mapItkDernierJourSemis <- listeITKs group_by (each.strategieSemisITK.getJourJulienFinMax(0));
 	}
	

}

species itk{
	especeCultivee especeCultiveeITK <- nil;
//		especeCultivee especeCultiveeAlternative <- nil; // Cette espece doit appartenir au meme SDC que lespeceCultiveeITK -> tres complexe, ou alors il faut faire un ITK par espece et par IdSDC meme si ils ont les memes valeurs...
	strategieTravailSol strategieTravailSolITK <- nil;	
	strategieBinageSol strategieBinageSolITK <- nil;	
	strategieIrrigation strategieIrrigationITK <- nil;
	strategieSemis strategieSemisITK <- nil;
	strategieRecolte strategieRecolteITK <- nil;
	strategieRepriseTravailSol strategieRepriseTravailSolITK <- nil;
	strategiePhyto strategiePhytoITK <- nil;
	strategieFerti strategieFertiITK <- nil;
	strategieFauche strategieFaucheITK <- nil;
	strategiePature strategiePatureITK <- nil;
	
	//map travailParHectare <- map([]);
	float varianceRendement <- 0.0;
	bool isCultureHiver <- false;
	bool semisAnneeNrecolteAnneeNplusUn <- false; // JV 020420 même information que isCultureHiver mais inférée à partir des fenêtre de semis et de récolte, voir Mantis #0002510
	bool isCultureSup365 <- false; // JV 020622 vrai si les fenêtres de semis et culture se chevauchent: dans ce cas, la récolte se fait l'année N+1 même (cas typique du colza qui peut rester en place plus d'un an), voir Mantis #0002905
	string nomPourAffichage <- "";
	string idITK <- "";
	materielIrrigation matITK <- nil;
	map<string, string> listSolITK <- map([]);
	list<string> listTypeExploitITK;
	list<string> listGestionPrairieITK;
	
	bool contientStrategiesFerti <- false;
	bool isGel <- false; // RM 071020 utilisé dans strategieRecolte
	bool optimisation_corpen <- false; // RM 300725 Détermine si l'itk est soumis à une optimisation corpen
	
	action majVariance {
		set varianceRendement <- (especeCultiveeITK.rendementOptimal - especeCultiveeITK.rendementMin)^2 /4.0;
	}
			
	/*
	 * *****************************************************************************************
	 */

	// Lespece nous renseigne si la culture peut etre irriguee (isIrrigable), cette variable indique si la culture sera reellement irriguee avec cette ITK
	bool isIrriguee{
		if(strategieIrrigationITK != nil){
			return true;
		}else{
			return false;
		}			
	}
	
	bool isDerogatoire{
		if(especeCultiveeITK.isCulturesDerogatoires){
			return true;
		}else{
			return false;
		}
	}
	
	action setSemisAnneeNrecolteAnneeNplusUn{
		// JV 020420 semis et recolte pas la même année si jour début semis après jour fin récolte, voir mantis 0002510 (on considère que le delta temporel ne change pas cette propriété -> met à 0)
		// JV 150424 cas ITK sans récolte (ex: prairie permanente)
		if strategieRecolteITK=nil {
			semisAnneeNrecolteAnneeNplusUn <- false;
		} else {
			semisAnneeNrecolteAnneeNplusUn <- ((strategieRecolteITK.getJourJulienFinMax(0) -  strategieSemisITK.getJourJulienDebutMin(0)<0));
			// JV 090920 si c'est un gel on force à vrai (cf Mantis #0002670)
			if(especeCultiveeITK.idEspeceCultivee="gel"){
				semisAnneeNrecolteAnneeNplusUn <- true;
			}
		}
	}
	
	action setIsCultureSup365 {
		// on infère que la culture est biannuelle si les fenêtres de semis et de récolte se chevauchent
		// deux intervalles se chevauchent si la somme de leurs longueurs est supérieure à la longueur de leur union https://stackoverflow.com/a/25369187
		// le biais de perception étant identique pour les deux fenêtres, on peut le laisser à 0 pour tester le chevauchement
		// JV 150424 ITK sans récolte (ex: prairie permanente) pas concernés (valeur laissée à false par défaut)
		if strategieRecolteITK!=nil {
			int s0 <- strategieSemisITK.getJourJulienDebutMin(0);
			int s1 <- strategieSemisITK.getJourJulienFinMax(0);
			int r0 <- strategieRecolteITK.getJourJulienDebutMin(0);
			int r1 <- strategieRecolteITK.getJourJulienFinMax(0);		
			isCultureSup365 <- ((max(s1,r1)-min(s0,r0)) < ((s1-s0)+(r1-r0)));
			// gel pas concerné
			if(especeCultiveeITK.idEspeceCultivee="gel"){
				isCultureSup365 <- false;
			}
		}
	}
	
	// JV 170920 renvoie le 1er jour de la 1ere fenetre temporelle la plus precoce de l'ITK, toutes OT confondues
	// appele dans systemeDeCulture.setJourRecolteGel lorsqu'on identifie le jour de récolte du gel à la veille de l'OT la plus précoce de l'ITK suivant 
	int getJourJulienMinToutesOT(int deltaTemporel){
		list<int> joursDebutOT; 
		int jourDebutSemis <- 0; // RM quick fix #41
		// si on ajoute un nouveau type d'OT ne pas oublier de l'ajouter ici, ou bien regrouper les OT de l'ITK dans une liste ?
		int tmp <- 0;
		if strategieBinageSolITK!=nil {tmp <- strategieBinageSolITK.getJourJulienDebutMin(deltaTemporel);		if tmp!=0 {joursDebutOT << tmp;}}
		if strategieIrrigationITK!=nil {tmp <- strategieIrrigationITK.getJourJulienDebutMin(deltaTemporel);		if tmp!=0 {joursDebutOT << tmp;}}
		if strategieSemisITK!=nil {
			tmp <- strategieSemisITK.getJourJulienDebutMin(deltaTemporel);
			if tmp!=0 {joursDebutOT << tmp;}
			jourDebutSemis <- tmp;
		}
		if strategieRecolteITK!=nil {tmp <- strategieRecolteITK.getJourJulienDebutMin(deltaTemporel);		if tmp!=0 {joursDebutOT << tmp;}}
		if strategieRepriseTravailSolITK!=nil {tmp <- strategieRepriseTravailSolITK.getJourJulienDebutMin(deltaTemporel);	if tmp!=0 {joursDebutOT << tmp;}}
		
		// Ferti RM 081020 
		if (strategieFertiITK != nil) {
			if (plusieursFertilisationsParITK) {
				loop stratAlt over: strategieFertiITK.mesStrategiesFertiAlternative {
					strategieFertiApport premierApport_alt <- first(stratAlt.mesApports where (each.ordre_apport = 1));
					tmp <- premierApport_alt.getJourJulienDebutMin(deltaTemporel);           if(tmp!=0){joursDebutOT << tmp;}
				}
			} else {
				tmp <- strategieFertiITK.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT << tmp;}
			}
		}
		
		// Travail du sol
		if (strategieTravailSolITK != nil) {
			if (plusieursTravauxDuSolParITK) { // Pas de travail du sol sur le gel
				loop stratTravailSol over: strategieTravailSolITK.mesStrategiesMultiples {
					tmp <- stratTravailSol.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT << tmp;}
				}	
			} else {
				if strategieTravailSolITK != nil {tmp <- strategieTravailSolITK.getJourJulienDebutMin(deltaTemporel);        if tmp!=0 {joursDebutOT << tmp;}}
			}
		}
		
		// Traitements phyto
		if (strategiePhytoITK != nil) {
			if (plusieursTraitementsPhytoParITK) { // Pas de travail du sol sur le gel
				loop stratPhyto over: strategiePhytoITK.mesStrategiesMultiples {
					tmp <- stratPhyto.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT << tmp;}
				}	
			} else {
				tmp <- strategiePhytoITK.getJourJulienDebutMin(deltaTemporel);        if(tmp!=0){joursDebutOT << tmp;}
			}
		}
		//assert(length(joursDebutOT)>0); // au moins une OT dans l'ITK
		int jour_seuil <- max([0, jourDebutSemis - 130]); // RM quick fix #41
		joursDebutOT <- joursDebutOT where (each >= jour_seuil); // RM quick fix #41		
		int jourPremiereOT <- min(joursDebutOT);
		
		return jourPremiereOT;
	}
	
	// Recherche de l'OT la plus précoce d'un ITK (spécifique pour les itk suivants une prairie) RM 180823
	int getJourJulienMinToutesOTPrairies(int deltaTemporel){
		// on ne considère pas l'irrigation et la récolte qui de toute façon seront après le semis
		map<string,int> joursDebutOT; 
		int jourDebutSemis <- 0; // RM quick fix #41
		// si on ajoute un nouveau type d'OT ne pas oublier de l'ajouter ici, ou bien regrouper les OT de l'ITK dans une liste ?
		int tmp;
		if (strategieBinageSolITK != nil) {tmp <- strategieBinageSolITK.getJourJulienDebutMin(deltaTemporel);		if(tmp!=0){joursDebutOT <+ 'binage'::tmp;}}
		if strategieSemisITK!=nil {
			tmp <- strategieSemisITK.getJourJulienDebutMin(deltaTemporel);
			if tmp!=0 {joursDebutOT << tmp;}
			jourDebutSemis <- tmp;
		}
		tmp <- strategieRecolteITK.getJourJulienDebutMin(deltaTemporel);		if(tmp!=0){joursDebutOT <+ 'recolte'::tmp;}
		
		// Ferti RM 081020 
//		if (strategieFertiITK != nil) {
//			if (plusieursFertilisationsParITK) {
//				int cpt_ot <- 0;
//				loop stratAlt over: strategieFertiITK.mesStrategiesFertiAlternative {
//					cpt_ot <- cpt_ot + 1;
//					strategieFertiApport premierApport_alt <- first(stratAlt.mesApports where (each.ordre_apport = 1));
//					tmp <- premierApport_alt.getJourJulienDebutMin(deltaTemporel);           if(tmp!=0){joursDebutOT <+ 'ferti'+cpt_ot::tmp;}
//				}				
//			} else {
//				tmp <- strategieFertiITK.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT <+ 'ferti1'::tmp;}
//			}
//		}
		
		// Travail du sol
		if (strategieTravailSolITK != nil) {
			if (plusieursTravauxDuSolParITK) { // Pas de travail du sol sur le gel
				int cpt_ot <- 0;
				loop stratTravailSol over: strategieTravailSolITK.mesStrategiesMultiples {
					cpt_ot <- cpt_ot + 1;
					tmp <- stratTravailSol.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT <+ 'wsol'+cpt_ot::tmp;}
				}	
			} else {
				if strategieTravailSolITK != nil {tmp <- strategieTravailSolITK.getJourJulienDebutMin(deltaTemporel);        if tmp!=0 {joursDebutOT <+ 'wsol1'::tmp;}}
			}
		}
				
//		// Traitements phyto
//		if (strategiePhytoITK != nil) {
//			if (plusieursTraitementsPhytoParITK) { // Pas de travail du sol sur le gel
//				int cpt_ot <- 0;
//				loop stratPhyto over: strategiePhytoITK.mesStrategiesMultiples {
//					cpt_ot <- cpt_ot + 1;
//					tmp <- stratPhyto.getJourJulienDebutMin(deltaTemporel);            if(tmp!=0){joursDebutOT <+ 'phyto'+cpt_ot::tmp;}
//				}	
//			} else {
//				tmp <- strategiePhytoITK.getJourJulienDebutMin(deltaTemporel);        if(tmp!=0){joursDebutOT <+ 'phyto1'::tmp;}
//			}
//		}
		
//		write "TEST HERBSIM - Renaud : joursDebutOT = " + joursDebutOT;
		
		// identification itk superposés sur 2 années dont lale semis serait en 2e année avant le 15 mai (ex : une ot décembre et semis en janvier)
		// 15 mai = j 135 ---- 
		// RM ligne ci-dessous supprimée pour quick fix #41
//		list<int> jour_sup_recolte_DebutOT <- joursDebutOT where (each > joursDebutOT['recolte']); 
//		write "TEST HERBSIM - Renaud : jour_sup_recolte_DebutOT = " + jour_sup_recolte_DebutOT;

//		int jour_seuil <- max([0, jourDebutSemis - 130]); // RM quick fix #41
//		list<int> joursDebutOT_filtre <- joursDebutOT where (each >= jour_seuil); // On filtre d'abord les OT trop anciennes // RM quick fix #41
		list<int> jour_sup_recolte_DebutOT <- joursDebutOT where (each > joursDebutOT['recolte']); // Parmi celles-ci, on regarde celles qui sont après la récolte // RM quick fix #41
		
		// Si il y a des OT dont la date de début est supérieure à celle de la récolte
		int jourPremiereOT;
		if (length(jour_sup_recolte_DebutOT) > 0) {
			jourPremiereOT <- min(jour_sup_recolte_DebutOT);
		} else { // Si la date de récolte est la date la plus tardive en jours juliens
			jourPremiereOT <- min(joursDebutOT);
		}
		
		//assert(length(joursDebutOT)>0); // au moins une OT dans l'ITK
//		write "TEST HERBSIM - Renaud : debut premiere OT = " + jourPremiereOT;

		
		return jourPremiereOT;
	}
	
	// JV 200920 fenetres semis et recolte forcees a [1,365] pour le gel, cf Mantis 0002670
	// appele a la fin de systemeDecCultureDeReference.lectureFichierReglesDeDecisions
	action forceFenetresSemisRecolteITKGel{
		strategieSemisITK.nbSousPeriode <- 1;
		strategieSemisITK.mapFenetresTemporellesDebut <- [0::1];
		strategieSemisITK.mapFenetresTemporellesFin <- [0::365];
		strategieRecolteITK.nbSousPeriode <- 1;
		strategieRecolteITK.mapFenetresTemporellesDebut <- [0::1];
		strategieRecolteITK.mapFenetresTemporellesFin <- [0::365];
	}
	
	string toString{
		return name + ' - espece = ' + especeCultiveeITK + 
					" - isIrriguee = " + isIrriguee() + 
					" - SIR = " + strategieSemisITK + "|" + strategieIrrigationITK + "|"+ strategieRecolteITK
					+" - nomPourAffichage = " + nomPourAffichage
					+ " - matITK "+ matITK;
	}			
}
