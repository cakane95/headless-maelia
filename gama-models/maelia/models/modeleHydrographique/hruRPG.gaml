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
 *  hruRPG
 *  Author: Maroussia Vavasseur
 *  Description: Une HRU rpg est un decoupage de la ZH en zone non georeferencees crees en fonction de : (pente,surface,clc), dans lequel on ne prend en compte que les ilots.
 * 				 Ainsi, on va avoir autant de hruRPG qu'il y a de type de sol differents pour les ilots de la ZH associee (si on considere que la pente est la meme pour toutes les HRU).
 */

model hruRPG

import "zoneHydrographique.gaml"

global{

	/*
	 * *****************************************************************************************
	 * Publique
	 * Une HRUrpg, meme si elle est tres petite, va etre gardee telle quel.
	 * A la difference dune HRU classique, elle est composee dilot (georeferences), il faut tous les traiter de maniere dissociee.
	 */ 
	action constructionHRUsRPG{	
		ask listeZonesHydrographiques{
			loop ilotCourant over: listeIlotsAssocies{				
				if(ilotCourant.sol != nil and ilotCourant.surfaceParcellesUtiles > 0.0){					
					hruRPG hruRPGassocieeTemp <- first(zoneHydrographiqueSWAT(self).listeHRUrpgAssociees where ((each.sol = ilotCourant.sol) and (each.penteAssociee = ilotCourant.penteSwat)));
					
					// Si la HRU deja cree
					if( hruRPGassocieeTemp != nil){	
						ask hruRPGassocieeTemp{							
							add ilotCourant to: listeIlotsAssocies;
							surface <- surface + ilotCourant.surfaceParcellesUtiles;
							fractionDansZH <- surface / zh.shape.area;
						}
						ilotCourant.hruRPGassociee <- hruRPGassocieeTemp;								
					}else{
						create hruRPG{						
							zh <- (myself as zoneHydrographiqueSWAT);
							surface <- ilotCourant.surfaceParcellesUtiles;
							fractionDansZH <- surface / zh.shape.area;
							sol <- ilotCourant.sol;	
							penteAssociee <- ilotCourant.penteSwat;	
							idHRU <- zh.idZoneHydrographique + "_" + sol.nom + "_" + penteAssociee;	
							add ilotCourant to: listeIlotsAssocies;			
							add self to: zh.listeHRUrpgAssociees;									
							do initialisationHRU();	
						}											
						ilotCourant.hruRPGassociee <- last(hruRPG as list);	 // attribut Ilot													
					}														
				}else{
					write '' + ilotCourant.id + ' - [HRUrpg/init] Type de sol nul !!!!! ' + idZoneHydrographique;
				}				
			}			
		}
		
		//La correction des sommes de fractions des HRUs aura lieu dans l'initialisation des HRU!
		
		
//		/*
//		 * DEBUG
//		 */	
//		let somme type: float value: 0.0;
//		let sommeFraction type: float value: 0.0;
//	
//		ask listeZonesHydrographiques{	
//			ask zoneHydrographiqueSWAT(self).listeHRUrpgAssociees{
//				set somme value: somme + surface;
//				set sommeFraction value: sommeFraction + fractionDansZH;
//			}
////			write '[HRURPG/Init] ZH = ' + name + ' sommeFraction ZH = ' + (shape.area - surfaceZhSansIlots) / shape.area;					
//		}
//		write '[HRURPG/Init] ZH = ' + name + ' sommeSurface = ' + somme;		
//		write '[HRURPG/Init] ZH = ' + name + ' sommeFraction = ' + sommeFraction/length(listeZonesHydrographiques);			
//		
//		let somme type: float value: 0.0;
//		let sommeFraction type: float value: 0.0;
//		ask listeZonesHydrographiques{	
//			ask zoneHydrographiqueSWAT(self).listeHRUAssociees{
//				set somme value: somme + surface;
//				set sommeFraction value: sommeFraction + fractionDansZH;
//								
////				if(fractionDansZH * 100 < 5.0){
////					write '[HRU/Init] ' + name + ' fractionDansZH = ' + fractionDansZH * 100;			
////				}									 
//			}
////			write '[HRU/Init] ZH = ' + name + ' sommeSurface = ' + somme ;	
////			write '[HRU/Init] ZH = ' + name + ' surfaceZhSansIlots = ' + surfaceZhSansIlots;		
////			write '[HRU/Init] ZH = ' + name + ' shape.area = ' + shape.area;				
//		}
//		write '[HRU/Init] ZH = ' + name + ' sommeSurface = ' + somme ;											
//		write '[HRU/Init] ZH = ' + name + ' sommeFraction = ' + sommeFraction /length(listeZonesHydrographiques);			
	}
}

