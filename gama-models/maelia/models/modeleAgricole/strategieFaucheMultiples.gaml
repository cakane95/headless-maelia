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
 *  strategieFaucheMultiple
 *  Author: Renaud Missli,
 *  Description: 
 */

model strategieFaucheMultiple

import "Ilots/ilot.gaml"
import "strategieFauche.gaml"

global{}

species strategieFaucheMultiples parent: strategieFauche {
	strategieFauche strategieFauche_parent;

	/*
	 * *****************************************************************************************
	 */
	action miseEnOeuvreActivite (parcelle parc, agriculteur agri, int idGroupe, float surfaceIrrigueeEntree){
		parc.cpt_fauche <- 0;
//		write "réalisation fauche";
		//add self to: parc.OTFaucheMultiplesEffectuee;
		do ecritureDebugActivite(parc);
		
		ask cultureHerbSim(parc.cultureParcelle.monModelDeCulture) {
			do updateHerbeFauche(myself.hauteurCoupe);
		}

		// JV 140121 stocke uniquement si utile
		if parc.memoireOTsurParcelle.keys contains FAUCHE {
			ask parc{
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at FAUCHE);
				float rendement_herbe <- cultureHerbSim(parc.cultureParcelle.monModelDeCulture).Yield / 1000; //[t/ha]
				float bm_restit <-  cultureHerbSim(parc.cultureParcelle.monModelDeCulture).biomasse_aer_restit_fauche / 1000; // [t/ha]
				
				map<string,string> complements <- [];
				
				if (nomChoixModeleCroissancePrairie = 'HerbSimNC'){ // Enregistrement du N et C exporté dans suiviOTParParcelle
					float rdt_n <-  cultureHerbSim(parc.cultureParcelle.monModelDeCulture).N_export_fauche;
					float rdt_c <-  cultureHerbSim(parc.cultureParcelle.monModelDeCulture).C_export_fauche;
					complements <- ["rendement"::string(rendement_herbe with_precision nb_decimales_sorties),"restitutions"::string(bm_restit with_precision nb_decimales_sorties),"exportationsN"::string(rdt_n with_precision nb_decimales_sorties),"exportationsC"::string(rdt_c with_precision nb_decimales_sorties)];
				
				} else {
					complements <- ["rendement"::string(rendement_herbe with_precision nb_decimales_sorties),"restitutions"::string(bm_restit with_precision nb_decimales_sorties)];
				}

				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at FAUCHE);	
			}
		}
//		write 'HERBSIM Renaud - mise en oeuvre Fauche';
		
		// Variables ibio
		if (sorties_iBio) {
			parc.n_coupes_fauches <- parc.n_coupes_fauches + 1;
		}
	}
}	

