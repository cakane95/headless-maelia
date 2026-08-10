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
 *  ZonesHydrographiques
 *  Author: Maroussia Vavasseur
 *  Description: La zone hydrographique ou ZH est l'entite de reference, la maille, de MAELIA. 
 * 				 Espece correpsondant au decoupage de la zone MAELIA (remplace les cellules)
 */

model zoneHydrographique

import "../modeleAgricole/Ilots/ilot.gaml"

global{
//	string zoneHydrographiqueShape <- '../main/log/zoneMaeliaTest3DExport.shp';	
	string zoneHydrographiqueShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/ZH.shp';	
	//file initDataDebitEntree <- csv_file ( '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/debitEntre.csv' , ";"); 	
	//file initDataDebitEntreeObs <- csv_file ( '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/debitEntreObs.csv', ";" ); 	
	
	string nomFichierDebitEntre <- "debitEntre.csv";
	string nomFichierDebitEntreObs <- "debitEntreObs.csv"; // Hydrologie de forçage sans les barrages!
	string pathToFichiersDebitEntre <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/zonesHydrographiques/';
	
	

	map<string, zoneHydrographique> mapZH <- map([]);
	list<zoneHydrographique> listeZonesHydrographiques <- [];
	list<zoneHydrographique> listeZonesHydrographiquesHierarchisees <- [];
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action creationZoneHydrographique{
		switch nomChoixModeleHydrographique {
        	match Simple {
        		do constructionZH(typeZH:zoneHydrographique);                    
            }
        	match SWAT {
               do constructionZH(typeZH:zoneHydrographiqueSWAT); 
               do initialisationParametresMNT(); 
            }            
            default {
                do constructionZH(typeZH:zoneHydrographique);                          
            } 
        }
        do initialisationDebitsEntresZonesHydrographiques();
	}

	// JV 150819 modif demandée par Benoit en prévision du passage à GAMA 1.8 (cf mail Benoît 30/07/19 et mantis #0002287)
	action constructionZH(species<zoneHydrographique> typeZH <- zoneHydrographique){
		//arg typeZH type: species default: zoneHydrographique;
		
		if !file_exists(zoneHydrographiqueShape) {do raiseError("fichier inexistant: " + zoneHydrographiqueShape);}
		//if !is_shape(zoneHydrographiqueShape) {do raiseError("le fichier " + zoneHydrographiqueShape + " n'est pas un fichier shape");}
		
		create typeZH from: file(zoneHydrographiqueShape) with: [idZoneHydrographique::string(read (ID_ZH)),
														   idExutoire::int(read( ID_ND_EXUT )),
														   zoneClimatique::string(read(ZONECLIM))]{
			name <- idZoneHydrographique;
			// Suppression des ilots nappartenat pas a la zone detude
			if(executerModeleSurUneZH and !(listNomsZHsDecoupageZone contains idZoneHydrographique)){
				ask self{
					do die();	
				}						
			}else{					
				listeZonesHydrographiques << self;	
				put self at: idZoneHydrographique in: mapZH;				
			}
		}
	}


	/*
	 * *****************************************************************************************
	 * Publique
	 * Lecture fichier avec debit entree pour certaine ZH
	 */ 
	action initialisationDebitsEntresZonesHydrographiques{
		// Dans le cas ou on voudrait forcer le debit de cette zone car la zone amont nest pas simulee (cas tres particulier)
//		if(nomDecoupageZonePourLectureFichiers = DecoupageAveyron and first(listeZonesHydrographiques where (each.idZoneHydrographique = "O583")) = nil){
//			listNomsZHsDebitForce << "O584";
//		}

		if(file_exists(pathToFichiersDebitEntre + nomFichierDebitEntre)){ // JV 250920
			file cheminfichier <- csv_file(pathToFichiersDebitEntre + nomFichierDebitEntre, ";", false);
			if ((!executerModeleNormatif or ! executerBarrage) and (file_exists(pathToFichiersDebitEntre + nomFichierDebitEntreObs))){ //and 
				cheminfichier <- file(pathToFichiersDebitEntre + nomFichierDebitEntreObs);
			}
			
			// On selectionne les zhs focrees
			list<zoneHydrographique> listeZhComplement <- [];
			loop idZh over: listNomsZHsDebitComplement{
				if(first(listeZonesHydrographiques where (each.idZoneHydrographique = idZh)) != nil){
					listeZhComplement << first(listeZonesHydrographiques where (each.idZoneHydrographique = idZh));
				}			
			}
			list<zoneHydrographique> listeZhForcees <- [];
			loop idZh over: listNomsZHsDebitForcee{
				if(first(listeZonesHydrographiques where (each.idZoneHydrographique = idZh)) != nil){
					listeZhForcees << first(listeZonesHydrographiques where (each.idZoneHydrographique = idZh));
				}			
			}
			if((!empty(listeZhForcees)) or (!empty(listeZhComplement))){
				matrix matriceDebit <- matrix(cheminfichier);	
				int nbLignes <- length(matriceDebit column_at 0);
				int nbColonnes <- length(matriceDebit row_at 0);
				loop j from: 1 to: ( nbColonnes - 1 ) { 
					list<string> colonneJ <- (matriceDebit column_at j) as list<string>;
					string idZhLue <- (colonneJ at 2);
					zoneHydrographique zhComplement <- first(listeZhComplement where (each.idZoneHydrographique = idZhLue)); 
					zoneHydrographique zhForcee <- first(listeZhForcees where (each.idZoneHydrographique = idZhLue)); 
					if((zhComplement != nil) or (zhForcee !=nil)){
						loop i from: 3 to: ( nbLignes - 1 ) { 
							list<string> ligneI <- (matriceDebit row_at i) as list<string>;
							string dateLue <- ligneI at 0;
							float volume <- (float(ligneI at j) / nbLDansM3 ) * nbSecondesDansUneJournee;	// L/s	-> m3/jour
							// Parsing date
							list<string> dateCouranteTemporaire <- (dateLue tokenize '/, ');
							int anneeCourant <- int(dateCouranteTemporaire at 2);
							if(anneeCourant < 1000){ // TODO : voir pb fichier entree !!
								anneeCourant <- anneeCourant + 2000;
							}
							int jourCourant <- int(dateCouranteTemporaire at 0);
							int moisCourant <- int(dateCouranteTemporaire at 1);
							int idDateCourante <- jourCourant * 1000000 +  moisCourant * 10000 + anneeCourant;
							// Calcul de indiceDateAConvertir
							int indiceDateConverti <- 0;
							ask dateCour{
								indiceDateConverti <- (convertirDateEnIndice(jourAConvertir:jourCourant, moisAConvertir:moisCourant, anneeAConvertir:anneeCourant));	
							}
							if(zhComplement != nil){
								put volume at: indiceDateConverti in: zhComplement.mapVolumeEntre;
							}else{//ZH Forcee
								put volume at: indiceDateConverti in: zhForcee.mapVolumeForcee;
							}
							
						}					
					}			
				}		
			}
		}			
	}

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action initialisationZonesHydrographiques{
		ask listeZonesHydrographiques{
			do initialisationZoneHydrographique();	
		}
		// On peut affecter les ZH amonts et aval (apres laffectation des noeuds de sortie et entree)
		ask listeZonesHydrographiques{
			do initialisationLienEntreZonesHydro();
		}
		do creationMapArbreZHEtNiveau();
	}
 
	 /*
	  * *****************************************************************************************
	  */
	 action creationMapArbreZHEtNiveau{
		// Initialisation du niveau a 0 pour les differents exutoires (pour maelia 3 exutoires = O187   O098   O208)
		ask ((listeZonesHydrographiques) where (listeExutoiresZoneMaelia contains each.idZoneHydrographique)){
			niveauHierarchiqueArbreZH <- 0;	
		}
						
		list<zoneHydrographique> listeZHamonts <- ((listeZonesHydrographiques) where (listeExutoiresZoneMaelia contains each.idZoneHydrographique));
		int niveauIncr <- 1; // mettre la premiere zh a 0 pour niveau
		loop while: (!empty(listeZHamonts)){
			list<zoneHydrographique> listeTemp <- [];
			ask listeZHamonts{								
				loop zhAmontCourante over: listeZonesHydrographiquesAmonts{
					zhAmontCourante.niveauHierarchiqueArbreZH <- niveauIncr;			
					listeTemp << zhAmontCourante;	
				}					
			}
			listeZHamonts <- listeTemp;		
			niveauIncr <- niveauIncr + 1;
		}
		
		// On rempli la liste des ZH hierachisee en mettant en premier les ZH avec le plus grand niveau et ainsi du suite
		listeZonesHydrographiquesHierarchisees <- listeZonesHydrographiques sort_by (each.niveauHierarchiqueArbreZH);	
		// Il faut inverser la liste
		list<zoneHydrographique> temp <- nil;
		int j <- length(listeZonesHydrographiquesHierarchisees) - 1;
		loop i from: 0 to: length(listeZonesHydrographiquesHierarchisees) - 1{
			temp << listeZonesHydrographiquesHierarchisees at j;
			 j <- j - 1;
		}
		listeZonesHydrographiquesHierarchisees <- temp;	
//	 	ask listeZonesHydrographiquesHierarchisees{
//			write "" + idZoneHydrographique + " - " + niveauHierarchiqueArbreZH;
//		}
	 }
	 
	/*
	 * *****************************************************************************************
	 * Accesseurs
	 */ 
	 float getDebitMax{
	 	float debitMax <- 0.0;
	 	if(!empty(listeZonesHydrographiques)){
		 	debitMax <- (listeZonesHydrographiques) max_of (each.debitCourant);	 		
	 	}
		return debitMax;
	 }
	 float getSurfaceTotaleZHs{
		let surfaceZH type: float value: 0.0;
		loop zhCourante over: listeZonesHydrographiques{
			surfaceZH <- surfaceZH + ((zhCourante.shape).area);
		}		
		return surfaceZH;
	 }
	float getVolumeUtileAvantPrelevementEtRejet_ZM{
	 	arg nature type: string default: SURF;	 	
		float volume <- 0.0;
 		ask listeZonesHydrographiques{
		 	volume <- volume + getVolumeUtileAvantPrelevementEtRejet(nature);				
 		} 			 	
	 	return volume;
	}
	float getVolumeUtileApresPrelevementEtRejet_ZM{
	 	arg nature type: string default: SURF;	 	
		float volume <- 0.0;
 		ask listeZonesHydrographiques{
		 	volume <- volume + getVolumeUtileApresPrelevementEtRejet(nature);				
 		} 			 	
	 	return volume;
	}
		
	float getVolumePreleve_ZH_ZM{
	 	arg nature type: string default: SURF;	
	 	arg type type: string default: SOUHAITE; 	 		
		float volume <- 0.0;		
 		ask listeZonesHydrographiques{	
		 	volume <- volume + getVolumePreleve(nature, type);				
 		} 			 	
	 	return volume;
	}
	float getVolumeRejet_ZH_ZM{ // il ny a des rejets que pour SURF et on ne calcul pas le rejet souhaite
		float volume <- 0.0;
 		ask listeZonesHydrographiques{
		 	volume <- volume + getVolumeRejet();				
 		} 			 	
	 	return volume;
	}
	float getSommeVolumePreleve_ZH_ZM{
		arg type type: string default: SOUHAITE;
		return (getVolumePreleve_ZH_ZM(SURF, type) + getVolumePreleve_ZH_ZM(NAPP, type) + getVolumePreleve_ZH_ZM(RET, type));		
	}
	float getSommeVolumeRejet_ZH_ZM{ // forcement en SURF et REEL
		return getVolumeRejet_ZH_ZM();		
	}
	float getSommeVolumeConsome_ZH_ZM{
		return (getSommeVolumePreleve_ZH_ZM(REEL) - getSommeVolumeRejet_ZH_ZM());		
	}
}