species hruRPG parent: hru{
	list<ilot> listeIlotsAssocies <- [];
	map<string, hru> mapHrusHydroAssociees <- map([]); // typeClasseClc::hruCorrepsondante
	float humiditeHorizonTotal <- 0.0; // JV 280618 pour calcul SwFin (récupéré en [m3] depuis les îlots mais converti en [mm] dans calculHumiditeHorizonTotal)
	

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 */	
	action initialisationHRU{	
		clcAssocie <- first(zh.landCoverAssocie where (each.typeClasse = RPG)); // ne peut pas etre nul !
	
		// Hru bati correpsondante
		hru hruHydroAssocieeBati <- first((zh.listeHRUAssociees) where ((each.clcAssocie.typeClasse = BATI) and (each.sol = sol) and (each.penteAssociee = penteAssociee)));
		put hruHydroAssocieeBati at: BATI in: mapHrusHydroAssociees;
		// Hru foret correspondante
		hru hruHydroAssocieeForet <- first((zh.listeHRUAssociees) where ((each.clcAssocie.typeClasse = FORET) and (each.sol = sol) and (each.penteAssociee = penteAssociee)));
		put hruHydroAssocieeForet at: FORET in: mapHrusHydroAssociees;		
	}

	/*
	 * *****************************************************************************************
	 * Juste avant la disparition des ilots (sinon, je ne peux plus connaitre les surface et autre de lilot qui nexiste plus) !!
	 * TODO : voir le cas ou la HRU a augmenter nexiste pas (prendre celle la plus proche de lilot)
	 */	 
	action miseAJourFractionHRUs(map<string,list<ilot>> mapIdClasse){	
		// On boucle sur les different type qui vont prendre la place des ilots
		loop typeClasseClc over: mapIdClasse.keys{
			// Liste des ilots de la zh qui doivent disparaitre cette annee	au profit de idClasseClc
			list<ilot> listeIlotsAdisparaitreZH value: mapIdClasse at typeClasseClc;
			// liste des ilots de la hru qui doivent disparaitre cette annee au profit de idClasseClc
			list<ilot> listeIlotsAdisparaitreHRU value: listeIlotsAdisparaitreZH inter listeIlotsAssocies;
							
			// On met a jour la liste des ilots de la hruRPG
			let sommeSurfaceIlotsAdisparaitre type: float value: 0.0;
			loop ilotCourant over: listeIlotsAdisparaitreHRU{					
				set sommeSurfaceIlotsAdisparaitre value: sommeSurfaceIlotsAdisparaitre + ilot(ilotCourant).shape.area;
				remove ilotCourant from: listeIlotsAssocies;
			}
			// On met a jour la fraction de la hruRPG
			set surface value: surface - sommeSurfaceIlotsAdisparaitre;	
			set fractionDansZH value: surface / zh.shape.area;	
			// On met a jour la fraction de la hruHydro de la ZH dont le type de sol, le clc (= idClasseClc) et la pente sont le meme que la hruRPG courante
			hru hruHydroComplementaire <- mapHrusHydroAssociees at typeClasseClc;
			hruHydroComplementaire.surface <- hruHydroComplementaire.surface + sommeSurfaceIlotsAdisparaitre;
			hruHydroComplementaire.fractionDansZH <- hruHydroComplementaire.surface / zh.shape.area;	
		}	
		
		if(surface < zeroApproche){
			remove self from: zh.listeHRUrpgAssociees;	
			do die;
		}			
	}

	/*
	 * *****************************************************************************************
	 * Cette methode va faire executer le processus de croiassance des plantes des parcelles appartenants a la HRU
	 * On doit faire anisi, car on calcul dans la boucle des ZH le volume reel a irriguer sur les parcelles (irrigationReelle est mis a jour juste avant)
	 */	
	action croissancePlanteHRU{
		ask listeIlotsAssocies{
			do croissancePlante();
		}
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE sol : 2 -Methode renvyant la quantite deau de ruissellement mise a jour par les ilots de la HRU et qui va ensuite vers le cour deau principal
	 */	
	float calculRuissellementDeSurface{
		// Il faut sommer des volumes (et non des hauteurs deau) 
		// La quantite rajoutee par les ilots est un volume [m3], or la quantite a rejettee dans la ZH est une hauteur en mm	
		if(surface > zeroApproche and ruissellementDeSurfaceHRU > zeroApproche){
			ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU / surface * nombreMillimetreDansUnMetre; // [mm]
		}else{
			ruissellementDeSurfaceHRU <- 0.0;
		}
		return ruissellementDeSurfaceHRU; // [mm]
	}	

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE sol : 2 -on ne la calcul pas dans la hru pour le RPG
	 */	
	float calculEcoulementLateral{return 0.0;}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE sol : 3 -on ne la calcul pas dans la hru pour le RPG
	 */	
	float calculEvapotranspirationReelle{
		if(surface > zeroApproche and evapoTranspirationReelle > zeroApproche){
			evapoTranspirationReelle <- evapoTranspirationReelle / surface * nombreMillimetreDansUnMetre; // [mm]
		}else{
			evapoTranspirationReelle <- 0.0;
		}				
		return evapoTranspirationReelle;
	}

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * PHASE sol : 2 - renvoie l'humidite de l'horizon total (variable TotAWC de AqYield: http://maelia-platform.inra.fr/modeles/processus-agricoles/dynamique-sol-culture-2/dynamique-sol-culture/)
	 * agrégé au niveau de la HRU RPG et en [mm]
	 */	
	float calculHumiditeHorizonTotal{
		// Il faut sommer des volumes (et non des hauteurs deau) 
		// La quantite rajoutee par les ilots est un volume [m3], or la quantite a rejettee dans la ZH est une hauteur en mm	
		if(surface > zeroApproche and humiditeHorizonTotal > zeroApproche){
			humiditeHorizonTotal <- humiditeHorizonTotal / surface * nombreMillimetreDansUnMetre; // [mm]
		}else{
			humiditeHorizonTotal <- 0.0;
		}
		return humiditeHorizonTotal; // [mm]
	}	

	/*
	 * *****************************************************************************************
	 * PHASE sol : 	4 - Mise a jour de la quantite deau dentree pour le calcul du base flow
	 * 					Le calcul de de lecoulement des eaux souterraines (base flow) se fait avec la meme methode que pour les hru classiques
	 */	
	action miseAJourEauEntreePourCalculEcoulementSouterrain{	
		// Il faut sommer des volumes (et non des hauteurs deau) 
		// La quantite rajoutee par les ilots est un volume [m3], or la quantite a rejettee dans la ZH est une hauteur en mm	
		if(surface > zeroApproche and getPercolationDerniereCouche() > zeroApproche){
			float eauDernierCouche <- getPercolationDerniereCouche();
			do setPercolationDerniereCouche(eauDernierCouche / surface * nombreMillimetreDansUnMetre);// [mm]
			}else{
				do setPercolationDerniereCouche(0.0);
			}
		}
 
 		/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Remise a zero de certains attributs pour le jour suivant
	 */	 		
	action remiseAzero{					
		ruissellementDeSurfaceHRU <- 0.0;
		ecoulementLateral <- 0.0;
		evapoTranspirationReelle <- 0.0;
		// ecoulementEauSouterraine <- 0.0;  //  JV 030918
		humiditeHorizonTotal <- 0.0;		
		do setPercolationDerniereCouche(0.0);
	}
	 /*
	 * *****************************************************************************************
	 * @Overwrite
	 */	 		
	float addRevapEauDerniereCouche (float eau){
		float eauNonTransmissible <- 0.0; //Water that cannot be put to the last soil layer
										 // due to water saturation
		float sommeSurface <- 0.0;
		ask listeIlotsAssocies{
			ask listeParcelles{
				sommeSurface <-sommeSurface + surface;
				eauNonTransmissible <- eauNonTransmissible + addRevapparcelle(eau)*surface;
			}
		}
		eauNonTransmissible <- eauNonTransmissible/sommeSurface;			
		return eauNonTransmissible;
	}
	

	/*
	 * *****************************************************************************************
	 * @Overwrite
	 * Debug
	 */
	string toString{
		string resultat <- "******* " + name + " *******"; 
		resultat <- resultat + ' zh  : ' + zh;
		resultat <- resultat + ' ruissellementDeSurfaceHRU : ' + ruissellementDeSurfaceHRU;
		resultat <- resultat + ' curveNumber : ' + curveNumber;
		return resultat;
	}

    	// JV 250419 renvoie la somme des volumes d'irrigations en [m3] sur les parcelles associées, utilisée dans ZoneHydroSWAT.checkBilanSol
    	float getVolumeIrrigationSurParcellesAssociees{
    		float res <- 0.0;
    		ask listeIlotsAssocies{
    			ask listeParcelles{
    				res <- res + irrigationReelle/nombreMillimetreDansUnMetre * surface; // irrigationReelle en [mm]  
    			}
    		}
    		return res;
    	}

}	


