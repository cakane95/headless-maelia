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
 *  zoneAdministrative
 *  Author: Maroussia Vavasseur
 *  Description: Une zone administrative est composee d'un ensemble de communes. C'est sur cette zone, decoupee en secteur, que vont s'apppliquer les arretes d'irrigation.
 * 				 Une zone est associee a un et un seul point de reference.
 */

model zoneAdministrative

import "../modeleCommun/contourZoneMaelia.gaml"
import "pointDeReferenceNonRealimente.gaml"
import "zoneAdministrativeSimple.gaml"
import "zoneAdministrativeComplexe.gaml"
 
global{
	string cheminZA <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/zonesAdministratives/';
 	string nomFichierZA <- 'zonesAdministratives.shp';
	
	list<zoneAdministrative> listeZAparOrdreAvalVersAmont <- [];
	list<zoneAdministrative> listZonesAdministratives <- [];
			
	/*
	 * *****************************************************************************************
	 * Publique
	 */

	action constructionZonesAdministratives{
		
		if !file_exists(cheminZA + nomFichierZA) 	{do raiseWarning("fichier inexistant: " + cheminZA + nomFichierZA);}
		//else if !is_shape(cheminZA + nomFichierZA) 	{do raiseWarning("le fichier " + cheminZA + nomFichierZA + " n'est pas un fichier shape");}
		
		switch nomChoixModeleZA {
       		match Complexe {
                do creationZonesAdministrativesComplexe();                       
            }
        	match Simple {
                do creationZonesAdministrativesSimple();    
            }            
            default {
                do creationZonesAdministrativesComplexe();
            }
       }
			
	}
		
	action creationZonesAdministratives(species<zoneAdministrative> typeZA <- zoneAdministrative ){	
		
		create typeZA from: file(cheminZA + nomFichierZA) with: [idZoneAdministrative::string(read ( ID_ZA ))]{ 
			pointDeReferenceAssocie <- first((pointDeReference as list) where (each.idPointDeReference = string(shape get( ID_STH ))));

			// Creation dun point Non realimente si ZA non realimentee
			string idSth <- string(shape get( ID_STH ));
			if((empty(idSth)) or idSth contains "NULL"){	
				geometry geo <- self.shape;			
				pointDeReferenceAssocie <- world.creationPointDeReferenceNonRealimente(geo); // TODO : voir si definition en entree des ZA non realimentee des doe/dcr par ZA				
			}
			// Suppression des polygones nappartenant pas a la zone detude (donc n'ayant pas de ptDeRef)
			if(pointDeReferenceAssocie = nil){
				ask self{
					do die();	
				}
			}else{
				do initialisationZoneAdministrative();
			}
			listZonesAdministratives << self;			
		}	
		do determinationZoneAdministrativeRealimenteeAval();
	}
	
	/*
	 * *****************************************************************************************
	 * Private
	 * on suppose dans un premier temps qu'il n'y a qu'une seule zone en amont
	 */ 
	action determinationZoneAdministrativeRealimenteeAval{		
		list<zoneHydrographique> listeZHTemp <- [];
		list<zoneAdministrative> listeZArealimentees <- (listZonesAdministratives) where (each.isRealimentee());
		ask listeZArealimentees{
			if(getNiveauAmontAval() != -1){
				add pointDeReferenceAssocie.zoneHydrographiqueAssociee to: listeZHTemp;				
			}				
		}

		ask listeZArealimentees{
			int niveauTemp <- -1;			
			loop zhCourante over: listeZHTemp{							
				// Si la zh associee a la za courante a un niveau hierarchique sup (et donc que c'est une zone amont) a la zh courante alors il est possible que �a soit sa zone aval proche
				if(zhCourante.niveauHierarchiqueArbreZH < getNiveauAmontAval()){
					if(niveauTemp < zhCourante.niveauHierarchiqueArbreZH){
						niveauTemp <- zhCourante.niveauHierarchiqueArbreZH;
						zoneAdministrativeAval <- first((listZonesAdministratives) where (each.pointDeReferenceAssocie.zoneHydrographiqueAssociee = zhCourante));
					}
				}
			}						
		}	
		
		//creation Liste ZA aval Vers Amont
		listeZAparOrdreAvalVersAmont <- (listZonesAdministratives) where (each.pointDeReferenceAssocie.zoneHydrographiqueAssociee != nil);	
		listeZAparOrdreAvalVersAmont <- listeZAparOrdreAvalVersAmont sort_by (each.pointDeReferenceAssocie.zoneHydrographiqueAssociee.niveauHierarchiqueArbreZH);	
		
		// On rajoute ensuite les ZA sans ordre particulier (les non realimentees)
		list<zoneAdministrative> listeZAnonRealimentees <- (listZonesAdministratives) where (!each.isRealimentee());
		ask listeZAnonRealimentees{
			listeZAparOrdreAvalVersAmont << self;
		}		
	}
}