species zoneHydrographique{
	string idZoneHydrographique <- '';
	int idExutoire <- 0; //lecture dans le shp
	list<ilot> listeIlotsAssocies <- [];
	list<typeDeSol> listeTypeDeSolAssocies <- [];	
	list<clc> landCoverAssocie <- [];
	list<zoneHydrographique> listeZonesHydrographiquesAmonts <- []; // au desus
	zoneHydrographique zoneHydrographiqueAval <- nil; // au dessous   // 1 et 1 seulement (exutoire)
	noeudHydrographique exutoire <- nil;
	noeudHydrographique pointDentree <- nil;		
	zoneMeteoMoyenne meteo <- nil;	// zoneMeteoMoyenneAssociee	
	map<string,list<ressourceEnEau>> ressourceEnEauAssociees <- map([]);			
	float pluie <- 0.0; // Rday [mm]
	float tMoy <- 0.0; // tmpav(izh)
	float tMin <- 0.0; // tmn(izh) ou tmnav
	float tMax <- 0.0; // tmx(izh) ou tmxav
	float surfaceIlotsTotale <- 0.0;
	float debitCourant <- 0.0;
	float volumeEntree <- 0.0;	 // wtrin
	float volumeSorti <- 0.0; // rtwtr  ->    cest le debit de sorti de la zh courante au jour courant	
	float volumeEntrantDesZHsAmonts <- 0.0;
	bool isDebitNegatifPasDeTempsCourant <- false;
	int niveauHierarchiqueArbreZH <- -1;
	map<int,float> volumesLacherBarrage <- map<int,float>([]);		
	// Stockage eau provenant des ilots
	float volumeRuissellementDeSurfaceRPG <- 0.0; 
	float volumeEcoulementLateralRPG <- 0.0; 	
	float volumeEvapotranspirationRPG <- 0.0;	
	float volumeEcoulementEauSouterraineRPG <- 0.0; 
	float volumePercolationRPG <- 0.0; // [m3] JV 150618 		
	float volumeHumiditeHorizonTotalRPG <- 0.0; // [m3] JV 280618					
	map<int,float> mapVolumeEntre <- map<int,float>([]); // debit complementaire a la ZH
	map<int,float> mapVolumeForcee <- map<int,float>([]); // debit forçage ZH
	//zone climatique
	string zoneClimatique <- "";
	// Affichage	
	rgb couleurZoneHydrographique <- rgb('white');
	rgb couleurEvolutionTemperature <- rgb('white');
	rgb couleurCoursDeauZoneHydrographique <- rgb('blue');
	rgb couleurDebitZoneHydrographique <- rgb('white'); // au lieu de colorer les cours d'eau on colore la zh entiere
	rgb couleurEvolutionPrecipitation <- rgb('white');
			
	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{				
		do applicationConditionsMeteo();				
		do phaseSol();
		do calculVolumeUtile();
		if(isPrelevementEtRejetSimules){
			do calculVolumePrelevesReels();	// on prend en compte volumePhaseSol + volumeZHamonts		
		}						
		do phaseSolRPG(); // on fait la croissance des plantes apres les prelevements (pour lirrigation qui doit s efaire avant de faire ruisseler leau des parcelles)

		// JV bilan hydro
		//do checkBilanPhaseSol();
		//do checkBilanPhaseSol_Hydro();
		//do checkBilanPhaseSol_RPG();
		// fin JV			

		ask world{
			do remplissageRetenue(myself);
		}
		do calculVolumeUtileCoursEauReel(); // Pour tenir compte de l'interception de l'eau par les retenues!
		if(isPrelevementEtRejetSimules){	
			do calculRejetsReels();
			do miseAjourVolumeNappe();
		}
		do phaseRoutage();
		//do checkBilanPhaseRoutage();
		
		do calculDebitSorti();			
		do changementCouleurEnFonctionTemperatureMoyenne();
		do changementCouleurEnFonctionPrecipitationEtEtpMoyen();			
		do changementCouleurEnFonctionDebit();	
	}
	
	/*
	 * *****************************************************************************************
	 */			
	action initialisationZoneHydrographique{}
			
   /*
  	* *****************************************************************************************
	* Initialisation des zones hydro en amont et aval
	*/
	action initialisationLienEntreZonesHydro{
		
		if (length(noeudHydrographique as list) > 0){ // TODO Supprimer code quand tous les pretraitements auront ete refait
			// Implique egalement de faire disparaitre le code sur les noeudsHydro qui n'ont alors plus aucune utilite
			// ZH amonts
			listeZonesHydrographiquesAmonts <- (listeZonesHydrographiques) where (each.exutoire = pointDentree); // 0 ou n
			// ZH avals
			if(length((listeZonesHydrographiques) where (each.pointDentree = exutoire)) > 1){
				write '[ZH/initialisationLienEntreZonesHydro] Probleme : plus de 1 ZH en aval !!!! (exutoire) ' + exutoire + " pour la ZH "+ name;
				write '[ZH/initialisationLienEntreZonesHydro] zoneHydrographiqueAval = ' + ((listeZonesHydrographiques) where (each.pointDentree = exutoire));
			}
			zoneHydrographiqueAval <- first((listeZonesHydrographiques) where (each.pointDentree = exutoire));	
		}else{ //Cas ou l'information du BV suivant est dans le shape contenu dans la variable idExutoire
			listeZonesHydrographiquesAmonts <- (listeZonesHydrographiques) where (string(each.idExutoire) = idZoneHydrographique);
			zoneHydrographiqueAval <- first((listeZonesHydrographiques) where (each.idZoneHydrographique = string(idExutoire)));
		}
		
							
	}
	
	/*
	 * *****************************************************************************************
	 * Eau provenant des barrages, on stocke leau dans une map car le barrage a un temps de transfert
	 */
	 action stockageLacherBarrage(float eauEnEntree, int indiceDateDarrivee){
	 	float eauArrvantADateEntree <- volumesLacherBarrage at indiceDateDarrivee;
	 	put (eauEnEntree+eauArrvantADateEntree) at: indiceDateDarrivee in: volumesLacherBarrage;
	 }

			
	/*
	 * *****************************************************************************************
	 * Pluie et ETP
	 */	
	action applicationConditionsMeteo{						
		// il faut retrancher a l'eau de pluie qui arrive sur la ZH l'eau de pluie qui arrive sur ses ilots
		pluie <- meteo.pluie;			
 		tMin <- meteo.tMin; // tmn(izh) ou tmnav
		tMax <-  meteo.tMax; // tmx(izh) ou tmxav
 		tMoy <- meteo.tMoy; // tmpav(izh)
	}

	/*
	 * *****************************************************************************************
	 * Pour le modele simple il ny a pas de phase sol donc le volume phase sol est la pluie uniquement
	 */	
	action phaseSol{}

	/*
	 * *****************************************************************************************
	 * PHASE SOL des HRUs RPG
	 */
	action phaseSolRPG{
		ask listeIlotsAssocies{
			do croissancePlante();
		}
	}

	/*
	 * *****************************************************************************************
	 */	
	action miseAzeroVolume{		 
		volumeRuissellementDeSurfaceRPG <- 0.0;
		volumeEcoulementLateralRPG <- 0.0;
		volumeEvapotranspirationRPG <- 0.0;
		volumeEcoulementEauSouterraineRPG <- 0.0;
		volumePercolationRPG <- 0.0;
		volumeHumiditeHorizonTotalRPG <-0.0;		
	}


	/*
	 * *****************************************************************************************
	 * Calcul Volume de surface presant pour les prelevements
	 */	
	action calculVolumeEntreAmont{	
		// Calcul du volume entree dans cours deau principal de la ZH le jour courant (on recupere leau de sortie de toutes ses ZH amonts + eau de ruissellement de la phase sol)
		 
		 if((mapVolumeForcee at dateCour.indiceDate) != nil){
			volumeEntrantDesZHsAmonts <- mapVolumeForcee at dateCour.indiceDate;	
		}else{
			volumeEntrantDesZHsAmonts <- 0.0;
			 ask(listeZonesHydrographiquesAmonts){	 		
			 	myself.volumeEntrantDesZHsAmonts <- myself.volumeEntrantDesZHsAmonts + volumeSorti;
			 }	 
			
			if((mapVolumeEntre at dateCour.indiceDate) != nil){
				volumeEntrantDesZHsAmonts <- volumeEntrantDesZHsAmonts + mapVolumeEntre at dateCour.indiceDate;	
			}
		}
		assert(volumeEntrantDesZHsAmonts>=0);			
	}
	
	

	/*
	 * *****************************************************************************************
	 * Calcul Volume de surface presant pour les prelevements
	 */	
	action calculVolumeUtileCoursEauReel{	
	 	
	 	// Calcul du volume present dans la ZH au moment du calcul des prelevements reels (sans la phaseSOlrpg)
	 	float volumeUtilePourPrelevementsCoursEau <- (volumeEntrantDesZHsAmonts + getVolumePhaseSolHydro() + (volumesLacherBarrage at dateCour.indiceDate));		 	
	 	list<ressourceEnEau> listeCoursDeauZH <- (ressourceEnEauAssociees at SURF);		 	 			 			 	
	 	ask listeCoursDeauZH{
	 		volumeUtileAvantPrelevementEtRejet <- volumeUtilePourPrelevementsCoursEau / length(listeCoursDeauZH);
	 	}		 	
	}

	/*
	 * *****************************************************************************************
	 * Calcul Volume des nappes presant pour les prelevements
	 */	
	action calculVolumeUtileNappesReel{	
	 	list<ressourceEnEau> listeNappes <- (ressourceEnEauAssociees at NAPP);			 			 			 			 	
	 	ask (listeNappes){
	 		volumeUtileAvantPrelevementEtRejet <- quantiteEauMaxDispoAgri; 
	 	}
	}

	/*
	 * *****************************************************************************************
	 * Calcul Volume des retenues presant pour les prelevements
	 */	
	action calculVolumeUtileRetenuesReel{	
	 	list<retenueCollinaire> listeRetenues <- (ressourceEnEauAssociees at RET) as list<retenueCollinaire>;			 			 			 			 	
	 	ask (listeRetenues){
	 		volumeUtileAvantPrelevementEtRejet <- max([0.0 , volumeActuel - volumeCulot]); 
	 	}
	}

	/*
	 * *****************************************************************************************
	 * Calcul des volumes presants dans chaque type de ressources de la ZH (surf, nappe, ret)
	 */	
	action calculVolumeUtile{
		do calculVolumeEntreAmont();	
		do calculVolumeUtileCoursEauReel();		
		do calculVolumeUtileNappesReel();
		do calculVolumeUtileRetenuesReel();	
	}

	/*
	 * *****************************************************************************************
	 */
	action calculVolumePrelevesReels{				
		ask (interleave(ressourceEnEauAssociees.values)){
			do calculVolumePrelevesReels();
		}
	}

	/*
	 * *****************************************************************************************
	 */
	action calculRejetsReels{				
		list<coursDeau> coursDeauAssocies <- (ressourceEnEauAssociees at SURF) as list<coursDeau>;
		ask coursDeauAssocies{
			do calculRejetsReels();
		}
		
	}

	/*
	 * *****************************************************************************************
	 * Une fois que les prelevements humains et rejets calcules, on peut mettre a jour la quantite presente dans les nappes de chaque HRU
	 */	
	action miseAjourVolumeNappe{}

	/*
	 * *****************************************************************************************
	 * Une fois que les prelevements humains et rejets calcules, on peut connaitre le volume dentree de la ZH pour la phase routage
	 */	
	float getVolumeEntreePhaseRoutage{
		// JV 241019 modif pour bug prelevements (1/2) (bug #0002435)
		// volumeEntree <- getVolumeUtileAvantPrelevementEtRejet(SURF);
		volumeEntree <- getVolumeUtileAvantPrelevementEtRejet(SURF) + getVolumePhaseSolRPG();
		float volumeRes <- volumeEntree;
		if(isPrelevementEtRejetSimules){
			// JV 241019 modif pour bug prelevements (2/2) (bug #0002435)
			//volumeRes <- volumeRes - getVolumePreleve(SURF, REEL) + (getVolumeRejet() + getVolumePhaseSolRPG());
			volumeRes <- volumeRes - getVolumePreleve(SURF, REEL) + getVolumeRejet();
		}		 
		
		if(volumeRes < zeroApproche){		 		
	 		if(volumeRes < 0.0){
	 			isDebitNegatifPasDeTempsCourant <- true;
	 		}
	 		volumeRes <- 0.0;
	 	}	
	 	
	 	return volumeRes; 
	}

	/*
	 * *****************************************************************************************
	 * Pour le modele simple, le volume de sorti est egal a celui dentree (il ny a pas de perte entre lecoulement dans la ZH pendant le pas de temps)
	 * On suppose que dans une journee toutes les precipatations qui sont allees sur la zone se sont ecoulees dans la zone suivante
	 */	
	action phaseRoutage{
		// Calcul du volume de sorti
		volumeSorti <- getVolumeEntreePhaseRoutage(); // [m] * [m2] = [m3]						 	
	}			

	/*
	 * *****************************************************************************************
	 */	
	action calculDebitSorti{					
	 	// Calcul du debit pour le jour courant		 	
 		debitCourant <- volumeSorti / nbSecondesDansUneJournee;	 
	}

	/*
	 * *****************************************************************************************
	 * Utile uniquement pour SWAT
	 */		 
	action miseAjourHRUrpg(map<string,list<ilot>> mapDisparitionIlots){}
	 
	/*
	 * *****************************************************************************************
	 * La couleur de la zone hydro va changer en fonction de l'evolution de sa temperature moyenne (Tmin-Tmax)
	 */	
	action changementCouleurEnFonctionTemperatureMoyenne{				
		set couleurEvolutionTemperature value: paletteCouleursTemperature at int(tMoy);	// temperatureMoyenne					
	}
	
	/*
	 * *****************************************************************************************
	 * Coloration ZH en fonction de la valeur des precipitations (RRmm Moyenne)
	 */	
	action changementCouleurEnFonctionPrecipitationEtEtpMoyen{
		if (pluie = 0.0){
			set couleurEvolutionPrecipitation value: rgb('white');				
		}								
		else{
			loop indiceCorrespondantALaPlageDuDebit over: mapCorrespondanceIndicePlageHauteurPluie.keys{
				let debitMin type: int value: (mapCorrespondanceIndicePlageHauteurPluie at indiceCorrespondantALaPlageDuDebit) at 0;
				let debitMax type: int value: (mapCorrespondanceIndicePlageHauteurPluie at indiceCorrespondantALaPlageDuDebit) at 1;
				if (pluie > debitMin) and (pluie <= debitMax){
					set couleurEvolutionPrecipitation value: paletteCouleursDebitZoneHydro at indiceCorrespondantALaPlageDuDebit;
				}
			}
		}
	}		 
	
	/*
	 * *****************************************************************************************
	 * Coloration de la zone en fonction du debit
	 */	  
	action changementCouleurEnFonctionDebit{
		if (debitCourant < 0.0 or isDebitNegatifPasDeTempsCourant){
			set couleurCoursDeauZoneHydrographique value: rgb('red');
			set couleurDebitZoneHydrographique value: rgb('red');
			set isDebitNegatifPasDeTempsCourant value: false;		
		}
		else{
			if (debitCourant = 0.0){
				set couleurCoursDeauZoneHydrographique value: rgb('white');
				set couleurDebitZoneHydrographique value: rgb('white');					
			}								
			else{
				loop indiceCorrespondantALaPlageDuDebit over: mapCorrespondanceIndicePlageDebit.keys{
					let debitMin type: int value: ((mapCorrespondanceIndicePlageDebit at indiceCorrespondantALaPlageDuDebit) at 0);
					let debitMax type: int value: ((mapCorrespondanceIndicePlageDebit at indiceCorrespondantALaPlageDuDebit) at 1);
					if (debitCourant > debitMin) and (debitCourant <= debitMax){
						set couleurCoursDeauZoneHydrographique value: paletteCouleursDebitZoneHydro at indiceCorrespondantALaPlageDuDebit;
						set couleurDebitZoneHydrographique value: paletteCouleursDebitZoneHydro at indiceCorrespondantALaPlageDuDebit;
					}
				}
			}
		}				
			
		list<coursDeau> coursDeauAssocies <- (ressourceEnEauAssociees at SURF) as list<coursDeau>;
		ask coursDeauAssocies{
			set couleurEvolutionDebitCoursDeau value: myself.couleurCoursDeauZoneHydrographique;
		}
	}


	float getSurfaceZhSansIlots{
		return (shape.area - surfaceIlotsTotale); // [m2]
	}
	float getVolumePrecipitations{
		return (pluie / nombreMillimetreDansUnMetre) * getSurfaceZhSansIlots(); // [m3]
	}	
	float getVolumePhaseSol{
		return getVolumePhaseSolHydro() + getVolumePhaseSolRPG(); // [m3]		
	}
	float getVolumePhaseSolHydro{
		return getVolumePrecipitations() * pourcentagePluiePourCoursDeauPrincipal; // [m3]		
	}
	float getVolumeRuissellementDeSurface{ // volQsurf [m3]
		return (volumeRuissellementDeSurfaceRPG);
	}
	
	action miseAjourVolumePhaseSolHydro (float fraction){ // En fait non pertinent pour les ZH de base
		// car les grandeurs suivantes sont de bases nuls et les retenues non connectes sont ignoree
		do miseAjourVolumeRuissellement(fraction);
		volumeEcoulementLateralRPG <- volumeEcoulementLateralRPG * (fraction);
		volumeEcoulementEauSouterraineRPG <- volumeEcoulementEauSouterraineRPG * (fraction);
	}
	action miseAjourVolumeRuissellement (float fraction){		
		volumeRuissellementDeSurfaceRPG <- volumeRuissellementDeSurfaceRPG * (fraction);
	}		
	// Prend en compte la pluie et les rejets irrigation :  ne correspond donc pas uniquement aux rejets de lirrigation...
	float getVolumePhaseSolRPG{
		return volumeRuissellementDeSurfaceRPG + volumeEcoulementLateralRPG + volumeEcoulementEauSouterraineRPG; // [m3]		
	}		

	float getVolumePreleve{
		arg natureRessource type: string default: SURF;
		arg type type: string default: SOUHAITE; 	

		float volume <- 0.0;			
		list<ressourceEnEau> liste <- ressourceEnEauAssociees at natureRessource;
		ask (liste){
			volume <- volume + self.getVolumePreleve(type);
		}			
		return volume;
	}
	float getVolumeRejet{			// AEP ET IND uniquement car le rejets RPG sont calcules depuis les ilots et non a laide des equ de rejet (donc cest la ZH qui gere et pas les cours deau...)
		float volume <- 0.0;
		
		list<coursDeau> liste <- ressourceEnEauAssociees at SURF as list<coursDeau>;
		ask (liste){
			volume <- volume + self.getVolumeRejetReel();
		}			
		return volume;
	}
	float getVolumeUtileAvantPrelevementEtRejet{
		arg natureRessource type: string default: SURF;
		
		float volume <- 0.0;
		list<ressourceEnEau> liste <- ressourceEnEauAssociees at natureRessource;
		ask (liste){
			volume <- volume + getVolumeUtileAvantPrelevementEtRejet();
		}			
		return volume;
	}				
	float getVolumeUtileApresPrelevementEtRejet{
		arg natureRessource type: string default: SURF;
		
		float volume <- 0.0;
		list<ressourceEnEau> liste <- ressourceEnEauAssociees at natureRessource;
		ask (liste){
			volume <- volume + self.getVolumeUtileApresPrelevementEtRejet();
		}			
		return volume;
	}				

	float rechargeRetenueParNappe (float eauDemande){
		return 0.0;
	}
	/*
	 * *****************************************************************************************
	 * Display
	 */
	aspect basic{
		draw shape color: couleurZoneHydrographique;
	}
	aspect evolutionTemperatureAspect{
		draw shape color: couleurEvolutionTemperature border: couleurEvolutionTemperature;
//    		draw '' + int(tMoy) at: location color: rgb('black') size: taillePointsMax;
	}
	aspect evolutionDebitAspect{
		draw shape color: couleurDebitZoneHydrographique border: couleurDebitZoneHydrographique;
//    		draw '' + int(debitCourant) at: location color: rgb('black') size: taillePointsMax;
	}	
	aspect evolutionPrecipitationAspect{
		draw shape color: couleurEvolutionPrecipitation;
//    		draw '' + (pluie) at: location color: rgb('black') size: taillePointsMax;
	}
	
	/*
	 * *****************************************************************************************
	 * Debug
	 */
	string toString{
		string resultat <- "[ZH] " + name;
		resultat <- resultat + ' | volumeEntrantDesZHsAmonts : ' + volumeEntrantDesZHsAmonts;
		resultat <- resultat + ' | volumeSorti : ' + volumeSorti;
		resultat <- resultat + ' | mapVolumeEntre at date.indiceDate : ' + mapVolumeEntre at dateCour.indiceDate;
		resultat <- resultat + ' | mapVolumeForcee at date.indiceDate : ' + mapVolumeForcee at dateCour.indiceDate;
		resultat <- resultat + ' | debitCourant : ' + debitCourant;
		return resultat; 					
		}
}	

