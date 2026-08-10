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
 *  equipementDeCaptage
 *  Author: Maroussia Vavasseur
 *  Description: Pour le moment le pointPrelevementIRR donne un volume pour la ZH associe (les ilots prelevent arbitrairement dans un des PPirr de la ZH qui leur sont associes)
 */

model equipementDeCaptageIRR

import "ressourceEnEau.gaml"

global {	
	string pointsPrelevementIRRShape <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleHydrographique/equipements/pointsDePrelevement/irr/ppIrr.shp';
			
	/*
	 * *****************************************************************************************
	 * Publique
	 */ 
	action constructionEquipementsDeCaptageIRR{
		if !file_exists(pointsPrelevementIRRShape) 		{do raiseWarning("fichier des points de prélèvements pour l'irrigation inexistant: " + pointsPrelevementIRRShape);}
		//else if !is_shape(pointsPrelevementIRRShape) 	{do raiseWarning("le fichier des points de prélèvements pour l'irrigation n'est pas un fichier shape: " + pointsPrelevementIRRShape);}		
		do creationEquipements(cheminEntree:pointsPrelevementIRRShape, typeEquipement:equipementDeCaptageIRR);
	}
}

species equipementDeCaptageIRR parent: equipementDeCaptage{	
	string acteurAssocie <- IRR;
	rgb couleurEquipement <- rgb('green');				
	map<parcelle,float> mapVolumeSouhaiteParParcelle <- map<parcelle,float>([]); // parcelle::volumeSouhaiteIrrigation    mise a jour journalierement
	// Normatif
	secteurAdministratif secteurAdministratifAssocie <- nil;	
	bool isASA <- false;
	string idASA <- "";
	map<string, float> quota <- map<string, float>([]);
	map<string, float> quota_moyen_par_ha <- map<string, float>([]);
	map<string, float> quotaDebit <- map<string, float>([]);
	map<string, float> quotaDebit_moyen_par_ha <- map<string, float>([]);
	map<string, float> quota_anneePrec <-map<string, float>([]);
	map<string, float> quota_moyen_par_ha_anneePrec <- map<string, float>([]);
	map<string, float> quotaDebit_anneePrec <- map<string, float>([]);
	map<string, float> quotaDebit_moyen_par_ha_anneePrec <- map<string, float>([]);
	uniteDeDefinitionDuVP sonUniteDeDefinitionDuVP <- nil;
				
	/*
	 * *****************************************************************************************
	 * @Overwrite
	 */	
	action comportementJournalier{}		
	
	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	action miseAJourVolumeSouhaite{	
		arg volumeApreleverEntree type: float default: 0.0;
				
		float volumeSouhaite <- getVolumeSouhaite() + volumeApreleverEntree;

		ask ressourceAssociee{								
			do setMapVolumePreleveSouhaite(acteur: myself.acteurAssocie,valeur: volumeApreleverEntree);				
		}	
	}		

	/*
	 * *****************************************************************************************
	 *  @Overwrite
	 */
	action miseAJourVolumeReel{						
		arg pourcentage type: float default: 0.0;
		
		volumeReel <- getVolumeSouhaite() * pourcentage;
		ask ressourceAssociee{								
			do setMapVolumePreleveReel(acteur:myself.acteurAssocie, valeur: myself.volumeReel);				
		}
		
		// Mise a jour de la quantite irriguee sur les parcelles			
		list<parcelle> listeParcellesPR <- mapVolumeSouhaiteParParcelle.keys;
	 	ask listeParcellesPR{
	 		irrigationReelle <- irrigationReelle + ((myself.mapVolumeSouhaiteParParcelle at self) / surface * pourcentage) *
	 				 nombreMillimetreDansUnMetre / (1+EFFICIENCE_PPA_PARCELLE); 
	 				 // une parcelle peut etre appelle plusieurs (pour des points de preleveents differents)
			if memoireOTsurParcelle.keys contains IRRIGATION {
				put getITKAnnee() at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelle at IRRIGATION);
				map<string,string> complements <- (memoireOTsurParcelleComplements at IRRIGATION) at dateCour.nbJoursEcoulesDansAnnee;
				//write "parc " + idParcelle + " irrigDose: " + complements["irrigDose"] + "irrigReelle: " + complements["irrigReelle"];
				complements["irrigReelle"] <- string(float(complements["irrigReelle"]) + irrigationReelle); // MAJ irrigReelle (initialisée à 0.0 dans strategieIrrigation): peut être MAJ plusieurs fois si parcelle sur plusieurs équipements IRR
				//write "parc " + idParcelle + " irrigDose: " + complements["irrigDose"] + "irrigReelle: " + complements["irrigReelle"];
				put complements at: dateCour.nbJoursEcoulesDansAnnee  in: (memoireOTsurParcelleComplements at IRRIGATION);
			}
	 		// JV debug
	 		//write "parcellePR " + idParcelle + " irrigationReelle=" + irrigationReelle;
	 	}
	}
	
	float getVolumeSouhaite{
		return sum(mapVolumeSouhaiteParParcelle.values);
	}
			
	/*
	 * *****************************************************************************************
	 * On le remet a zero car pour les ppIRR il faut faire une somme recursive sur le volumeJournalier
	 */	
	action miseAzeroVolumeJouralier{	
		volumeReel <- 0.0;
		mapVolumeSouhaiteParParcelle <- map<parcelle,float>([]);
	}	
	
	// Utile pour mettre la priorite des equipements dans ilots
	string getTypologiePrioritaire{
		if(isASA){
			return ASA;
		}else{
			return typologie;
		}
	}
	
	zoneAdministrative getZaAssociee{
		if(secteurAdministratifAssocie != nil){
			return secteurAdministratifAssocie.zaAssociee;
		}else{
			return nil;
		}			
	}	
			
	bool isDisponibleJourCourant (materielIrrigation typeMaterielDeLIlot){	
		if(isRessourceDisponible() and !isEnRestrictionJourCourant(typeMaterielDeLIlot)){
			return true;
		}else{
			return false;
		}
	}		
	bool isRessourceDisponible{	
		if(ressourceAssociee.volumeDuJourPrecedent > 0.0){
			return true;
		}else{
			return false;
		}
	}
	// Si lequipement est considere comme etant jamais soumis a restriction
	bool isPpaPeutEtreEnRestriction{	
		if(!(typologie in RESSOURCE_NON_RESTREINTES)){ // typologie = NAPP_CO, SURF, ASA
			return true;
		}else{
			return false;
		}
	}
	
	bool isEnRestriction{	
		if(secteurAdministratifAssocie != nil and isPpaPeutEtreEnRestriction()){
			if(isASA and secteurAdministratifAssocie.getNiveauRestriction() < 3){
				return false;
			}else{
				return secteurAdministratifAssocie.isEnRestriction();
			}
		}else{
			return false;
		}
	}
	
	bool isEnRestrictionJourCourant (materielIrrigation typeMaterielDeLIlot){	
		if(isEnRestriction()){
			return secteurAdministratifAssocie.isEnRestrictionJourCourant(typeMaterielDeLIlot);
		}else{
			return false;
		}
	}
	int getNbJoursRestriction (materielIrrigation typeMaterielDeLIlot){
		if(isEnRestriction()){
			return secteurAdministratifAssocie.getNbJoursRestriction(typeMaterielDeLIlot);
		}else{
			return 0;
		}			
	}
	int getBaseDeDefinitionJoursDeRestriction{
		return secteurAdministratifAssocie.zaAssociee.getBaseDeDefinitionJoursDeRestriction();
	}
	int getNiveauRestriction{
		if(isEnRestriction()){
			return secteurAdministratifAssocie.getNiveauRestriction();
		}else{
			return 0;
		}			
	}					
			
	list<cultureIrrigable> getListeCultureIrrigueesPasDeTempsCourant{
		list<cultureIrrigable> listeCult <- [];
		ask(mapVolumeSouhaiteParParcelle.keys){
			listeCult << cultureIrrigable(cultureParcelle);		
		}
		return listeCult;
	}
	// dateJ est un jour julien
	float getQuota(int dateJ){
		return quota at getIndiceSousPeriode(dateJ);
	}
	action setQuota(int dateJ, float Q){
		put Q at: getIndiceSousPeriode(dateJ) in: quota;
	}
	float getQuotaAnnePrec(int dateJ){
		return quota_anneePrec at getIndiceSousPeriode(dateJ);
	}
	float getQuotaDebit(int dateJ){
		return quotaDebit at getIndiceSousPeriode(dateJ);
	}
	float getQuotaDebitAnnePrec(int dateJ){
		return quotaDebit_anneePrec at getIndiceSousPeriode(dateJ);
	}
	bool fenetreTempOkLocal(int jourC, int jourJulienFenetreMin, int jourJulienFenetreMax){
		if (jourJulienFenetreMax < jourJulienFenetreMin) {
			return jourC >= jourJulienFenetreMin or jourC <= jourJulienFenetreMax;	
 		}else {
			return jourC >= jourJulienFenetreMin and jourC <= jourJulienFenetreMax;
		}
 	}	 		 	
 	string getIndiceSousPeriode(int jourC){ //jourc peut être par exemple dateCour.nbJoursEcoulesDansAnnee
 		string id <- nil;
 		loop idMap over: sonUniteDeDefinitionDuVP.mapFenetresTemporellesDebutPeriodeQuota.keys{
 			if(fenetreTempOkLocal(jourC:( jourC), 
 				jourJulienFenetreMin:(sonUniteDeDefinitionDuVP.mapFenetresTemporellesDebutPeriodeQuota at idMap), 
 				jourJulienFenetreMax:(sonUniteDeDefinitionDuVP.mapFenetresTemporellesFinPeriodeQuota at idMap)
 			)){
 				id <- idMap;
 			}
 		}
 		return id;
 	} 
	
	/*
	 * *****************************************************************************************
	 * A chaque pas de temps on apelle cette methode
	 */
	bool isEnBesoinAgricoleFort{
		bool isBesoinFortSortie <-false;
		int nombreCultureIrrigueesStadePhenoAvance <- 0;
		
		ask(getListeCultureIrrigueesPasDeTempsCourant()){			
			if(parcelle_app.getKc() > 0.8){ // choix arbitraire de 0.8
				nombreCultureIrrigueesStadePhenoAvance <- nombreCultureIrrigueesStadePhenoAvance + 1;
			}								
		}
		
		// Si au moins une culture irriguee est dans un stade phenologique avance, alors on est en besoin fort
		if(nombreCultureIrrigueesStadePhenoAvance > 0){
			return true;
		}else{
			return false;
		}
	}			
}