species zoneAdministrative{
	string idZoneAdministrative <- "";
	list<secteurAdministratif> secteursAdministratifsAssocies <- [];
	pointDeReference pointDeReferenceAssocie <- nil;
	zoneAdministrative zoneAdministrativeAval <- nil;
	int niveauDeRestriction <- 0; // il y a 5 niveau de restriction : 0j, 1j, 2j, 3,5j, 7j
	gestionnaireDeBarrage gestionnaireBarrageAssocie <- nil;
	bool isEnCampagneEtiage <- false;		
	bool isBesoinAgricoleFort <- false; // TODO : a initialiser et metre a jour tous les jours ?
	int nbJoursMemeNiveauRestriction <- 0; // Il faut attendre 7 jours pour pouvoir baisser de 1 niveau si il y a eu une amelioration
	string consoleDebug <- "";
	map<int, int> mapBaseDefinitionPeriodeDeRestriction <- [0::7, 1::7, 2::7, 3::7, 4::7] ; //par defaut definition des jours de restriction en base journaliere
	map<int,float> mapNiveauDeRestriction <- [0::0, 1::1, 2::2, 3::3.5, 4::7] ; 
	map<int, string> nomAffichageNiveauRestriction <- [0::"0", 1::"1", 2::"2", 3::"3", 4::"4"];
	list<ilot> listIlotsIrrigablesAssocies <- [];
	map<int,float> volumePrelevePasse <- map<int,float>([]); //date , volume
	
	
	
	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		do miseAJourBesoinAgricole();
		float volTot <- 0.0;
		ask secteursAdministratifsAssocies{
			ask listePPAassocies{
				volTot <- volTot + self.getVolumeSouhaite() ;
			}
		}
		put volTot at:dateCour.indiceDate in:volumePrelevePasse ;
	}
	
	action comportementAnnuel{	
		volumePrelevePasse <- map<int,float>([]);
	}
	
	/*
	 * *****************************************************************************************
	 */	
	action initialisationZoneAdministrative{
		name <- idZoneAdministrative;
		gestionnaireBarrageAssocie <- first((gestionnaireDeBarrage as list) where (each.pointNodalAssocie = pointDeReferenceAssocie));
		if(isRealimentee() and gestionnaireBarrageAssocie = nil){
			write "[ZA/INIT] Pb !!!!! la ZA est realimentee mais na pas de gestionnaire de barrage associee - " + self;
		}else{
			if(gestionnaireBarrageAssocie!=nil){
				ask gestionnaireBarrageAssocie{
					zaAssociee <- myself;
				}
			}
			ask listeIlots  where (each.location intersects shape){
				if (isIrrigable){
					myself.listIlotsIrrigablesAssocies << self;
				}
			}
		}
	}	
	float getNbJoursRestriction{
		return mapNiveauDeRestriction at (niveauDeRestriction);
	}			
	bool isRealimentee{
		return pointDeReferenceAssocie.isRealimente and (gestionnaireBarrageAssocie != nil);
	}	
		
	int getNiveauAmontAval{
		int niveau <- -1;
		if(pointDeReferenceAssocie.zoneHydrographiqueAssociee != nil){
			niveau <- pointDeReferenceAssocie.zoneHydrographiqueAssociee.niveauHierarchiqueArbreZH;			
		}			
		return niveau;
	}
	int getBaseDeDefinitionJoursDeRestriction{
		return mapBaseDefinitionPeriodeDeRestriction at niveauDeRestriction ;
	}
	
	float getPrelevementAgricoleMoyenSemaineDerniere{
		float volTot <- 0.0;
		loop i from: (dateCour.indiceDate - 6) to: dateCour.indiceDate{
			volTot <- volTot + (volumePrelevePasse at i);
		} 
		volTot <- volTot / 7;	
		return volTot;
	}	
			
	/*
	 * *****************************************************************************************
	 */			
	action surveillanceZoneAdministrative{
		ask(pointDeReferenceAssocie){
			myself.isEnCampagneEtiage <- surveillancePointDeReference(); //on regarde si on est en dessous du DOE
		}
		
		// Si on est en restriction (meme si le debit courant est > doe) alors on est en gestion d'etiage. 
		// De meme que si la ZA aval est en restriction de plus de 1 niveau d'ecart de la ZA. (i.e. on était en restriction (niveauDeRestriction > 0 ) et il y a une zone administrative aval
		if(niveauDeRestriction > 0 or zoneAdministrativeAval != nil){
			isEnCampagneEtiage <- true;
		}
	}

	/*
	 * *****************************************************************************************
	 */	
	action miseAJourBesoinAgricole{	
		ask secteursAdministratifsAssocies{				
			// Si au moins un secteur est en besoin fort alors toute la ZA l'est
			if(bool(isSecteurEnBesoinAgricoleFort())){
				myself.isBesoinAgricoleFort <- true;					
			}
		}
	}

	/*
	 * *****************************************************************************************
	 */	
	action interdictionPompage(int nouveauNiveauRestrictionEntree){						
		if(nouveauNiveauRestrictionEntree = 0){
			nbJoursMemeNiveauRestriction <- 0;
		}else{
			// on regarde que le nouveau niveau de restriction est le meme que l'ancien
			 if(nouveauNiveauRestrictionEntree = niveauDeRestriction){
				nbJoursMemeNiveauRestriction <- nbJoursMemeNiveauRestriction + 1;		
			}else{
				nbJoursMemeNiveauRestriction <- 0;		
			}	
		}
		niveauDeRestriction <- nouveauNiveauRestrictionEntree;								
	}

	/*
	 * *****************************************************************************************
	 */	
	bool isLacheBarrageEnCours{	
		return gestionnaireBarrageAssocie.isLacherEnCours();
	}	
		
	/*
	 * *****************************************************************************************
	 * // Les lachers sont fait de puis le gestionnaire de barrage
	 */			
	action gestionEtiage{	
		// RESTRICTIONS
		if(isEnCampagneEtiage){				
		
		}
	}		
	
	/*
	 * *****************************************************************************************
	 */
	rgb getCouleurTypePointRef{
		return pointDeReferenceAssocie.couleurTypePoint;
	}				
	rgb getCouleurEnFonctionPointRef{
		return pointDeReferenceAssocie.couleurPalierDebit;
	}		
	rgb getCouleurNbJoursRestrictionAspect{
		if((mapNiveauDeRestriction at niveauDeRestriction) = 0){
			return rgb('white');
		}else{
			return rgb(paletteCouleursNbJourRestriction at (mapNiveauDeRestriction at niveauDeRestriction));
		}	
	}		
	
	/*
	 * *****************************************************************************************
	 */
	aspect basic{
		draw shape color: getCouleurTypePointRef();
	}					
	aspect pointRefPalierDebitAspect{
		draw shape color: getCouleurEnFonctionPointRef();
	}	
	aspect nbJoursRestrictionAspect{
		draw shape color: getCouleurNbJoursRestrictionAspect();
//			draw  '' + niveauDeRestriction at: location color: rgb('black') size: taillePointsMax;
	}		
		
	/*
	 * *****************************************************************************************
	 */
	action toString{
		string chaine <- "******* " + name + " *******";		
		chaine <- chaine + '\t/ idZoneAdministrative = ' + idZoneAdministrative;			
		chaine <- chaine + '\t/ secteursAdministratifsAssocies = ' + secteursAdministratifsAssocies;
		chaine <- chaine + '\t/ pointDeReferenceAssocie = ' + pointDeReferenceAssocie;
		chaine <- chaine + '\t/ gestionnaireBarrageAssocie = ' + gestionnaireBarrageAssocie;
		chaine <- chaine + '\t/ zoneAdministrativeAval = ' + zoneAdministrativeAval;
		chaine <- chaine + '\t/ isRealimente = ' + isRealimentee();
		chaine <- chaine + '\t/ isBesoinAgricoleFort = ' + isBesoinAgricoleFort;
		chaine <- chaine + '\t/ isEnCampagneEtiage = ' + isEnCampagneEtiage;
		chaine <- chaine + '\t/ niveauDeRestriction = ' + niveauDeRestriction;
		chaine <- chaine + '\t/ nbJoursMemeNiveauRestriction = ' + nbJoursMemeNiveauRestriction;
		return chaine;
	}					
}

