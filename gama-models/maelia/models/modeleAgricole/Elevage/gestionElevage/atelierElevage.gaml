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
 *  Exploitations
 *  Author: Renaud Misslin
 *  Description: Un atelier d'élevage
 */

model atelierElevage

import "../../Ilots/ilot.gaml"
import "lotAnimaux.gaml"

global{
	string fichierLotsAnimaux <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/agriculteurs/lotsAnimaux.csv';
	list<exploitation> exploitationsElevage; // Liste des exploitations ayant un ou plusieurs ateliers d'élevage
	action creationAtelierElevage (string ID_exploit){
		
	}

}

	
species atelierElevage {
	//list<parcelle> parcellesPaturables; // MAJ chaque jour, rassemble les parcelles potentiellement paturables
	//list<parcelle> parcellesFauchables; // MAJ chaque jour, rassemble les parcelles potentiellement fauchables
	list<lotAnimaux> mesLotsAnimaux;
	exploitation monExploitation;
	agriculteur monAgriculteur;
	batiment monBatiment;
	
	/*
	* *****************************************************************************************
	* Initialisation
	*/
	
	
	/*
	* *****************************************************************************************
	* Actions / fonctions
	*/
	

	 
	// Sélection journalière des parcelles paturables : vise à identifier de nouvelles parcelles paturables pour satisfaire les besoins de lots d'animaux qui n'auraient pas de parcelle attribué pour le jour courant
	list<parcelle> SelectionParcellesPaturables (lotAnimaux lotCourant) {
		list<parcelle> parcelles_paturables;
		list<parcelle> resultat;
//		write "mes parcelles -> " + lotCourant.monAtelierElevage;
		// 1. Identification des parcelles potentiellement paturables
		parcelles_paturables <- lotCourant.monAtelierElevage.monAgriculteur.listeParcelles collect each where (each.isPaturable); // Sélection des parcelles qui sont des paturages
//		write "parcelles isPaturable pour " + lotCourant.idLotAnimaux + " avant eloignement -> " + length(parcelles_paturables);
//		loop par over: parcelles_paturables {
//			write "itk = " + par.getITKAnnee().nomPourAffichage;
//		}

		point locBat <- lotCourant.monAtelierElevage.monExploitation.monBatiment.location;
		parcelles_paturables <- parcelles_paturables collect each where (
									    (topology(world) distance_between [locBat, each.location] >= lotCourant.eloignement_min * 1000.0) and
									    (topology(world) distance_between [locBat, each.location] <= lotCourant.eloignement_max * 1000.0)
								);

		parcelles_paturables <- parcelles_paturables collect each where (each.getITKAnnee().strategiePatureITK != nil); // Sélection des parcelles dans lequelles il y a des ITK pature cette année
//		write "parcelles itk pature cette année -> " + parcelles_paturables;
		
		parcelles_paturables <- parcelles_paturables collect each where (each.cultureParcelle != nil);
//		write "parcelles en culture" + parcelles_paturables;
		parcelles_paturables <- parcelles_paturables collect each where ((each.cultureParcelle.espece.idEspeceCultivee = PRAIRIEP) or (each.cultureParcelle.espece.idEspeceCultivee = PRAIRIET) or (each.isPrairiePermanente) or (listeNomsEspecesHerbSim contains each.cultureParcelle.espece.idEspeceCultivee)); // On ne veut que des parcelles en prairie
//		write "parcelles en prairie" + parcelles_paturables;
		parcelles_paturables <- parcelles_paturables collect each where (each.lotAnimauxCourant = nil);
//		write "parcelles sans animaux" + parcelles_paturables;
		parcelles_paturables <- parcelles_paturables collect each where (each.tpsReposParcelle = 0);
		parcelles_paturables <- parcelles_paturables collect each where (each.jourProchaineRecoltePrairie != dateCour.nbJoursEcoulesDansAnnee);
		
		// Sélection des parcelles dans lesquelles il y a des ITK pature aujourd'hui
		list<parcelle> pp;
		loop parcelle_potentielle over: parcelles_paturables {
			loop stratPat over: parcelle_potentielle.getITKAnnee().strategiePatureITK.mesStrategiesMultiples {
				if (
					stratPat.isFenetreTemporelleOk(parcelle_potentielle, parcelle_potentielle.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite)
					and ((cultureHerbSim(parcelle_potentielle.cultureParcelle.monModelDeCulture).getBiomasseAboveGround() * (parcelle_potentielle.surface / 10000)) * stratPat.coefHerbeAccessible >= lotCourant.besoinJourCourant)
					and stratPat.isPaturableSiFauchable(parcelle_potentielle)
				) 
				 {
					pp <+ parcelle_potentielle;
				}
			}
		}
		parcelles_paturables <- remove_duplicates(pp);
//		write "parcelles itk pature aujourd'hui et biomasse ok -> " + parcelles_paturables;
		
//		parcelles_paturables <- parcelles_paturables sort_by (topology(world) distance_between [lotCourant, each]); // On tri les parcelles en fonction de leur proximité avec le lot
//		parcelles_paturables <- parcelles_paturables collect each where ((cultureHerbSim(each.cultureParcelle.monModelDeCulture).getBiomasseAboveGround() * (each.surface / 10000))*each.getITKAnnee().strategiePatureITK.coefHerbeAccessible >= lotCourant.besoinJourCourant) ; // Il faut que la parcelle réponde aux besoin du lot pour au moins une journée
//		write "parcelles < 1000 m" + parcelles_paturables;
		

		// 2. Identification des parcelles répondant positivement aux contraintes d'entrée d'un lot
//		write "HERBSIM Renaud - parcelles potentiellement paturables = " + parcelles_paturables;
		if (parcelles_paturables != nil) {
			loop p over: parcelles_paturables {
				loop stratPat over: p.getITKAnnee().strategiePatureITK.mesStrategiesMultiples {
					// Si on est entre le 15 mai et le 15 aout OU entre le 15 octobre et le 15 décembre -> on ne regarde plus les contraintes pour entrer sur les parcelles (seulement si la quantité d'herbe est ok)
					if ((dateCour.nbJoursEcoulesDansAnnee > 135 and dateCour.nbJoursEcoulesDansAnnee < 227) or (dateCour.nbJoursEcoulesDansAnnee > 288 and dateCour.nbJoursEcoulesDansAnnee < 349) ) {
						if (stratPat.isPaturableFinSaison(p, p.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite, lotCourant.calculBesoinsAlimentation())) {
							if !(resultat contains p) {resultat <+ p;}
						}
					// Si on est à un autre moment de l'année
					} else {
						if (stratPat.isPaturable(p, p.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite, lotCourant.calculBesoinsAlimentation())) {
							if !(resultat contains p) {resultat <+ p;}
						}
					}
				}
			}
		}
		parcelles_paturables <- resultat;
		
		list<parcelle> parcelles_paturables_1km <- parcelles_paturables collect each where (topology(world) distance_between [each, lotCourant] < 1000); // Sélection des parcelles situées à moins de 1 km du lot 
//		write "toutes les parcelles paturables = " + parcelles_paturables;
//		write "parcelles paturables à moins de 1000 m = " + parcelles_paturables_1km;
		
		// Si des parcelles sont paturables dans un rayon de 1 km, on prend celle où il y a le + de biomasse
		if (length(parcelles_paturables_1km) > 0) {
			parcelles_paturables <- parcelles_paturables_1km;
			parcelles_paturables <- reverse(parcelles_paturables sort_by (cultureHerbSim(each.cultureParcelle.monModelDeCulture).getBiomasseAboveGround() * (each.surface / 10000))); // On tri les parcelles en fonction de leur proximité avec le lot
//			write "toutes les parcelles paturables classées biomasse = " + parcelles_paturables;
//			write "première parcelle " + first(parcelles_paturables) + " -> biomasse = " + (cultureHerbSim(first(parcelles_paturables).cultureParcelle.monModelDeCulture)).getBiomasseAboveGround() * (first(parcelles_paturables).surface / 10000);
		} else { // Si pas de parcelle dispo dans un rayon de 1 km, on prend la plus proche dans un rayon de 5 km
			list<parcelle> parcelles_paturables_5km <- parcelles_paturables collect each where (topology(world) distance_between [each, lotCourant] < 5000);
			parcelles_paturables <- parcelles_paturables_5km;
			parcelles_paturables <- parcelles_paturables sort_by (topology(world) distance_between [lotCourant, each]);
		}
				
		// 3. SI aucune parcelle ne répond positivement aux contraintes d'entrée TODO 24092025 RM -> si on fait ça on envoit les animaux sur des parcelles qui n'ont pas forcément assez de biomasse pour une journée puisqu'on ne regarde pas la biomasse dispo
		//    MAIS que des parcelles sont potentiellement paturables, que le lot est dehors et qu'on est dans la fenêtre de paturage,on choisi celle qui a la biomasse la plus élevée
		//    même si les autres conditions ne sont pas bonnes
//		write "resultat = " + resultat + " -- parcelles_paturables = " + parcelles_paturables + " -- !lotCourant.auBatiment = " + !lotCourant.auBatiment;
//		write "resultat = " + (length(resultat) = 0) + " -- parcelles_paturables = " + (parcelles_paturables != nil) + " -- !lotCourant.auBatiment = " + !lotCourant.auBatiment;
//		if (length(resultat) = 0 and parcelles_paturables != nil and !lotCourant.auBatiment) {
//			// Sélection des parcelles sur la base de la fenetre temporelle
//			list<parcelle> parcelle_encore_paturables;
//			loop p over: parcelles_paturables {
//				if (p.getITKAnnee().strategiePatureITK.isFenetreTemporelleOk(p, p.ilot_app.agriculteurAssocie.nbJoursDeDecalageActivite)) {
//					parcelle_encore_paturables <+ p;
//				}
//			}
//			parcelle_encore_paturables <- parcelle_encore_paturables sort_by (cultureHerbSim(each.cultureParcelle.monModelDeCulture).biomass_above_ground); // TODO ajouter tri par hauteur d'herbe selon mode  de gestion
//			resultat <- reverse(parcelle_encore_paturables); // Tri de la parcelle qui a la biomasse la plus grande à celle qui a la plus petite biomasse
//			//p.getITKAnnee().strategiePatureITK.isFenetreTemporelleOk(parcelleEntree, deltaTemporel)
//			write "parcelles encore paturables = " + resultat;
//		}
//		write "HERBSIM Renaud - parcelles potentiellement paturables = " + parcelles_paturables + " -- vraiment paturables = " + resultat + " (lot au batiment = " + lotCourant.auBatiment + ")";
		return parcelles_paturables;
	}
	
	// Sélection journalière des parcelles fauchables : parcelles qui ne sont pas potentiellement paturées et qui ont un statut "fauchable"
	list SelectionParcellesFauchables {
		list<parcelle> parcelles_selectionnees;
		return parcelles_selectionnees;
	}
	
	/*
	 * *****************************************************************************************
	 * Display
	 */
	 
	aspect basic{
		//draw shape color: couleurExploitation;
	}   	
}

	
