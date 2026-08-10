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
 *  groupeIrrigation
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model groupeIrrigation

import "Cultures/groupeIrrigationCulture.gaml"

global{
	string imageGroupeIrr <- cheminRacineMaelia + 'images/Goutte_deau.png' ;
	string imageGroupeIrrRestriction <- cheminRacineMaelia + 'images/Goutte_deau_restriction.png' ;
	string imageGroupeIrrRestrictionTotale <- cheminRacineMaelia + 'images/Goutte_deau_restrictionTotale.png' ;
	string imageGroupeIrrRestrictionTotaleMaisIrr <- cheminRacineMaelia + 'images/Goutte_deau_restrictionTotale_Irr.png' ;
	
	
	/*
		 *  *****************************************************************************************
		 * divise les deux groupes pour leur donner une taille equivalente
		 * groupeIrrigation grpComplet, groupeIrrigation grpNonComplet
		 */
		 action reequilibreGroupeIrrigation(groupeIrrigation grpComplet, groupeIrrigation grpNonComplet){
		 	// Si le dernier bloc etant deja presque complet alors on ne fait rien
		 	if(grpNonComplet.surfaceTotale / grpNonComplet.surfaceMax < 0.80){
		 		//Si le groupe peut etre couvert en 1 jour alors on l assemble avec le precedent 
		 		if(grpNonComplet.surfaceTotale / grpNonComplet.materielAssocie.surfaceIrrigableParJour < 1){ 
		 			loop parc over: grpNonComplet.parcellesIrrigable.keys{
		 				put (grpNonComplet.parcellesIrrigable at parc) at: parc in: grpComplet.parcellesIrrigable ;
		 				ask parc.listeGroupeIrrigationCulture where (each.indiceGroupe= grpNonComplet.id){
		 					indiceGroupe <- grpComplet.id;
		 				}
		 			}
		 			grpComplet.surfaceTotale <- grpComplet.surfaceTotale + grpNonComplet.surfaceTotale ;
		 			grpComplet.surfaceMax<- max([grpComplet.surfaceMax,grpComplet.surfaceTotale]);
		 			grpComplet.agriculteurAssocie.listeGroupesIrrigation >> grpNonComplet;
		 			ask grpNonComplet{
		 				do die();
		 			}
		 			
		 		}else{ // on divise les groupe
		 			float surfObjectif <- (grpComplet.surfaceTotale + grpNonComplet.surfaceTotale)/2 ;
		 			bool fin <- false;
		 			loop while:(!fin){
		 				//On cherche la parcelle la plus proche de la derniere parcelle du bloc
		 				parcelle premiereParcelleDuBloc <- first(grpNonComplet.parcellesIrrigable.keys);
//		 				parcelle parcelleADeplacer <- (grpComplet.parcellesIrrigable.keys closest_to premiereParcelleDuBloc.location);
		 				parcelle parcelleADeplacer <- (grpComplet.parcellesIrrigable.keys with_min_of(each.location distance_to( premiereParcelleDuBloc.location)));
		 				groupeIrrigationCulture grpCult <- 
		 						first( parcelleADeplacer.listeGroupeIrrigationCulture  where (each.indiceGroupe= grpComplet.id));
		 				if(grpCult.surface > 0.8 *grpComplet.surfaceTotale){ // si la parcelle represente plus de 80% de la taile du bloc, on ne la bouge pas
		 					fin <- true;
		 				}else{
		 					float nouvelleSurface <- (grpNonComplet.parcellesIrrigable at parcelleADeplacer) + grpCult.surface;
		 					put nouvelleSurface at: parcelleADeplacer in: grpNonComplet.parcellesIrrigable ;
		 					nouvelleSurface <- (grpComplet.parcellesIrrigable at parcelleADeplacer) - grpCult.surface;
		 					put nouvelleSurface at: parcelleADeplacer in: grpComplet.parcellesIrrigable ;
		 					
		 					if(nouvelleSurface <= 1.0){//m2
			 					map<parcelle, float> mapTmp <- copy(grpComplet.parcellesIrrigable);
			 					grpComplet.parcellesIrrigable <- map<parcelle,float>([]);
			 					loop parc over: mapTmp.keys{
			 						if((mapTmp at parc) > 1.0){
			 							put (mapTmp at parc) at: parc in: grpComplet.parcellesIrrigable;
			 						}
			 					}
		 					}
		 					grpCult.indiceGroupe <- grpNonComplet.id;
		 					grpComplet.surfaceTotale <- grpComplet.surfaceTotale - grpCult.surface;
		 					grpNonComplet.surfaceTotale <- grpNonComplet.surfaceTotale + grpCult.surface;
		 					if(grpNonComplet.surfaceTotale  > surfObjectif){ //Gestion du cas ou lajout du bloc fait franchir le seuil d egalite
			 					fin <- true;
			 				}
		 				}
	 				}
		 			
		 		}
		 	}
		 }
	
}

