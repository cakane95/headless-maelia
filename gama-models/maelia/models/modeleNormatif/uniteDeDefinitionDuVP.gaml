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
 *  uniteDeDefintionDuVP
 *  Author: Maelia
 *  Description: Une des problematique de MAELIA est d'avoir differents scenarios, avec entre autre comme variable la definition du VP.
 *				 Par exemple, chaque annee on peut calculer le VP comme le volume annuel de l'annee la pire sur 5 annees (annee quinquenale seche). Ce calcul est fonction du DOE.
 * 				 Une unite va calculer un VP d'une unite de gestion. Car une UG est associee a un point DOE.
 */

model uniteDeDefinitionDuVP

import "../modeleHydrographique/ressourceEnEau.gaml"

global{
	/* 
	 * *****************************************************************************************
	 * Publique
	 */
	string cheminVP <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleNormatif/uniteDeGestion/';
 	string nomFichierVP <- 'VP_historique.csv';
 
	 
	action constructionUniteDeDefinitionDuVP{
		loop ug over: uniteDeGestion{
			create uniteDeDefinitionDuVP{
				uniteDeGestionAssociee <- ug;
				do initialisationUniteDeDefinitionDuVP;
			}			
		}
		if(!isEauDisponibleAgriInfinie){
			//Suppression des ppa sans quota ou hors zone
			ask equipementDeCaptageIRR {
				if(sonUniteDeDefinitionDuVP = nil){
					list<equipementDeCaptageIRR> liste <- (ressourceAssociee.mapEquipementsCaptageAssocies at IRR) as list<equipementDeCaptageIRR>;
					liste >> self;
					put liste in: ressourceAssociee.mapEquipementsCaptageAssocies at: IRR;
					liste <- (mapEquipementsDeCaptage at IRR) as list<equipementDeCaptageIRR>;
					liste >> self;
					put liste in: mapEquipementsDeCaptage at: IRR;
					loop uVP over: uniteDeDefinitionDuVP{
						liste <- uVP.listPPA_UG;
						liste >> self;
						uVP.listPPA_UG <- liste;
					}
					do die();
				}
			}
			ask ilot as list{

				map<equipementDeCaptageIRR, float> mapACopier <- map<equipementDeCaptageIRR, float>([]); 
				loop eq over: listeEquipementsCaptagesAssocies.keys{
					if(!dead(eq)){
						put (listeEquipementsCaptagesAssocies at eq) at: eq  in: mapACopier;
					}
				}
				listeEquipementsCaptagesAssocies <- mapACopier;
				
			}
		}
		
	}	
}

