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
 *  resultatsDemoChambreAlsace
 *  Author: JV
 *  Description: 
 */

model resultatsDemoChambreAlsace

import "ecritureResultats.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"
import "../modeleHydrographique/zoneHydrographiqueSWAT.gaml"
import "../modeleHydrographique/retenueCollinaire.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	action initialisationEcritureFichiersDemoChambreAlsace{
		do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers demoChambreAlsace';		
		
		create resultatsDemoChambreAlsace number: 1{
			do initialisation();
			listesFichiersAcreer << self;
		}
	}			
}


species resultatsDemoChambreAlsace parent: ecritureResultats{
	/*
	 * @Overwrite
	 */
	 float surfaceTotale <- 0.0; // [m2]
	 
	 string initialisationJournalier{	
		nomFichierJournalier <- cheminRelatifDuDossierDeSortieDeSimulation +'/demoChambreAlsace'+ nomDeLaSimulation + '.csv';
		loop zh over: listeZonesHydrographiques{
			ask zoneHydrographiqueSWAT(zh).listeHRUAssociees{
			 		myself.surfaceTotale <- myself.surfaceTotale + surface;
			 }
			ask zoneHydrographiqueSWAT(zh).listeHRUrpgAssociees{
			 		myself.surfaceTotale <- myself.surfaceTotale + surface;
			 }
		}			
		return "date;surface;volRetDeconnectees;volRetConnectees;volRetSurNappe;pluie;exutoire;percolation;irrigation;eqSurf;eqRet;eqSurNappe;eqSurfSouhaite;eqRetSouhaite;eqSurNappeSouhaite";
	 }

	 string ecritureJournaliere{		 	
		string data <- '' + string(dateCour.annee as int) + '/' + (dateCour.mois as int) + '/' + (dateCour.jour as int);
		
		// surface [m2]
		data <- data 	+ ";" + surfaceTotale; 								
	
		// retenues
		list<retenueCollinaire> retDeconnectees <- listeRetenuesCollinaires where ((each.typeOfRet)=DECONNECTE);
		list<retenueCollinaire> retConnectees <- listeRetenuesCollinaires where ((each.typeOfRet)=CONNECTE);
		list<retenueCollinaire> retSurNappe <- listeRetenuesCollinaires where ((each.typeOfRet)=SURNAPPE);		
		data <- data + ";" + retDeconnectees sum_of each.volumeActuel + ";" + retConnectees sum_of each.volumeActuel + ";" + retSurNappe sum_of each.volumeActuel; 
		
		// pluie
		data <- data + ";" + listeZonesHydrographiques sum_of each.pluie;			
		
		// volume sortie exutoire
		zoneHydrographique ZH2402 <- first(listeZonesHydrographiques where ((each.idZoneHydrographique)="2402"));
		data <- data + ";" + ZH2402.volumeSorti;
		
		// volume percolation
		data <- data + ";" + listeZonesHydrographiques sum_of zoneHydrographiqueSWAT(each).getVolumePercolationTotal();

		// volume irrigation total
		data <- data + ";" + listeParcelles sum_of each.getVolumeIrrigueReel();	

		// volumes prélèvements irrigation par type de ressource		
		list<equipementDeCaptageIRR> eqSurf <- equipementDeCaptageIRR where ((each.natureRessourcePrelevee)="SURF");
		list<equipementDeCaptageIRR> eqRet <- equipementDeCaptageIRR where ((each.natureRessourcePrelevee)="RET");
		list<equipementDeCaptageIRR> eqNapp <- equipementDeCaptageIRR where ((each.natureRessourcePrelevee)="NAPP");
		data <- data + ";" + eqSurf sum_of each.getVolumeReel() + ";" + eqRet sum_of each.getVolumeReel() + ";" + eqNapp sum_of each.getVolumeReel();
		data <- data + ";" + eqSurf sum_of each.getVolumeSouhaite() + ";" + eqRet sum_of each.getVolumeSouhaite() + ";" + eqNapp sum_of each.getVolumeSouhaite();
		
		// focus sur ilôts avec eq retenue
		list<string> idIlotsRet <- ["082-5641700","082-5640949","082-5632418","082-5635968","082-5668446","082-5635955","082-5634079","082-5634075","082-5675546","082-5675548","082-5675547","082-5636422","082-5636418","082-5651894","082-5651895","082-5651896","082-5651889","082-5659318","082-5659319","082-5671121","082-5631000","082-5639193
","082-5639192","082-5652642","082-5652643","082-5652640","082-5652637"];
		
		return data;					
	}

	string initialisationFinAnnuel{	
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/demoChambreAlsace'+ nomDeLaSimulation + '_rdt.csv';	
		string data <- "annee;";
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 
			data <- data + ';' + espece.idEspeceCultivee ;
		}
		return data;		
	 }

	 string ecritureFinAnnuelle{			 		 			 		
		string data <- '' + (dateCour.annee);
		loop espece over: listeEspecesCultiveesParOrdreSaisie{ 										
			float RDT<- 0.0;
			float Surface<- 0.0;
			loop agri over: listeAgriculteurs{
				ask (agri.listMemoire) where (each.itkAssocie.especeCultiveeITK = espece){
					RDT <- RDT + getMoyenneRendementsAnneeEnCours() *getSurfaceAnneeEnCours();
					Surface <- Surface + getSurfaceAnneeEnCours();
				}
			}
			if (Surface>0.0){
				data <- data + ';' + (RDT/Surface*nombreMeterCarreDansUnHectare) with_precision 2 ;//pour avoir un rdt en t/ha
			}else{
				data <- data + ';' ;
			}
		}		
		return data;	
	 }	
		 
}

