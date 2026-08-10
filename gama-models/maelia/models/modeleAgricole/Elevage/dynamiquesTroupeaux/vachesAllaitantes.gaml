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
 *  Vaches allaitantes
 *  Author: Theo Bullat
 *  Description: 
 */

model vachesAllaitantes

import "velagePrimi.gaml"

species vachesAllaitantes parent: vachesAdultes{
	
	float UGB <- 0.25; 
	
	
	float demarrerCalcul {
		do calculerRang;
		do calculerAge;
		do calculerPoids;
		do calculerNoteEtat;
		do calculerSemaineLactation;
		do calculerSemaineGestation;
		do calculerProductionLaitiere;
		do calculerCapaciteIngestion;
		besoinProteique <- demarrerCalculProt();
		besoinEnergetique <- demarrerCalculEnerg();
		return besoinProteique + besoinEnergetique;
	}
	
	float demarrerCalculProt {
		do calculerBesoinProteiqueGestation;
		do calculerBesoinProteiqueEntretien;
		do calculerBesoinProteiqueProductionLaitiere;
		return (besoinProteiqueEntretien + besoinProteiqueGestation + besoinProteiqueProductionLaitiere);
	}
	
	float demarrerCalculEnerg{
		do calculerBesoinEnergetiqueGestation;
		do calculerBesoinEnergetiqueEntretien;
		do calculerBesoinEnergetiqueProductionLaitiere;
		return (besoinEnergetiqueEntretien + besoinEnergetiqueGestation + besoinEnergetiqueProductionLaitiere);
	}
	
	action calculerRang{
		if int(age1erVelage + semaineDepuis1erVelage*7/30.4)
			<=	age1erVelage + 1/tauxDeRenouvellement*IVV/30.4 - (IVV-dureeLactation)/30.4{
			rang <- int(1 + semaineDepuis1erVelage*7/IVV);
		}else{
			rang <- 0;
		}
	}
	
	action calculerAge{
		if rang = 0 {
			age <- 0;
		}else{
			age <- int(age1erVelage + semaineDepuis1erVelage*7/30.4);
		}
	}
	
	action calculerPoids{
		if rang = 0 {
			poids <- 0.0;
		}else if rang = 1{
			poids <- 0.8*poidsAuVelage + (0.2*poidsAuVelage) * (semaineDepuis1erVelage-(rang-1)*51) / (IVV/7);
		}else{
			poids <- -0.0003503*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^3) 
					 +0.0761841*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^2)
					 -3.0493099*((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51) + poidsAuVelage +3; 
		}
	}
	
	action calculerNoteEtat{
		if rang = 0 {
			noteEtat <- 0.0;
		}else{
			noteEtat <- -0.000067*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^3) 
						+0.005985*(((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51)^2) 
						-0.130742*((semaineDepuis1erVelage - (rang-1)*51)/(IVV/7)*51) + noteEtatVelage +0.1; 
		}
	}
	
	action calculerSemaineLactation{
		if rang = 0 or semaineDepuis1erVelage > ((rang-1)*IVV/7 + dureeLactation/7){
			semaineLactation <- 0;
		}else{
			semaineLactation <- int(max([0 , semaineDepuis1erVelage - round((rang-1)*IVV/7)]));
		}
	}

	action calculerSemaineGestation{
		if rang = 0
		or semaineDepuis1erVelage < IVV/7*rang-9*4.5
		or semaineDepuis1erVelage > IVV/7*rang{
			semaineGestation <- 0;
		}else{
			semaineGestation <- int(semaineDepuis1erVelage-semaineLactationAvecInsemFecond-round(IVV/7*(rang-1)));
		}
	}
	
	action calculerProductionLaitiere{
		float coeffRang <- 1.0;
		if rang = 1 {
			coeffRang <- 0.8;
		}
		if semaineLactation >0{
			productionLaitiere <- coeffRang*prodMaxLaitTheorique*(0.885*semaineLactation^0.2)*exp(-0.04*semaineLactation);
		}else{
			productionLaitiere <- 0.0;
		}
	}
	
	action calculerCapaciteIngestion{
		float IStade <- 1.0;
		float IPar <- 1.0;
		float INote <- 0.0015;
		if semaineGestation>=40 or semaineLactation <= 1{
			IStade <- 0.9;
		}else if semaineGestation >= 39 and semaineGestation <40 
			 and semaineGestation <= 2  and semaineLactation <= 2 {
			IStade <- 0.95;
		}else if semaineGestation >=9 and semaineGestation <= 14{
			IStade <- 1.02;
		}
		if rang = 1 and semaineGestation!=0{
			IPar <- 0.88;
		}else if rang = 1 and semaineLactation/4.5<=3{
			IPar <- 0.03*int(semaineLactation/4.5)+0.9;
		}		
		if semaineGestation>0{
			INote <- 0.002;
		}
		capaciteIngestion <- IRace*IStade*IPar*(3.2+0.015*poids+0.25*productionLaitiere-INote*poids*(noteEtat-2.5));
	}
	
	action calculerBesoinEnergetiqueGestation{
		if semaineGestation > 0{
			besoinEnergetiqueGestation <- 0.00072 * poidsVeauNaissance * exp(0.116*semaineGestation);
		}else{
			besoinEnergetiqueGestation <- 0.0;
		}
	}
	
	action calculerBesoinEnergetiqueEntretien{
		float coefEntretien <- 1.1;
		float coefEntretienPoids <- 0.037;
//		if situation = "Pâturage"{
		if true{
			coefEntretien <- 1.2;
		}
		if semaineLactation > 0{
			coefEntretienPoids <- 0.041;
		}
		besoinEnergetiqueEntretien <- (coefEntretien*coefEntretienPoids+0.0068*(noteEtat-2.5))*poids^0.75;
	}
	
	action calculerBesoinEnergetiqueProductionLaitiere{
		if semaineLactation > 0{
			besoinEnergetiqueProductionLaitiere <- 0.45*productionLaitiere;
		}else{
			besoinEnergetiqueProductionLaitiere <- 0.0;
		}
	}
	
	action calculerBesoinProteiqueGestation{
		if semaineGestation > 0{
			besoinProteiqueGestation <- 0.07*poidsVeauNaissance*exp(0.111*semaineGestation);
		}else{
			besoinProteiqueGestation <- 0.0;
		}
	}
	
	action calculerBesoinProteiqueEntretien{
		besoinProteiqueEntretien <- 3.25*poids^0.75;
	}
	
	action calculerBesoinProteiqueProductionLaitiere{
		if semaineLactation > 0{
			besoinProteiqueProductionLaitiere <- 53*productionLaitiere;
		}else{
			besoinProteiqueProductionLaitiere <- 0.0;
		}
	}
	
}