species uniteDeDefinitionDuVP{
	float volumePrelevableTotal <- 0.0;
	uniteDeGestion uniteDeGestionAssociee <- nil;
	list<float> listEnregistrementDebitEtiageParAnnee <- []; // attention liste dans un ordre le dernier rajouter correspond au debit de la derniere annee
	float sommeDebitAnneeCourante <- 0.0;
	list<equipementDeCaptageIRR> listPPA_UG <- [];	//liste des PPA
	map<string,int> mapFenetresTemporellesDebutPeriodeQuota <- map<string,int>([]); //ID periode ; date
	map<string,int> mapFenetresTemporellesFinPeriodeQuota <- map<string,int>([]);
	
	
	/*
	 * *****************************************************************************************
	 */			
	action initialisationUniteDeDefinitionDuVP{
		listPPA_UG <- equipementDeCaptageIRR inside(uniteDeGestionAssociee);
		if(!isEauDisponibleAgriInfinie){
			if (file_exists(cheminVP + nomFichierVP)){
				matrix Init <- matrix(csv_file(cheminVP +nomFichierVP,";",false));
				//matrix Init <- matrix(file(cheminVP +nomFichierVP));
				map<int,string> mapNomPeriode <- map([]);
				int nbLignes <- length(Init column_at 0);
				int nbPeriodeAllocationQuota <- 0;
				list ligneCourante <-  ( Init row_at (nbPeriodeAllocationQuota +1) );
				
				loop while:(!(ligneCourante contains ('###'))){
					put (ligneCourante at 0) in: mapNomPeriode at: nbPeriodeAllocationQuota;
					list<string> dateATransformer <- (string(ligneCourante at 1) split_with "/") ;
					int d <- 1;
					ask dateCour{
						d <- calculNbJourEcouleDansAnnee(int(dateATransformer at 0), int(dateATransformer at 1 ));
					}
					put d at: (ligneCourante at 0) in: mapFenetresTemporellesDebutPeriodeQuota;
					dateATransformer <- (string(ligneCourante at 2) split_with "/") ;
					ask dateCour{
						d <- calculNbJourEcouleDansAnnee(int(dateATransformer at 0), int(dateATransformer at 1 ));
					}
					put d at: (ligneCourante at 0) in: mapFenetresTemporellesFinPeriodeQuota;
					
					nbPeriodeAllocationQuota <- nbPeriodeAllocationQuota +1;
					ligneCourante <-  ( Init row_at (nbPeriodeAllocationQuota +1) );
				}
				loop i from:(nbPeriodeAllocationQuota +3) to: (nbLignes -1){
					ligneCourante <-  ( Init row_at i );
					string id_ppa <- ligneCourante at 0;
					ask listPPA_UG where (each.idEquipement=id_ppa) { 
						sonUniteDeDefinitionDuVP <- myself;
						
						loop numPeriode from:0 to: (nbPeriodeAllocationQuota -1){
							string idPeriode <- mapNomPeriode at numPeriode;
							put  float(ligneCourante at (numPeriode*4 + 1)) in: quota_anneePrec at:idPeriode ;
							put  float(ligneCourante at (numPeriode*4 + 2)) in: quota_moyen_par_ha_anneePrec at:idPeriode ;
							if((ligneCourante at (numPeriode*4 + 3)) = 'nan'){
								put -1 in: quotaDebit_anneePrec at: idPeriode;
							}else{
								put float(ligneCourante at (numPeriode*4 + 3)) in: quotaDebit_anneePrec at: idPeriode;
							}
							
							if((ligneCourante at (numPeriode*4 + 4)) = 'nan'){
								put -1 in: quotaDebit_moyen_par_ha_anneePrec at: idPeriode;
							}else{
								put float(ligneCourante at (numPeriode*4 + 4)) in: quotaDebit_moyen_par_ha_anneePrec at: idPeriode;
							}
						}
						
						loop idPeriode over: sonUniteDeDefinitionDuVP.mapFenetresTemporellesDebutPeriodeQuota.keys{
							put (quota_anneePrec at idPeriode) in: quota at: idPeriode;
							put (quota_moyen_par_ha_anneePrec at idPeriode) in: quota_moyen_par_ha at: idPeriode;
							put (quotaDebit_anneePrec at idPeriode) in: quotaDebit at: idPeriode;
							put (quotaDebit_moyen_par_ha_anneePrec at idPeriode) in: quotaDebit_moyen_par_ha at: idPeriode;
						}
					}
				}
				list<equipementDeCaptageIRR> listePPAAsupprimer <- [];
				ask listPPA_UG{
					if(sonUniteDeDefinitionDuVP = nil){
						listeEquipements >> self;
						write "le point de prelevement " + self.idEquipement + " n'a pas de quota ou n'est pas rattache a un ilot, il sera supprime";
						
						list<equipementDeCaptageIRR> liste <- (ressourceAssociee.mapEquipementsCaptageAssocies at IRR) as list<equipementDeCaptageIRR>;
						liste >> self;
						put liste in: ressourceAssociee.mapEquipementsCaptageAssocies at: IRR;
						
						liste <- (mapEquipementsDeCaptage at IRR) as list<equipementDeCaptageIRR>;
						liste >> self;
						put liste in: mapEquipementsDeCaptage at: IRR;
						
						listePPAAsupprimer << self;
						do die;								
					}
				}
				loop eq over: listePPAAsupprimer{
					listPPA_UG >> eq;
				}
			}else{
				unknown toto <- world.raiseWarning("fichier " + cheminVP + nomFichierVP + " manquant : un quota illimité sera affecté aux irrigants");
				isEauDisponibleAgriInfinie <- true;
			}
			
		}
		
		if(isEauDisponibleAgriInfinie){
			put 1 at: "ANNUEL" in: mapFenetresTemporellesDebutPeriodeQuota;
			put 366 at: "ANNUEL" in: mapFenetresTemporellesFinPeriodeQuota;
			ask listPPA_UG{
				sonUniteDeDefinitionDuVP <- myself;
			}
			
		}
		do allocationVPauxAgriculteurs;
	}		
		
	/*
	 * *****************************************************************************************
	 * On enregistre la somme du debit pedant la periode d'etiage pour chaque UG
	 */			
	action enregistrementDebitEtiage{
		// TODO : revoir les dates pour la periode d'etiage entre 01/07 et 31/10 ?
		bool isEnPeriodeEtiageAEAG <- false;
		ask dateCour{
			isEnPeriodeEtiageAEAG <- isDateCourantEntreDeuxDates(jourDebutEntree:premierJourEtiageAEAG, moisDebutEntree:premierMoisEtiageAEAG,jourFinEntree:dernierJourEtiageAEAG, moisFinEntree:dernierMoisEtiageAEAG);
		}
		
		if(isEnPeriodeEtiageAEAG and uniteDeGestionAssociee.pointNodalAssocie != nil){
			if(uniteDeGestionAssociee.pointNodalAssocie.debitJournalier > uniteDeGestionAssociee.pointNodalAssocie.doe){
				sommeDebitAnneeCourante <- sommeDebitAnneeCourante + (uniteDeGestionAssociee.pointNodalAssocie.debitJournalier - uniteDeGestionAssociee.pointNodalAssocie.doe);
			}
		}					
	}
			
	/*
	 * *****************************************************************************************
	 */			
	action allocationVPauxAgriculteurs{						
		if(isEauDisponibleAgriInfinie){
			ask listPPA_UG{
				loop idPeriode over: sonUniteDeDefinitionDuVP.mapFenetresTemporellesDebutPeriodeQuota.keys{
					put quantiteEauMaxDispoAgri in: quota at: idPeriode;
					put quantiteEauMaxDispoAgri in: quota_moyen_par_ha at: idPeriode;
					put -1 in: quotaDebit at: idPeriode;
					put -1 in: quotaDebit_moyen_par_ha at: idPeriode;
				}
			}
		}else{
			ask listPPA_UG{
				loop idPeriode over: sonUniteDeDefinitionDuVP.mapFenetresTemporellesDebutPeriodeQuota.keys{
					put (quota_anneePrec at idPeriode) in: quota at: idPeriode;
					put (quota_moyen_par_ha_anneePrec at idPeriode) in: quota_moyen_par_ha at: idPeriode;
					put (quotaDebit_anneePrec at idPeriode) in: quotaDebit at: idPeriode;
					put (quotaDebit_moyen_par_ha_anneePrec at idPeriode) in: quotaDebit_moyen_par_ha at: idPeriode;
				}
			}
		}
	}
	
	/*
	 * *****************************************************************************************
	 */
	action toString{
		write "******* " + name + " *******"; 
		write "uniteDeGestionAssociee = " + uniteDeGestionAssociee; 
		write "listEnregistrementDebitEtiageParAnnee = " + listEnregistrementDebitEtiageParAnnee;
		write "sommeDebitAnneeCourante = " + sommeDebitAnneeCourante;
		write "volumePrelevableTotal = " + volumePrelevableTotal;  
	}	
}

