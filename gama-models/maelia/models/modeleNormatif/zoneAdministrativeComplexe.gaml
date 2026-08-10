/***************************************************************************
 * MAELIA - http://maelia-platform.inra.fr/
 *    Copyright (C) 2014-2017 
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
* Name: zoneAdministrativeComplexe
* Author: lardyr
* Description: Gestion des ZA selon l'approche la plus frequente
*/

model zoneAdministrativeComplexe

import "zoneAdministrative.gaml"

global{
	int nbJoursMinPourNouvelleRestriction <- 3 const: true; // Il faut attendre 3 jours min pour pouvoir appliquer une nouvelle restriction
	int nbJoursMinPourBaisserRestriction <- 7 const: true; // Il faut attendre 7 jours pour pouvoir baisser de 1 niveau si il y a eu une amelioration
	
	action creationZonesAdministrativesComplexe{
		do creationZonesAdministratives(zoneAdministrativeComplexe);
	}
}

species zoneAdministrativeComplexe parent:zoneAdministrative{
	
	/*
	 * *****************************************************************************************
	 * // Les lachers sont fait de puis le gestionnaire de barrage
	 */			
	action gestionEtiage{	
		// RESTRICTIONS
		if(isEnCampagneEtiage){
			consoleDebug <- "";					
			// On ne peut baisser le niveau de l'arrete que si il y est depuis 7 jours
			// Si il y a une restriction en cours et que le debit courant s'est ameliore et a depasse le seuil max de la restriction alors on baisse d'un niveau (meme si le debit a depasse 2 seuils)							
			if(nbJoursMemeNiveauRestriction >= nbJoursMinPourBaisserRestriction 
				and (niveauDeRestriction > 0) 
					and (pointDeReferenceAssocie.qmj3 > (pointDeReferenceAssocie.mapDebitMaxParNiveauDeRestriction at niveauDeRestriction))){
				
				consoleDebug <- consoleDebug + '[gestionEtiage]  on baisse niveau \n';
				do interdictionPompage(niveauDeRestriction - 1);					
			// Pour faire ce traitement, il faut imperativement ne pas avoir d'arrete en cours si nbJoursMemeNiveauRestriction = 0 et sinon il faut attendre 3 jour si il y a un arrete 
			// De plus, il faut s'assurer que le debit courant est < au debit max de la restriction en cours, sinon entre 3 et 7 jours de restriction il serait possible de baisser le niveau : or �a n'est pas possbile
			}else if((nbJoursMemeNiveauRestriction = 0 and niveauDeRestriction = 0) 
						or nbJoursMemeNiveauRestriction >= nbJoursMinPourNouvelleRestriction 
							and (pointDeReferenceAssocie.qmj3 <= (pointDeReferenceAssocie.mapDebitMaxParNiveauDeRestriction at niveauDeRestriction))){
				
				consoleDebug <- consoleDebug + '[gestionEtiage]  on rentre dans gestion etiage \n';
				
				if(pointDeReferenceAssocie.qa < pointDeReferenceAssocie.qmj3 and pointDeReferenceAssocie.qmj3 <= pointDeReferenceAssocie.doe){
					consoleDebug <- consoleDebug + '[gestionEtiage]  qa < q < doe \n';											
//						do lacheBarrage();						
				}else if(pointDeReferenceAssocie.qar < pointDeReferenceAssocie.qmj3 and pointDeReferenceAssocie.qmj3 <= pointDeReferenceAssocie.qa){
					consoleDebug <- consoleDebug + '[gestionEtiage]  qar < q < qa \n';						
//						do lacheBarrage();
					if(!isBesoinAgricoleFort or isLacheBarrageEnCours() and isRealimentee()){																										
						if(pointDeReferenceAssocie.qmj3 > pointDeReferenceAssocie.qi){
							consoleDebug <- consoleDebug + '[gestionEtiage]  q < qi \n';
							do interdictionPompage(1);										
						}else{
							set consoleDebug <- consoleDebug + '[gestionEtiage]  qi < q \n';
							do interdictionPompage(2);
						}
					}				
				}else if(pointDeReferenceAssocie.dcr < pointDeReferenceAssocie.qmj3 and pointDeReferenceAssocie.qmj3 <= pointDeReferenceAssocie.qar){
					consoleDebug <- consoleDebug + '[gestionEtiage]  dcr < q < qar \n';						
//						do lacheBarrage();	
					do interdictionPompage(3);						
				}else if(pointDeReferenceAssocie.qmj3 <= pointDeReferenceAssocie.dcr){
					consoleDebug <- consoleDebug + '[gestionEtiage]  q < dcr \n';
//						do lacheBarrage();		
					do interdictionPompage(4);						
				}		
			}else{
				consoleDebug <- consoleDebug + '[gestionEtiage]  on fait rien (nbJoursMemeNiveauRestriction + 1) = ' + (nbJoursMemeNiveauRestriction + 1) + '\n';
				nbJoursMemeNiveauRestriction <- nbJoursMemeNiveauRestriction + 1;
			}					
							
			// Si la zone aval est en restriction : il faut que le niveau de la ZA courante soit >= niv -1 de la ZA avale
			// On ne force le niveau de la ZA courante que si il est strictement < a celui de la ZA aval (car si le niveau de la ZA courante >= niveau de la ZA aval alors on ne prend pas en compte)
			// Si le debit de la ZA courante est > au debit max alors aucun traitement n'est necessaire					
			if(zoneAdministrativeAval != nil and zoneAdministrativeAval.niveauDeRestriction > (niveauDeRestriction + 1)){				
				consoleDebug <- consoleDebug + '[gestionEtiage]  za aval en restriction sup \n';									
				do interdictionPompage(zoneAdministrativeAval.niveauDeRestriction - 1);					
			}
		}
	}	
	//write consoleDebug;	
}
