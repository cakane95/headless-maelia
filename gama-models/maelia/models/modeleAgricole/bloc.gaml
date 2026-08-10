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
 *  Bloc
 *  Author: Romain Lardy
 *  Description: le bloc est un ensemble de parcelles considerer comme un ensemble
 *  homogene lors de la gestion de l'assolement
 */

model bloc

import "../modeleHydrographique/zoneHydrographique.gaml" 

global{	
	string fichierBlocs <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/blocs'+ nomChoixAssolement +'.csv';
	string fichierBlocsCorrige <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/blocs'+ nomChoixAssolement +'_cor.csv';
	bool pretraitementBlocs <- true;
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	 action constructionBlocs{
	 	if (pretraitementBlocs){
	 		do pretraitementBlocs();
	 	}
	 	if (file_exists(fichierBlocs)){
	 		do constructionBlocsParlectureFichier();
	 	}else{
	 		loop agri over: listeAgriculteurs{
		 		do constructionBlocs1Agri(agri); // méthode pour creer 1 bloc irrigable et 1 bloc non irr
		 	}
	 	}
	 }
	 
	 action constructionBlocsParlectureFichier{
	 	do pretraitementFichierBlocsAvantLecture; // cf Mantis #0002913
	 	file unFic <- csv_file(fichierBlocsCorrige,";",string,false);
	 	matrix<string> InitBloc <- matrix(unFic);
	 	int nbLignes <- length(InitBloc column_at 0);
	 	loop i from: 0 to: (nbLignes -1){ //boucle sur les blocs
	 		//creation de la liste parcelle à partir des id;
	 		list<parcelle> groupeparcelleBlocs <- [];
			list<string> ligne <- InitBloc row_at i;
	 		ask listeAgriculteurs where (each.idAgriculteur = ligne[0]){
				loop j from:1 to:(length(ligne)-1){
		 			ask self.listeParcelles where (each.idParcelle = ligne[j]){
		 				groupeparcelleBlocs << self;
		 			}
		 		}
	 		}  
	 		
	 		if (length(groupeparcelleBlocs)> 0){
	 			//creation du bloc
			 	create bloc returns: bl{
					listeParcellesBloc <- groupeparcelleBlocs;
					systemeDeCultureDeReference sdcDuBloc <- nil;
					if(!itkParPrecedent){ // pas de SdcRef lorsque les ITK sont définis par couple culture/précédent -> dans ce cas sdcDuBloc=nil, refaire ça proprement
						sdcDuBloc <- (groupeparcelleBlocs[0]).systemeDeCultureParcelle.sdcRefAssocie;
					
						//en attendant une rectification des pretraitements
						// il faut changer les sdc contenant des proteagineux sur les bloc non irr
	//					if (!first(groupeparcelleBlocs).isParcelleIrrigable()){
	//						if (sdcDuBloc.idSdc = '11'){
	//							sdcDuBloc <- (mapSystemesDeCultureDeRef at '10');
	//						}
	//						if (sdcDuBloc.idSdc = '9'){
	//							sdcDuBloc <- (mapSystemesDeCultureDeRef at '8');
	//						}
	//					}
						idSdcRefInitialDuBloc <- sdcDuBloc.idSdc;
					}
					loop parc over:groupeparcelleBlocs{
						parc.bloc_app <- self;
						surfaceBloc <- surfaceBloc +parc.surface;
						ask ((groupeparcelleBlocs[0]).ilot_app.agriculteurAssocie) {
							do uniformisationBloc(parc, sdcDuBloc);	
						}
					}
					string ZC <- ""; 
					if ((groupeparcelleBlocs[0]).isParcelleHorsZone){
							list<parcelle> parcelleExploit <- ((groupeparcelleBlocs[0]).ilot_app.agriculteurAssocie.listeParcelles where (each.ilot_app.zoneHydroAssociee != nil));
							// parcelle tmp <- (parcelleExploit closest_to (groupeparcelleBlocs[0]).location );
							parcelle tmp <- parcelleExploit with_min_of (each.location distance_to ((groupeparcelleBlocs[0]).location) );
							
							if (tmp = nil){ // La fonction closest_to renvoie nil pour des elements situe hors zone. Il faut augmenter le shape de l'environement
								write 'pbm parcelle HZ : closest_to ' + (groupeparcelleBlocs[0]) + " vs "+ length(parcelleExploit);
							}
							ZC <- tmp.ilot_app.zoneHydroAssociee.zoneClimatique;
					}else{
						ZC <- (groupeparcelleBlocs[0]).ilot_app.zoneHydroAssociee.zoneClimatique;
					}
					
					zonePedo <- (groupeparcelleBlocs[0]).ilot_app.getNomZonePedo();
					if ((groupeparcelleBlocs[0]).isParcelleIrrigable()){ //cas bloc irrigable
					    sdcBloc <- SDCRefParZonePedoClim at (ZC+ "_" + zonePedo);
						materielDuBloc <- (groupeparcelleBlocs[0]).ilot_app.materielIlot;	
					}else{ //cas bloc non irrigable
						if (SDCRefParZonePedoClim at (ZC+ "_" + zonePedo)) != nil {
							loop sdcRef over: (SDCRefParZonePedoClim at (ZC+ "_" + zonePedo)) {
								if (!sdcRef.parcelleIrrigableSdC) {
									add sdcRef to: sdcBloc;
								}			
							}
						 }
					}
					
			 	}
				(groupeparcelleBlocs[0]).ilot_app.agriculteurAssocie.listBloc << first(bl);
	 		}
		 }
	 }
	 
	 action constructionBlocs1Agri(agriculteur agri){
		list<parcelle> g1 <- [];  //parcelles irrigables
		list<parcelle> g2 <- []; //parcelles non irrigables
		loop parc over: agri.listeParcelles {
			if parc.isParcelleIrrigable() {
				add parc to: g1;
			}else {
				add parc to: g2;
			}
		}
		if(length(g1)>0){
			create bloc returns: b1{
				listeParcellesBloc <- g1;
				systemeDeCultureDeReference sdcDuBloc <- (g1[0]).systemeDeCultureParcelle.sdcRefAssocie;
				loop parc over:g1{
					parc.bloc_app <- self;
					surfaceBloc <- surfaceBloc +parc.surface;
					ask agri{
						do uniformisationBloc(parc, sdcDuBloc);	
					}
				}
				//parcelles irrigables donc tous les sdc de la zone climatiques sont acceptables
				string ZC <- (g1[0]).ilot_app.zoneHydroAssociee.zoneClimatique; 
				zonePedo <- (g1[0]).ilot_app.getNomZonePedo();
				sdcBloc <- SDCRefParZonePedoClim at (ZC + "_"+ zonePedo);
				materielDuBloc <- (g1[0]).ilot_app.materielIlot;
				
			}
			agri.listBloc << first(b1);		
		}
		if (length(g2)>0){
			create bloc returns: b2{
				listeParcellesBloc <- g2;
				systemeDeCultureDeReference sdcDuBloc <- (g2[0]).systemeDeCultureParcelle.sdcRefAssocie;
				
				loop parc over:g2{
					parc.bloc_app <- self;
					surfaceBloc <- surfaceBloc +parc.surface;
					ask agri{
						do uniformisationBloc(parc, sdcDuBloc);	
					}	
				}
				//parcelles non irrigables donc seules les sdc non irr de la zone climatiques sont acceptables
				string ZC <- (g2[0]).ilot_app.zoneHydroAssociee.zoneClimatique; 
				zonePedo <- (g2[0]).ilot_app.getNomZonePedo();
				loop sdcRef over: (SDCRefParZonePedoClim at (ZC+ "_" + zonePedo)) {
					if (!sdcRef.parcelleIrrigableSdC) {
						add sdcRef to: sdcBloc;
					}			
				}
			}
			agri.listBloc << first(b2);				
		}
		
	}

	 // Fonction temporaire de division des parcelles en blocs
	 action	pretraitementBlocs{
	 	string data <- "";
	 	list<materielIrrigation> listMatTemp <- (materielIrrigation as list);
	 	
	 	loop agri over: listeAgriculteurs{
	 		// BEN
	 		// write "=========================================";
	 		// write "Agriculteur :   " + agri;
	 		//	 		
	 		loop i from: 0 to:length(listMatTemp){
	 			materielIrrigation mat <- nil;
	 			if (i < length(listMatTemp)){
	 				mat <- listMatTemp[i];	
	 			}

		 		list<list<parcelle>> listeGroupeParcelles <- []; //pour le moment juste un groupe irrigable et un non irr
		 		//Plus tard diviser les groupes par zones climatiques et par source d'irrigation
		 		list<parcelle> grpParIrr <- []; //parcelles irrigables
				list<parcelle> grpParNonIrr <- []; //parcelles non irrigables
				list<parcelle> grpParIrrHZ <- []; //parcelles horsZone irrigables
				list<parcelle> grpParNonIrrHZ <- []; //parcelles horsZone non irrigables
				
				loop parc over: agri.listeParcelles {
					
//					write "parc.ilot_app.materielIlot "+ parc.ilot_app.materielIlot
//					+ " mat "+ mat + " " + (parc.ilot_app.materielIlot = mat);
					if (parc.ilot_app.materielIlot = mat){
						if parc.isParcelleIrrigable() {
							if parc.isParcelleHorsZone {
								add parc to: grpParIrrHZ;
							}else{ 
								add parc to: grpParIrr;
							}
						}else {
							if parc.isParcelleHorsZone {
								add parc to: grpParNonIrrHZ;
							}else{ 
								add parc to: grpParNonIrr;
							}
						}
					}
				}
				if (length(grpParIrr)>0){listeGroupeParcelles << grpParIrr;}
				if (length(grpParNonIrr)>0){listeGroupeParcelles << grpParNonIrr;}
								
				//On divise listeGroupeParcelles par Zone Climatique
				list<list<parcelle>> listeGroupeParcellesTemp <- [];
				loop listParc over:listeGroupeParcelles{
					list<parcelle> temp <- listParc; 
		 			map<string,list<parcelle>> listParcTriee <- ( temp group_by (each.ilot_app.zoneHydroAssociee.zoneClimatique));
		 			loop ZC over: listParcTriee.keys{
		 				listeGroupeParcellesTemp << listParcTriee at ZC;
		 			}
				}
		 		listeGroupeParcelles <- listeGroupeParcellesTemp;
		 			 		
		 		if (nomChoixAssolement = 'Donnees') {  //On groupe par SDC de Reference		 		
		 			if (length(grpParIrrHZ)>0){listeGroupeParcelles << grpParIrrHZ;}
					if (length(grpParNonIrrHZ)>0){listeGroupeParcelles << grpParNonIrrHZ;}
		 			list<list<parcelle>> listeGroupeParcellesTemp <- [];
					loop listParc over:listeGroupeParcelles{
						list<parcelle> temp <- listParc; 
			 			map<string,list<parcelle>> listParcTriee <- ( temp group_by (each.idSdcRef));
			 			loop IDSDC over: listParcTriee.keys{
			 				listeGroupeParcellesTemp << listParcTriee at IDSDC;
			 			}
					}
					listeGroupeParcelles <- listeGroupeParcellesTemp;
//					listeGroupeParcelles <- listeGroupeParcelles sort_by (length(each)); // JV 120321 trie les listes de parcelles par taille décroissante: sort puis reverse, sinon problèmes à la lecture du fichier bloc
//					listeGroupeParcelles <- reverse (listeGroupeParcelles);
//					int longueurMaxBloc <- length(first(listeGroupeParcelles)); // JV 120321 longueur de la plus longue liste de parcelles
					loop blocAcreer over: listeGroupeParcelles{
						list<parcelle> listeParcellesDuBloc <- blocAcreer;
						data <- data + (listeParcellesDuBloc[0]).ilot_app.agriculteurAssocie.idAgriculteur +";";
						loop parc over:listeParcellesDuBloc{
							data <- data + parc.idParcelle +";" ;
						}
						data <- data + "\n";					
					}
		 		}else{
		 			loop listParc over:listeGroupeParcelles{
			 			//creation de groupe par type de sol
			 			list<parcelle> temp <- listParc; 
			 			
						map<int,list<parcelle>> listParcTriee <- ( temp group_by (each.ilot_app.sol.stuDominant));	 			
			 			
			 			float surfaceGroupe <- 0.0;
			 			list<list> listeParcGroupeParSol <- []; //0: listes de parcelles ; 1: somme des surfaces ; 2: sol
						loop stu over: listParcTriee.keys{
							list element <- [];
							list<parcelle> liste1Groupe <- listParcTriee at stu;
							element << copy(liste1Groupe);
							element << sum(liste1Groupe collect (each.surface));
							surfaceGroupe <- surfaceGroupe + sum(liste1Groupe collect (each.surface));
							element << first(liste1Groupe).ilot_app.sol;
							listeParcGroupeParSol << element;
						}					
						
						listeParcGroupeParSol <- listeParcGroupeParSol sort_by (each[1] as float);
						float surfacePremierGroupe <- (listeParcGroupeParSol[0])[1] as float;
						loop while: (surfacePremierGroupe < (0.2*surfaceGroupe)){
							//On determine a quel type de sol on se rapproche
							int indiceSolLePlusProche <- detSolLePlusProche(listeParcGroupeParSol);
							list elementADeplacer <- listeParcGroupeParSol[0];
							list elementDestination <- listeParcGroupeParSol[indiceSolLePlusProche];
							list<parcelle> listeGroupeADeplacer <- elementADeplacer[0] as list<parcelle>;
							list<parcelle> listeGroupeDestination <- elementDestination[0] as list<parcelle>;
							loop e over: listeGroupeADeplacer{
								listeGroupeDestination << e;
							}
							elementDestination[0] <- copy(listeGroupeDestination);
							elementDestination[1] <- float(elementDestination[1]) + float(elementADeplacer[1]);
							listeParcGroupeParSol[indiceSolLePlusProche] <- copy(elementDestination);
							listeParcGroupeParSol >> elementADeplacer;
							listeParcGroupeParSol <- listeParcGroupeParSol sort_by (each[1] as float);
							surfacePremierGroupe <- (listeParcGroupeParSol[0])[1] as float;
						}
						
						
						//Pour le moment les parcelles HZ vont être assemble au bloc dominant 
						//et non constituer un bloc à part entière
						//Par consequent leur ZC sera celle du bloc d'origine
						
						
						if (first(temp).isParcelleIrrigable()){ // si groupe irrigable
							if (length(grpParIrrHZ)>0){ // on va ajouter g3 dans le bloc majoritaire (i.e. le dernier de la liste)
								list elementDestination <- listeParcGroupeParSol[length(listeParcGroupeParSol)-1];
								list<parcelle> listeGroupeDestination <- elementDestination[0] as list<parcelle>;
								listeGroupeDestination <- listeGroupeDestination +grpParIrrHZ;
								elementDestination[0] <- copy(listeGroupeDestination);
								listeParcGroupeParSol[length(listeParcGroupeParSol)-1] <- copy(elementDestination);
								grpParIrrHZ <- []; // On vide g3 pour savoir qu'il ne faut pas creer un groupe specifique à la fin
							}
						}else{
							if (length(grpParNonIrrHZ)>0){
								list elementDestination <- listeParcGroupeParSol[length(listeParcGroupeParSol)-1];
								list<parcelle> listeGroupeDestination <- elementDestination[0] as list<parcelle>;
								listeGroupeDestination <- listeGroupeDestination +grpParNonIrrHZ;
								elementDestination[0] <- copy(listeGroupeDestination);
								listeParcGroupeParSol[length(listeParcGroupeParSol)-1] <- copy(elementDestination);				
								grpParNonIrrHZ <- [];// On vide g4 pour savoir qu'il ne faut pas creer un groupe specifique à la fin
							}
						}					
						
						loop blocAcreer over: listeParcGroupeParSol{
							list<parcelle> listeParcellesDuBloc <- blocAcreer[0] as list<parcelle>;
							data <- data + (listeParcellesDuBloc[0]).ilot_app.agriculteurAssocie.idAgriculteur +";";
							loop parc over:listeParcellesDuBloc{
								data <- data + parc.idParcelle +";" ;
							}
							data <- data + "\n";					
						}
			 		} //fin boucle listeGroupeParcelles
			 		//Code pour créer un bloc pour parcelles HZ
			 		// Si elles n'ont pas ete ajoute correspondant précedement
					if (length(grpParIrrHZ)>0){ //un bloc par type de materiel
						map<materielIrrigation,list<parcelle>> listParc <- ( grpParIrrHZ group_by (each.ilot_app.materielIlot));
						loop mat over: listParc.keys{
							data <- data + (grpParIrrHZ[0]).ilot_app.agriculteurAssocie.idAgriculteur +";";
							loop parc over: (listParc at mat) {data <- data + parc.idParcelle +";" ;}
							data <- data + "\n";
						}
					}
					if (length(grpParNonIrrHZ)>0){
						data <- data + (grpParNonIrrHZ[0]).ilot_app.agriculteurAssocie.idAgriculteur +";";
						loop parc over: grpParNonIrrHZ {data <- data + parc.idParcelle +";" ;}
						data <- data + "\n";
					}
		 		}
		 		
	 		}//fin boucle materiel
	 	}// fin boucle agri
	 	save data to: fichierBlocs format: 'text' rewrite:true;
	 }
	 
	 /*
	  * Algorithme en deux etapes :
	  * - on divise la liste en une liste de sols differant de plus ou moins de 20% de RU
	  * on choisit par taux d'argile le plus proche dans le groupe different a moins de 20% de RU
	  * Sinon on prend le sol le plus proche en terme de RU (reservePotentielleUtileMax) 
	  */
	 int detSolLePlusProche(list<list> listeParcGroupeParSol){
	 	  //list<list> listeParcGroupeParSol -> 0: listes de parcelles 
	 	  // 1: somme des surfaces 
	 	  // 2: sol
		int indiceARetourner <- 0;
		float RUDeRefrence <- typeDeSol(listeParcGroupeParSol[0][2]).reservePotentielleUtileMax;
		float TauxArgileDeRefrence <- typeDeSol(listeParcGroupeParSol[0][2]).tauxArgile;
		list<list> listeIndicesDesGroupeParSol <- []; //0: indice
			//1: RU
			//2: taux argile
	 	loop i from: 1 to: (length(listeParcGroupeParSol)-1){
	 		list element<-[];
	 		element << i;
	 		typeDeSol tds <- ((listeParcGroupeParSol[i])[2]) as typeDeSol;
	 		element << abs((tds.reservePotentielleUtileMax - RUDeRefrence)/RUDeRefrence) ;
	 		element << abs((tds.tauxArgile - TauxArgileDeRefrence)/TauxArgileDeRefrence) ;
	 		listeIndicesDesGroupeParSol << element;
	 	}
	 	//On trie la liste par RU (reservePotentielleUtileMax)
	 	listeIndicesDesGroupeParSol <- listeIndicesDesGroupeParSol sort_by (each[1] as float);
	 	list<list> listeTrieeParTauxArgile <- [];
	 	loop e over: listeIndicesDesGroupeParSol{
	 		if( float(e[1])  <0.2) {
	 			listeTrieeParTauxArgile << e;
	 		}
	 	}
	 	if (length(listeTrieeParTauxArgile)>0){
	 		listeTrieeParTauxArgile <- listeTrieeParTauxArgile sort_by (each[2] as float);
	 		indiceARetourner <- listeTrieeParTauxArgile[0][0] as int;
	 	}else{
	 		indiceARetourner <- listeIndicesDesGroupeParSol[0][0] as int; 
	 	}
	 	return indiceARetourner;
	 }
	
	// JV 140622 prétraitement du fichier blocsDonnees.csv avant sa lecture dans constructionBlocsParlectureFichier, cf Mantis #0002913
	// le prétraitement consiste à homogénéiser le nombre de colonnes pour chaque ligne du csv, sinon cela peut poser des problème lors du cast en matrix
	action pretraitementFichierBlocsAvantLecture {
		int longueurMax <- 0;
		file fic <- text_file(fichierBlocs);
		// parcours du fichier pour identifier le nombre max de colonnes
		loop ligne over: fic {
			int longueurLigne <- length(string(ligne) split_with(";"));
			longueurMax <- max([longueurMax, longueurLigne]);
		}
		// pour chaque ligne on construit 2 listes
		// - listeMax: liste vide de longueurMax éléments
		// - listeLigne: liste de n éléments construite en découpant la ligne courante
		// on remplit les n premiers éléments de listeMax avec les n éléments de listeLigne 
		string s <- "";
		loop ligne over: fic {		
			list<string> listeMax <- list_with(longueurMax,"");
			list<string> listeLigne <- string(ligne) split_with(";");
			if length(listeLigne)>0 {
				loop i from:0 to:(length(listeLigne)-1) {
					listeMax[i] <- listeLigne[i];
				}
				loop i from:0 to:(length(listeMax)-1) {
					s <- s + listeMax[i] + ";";
				}
			}
			s <- s + "\n";
		}
		save s to: fichierBlocsCorrige format: 'text';			
	}
	
	 			
}

species bloc {
	string idBloc <- '';
	string idSdcRefInitialDuBloc <- "";
	list<parcelle> listeParcellesBloc <-[];
	float surfaceBloc <- 0.0;
	list<systemeDeCultureDeReference> sdcBloc <- [];
	materielIrrigation materielDuBloc <- nil;
	string zonePedo <- "";		
}
