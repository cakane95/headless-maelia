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
 *  planAssolementDonneesEntrees
 *  Author: Maroussia Vavasseur
 *  Description: Affecteu UN systeme de culture aux parcelles de lagri UNE seule fois (a linit)
 * 				 Il ny a pas de choix de plan a la fin dune rotation : on prend toujours le meme
 */

model planAssolementDonneesEntrees

import "../especeCultivee.gaml"
import "../Ilots/ilot.gaml"
import "../SystemesDeCultures/systemeDeCulture.gaml"

global{	
	/*
	 * Publique
	 * Creation de un plan par agri : 
	 */
	action constructionPlanAssolementDonneesEntrees{
		loop agriculteurCourant over: listeAgriculteurs{				
			create planAssolementDonneesEntrees{
				agri <- agriculteurCourant;
				add self to: agriculteurCourant.listePlans;	
				add self to: listePlansAssolement;
			}			
		}
	}	
}

species planAssolementDonneesEntrees parent: planAssolement{}
