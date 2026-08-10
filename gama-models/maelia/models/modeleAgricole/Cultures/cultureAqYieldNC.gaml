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
 *  cultureAqYieldNC
 *  Author: Renaud Misslin
 *  Description: La culture est une entite qui ne va exister qu'entre le jour de son semi et celui de sa recolte. Elle est semee sur une parcelle.
 */

model cultureAqYieldNC

import "../Parcelles/parcelleAqYieldNC.gaml"
import "../StrategiesIrrigation/strategieIrrigation.gaml"   

global{
    
    }

species cultureAqYieldNC  parent:cultureAqYield{
        
    float QN_demande_jour <- 0.0;
    float QN_demande_jour_stressH <- 0.0; //Hugues 210512
    float QN_demande_cumul_stressH <- 0.0;//Hugues 210512
    list<float> QN_acquis10j <- [];
    float QN_demande_cumul_prec <- 0.0;
    float QN_demande_cumul <- 0.0;
    list<float>  QN_demande10j <- [];
    float QN_acquis_fin_frein <- 0.0;
    float QN_demande_fin_frein <- 0.0;
    float QN_acquis_Em500DD <- 0.0;
    float QN_acquis_sans_mic <- 0.0;
    int cas_demande_azote <- 0;
    list<float> INN_periode_culture <- [];
    //list<float> INN_journaliers <- [];
    float effetN_kc <- 1.0;
    float QNfix <- 0.0;
    float dkcMAX_to_suppr <- 0.0;
    float demandeN_j;
    int emergence_duration <- 0;
    int DWR <- 0;// nb of consecutive days without significant water input (daily rainfall or irrigation < 3mm) see Tribouillois et al EJA 93 (2018) 73-81
    list<float> indiceSatifactionHydrique_10j;
    float ISH10 <- 0.0;
    bool is_MSA_exportee <- false;
    
    float sommeDegresJourCulture_depuisSemisPrec <- 0.0;
    float sommeDegresJourCulture_depuisSemisCorrectionFrein <- 0.0;
    float sommeDegresJourCulture_depuisSemisCorrectionFreinPrec <- 0.0;
    float sommeDegresJourCulture_depuisLevee <- 0.0;
    float sommeDegresJourCulture_depuisLeveePrec <- 0.0;
    float sommeDegresJourCultureFinFrein <- 0.0;
    float sommeDegresJourCultureFloraison <- 0.0;
    float sommeDegresJourCultureMaturite <- 0.0;
    
    float dKc_save; // Enregistrement du dKc pour comparaison AqYield Excel / Maelia

	float Nmin_cumul_corpen <- 0.0; // Nmin_total cumulé depuis le semis (utilisé pour calculer l'abattement corpen)

    //*************************************************
    // Debug
    float MSA <- 0.0;
    float MSR <- 0.0;
    
    // Tests stockage carbone forcés
    bool fertilisation_realisee <- false;
    int cpt_ferti <- 1;
    //*************************************************
        
    action initialisationCulture{
        //write "Initialisation culture";
        anneeCreation <- dateCour.annee;
        if(dateCour.mois >= moisDebutCultureHiver or dateCour.mois <= moisFinCultureHiver){
            isCultureHiver <- true;
        }        
        date_semis <- dateCour.calculNbJourEcouleDansAnnee(dateCour.jour, dateCour.mois);
        
        // Initialisation azote
        QN_acquis_cumul <- 0.0;
        QN_demande_cumul <- 0.0;
        // Type de culture pour la demande en azote, types = FloMat (1, ex: colza, tournesol), CstFloMat (2, ex: blé, orge), CI (3), Cst (4, ex: maïs, soja), 500Mat (5, ex: feverole, pois), CIfrein (6, ex: rgi)            
        if(espece.Type_Nacq  = "FloMat"){// Cas n° 1 : un point d'inflexion et pas de frein
            cas_demande_azote <- 1;
        }            
        else if (espece.Type_Nacq  = "CstFloMat") {// Cas n° 2 : un point d'inflexion et frein
            cas_demande_azote <- 2;
        }            
        else if (espece.Type_Nacq  = "CI") {// Cas n° 3 : courbe de demande CI
            cas_demande_azote <- 3;
        }    
        else if (espece.Type_Nacq  = "Cst") {// Cas n° 4 : une courbe de demande droite
            cas_demande_azote <- 4;
        }    
        else if (espece.Type_Nacq  = "500Mat") {// Cas n° 5 : 500Mat légumineuses
            cas_demande_azote <- 5;
        }            
         else if (espece.Type_Nacq  = "CIfrein") {// Cas n° 6 : type Ci avec frein
            cas_demande_azote <- 6;
        }
        
        // Mode de gestion des pailles (exportation ou restitution)
        if (!empty(parcelle_app.systemeDeCultureParcelle.rotationGestionPailles)) {
	        if (parcelle_app.systemeDeCultureParcelle.rotationGestionPailles[parcelle_app.systemeDeCultureParcelle.indiceItkCourant] in ["exp", "exportation"]) {
	        	is_MSA_exportee <- true;
	        }
        }
        
        // Sélection de l'alternative de fertilisation pour l'ITK appliqué à la culture en cours // ceci devrait être supprimé
//        if (plusieursFertilisationsParITK and parcelle_app.getITKAnnee().contientStrategiesFerti) {
//            ask parcelleAqYieldNC(parcelle_app) {
//                //write "-ITKFERTi- création de la culture";
//                write "debug - Prélèvement cultureAqYieldNC";
//                do selection_alternative_ferti;
//            }
//        }
        
        // Calcul du retard de levée au moment de l'implantation d'un couvert
        // Ajouter une condition pour n'effectuer le calcul de DWR pour emergence_duration seulement si la culture est un CI
        if (espece.Type_Nacq  = "CIfrein" or espece.Type_Nacq  ="CI"){
            if (parcelle_app.getPluie() >= 3.0) { // si pluie >= 3 mm le jour du semis alors DWR = 0
                DWR <- 0;
            } else {
                if (parcelle_app.getITKAnnee().isIrriguee()) { // - Si ITK avec irrigation et pas de pluies >= 3 mm dans les 3 jours suivants le semis 
                    list<float> liste_pluies_prevues <- parcelle_app.ilot_app.meteo.liste_pluies_futur(3);
                    loop i from: 0 to: length(liste_pluies_prevues) -1 {
                        if (liste_pluies_prevues[i] >= 3.0) {
                            DWR <- 1 + i;
                            //write "ITK irrigué -- pluies prévues -> " + liste_pluies_prevues;
                            break;
                        }
                        if (DWR = 0) { // Si pas de pluie >= 3 mm dans les 3 prochains jours, DWR = 3 (on considère que l'irrigation arrivera dans les 3 jours suivant le semis)
                            DWR <- 3;
                        }
                    }
                } else { // - Si ITK sans irrigation, on calcule quand aura lieu la prochaine pluie >= 3 mm dans les 50 prochains jours
                    list<float> liste_pluies_prevues <- parcelle_app.ilot_app.meteo.liste_pluies_futur(50);
                    loop i from: 0 to: length(liste_pluies_prevues) -1 {
                        if (liste_pluies_prevues[i] >= 3.0) {
                            DWR <- 1 + i;
                            //write "ITK non irrigué -- pluies prévues -> " + liste_pluies_prevues;
                            break;
                        }
                    }
     
                    if (DWR = 0) { // Si pas de pluie >= 3 mm dans les 50 prochains jours, DWR = 50 (on borne à 50 jours)  
                        DWR <- 50;
                    }
                }
            }
            
            float sm <- (parcelleAqYield(parcelle_app).Hs + parcelleAqYield(parcelle_app).HPFs_mm) * parcelle_app.ilot_app.sol.HCCw / (parcelleAqYield(parcelle_app).RUsPrec + parcelleAqYield(parcelle_app).HPFs_mm); // Soil moisture (%) // Modif Renaud RUs remplacé par RUsPrec à cause de division par 0 dans "float sm" (cultureAqYieldNC) 290421
            emergence_duration <- int(6.9 - 0.29*sm + 0.44*DWR + 0.03*espece.Dde); // equation calculating emergence duration in days (cf Tribouillois et al, 2018)
        	
        }
        
		// Calcul de la profondeur maximale pouvant être atteinte par les racine pour la culture courante // Renaud 30052023
		parcelleAqYield(parcelle_app).RUr_max <- RUr_max_culture_courante();
//		write "parcelle_app.RUr_max = " + parcelleAqYield(parcelle_app).RUr_max;
//		write "parcelle_app.RUm = " + parcelleAqYield(parcelle_app).RUm;
    }

    /*
     * *****************************************************************************************
     * MODELE AQYIELD
     * Appelee dans parcelle
     */         
    action croissanceCulture { // Overwrite
    	
    	// Maj du Nmin cumulé si adaptation ferticorpen
    	if (adaptationFertilisation = "corpen") {
    		Nmin_cumul_corpen <- Nmin_cumul_corpen + parcelleAqYieldNC(parcelle_app).DNhum_MO_cm_j_sortie;
    	}
    	
        //write "Température ---> " + parcelle_app.getTmoy();
        //write "HS = " + parcelleAqYield(parcelle_app).Hs + " - HPFs_mm = " + parcelleAqYield(parcelle_app).HPFs_mm + " - HCCw = " + parcelle_app.ilot_app.sol.HCCw + " - RUs = " + parcelleAqYield(parcelle_app).RUs;
//        write espece.idEspeceCultivee + " - echveg = " + echV;
        
        float sm <- (parcelleAqYield(parcelle_app).Hs + parcelleAqYield(parcelle_app).HPFs_mm) * parcelle_app.ilot_app.sol.HCCw / (parcelleAqYield(parcelle_app).RUs + parcelleAqYield(parcelle_app).HPFs_mm); // Soil moisture (%)
        //write "sm = " + sm;
		
        // 1. Calcul de la somme de degrés jour     
        // Somme de degrés jour depuis le semis
        if (echV > 0) { // La somme de degrés jour depuis semis n'est calculée qu'à partir du deuxième jour où echV > 0
            sommeDegresJourCulture_depuisSemisPrec <- sommeDegresJourCulture_depuisSemis;
            float DegresJourCulture <- min([espece.tmax, parcelle_app.getTmoy()]);
            DegresJourCulture <- max([0, DegresJourCulture - espece.tbase]);
            sommeDegresJourCulture_depuisSemis <- sommeDegresJourCulture_depuisSemis + DegresJourCulture;
			sommeDegresJourCulture <- sommeDegresJourCulture_depuisSemis; // RM 121125 issue #39
            
            // Somme de degrés jour depuis le semis corrigé par le frein
            sommeDegresJourCulture_depuisSemisCorrectionFreinPrec <- sommeDegresJourCulture_depuisSemisCorrectionFrein;
             if(isCultureHiver and ((dateCour.annee = anneeCreation and dateCour.nbJoursEcoulesDansAnnee >= indexDateDebutFrein) or (dateCour.annee != anneeCreation and dateCour.nbJoursEcoulesDansAnnee <= indexDateFinFrein))){
                sommeDegresJourCulture_depuisSemisCorrectionFrein <- sommeDegresJourCulture_depuisSemisCorrectionFrein + DegresJourCulture * espece.freinCult;
            } else {
                sommeDegresJourCulture_depuisSemisCorrectionFrein <- sommeDegresJourCulture_depuisSemisCorrectionFrein + DegresJourCulture;
            }
        }

        // Somme de degrés jour depuis la levée
        if (kc > 0) { // La somme de degrés jour depuis levée n'est calculée qu'à partir du deuxième jour où kc > 0
            sommeDegresJourCulture_depuisLeveePrec <- sommeDegresJourCulture_depuisLevee;
            float DegresJourCulture <- min([espece.tmax, parcelle_app.getTmoy()]);
            DegresJourCulture <- max([0, DegresJourCulture - espece.tbase]);
            sommeDegresJourCulture_depuisLevee <- sommeDegresJourCulture_depuisLevee + DegresJourCulture;
            //sommeDegresJourCulture <- sommeDegresJourCulture_depuisSemis; // RM 121125 issue #39
        }
        
        // 2. Echelle vegetation
        float detlaEchelleVegetation <- (max([min([parcelle_app.getTmoy(), espece.tmax]) - espece.tbase,0.0]) / espece.degresJourAfloraisonCult);    
         
        // 3. Frein (si dans annee de semis de culture hiver ou si avant 15/02)
        if(isCultureHiver and ((dateCour.annee = anneeCreation and dateCour.nbJoursEcoulesDansAnnee >= indexDateDebutFrein) or (dateCour.annee != anneeCreation and dateCour.nbJoursEcoulesDansAnnee <= indexDateFinFrein))){
            // frein <- frein + detlaEchelleVegetation * (1-espece.freinCult) ; // Modifié Renaud (Rdv Hélène 03/04/18) --> Le frein n'a pas besoin d'être calculé, son effet est donné par espece.freinCult
            detlaEchelleVegetation <- detlaEchelleVegetation * espece.freinCult; // Le frein est utilisé ici une première fois modif_frein
        } else if(sommeDegresJourCultureFinFrein = 0.0 and isCultureHiver and ((dateCour.nbJoursEcoulesDansAnnee <= indexDateDebutFrein and dateCour.nbJoursEcoulesDansAnnee >= indexDateFinFrein) and dateCour.annee != anneeCreation)){
            sommeDegresJourCultureFinFrein <- sommeDegresJourCulture_depuisSemisCorrectionFrein;
            QN_acquis_fin_frein <- QN_acquis_cumul;
            QN_demande_fin_frein <- QN_demande_cumul;
        }
        //write "QN_acquis_fin frein : " + QN_acquis_fin_frein;
        echV <- echV + detlaEchelleVegetation; //modif_feuillage
        if(echV >= 1 and kc_flo = 0.0){
            kc_flo <- kc;
        }
        
        // 3bis. ajout hugues, calculation:  N uptake from emergence to 500DD, type 500Mat
        if (espece.Type_Nacq  = "500Mat" and sommeDegresJourCulture_depuisSemis > espece.degresJourLeveeCult + 500 and QN_acquis_Em500DD = 0){
            QN_acquis_Em500DD <- QN_acquis_cumul;
        }
        
        // Stockage de valeurs de degrés jour pour courbes d'acquisition
        if (sommeDegresJourCultureFloraison = 0.0 and echV >= 1) {
            sommeDegresJourCultureFloraison <- sommeDegresJourCulture_depuisLevee;
        } else if (sommeDegresJourCultureMaturite = 0.0 and echV >= espece.echelleVegetationStadeMaturite) {
            sommeDegresJourCultureMaturite <- sommeDegresJourCulture_depuisLevee;
        }
                
        // 4. Coefficient cultural    
        //write "Moy. flottante ISH -> indiceSatifactionHydrique = " + indiceSatifactionHydrique + " (cultureAqYieldNC.gaml)";
        // Calcul de l'indice de satisfaction hydrique moyen sur 10 jours
        if (kc > 0.0){
            if (length(indiceSatifactionHydrique_10j) < 10) {
                indiceSatifactionHydrique_10j <+ indiceSatifactionHydrique;
                ISH10 <- indiceSatifactionHydrique;
            } else {
                indiceSatifactionHydrique_10j[] >>- 0; // L'indice le plus ancien de la liste est retiré
                indiceSatifactionHydrique_10j <+ indiceSatifactionHydrique;
                ISH10 <- mean(indiceSatifactionHydrique_10j);
            }
        }
        //write "indice stress hydrique 10 jours = " + ISH10;
        // Calcul du stress azoté qui agit sur le coefficient cultural (dKcMax)
        // Calcul du dKc
        float lj <- dateCour.longueurDuJour;            
        float coefTemp <- 1000.0;
        float dKcMax <- (parcelle_app.getTmoy() / coefTemp) * (lj*3) * indiceSatifactionHydrique * (effetN_kc - kc); // Ajouter effetN_kc pour avoir l'effet de l'azote sur la plante
        
        dkcMAX_to_suppr <- dKcMax;
        float dKc <- 0.0;

        if ((echV < espece.echelleVegetationStadeLevee)){
            dKc <- 0.0;
        } else if ((echV >= espece.echelleVegetationStadeLevee) and (echV <= espece.echelleVegetationStadeFloraison)){
            dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (lj*3) * indiceSatifactionHydrique * espece.coefVigueurVegetativeCult * (echV^1.5)]);
            dKc <- max([0.0, dKc]);

//            if (meanINN10j >= 0.6 ) { // signe à changer
//                dKc <- max([0.0, dKc]);
//            }
        } else {
            dKc <- min([dKcMax, (parcelle_app.getTmoy() / coefTemp) * (- 2)*(((echV-1)/(espece.echelleVegetationStadeMaturite-1))^2.5)]);
        }
        
        if (echV >= espece.echelleVegetationStadeLevee) {
            kc <- min([espece.coefCulturalMax, kc + dKc]);
            kc <- max([0.0, kc]);
        } else {
            kc <- 0.0;
            QN_demande_jour <- 0.0;
            kc_flo <- 0.0; //modif_feuillage --> à vérifier qu'il est bien réinitialisé au bon endroit            
        }
        dKc_save <- dKc;
        if (avecStressClimatique) {
			do calculJourEchaudant;
			do destructionGel;
		}
        do changementCouleurEnFonctionKc();
     }
     
     /*
     * *****************************************************************************************
    AqYield - partie Azote
     */
    
    float estimation_QNdemande_plante_j {
        float resultat <- 0.0;
        // Calcul de la demande en fonction du cas 
        switch cas_demande_azote {
            // Cas n° 1 : un point d'inflexion et pas de frein type FloMat (ex : tournesol, colza)
            match 1 {
//                write "cas 1 : tournesol";
                // Période pré-floraison
                //write "Acquisition des couverts : sommeDegresJourCulture_depuisLevee = " + sommeDegresJourCulture_depuisLevee + " -- >= debut_besoin_N --> " + (sommeDegresJourCulture_depuisLevee >= espece.debut_besoin_N);
                if(sommeDegresJourCulture_depuisLevee >= espece.debut_besoin_N and echV < 1){
                    resultat <- QN_demande_cumul_prec + (espece.pre_floraison_besoin_N * espece.QNmax / (espece.degresJourAfloraisonCult - espece.debut_besoin_N - espece.degresJourLeveeCult)) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                    //write "pre_floraison_besoin_N = " + espece.pre_floraison_besoin_N + " -- QNmax = " + espece.QNmax + " -- degresJourAfloraisonCult = " + espece.degresJourAfloraisonCult + " -- debut_besoin_N = " + espece.debut_besoin_N + " -- degresJourLeveeCult" + espece.degresJourLeveeCult + " -- sommeDegresJourCulture_depuisLevee = " + sommeDegresJourCulture_depuisLevee + " -- sommeDegresJourCulture_depuisLeveePrec = " + sommeDegresJourCulture_depuisLeveePrec; 
                }
                // Période pré-maturité
                else if (echV >= 1 and echV < espece.degresJourMaturiteCult / espece.degresJourAfloraisonCult) {
                    resultat <- QN_demande_cumul_prec + (espece.pre_maturite_besoin_N * espece.QNmax / (espece.degresJourMaturiteCult - espece.degresJourAfloraisonCult)) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                } else {
                    resultat <- QN_demande_cumul_prec;
                }
                //write 'Acquisition des couverts : demandeJ = ' + resultat;
            }
            
            // Cas n° 2 : un point d'inflexion et frein de culture d'hiver type CstFloMat (ex : blé)
            match 2 {
//                write "cas 2 : céréale à paille";// colza en test 2020-12-16  
//                write "estimation_QNdemande_plante_j espece=" + espece.idEspeceCultivee + " sommeDegresJourCulture_depuisLevee=" + sommeDegresJourCulture_depuisLevee + " espece.debut_besoin_N=" + espece.debut_besoin_N;              
                
                if (sommeDegresJourCulture_depuisLevee >= espece.debut_besoin_N){                
                    // Avant période de frein (modif Hugues 2020-12-16 pour colza)
                    if (dateCour.nbJoursEcoulesDansAnnee <= indexDateDebutFrein and dateCour.annee = anneeCreation and echV < 1) {
                        resultat <- QN_demande_cumul_prec + (espece.pre_floraison_besoin_N * espece.QNmax / (espece.degresJourAfloraisonCult - espece.debut_besoin_N - espece.degresJourLeveeCult)) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec); 
//						write "cas 2.1 res=" + resultat + " espece.pre_floraison_besoin_N=" + espece.pre_floraison_besoin_N + " espece.QNmax=" + espece.QNmax + " espece.degresJourAfloraisonCult=" + " espece.debut_besoin_N=" + espece.debut_besoin_N + " espece.degresJourLeveeCult=" + espece.degresJourLeveeCult;
                    }
                    //Période de frein
                    else if(isCultureHiver and ((dateCour.annee = anneeCreation and dateCour.nbJoursEcoulesDansAnnee >= indexDateDebutFrein) or (dateCour.annee != anneeCreation and dateCour.nbJoursEcoulesDansAnnee <= indexDateFinFrein))){
                        resultat <- QN_demande_cumul_prec + espece.frein_besoin_N * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
//						write "cas 2.2 res=" + resultat + " espece.frein_besoin_N=" + espece.frein_besoin_N;
                    }                                    
                    // Période pré-floraison
                    else if((dateCour.nbJoursEcoulesDansAnnee > indexDateFinFrein and dateCour.annee != anneeCreation) and echV < 1) {
//                        resultat <- QN_demande_cumul_prec + ((espece.pre_floraison_besoin_N * espece.QNmax - QN_acquis_fin_frein) / (espece.degresJourAfloraisonCult - sommeDegresJourCultureFinFrein)) * (sommeDegresJourCulture_depuisSemisCorrectionFrein - sommeDegresJourCulture_depuisSemisCorrectionFreinPrec); // enregistrer la quantité d'azote acquise à la fin du frein --> correction faite le 290421
                        resultat <- QN_demande_cumul_prec + (max([0,(espece.pre_floraison_besoin_N * espece.QNmax - QN_demande_fin_frein)]) / (espece.degresJourAfloraisonCult - sommeDegresJourCultureFinFrein)) * (sommeDegresJourCulture_depuisSemisCorrectionFrein - sommeDegresJourCulture_depuisSemisCorrectionFreinPrec);
						//write "cas 3 res=" + resultat;
                    }
                    // Période pré-maturité
                    else if(echV >= 1 and sommeDegresJourCulture_depuisSemisCorrectionFrein < espece.degresJourMaturiteCult){
                        resultat <- QN_demande_cumul_prec + (espece.pre_maturite_besoin_N * espece.QNmax / (espece.degresJourMaturiteCult - espece.degresJourAfloraisonCult)) * (sommeDegresJourCulture_depuisSemisCorrectionFrein - sommeDegresJourCulture_depuisSemisCorrectionFreinPrec);
						//write "cas 4 res=" + resultat + " espece.pre_maturite_besoin_N=" + espece.pre_maturite_besoin_N + " espece.QNmax=" + espece.QNmax + " espece.degresJourMaturiteCult=" + espece.degresJourMaturiteCult + " espece.degresJourAfloraisonCult=" + espece.degresJourAfloraisonCult;
                    } else {
                        resultat <- QN_demande_cumul_prec;
						//write "cas 5 res=" + resultat;
                    }
                }    
            }
            
            // Cas n° 3 :  type CI
            match 3 {
//                write "cas 3 : CI";
                // AVant la levée
                if (sommeDegresJourCulture_depuisSemis < espece.degresJourLeveeCult + espece.debut_besoin_N){
                    resultat <- QN_demande_cumul_prec + 0;
                } 
                // Après la levée
                else {
                    resultat <- QN_demande_cumul_prec + (- espece.a_Ndemand_ci * date_semis + espece.b_Ndemand_ci) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                }
//                write "demande CI = " + resultat;
            }
            
            // Cas n° 4 : une courbe de demande droite type Cst (ex : maïs, soja)
            match 4 {
//                write "cas 4 : maïs, soja";
                if (sommeDegresJourCulture_depuisSemis >= espece.degresJourLeveeCult + espece.debut_besoin_N and sommeDegresJourCulture_depuisSemis < espece.degresJourMaturiteCult){
                    if (espece.besoin_N_total > 0 and espece.besoin_N = nil) { // (betterave ou pdt
	                  	resultat <- QN_demande_cumul_prec + (espece.besoin_N_total / (espece.degresJourMaturiteCult - espece.debut_besoin_N - espece.degresJourLeveeCult)) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
					} else { //(mais soja)
                    	resultat <- QN_demande_cumul_prec + (espece.QNmax / (espece.degresJourMaturiteCult - espece.debut_besoin_N - espece.degresJourLeveeCult)) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                    }
                } else {
                    resultat <- QN_demande_cumul_prec;
                }
            }
        
            // Cas n° 5 : type 500Mat (feverole, pois); Ndemand: emergence to emergence + 500DD = 0.0044 per DD then (Nmax-Nup500DD)/(SumDDmat-(SumDDem+500 DD)) per DD 
            match 5 {
//                write "cas 5 : 500Mat";
                if (sommeDegresJourCulture_depuisSemis >= espece.degresJourLeveeCult  and sommeDegresJourCulture_depuisSemis <= espece.degresJourLeveeCult + 500){
                    resultat <- QN_demande_cumul_prec +  espece.coef_500Mat * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                } else if (sommeDegresJourCulture_depuisSemis > espece.degresJourLeveeCult + 500 and sommeDegresJourCulture_depuisSemis < espece.degresJourMaturiteCult){
                    resultat <- QN_demande_cumul_prec + ((espece.QNmax - QN_acquis_Em500DD) / (espece.degresJourMaturiteCult - (espece.degresJourLeveeCult + 500))) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                } else {
                    resultat <- QN_demande_cumul_prec;
                }
            }        
        
            // Cas n° 6 : type CI avec frein (rgi)
            match 6 {
//                write "cas 6 : CI frein";
                // AVant la levée               
                if (sommeDegresJourCulture_depuisSemis < espece.degresJourLeveeCult){
                    resultat <- QN_demande_cumul_prec + 0;
                } 
                // Après la levée
                else {
                    resultat <- QN_demande_cumul_prec + (- espece.a_Ndemand_ci * date_semis + espece.b_Ndemand_ci) * (sommeDegresJourCulture_depuisLevee - sommeDegresJourCulture_depuisLeveePrec);
                }
            }    
        
        }
        
        return resultat;
    }
    
    // 1. Calcul de la demande effective totale
    float QNdemande_j {
        // Update des variables qui concernent la demande
        QN_demande_cumul_prec <- QN_demande_cumul;
        QN_demande_cumul <- estimation_QNdemande_plante_j();
        QN_demande_jour <- QN_demande_cumul - QN_demande_cumul_prec;
        QN_demande_jour_stressH <- QN_demande_jour * ISH10; //Hugues 210512
        QN_demande_cumul_stressH <- QN_demande_cumul_stressH + QN_demande_jour_stressH;//Hugues 210512
                    
        return QN_demande_jour * ISH10;//return QN_demande_jour modif hugues + *ISH10
    }
    
    // 2. Calcul de la demande de la plante dans W avant le prélèvement N par les microorganismes
    float demande_plante_w {
        demandeN_j <- QNdemande_j();
        float offreN <- parcelleAqYieldNC(parcelle_app).QNacq_pot(availN_w_arg: parcelleAqYieldNC(parcelle_app).availN_w);
        //write "avail N w pour QN_pot demande pot plante : "+parcelleAqYieldNC(parcelle_app).availN_w;
        QN_acquis_sans_mic <- min([demandeN_j, offreN]);
        
        return QNacq_w(profR: parcelleAqYieldNC(parcelle_app).profR, 
                                          profW: parcelleAqYieldNC(parcelle_app).ilot_app.sol.profHum,
                                          QNinitialeJ_w_arg: parcelleAqYieldNC(parcelle_app).availN_w,
                                          QNfinaleJ_r_arg: parcelleAqYieldNC(parcelle_app).QNfinaleJ_r,
                                          QN_acquis_arg: QN_acquis_sans_mic
                                  );
    }
    
    // 3. Consommation N
    action consommationN {
        float offreN <- parcelleAqYieldNC(parcelle_app).QNacq_pot(availN_w_arg: parcelleAqYieldNC(parcelle_app).availN_w_plant);
//        write "Renaud rendement couvert ---> offreN = " + offreN;
//        write "Renaud rendement couvert ---> demandeN_j = " + demandeN_j;
        //write "avail N w pour QN_pot action consoN : "+parcelleAqYieldNC(parcelle_app).availN_w_plant;
        
        QN_acquis <- min([demandeN_j, offreN]); // demandeN_j est actualisé dans demande_plante_w()
        QN_acquis_cumul <- QN_acquis_cumul + QN_acquis;
        parcelleAqYieldNC(parcelle_app).sortie_acquisition <- QN_acquis_cumul; // Variable à supprimer utilisée pour vérifier le bilan N
    }
    
    // Azote acquis dans l'horizon W
    // float calculReserveAccessibleRacine{    
