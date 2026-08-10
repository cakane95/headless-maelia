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
*  resultatsSuivi_ajot_pools_residus
*  Author: Jean Villerd
*  Description: 
 */

model resultatsSuivi_ajout_pools_residus

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	
	map<string,int> numColPools <- [
		"annee"::0,
		"date"::1,
		"parcelle"::2,
		"exploitation"::3,
		"culture"::4,
		"situation"::5,
		"masseC"::6,
		"masseN"::7,
		"ratioCN"::8,
		"nomProduit"::9,
		"resType"::10,
		"poolType"::11,
		"Kres"::12,
		"Hres"::13,
		"CNbio"::14,
		"Yres"::15
	];
	
	action initialisationSuivi_ajouts_pools_residus{
	
		// toutes les OT sont à mémoriser
		//listOTAMemoriser <- listOT;
	
        do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers suivi_ajout_pools_residus.';           
        
        create resultatsSuivi_ajout_pools_residus number: 1{
              do initialisation();
              listesFichiersAcreer << self;
        }
	}			
}


species resultatsSuivi_ajout_pools_residus parent: ecritureResultats{




//
//	/*
//	 * @Overwrite
//	 */
	 string initialisationFinAnnuel{			
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/suivi_ajout_pools_residus'+ nomDeLaSimulation + '.csv';
		string entete <- 'annee;date;parcelle;exploitation;culture;situation;masse_C[kg/ha];masse_N[kg/ha];ratio_CN;nom_produit;type_residu;type_pool;Kres;Hres;CNbio;Yres\n';
		return entete;
	 }


	list<string> ecritureFinAnnuelle{
		list<string> output <- [];
		// faire une boucle autour des parcelles qui sont dans la liste
		// Aller chercher le nombre de pools ajouté par la parcelle (longueur de la liste)
		loop parc over:  listeParcellesUtiles{
			string idExploitation <- parc.ilot_app.codeExploitationAssociee;
			if length(parcelleAqYieldNC(parc).sorties_resType) > 0 {  //marche pas
				loop i from: 0 to: (length(parcelleAqYieldNC(parc).sorties_resType) - 1) { 
					list<string> aEcrire <- list_with(length(numColPools),""); // Liste pour une ligne
		    		aEcrire[numColPools["annee"]] <- string(dateCour.annee);
		    		aEcrire[numColPools["date"]] <- string(parcelleAqYieldNC(parc).sorties_dateAjout[i]);
		    		aEcrire[numColPools["parcelle"]] <- parc.idParcelle;
		    		aEcrire[numColPools["exploitation"]] <- idExploitation;
		    		aEcrire[numColPools["culture"]] <- parcelleAqYieldNC(parc).sorties_culture[i];
		    		aEcrire[numColPools["situation"]] <- parcelleAqYieldNC(parc).sorties_situationRes[i];
		    		aEcrire[numColPools["masseC"]] <- string(parcelleAqYieldNC(parc).sorties_masseC[i]);
		    		aEcrire[numColPools["masseN"]] <- string(parcelleAqYieldNC(parc).sorties_masseN[i]);
		    		aEcrire[numColPools["ratioCN"]] <- string(parcelleAqYieldNC(parc).sorties_CNres[i]);
		    		aEcrire[numColPools["nomProduit"]] <- parcelleAqYieldNC(parc).sorties_nomProduit[i];
		    		aEcrire[numColPools["resType"]] <- parcelleAqYieldNC(parc).sorties_resType[i];
		    		aEcrire[numColPools["poolType"]] <- parcelleAqYieldNC(parc).sorties_poolType[i];
		    		aEcrire[numColPools["Kres"]] <- string(parcelleAqYieldNC(parc).sorties_Kres[i]);
		    		aEcrire[numColPools["Hres"]] <- string(parcelleAqYieldNC(parc).sorties_Hres[i]);
		    		aEcrire[numColPools["CNbio"]] <- string(parcelleAqYieldNC(parc).sorties_CNbio[i]);
		    		aEcrire[numColPools["Yres"]] <- string(parcelleAqYieldNC(parc).sorties_Yres[i]);
		    		loop j over: aEcrire{
		    			output <+ j;
		    			output <+ ";";
		    		}
					remove index:length(output)-1 from:output; // supprime le dernier ;					
					output <+ "\n";
				}
			}
			parcelleAqYieldNC(parc).sorties_dateAjout <- [];
			parcelleAqYieldNC(parc).sorties_situationRes <- [];
			parcelleAqYieldNC(parc).sorties_masseC <- [];
			parcelleAqYieldNC(parc).sorties_masseN <- [];
			parcelleAqYieldNC(parc).sorties_CNres<- [];
			parcelleAqYieldNC(parc).sorties_nomProduit<- [];
			parcelleAqYieldNC(parc).sorties_resType <- [];
			parcelleAqYieldNC(parc).sorties_poolType <- [];
			parcelleAqYieldNC(parc).sorties_Kres<- [];
			parcelleAqYieldNC(parc).sorties_Hres<- [];
			parcelleAqYieldNC(parc).sorties_CNbio<- [];
			parcelleAqYieldNC(parc).sorties_Yres<- [];
			parcelleAqYieldNC(parc).sorties_culture <- [];
						
		}
		return output;
	}
}


