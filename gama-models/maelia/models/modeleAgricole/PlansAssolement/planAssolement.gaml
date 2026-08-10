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
 *  PlansAssolement
 *  Author: Maroussia Vavasseur
 *  Description: L'agriculteur est amene a choisir chaque annee un plan d'assolement qui correspond a la liste exhaustive de tous ses choix possible d'assolement pour toute ses parcelles.
 * 				 Ainsi, un plan d'assolement va correspondre a un liste daffectation des rotations de culture aux parcelles.
 */

model planAssolement

import "planAssolementFonctionsCroyances.gaml"
import "planAssolementDonneesEntrees.gaml"

global{
	list<planAssolement> listePlansAssolement <- [];
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionPlanAssolement{
		switch nomChoixAssolement {
        	match Donnees {
               do constructionPlanAssolementDonneesEntrees();  
            }
        	match FonctionsDeCroyances {
               do constructionPlanAssolementFonctionsCroyances();    
            }            
            default {
 
            }
        }
	}
}

// Abstract
species planAssolement {
	agriculteur agri <- nil; 
}
