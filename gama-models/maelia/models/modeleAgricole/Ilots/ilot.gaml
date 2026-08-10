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
 *  Ilots
 *  Author: Maroussia Vavasseur
 *  Description: L'ilot est la seule entite georeferencee du modele agricole. C'est par regroupement d'ilots que l'on peut avoir une visualisation de l'exploitation. Mais on ne peut en revanche 
 *  			 avoir aucune representation de ses parcelles.
 * 				 L'ilot est l'entite qui va faire le lien avec le modele hydrographique. De meme, c'est sur l'ilot que la pluie va tomber.
 */

model ilot

import "../Parcelles/parcelle.gaml"
import "../../output/selectionOutput.gaml" // JV 110221 to know whether we have to cumulate drain for monthly output or not 

global{
	string ilotsAllDepartementsShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/dansZone/ilots.shp';
	map<string,ilot> mapIlots <- map([]);
	list<ilot> listeIlots <- [];
	list<string> listeExploitations <- []; // utile uniquement pour la creation des ilots hors zone

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action creationIlots{
		
		if !file_exists(ilotsAllDepartementsShape)	{do raiseError("fichier inexistant: " + ilotsAllDepartementsShape);}
		//if !is_shape(ilotsAllDepartementsShape)		{do raiseError("le fichier " + ilotsAllDepartementsShape + " n'est pas un fichier shape");}	
			
		create ilot from: file(ilotsAllDepartementsShape) with: [	id::string(read ( ID_ILOT )), 
															codeExploitationAssociee::string(read ( PAE_ID_EXP )),
															penteAssociee::float(read( PENTE_MOY )), 
															penteSwat::float(read( PENTE_SWAT )),  // TODO = a mettre dans donnees entrees (pour le moment une HRUrpg creee par ilot pratiquement)
															idsEquipementsAssocies::string(read( LISTE_EQUS ))]{		
			if(codeExploitationAssociee = ""){
				codeExploitationAssociee <- string(shape get( ID_EXPL ));			
			}
			if("." in id){
				id <- (id tokenize "." at 0);			
			}			
			zoneHydroAssociee<- mapZH at string(shape get( ID_ZH ));						
			if string(shape get( CARACT_IRR)) = 'O'{
				isIrrigable <- true;
			}

			// Suppression des ilots nappartenat pas a la zone detude			
			if(zoneHydroAssociee = nil or 
				(!(codeExploitationAssociee = idExploitationAexecuter) and executerUnSeulAgriculteur) or
				(!(listIdExploitationAexecuter contains codeExploitationAssociee) and executerSurEnsembleExploit) or
					(executerModeleAgricoleIrrigationUniquement and !isIrrigable)){
				ask self{
					do die();	
				}						
			}else{		
				name <- id+ '_' + string(shape get( CARACT_IRR));// + '-' + name;		
										
				// Lien type de sol	
				if(!executerParcelleVirtuelle){
					sol <- first(zoneHydroAssociee.listeTypeDeSolAssocies where (each.idTypeDeSOl = string(shape get( ID_SOL ))));
				}else{
					// Uniquement dans le cas ou on execute le modele Aveyron sur une parcelle et si on a defini un nom de type de sol en entree
					sol <- first((typeDeSol as list) where (each.nom = typeDeSolForceParcelle));
					//sol <- first((typeDeSol as list) where (each.idTypeDeSOl = typeDeSolForceParcelle));			
				}					
				if(sol = nil){
					write "[INIT/ILOT] Le sol "+string(shape get( ID_SOL ))+" est nul ! " + id;
					do die();
				}			
								
				put self at: id in: mapIlots;
				listeIlots << self;
																		
				if(! (codeExploitationAssociee in listeExploitations)){
					listeExploitations << codeExploitationAssociee;
				}
				
				if (isIrrigable){
					string idMat <- string(shape get( MATERIEL)); 
					if(executerParcelleVirtuelle) and (typeDeMaterielIrrigationForceParcelle != 'NA'){
						idMat <- typeDeMaterielIrrigationForceParcelle;
					}
					materielIlot <- (mapMateriel at idMat);
					if (materielIlot = nil){
						materielIlot <- mapMateriel["enroul25"];
						write "Affectation d'un materiel enroul25 par defaut a l'ilot "+ name;
					}
					if (materielIlot = nil){
						materielIlot <- any(mapMateriel);
						write "Affectation d'un materiel choisi aleatoirement a l'ilot "+ name;
					}
				}
				
				
				
			}						
		}
	}
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action initialisationIlot{		
		ask (listeIlots + listeIlotsHorsZone){
			do initialisationIlots();
		}
	}
}

