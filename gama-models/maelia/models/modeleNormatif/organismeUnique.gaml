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
 *  organismeUnique
 *  Author: Maelia
 *  Description: Il edicte chaque ann�e le VP � allouer � chaque agriculteur.
 */

model organismeUnique

import "uniteDeDefinitionDuVP.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleHydrographique/equipementDeCaptageIRR.gaml"

global{

	/* 
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionOrganismeUnique{
		create species: organismeUnique number: 1;
	}	
}

species organismeUnique{

	/*
	 * *****************************************************************************************
	 */	
	action comportementJournalier{	
		ask (uniteDeDefinitionDuVP as list){
			do enregistrementDebitEtiage;
		}
	}

	/*
	 * *****************************************************************************************
	 */	
	action comportementAnnuel{	
		ask (uniteDeDefinitionDuVP as list){
			do allocationVPauxAgriculteurs;
		}
		if(isEauDisponibleAgriInfinie){
			ask listeAgriculteurs{
				eau_disponible <- quantiteEauMaxDispoAgri;
			}
		}else{
			// Calculer quota irrigation / agri
			ask listeAgriculteurs{
				eau_disponible <- 0.0;
				
				loop uVP over: (uniteDeDefinitionDuVP as list){
					loop idPeriode over: uVP.mapFenetresTemporellesDebutPeriodeQuota.keys{
						map<string, float> quotaParPPA_nonCollectif<- map<string, float>([]);// cle: ID du PPA ; value : quota
						map<string, float> quotaParPPA_Collectif<- map<string, float>([]);// cle: ID du PPA ; value: surface
						loop il over: sonExploitation.listeIlots{
							ask il.listeEquipementsCaptagesAssocies.keys{
								if(sonUniteDeDefinitionDuVP = uVP){ // si il appartient a l UG
									if(isASA){
										put il.surfaceParcellesUtiles at: idEquipement in: quotaParPPA_Collectif ;
									}else{
										put (quota at idPeriode) at: idEquipement in: quotaParPPA_nonCollectif ;
									}
								}
								
							}
						}
						
						loop  qq over: quotaParPPA_nonCollectif.values{
							eau_disponible <- eau_disponible + qq;
						}
						
						loop  idEq over: quotaParPPA_Collectif.keys{
							equipementDeCaptageIRR eq <- first (equipementDeCaptageIRR where (each.idEquipement = idEq));
							eau_disponible <- eau_disponible + (quotaParPPA_Collectif at idEq)/10000.0 * (eq.quota_moyen_par_ha at idPeriode);
						}
						
					}
				}
				
				eau_quotaExploitation <- eau_disponible; 
			}
			
		}
		
	}

	/*
	 * *****************************************************************************************
	 */
	action toString{
		write "******* " + name + " *******"; 
		ask (uniteDeDefinitionDuVP as list){
			do toString;
		}
	}
}