species groupeIrrigation{
	bool isIrrigation <- false;
	itk itkAssocie <- nil;
	string aspectGroupe <- imageGroupeIrr;
	int id <- 0;
	agriculteur agriculteurAssocie <- nil; 
	zoneAdministrative zaAssociee <- nil; 
	materielIrrigation materielAssocie <- nil; // materiel d'irrigation associe a ce groupe
	map<parcelle,float> parcellesIrrigable <- map<parcelle,float>([]); // parcelles appartenant au groupe, doivent toutes etre irriguees dans le tour deau (en entier ou leur fraction associee a ce groupe)
	float surfaceTotale <- 0.0; // Surface du groupe a irriguer pendant un tour deau (forcement <= surfaceMax)
	float surfaceMax <- 0.0;  // surfaceMaxTraiteeParUnGroupe, la meme pour tous les groupes de meme culture (sauf si ajout residuel de derniere parcelle)
	float surfaceJournaliereTotale <- 0.0; // sufaceAirriguerParJour (change selon restriction)
	parcelle derniereParcelleIrriguee <- nil;  // derniere parcelle au jour courant
   

	/* JV 300321 ancienne version avant 1.3.12
	 *  *****************************************************************************************
	 * 	Public
	 * ATTENTION : si prbleme surfaceTotale < 0.0 ??? [GROUPE_IRR/irrigation] PB surfaceJournaliereTotale NULLE !!!! -8038.019780212189 - surfaceRestanteDerniereParcelle = 87108.23773129006
	 * Cest car je passe 2 fois dans la meme parcelle au niveau de lagriculteur
	 */	
   		list<parcelle> creationGroupe(list<parcelle> parcellesEntree, 
   			zoneAdministrative zaEntree,
   			 agriculteur agriEntree,
   			 int indiceDernierGroupeEntree,
   			 materielIrrigation materielEntree,
   			 itk itkGroupe
   		){
	   		if verboseMode {
				write "\t\tappel creationGroupe";
				write "\t\t\tparcellesEntree " + parcellesEntree collect each.idParcelle;
				write "\t\t\tmaterielEntree " + materielEntree.idMateriel;
			}	
  
 			id <- indiceDernierGroupeEntree;  
 			zaAssociee <- zaEntree;
 			agriculteurAssocie <- agriEntree;
 			itkAssocie <- itkGroupe;
 			materielAssocie <- materielEntree; 
			surfaceMax <- itkAssocie.strategieIrrigationITK.periodeTourEau * materielAssocie.surfaceIrrigableParJour;  // surfaceMaxTraiteeParUnGroupe, la meme pour tous les groupes de meme culture
 
			list<parcelle> listeParcellesNonTraitees <- parcellesEntree;
			// il ny en a quune normalement ! (la derniere traitee dans le groupe id-1 de lagri)												
		parcelle parcelleEnCours <- first(parcellesEntree where (!empty(each.listeGroupeIrrigationCulture)));	
		float surfaceRestanteDerniereParcelle <- 0.0;
		if(parcelleEnCours = nil){
			parcelleEnCours <- first(parcellesEntree);
			surfaceRestanteDerniereParcelle <- parcelleEnCours.surface;
		}else{
			surfaceRestanteDerniereParcelle <- parcelleEnCours.surface - parcelleEnCours.getSurfaceTotaleGroupesIrr();				
//				if(surfaceRestanteDerniereParcelle < 0.0){
//					write "[GROUPE/creationGroupe] PB !!!!!!!!!!!! parcelleEnCours = " + parcelleEnCours + " - surfaceRestanteDerniereParcelle = " + surfaceRestanteDerniereParcelle + " - parcelleEnCours.surface = " + parcelleEnCours.surface + " - parcelleEnCours.listeGroupeIrrigationCulture = " + parcelleEnCours.listeGroupeIrrigationCulture + " - SURF GROUPE = " + parcelleEnCours.getSurfaceTotaleGroupesIrr();
//				}
		}						
		float surfaceEntreeTotale <- 0.0;
		ask parcellesEntree{
			surfaceEntreeTotale <- surfaceEntreeTotale + surface;								
		}											
		float surfaceRestante <- min([surfaceMax, surfaceEntreeTotale]);				

		groupeIrrigationCulture grCultCree <- nil;
		bool arret <- false;
		loop while: (!arret) {
			// On change de parcelle car il reste de la surface dans le groupe 
			if(surfaceRestante >= surfaceRestanteDerniereParcelle){																		
				surfaceRestante <- surfaceRestante - surfaceRestanteDerniereParcelle;
				surfaceTotale <- surfaceTotale + surfaceRestanteDerniereParcelle;							
				listeParcellesNonTraitees <- listeParcellesNonTraitees - parcelleEnCours;

				put surfaceRestanteDerniereParcelle at: parcelleEnCours in: parcellesIrrigable;
				groupeIrrigation groupeTemp <- self;
				grCultCree <- world.creationGroupeIrrigationCulture(indiceDernierGroupeEntree, surfaceRestanteDerniereParcelle, parcelleEnCours, groupeTemp);

				// Je choisi une autre parcelle
				if(!empty(listeParcellesNonTraitees)){
					parcelle parcelleAncien <- parcelleEnCours;						
					parcelleEnCours <- first(listeParcellesNonTraitees where (each.ilot_app = parcelleAncien.ilot_app));
					if(parcelleEnCours = nil){
						// parcelleEnCours <- (listeParcellesNonTraitees closest_to parcelleAncien.location);
						parcelleEnCours <- (listeParcellesNonTraitees with_min_of( each.location distance_to( parcelleAncien.location)));						
					}
					// Pb si que parcelles HZ ...
					if(parcelleEnCours = nil){
						parcelleEnCours <- first(listeParcellesNonTraitees);
//							write "" + agriculteurAssocie.name + " - [GROUPE/creationGroupe] PB : PARCELLE NULLE !!! parcelleEnCours = " + parcelleEnCours + " - parcelleAncien = " + parcelleAncien + " - listeParcellesNonTraitees = " + listeParcellesNonTraitees;
					}					
					surfaceRestanteDerniereParcelle <- parcelleEnCours.surface;

					// On change de groupe : Si lilot le plus proche est distant de plus de dmax alors n cree en autre groupe dirrigation (en plus du nb initial)
					if((parcelleEnCours distance_to parcelleAncien) > distanceMaxIlotsGroupeIrrigation){							
						arret <- true;
					}						
				}else{
					arret <- true;
				}						
			// on ne change pas de parcelle, mais de groupe																		
			}else{
				// Si la surface restance est tres petite, on met le reste de la surface de la parelle dans le groupe
				float surfaceReajusteeParcelle <- surfaceRestante;
				if((surfaceRestanteDerniereParcelle-surfaceRestante) < (parcelleEnCours.surface) * 0.05){
					surfaceReajusteeParcelle <- surfaceRestanteDerniereParcelle;
					listeParcellesNonTraitees <- listeParcellesNonTraitees - parcelleEnCours;
				}
				
				surfaceTotale <- surfaceTotale + surfaceReajusteeParcelle;	
				put surfaceReajusteeParcelle at: parcelleEnCours in: parcellesIrrigable;
				grCultCree <- world.creationGroupeIrrigationCulture(indiceDernierGroupeEntree, surfaceReajusteeParcelle, parcelleEnCours,groupeIrrigation(nil));
																		
				arret <- true;		
			}																																		
		}			
		// Si on a mit dans un groupe une parcelle entiere car il restait un residu, alors la surfaceMax est surevaluee, Il est par contre tout a fait ppssible que la surfaceTot soit < surfMax
		if(surfaceMax < surfaceTotale){
			surfaceMax <- surfaceTotale;				
		}			
		location <- one_of(parcellesIrrigable.keys).location;

   		if verboseMode {write "\t\t\trenvoie " + listeParcellesNonTraitees collect each.idParcelle;}							
		return listeParcellesNonTraitees;
	}

	/* JV 300321 ancienne version avant 1.3.12
	 *  *****************************************************************************************
	 * 	Public
	 * ATTENTION : si prbleme surfaceTotale < 0.0 ??? [GROUPE_IRR/irrigation] PB surfaceJournaliereTotale NULLE !!!! -8038.019780212189 - surfaceRestanteDerniereParcelle = 87108.23773129006
	 * Cest car je passe 2 fois dans la meme parcelle au niveau de lagriculteur
	 	
   		list<parcelle> creationGroupe(list<parcelle> parcellesEntree, 
   			zoneAdministrative zaEntree,
   			 agriculteur agriEntree,
   			 int indiceDernierGroupeEntree,
   			 materielIrrigation materielEntree
   		){   
			write "\t\tappel creationGroupe";
			write "\t\t\tparcellesEntree " + parcellesEntree collect each.idParcelle;
			write "\t\t\tmaterielEntree " + materielEntree.idMateriel;
			
  
 			id <- indiceDernierGroupeEntree;  
 			zaAssociee <- zaEntree;
 			agriculteurAssocie <- agriEntree;
 			itkAssocie <- first(parcellesEntree).getITKAnnee();
 			materielAssocie <- materielEntree; 
			surfaceMax <- itkAssocie.strategieIrrigationITK.periodeTourEau * materielAssocie.surfaceIrrigableParJour;  // surfaceMaxTraiteeParUnGroupe, la meme pour tous les groupes de meme culture
 
			list<parcelle> listeParcellesNonTraitees <- parcellesEntree;
			// il ny en a quune normalement ! (la derniere traitee dans le groupe id-1 de lagri)												
		parcelle parcelleEnCours <- first(parcellesEntree where (!empty(each.listeGroupeIrrigationCulture)));	
		float surfaceRestanteDerniereParcelle <- 0.0;
		if(parcelleEnCours = nil){
			parcelleEnCours <- first(parcellesEntree);
			surfaceRestanteDerniereParcelle <- parcelleEnCours.surface;
		}else{
			surfaceRestanteDerniereParcelle <- parcelleEnCours.surface - parcelleEnCours.getSurfaceTotaleGroupesIrr();				
//				if(surfaceRestanteDerniereParcelle < 0.0){
//					write "[GROUPE/creationGroupe] PB !!!!!!!!!!!! parcelleEnCours = " + parcelleEnCours + " - surfaceRestanteDerniereParcelle = " + surfaceRestanteDerniereParcelle + " - parcelleEnCours.surface = " + parcelleEnCours.surface + " - parcelleEnCours.listeGroupeIrrigationCulture = " + parcelleEnCours.listeGroupeIrrigationCulture + " - SURF GROUPE = " + parcelleEnCours.getSurfaceTotaleGroupesIrr();
//				}
		}						
		float surfaceEntreeTotale <- 0.0;
		ask parcellesEntree{
			surfaceEntreeTotale <- surfaceEntreeTotale + surface;								
		}											
		float surfaceRestante <- min([surfaceMax, surfaceEntreeTotale]);				

		groupeIrrigationCulture grCultCree <- nil;
		bool arret <- false;
		loop while: (!arret) {
			// On change de parcelle car il reste de la surface dans le groupe 
			if(surfaceRestante >= surfaceRestanteDerniereParcelle){																		
				surfaceRestante <- surfaceRestante - surfaceRestanteDerniereParcelle;
				surfaceTotale <- surfaceTotale + surfaceRestanteDerniereParcelle;							
				listeParcellesNonTraitees <- listeParcellesNonTraitees - parcelleEnCours;

				put surfaceRestanteDerniereParcelle at: parcelleEnCours in: parcellesIrrigable;
				groupeIrrigation groupeTemp <- self;
				grCultCree <- world.creationGroupeIrrigationCulture(indiceDernierGroupeEntree, surfaceRestanteDerniereParcelle, parcelleEnCours, groupeTemp);

				// Je choisi une autre parcelle
				if(!empty(listeParcellesNonTraitees)){
					parcelle parcelleAncien <- parcelleEnCours;						
					parcelleEnCours <- first(listeParcellesNonTraitees where (each.ilot_app = parcelleAncien.ilot_app));
					if(parcelleEnCours = nil){
						// parcelleEnCours <- (listeParcellesNonTraitees closest_to parcelleAncien.location);
						parcelleEnCours <- (listeParcellesNonTraitees with_min_of( each.location distance_to( parcelleAncien.location)));						
					}
					// Pb si que parcelles HZ ...
					if(parcelleEnCours = nil){
						parcelleEnCours <- first(listeParcellesNonTraitees);
//							write "" + agriculteurAssocie.name + " - [GROUPE/creationGroupe] PB : PARCELLE NULLE !!! parcelleEnCours = " + parcelleEnCours + " - parcelleAncien = " + parcelleAncien + " - listeParcellesNonTraitees = " + listeParcellesNonTraitees;
					}					
					surfaceRestanteDerniereParcelle <- parcelleEnCours.surface;

					// On change de groupe : Si lilot le plus proche est distant de plus de dmax alors n cree en autre groupe dirrigation (en plus du nb initial)
					if((parcelleEnCours distance_to parcelleAncien) > distanceMaxIlotsGroupeIrrigation){							
						arret <- true;
					}						
				}else{
					arret <- true;
				}						
			// on ne change pas de parcelle, mais de groupe																		
			}else{
				// Si la surface restance est tres petite, on met le reste de la surface de la parelle dans le groupe
				float surfaceReajusteeParcelle <- surfaceRestante;
				if((surfaceRestanteDerniereParcelle-surfaceRestante) < (parcelleEnCours.surface) * 0.05){
					surfaceReajusteeParcelle <- surfaceRestanteDerniereParcelle;
					listeParcellesNonTraitees <- listeParcellesNonTraitees - parcelleEnCours;
				}
				
				surfaceTotale <- surfaceTotale + surfaceReajusteeParcelle;	
				put surfaceReajusteeParcelle at: parcelleEnCours in: parcellesIrrigable;
				grCultCree <- world.creationGroupeIrrigationCulture(indiceDernierGroupeEntree, surfaceReajusteeParcelle, parcelleEnCours,groupeIrrigation(nil));
																		
				arret <- true;		
			}																																		
		}			
		// Si on a mit dans un groupe une parcelle entiere car il restait un residu, alors la surfaceMax est surevaluee, Il est par contre tout a fait ppssible que la surfaceTot soit < surfMax
		if(surfaceMax < surfaceTotale){
			surfaceMax <- surfaceTotale;				
		}			
		location <- one_of(parcellesIrrigable.keys).location;

		write "\t\t\trenvoie " + listeParcellesNonTraitees collect each.idParcelle;									
		return listeParcellesNonTraitees;
	}
	*/



	/*
	 *  *****************************************************************************************
	 * Public
	 */			
	action irrigation {
		arg nb_h type: float default: 0.0;
		
		surfaceJournaliereTotale <- 0.0;
		map<parcelle,float> parcellesIrrigableRestantes <- calculListeParcellesIrrigablesAujourdhui(); // {parcelle::sufaceAirriguer}	
				
		if(!empty(parcellesIrrigableRestantes.keys)){
			surfaceJournaliereTotale <- calculSurfaceJournaliere(mapParcelles:parcellesIrrigableRestantes);		
			
			if(surfaceJournaliereTotale > 0.0){
				float surfaceRestanteJournaliere <- surfaceJournaliereTotale;					
				bool arret <- false;
				
				loop while: (!arret) { 
					float temps_traitement <- 0.0;
														
					// Si il ny a pas de parcelle en cours, on en prend une au hasard
					if(derniereParcelleIrriguee = nil){
						derniereParcelleIrriguee <- first(parcellesIrrigableRestantes.keys);											
					} // JV 061020 idem si parcelle en cours a changé d'ITK entre-temps et n'est plus irrigable 				
					else if(derniereParcelleIrriguee.getITKAnnee().strategieIrrigationITK=nil){
						derniereParcelleIrriguee <- first(parcellesIrrigableRestantes.keys);											
					}					
					
					float surfaceRestanteDerniereParcelle <- parcellesIrrigableRestantes at derniereParcelleIrriguee;
					
					if(surfaceRestanteJournaliere > surfaceRestanteDerniereParcelle){
						
						//d'abord le test pour vérifier que l'on dispose du temps nécessaire en MO pour irriguer
						temps_traitement <- surfaceRestanteDerniereParcelle / surfaceJournaliereTotale * materielAssocie.tempsDeTravailParJour; 
						if ((nb_h = 0) or ((temps_traitement + nb_h) < agriculteurAssocie.nb_heures_travails_max)){ // si premiere action de la journee (nb_h ==0) ou si realisable dans la journee
							surfaceRestanteJournaliere <- surfaceRestanteJournaliere - surfaceRestanteDerniereParcelle;

							// IRRIGATION PARCELLE : donner en entree le groupe et la surface qui est effectivement irriguee
							ask ((derniereParcelleIrriguee.getITKAnnee()).strategieIrrigationITK){
								do miseEnOeuvreActivite(myself.derniereParcelleIrriguee, myself.agriculteurAssocie, myself.id, surfaceRestanteDerniereParcelle);
							}
							remove key: derniereParcelleIrriguee from: parcellesIrrigableRestantes;
							
							// Si il reste des parcelles a irriguer et que lagri peut encore travailler
							if(!empty(parcellesIrrigableRestantes.keys)){
								parcelle parcelleAncien <- derniereParcelleIrriguee;						
								derniereParcelleIrriguee <- first(parcellesIrrigableRestantes.keys where (each.ilot_app = parcelleAncien.ilot_app));
								// si changement ilot // ca prend une heure de changer dilot
								if(derniereParcelleIrriguee = nil){
//									derniereParcelleIrriguee <- (parcellesIrrigableRestantes.keys closest_to parcelleAncien.location);
									derniereParcelleIrriguee <- (parcellesIrrigableRestantes.keys with_min_of(each.location distance_to( parcelleAncien.location)));
									// Pb si que parcelles HZ ...
									if(derniereParcelleIrriguee = nil){
										derniereParcelleIrriguee <- first(parcellesIrrigableRestantes.keys);
//										write "" + agriculteurAssocie.name + " - [GROUPE_IRR/irrigation 1] PB derniereParcelleIrriguee NULLE !!!! " + derniereParcelleIrriguee + " - LISTE " + parcellesIrrigableRestantes.keys;
									}								
								}
								surfaceRestanteDerniereParcelle <- derniereParcelleIrriguee.surface;
																																		
							// Dans le cas ou l'griculteur a encore la possibilite dirriguer des surfaces (surfaceRestanteAirriguerGroupe > 0) mais il n'a plus  de parcelle pouvant etre irriguee										
							}else{
								derniereParcelleIrriguee <- nil;
								arret <- true;
							}						
								
						}else{ // On fera cette irrigation le lendemain
							temps_traitement <- 0.0;
							arret <- true;
						}
										
					// PAS CHANGEMENT PARCELLE, CHANGEMENT GROUPE : la derniere parcelle traite ne change pas // ca prend une heure de changer dilot
					}else{					
						temps_traitement <-  surfaceRestanteJournaliere / surfaceJournaliereTotale * materielAssocie.tempsDeTravailParJour;  // l'irrigation de surfaceJournaliereTotale prendrait 1 heure
						if ((nb_h = 0) or ((temps_traitement + nb_h) < agriculteurAssocie.nb_heures_travails_max)){ // si premiere action de la journee (nb_h ==0) ou si realisable dans la journee
							ask ((derniereParcelleIrriguee.getITKAnnee()).strategieIrrigationITK){
								do miseEnOeuvreActivite(myself.derniereParcelleIrriguee, myself.agriculteurAssocie, myself.id, surfaceRestanteJournaliere);
							}
						}else{
							temps_traitement <- 0.0;
						}
						arret <- true;
					}
					
					// A chaque irrigation ca prend 1 heure. l'irrigation de tout surfaceJournaliereTotale prend 1 h
					nb_h <- nb_h + temps_traitement;					
					if nb_h > agriculteurAssocie.nb_heures_travails_min{  // (nb_h > nb_heures_travails_max) ???
						arret <- true;
					}	
				}					
			}				
		}
		if(derniereParcelleIrriguee != nil){
			location <- derniereParcelleIrriguee.location;
		}		
		return nb_h;
	}

	/*
	 *  *****************************************************************************************
	 * Private
	 */	
	map<parcelle,float> calculListeParcellesIrrigablesAujourdhui{
		map<parcelle,float> parcellesIrrigableRestantes <- map<parcelle,float>([]); // {parcelle::sufaceAirriguer}
		loop parcelleCourante over: parcellesIrrigable.keys {		
			if((parcelleCourante.getITKAnnee()) != nil){
				if(parcelleCourante.getITKAnnee().strategieIrrigationITK != nil){
					ask ((parcelleCourante.getITKAnnee()).strategieIrrigationITK){	
						if(isActivitePossible(parcelleCourante, myself.id, parcelleCourante.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite)){
							float surfaceResultat <- parcelleCourante.getSurfacePouvantEtreIrriguee(myself.id);//float(getSurfaceIrrigueePossible(indiceGroupe:myself.id, parcelleIrrEntree:parcelleCourante));					
							if(surfaceResultat > 0.0){
								put surfaceResultat at: parcelleCourante in: parcellesIrrigableRestantes;
							}								
						}
					}					
				}
			}									
		}
		return parcellesIrrigableRestantes;
	}

	/*
	 *  *****************************************************************************************
	 * Private
	 * Calcul la surface totale au jour courant des parcelles en restriction (c'est a dire nayant pas au moins 1 equipement non restreint)
	 */	
	float calculSurfaceEnRestriction{
		float res <- 0.0;	
		// comme on a cree les groupes d'irrigation par nature de ressource prioritaire. Le cas za = nil mais à l'instant t l'ilot peut
		// utiliser un ppa lie a une za, ce qui posserait un probleme dans la fonction calculSurfaceJournaliere
		if(zaAssociee != nil){ 
			if(zaAssociee.getNbJoursRestriction() > 0.0){
				ask(parcellesIrrigable.keys){
					if(ilot_app.isEnRestriction()){ // si le ppa est nul, on ne considere pas la parcelle comme etant en restriction
						res <- res + (myself.parcellesIrrigable at self);
					}					
				}
			}
		}	
		return res;
	}

	/*
	 *  *****************************************************************************************
	 * Private
	 */			
	float calculSurfaceJournaliere(map<parcelle,float> mapParcelles) {
		float surfaceIrrParJourMax <- 0.0;
		float surfaceEnRestriction <- calculSurfaceEnRestriction();
		if(surfaceEnRestriction > 0.0){  // Cas particulier des ppa  soumis a restriction
				
			// Le tour deau nest pas forcement une semaine, donc il faut ramener le nb de jours de restriction de 7 jours au nb de jour de tour deau
			float nbJourRestrictionRamenesAuTourEau <- ((itkAssocie.strategieIrrigationITK.periodeTourEau * zaAssociee.getNbJoursRestriction()) / zaAssociee.getBaseDeDefinitionJoursDeRestriction());			

			float deuxJourRestrictionRamenesAuTourEau <- ((itkAssocie.strategieIrrigationITK.periodeTourEau * 2) / nbJoursDansUneSemaine);
			float nbJourNonRestreints <- itkAssocie.strategieIrrigationITK.periodeTourEau - nbJourRestrictionRamenesAuTourEau;
			
			// Si la surface en restriction est inferieure a la surface max sous restriction, cela signifie que lirrigation peut se faire normalement car toutes les parcelles irriguees resteinte peuvent letre car les parcelles non restreintes le seront pendant la restriction
			if(surfaceEnRestriction/surfaceMax <= nbJourNonRestreints/ zaAssociee.getNbJoursRestriction()){
				surfaceIrrParJourMax <- surfaceMax / itkAssocie.strategieIrrigationITK.periodeTourEau;
			}else{			
				// 7 jours de restrictions (restriction totale)
				if((nbJourRestrictionRamenesAuTourEau = itkAssocie.strategieIrrigationITK.periodeTourEau) or (!accelerationTourEauSiRestriction)){
					// Aucune des parcelles en restristion ne pourront etre irriguees, alors on irrigue normalement les autres pouvant letre (liees a un equ non contraint)
					// sans contrainte de surface max par jour (autre que celle imposee par le groupe dirrigation)
					surfaceIrrParJourMax <- surfaceMax / itkAssocie.strategieIrrigationITK.periodeTourEau; 
				} // 2 jours (on accelere)
				else if(nbJourRestrictionRamenesAuTourEau <= deuxJourRestrictionRamenesAuTourEau){					
					surfaceIrrParJourMax <- surfaceMax /  (itkAssocie.strategieIrrigationITK.periodeTourEau - nbJourRestrictionRamenesAuTourEau); // SurfaceSemaineMax / NbJoursNonRestreints
				// 3 ou 4 jours de restrictions (on accelere)
				}else{
					surfaceIrrParJourMax <- surfaceMax /  (itkAssocie.strategieIrrigationITK.periodeTourEau - deuxJourRestrictionRamenesAuTourEau);
				}
				
			}
			
		}
		else{
			surfaceIrrParJourMax <- surfaceMax / itkAssocie.strategieIrrigationITK.periodeTourEau;
		}
				
		return surfaceIrrParJourMax;
	}
	
	action colorationGroupe{    		
		isIrrigation <- true;
		if(derniereParcelleIrriguee = nil){
			isIrrigation <- false;
		}else{
			ask derniereParcelleIrriguee{
				if(etatIrrigationParcelle = ETAT_PAS_IRRIGATION_DEMANDEE){
					myself.isIrrigation <-  false;
				}else if(etatIrrigationParcelle = ETAT_IRRIGATION_CONTRE_RESTRICTION){
					myself.aspectGroupe <-  imageGroupeIrrRestrictionTotale; // imageGroupeIrrRestrictionTotale   imageGroupeIrrRestrictionTotaleMaisIrr
				}else if(etatIrrigationParcelle = ETAT_PAS_ASSEZ_DEAU){
					myself.aspectGroupe <-  imageGroupeIrrRestriction;
				}else if(etatIrrigationParcelle = ETAT_RESTRICTION){
					myself.aspectGroupe <-  imageGroupeIrrRestrictionTotale;					
				}else{
					myself.aspectGroupe <-  imageGroupeIrr;
				}
			}				
		}
	}
	
	string toString{
		return "" + id + " / agri = " + agriculteurAssocie + " / itk = " + itkAssocie + " / espece = " + itkAssocie.especeCultiveeITK + " / ZA = " + zaAssociee + " / Derniere Parcelle = " + derniereParcelleIrriguee + " / Parcelles = " + parcellesIrrigable + " / Surf tot = " + surfaceTotale + " / Surf j = " + surfaceJournaliereTotale + " / Surf Max = " + surfaceMax + "\n";
	}
	aspect imageAspect{
		if(isIrrigation){	
			draw image_file(aspectGroupe) size: 1500;		// taillePoints		
		}
	}
}