species ilot schedules: [] {
	string id <- "";	 	
	string codeExploitationAssociee <- "";
	bool isIrrigable <- false;		
	list<parcelle> listeParcelles <- [];
	list<parcelle> listeParcellesHydro <- []; // les parcelles a linterieure vont etre traitee par les hru
	parcelle parcellePrincipale <- nil; 	// Cette parcelle correspond a la parcelle de lilot qui a la plus grande surface, elle est utilie uniquement pour l'affichage de l'ilot
	zoneMeteo meteo <- nil;
	zoneHydrographique zoneHydroAssociee <- nil;		
	typeDeSol sol <- nil;		
	map<equipementDeCaptageIRR,float> listeEquipementsCaptagesAssocies <- map<equipementDeCaptageIRR,float>([]); // {equ:impact}		
	equipementDeCaptageIRR ppaCourant <- nil;
	agriculteur agriculteurAssocie <- nil;				
	hruRPG hruRPGassociee <- nil;	
	float penteSwat <- 0.0;
	float penteAssociee <- 0.0;
	string idsEquipementsAssocies <- '';
	float surfaceIlotAPrtirDesParcelles <- 0.0;
	float surfaceParcellesUtiles <- 0.0;
	materielIrrigation materielIlot <- nil;
	float drainIlot <- 0.0; //pour sortie
	float drainIlotCumulMois <- 0.0; //pour sortie
	float drainIlotCumulQuinzaine <- 0.0; //pour sortie
	float ETRIlot <- 0.0; //pour sortie
	float ETRIlotCumulMois <- 0.0; //pour sortie
	float ETRIlotCumulQuinzaine <- 0.0; //pour sortie
	float ruissellementIlot <- 0.0; //pour sortie
	float ruissellementIlotCumulMois <- 0.0; //pour sortie
	float ruissellementIlotCumulQuinzaine <- 0.0; //pour sortie
	bandeAltitude bandeAltiAssocie <- nil;
	float surfaceIlotAvecCultureIrriguee <- 0.0;
	bool isSurfaceIlotAvecCultureIrrigueeCalculated <- false; 
	
	//Affichage
	rgb couleurIlotParExploitation <- rgb('yellow');
		

	action comportenmentJournalier{
		do remiseAzeroIlot();
		//Mise a jour du ppaCourant apres reinit de l ilot car cette phase contient le report du cout de leau rellement consomme
		ppaCourant <- getPpaASolliciterJourCourant(); // peut etre nul dans le cas ou toutes les ressoureces sont vides, ou si modele hydro non exe
		if(dateCour.jour=1){
			surfaceIlotAvecCultureIrriguee <- 0.0; //donne necessaire pour le calcul des charges d'irrigation et la gestion des barrages 
			isSurfaceIlotAvecCultureIrrigueeCalculated <- false; 
		}
	}
	action croissancePlante{
		do ruissellementVersZH();
	}

	action calculSurfaceRellementIrriguableSurAnnee{
		if(!isSurfaceIlotAvecCultureIrrigueeCalculated){
			loop p over: listeParcelles{
				if(p.cultureParcelle != nil){
					if(p.cultureParcelle.isIrrigable()){
						surfaceIlotAvecCultureIrriguee <- surfaceIlotAvecCultureIrriguee+ p.surface;	
					}
				}
			}
			isSurfaceIlotAvecCultureIrrigueeCalculated <- true; 
		}
	}
	/*
	 * *****************************************************************************************
	 * Associer l'ilot aux zones hydro qu'il intercepte et au zoneMeteo le plus proche
	 */	
	action initialisationIlots{			
		if (listeParcelles = nil or empty(listeParcelles)) {
//				write '[ILOT] ' + id + "- LISTE PARCELLE NULLE = " + listeParcelles;								
			remove key: id from: mapIlots;
			remove self from: listeIlots;
			do die();
		}					
		else {					
			// Lien ilot / ZH					
			ask zoneHydroAssociee{	 
				listeIlotsAssocies << myself;	
				//surfaceIlotsTotale <- surfaceIlotsTotale + myself.surfaceParcellesUtiles;	// JV 260922 transmission de la surface à la ZH déplacé plus loin, cf. Mantis #0002938		
			}
			
			// calcul de la surface total de l'ilot									
			parcellePrincipale <- (listeParcelles with_max_of ((each.surface))); 																	
			loop parcelleCourante over: (listeParcelles + listeParcellesHydro){
				surfaceIlotAPrtirDesParcelles <- surfaceIlotAPrtirDesParcelles + parcelleCourante.surface;
			}	
			// JV 290522 on ne réajuste pas la surface de la parcelle si on ne simule qu'une parcelle, cf. Mantis #0002903 
			if(!executerParcelleVirtuelle and !executerUneSeuleParcelle and reajusterSurfaceParIlot){
				// Redefinition de la surface pour quelle corresponde exactement a la suface gama
				//if(verboseMode){write "surface avant MAJ ilot" + listeParcelles collect (each.idParcelle + " " + each.surface);} // JV debug					
				ask (listeParcelles + listeParcellesHydro){
					surface <- surface * (myself.shape.area / myself.surfaceIlotAPrtirDesParcelles);
				}					
				//if(verboseMode){write "surface apres MAJ ilot" + listeParcelles collect (each.idParcelle + " " + each.surface);} // JV debug		
				//if(verboseMode){write "shape.area=" + shape.area + " surfaceIlotAPrtirDesParcelles=" + surfaceIlotAPrtirDesParcelles;}			
			}				
			//if(verboseMode){write "shape.area=" + shape.area + " surfaceIlotAPrtirDesParcelles=" + surfaceIlotAPrtirDesParcelles;}			
			ask (listeParcelles){
				myself.surfaceParcellesUtiles <- myself.surfaceParcellesUtiles + surface;
			}
			ask zoneHydroAssociee{   // JV 230822 MAJ ZH.surfaceIlotTotale pour tenir compte de l'ajustement des surfaces des parcelles, cf. Mantis #0002938
				surfaceIlotsTotale <- surfaceIlotsTotale + myself.surfaceParcellesUtiles;             
			}

			// Le lien entre equipement et ilot se fait en pretraitement
			if(executerModeleHydrographique and isPrelevementEtRejetSimules){
				list<equipementDeCaptageIRR> listeEquiTemp <- []; 
				list<string> ids <- idsEquipementsAssocies tokenize('_');
				if(!empty(ids)){
					// Pour faciliter, il faudrait considerer que lilot nest relie qua un equipement de captage, car :
					// ATTENTION : les restricions se font sur les points de prelevements, il faut repenser en partie la maniere dont lagriculteur irrigue 
					//				(si un des ppa de lilot est en restriction, il ne va pouvoir irriguer quun certain pourcetage, mais il pourrait aussi revoir 
					//				sa strategie pour prendre plus deau sur les autres ppa que dhabitude)
					listeEquiTemp <- (equipementDeCaptageIRR as list) where (ids contains each.idEquipement);
				}		
				
				// Dans le cas ou on execute sur une ZH, il est possible que lilot ne puisse pas etre relie a ses equipements (car pas crees), alors on affecte le plus proche
				if(affecterEqIrrSiInexistant){
					if(empty(listeEquiTemp) and isIrrigable){ //  and isIrrigable <- pour le moment des parcelles ont un sdc Irriguee sur un ilot considere comme non irrigable
						equipementDeCaptageIRR equ <- (equipementDeCaptageIRR as list) closest_to self;
						listeEquiTemp << equ;
						if isPrelevementEtRejetSimules { // peut pas appeler raiseWarning depuis une fonction non globale
							string ch <- "l'îlot " + id + " est irriguable mais n'est pas rattaché à un équipement de prélèvement (vraisembablement car celui-ci est en dehors de la zone simulée \u2192 affectation de l'équipement le plus proche: " + equ.idEquipement;
							write "\t\u2757 WARNING " + ch color:#orange;
							initLogWarning <- initLogWarning + "- " + ch + "\n";
						}
						if(!executerModeleSurUneZH and isPrelevementEtRejetSimules){
							//write "[ILOT/init] Attention : equ nul (si simu pas sur zone entiere OU prelevts non simules -> normal) " + id + " - listeEquiTemp = " + listeEquiTemp + " - ids = " + ids;
							write "[ILOT/init] Attention : equ nul " + id + " - listeEquiTemp = " + listeEquiTemp + " - ids = " + ids;
						}											
					}
				}
								
				// TODO supprimer une partie du code, on a plus besoin que la somme du "pourcentage" ressource fasse 1
				
				// Initialisation du prorata de chaque equ
				float sommePourcentage <- 0.0;		
				loop typeRess over: importancePrelevementParTypeRessource.keys{	
					list<equipementDeCaptageIRR> listeEquAvecCeType <- (listeEquiTemp where (each.getTypologiePrioritaire() = typeRess));
					if(!empty(listeEquAvecCeType)){
						sommePourcentage <- sommePourcentage + (importancePrelevementParTypeRessource at typeRess);
					}		
				}
				loop typeRess over: importancePrelevementParTypeRessource.keys{							
					list<equipementDeCaptageIRR> listeEquAvecCeType <- (listeEquiTemp where (each.getTypologiePrioritaire() = typeRess));
					if(!empty(listeEquAvecCeType)){
						float pourcentageRessource <- ((importancePrelevementParTypeRessource at typeRess) / sommePourcentage)/ length(listeEquAvecCeType);						
						ask listeEquAvecCeType{
							put pourcentageRessource at:self in: myself.listeEquipementsCaptagesAssocies;
						}								
					}					
				}	
				ppaCourant <- getPpaPrioritaire(listeEquipementsCaptagesAssocies.keys);
			}
		}
	}
			
	/*
	 * *****************************************************************************************
	 * Va chercher les valeurs du zoneMeteo pour la date courante et fait pleuvoir sur l'ilot
	 */
	action remiseAzeroIlot {			
		ask listeParcelles{	
			do affectationCoutIrrigation();
			do remiseAzeroParcelle();							
		}							
	}

	string getNomZonePedo{
		return sol.nom;
	}

	bool isPpaDispo{			
		if(executerModeleHydrographique and isPrelevementEtRejetSimules){
			if(ppaCourant != nil and !isEnRestrictionJourCourant()){										
				return true;		
			}else{
				return false;
			}				
		}else{
			return true;
		}			
	}		
	
	bool isEnRestriction{			
		if(ppaCourant != nil){
			return ppaCourant.isEnRestriction();		
		}else{
			return false;
		}			
	}
	// Est en restriction si le ppa dans lequel il pioche lest, sinon non		
	bool isEnRestrictionJourCourant{			
		if(ppaCourant != nil){
			return ppaCourant.isEnRestrictionJourCourant(materielIlot);		
		}else{
			return false;
		}			
	}
	int getNbJoursRestriction{
		if(ppaCourant != nil){
			return ppaCourant.getNbJoursRestriction(materielIlot);		
		}else{
			return 0;
		}			
	}	
	// Correspond a celle du point de prelevement en ASA ou SURF (si existe), peut etre nul si equ uniquement non restreints
	zoneAdministrative getZAassociee{
		equipementDeCaptageIRR equ <- getPpaPrioritaire(listeEquipementsCaptagesAssocies.keys);
		if(equ != nil){
			return equ.getZaAssociee();	
		}
		return nil;
	}	

	equipementDeCaptageIRR getPpaPrioritaire(list<equipementDeCaptageIRR> equs){	
	 	float max <- 0.0;
	 	equipementDeCaptageIRR res <- nil;
	 	ask listeEquipementsCaptagesAssocies.keys{
	 		if(self in equs){
		 		if(max < (myself.listeEquipementsCaptagesAssocies at self)){
		 			max <- myself.listeEquipementsCaptagesAssocies at self;
		 			res <- self; 
		 		}		 			
	 		}
	 	}		
	 	 	
		return res;	
	}
	equipementDeCaptageIRR getPpaASolliciterJourCourant{
		// Je parcours la lite des ppa, et regardes ceux qui ont de l'eau dispo si restriction
		list<equipementDeCaptageIRR> equsNonRestreintsEtAvecQuota <- [];
		list<equipementDeCaptageIRR> equsRestreintsMaisAvecQuota <- [];
		ask listeEquipementsCaptagesAssocies.keys{				
			if(isDisponibleJourCourant(myself.materielIlot)){
				if(!executerModeleNormatif){
					equsNonRestreintsEtAvecQuota << self;
				}else if(self.getQuota(dateCour.nbJoursEcoulesDansAnnee) > zeroApproche){ // et s'il reste du quota sur le PPA
					equsNonRestreintsEtAvecQuota << self;
				}
			}else if(isRessourceDisponible()){
				if(!executerModeleNormatif){
					equsRestreintsMaisAvecQuota << self;
				}else if(self.getQuota(dateCour.nbJoursEcoulesDansAnnee) > zeroApproche){ // et s'il reste du quota sur le PPA
					equsRestreintsMaisAvecQuota << self;
				}
			}
		}			
		if(length(equsNonRestreintsEtAvecQuota) > 0){
			return getPpaPrioritaire(equsNonRestreintsEtAvecQuota);	
		}else{
			return getPpaPrioritaire(equsRestreintsMaisAvecQuota);	 // Pour que l'on ait quand meme un ppa pour les cultures derogatoires
		}		
	}
			
	/*
	 * *****************************************************************************************
	 * [Appele dans la strategieIrrComplexe] Lors de l'irrigation on preleve une certaine quantite d'eau qu'on va retrancher a la quantite d'eau dans la ZH
	 */
	action prelevementEau(parcelle parcelleEntree, float quantiteEauPreleveePourIrrigation){
		// Le prelevement de leau se fait depuis un pt de prelevement (nappe ou eau de surface ou RET), pas plusieurs en une journee
		if(ppaCourant!=nil){
			ask ppaCourant{
				do miseAJourVolumeSouhaite(quantiteEauPreleveePourIrrigation*(1+EFFICIENCE_PPA_PARCELLE));
	
				// Un point de PR ne va irriguer que une fois par jour une Parcelle, sauf si elle appartient a plusieurs groupe dirrigation		
				float volumeAprelever <- quantiteEauPreleveePourIrrigation *(1+EFFICIENCE_PPA_PARCELLE) + (mapVolumeSouhaiteParParcelle at parcelleEntree);
				put volumeAprelever at: parcelleEntree in: mapVolumeSouhaiteParParcelle; 
				write "\tvolume A prelever: " + quantiteEauPreleveePourIrrigation *(1+EFFICIENCE_PPA_PARCELLE) + "\tEFFICIENCE_PPA_PARCELLE= " + EFFICIENCE_PPA_PARCELLE; // JV debug
			}					
		}
		//else{warn "ilot.prelevementEau attention ppaCourant nil";}			
	}
	
					
	/*
	 * *****************************************************************************************
	 * Apres la croissance des plantes il y a un potentiel ruissellement de surface (et ecoulement souterrain pour AQYIELD)
	 */
	action ruissellementVersZH {
		float sommeEauSurfaceSortieCultures <- 0.0; // [m3]
		float sommeEauSouterraineSortieCultures <- 0.0; // [m3]
		float sommeEvapotranspiration <- 0.0; // [m3]
											
		ask listeParcelles{
			// Mise a jour eau entree parcelle
			do calculEauEntreeReelleSurParcelle();					
			// On recupere l'eau de ruissellement de surface (ou de sortie) de la culture si il y en a
			sommeEauSurfaceSortieCultures <- sommeEauSurfaceSortieCultures + float(calculQuantiteEauDeRuissellement() / nombreMillimetreDansUnMetre) * (surface);	//[m3]
			// On calcule la somme d'eau perdu par evapotranspiration
			sommeEvapotranspiration <- sommeEvapotranspiration + float(calculEvapoTranspiration() / nombreMillimetreDansUnMetre) * (surface);		//[m3]
			// On recupere l'ecoulement souterrain (ou de sortie) de la culture si il y en a		
			sommeEauSouterraineSortieCultures <- sommeEauSouterraineSortieCultures + float(calculEcoulementEauSouterraine() / nombreMillimetreDansUnMetre) * (surface);		//[m3]
			
			do maj_journ_NC; // Voir déclaration dans parcelle.gaml 
			
			// Calcul utile pour le rendement a la fin de la annee					
			do majPourCalculRendement();
		}
		
		// Partie Azote
		if(nomChoixModeleCroissancePlante = 'AqYieldNC'){ // Renaud : temporaire
			// Fertilisation
//			if(dateCourante(first(dateCourante)).jour = 1 and dateCourante(first(dateCourante)).mois = 3){ // Déplacer dans l'ITK
//				ask parcelleAqYieldNC {
//					do fertilisationN;
//				}
//			}

			
			// Initilisation pour comparaison AqYield excel
			if(dateCourante(first(dateCourante)).jour = 31 and dateCourante(first(dateCourante)).mois = 12){ // Déplacer dans l'ITK
//				ask parcelleAqYieldNC {
//					QNfinaleJ_w <- 20.0;
//					QNfinaleJ_r <- 0.0;
//					QNfinaleJ_p <- 40.0;
//					QNsol_tot <- QNfinaleJ_w + QNfinaleJ_r + QNfinaleJ_p;
//				}
			}
		}
				
		drainIlot <- sommeEauSouterraineSortieCultures ;	
		ruissellementIlot <- 	sommeEauSurfaceSortieCultures;	
		ETRIlot <- sommeEvapotranspiration;
		// Si pas swat, on donne leau ruissellee et souterraine directement a la ZH
		if(hruRPGassociee = nil){
			if(zoneHydroAssociee != nil){
				ask zoneHydroAssociee{
					volumeRuissellementDeSurfaceRPG <- volumeRuissellementDeSurfaceRPG + sommeEauSurfaceSortieCultures;
					volumeEvapotranspirationRPG <- volumeEvapotranspirationRPG + sommeEvapotranspiration;
					volumeEcoulementEauSouterraineRPG <- volumeEcoulementEauSouterraineRPG + sommeEauSouterraineSortieCultures; // [m3]						
				}					
			}	
		// Sinon, leau ruissellee va dans la HRU associee			
		}else{
			ask hruRPGassociee{
				ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU + sommeEauSurfaceSortieCultures; // on somme des volumes dans un premier temps, mais ensuite ruissellementDeSurfaceHRU est exprime en hauteur
				evapoTranspirationReelle <- evapoTranspirationReelle + sommeEvapotranspiration;
				
				float eauDernierCouche <- getPercolationDerniereCouche();					
				do setPercolationDerniereCouche(eauDernierCouche + sommeEauSouterraineSortieCultures); // [m3]
			}				
		}
		
		// JV 110221 MAJ drainIlotCumulMois et drainIlotCumulQuinzaine 
		// test sut annee car remis à 0 le dernier jour du mois dans resultatsDrainIlotMensuel.miseAzero
		// si simulation commence en 2005 -> ne sera remis à zéro que le 31/01/06 donc on ne commence à cumuler qu'à partir du 01/01/06 sinon au 31/01/06 on aura tout le cumul de 2005 + janvier 2006
		// à gérer de façon plus élégante...
		if(dateCour.annee > anneeDebutSimulation){
			if(DrainIlot_mois or DrainIlotDetail_mois){
				drainIlotCumulMois <- drainIlotCumulMois + drainIlot;
				ruissellementIlotCumulMois <- ruissellementIlotCumulMois + ruissellementIlot;
				ETRIlotCumulMois <- ETRIlotCumulMois + ETRIlot;			
			} 
			if(DrainIlot_quinzaine or DrainIlotDetail_quinzaine){
				drainIlotCumulQuinzaine <- drainIlotCumulQuinzaine + drainIlot; 
				ruissellementIlotCumulQuinzaine <- ruissellementIlotCumulQuinzaine + ruissellementIlot;
				ETRIlotCumulQuinzaine <- ETRIlotCumulQuinzaine + ETRIlot;			
			}
		}
	}

	/*		
	 * *****************************************************************************************
	 */	
	rgb getCouleurIlot{
		return rgb([255,153,51]);
	}
	rgb getCouleurIsIrrigable{
		if(!isIrrigable){
			return couleurVertClaire;
		}else{
			return couleurBleuClaire;
		}			
	}														
	/*
	 * *****************************************************************************************
	 * Display
	 */					
	aspect basic{
		draw shape color: getCouleurIlot() wireframe: false border: getCouleurIlot();
	}
	aspect basic2{
		draw shape color: couleurGrisClaire wireframe: false border: couleurGrisClaire;
	}
	aspect videoAspect{
		if(dateCour.jour != 1 and dateCour.mois != 1){
			draw shape color: parcellePrincipale.getCouleurCulture() wireframe: false border: parcellePrincipale.getCouleurCulture();
		}    		
	}
	aspect cultureAspect{
		if(parcellePrincipale != nil){		
			if(parcellePrincipale.cultureParcelle != nil){			
				if(parcellePrincipale.name = nomParcelleAffichee and parcellePrincipale.getITKAnnee() != nil and executerUneSeuleParcelle){
					draw shape color: rgb('red') wireframe: false border: rgb('red');
					draw parcellePrincipale.getMessageAffiche() at: location color: rgb('black') size: tailleTexte;
				}else{
					draw shape color: parcellePrincipale.getCouleurCulture() wireframe: false border: parcellePrincipale.getCouleurCulture();
				}
			}     			
		}
	
	}
	aspect exlpoitationAspect{
		draw shape color: couleurIlotParExploitation wireframe: false border: couleurIlotParExploitation;
	}
	aspect coefficientCulturalCulturePrincpaleAspect{
		if (parcellePrincipale != nil){
    		if (parcellePrincipale.cultureParcelle != nil){
    			draw shape color: parcellePrincipale.getCouleurCoefCultural() wireframe: false border: parcellePrincipale.getCouleurCoefCultural();
    		}
		}
	}
 	aspect rfuParcelleAspect{
		draw shape color: parcellePrincipale.getCouleurRFU() wireframe: false border: parcellePrincipale.getCouleurRFU();
	}
	aspect ilotIrrigableAspect{
		draw shape color: getCouleurIsIrrigable() wireframe: false border: getCouleurIsIrrigable();
	}
	aspect ilotIrrigueAspect{
		draw shape color: parcellePrincipale.getCouleurIsIrriguee() wireframe: false border: parcellePrincipale.getCouleurIsIrriguee();
	}
  	aspect parcellePrincipaleEnRestricton{
  		if(parcellePrincipale != nil){
     		if(parcellePrincipale.isAffichage()){
    			draw shape color: parcellePrincipale.getCouleurEsEnRestriction() wireframe: false border: parcellePrincipale.getCouleurEsEnRestriction();
    		}     			
  		}
	}  
 	aspect parcellePrincipaleEnFonctionDuNiveauDeRestriction{
 		if(parcellePrincipale != nil){
    		if(parcellePrincipale.isAffichage()){
    			draw shape color: parcellePrincipale.getCouleurNiveauRestriction() wireframe: false border: parcellePrincipale.getCouleurNiveauRestriction();
			}
		}
	}   	
 	aspect etatIrrigationParcelle{
 		if(parcellePrincipale != nil){
     		if(parcellePrincipale.isAffichage()){
    			draw shape color: parcellePrincipale.getCouleurEtatIrrigation() wireframe: false border: parcellePrincipale.getCouleurEtatIrrigation();   		
    		}	    			
 		}
	} 
	aspect ilotEnStressHydrique{
		if(parcellePrincipale != nil){
    		if(parcellePrincipale.isAffichage()){
    			draw shape color: parcellePrincipale.getCouleurEsEnStressHydrique() wireframe: false border: parcellePrincipale.getCouleurEsEnStressHydrique();
    		}    			
		}
	}      			
	
	/*
	 * *****************************************************************************************
	 * Debug
	 */	
	string toString{		
		return '' + id + ' / ' + zoneHydroAssociee + ' / ' + sol + ' / ' + penteAssociee;		
		}	
}
