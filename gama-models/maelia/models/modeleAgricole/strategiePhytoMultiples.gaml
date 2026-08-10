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
 *  strategieBinage
 *  Author: Maroussia Vavasseur
 *  Description: 
 */

model strategiePhyto

import "Ilots/ilot.gaml"

global{}

species strategiePhytoMultiples parent: strategiePhyto {
	strategiePhyto strategiePhyto_parent;
	float doseParHectare <- 0.0;
	string type_phyto;
		
	
	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains PHYTO {				 		
			ask parc{
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at PHYTO);
			}
		}	
		add self to: parc.OTPhytoMultiplesEffectuee;
		do ecritureDebugActivite(parc);
		
		// Inscription en mémoire des données concernant ibio si activé
		if (sorties_iBio) {
			do sauvegarde_donnees_ibio(parc);
		}

	}
}	

