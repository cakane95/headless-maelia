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
 *  RetenuesCollinaires
 *  Author: Maroussia Vavasseur
 *  Description: Ouvrages de stockage de l'eau qui sont remplies par les eaux de surface, les eaux de ruissellement. Elles sont utilisees par les agriculteurs.
 */

model retenueCollinaire

import "../modeleCommun/contourZoneMaelia.gaml"
import "zoneHydrographiqueSWAT.gaml"
 
global{	
	string retenueCollinaireShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/retenuesCollinaires/retenuesParZH.shp';
	list<retenueCollinaire> listeRetenuesCollinaires <- [];
	float eta <- 0.6; //coefficient de conversion de l'etp en evaporation des surfaces en eauv
	float relationVolumeCulot_VolumeMax <- 0.25; //75% du volume est considéré comme utilisable pour l'irrigation
	
	// JV mai 2019 pour bilan hydro
	string nomFichierBilanRetenues <- cheminRelatifDuDossierDeSortieDeSimulation +'/debugBilanRetenues.csv';
	bool enteteRetenuesDejaEcrit <- false;	 
	
	/*
	 * *****************************************************************************************
	 * Publique
	 */
	action constructionRetenueCollinaire{
		
		if !file_exists(retenueCollinaireShape) {do raiseWarning("fichier inexistant: " + retenueCollinaireShape);}
		//else if !is_shape(retenueCollinaireShape) {do raiseError("le fichier " + retenueCollinaireShape + " n'est pas un fichier shape");}
		
		listeRetenuesCollinaires <- constructionRessourcesEnEau(typeRessource:retenueCollinaire, cheminShp:retenueCollinaireShape, type:RET) as list<retenueCollinaire>;
		
		list<retenueCollinaire> listRetenueAvecImpluvium <- (retenueCollinaire where (each.fractionBassinDraine > 0.0) );
		
		ask retenueCollinaire{
			if(volumeMax < surface * 0.5){
				unknown toto <- world.raiseWarning("retenue " + id + ": volume estimé trop faible, elle aurait une profondeur moyenne de " + (volumeMax/surface *100) with_precision 0 +
						 " cm. On va donc lui affecter un volume correspondant a une profondeur moyenne de 1 m");
				volumeMax<- surface;
				volumeCulot <- relationVolumeCulot_VolumeMax*volumeMax;
			}		
			volumeActuel <- volumeMax;
			if((typeOfRet = CONNECTE) and (fractionBassinDraine <= 0.0)){				
				retenueCollinaire retLoc <- listRetenueAvecImpluvium closest_to self;
				retLoc.fractionBassinDraine <- retLoc.fractionBassinDraine/2.0;
				fractionBassinDraine <- retLoc.fractionBassinDraine;
			}else if((typeOfRet = DECONNECTE) and (fractionBassinDraine <= 0.0)){
				typeOfRet <- SURNAPPE;
			}
		}
		
		//rechargeHivernale
		loop idRet over: listeRetenuesRechargeHivernale{
			ask (retenueCollinaire where (each.id=idRet)){
				rechargeHivernale <- true;
			}
		}
		
	}
	action videSurplusRetenue (zoneHydrographique zh){
		ask retenueCollinaire where (each.zhAssociee = zh){
			// tout d'abord mise a jour du volume
			if (volumeActuel - getVolumePreleveReel() < 0.0){
				write "volumeActuel "+ volumeActuel + " getVolumePreleveReel " + getVolumePreleveReel()+
				" volumeUtileAvantPrelevementEtRejet " + volumeUtileAvantPrelevementEtRejet
				+ " mapVolumePreleveReel " + mapVolumePreleveReel;
			}
			volumeActuel <- volumeActuel - getVolumePreleveReel();
			if (volumeActuel > volumeMax){
				float delta <- (volumeActuel -volumeMax );
				zhAssociee.volumeSorti <- zhAssociee.volumeSorti + //volumeStocke
										delta;
				ask zh{
					list<ressourceEnEau> listeCoursDeauZH <- (ressourceEnEauAssociees at SURF);	
					delta <- delta / length(listeCoursDeauZH);	 	 			 			 	
				 	ask listeCoursDeauZH{
				 		volumeUtileAvantPrelevementEtRejet <- volumeUtileAvantPrelevementEtRejet + delta ;
				 	}						 
					
				}						 
				volumeActuel <- volumeMax;
			}
		}
	}
	

	// JV nouvelle gestion des retenues en une seule passe 270718
	// pour une meileure lisibilité j'ai délibérément renoncé à modulariser ce code en rassemblant le code ici
	action remplissageRetenue (zoneHydrographique zh){
		
		// Pour chaque retenue de la ZH hors retenues connectées sur drain principal
		
			// 1.0 mise à jour du volumeActuel = volumeActuel + pluie - évaporation - percolation - prélèvements
			// 1.1 calcul de la recharge potentielle = volume max que peut drainer la retenue dans les HRU pour se remplir
			// 		connectée:		recharge potentielle = fractionBassinDraine * ZH.volumePhaseSol (ruissellement, latéral, souterrain)
			// 		déconnectée:	recharge potentielle = fractionBassinDraine * ZH.volumeRuissellement (ruissellement uniquement)
			// 		sur nappe:		recharge potentielle = 0.0			
			// 1.2 calcul du delta = min(volMax - volActuel, rechargePotentielle)
			// si delta>0 : on remplit la retenue
			// 		2.1 MAJ du volumeActuel = volumeActuel + delta
			//		2.2 on retire delta des volumes des HRU
			// 			déconnectée:				on retire delta en répartissant au prorata des portions hydro et RPG du volume de ruissellement total
			// 			connectée drain secondaire:	on retire delta en répartissant au prorata des volumes de la phase sol
			// si delta<0 : la retenue déborde déjà -> on ne la remplit pas et on reverse le surplus dans les HRU et la ZH
			//		3.1 MAJ du volumeActuel = volumeMax (la retenue est pleine)
			//		3.2 on reverse le surplus
			// 			déconnectée 				-> on répercute sur tous les volumes de la phase sol (ruiss, lat, sout)
			//	 		connectée drain secondaire 	-> on répercute sur tous les volumes de la phase sol (ruiss, lat, sout)
			
		// Fin pour
		
		// Pour chaque retenue connectée au drain principal dans l'ordre amont -> aval

			// 4.0	mise à jour du volumeActuel = volumeActuel + pluie - évaporation - percolation - prélèvements
			// 4.1	si le volume entrant des ZH en amont > débit réserve et que la retenue n'est pas pleine -> on remplit la retenue par le cours d'eau
			//		delta = max(0,min(volEntrant-debitReserve,volMax-volActuel))
			//		volEntrant = volEntrant - delta
			//		volActuel = volActuel + delta
			// 4.2 si la retenue n'est toujours pas pleine -> on finit le remplissage en puisant dans les HRU
			// 		4.21 calcul de la recharge potentielle = volume max que peut drainer la retenue dans les HRU pour se remplir
			// 		4.22 calcul du delta = min(volMax - volActuel, rechargePotentielle)
			// 		4.23 MAJ du volumeActuel = volumeActuel + delta
			//		4.24 on retire delta des volumes des HRU en répartissant au prorata des volumes de la phase sol
			// 4.3 si la retenue déborde déjà avec les précipitations -> on verse le surplus dans le cours d'eau
			// 		4.3.1 MAJ du volumeActuel = volumeMax (la retenue est pleine)
			//		4.3.2 volEntrant = volEntrant + delta (delta = volActuel - volMax)
			//			on peut reverser dans ZH.volEntrant car les volumes des cours d'eau sont calculés après dans calculVolumeUtileCoursEauReel 

		// Fin pour			
		
		// 	retenues sur nappe: les prélèvements sont répercutés sur l'aquifère peu profond dans ZoneHydrographiqueSWAT.miseAjourVolumeNappe
		
		// Pour chaque retenue de la ZH hors retenues connectées sur drain principal (traitées à part)
		ask retenueCollinaire where ((each.zhAssociee = zh) and not(each.typeOfRet=CONNECTE and each.isOnDrainPrincipal)){
				
			// JV mai 2019: variables pour la vérification des bilans
			bilan_volumeDebut <- volumeActuel; // volume du jour précédent
			bilan_volumeFin <- 0.0;  // volume à la fin de la procédure
			bilan_precip <- getVolumePrecip(); // volume précipitations
			bilan_evap <- getVolumeEvap(); // volume évaporation
			bilan_percol <- getVolumePercol(); // volume percolation
			bilan_prelev <- getVolumePreleveReel(); // volume prélèvements
			bilan_rechargeHRU <- 0.0; // volume recharge puisé dans les HRU
			bilan_rechargeCoursEau <- 0.0; // volume rechargé puisé dans le cours d'eau (non concerné ici car pas sur drain principal)
			bilan_surplus <- 0.0; // volume de débordement rejeté
			bilan_tauxRemplissage <- 0.0; // volumeFin/volumeMax
			// fin JV

			// 1.0 mise à jour du volumeActuel = volumeActuel + pluie - évaporation - percolation - prélèvements
			// on enlève les prélèvements du jour j avant le remplissage
			// calcul du volume de la retenue au jour j: vol(j) = vol(j-1) + pluie - évaporation - percolation - prélèvements
			volumeActuel <- volumeActuel + getVolumePrecip() - getVolumeEvap() - getVolumePercol() - getVolumePreleveReel();			
			
			if(volumeActuel<0.0){
				write("ret " + id + " volumeActuel négatif: " + volumeActuel);
			}
			assert(volumeActuel>=0.0);
											
			// on enlève les prélèvements du jour j après le remplissage (sinon retenue toujours à son niveau max)
			// calcul du volume de la retenue au jour j: vol(j) = vol(j-1) + pluie - évaporation - prélèvements
			//volumeActuel <- volumeActuel + getVolumePrecip() - getVolumePercol();			
			
			// 1.1 calcul de la recharge potentielle = volume max que peut drainer la retenue dans les HRU pour se remplir
			// calcul de la recharge potentielle (volume max qu'on peut apporter à la retenue en fonction de la fraction de bassin drainé par la retenue)
			// retenue connectée:	recharge potentielle = fractionBassinDraine * ZH.volumePhaseSol (ruissellement, latéral, souterrain)
			// retenue déconnectée:	recharge potentielle = fractionBassinDraine * ZH.volumeRuissellement (ruissellement uniquement)
			// retenue sur nappe:	recharge potentielle = 0.0
			float rechargePotentielle <- getVolumeIn();
			
			if(rechargePotentielle<0.0){
				switch typeOfRet {
					
					match CONNECTE { //SI CONNECTE
						write("ret " + id + " frac: " + fractionBassinDraine + " ZH.solhydro: " + zoneHydrographiqueSWAT(zh).getVolumePhaseSolHydro()  + " ZH.solRPG: " + zh.getVolumePhaseSolRPG()); 
					}
					match DECONNECTE {
						write("ret " + id + " frac: " + fractionBassinDraine + " ZH.ruiss: " + zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface()); 
					}
					default { //Sur Nappes ? ou statut inconnu 
						write("nappes"); 
		            } 
				}								
			}
			assert(rechargePotentielle>=0.0);
			
			// 1.2 calcul du volume à remplir: delta = min(volMax - volActuel, rechargePotentielle)
			// pour ne pas remplir plus que ce que la retenue peut drainer
			float delta <- min([volumeMax - volumeActuel, rechargePotentielle]);
								
			if(delta > 0.0){ // si delta positif: on remplit la retenue								
															
				// 2.1 MAJ effective du volume de la retenue
				volumeActuel <- volumeActuel + delta;

				bilan_rechargeHRU <- delta; // JV pour bilan

				// 2.2 on retire delta des volumes des HRU						
				// déconnectée:					on retire delta en répartissant au prorata des portions hydro et RPG du volume de ruissellement total
				// connectée drain secondaire:	on retire delta en répartissant au prorata des volumes de la phase sol
				// connectée drain principal	on retire delta du cours d'eau, traitée séparément
								
				switch typeOfRet {
				
					match DECONNECTE { 
						// calcul des volumes [m3] hydro et RPG à retirer au niveau de la ZH au prorata des portions hydro et RPG du volume de ruissellement total
						float volumeRuissARetirerZHHydro <- 0.0;
						float volumeRuissARetirerZHRPG <- 0.0;
						if(zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() > 0.0){
							volumeRuissARetirerZHHydro <- delta * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface();
							volumeRuissARetirerZHRPG <- delta * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface();											
						}
						// on retire des HRU hydro et RPG: attention ce sont des hauteurs en [mm]
						float tmp<-0.0;
						float sommeContribHRU <- 0.0;
						ask(zoneHydrographiqueSWAT(zh).listeHRUAssociees){
							// 1. calcul de la contribution de la HRU au volume de ruissellement de la ZH: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
							float contributionHRU <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro > 0.0){
								contributionHRU <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro;							
							}
							// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de ruissellement de la ZH
							float volumeARetirerHRU <- volumeRuissARetirerZHHydro * contributionHRU; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurARetirerHRU <- (volumeARetirerHRU/surface) * 1000.0;
							// 4. on retire de la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurARetirerHRU;
							tmp <- tmp + volumeARetirerHRU;
							sommeContribHRU <- sommeContribHRU + contributionHRU;				
						} 
						tmp <- 0.0;
						sommeContribHRU <- 0.0;
						ask(zoneHydrographiqueSWAT(zh).listeHRUrpgAssociees){
							// 1. calcul de la contribution de la HRU au volume de ruissellement de la ZH: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceRPG[m3]
							float contributionHRU <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG > 0.0){
								contributionHRU <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG;							
							}
							// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de ruissellement de la ZH
							float volumeARetirerHRU <- volumeRuissARetirerZHRPG * contributionHRU; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurARetirerHRU <- (volumeARetirerHRU/surface) * 1000.0;
							// 4. on retire de la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurARetirerHRU;						
							tmp <- tmp + volumeARetirerHRU;						
							sommeContribHRU <- sommeContribHRU + contributionHRU;				
						} 
						// retrait effectif au niveau de la ZH (fait en dernier car les boucles HRU utilisent ces volumes pour le calcul des contributions) 
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro - volumeRuissARetirerZHHydro; 
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG - volumeRuissARetirerZHRPG;
					}
				
					match CONNECTE {					
						// on répartit le volume delta à retirer de la ZH au prorata des volumes de la phase sol
						float deltaRuiss <- 0.0;
						float deltaLat <- 0.0;
						float deltaSout <- 0.0;
						if(zoneHydrographiqueSWAT(zh).getVolumePhaseSol() > 0.0){
							deltaRuiss <- delta * zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
							deltaLat <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
							deltaSout <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
						}
						if((deltaRuiss + deltaLat + deltaSout) != delta){
							write("ret " + id + " connectee pb repartition: deltaRuiss=" + deltaRuiss + " deltaLat=" + deltaLat + " deltaSout=" + deltaSout + " delta=" + delta);
						}
						// seconde répartition de chaque volume delta au prorata des portions hydro et RPG
						float volumeRuissARetirerZHHydro <- 0.0; 
						float volumeRuissARetirerZHRPG <- 0.0; 
						float volumeLatARetirerZHHydro <- 0.0; 
						float volumeLatARetirerZHRPG <- 0.0; 
						float volumeSoutARetirerZHHydro <- 0.0; 
						float volumeSoutARetirerZHRPG <- 0.0; 										
						if(zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() > 0.0){
							volumeRuissARetirerZHHydro <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
							volumeRuissARetirerZHRPG <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
						}
						if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() > 0.0){
							volumeLatARetirerZHHydro <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
							volumeLatARetirerZHRPG <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
						}
						if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() > 0.0){
							volumeSoutARetirerZHHydro <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 
							volumeSoutARetirerZHRPG <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 										
						}
						// on retire des HRU hydro et RPG: attention ce sont des hauteurs en [mm]
						float tmpRuiss<-0.0;
						float tmpLat<-0.0;
						float tmpSout<-0.0;
						float sommeContribHRURuiss <- 0.0;						
						float sommeContribHRULat <- 0.0;
						float sommeContribHRUSout <- 0.0;
						ask(zoneHydrographiqueSWAT(zh).listeHRUAssociees){
							// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
							float contributionHRURuiss <- 0.0;
							float contributionHRULat <- 0.0;
							float contributionHRUSout <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro > 0.0){
								contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro > 0.0){
								contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro > 0.0){
								contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro;							
							}
							// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de la ZH
							float volumeRuissARetirerHRU <- volumeRuissARetirerZHHydro * contributionHRURuiss; // [m3]
							float volumeLatARetirerHRU <- volumeLatARetirerZHHydro * contributionHRULat; // [m3]
							float volumeSoutARetirerHRU <- volumeSoutARetirerZHHydro * contributionHRUSout; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurRuissARetirerHRU <- (volumeRuissARetirerHRU/surface) * 1000.0;
							float hauteurLatARetirerHRU <- (volumeLatARetirerHRU/surface) * 1000.0;
							float hauteurSoutARetirerHRU <- (volumeSoutARetirerHRU/surface) * 1000.0;
							// 4. on retire de la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurRuissARetirerHRU;						
							ecoulementLateral <- ecoulementLateral - hauteurLatARetirerHRU;
							ecoulementEauSouterraine <- ecoulementEauSouterraine - hauteurSoutARetirerHRU;
							tmpRuiss <- tmpRuiss + volumeRuissARetirerHRU;
							tmpLat <- tmpLat + volumeLatARetirerHRU;
							tmpSout <- tmpSout + volumeSoutARetirerHRU;
							sommeContribHRURuiss <- sommeContribHRURuiss + contributionHRURuiss;				
							sommeContribHRULat <- sommeContribHRULat + contributionHRULat;
							sommeContribHRUSout <- sommeContribHRUSout + contributionHRUSout;													
						}
						tmpRuiss<-0.0;
						tmpLat<-0.0;
						tmpSout<-0.0;
						sommeContribHRURuiss <- 0.0;						
						sommeContribHRULat <- 0.0;
						sommeContribHRUSout <- 0.0;						
						ask(zoneHydrographiqueSWAT(zh).listeHRUrpgAssociees){
							// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
							float contributionHRURuiss <- 0.0;
							float contributionHRULat <- 0.0;
							float contributionHRUSout <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG > 0.0){
								contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG > 0.0){
								contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG > 0.0){
								contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG;							
							}
							// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de la ZH
							float volumeRuissARetirerHRU <- volumeRuissARetirerZHRPG * contributionHRURuiss; // [m3]
							float volumeLatARetirerHRU <- volumeLatARetirerZHRPG * contributionHRULat; // [m3]
							float volumeSoutARetirerHRU <- volumeSoutARetirerZHRPG * contributionHRUSout; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurRuissARetirerHRU <- (volumeRuissARetirerHRU/surface) * 1000.0;
							float hauteurLatARetirerHRU <- (volumeLatARetirerHRU/surface) * 1000.0;
							float hauteurSoutARetirerHRU <- (volumeSoutARetirerHRU/surface) * 1000.0;
							// 4. on retire de la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurRuissARetirerHRU;						
							ecoulementLateral <- ecoulementLateral - hauteurLatARetirerHRU;
							ecoulementEauSouterraine <- ecoulementEauSouterraine - hauteurSoutARetirerHRU;						
							tmpRuiss <- tmpRuiss + volumeRuissARetirerHRU;
							tmpLat <- tmpLat + volumeLatARetirerHRU;
							tmpSout <- tmpSout + volumeSoutARetirerHRU;
							sommeContribHRURuiss <- sommeContribHRURuiss + contributionHRURuiss;				
							sommeContribHRULat <- sommeContribHRULat + contributionHRULat;
							sommeContribHRUSout <- sommeContribHRUSout + contributionHRUSout;													
						}
						// retrait effectif de la ZH (fait en dernier car les boucles HRU utilisent ces volumes pour le calcul des contributions)
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro - volumeRuissARetirerZHHydro;
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG - volumeRuissARetirerZHRPG;
						zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro - volumeLatARetirerZHHydro;
						zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG - volumeLatARetirerZHRPG;
						zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro - volumeSoutARetirerZHHydro;
						zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG - volumeSoutARetirerZHRPG;						
					}
					
					default{
						// JV cas des retenues sur nappe ? -> on ne fait rien
					} 
				
				} // fin switch	
			} // fin si delta > 0.0		
			else if(delta < 0.0){
			
				// si delta négatif: la retenue déborde déjà -> on ne la remplit pas et on reverse le surplus dans les HRU et la ZH			
				
				// 3.1 MAJ du volumeActuel = volumeMax (la retenue est pleine)
				volumeActuel <- volumeMax;
				
				// 3.2 on reverse le surplus
				// volume à reverser dans les HRU et la ZH
				float delta <- abs(delta);																
				
				bilan_surplus <- delta; // JV pour bilan
												 											
				switch typeOfRet {
				
				// 230918 vu avec Olivier
				// déconnectée 					-> on répercute sur tous les volumes de la phase sol (ruiss, lat, sout)
				// connectée drain secondaire 	-> on répercute sur tous les volumes de la phase sol (ruiss, lat, sout)
				// connectée drain principal	-> on répercute sur cours d'eau, traitée à part
				
					match_one [DECONNECTE,CONNECTE] {
						
						// on répartit le volume delta à ajouter à la ZH au prorata des volumes de la phase sol
						float deltaRuiss <- 0.0;
						float deltaLat <- 0.0;
						float deltaSout <- 0.0;
						if(zoneHydrographiqueSWAT(zh).getVolumePhaseSol() > 0.0){
							deltaRuiss <- delta * zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
							deltaLat <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
							deltaSout <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
						}
						if((deltaRuiss + deltaLat + deltaSout) != delta){
							write("ret " + id + " connectee pb repartition: deltaRuiss=" + deltaRuiss + " deltaLat=" + deltaLat + " deltaSout=" + deltaSout + " delta=" + delta);
						}
						// seconde répartition de chaque volume delta au prorata des portions hydro et RPG
						float volumeRuissAAjouterZHHydro <- 0.0; 
						float volumeRuissAAjouterZHRPG <- 0.0; 
						float volumeLatAAjouterZHHydro <- 0.0; 
						float volumeLatAAjouterZHRPG <- 0.0; 
						float volumeSoutAAjouterZHHydro <- 0.0; 
						float volumeSoutAAjouterZHRPG <- 0.0; 										
						if(zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() > 0.0){
							volumeRuissAAjouterZHHydro <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
							volumeRuissAAjouterZHRPG <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
						}
						if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() > 0.0){
							volumeLatAAjouterZHHydro <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
							volumeLatAAjouterZHRPG <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
						}
						if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() > 0.0){
							volumeSoutAAjouterZHHydro <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 
							volumeSoutAAjouterZHRPG <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 										
						}
						// on ajoute aux HRU hydro et RPG: attention ce sont des hauteurs en [mm]
						ask(zoneHydrographiqueSWAT(zh).listeHRUAssociees){
							// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
							float contributionHRURuiss <- 0.0;
							float contributionHRULat <- 0.0;
							float contributionHRUSout <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro > 0.0){
								contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro > 0.0){
								contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro > 0.0){
								contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro;							
							}
							// 2. calcul du volume à ajouter à la HRU au proprata de sa contribution au volume de la ZH
							float volumeRuissAAjouterHRU <- volumeRuissAAjouterZHHydro * contributionHRURuiss; // [m3]
							float volumeLatAAjouterHRU <- volumeLatAAjouterZHHydro * contributionHRULat; // [m3]
							float volumeSoutAAjouterHRU <- volumeSoutAAjouterZHHydro * contributionHRUSout; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurRuissAAjouterHRU <- (volumeRuissAAjouterHRU/surface) * 1000.0;
							float hauteurLatAAjouterHRU <- (volumeLatAAjouterHRU/surface) * 1000.0;
							float hauteurSoutAAjouterHRU <- (volumeSoutAAjouterHRU/surface) * 1000.0;
							// 4. on ajoute à la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU + hauteurRuissAAjouterHRU;						
							ecoulementLateral <- ecoulementLateral + hauteurLatAAjouterHRU;
							ecoulementEauSouterraine <- ecoulementEauSouterraine + hauteurSoutAAjouterHRU;						
						} 
						ask(zoneHydrographiqueSWAT(zh).listeHRUrpgAssociees){
							// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
							float contributionHRURuiss <- 0.0;
							float contributionHRULat <- 0.0;
							float contributionHRUSout <- 0.0;
							if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG > 0.0){
								contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG > 0.0){
								contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG;							
							}
							if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG > 0.0){
								contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG;							
							}
							// 2. calcul du volume à ajouter à la HRU au proprata de sa contribution au volume de la ZH
							float volumeRuissAAjouterHRU <- volumeRuissAAjouterZHRPG * contributionHRURuiss; // [m3]
							float volumeLatAAjouterHRU <- volumeLatAAjouterZHRPG * contributionHRULat; // [m3]
							float volumeSoutAAjouterHRU <- volumeSoutAAjouterZHRPG * contributionHRUSout; // [m3]
							// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
							float hauteurRuissAAjouterHRU <- (volumeRuissAAjouterHRU/surface) * 1000.0;
							float hauteurLatAAjouterHRU <- (volumeLatAAjouterHRU/surface) * 1000.0;
							float hauteurSoutAAjouterHRU <- (volumeSoutAAjouterHRU/surface) * 1000.0;
							// 4. on ajoute à la hauteur de la HRU			
							ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU + hauteurRuissAAjouterHRU;						
							ecoulementLateral <- ecoulementLateral + hauteurLatAAjouterHRU;
							ecoulementEauSouterraine <- ecoulementEauSouterraine + hauteurSoutAAjouterHRU;						
						}
						// ajout effectif à la ZH (fait en dernier car les boucles HRU utilisent ces volumes pour le calcul des contributions)
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro + volumeRuissAAjouterZHHydro;
						zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG + volumeRuissAAjouterZHRPG;
						zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro + volumeLatAAjouterZHHydro;
						zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG + volumeLatAAjouterZHRPG;
						zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro + volumeSoutAAjouterZHHydro;
						zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG + volumeSoutAAjouterZHRPG;												
						
					}
					
					default{
						// JV cas des retenues sur nappe ? -> on ne fait rien
					} 
				
				} // fin switch
							
				//write("ret " + id + " delta: " + delta + " volumeMax:" + volumeMax + " volumeActuel:" + volumeActuel + " rechargePotentielle: " + rechargePotentielle);
				
			} // fin delta < 0.0
			
			// JV pour bilan
			bilan_volumeFin <- volumeActuel;
			bilan_tauxRemplissage <- volumeActuel/volumeMax;
			if(!enteteRetenuesDejaEcrit){
				//save 'date;ZH;idRet;typeRet;isOnDrainPrincipal;volDebut;volFin;tauxRempl;precip;rechargeHRU;rechargeCoursEau;evap;percol;prelev;surplus' to: nomFichierBilanRetenues type: 'csv' rewrite:false;
				enteteRetenuesDejaEcrit <- true;
			}			
			string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + zh.idZoneHydrographique + ";" + id + ";" + typeOfRet + ";" + isOnDrainPrincipal + ";" + bilan_volumeDebut + ";" + bilan_volumeFin + ";" + bilan_tauxRemplissage + ";" + bilan_precip + ";" + bilan_rechargeHRU + ";0.0;" + bilan_evap + ";" + bilan_percol + ";" + bilan_prelev + ";" + bilan_surplus;
			//save chaineAEcrire to: nomFichierBilanRetenues type: 'csv' rewrite:false;
			// fin JV
					
		} // fin pour chaque retenue de la ZH
		
		// JV ici cas des retenues sur drain principal: si pas pleine, la remplir avec le cours d'eau mais dans une boucle à part car elles doivent être ordonnées sur le cours d'eau
		// aupravant étaient parcourues en partant de l'exutoire (aval->amont), remis dans le sens amont->aval										
		ask (retenueCollinaire where ((each.zhAssociee = zh) and (each.isOnDrainPrincipal))) sort_by (each.prioriteSurDrain){

			// JV mai 2019: variables pour la vérification des bilans
			bilan_volumeDebut <- volumeActuel; // volume du jour précédent
			bilan_volumeFin <- 0.0;  // volume à la fin de la procédure
			bilan_precip <- getVolumePrecip(); // volume précipitations
			bilan_evap <- getVolumeEvap(); // volume évaporation
			bilan_percol <- getVolumePercol(); // volume percolation
			bilan_prelev <- getVolumePreleveReel(); // volume prélèvements
			bilan_rechargeHRU <- 0.0; // volume recharge puisé dans les HRU
			bilan_rechargeCoursEau <- 0.0; // volume recharge puisé dans le cours d'eau
			bilan_surplus <- 0.0; // volume de débordement rejeté
			bilan_tauxRemplissage <- 0.0; // volumeActuel/volumeMax
			// fin JV

			// mise à jour du volumeActuel = volumeActuel + pluie - évaporation - percolation - prélèvements
			// on enlève les prélèvements du jour j avant le remplissage
			// calcul du volume de la retenue au jour j: vol(j) = vol(j-1) + pluie - évaporation - percolation - prélèvements
			volumeActuel <- volumeActuel + getVolumePrecip() - getVolumeEvap() - getVolumePercol() - getVolumePreleveReel();			
			
			assert(zhAssociee.volumeEntrantDesZHsAmonts>=0.0);

			// 4.1 si le volume entrant des ZH en amont > débit réserve et que la retenue n'est pas pleine -> on remplit la retenue par le cours d'eau
			if((zhAssociee.volumeEntrantDesZHsAmonts > debitReserve*3600.0*24.0) and (volumeActuel < volumeMax)){
				float delta <- max([0.0 ,min ([zhAssociee.volumeEntrantDesZHsAmonts -debitReserve*3600.0*24.0, volumeMax - volumeActuel ])]) ; //write "\t" + delta;
				zhAssociee.volumeEntrantDesZHsAmonts <- zhAssociee.volumeEntrantDesZHsAmonts - delta ;
				volumeActuel <- volumeActuel + delta;
				volumeRechargeEffective <- volumeRechargeEffective + delta;			
			
				bilan_rechargeCoursEau <- delta; // JV pour bilan
			}

			// 4.2 si la retenue n'est toujours pas pleine -> on finit le remplissage en puisant dans les HRU (JV 091222 correction #0002945)
			if volumeActuel < volumeMax {
					
				// 4.2.1 calcul de la recharge potentielle
				float rechargePotentielle <- getVolumeIn();
				assert(rechargePotentielle>=0.0);
	
				// 4.22 calcul du delta = min(volMax - volActuel, rechargePotentielle)										
				float delta <- min([volumeMax - volumeActuel, rechargePotentielle]);
				
				// 4.23 MAJ du volumeActuel = volumeActuel + delta
				volumeActuel <- volumeActuel + delta;

				bilan_rechargeHRU <- delta; // JV pour bilan 									
			
				// 4.24 on retire delta des volumes des HRU en répartissant au prorata des volumes de la phase sol
				// même code que 2.2 type CONNECTE
				// on répartit le volume delta à retirer de la ZH au prorata des volumes de la phase sol
				float deltaRuiss <- 0.0;
				float deltaLat <- 0.0;
				float deltaSout <- 0.0;
				if(zoneHydrographiqueSWAT(zh).getVolumePhaseSol() > 0.0){
					deltaRuiss <- delta * zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
					deltaLat <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
					deltaSout <- delta * zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() / zoneHydrographiqueSWAT(zh).getVolumePhaseSol();
				}
				if((deltaRuiss + deltaLat + deltaSout) != delta){
					write("ret " + id + " connectee pb repartition: deltaRuiss=" + deltaRuiss + " deltaLat=" + deltaLat + " deltaSout=" + deltaSout + " delta=" + delta);
				}
				// seconde répartition de chaque volume delta au prorata des portions hydro et RPG
				float volumeRuissARetirerZHHydro <- 0.0; 
				float volumeRuissARetirerZHRPG <- 0.0; 
				float volumeLatARetirerZHHydro <- 0.0; 
				float volumeLatARetirerZHRPG <- 0.0; 
				float volumeSoutARetirerZHHydro <- 0.0; 
				float volumeSoutARetirerZHRPG <- 0.0; 										
				if(zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface() > 0.0){
					volumeRuissARetirerZHHydro <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
					volumeRuissARetirerZHRPG <- deltaRuiss * zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG/zoneHydrographiqueSWAT(zh).getVolumeRuissellementDeSurface(); 
				}
				if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral() > 0.0){
					volumeLatARetirerZHHydro <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
					volumeLatARetirerZHRPG <- deltaLat * zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementLateral(); 
				}
				if(zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine() > 0.0){
					volumeSoutARetirerZHHydro <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 
					volumeSoutARetirerZHRPG <- deltaSout * zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG/zoneHydrographiqueSWAT(zh).getVolumeEcoulementEauSouterraine(); 										
				}
				// on retire des HRU hydro et RPG: attention ce sont des hauteurs en [mm]
				float tmpRuiss<-0.0;
				float tmpLat<-0.0;
				float tmpSout<-0.0;
				float sommeContribHRURuiss <- 0.0;						
				float sommeContribHRULat <- 0.0;
				float sommeContribHRUSout <- 0.0;
				ask(zoneHydrographiqueSWAT(zh).listeHRUAssociees){
					// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
					float contributionHRURuiss <- 0.0;
					float contributionHRULat <- 0.0;
					float contributionHRUSout <- 0.0;
					if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro > 0.0){
						contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro;							
					}
					if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro > 0.0){
						contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro;							
					}
					if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro > 0.0){
						contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro;							
					}
					// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de la ZH
					float volumeRuissARetirerHRU <- volumeRuissARetirerZHHydro * contributionHRURuiss; // [m3]
					float volumeLatARetirerHRU <- volumeLatARetirerZHHydro * contributionHRULat; // [m3]
					float volumeSoutARetirerHRU <- volumeSoutARetirerZHHydro * contributionHRUSout; // [m3]
					// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
					float hauteurRuissARetirerHRU <- (volumeRuissARetirerHRU/surface) * 1000.0;
					float hauteurLatARetirerHRU <- (volumeLatARetirerHRU/surface) * 1000.0;
					float hauteurSoutARetirerHRU <- (volumeSoutARetirerHRU/surface) * 1000.0;
					// 4. on retire de la hauteur de la HRU			
					ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurRuissARetirerHRU;						
					ecoulementLateral <- ecoulementLateral - hauteurLatARetirerHRU;
					ecoulementEauSouterraine <- ecoulementEauSouterraine - hauteurSoutARetirerHRU;
					tmpRuiss <- tmpRuiss + volumeRuissARetirerHRU;
					tmpLat <- tmpLat + volumeLatARetirerHRU;
					tmpSout <- tmpSout + volumeSoutARetirerHRU;
					sommeContribHRURuiss <- sommeContribHRURuiss + contributionHRURuiss;				
					sommeContribHRULat <- sommeContribHRULat + contributionHRULat;
					sommeContribHRUSout <- sommeContribHRUSout + contributionHRUSout;													
				}
				tmpRuiss<-0.0;
				tmpLat<-0.0;
				tmpSout<-0.0;
				sommeContribHRURuiss <- 0.0;						
				sommeContribHRULat <- 0.0;
				sommeContribHRUSout <- 0.0;						
				ask(zoneHydrographiqueSWAT(zh).listeHRUrpgAssociees){
					// 1. calcul de la contribution de la HRU à chaque volume de la ZH: ex: (HRU.ruissellementDeSurfaceHRU[mm]/1000*HRU.surface[m2])/ZH.volumeRuissellementDeSurfaceHydro[m3]
					float contributionHRURuiss <- 0.0;
					float contributionHRULat <- 0.0;
					float contributionHRUSout <- 0.0;
					if(zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG > 0.0){
						contributionHRURuiss <- ((ruissellementDeSurfaceHRU/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG;							
					}
					if(zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG > 0.0){
						contributionHRULat <- ((ecoulementLateral/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG;							
					}
					if(zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG > 0.0){
						contributionHRUSout <- ((ecoulementEauSouterraine/1000.0) * surface) / zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG;							
					}
					// 2. calcul du volume à retirer de la HRU au proprata de sa contribution au volume de la ZH
					float volumeRuissARetirerHRU <- volumeRuissARetirerZHRPG * contributionHRURuiss; // [m3]
					float volumeLatARetirerHRU <- volumeLatARetirerZHRPG * contributionHRULat; // [m3]
					float volumeSoutARetirerHRU <- volumeSoutARetirerZHRPG * contributionHRUSout; // [m3]
					// 3. transformation en hauteur: on divise par la surface en [m2] -> on obtient une hauteur en [m] -> on multiplie par 1000 pour avoir des [mm]
					float hauteurRuissARetirerHRU <- (volumeRuissARetirerHRU/surface) * 1000.0;
					float hauteurLatARetirerHRU <- (volumeLatARetirerHRU/surface) * 1000.0;
					float hauteurSoutARetirerHRU <- (volumeSoutARetirerHRU/surface) * 1000.0;
					// 4. on retire de la hauteur de la HRU			
					ruissellementDeSurfaceHRU <- ruissellementDeSurfaceHRU - hauteurRuissARetirerHRU;						
					ecoulementLateral <- ecoulementLateral - hauteurLatARetirerHRU;
					ecoulementEauSouterraine <- ecoulementEauSouterraine - hauteurSoutARetirerHRU;						
					tmpRuiss <- tmpRuiss + volumeRuissARetirerHRU;
					tmpLat <- tmpLat + volumeLatARetirerHRU;
					tmpSout <- tmpSout + volumeSoutARetirerHRU;
					sommeContribHRURuiss <- sommeContribHRURuiss + contributionHRURuiss;				
					sommeContribHRULat <- sommeContribHRULat + contributionHRULat;
					sommeContribHRUSout <- sommeContribHRUSout + contributionHRUSout;													
				}
				// retrait effectif de la ZH (fait en dernier car les boucles HRU utilisent ces volumes pour le calcul des contributions)
				zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceHydro - volumeRuissARetirerZHHydro;
				zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG <- zoneHydrographiqueSWAT(zh).volumeRuissellementDeSurfaceRPG - volumeRuissARetirerZHRPG;
				zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralHydro - volumeLatARetirerZHHydro;
				zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementLateralRPG - volumeLatARetirerZHRPG;
				zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineHydro - volumeSoutARetirerZHHydro;
				zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG <- zoneHydrographiqueSWAT(zh).volumeEcoulementEauSouterraineRPG - volumeSoutARetirerZHRPG;						
			} // 4.2 fin si retenue toujours pas pleine			
			else if(volumeActuel > volumeMax){				
				// 4.3 si la retenue déborde déjà avec les précipitations -> on verse le surplus dans le cours d'eau
				float delta <- volumeMax-volumeActuel;			

				// 	4.3.1 MAJ du volumeActuel = volumeMax (la retenue est pleine)
				volumeActuel <- volumeMax;
				
				bilan_surplus <- abs(delta); // JV pour bilan
				
				//	4.3.2 volEntrant = volEntrant + delta (delta = volActuel - volMax)
				// on peut reverser dans ZH.volEntrant car les volumes des cours d'eau sont calculés après dans calculVolumeUtileCoursEauReel 
				zhAssociee.volumeEntrantDesZHsAmonts <- zhAssociee.volumeEntrantDesZHsAmonts + abs(delta); // JV 081222 correction ajout valeur absolue car delta negative ici cf. #0002945
								
			} // fin si retenue déborde
			
			// JV pour bilan
			bilan_volumeFin <- volumeActuel;
			bilan_tauxRemplissage <- volumeActuel/volumeMax; 
			if(!enteteRetenuesDejaEcrit){
				//save 'date;ZH;idRet;typeRet;isOnDrainPrincipal;volDebut;volFin;tauxRempl;precip;rechargeHRU;rechargeCoursEau;evap;percol;prelev;surplus' to: nomFichierBilanRetenues type: 'csv' rewrite:false;
				enteteRetenuesDejaEcrit <- true;
			}			
			
			string chaineAEcrire <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int) + ";" + zh.idZoneHydrographique + ";" + id + ";" + typeOfRet + ";" + isOnDrainPrincipal + ";" + bilan_volumeDebut + ";" + bilan_volumeFin + ";" + bilan_tauxRemplissage + ";" + bilan_precip + ";" + bilan_rechargeHRU + ";" + bilan_rechargeCoursEau + ";" + bilan_evap + ";" + bilan_percol + ";" + bilan_prelev + ";" + bilan_surplus;
			//save chaineAEcrire to: nomFichierBilanRetenues type: 'csv' rewrite:false;
			// fin JV
			
		} // fin pour chaque retenue connectée au drain principal

		ask retenueCollinaire where ((each.zhAssociee=zh) and (each.rechargeHivernale)){		
			do setPompageHivernale;
		}			
					
	}
	
	// Probleme si on fait ces actions consécutivement on un probleme d interaction entre la phase sol et la phase routage!
