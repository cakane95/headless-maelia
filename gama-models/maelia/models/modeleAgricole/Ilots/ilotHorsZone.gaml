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
 *  ilotHorsZone
 *  Author: Maroussia Vavasseur	
 *  Description: Ces ilots n'appartiennent pas geographiquement a la zone MAELIA. Ils sont pris en compte pour la coherence de exploitations.
 * 				 Ainsi ces ilots appartiennent forcement a une exploitation agricole de la ZM, ils seront traites plus simplement que les ilots classiques car on ne peut pas 
 * 				connaitre les debits simules hors ZM.
 */

model ilotHorsZone

import "../../modeleCommun/typeDeSol.gaml"

global{
	string ilotsHorsZoneShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/horsZone/ilots_HZ.shp';  //ilot_2009    ilot_2009_SansCultureNonPrisesEnCharges
	map<string,list<ilotHorsZone>> mapIlotsHorsZoneParExploitation <- map([]); // idExpl::{IlotHorsZone}
	map<string,ilotHorsZone> mapIlotsHorsZone <- map([]); // idIlot::Ilot
	list<ilotHorsZone> listeIlotsHorsZone <- [];

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action creationIlotHorsZone{

		if !file_exists(ilotsHorsZoneShape)	{do raiseError("fichier inexistant: " + ilotsHorsZoneShape);}
		//if !is_shape(ilotsHorsZoneShape)	{do raiseError("le fichier " + ilotsHorsZoneShape + " n'est pas un fichier shape");}	

		create ilotHorsZone from: file(ilotsHorsZoneShape) with: [id::string(read ( ID_ILOT )), codeExploitationAssociee::string(read ( PAE_ID_EXP) )]{						
			if(codeExploitationAssociee = ""){
				codeExploitationAssociee <- string(shape get( ID_EXPL ));			
			}								
			// Suppressin ilots hors zone dont l'id exploitation nest pas dans la simu courante
			if(!(codeExploitationAssociee in listeExploitations)){
				ask self{
					do die;	
				}							
			}else{
				if("." in id){
					id <- string(id tokenize "." at 0);			
				}				
				if string(shape get( CARACT_IRR)) = 'O'{
					isIrrigable <- true;
				}
				
				// Lien type de sol	
				nomZonePedo <- string(shape get( ID_SOL ));
				if(nomZonePedo != nil){
					list<string> tmp<-(nomZonePedo split_with"_");			
					nomZonePedo <- tmp[1];
					int i <- 2;
					loop while: (i < length(tmp)){
						nomZonePedo <- nomZonePedo + "_" + tmp[i] ;
						i <- i+1;
					}
				}else{
					nomZonePedo <- "";// first(listNomZonePedo);
					//write "type de sol inconnu "
				}
				
//				
				name <- id+ '-HZ';// + '-' + name;				
				put self at: id in: mapIlotsHorsZone;
				add self to: listeIlotsHorsZone;
				
				list<ilotHorsZone> listIlotsHZ <- [];
				if(!empty(list(mapIlotsHorsZoneParExploitation at codeExploitationAssociee))){
					set listIlotsHZ value: list(mapIlotsHorsZoneParExploitation at codeExploitationAssociee);
				}
				add self to: listIlotsHZ;
				put listIlotsHZ at: codeExploitationAssociee in: mapIlotsHorsZoneParExploitation;
				//TODO lecture dans le shapeFile!
				//string idMat <- string(shape get( MAT_IRR)); 
				if (isIrrigable){
					string idMat <- string(shape get( MATERIEL)); 
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
}

species ilotHorsZone parent: ilot{
	string nomZonePedo <- "";		
	action initialisationIlots{			
		if listeParcelles = nil or empty(listeParcelles) {
//				write '[ILOT HORS ZONE] ' + id + "- LISTE PARCELLE NULLE = " + listeParcelles;
			
			// Mise a jour de la map contenant les ilots en enlevant les ilots allant mourrir
			remove key: id from: mapIlotsHorsZone;
			remove self from: listeIlotsHorsZone;
			
			let listIlotHZ type: list value: mapIlotsHorsZoneParExploitation at codeExploitationAssociee;
			remove self from: listIlotHZ;
			put listIlotHZ at: codeExploitationAssociee in: mapIlotsHorsZoneParExploitation;
			
			do die;
		}					
		else {		
			parcellePrincipale <- (list(listeParcelles) with_max_of ((each.surface))); 
						
			// calcul de la surface total de l'ilot
			loop parcelleCourante over: listeParcelles{
				set surfaceIlotAPrtirDesParcelles value: surfaceIlotAPrtirDesParcelles + parcelleCourante.surface;
			}					
			// Redefinition de la surface pour quelle corresponde exactement � la suface gama
			ask listeParcelles{
				set surface value: float(surface * (myself.shape.area / myself.surfaceIlotAPrtirDesParcelles));
			}
		}			
	}		

	string getNomZonePedo{
		return nomZonePedo;
	}
}	
