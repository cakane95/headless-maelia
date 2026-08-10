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
 *  secteurAdministratif
 *  Author: Maroussia Vavasseur
 *  Description: 	Une Zone Administrative peut etre divisee en 2 ou plusiques secteurs. Un secteur est aussi une agreation de communes
 * 					On applique alternativement les jours de restriction sur les differents secteurs la ZA.
 */

model secteurAdministratif 

import "../modeleHydrographique/canaux.gaml"

global{
	string restrictionCanaux <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/canaux/RestrictionsDebitCanaux.csv'; 

	string cheminSecteurAdministratif <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/zonesAdministratives/';
 	string nomFichierSecteurAdministratif <- 'secteursAdministratifs.shp';
	
	string cheminJoursRestriction <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/zonesAdministratives/';
 	string nomFichierJoursRestriction <- 'joursRestrictionSecteurs.csv';

	string cheminRestrictionCanaux <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/canaux/';
 	string nomFichierRestrictionCanaux <- 'RestrictionsDebitCanaux.csv';

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionSecteursAdministratif{
				
		if !file_exists(cheminSecteurAdministratif + nomFichierSecteurAdministratif) 	{do raiseWarning("fichier inexistant: " + cheminSecteurAdministratif + nomFichierSecteurAdministratif);}
		//else if !is_shape(cheminSecteurAdministratif + nomFichierSecteurAdministratif) 	{do raiseWarning("le fichier " + cheminSecteurAdministratif + nomFichierSecteurAdministratif + " n'est pas un fichier shape");}

		create secteurAdministratif from: file(cheminSecteurAdministratif + nomFichierSecteurAdministratif) with: [id::string(read (ID_SECTEU)),nature::string(read (NATURE))]{					
			zoneAdministrative za <- first((listZonesAdministratives) where (each.idZoneAdministrative = string(shape get(ID_ZA)))) ;
			if(za = nil){
				ask self{
					do die();
				}
			}else{
				zaAssociee <- za;
				if(nature = nil){
					nature <- SURF + "_" + CAN + "_" + NAPP;
				}
				do initialisationSecteurAdministratif();					
			}					
		}			
		do lectureJoursRestrictions();								
		do verificationAssociationPPA_Secteur();
		do affectationProprietesRestrictionCanaux();	
	}	
	
	action verificationAssociationPPA_Secteur{
		ask (equipementDeCaptageIRR as list) + (equipementDeCaptageCanaux as list) {
			if(secteurAdministratifAssocie = nil) and (self.natureRessourcePrelevee =SURF or self.natureRessourcePrelevee =CAN){
				list<secteurAdministratif> listeSecteursPotentiels <- ((secteurAdministratif as list) where (each.nature contains self.natureRessourcePrelevee));
				if(length(listeSecteursPotentiels) < 1){
					listeSecteursPotentiels <- ((secteurAdministratif as list) where (each.nature contains SURF));
				}
				secteurAdministratifAssocie <- listeSecteursPotentiels closest_to self;
				write "Probleme l'equipement "+ self + " de type " + self.natureRessourcePrelevee+ " n'a pas de secteur administratif. Il sera affecte dans "+ secteurAdministratifAssocie.id;
				ask secteurAdministratifAssocie{
					listePPAassocies << myself;
				}
			}
		}
	}
	
	action affectationProprietesRestrictionCanaux{
		if (length(listeCanaux) > 0){
			if (file_exists(cheminRestrictionCanaux + nomFichierRestrictionCanaux)) {
				
				// Si fichier non existant alors canal non sousmis a restriction
				ask((canal as list)){ // Placer le canal dans un secteur
				list<secteurAdministratif> listeSecteursPotentiels <- ((secteurAdministratif as list) where (each.nature contains CAN));
					if(length(listeSecteursPotentiels) < 1){
						listeSecteursPotentiels <- ((secteurAdministratif as list) where (each.nature contains SURF));
					}
					secteurAdministratifAssocie <- listeSecteursPotentiels closest_to self;
				}
				
				 matrix initRestrictionCanaux <- matrix(csv_file (cheminRestrictionCanaux + nomFichierRestrictionCanaux,";",false));	
			 	 //matrix initRestrictionCanaux <- matrix(file (cheminRestrictionCanaux + nomFichierRestrictionCanaux));	
				 int nbLignes <- length(initRestrictionCanaux column_at 0);	
				 	
				 loop i from: 1 to: (nbLignes - 1){
					list<string> ligneI <- (initRestrictionCanaux row_at i) as list<string>; 
					// en 0 le nom pour info du canal ; en 1 l'id du canal ; en 2 le niveau de restriction ;
					// en 3 la limitation prelevement et 4 la limitation de rejet
									
					string idCanaux <- (ligneI at 1);
					canal canalAssocie <- mapCanaux at idCanaux;
					int niveauRestriction <- int(ligneI at 2);
					list<float> listeDeslimiteDePrelevement <- (ligneI at 3) tokenize SEPARATEUR as list<float>;
					float limitationRejet <- float(ligneI at 4);
					if(length(listeDeslimiteDePrelevement)=length(canalAssocie.listEquipementAlimentantCeCanal)){
						loop j from: 0 to: (length(listeDeslimiteDePrelevement) -1){
							ask canalAssocie.listEquipementAlimentantCeCanal[j]{
								put (listeDeslimiteDePrelevement[i] * nbSecondesDansUneJournee) at:niveauRestriction  in:restrictionDebitPrelevement;
							}
						}
					}else{
						write "Probleme de definition des restrictions canaux. Le canal" + idCanaux+ " contient " + length(listeDeslimiteDePrelevement) +
							" points de prelevement d 'alimentation, mais les definitions de restriction de niveau "+ niveauRestriction+" en contiennent " +
							 length(canalAssocie.listEquipementAlimentantCeCanal);
						write "Cette restriction sera ingnoree.";
					}
					
					if(length(canalAssocie.listEquipementSortieCanal) > 0){ // si on des pp des sorties
						loop j from: 0 to: (length(canalAssocie.listEquipementSortieCanal) -1){
							ask canalAssocie.listEquipementSortieCanal[j]{
								put limitationRejet at:niveauRestriction  in:restrictionRejet;
							}
						}
					}
				}
			}else{
				write "Attention aucune gestion particuliere des canaux n a ete specifie. Aucunes restrictions (en prelevement ou rejet)" +
 						"ne sera appliquees";
				ask((canal as list)){
					ask listEquipementAlimentantCeCanal{ // on ne sousmet les pp aux restrictions
						secteurAdministratifAssocie <- nil;
					}
				}
			}
		}
		// if restrictionCanaux
	}
	
	/*
	 * *****************************************************************************************
	 * Private
	 */
	action lectureJoursRestrictions{
		if(file_exists(cheminJoursRestriction+nomFichierJoursRestriction)){
			 matrix initJoursRestrictions <- matrix(csv_file (cheminJoursRestriction+nomFichierJoursRestriction,";",false));	
			 int nbLignes <- length(initJoursRestrictions column_at 0);	
			 int nbCol <- length(initJoursRestrictions row_at 0);
			 	
			 loop i from: 1 to: (nbLignes - 1){
				list<string> ligneI <- (initJoursRestrictions row_at i) as list<string>;							
				string idSect <- (ligneI at 0);
				int niveauRestriction <- 0;
				int baseDeDefRestriction <- 7;
				string joursRestriction <- "";
				list<materielIrrigation> materielAssocieALaRestriction <- mapMateriel.values ;
				if(nbCol>4){ // si on specifie des restrictions par type de materiel d'irrigation
					if((ligneI at 1) != '*'){ // si c'est * on a pas besoin de modifier materielAssocieALaRestriction
						materielAssocieALaRestriction <- [];
						loop mat over: ((ligneI at 1) split_with '|'){
							materielAssocieALaRestriction << (mapMateriel at mat) ;
						}
					}
					niveauRestriction <- int(ligneI at 2);
					baseDeDefRestriction <- int(ligneI at 3);
					joursRestriction <- (ligneI at 4);
				}else{
					niveauRestriction <- int(ligneI at 1);
					baseDeDefRestriction <- int(ligneI at 2);
					joursRestriction <- (ligneI at 3);
				}
				secteurAdministratif secteurLu <- first((secteurAdministratif as list) where (each.id = idSect));
				
				if(secteurLu!=nil){
					ask(secteurLu){
						if(joursRestriction != nil){
							list<int> listeJours <- joursRestriction tokenize SEPARATEUR as list<int>;
							loop mat over: materielAssocieALaRestriction{
								map<int,list<int>> mapJoursDeLaSemaineARestreindre <- mapJoursDeLaSemaineARestreindreParTypeDeMateriel at mat;
								if(mapJoursDeLaSemaineARestreindre = nil){
									mapJoursDeLaSemaineARestreindre <- [];
								}
								put listeJours at: niveauRestriction in: mapJoursDeLaSemaineARestreindre;
								put mapJoursDeLaSemaineARestreindre at: mat in: mapJoursDeLaSemaineARestreindreParTypeDeMateriel;
							}
						}	
						put baseDeDefRestriction at: niveauRestriction in: zaAssociee.mapBaseDefinitionPeriodeDeRestriction;					
					}
				}	
			}
			
			//controle de coherence : chaque secteur a t il des restrictions defini pour tous les types de materiel pour tous les niveaux
			ask secteurAdministratif{
				loop mat over: mapMateriel.values{
					map<int,list<int>> mapJoursDeLaSemaineARestreindre <- mapJoursDeLaSemaineARestreindreParTypeDeMateriel at mat;
					if(mapJoursDeLaSemaineARestreindre = nil){
						write 'Probleme dans la definitin des restrictions : le secteur ' + self.id + " n'a pas restrcition defini pour " + mat.idMateriel;
						put  [1::[1], 2::[1,3], 3::[1,3,5], 4::[1,2,3,4,5,6,7]] at: mat in: mapJoursDeLaSemaineARestreindreParTypeDeMateriel;
					}else{
						loop i from: 1 to:4 {
							if((mapJoursDeLaSemaineARestreindre at i) = nil){
								write 'Probleme dans la definitin des restrictions : le secteur ' + self.id +
									 " n'a pas restrcition defini pour " + mat.idMateriel + ' pour le niveau '+ i;
								put [1,2,3,4,5,6,7] at: i in: mapJoursDeLaSemaineARestreindre;
							}
						}
						put  mapJoursDeLaSemaineARestreindre at: mat in: mapJoursDeLaSemaineARestreindreParTypeDeMateriel;
					}
				}
			}
			// affectation Nombre de jours moyen de restrictions par  niveau de restrictions par ZA
			if(executerModeleAgricole){ // Ne sert que si le modele agricole est active et necessite le materiel d'irrigation
				ask listZonesAdministratives{
					self.mapNiveauDeRestriction <- [] ;
					loop niveau over:mapBaseDefinitionPeriodeDeRestriction.keys{
						put 0.0 at: niveau in: self.mapNiveauDeRestriction;
					}
					loop sa over: secteursAdministratifsAssocies{
						loop mat over: sa.mapJoursDeLaSemaineARestreindreParTypeDeMateriel.keys{
							map<int,list<int>> mapJoursDeLaSemaineARestreindre <- sa.mapJoursDeLaSemaineARestreindreParTypeDeMateriel at mat;
							loop i over: (mapJoursDeLaSemaineARestreindre).keys{
								put (length(mapJoursDeLaSemaineARestreindre at i) +  (self.mapNiveauDeRestriction at i))  at: i in: self.mapNiveauDeRestriction;
							}
						}
					}
					loop i over: mapNiveauDeRestriction.keys{
						put (mapNiveauDeRestriction at i)/(length(secteursAdministratifsAssocies)*length(mapMateriel)) at: i in: self.mapNiveauDeRestriction;
					}
				}
			}
		}else{
			write "aucun fichier de jours de restriction n'a ete fourni";
		}
	}
}