//	action bilanRetenue(zoneHydrographique zh){
//		do remplissageRetenue(zh);
//		do videSurplusRetenue(zh);
//	}
	
	action setVolumeIn (zoneHydrographique zh) { //[m3]
		//CONNECTE et DERIVATION
		float fractionDuBassinConnecte <- 0.0;
		ask retenueCollinaire where ((each.typeOfRet = CONNECTE) and (each.zhAssociee = zh)){
			fractionDuBassinConnecte <- fractionDuBassinConnecte + fractionBassinDraine;
		}
		
		//DECONNECTE 
		float fractionDuBassinDeconnecte <- 0.0;
		ask retenueCollinaire where  ((each.typeOfRet = DECONNECTE) and (each.zhAssociee = zh)){ //toutes les retenues
			fractionDuBassinDeconnecte <- fractionDuBassinDeconnecte + fractionBassinDraine;
		}
		ask zh{
			//Effet des retenues connecte au drain principal deja pris en compte
			do miseAjourVolumePhaseSolHydro(1 - fractionDuBassinConnecte);
			do miseAjourVolumeRuissellement((1 - fractionDuBassinDeconnecte -fractionDuBassinConnecte)/(1 - fractionDuBassinConnecte));
		}
	}
	
			
}

species retenueCollinaire parent: ressourceEnEau{
	float fractionBassinDraine <- 0.0001; //frimp : la fraction du sous-bassin drainee dans la retenue
	float volumeMax <- 1E10; //[m3]
	float volumeActuel <- 0.0; //[m3]
	float surface <- 1000.0; //[m2]
	string typeOfRet <- DECONNECTE; // DECONNECTE, CONNECTE SURNAPPE
	bool isOnDrainPrincipal <- false;
	float debitReserve <- 0.0;
	float volumeCulot <- relationVolumeCulot_VolumeMax*volumeMax;
	int prioriteSurDrain <- 0;
	float volumeRechargeEffective <- 0.0;
	bool rechargeHivernale <- false; // si oui alors on pompe de l'eau dans les cours d'eau pour la recharger
	float volumeAPomper <- 0.0; //volume a pomper pour recharger la retenue pendant la période hivernale
	
	// JV mai 2019: variables pour la vérification des bilans // JV 240822 déclarations déplacées ici pour être intégré à output sortie_retenues mais fonctionnement inchangé
	float bilan_volumeDebut <- 0.0; // volume du jour précédent
	float bilan_volumeFin <- 0.0;  // volume à la fin de la procédure
	float bilan_precip <- 0.0; // volume précipitations
	float bilan_evap <- 0.0; // volume évaporation
	float bilan_percol <- 0.0; // volume percolation
	float bilan_prelev <- 0.0; // volume prélèvements
	float bilan_rechargeHRU <- 0.0; // volume recharge puisé dans les HRU
	float bilan_rechargeCoursEau <- 0.0; // volume recharge puisé dans le cours d'eau
	float bilan_surplus <- 0.0; // volume de débordement rejeté
	float bilan_tauxRemplissage <- 0.0; // volumeActuel/volumeMax
	
	float getVolumePrecip{ // equation 8:1.1.5, p 517 de la documentation SWAT
		return surface * zhAssociee.pluie /nombreMillimetreDansUnMetre; //[m2] * [mm]
	}
	float getVolumeEvap{ // equation 8:1.1.6, p 517 de la documentation SWAT
		float evap <- surface * zhAssociee.meteo.etp /nombreMillimetreDansUnMetre * eta; //[m2] * [mm]
		evap <- min([volumeActuel - getVolumePreleveReel(), evap]); //Pour eviter d'evaporer plus deau que n'en contient le bassin
		return evap;
	}
	float getVolumePercol{ //[m3]
		switch typeOfRet {
//				match CONNECTE { // equation 8:1.1.7, p 517 de la documentation SWAT
//					return  Ksat * 24/nombreMillimetreDansUnMetre * surface; //surface en m2 et Ksat en mm/hr
//				}
			default {
                return 0.0;                         
            } 
		}
	}
	float getVolumeIn{ //[m3]
		switch typeOfRet {
			
			match CONNECTE { //SI CONNECTE 
				return  fractionBassinDraine *  zhAssociee.getVolumePhaseSol() ;
			}
			match DECONNECTE {
				return fractionBassinDraine *  zhAssociee.getVolumeRuissellementDeSurface();
			}
			default { //Sur Nappes ? ou statut inconnu 
				return 0.0; 
            } 
		}
	}
	
	action complementConstructionRessourceEau{
		fractionBassinDraine <- float(shape get( FRACTIONDRAIN ));
		volumeMax <- float(shape get( VOLMAX ));
		if (volumeMax <= 0.0){ // Vérification de l'existence de la valeur
			write '[INIT Retenue] Pas de volume pour la retenue ' + self;
		}	
		volumeCulot <- relationVolumeCulot_VolumeMax*volumeMax;
		surface <- float(shape get( SURFACERET ));	//équivalent a surface <- shape.area;		
		typeOfRet <- string(shape get( TYPEOFRET ));
			
		if((typeOfRet != CONNECTE) and (typeOfRet != DECONNECTE)){
			typeOfRet <- SURNAPPE;
		}
		
		if (string(shape get( TYPEDEDRAIN ))="principal"){
			isOnDrainPrincipal <- true;
		}
		debitReserve <- float(shape get( Q_RESERVE )); // L/s
		debitReserve <- debitReserve/1000.0;
//			if(debitReserve <= 0.0){
//				debitReserve <- 2.2;
//			}
		
		prioriteSurDrain <- int(shape get( ORDREDRAIN ));
		
	}
	
	//Pompage pour recharge hivernale. Pour le moment on pompe dans l'exutoire
	// TODO: Prevoir un fichier pour définir les retenues a recharger et les BVe
	action setPompageHivernale{
		if((dateCour.nbJoursEcoulesDansAnnee <= jourJulienFinPompage) or
			(dateCour.nbJoursEcoulesDansAnnee >= jourJulienDebutPompage)
		){
			if(dateCour.nbJoursEcoulesDansAnnee = jourJulienDebutPompage){ //alors on doit estimer les prelevements
				volumeAPomper <- max([volumeMax - volumeActuel, 0.0]) / ((365- jourJulienDebutPompage) + jourJulienFinPompage);
			}
			/* correction bug #1153
			//Pour le moment on va pomper sur le zh de l'exutoire
			ask  first(zoneHydrographique where (each.niveauHierarchiqueArbreZH=0)){
				list<ressourceEnEau> listeCoursDeauZH <- (ressourceEnEauAssociees at SURF);	
				if(myself.volumeActuel < myself.volumeMax){
					float delta <- myself.volumeAPomper/ length(listeCoursDeauZH);
					float eauNonPompable <- 0.0;	 	 			 			 	
				 	ask listeCoursDeauZH{
				 		if(volumeUtileAvantPrelevementEtRejet < delta){
				 			eauNonPompable <- delta - volumeUtileAvantPrelevementEtRejet;
				 			write "Probleme Pompage Hivernale pour les retenues. Il ne reste pas assez d'eau dans le cours d'eau principal";
							volumeUtileAvantPrelevementEtRejet <- 0.0;
				 		}else{
				 			volumeUtileAvantPrelevementEtRejet <- volumeUtileAvantPrelevementEtRejet - delta ;
				 		}
				 	}
				 	myself.volumeActuel <- myself.volumeActuel + myself.volumeAPomper - eauNonPompable;
				 	myself.volumeRechargeEffective <- myself.volumeRechargeEffective + myself.volumeAPomper - eauNonPompable;
				}
			}
			*/
			if(volumeActuel < volumeMax){
				volumeActuel <- volumeActuel + volumeAPomper ;
				volumeRechargeEffective <- volumeRechargeEffective + volumeAPomper ;
			}
		}		
	}

}