//         arg RUrPrecEntree type: float default: 0.0;    
//         arg noteQualiteStructureSolEntree type: float default: 0.0;
    float QNacq_w {
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
        arg QN_acquis_arg type: float default: 0.0; // Cet argument peut prendre 2 valeurs : QN_acquis ou QN_acquis_sans_mic 
        
        float resultat <- 0.0;
        if (profR > 0) {
            resultat <- min([QNinitialeJ_w_arg, QN_acquis_arg * profW / profR + max([0.0, (QN_acquis_arg * (profR - profW) / profR - QNfinaleJ_r_arg)])]); // les paramètres sont en arguments pour simplifier la lecture
        }
        return resultat;
    }

    float QNacq_r {
        arg profR type: float default: 1.0; 
        arg profW type: float default: 0.0;
        arg QNinitialeJ_w_arg type: float default: 0.0; // parcelleAqYield(parcelle_app).QNinitialeJ_w
        arg QNfinaleJ_r_arg type: float default: 0.0;
        arg QN_acquis_arg type: float default: 0.0;
        
        float resultat <- min([QNfinaleJ_r_arg, QN_acquis_arg * (profR - profW) / profR + max([0.0, (QN_acquis_arg * profW / profR - QNinitialeJ_w_arg)])]);
        return resultat;
    }
    
    // Calcul du stress azoté
    action updateINN10j {
        //write "QNacquis : "+QN_acquis;
        // Update QNdemande10j et  QNacquis10j
        //if (QN_demande_jour > 0 and QN_acquis != QN_demande_jour_stressH){
        //    INN_journaliers << QN_acquis / QN_demande_jour_stressH;//Hugues 210512
        //} else {
        //    INN_journaliers << 1.0;    
        //}        
        //write INN_journaliers;
        
        if(length(QN_demande10j) < 10 and QN_acquis_cumul > 0){
            QN_acquis10j << QN_acquis;
            QN_demande10j << QN_demande_jour_stressH;//Hugues 210512
            
        } else if (QN_acquis_cumul > 0)  {
            
            // QNacquis10j
            list<float> newQN_acquis10j <- [];
            loop i from: 1 to: length(QN_acquis10j) - 1 {
                newQN_acquis10j << QN_acquis10j[i];
            }
            QN_acquis10j <- newQN_acquis10j;
            QN_acquis10j << QN_acquis;
            
            // QNdemande10j
            list<float> newQN_demande10j <- [];
            loop i from: 1 to: length(QN_demande10j) - 1 {
                newQN_demande10j << QN_demande10j[i];
            }
            QN_demande10j <- newQN_demande10j;
            QN_demande10j << QN_demande_jour_stressH;//Hugues 210512
        }
        
        // Calcul de l'INN
        if (sum(QN_acquis10j) > 0 and sum(QN_demande10j) > 0) {
            meanINN10j <- sum(QN_acquis10j) / sum(QN_demande10j);
        }
        
        INN_periode_culture << meanINN10j;
    }
    
    action calculStressN {
        if (echV <= espece.echelleVegetationStadeMaturite and QN_acquis_cumul > 0) {
            do updateINN10j;
        }

        effetN_kc <- espece.coefCulturalMax;
        
        // Effet du stress azoté 
        if (!espece.isLEG) { // Suppression de l'effet du stress N sur le Kc pour les légumineuse olivier + renaud 140823
	        if (meanINN10j < 0.6 and espece.idEspeceCultivee = "CP" and QN_acquis_cumul > 0) { // Le blé n'est affecté que lorsque l'INN est inf à 0.6 (cf "Modélisation de la réponse à l’azote du rendement des grandes cultures et intégration dans un modèle économique d’offre agricole à l’échelle européenne. Application à l’évaluation des impacts du changement climatique")
	            effetN_kc <- meanINN10j * espece.coefCulturalMax;
	        } else if (espece.idEspeceCultivee != "CP" and QN_acquis_cumul > 0) { // Les autres espèces sont affectées quelque soit la valeur de l'INN
	            effetN_kc <- meanINN10j * espece.coefCulturalMax;
	        }
	    }
    }
    
    // Opérations effectuee à la récolte
    float calculRendement{ // Overwrite
        float rendement <- 0.0;
        float MSA_couvert <- 0.0; // Masse sèche aérienne totale du couvert
        float MSA_exportee <- 0.0; // Masse sèche aérienne exportée (couvert ou coproduit de culture principale)
        
        if (avecStressClimatique and espece.degresJourDebutRemplissage > 0 and nJoursRemplissageGrain > 0) {
	 		risqueEchaudage <- nJoursEchaudants / nJoursRemplissageGrain * 100;
	 	}
        
        // Part de biomasse restituée
        float Pss <- 1.0;
        if (is_MSA_exportee = true){
            Pss <- espece.Pse;
        }
        
        // Si la culture est un couvert intermédiaire, la biomasse est estimée à partir de la quantité de N acquis (cf a_N_to_DM dans especeCultivee.gaml)
        if (espece.isCouvert) {
            if (!espece.isLEG) {//Hugues 210512
				MSA_couvert <- exp(ln((QN_acquis_cumul ) /10/espece.adil/max([0.5,mean(INN_periode_culture)]))/(1-espece.bdil)); // Hugues + Renaud modif du 260723 + MD 04072024
//            	write "RECOLTE espece = " + espece.idEspeceCultivee + " --- MSA_couvert = " + MSA_couvert + " --- QN_acquis_cumul  = " + QN_acquis_cumul + " ---- INN_periode_culture = " + INN_periode_culture;
            }else{    //Hugues 210512
                QNfix <- QN_demande_cumul_stressH - QN_acquis_cumul;//Hugues 210512
//                write "QN_acquis_cumul = " + QN_acquis_cumul;
 //               write "espece = " + espece.idEspeceCultivee + " --- QN_demande_cumul_stressH  = " + QN_demande_cumul_stressH + " ---- espece.adil = " + espece.adil + " ---- adil = " + espece.adil + " ---- INN_periode_culture = " + INN_periode_culture;//Hugues 210512
//                write "QNfix = " + QNfix;
            	rendement <- exp(ln((QN_demande_cumul_stressH* espece.SR_ratio * espece.C_aer / (espece.SR_ratio * espece.C_aer +  1.65 * espece.C_rac))/10/espece.adil)/(1-espece.bdil));//Hugues 210512 - maj olivier+renaud 140823
				if (QN_demande_cumul_stressH = 0) { // JV 050625 reintroduction correction MD cf issue #22
						MSA_couvert <- 0.0; // MD 11092024
					}else{
						MSA_couvert <- exp(ln((QN_demande_cumul_stressH ) /10/espece.adil/max([0.5,mean(INN_periode_culture)]))/(1-espece.bdil)); // Hugues + Renaud modif du 260723 + MD 04072024   
				}
//				write "max([0.5,mean(INN_periode_culture)]) = " + max([0.5,mean(INN_periode_culture)]);
//				write "INN_periode_culture = " + INN_periode_culture;
            }
//            write "biomasse_aerienne_couvert = " + MSA_couvert + " -- espece.a_N_to_DM = " + espece.adil + " -- QN_acquis_cumul = " + QN_acquis_cumul + " -- espece.a_N_to_DM = " + espece.bdil; 
            sommeTranspirationR  <- 0.0; 
            sommeTranspirationMax <- 0.0;
            
	        // Calcul de la biomasse exportée qui n'est pas du grain pour enregistrement de la valeur
			if (is_MSA_exportee) {
		        MSA_exportee <- MSA_couvert * (1 - Pss); // Pour les couverts, la biomasse est directement donnée en matière séche (tms = 1) et l'intégralité de la biomasse est restituée ou exportée via Pse
				rendement <- MSA_exportee; //
//				write "Couvert exporté ---> MSA_exportee = " + MSA_exportee; 
			} else {
				rendement <- MSA_couvert;
//				write "restitution totale du couvert";
			}
            
        } else { // Si ce n'est pas un couvert intermédiaire, le rendement est estimé à partir du rendement optimal
            if (sommeTranspirationMax > 0.0 ) {
                float satisH <- sommeTranspirationR / sommeTranspirationMax;
                float a <- espece.coeff_Fonction_Prod;
                float rendementPotentiel <- espece.rendementOptimal;
                               
                // Stress hydrique
//                write 'satisH = ' + satisH;
                float effetStressHydriqueSurRendement <- max([0.1, 1 - min([1.0,a*((1-satisH)^2)])]); // Renaud 050521 suite à question par mail à Olivier et Hugues --> valeur min = 0.1
                
                // Stress azoté modif Hugues 2020-12-17 anciennement f(INN) -> f(Nacquis/Nmax) = f(QN_acquis_cumul/espece.QNmax)
                // Les légumineuses sont traitées différement des autres plantes
                float effetStressAzoteSurRendement <- getEffetStressAzoteSurRendement();
//				write "nom espece = " + espece.idEspeceCultivee;
//				write "effetStressHydriqueSurRendement = " + effetStressHydriqueSurRendement;
//				write "effetStressAzoteSurRendement = " + effetStressAzoteSurRendement;
                rendement <- min([effetStressHydriqueSurRendement, effetStressAzoteSurRendement]) * rendementPotentiel; // modif Renaud + Hugues 290421 : le rendement ne peut pas descendre en dessous de 10 % du rendement potentiel pour éviter à 0
//                write "Récolte -> effetStressHydriqueSurRendement = " + effetStressHydriqueSurRendement + " - effetStressAzoteSurRendement = " + effetStressAzoteSurRendement;
//                write "rendementPotentiel = " + rendementPotentiel + "rendement = " + rendement;
                sommeTranspirationR  <- 0.0; 
                sommeTranspirationMax <- 0.0;
		        
	        // Calcul de la biomasse exportée qui n'est pas du grain pour enregistrement de la valeur
				if (is_MSA_exportee) {
					MSA_exportee <- rendement * espece.Tms * (1-espece.HI)/espece.HI * (1 - Pss); // Calcul de la MS de pailles exportée (si culture ensilée = 0)
				}
            }
        }
        
	    // Inscription dans la parcelle de la valeur de biomasse exportée qui n'est pas du grain pour enregistrement et réutilisation dans le module filière
	    parcelleAqYieldNC(parcelle_app).MSA_exportee_parcelle <- MSA_exportee;
        
       	parcelleAqYieldNC(parcelle_app).QNfix_cumul <- parcelleAqYieldNC(parcelle_app).QNfix_cumul + QNfix;//Hugues 210517
        return rendement;
   
    }
    
    // Calcul de l'azote aérien et racinaire entrant suite à la récolte (matière sèche non récoltée)
    action N_entrant_postrecolte(float R) {
        // Masse de matière sèche non-récoltée
//        write "rendement = " + R + " | espece.Tms = " + espece.Tms;                                                                                                                   
//        write "espece = " + espece.idEspeceCultivee;
//        float MSA_restituee <- (R * espece.Tms * (espece.aa + (1 - espece.aa))) / espece.IRv;
//        float MSR_restituee <- (espece.bb * ((R * espece.Tms) * espece.ratio_R * (espece.IRv + 1))) / (espece.IRv * (1 - espece.ratio_R));

        // Part de biomasse restituée
        float Pss <- 1.0;
        if (is_MSA_exportee = true){
            Pss <- espece.Pse;
        }
        
        // Calcul de la masse de carbone restituée (aérienne et racinaire)
        // Biomasse aérienne
        float MSA_restituee <- 0.0; // Matière sèche aérienne restituée
        float MSA_restituee_carbone <- 0.0; // Carbone dans la matière sèche aérienne restituée
        float MSA_totale_carbone; // Carbonne dans la matière sèche aérienne totale (rendement = exporté + restitué)
        //float MSA_exportee <- 0.0; // Matière sèche aérienne exportée (inverse du restitué) NR 270924
        //float MSA_exportee_carbone <- 0.0; // Carbone dans la matière sèche aérienne exportée NR 270924
        
        if (espece.isCouvert) { // Si la culture est un couvert
            MSA_restituee <- R * Pss; // Pour les couverts, la biomasse est directement donnée en matière séche (tms = 1) et l'intégralité de la biomasse est restituée ou exportée via Pse
            MSA_restituee_carbone <- MSA_restituee * espece.C_aer * 1000;
            MSA_totale_carbone <- R * espece.C_aer * 1000;
        } else { // Si la culture n'est pas un couvert
            MSA_restituee <- R * espece.Tms * (1-espece.HI)/espece.HI * Pss;
            MSA_restituee_carbone <- MSA_restituee * espece.C_aer * 1000;
            
        }
        // Inscription dans la parcelle pour enregistrement
        parcelleAqYieldNC(parcelle_app).MSA_restituee_parcelle <- MSA_restituee;
		
	// Biomasse racinaire
        float MSR_restituee <- 0.0;
        float MSR_carbone <- 0.0;
        if (espece.RootC_fixed = 0){
            if (espece.isCouvert) { // Si la culture est un couvert
                MSR_restituee <- R / espece.SR_ratio * 1.65;// Hugues 210512
            } else {
                MSR_restituee <- R * espece.Tms / (espece.SR_ratio * espece.HI) * 1.65;
            }
            
            // MSR_carbone <- MSR_restituee * espece.C_rac * 1000 * (1-espece.beta^30);
			MSR_carbone <- MSR_restituee * espece.C_rac * 1000 * (1-espece.beta^parcelleAqYieldNC(parcelle_app).ilot_app.sol.profHum); // RM cf mail 211123            
        } else {
            MSR_carbone <- espece.RootC_fixed * 1000;
            MSR_restituee <- MSR_carbone / (espece.C_rac * 1000 * (1-espece.beta^parcelleAqYieldNC(parcelle_app).ilot_app.sol.profHum)); // Ajouté par Manon 171123 pour sortie Biomasse racinaire alimentant les pools minéralisés dans les 30 premiers cm du sol        }
        	//write "MSR_carbone=" + MSR_carbone + " MSR_restituee=" + MSR_restituee + " espece.beta=" + espece.beta + " profHum=" + parcelleAqYieldNC(parcelle_app).ilot_app.sol.profHum;
        }
        //write "rendement = " + R + " | ABG C input = " + MSA_restituee_carbone + " | BLG C input = " + MSR_carbone + " | surface = " + parcelleAqYieldNC(parcelle_app).surface;
        // Inscription dans la parcelle pour enregistrement
        parcelleAqYieldNC(parcelle_app).MSR_restituee_parcelle <- MSR_restituee;

        // Masse d'azote
//        float MSA_azote <- (MSA_restituee_carbone / espece.CN_aer); // Les équations de AMG donnent des résultats en t/Ha, AqYield prend des entrées en kg/Ha
//        float MSR_azote <- ((MSR_carbone / espece.CN_rac) + QNfix);
        float N_abg_bg <- 0.0;
        float N_grain <- 0.0;
        if (espece.isCouvert) {
            N_abg_bg <- (MSA_restituee_carbone + MSR_carbone) / (MSA_totale_carbone + MSR_carbone) * (QN_acquis_cumul + QNfix); // Hugues 260723 : le N en dessous de profHum est réalloué entre aérien et racinaire, si non aérien et racinaire n'auraient pas le même C/N
        } else {
            float N_grain_export_pot <- espece.N_grain/100 * R * espece.Tms*1000;
            float N_abg_bg_pot <- (MSA_restituee_carbone + MSR_carbone)/espece.CN_ratio;        
            N_grain <- N_grain_export_pot /(N_grain_export_pot + N_abg_bg_pot) * (QN_acquis_cumul + QNfix);
            N_abg_bg <- N_abg_bg_pot /(N_grain_export_pot + N_abg_bg_pot) * (QN_acquis_cumul + QNfix);    
        }        
                
        float MSA_azote <- MSA_restituee_carbone / (MSA_restituee_carbone+MSR_carbone)*N_abg_bg;
        float MSR_azote <- MSR_carbone / (MSA_restituee_carbone+MSR_carbone)*N_abg_bg;   //write "espece=" + espece.idEspeceCultivee + " MSR_azote=" + MSR_azote + " MSA_restituee_carbone=" + MSA_restituee_carbone + " MSR_carbone=" + MSR_carbone + " N_abg_bg=" + N_abg_bg;
//        write "ABG N input = " + MSA_azote + "| BLG N input = " + MSR_azote+ "| C:N ratio biomass = " + (MSA_restituee_carbone/MSA_azote);
//        write "Yield = " + R + "| N grain = " + N_grain + "| Grain N content %DM = " + (N_grain/(R*espece.Tms*1000)*100);
        
        // Apport des résidus à la parcelle
        ask (parcelleAqYieldNC(parcelle_app)) {
            do AddPoolResidus(MSR_carbone/MSR_azote, "incorpore", MSR_carbone, MSR_azote, "racines post recolte","residus racinaires", "labile", 0.0, 0.0, 0.0, 0.0); // Parties racinaires
            do AddPoolResidus(MSA_restituee_carbone/MSA_azote, "surface", MSA_restituee_carbone, MSA_azote,"aerien post recolte","residus aeriens", "labile", 0.0, 0.0, 0.0, 0.0); // Parties aériennes
        }
    }
    
	float getEffetStressAzoteSurRendement {
	    // Stress azoté modif Hugues 2020-12-17 anciennement f(INN) -> f(Nacquis/Nmax) = f(QN_acquis_cumul/espece.QNmax)
	    // Les légumineuses sont traitées différement des autres plantes
	    float effetStressAzoteSurRendement <- 1.0;
	    if (!espece.isLEG) {
	        effetStressAzoteSurRendement <- max([0.1, 1 - (1 - 0.95 * QN_acquis_cumul/espece.QNmax)^2]);
	    } else { // Si l'espèce est une légumineuse, on calcule la quantité d'azote fixée et le stress azoté garde une valeur de 1 (pas de stress)
	        //QNfix <- max([0.0, espece.QNmax * effetStressHydriqueSurRendement - QN_acquis_cumul]);//Hugues 210512
	        QNfix <- QN_demande_cumul_stressH - QN_acquis_cumul;//Hugues 210512
	    }
	    return effetStressAzoteSurRendement;
    }
    
    // JV 100522 introduit pour calcul journalier pour la sortie azote, sinon seulement calculé le jour de la récolte 
    float getQN_fix {
    	return (QN_demande_jour_stressH - QN_acquis);
    }
}


