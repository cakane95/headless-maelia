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
 *  AgriculteurAqYield
 *  Author: Maroussia Vavasseur
 *  Description: L'agriculteur AqYield a un comportement le plus logique et simple possible.
 * 				 Il se base sur les donnees d'entrees pour determiner les cultures d'une annees sur l'autres en utilisant en boucle ces rotations.
 */

model AgriculteurAqYield

import "../Ilots/ilot.gaml"

global{
	action constructionAgriculteursDonneesEntrees{		
		do creationAgriculteurs(agriculteurDonneesEntrees);
	}
}

species agriculteurDonneesEntrees parent: agriculteur{

	// Chaque annee on regarde les taux de mais ensilage et on met a jour la culture a venir (reste dans le meme SDC)
	// Au moment de l'appel, seule une parcelle a recolte sa culture
	// On change litk suivant des parcelles (mais on laisse la liste initiale telle quelle, juste l'itk courant sera modifie : une sorte ditk alternatif)
	// JV 020321 mantis #0002773 auparavant surcharge de choixAssolement, nom modifié compte tenu de la grande différence sémantique entre ce code et celui de la surcharge choixAssolement de agriculteurFronctionsDeCroyances et pour être plus explicite
	action affectationMaisEnsilage{
		// Etape 1 : calcul de la surface totale de prairie  et de mais de lexploitation
		float tauxPrairie <- surfacePP at sonExploitation; // JV 180221 si !gestionPrairiePParSWAT surfacePP est remis a zero et donc est nul ici
		float tauxMais <- 0.0;
		float surfExpl <- surfacePP at sonExploitation;
		list<parcelle> parcellesEnMais;
		//write "surfExpl avant =" + surfExpl;
		ask listeParcelles{
			if(systemeDeCultureParcelle = nil){
				write "[AgriDonnee] " + idParcelle + " - systemeDeCultureParcelle nul !!! " + systemeDeCultureParcelle;
			}else{
				if(systemeDeCultureParcelle.getProchainITKnonCI() != nil){
					string nomEspeceSuivante <- systemeDeCultureParcelle.getProchainITKnonCI().especeCultiveeITK.idEspeceCultivee;
					//write "agri " + myself.idAgriculteur + " parcelle " + idParcelle + " nomEspeceSuivante " + nomEspeceSuivante; // JV debug
					if(listeNomsEspecesHerbSim contains nomEspeceSuivante or self.isPrairiePermanente or nomEspeceSuivante = "prairiet") {
						tauxPrairie <- tauxPrairie + surface;
					}else if(nomEspeceSuivante contains "mais"){
						tauxMais <- tauxMais + surface;
						parcellesEnMais << self;
					}							
				}else{
					write "[AgriDonnee] " + idParcelle + " - itk nul !!! " + systemeDeCultureParcelle + " SdcRef: " + idSdcRef;
				}				
			}
			surfExpl <- surfExpl + surface;
		}
		
		// JV 020321 affichage pour debug 
		if verboseMode {
			write "=== affectation mais ensilage ===";
			write "parcelle\tsurface\tITK courant\tprochaine espece non CI\trotation";
			ask listeParcelles{ // +1 pour etre lisible par des non informaticiens car indiceItkCourant commence à 0
				write idParcelle + "`\t" + surface with_precision 2 + "\t" + (systemeDeCultureParcelle.indiceItkCourant+1) + "\t" + systemeDeCultureParcelle.getProchainITKnonCI().especeCultiveeITK.idEspeceCultivee + "\t" + rotationReelle;
			}		
			write "surface exploitation=" + surfExpl with_precision 2 + "surface prairie=" + tauxPrairie with_precision 2 + "surface mais=" + tauxMais with_precision 2; // JV debug
			write "parcellesEnMais=" + (parcellesEnMais collect each.idParcelle); // JV debug		
		}
		
		// Etape 2 : selection des parcelles en mais avec du mais ensilage si conditions remplies
		tauxPrairie <- tauxPrairie / surfExpl;//sonExploitation.surfaceExploitation * nombreMeterCarreDansUnHectare;
		tauxMais <- tauxMais / surfExpl; //sonExploitation.surfaceExploitation * nombreMeterCarreDansUnHectare;
		if verboseMode {
			write "taux prairie=" + tauxPrairie with_precision 3 ; // JV debug
			write "taux mais=" + tauxMais with_precision 3 ; // JV debug
		}
		if(tauxPrairie >= 0.1 and tauxMais > 0.0){
			list<parcelle> parcellesAmodifier <- [];
			//list<parcelle> parcellesEnMais <- listeParcelles where (each.systemeDeCultureParcelle.getITKanneeSuivante().especeCultiveeITK.idEspeceCultivee contains "mais"); // JV 25062020 deplacé plus haut, cf Mantis #2634
			if(tauxMais < 0.30){ // full_ensilage
				// toutes les parcelles en ensilage
				parcellesAmodifier <- getParcellesAmodifier(parcellesEnMais, 0.75); // parcellesEnMais;				
				if verboseMode {write "parcellesAmodifier 0.75 = " + (parcellesAmodifier collect each.idParcelle);}// JV debug
			}else{
				if(tauxPrairie > 0.35){ // max_conso
					// aucune parcelles en ensilage						
				}else if(tauxPrairie > 0.1 and tauxPrairie <= 0.35){ // mi_ensilage
					parcellesAmodifier <- getParcellesAmodifier(parcellesEnMais, 0.5);
					if verboseMode {write "parcellesAmodifier 0.5 = " + (parcellesAmodifier collect each.idParcelle);} // JV debug
				}
			}
			
//				write "------------ "  + idAgriculteur + " - listeParcelles = " + listeParcelles;
//				write "tauxPrairie - " + tauxPrairie + " - tauxMais - " + tauxMais + " - surfExpl - " + surfExpl + " - SURFBIS - " + sonExploitation.surfaceExploitation * nombreMeterCarreDansUnHectare + " - parcellesEnMais = " + parcellesEnMais + " - parcellesAmodifier = " + parcellesAmodifier;
//				
			// On applique un mais ensilage sur les parcelles concernees
			especeCultivee maisEnsilage <- first((especeCultivee as list) where (each.idEspeceCultivee contains "maisE"));
			if (maisEnsilage !=nil){
				ask parcellesAmodifier{
					ask systemeDeCultureParcelle{
						do forcerITKprochaineCultureNonCI(maisEnsilage, myself.ilot_app.materielIlot, myself.ilot_app.getNomZonePedo(), myself.ilot_app.agriculteurAssocie.sonExploitation.type, myself.gestionPrairie);
					}
				}
			}				
		}	
		if verboseMode {write "=== fin affectation mais ensilage ===";}
			
	}
	
	list<parcelle> getParcellesAmodifier(list<parcelle> parcellesEntree, float taux){
		list<parcelle> parcellesAmodifier <- [];
		// Si la plus grande parcelle a une taille > 75% de lensemble de parcelle en mais, alors on prend celle-la pour faire de lensilage
		float surfaceMaisTot <-  sum((parcellesEntree as list) collect (each.surface));
		parcelle laPlusGrande <- last(parcellesEntree sort_by each.surface);
		if(laPlusGrande.surface / surfaceMaisTot > taux){
			parcellesAmodifier << laPlusGrande;
		}else{
			float sommeSurf <- 0.0;
			ask (parcellesEntree){
				if(sommeSurf/surfaceMaisTot < taux){
					parcellesAmodifier << self;
					sommeSurf <- sommeSurf + surface;
				}
			}
		}
		return parcellesAmodifier;	
	}
	
	// Sur la parcelle en cours on fait le changement ditk
	action getAssolement1parcelle(parcelle parc){
		ask parc.systemeDeCultureParcelle{
			do changementITK();
			if(activerITKalternatif){ // JV 300320: just for consistency
				parc.itkAlternatif <-false;
			}
			// JV 090920 cas particulier gel (cf Mantis 0002670)
			if (nomChoixModeleCroissancePrairie != "HerbSim" and nomChoixModeleCroissancePrairie != "HerbSimNC") {
				if(parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee="gel"){
					do setJourRecolteGel(parc);
				}	
			} else if (nomChoixModeleCroissancePrairie = "HerbSim" or nomChoixModeleCroissancePrairie = "HerbSimNC") {// RM 170823 modif 280524 --> si prairie temporaire...
				if(parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee="prairiet" or (listeNomsEspecesHerbSim contains parc.getITKAnnee().especeCultiveeITK.idEspeceCultivee and !parc.isPrairiePermanente) ){//or parc.getITKAnnee().especeCultiveeITK.isEspeceHerbSim){
					do setJourRecoltePrairie(parc);
				}
			}
		}

		// JV 250321 MAJ du nb de parcelles irriguées de l'agri en fonction du nouvel ITK de cette parcelle
		// nbParcellesIrriguees utile lors de la création des groupes d'irrigation (instruit le 01/01)
		// à l'origine cette MAJ était réalisée le 31/12 mais cela a posé problème lors de l'introduction des CI (mantis 0002510)
		// elle a alors été déplacée lors du semis mais du coup lors de la création des groupes le 1/1 on ne comptabilise pas les cultures non encore semées
		// donc on le fait maintenant dès le changement d'ITK
				
		if(parc.isIrrigueeAnneeCourante()){
			if(parc.isParcelleIrrigable()){
				surfaceIrriguee <- surfaceIrriguee + parc.surface;
				nbParcellesIrriguees <- nbParcellesIrriguees + 1;
			}
			else{
				write "id_ilot concerné = " + parc.idIlot + " -- itk = " + parc.getITKAnnee().nomPourAffichage;
				write '[AGRI/miseAJourVariables] PB parcelle ne peut pas etre irriguee car non irrigable ' + parc.toString();
			}
		}
						
	}
}	
