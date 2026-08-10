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
 *  resultatsSuiviITKParPArcelle
 *  Author: JV
 *  Description: 
 */

model resultatsSuiviITKParParcelle

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/materielIrrigation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "ecritureResultats.gaml"


global{
	
	map<string,int> numCol <- [
		"annee"::0,
		"date"::1,
		"parcelle"::2,
		"exploitation"::3,
		"culture"::4,
		"ITK"::5,
		"OT"::6,
		"temps"::7,
		"prof"::8,
		"rendement"::9,
		"risqueEchaudage"::10,
		"impactGel"::11,
		"irrigDose"::12,
		"irrigReelle"::13,
		"fertiNCproduit"::14,
		"fertiNCnature"::15,
		"fertiNCAnnulee"::16,
		"fertiNCdoseBruteOrg"::17,
		"fertiNCapportNminTheorique"::18,
		"fertiNCapportNminReel"::19,
		"fertiNCapportNorg_labile"::20,
		"fertiNCapportNorg_recalcitrant"::21,
		"exportations"::22,
		"restitutions"::23,
		"racines"::24,
		"exportationsN"::25,
		"exportationsC"::26,
		"id_lot"::27,
		"nb_ugb"::28,
		"duree_pature"::29,
		"herbe_consommee"::30
	];
	
	action initialisationEcritureFichiersSuiviITKParParcelle{
	
		// toutes les OT sont à mémoriser
		//listOTAMemoriser <- listOT;
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suiviOTParParcelle.';           
        
        create resultatsSuiviITKParParcelle number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuiviITKParParcelle parent: ecritureResultats{

	/*
	 * @Overwrite
	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/suiviOTParParcelle'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;date;parcelle;exploitation;culture;ITK;OT;temps[h];profondeur[cm];RECOLTE_rendement[t/ha];RECOLTE_risqueEchaudage[%];RECOLTE_impactGel[%];IRRIGATION_dose[mm];IRRIGATION_reelle[mm];FERTI_produit;FERTI_nature;FERTI_annulee;FERTI_doseBruteOrg[kg/ha];FERTI_apportNminTheorique[kg/ha];FERTI_apportNminReel[kg/ha];FERTI_apportNorg_labile[kg/ha];FERTI_apportNorg_recalcitrant[kg/ha];BIOMASSE_export[t/ha];BIOMASSE_aer_restit[t/ha];BIOMASSE_rac_restit[t/ha];N_export[kg/ha];C_export[kg/ha];id_lot;nb_ugb;duree_pature[j];herbe_consommee[kg]\n';
		return entete;
	 }

	/*
	 * @Ecriture
	 */
	list<string> ecritureFinAnnuelle{
		//list<string> aEcrire <-  list_with(length(numCol),""); // liste de numCol éléments initialisés à ""
		list<string> output <- [];

		loop parc over:  listeParcellesUtiles{
		
			string idExploitation <- parc.ilot_app.codeExploitationAssociee;
						
			loop ot over: parc.memoireOTsurParcelle.keys{
				map<int, itk> opParDate <- parc.memoireOTsurParcelle at ot;
				loop d over: opParDate.keys{
					list<string> aEcrire <-  list_with(length(numCol),""); // liste de numCol éléments initialisés à ""
					aEcrire[numCol["annee"]] <- string(dateCour.annee);
					aEcrire[numCol["date"]] <- string(d);
					aEcrire[numCol["parcelle"]] <- parc.idParcelle;
					aEcrire[numCol["exploitation"]] <- idExploitation;
					aEcrire[numCol["culture"]] <- opParDate[d].especeCultiveeITK.idEspeceCultivee;
					aEcrire[numCol["ITK"]] <- opParDate[d].idITK;
					aEcrire[numCol["OT"]] <- ot;
					if parc.memoireOTsurParcelleTemps[ot][d]!=nil {aEcrire[numCol["temps"]] <- string(parc.memoireOTsurParcelleTemps[ot][d] with_precision nb_decimales_sorties);} // temps (nil pour RECOLTE_FORCEE et SEMIS_FORCEE)					
					map<string,string> complements <- parc.memoireOTsurParcelleComplements[ot][d];
					if complements["fertiNCdoseBrute"]="-1.0" {complements["fertiNCdoseBrute"] <- "";} // fertiNCdoseBrute inconnue pour les produits minéraux					
					
					if complements!=nil {
						loop comp over: complements.keys {
							aEcrire[numCol[comp]] <- complements[comp];
						}
					}	
					// chaine a partir de la liste
					loop i over: aEcrire {
						output <+ i;
						output <+ ";";
					}
					//chaine <- replace_regex(chaine,";$",""); // supprime le dernier ; (https://regex101.com/r/6ktNbp/1)
					remove index:length(output)-1 from:output; // supprime le dernier ;					
					output <+ "\n";
				}
			}
		}
		//chaine <- replace_regex(chaine,"\n$","");
//		if last(output) = '\n'{
//			remove index: length(output)-1 from:output;
//		}
		return output;
	}			

	string ecritureFinAnnuelleSAUV{
		string aEcrire <-  "";

		loop parc over:  listeParcellesUtiles{
		
			string idExploitation <- parc.ilot_app.codeExploitationAssociee;
						
			loop ot over: parc.memoireOTsurParcelle.keys{
				map<int, itk> opParDate <- parc.memoireOTsurParcelle at ot;
				loop d over: opParDate.keys{
					aEcrire <- "" + aEcrire + dateCour.annee + ";" + d + ";" + parc.idParcelle + ";" + idExploitation + ";" + opParDate[d].especeCultiveeITK.idEspeceCultivee + ";" + opParDate[d].idITK + ";" + ot + ";";
					if parc.memoireOTsurParcelleTemps[ot][d]!=nil {aEcrire <- aEcrire + parc.memoireOTsurParcelleTemps[ot][d] + ";";} // temps (nil pour RECOLTE_FORCEE et SEMIS_FORCEE)
					if parc.memoireOTsurParcelleComplements[ot][d]!=nil {aEcrire <- aEcrire + parc.memoireOTsurParcelleComplements[ot][d];} // compléments
					aEcrire <- aEcrire + "\n";
				}
			}
		}
		return aEcrire;
	}			

}