species secteurAdministratif{
	string id <- "";
	zoneAdministrative zaAssociee <- nil;
	list<equipementDeCaptageIRR> listePPAassocies <- [];
	map<materielIrrigation, map<int,list<int>>> mapJoursDeLaSemaineARestreindreParTypeDeMateriel  <- map([]); // map materiel puis niveau::jour(s) de la semaine restreint(s)
	string nature <-nil;
	
	/*
	 * *****************************************************************************************
	 */			
	action initialisationSecteurAdministratif{
		zaAssociee.secteursAdministratifsAssocies << self;							
		list<equipementDeCaptageIRR> listeTemp <- ((equipementDeCaptageIRR as list) + (equipementDeCaptageCanaux as list)) where 
					((each.location intersects shape) and
						(self.nature contains each.natureRessourcePrelevee )
					);
		
		listePPAassocies <- copy(listeTemp);
		ask listeTemp{
			// JV 080323 cas attendu: on n'a pas encore affecté un secteur administratif à ce point de prélèvement et on lui affecte le secteur courant
			if (secteurAdministratifAssocie = nil){
				secteurAdministratifAssocie <- myself;
			}else{
				// JV 080323 cas problématique: le point de prélèvement a déjà un secteur affecté: on ne lui rajoute pas le secteur courant
				write "Probleme dans le shape des secteurs adminstratifs : le point de prelevement "+self+
				 	" est situé sur le secteur "+ secteurAdministratifAssocie.id + " et sur "+
				 	myself.id;
				myself.listePPAassocies >> self;
			}
			
		}
	}

	/*
	 * *****************************************************************************************
	 */			
	action isSecteurEnBesoinAgricoleFort{
		bool isBesoinFort <- false;			
		ask listePPAassocies{
			// Si au moins une commune est en besoin fort alors tout le secteur l'est
			if(isEnBesoinAgricoleFort()){
				isBesoinFort <- true;					
			}
		}		
		return isBesoinFort;
	}

	/*
	 * *****************************************************************************************
	 */ 			
	int getNiveauRestriction{
		return zaAssociee.niveauDeRestriction;
	}		
	int getNbJoursRestriction (materielIrrigation typeMaterielDeLIlot){
		return length(getJoursDeRestriction(typeMaterielDeLIlot));
	}
	list<int> getJoursDeRestriction (materielIrrigation typeMaterielDeLIlot){
		map<int,list<int>> mapJoursDeLaSemaineARestreindre <- mapJoursDeLaSemaineARestreindreParTypeDeMateriel at typeMaterielDeLIlot;
		if(mapJoursDeLaSemaineARestreindre = nil){
			mapJoursDeLaSemaineARestreindre <- first(mapJoursDeLaSemaineARestreindreParTypeDeMateriel);
		}
		return mapJoursDeLaSemaineARestreindre at getNiveauRestriction();
	}

	bool isEnRestriction{
		if(getNiveauRestriction() > 0){
			return true;
		}else{
			return false;
		}
	}
	bool isEnRestrictionJourCourant (materielIrrigation typeMaterielDeLIlot){
		int indexDuJour <- dateCour.indiceJourDeLaSemaine;
		//Si restriction a la semaine alors on considere les jours de la semaines
		//sinon il faut recalculer l'indice depuis le dernier changement de niveau
		if(zaAssociee.getBaseDeDefinitionJoursDeRestriction() != 7){
			indexDuJour <- zaAssociee.nbJoursMemeNiveauRestriction mod zaAssociee.getBaseDeDefinitionJoursDeRestriction() ;
		}
		loop indiceJourRestriction over: getJoursDeRestriction(typeMaterielDeLIlot){
			if(indiceJourRestriction = indexDuJour){
				return true;
			}
		}
		return false;
					
		// PB GAMA : marche pas correctement -> (6 in [2,4,6]) return false
//			// Si le jour de la semaine de la date courante est compris dans la liste listeJoursDeLaSemaineRestreints alors on irrigue pas ce jour
//			if(dateCour.indiceJourDeLaSemaine in getJoursDeRestriction()){  // getJoursDeRestriction() contains int(dateCour.indiceJourDeLaSemaine)
//				return true;
//			}else{
//				return false;
//			}
	}
	rgb getCouleurNbJoursRestrictionAspect{
		if(!isEnRestrictionJourCourant(first(mapMateriel))){
			return rgb('white');
		}else{
			return zaAssociee.getCouleurNbJoursRestrictionAspect();
		}	
	}
	
	/*
	 * *****************************************************************************************
	 */		
	aspect nbJoursRestrictionAspect{
		draw shape color: getCouleurNbJoursRestrictionAspect();
		draw '' + getNiveauRestriction() at: location color: rgb('black') size: taillePointsMax;
	}		
			
	/*
	 * *****************************************************************************************
	 */
	string toString{			
		string chaine <- 	id 
							+ ' / zaAssociee = ' + zaAssociee
//								+ ' / listePPAassocies = ' + listePPAassocies
							+ ' / mapJoursDeLaSemaineARestreindreParTypeDeMateriel = ' + mapJoursDeLaSemaineARestreindreParTypeDeMateriel
							+ ' / getJoursDeRestriction = ' + getJoursDeRestriction(first(mapMateriel))
							+ ' / getNiveauRestriction = ' + getNiveauRestriction()
							+ ' / getNbJoursRestriction = ' + getNbJoursRestriction(first(mapMateriel))
							+ ' / isEnRestriction = ' + isEnRestrictionJourCourant(first(mapMateriel))
							+ ' / indiceJourDeLaSemaine = ' + dateCour.indiceJourDeLaSemaine;	
		return chaine;		 
	}		
}

