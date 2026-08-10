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
 *  planAssolementFonctionsCroyances
 *  Author: Patrick Taillandier et Maroussia Vavasseur
 *  Description: L'agriculteur est amene a choisir chaque annee un plan d'assolement qui correspond a la liste exhaustive de tous ses choix possible d'assolement pour toute ses parcelles.
 * 				 Ainsi, un plan d'assolement va correspondre a un liste daffectation des rotations de culture aux parcelles.
 */

model planAssolementFonctionsCroyances

import "../Parcelles/parcelle.gaml"

global{
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */	
	action constructionPlanAssolementFonctionsCroyances{		
		loop agriculteurCourant over: listeAgriculteurs{
			map<bloc,systemeDeCultureDeReference> PlanInit <- map([]);
			loop b over: agriculteurCourant.listBloc {
				parcelle parc <- b.listeParcellesBloc[0];
				if ( parc.systemeDeCultureParcelle != nil) {
					put (parc.systemeDeCultureParcelle.sdcRefAssocie) at: b in: PlanInit; 
				}
			}
			create planAssolementFonctionsCroyances returns: nvP{
					SdCParBlocs <- PlanInit; 
					agri <- agriculteurCourant;
					add self to: agriculteurCourant.listePlans;	
					add self to: listePlansAssolement;
			}
			agriculteurFonctionsDeCroyances(agriculteurCourant).dernierPlan <- first (nvP);
		} 
	}
}

species planAssolementFonctionsCroyances parent: planAssolement {
	map<bloc,systemeDeCultureDeReference> SdCParBlocs <- map([]);


	/*
	 * *****************************************************************************************
	 * Doit renvoyer 1 en cas de plan réellement similaire !
	 */		
	float similaritePlan (map<bloc,systemeDeCultureDeReference> SdCParBlocsAEvaluer){
		
		float similarite <- 0.0;
		float cpt <- 0.0;
		loop b over: SdCParBlocs.keys{
			systemeDeCultureDeReference SdC1 <- SdCParBlocs at b;
			systemeDeCultureDeReference SdC2 <- SdCParBlocsAEvaluer at b;
			//calcul a l'aide de la matrice de Distance Culturale
			similarite <- similarite + float(matriceDistanceCulturale[int(SdC1.idSdc),int(SdC2.idSdc)]) * b.surfaceBloc;
			//cpt <- cpt +1;
			cpt <- cpt + b.surfaceBloc ;
		}
		return  (similarite/cpt);
	}	
}
