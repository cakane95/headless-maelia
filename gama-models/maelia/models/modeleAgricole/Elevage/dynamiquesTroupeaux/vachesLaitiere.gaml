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
 *  Vaches Laitiere
 *  Author: Theo Bullat
 *  Description: 
 */

model vachesLaitiere

import "velagePrimi.gaml"


species vachesLaitiere parent: vachesAdultes{
	
	float UGB <- 0.25; 
	int tauxProteique <- 32;
	int tauxButyreux<- 37;
	
	
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
		if rang = 0 or semaineLactation = 0{
			productionLaitiere <- 0.0;
		}else if semaineLactation != 0 and rang = 1{
			productionLaitiere <- (0.0038*0.9*prodLaitTheorique+0.9643)*(1.084-0.7*exp(-0.46*semaineLactation)-0.009*semaineLactation-0.69*exp(-0.16*(45-semaineGestation)));
		}else{
			productionLaitiere <- (0.0045*prodLaitTheorique+0.2222)*(1.047-0.69*exp(-0.9*semaineLactation)-0.0127*semaineLactation-0.5*exp(-0.12*(45-semaineGestation)));		}
	}
	
	action calculerCapaciteIngestion{
		float coeffIngestion <- 0.6;
		if rang > 1{
			coeffIngestion <- 0.7;
		}
		if rang = 0 {
			capaciteIngestion <- 0.0;
		}else {
			capaciteIngestion <- 13.9+(0.015*(poids-600))+(0.15*productionLaitiere)+(1.5*(3-noteEtat))
								*(coeffIngestion+(1-coeffIngestion)*(1-exp(-0.16*semaineLactation)))
								*(0.8+0.2*(1-exp(-0.25*(40-semaineGestation))))
								*(-0.1+1.1*(1-exp(-0.08*age)));
		}
	}
	
	action calculerBesoinEnergetiqueCroissance{
		if rang > 0 and age < 40 {
			besoinEnergetiqueCroissance <- 3.25-0.08*age;
		}else {
			besoinEnergetiqueCroissance <- 0.0;
		}
	}
	
	action calculerBesoinEnergetiqueGestation{
		if semaineGestation = 0{
			besoinEnergetiqueGestation <- 0.0;
		}else{
			besoinEnergetiqueGestation <- 0.00072 * poidsVeauNaissance * exp(0.116*semaineGestation);
		}
	}
	
	action calculerBesoinEnergetiqueEntretien{
		float coefEntretien <- 1.1;
//		if situation = "Pâturage"{
		if true{
			coefEntretien <- 1.2;
		}
		if poids =0 {
			besoinEnergetiqueEntretien <- 0.0;
		}else{
			besoinEnergetiqueEntretien <- 0.041*poids^0.75*coefEntretien;
		}
	}
	
	action calculerBesoinEnergetiqueProductionLaitiere{
		if semaineLactation = 0{
			besoinEnergetiqueProductionLaitiere <- 0.0;
		}else{
			besoinEnergetiqueProductionLaitiere <- (0.44+0.0055*(tauxButyreux-40)+0.0033*(tauxProteique-31))*productionLaitiere;
		}
	}
	
	action calculerBesoinProteiqueCroissance{
		if rang > 0 and age < 40 {
			besoinProteiqueCroissance <- 422-10.4*age;
		}else{
			besoinProteiqueCroissance <- 0.0;
		}
	}
	
	action calculerBesoinProteiqueGestation{
		if semaineGestation = 0{
			besoinProteiqueGestation <- 0.0;
		}else{
			besoinProteiqueGestation <- 0.07*poidsVeauNaissance*exp(0.111*semaineGestation);
		}
	}
	
	action calculerBesoinProteiqueEntretien{
		besoinProteiqueEntretien <- 3.25*poids^0.75;
	}
	
	action calculerBesoinProteiqueProductionLaitiere{
		if semaineLactation = 0{
			besoinProteiqueProductionLaitiere <- 0.0;
		}else{
			besoinProteiqueProductionLaitiere <- 1.56*tauxProteique*productionLaitiere;
		}
	}
	
}


