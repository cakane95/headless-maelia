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
 *  parcelleHorsZone
 *  Author: Maroussia Vavasseur
 *  Description: 	Les agents parcelleHorsZone sont les parcelles appartenant aux agents ilotHorsZone. Cette classe est issue de la classe parcelle. 
 * 					Les actions redefinies le sont en faisant de grandes simplifications.
 */

model parcelleHorsZone

import "../../modeleAgricole/Ilots/ilot.gaml"

global{	
	string parcellesAqYieldShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/ilots/horsZone/parcelles_HZ.shp';
	list<parcelleHorsZone> listeParcellesHorsZone <- [];

	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action creationParcelleHorsZone{
		if !file_exists(parcellesAqYieldShape)	{do raiseError("fichier inexistant: " + parcellesAqYieldShape);}
		//if !is_shape(parcellesAqYieldShape)		{do raiseError("le fichier " + parcellesAqYieldShape + " n'est pas un fichier shape");}	
		listeParcellesHorsZone <- lectureFichierParcelle(cheminEntree:parcellesAqYieldShape, typeParcelle:parcelleHorsZone, creationHorsZone: true) as list<parcelleHorsZone>;		
	}				
}

species parcelleHorsZone parent: parcelle {	
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 */
	action initialisationParcelle {
		// Si un Sdc est def, alors la parcelle est simulee (sinon elle est tuee car na normalement que des prairies permanantes dessus, et comme pour les parcelles HZ on ne simule pas lhydro)
		if((mapSystemesDeCultureDeRef at idSdcRef) != nil){
			listeParcellesUtiles << self;
			name <- idParcelle + '_HZ';
			isParcelleHorsZone <- true;
			isParcelleUtile <- true;				
			ilot_app.listeParcelles << self;
			//mapIndiceDepartRotation <- [1::rnd(0), 2::rnd(1), 3::rnd(2), 4::rnd(3)]; // taille rotation :: indice de depart dans la rotation	//Si choix assolement par fonction croyance : on place lindice de depart alealoirement
			do initDerniereProd();
			do initMemoireDateOT();
		}else{
			ask self{
				do die();
			}
		}
	}
					
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * C'est l'eau totale qui ressort en surface apres la croissance de la plante
	 */
	float calculQuantiteEauDeRuissellement{return 0.0;}


	/*
	 * *****************************************************************************************
	 * @Overwrite
	 *  Appellee dans strategie dirrigation
	 * Pour le moment, on considere que les parcelles hos zone sont jamais en stress
	 */	
	bool isEnStressHydrique{	
		return false;
	}
	
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Appelee dans strategie de recolte
	 * On prend le rendement de la pacelle de la ZM la plus proche (avec le meme culture) et qui est deja recoltee : PB ! il peut ne pas y avoir de parcele de ce type!!
	 */
	float calculRendement {
		float rendement <- 0.0;			
		if(getITKAnnee() != nil){		
			if(getITKAnnee().especeCultiveeITK != nil){	
				ask(ilot_app.agriculteurAssocie){
					rendement <- mapRendementMoyenParCulture at myself.getITKAnnee().especeCultiveeITK;
				}
			}			
		}
		return rendement;
	}
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 */
	float getHumiditeSol{
		return 0.0;
	}				
}	


