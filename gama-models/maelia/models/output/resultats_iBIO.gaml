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
*  resultatsAssolementAgri
*  Author: Renaud Misslin
*  Description: calcul des indicateurs i-bio sur la base du travail de thèse d'Emma Soulé 
*  https://www.sciencedirect.com/science/article/pii/S1470160X23004314
 */

model resultats_iBIO

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleCommun/dateCourante.gaml"
import "../modeleCommun/timeStamp.gaml"
import "../modeleCommun/typeDeSol.gaml"
import "../modeleAgricole/Parcelles/parcelle.gaml"
import "../modeleAgricole/Parcelles/parcelleHorsZone.gaml"
import "../modeleAgricole/Cultures/cultureIrrigable.gaml"
import "../modeleAgricole/Ilots/ilot.gaml"
import "../modeleAgricole/Ilots/ilotHorsZone.gaml"
import "../modeleAgricole/ITKs/itk.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCulture.gaml"
import "../modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml"
import "../modeleAgricole/exploitation.gaml"
import "../modeleAgricole/especeCultivee.gaml"
import "../modeleAgricole/Agriculteurs/agriculteur.gaml"
import "ecritureResultats.gaml"
import "../modeleAgricole/Agriculteurs/memoire.gaml"

global{
	string cheminCorrespondanceMaeliaIbio <- '' + cheminModeleVersDonnees + nomDecoupageZonePourLectureFichiers + '/modeleAgricole/culture/correspondance_especesMAELIA_especesIBIO.csv';
	string chemintblDexiIbio <- '' + '../../models/output/i-bio';
	
	map<especeCultivee, string> map_especeMAELIA_especeIBIO;
	
	// Maps qui contiendront les tableaux DEXI
	map<map,string> Biodiversity;
	
	map<map,string> Microorganisms;
	map<map,string> Anthropogenic_pressures_Microorganisms;
	map<map,string> Chemical_input;
	map<map,string> Trophic_ressources_Microorganisms;
	
	map<map,string> Vegetation;
	map<map,string> Landscape_simplification;
	map<map,string> Semi_natural_land_cover;
	map<map,string> Composition;
	map<map,string> Weeds;
	map<map,string> Weed_abundance;
	map<map,string> Dicot_abundance;
	map<map,string> Monocot_abundance;
	map<map,string> Dicot_diversity;
	
	map<map,string> Invertebrates;
	map<map,string> Soil_invertebrates;
	map<map,string> Anthropogenic_pressures_Soil_invertebrates;
	map<map,string> Pesticide_Soil_Invertebrates;
	map<map,string> Trophic_ressources_Soil_invertebrates;
	map<map,string> Flying_invertebrates;
	map<map,string> Anthropogenic_pressures_Flying_invertebrates;
	map<map,string> Pesticide_Flying_Invertebrates;
	map<map,string> Trophic_ressources_Flying_invertebrates;
	
	map<map,string> Vertebrates;
	map<map,string> Anthropogenic_pressures_Vertebrates;
	map<map,string> Machinery_use;
	map<map,string> Trophic_ressources_Vertebrates;

	
    // Fonction de lecture des tableaux Dexi correspondant aux branches
	map lectureTableauDexiIbio (string chemin_tbl) { //  "/Microorganisms/Trophic ressources Microorganisms/Trophic ressources Microorganisms.csv"
		map<map, string> resultat; // Contient le résultat final
		
		// Chemin et chargement des données
		string chemin_relatif_tbl <- chemintblDexiIbio + chemin_tbl;
		if !file_exists(chemin_relatif_tbl) {do raiseError("fichier inexistant: " + chemin_relatif_tbl);}
		matrix initDataIbio <- matrix(csv_file (chemin_relatif_tbl,";",false)); 
		
		// Construction de la map de résultat
       	list<string> noms_regles <- (initDataIbio row_at 0) as list<string>;
       	int nb_regles <- length(noms_regles)-1; 
       	int nb_lignes <- length((initDataIbio column_at 0) as list<string>)-1; // Nb lignes sans haeder
       	
       	// La clé est une submap remplie, la valeur est le résultat correspondant à la submap
       	loop i from: 1 to: nb_lignes {
       		list<string> valeurs_regles <- (initDataIbio row_at i) as list<string>;
   	    	map<string, string> submap <- ([]); // Map contenue dans chaque entrée de la map de résultat (variable servant à la construction de la map de résultat)

       		// Remplissage de la submap
	       	loop j from: 0 to: nb_regles-1 { // On ne regarde pas la dernière colonne qui contient le résultats de l'association
	       		submap[noms_regles[j]] <- valeurs_regles[j];
	       	}
	       	
	       	// Remplissage de la map de résultats
	       	resultat[submap] <- valeurs_regles[nb_regles];
       	}

		return resultat;
	} 
	
    // Initialisation du fichier de résulats
    action initialisationEcritureFichiersresultats_iBIO {
	  	do ecritureConsolePourDebug isAfficherTemps: true chaineAEcrire: 'Initialisation ecriture fichiers resultats_iBIO';           
	  	do lectureCorrespondanceEspeceMaeliaIbio;
	   
	  	// Chargement des tableaux de règles DEXI
		Biodiversity <- lectureTableauDexiIbio("/Biodiversity.csv");
		
		Microorganisms <- lectureTableauDexiIbio("/Microorganisms/Microorganisms.csv");
		Anthropogenic_pressures_Microorganisms <- lectureTableauDexiIbio("/Microorganisms/Anthropogenic pressures Microorganisms/Anthropogenic pressures Microorganisms.csv");
		Chemical_input <- lectureTableauDexiIbio("/Microorganisms/Anthropogenic pressures Microorganisms/Chemical input/Chemical input.csv");
		Trophic_ressources_Microorganisms <- lectureTableauDexiIbio("/Microorganisms/Trophic ressources Microorganisms/Trophic ressources Microorganisms.csv");
		
		Vegetation <- lectureTableauDexiIbio("/Vegetation/Vegetation.csv");
		Landscape_simplification <- lectureTableauDexiIbio("/Vegetation/Landscape simplification/Landscape simplification.csv");
		Semi_natural_land_cover <- lectureTableauDexiIbio("/Vegetation/Landscape simplification/Semi natural land cover/Semi natural land cover.csv");
		Composition <- lectureTableauDexiIbio("/Vegetation/Landscape simplification/Semi natural land cover/Composition/Composition.csv");
		Weeds <- lectureTableauDexiIbio("/Vegetation/Weeds/Weeds.csv");
		Weed_abundance <- lectureTableauDexiIbio("/Vegetation/Weeds/Weed abundance/Weed abundance.csv");
		Dicot_abundance <- lectureTableauDexiIbio("/Vegetation/Weeds/Weed abundance/Dicot abundance/Dicot abundance.csv");
		Monocot_abundance <- lectureTableauDexiIbio("/Vegetation/Weeds/Weed abundance/Monocot abundance/Monocot abundance.csv");
		Dicot_diversity <- lectureTableauDexiIbio("/Vegetation/Weeds/Dicot diversity/Dicot diversity.csv");
		
		Invertebrates <- lectureTableauDexiIbio("/Invertebrates/Invertebrates.csv");
		Soil_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Soil invertebrates/Soil invertebrates.csv");
		Anthropogenic_pressures_Soil_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Soil invertebrates/Anthropogenic pressures Soil invertebrates/Anthropogenic pressures Soil invertebrates.csv");
		Pesticide_Soil_Invertebrates <- lectureTableauDexiIbio("/Invertebrates/Soil invertebrates/Anthropogenic pressures Soil invertebrates/Pesticide invertebrates/Pesticide invertebrates.csv");
		Trophic_ressources_Soil_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Soil invertebrates/Trophic ressources Soil invertebrates/Trophic ressources Soil invertebrates.csv");
		Flying_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Flying invertebrates/Flying invertebrates.csv");
		Anthropogenic_pressures_Flying_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Flying invertebrates/Anthropogenic pressures Flying invertebrates/Anthropogenic pressures Flying invertebrates.csv");
		Pesticide_Flying_Invertebrates <- lectureTableauDexiIbio("/Invertebrates/Flying invertebrates/Anthropogenic pressures Flying invertebrates/Pesticide invertebrates/Pesticide invertebrates.csv");
		Trophic_ressources_Flying_invertebrates <- lectureTableauDexiIbio("/Invertebrates/Flying invertebrates/Trophic ressources Flying invertebrates/Trophic ressources Flying invertebrates.csv");
		
		Vertebrates <- lectureTableauDexiIbio("/Vertebrates/Vertebrates.csv");
		Anthropogenic_pressures_Vertebrates <- lectureTableauDexiIbio("/Vertebrates/Anthropogenic pressures Vertebrates/Anthropogenic pressures Vertebrates.csv");
		Machinery_use <- lectureTableauDexiIbio("/Vertebrates/Anthropogenic pressures Vertebrates/Machinery use/Machinery use.csv");
		Trophic_ressources_Vertebrates <- lectureTableauDexiIbio("/Vertebrates/Trophic ressources Vertebrates/Trophic ressources Vertebrates.csv");
		
		// Valeurs biodiv état initial
	  	create resultats_iBIO number: 1{
		  	do initialisation();
		  	listesFichiersAcreer << self;
		  	
//		  	write "resultat_Microorganisms = " + resultat_Microorganisms(first(listeParcelles));
//		  	write "resultat_Vegetation = " + resultat_Vegetation(first(listeParcelles));
//			write "resultat_Vertebrates = " + resultat_Vertebrates(first(listeParcelles));
//			write "resultat_Invertebrates = " + resultat_Invertebrates(first(listeParcelles));
//			write "resultat_Biodiversity = " + resultat_Biodiversity(first(listeParcelles));
			string saving_biodiversity <- "";
			loop p over: listeParcelles {
				p.ibio_biodiversity <- resultat_Biodiversity(p);
				p.ibio_microorganisms <- resultat_Microorganisms(p);
				p.ibio_vegetation <- resultat_Vegetation(p);
				p.ibio_invertebrates <- resultat_Invertebrates(p);
				p.ibio_vertebrates <- resultat_Vertebrates(p);

				//saving_biodiversity <- saving_biodiversity + p.idParcelle + ";" + p.ibio_biodiversity + "\n";
			}
			//save saving_biodiversity to:"../results/parcelles_bio.csv"; 
	   	}
	    
	   	ask listeParcelles {
	   		do update_parcelles_1km;
	  	}
    }
     
    
    // Lecture du fichier de correpsondance especes maelia / espece ibio
    action lectureCorrespondanceEspeceMaeliaIbio {
		if !file_exists(cheminCorrespondanceMaeliaIbio) {do raiseError("fichier inexistant: " + cheminCorrespondanceMaeliaIbio);}
		
		matrix initDataMaeliaIbio <- matrix(csv_file (cheminCorrespondanceMaeliaIbio,";",false)); 
       	int nbColonnes <- length(initDataMaeliaIbio column_at 0);
       	
       	loop i from: 1 to: ( nbColonnes - 1 ) {
			list<string> colonneCourante <- (initDataMaeliaIbio row_at i) as list<string>;
			if((colonneCourante at 1) != nil){
				especeCultivee especeCourante <- first(listeEspecesCultiveesParOrdreSaisie collect each where (each.idEspeceCultivee = colonneCourante at 0));
				if (especeCourante != nil) {
					map_especeMAELIA_especeIBIO <+ especeCourante::colonneCourante at 1;
				}
				
			}
		}
    }
	
	
	// 
}


species resultats_iBIO parent: ecritureResultats {
	map<parcelle, list<string>> map_parcelles_cultures_1km;
	
	
	// ********************* COLLECTE DES VARIABLES ********************* //
	
	// N apporté par parcelle
//	float get_Napport_parcelle (parcelle p) {
//		float Napport_parcelle <- 0.0;
//		Napport_parcelle <- parcelleAqYieldNC(p).QNapport_min + parcelleAqYieldNC(p).QNapport_pro;
//		
//		return Napport_parcelle;
//	} 
//	
	// Matière Organique (%)
	float get_MO_parcelle (parcelle p) {
		float MO_parcelle <- 0.0;
		MO_parcelle <- parcelleAqYieldNC(p).OM_perc;
		
		return MO_parcelle;
	}
	
	// N minéral apporté (unité de N / ha)
	float get_Nmin_apport_parcelle (parcelle p) {
		float Napport_parcelle <- 0.0;
		Napport_parcelle <- parcelleAqYieldNC(p).iBio_QNapport_min;
		
		return Napport_parcelle;
	}
	
	// Nombre de traitements phyto 
	int get_n_traitements_pesticide (parcelle p) {
		int resultat <- 0;
		resultat <- p.nb_traitements_total;
		return resultat;
	}
	
	// Nombre de traitements insecticides 
	int get_n_traitements_insecticide (parcelle p) {
		int resultat <- 0;
		resultat <- p.nb_traitements_insecticides;
		return resultat;
	}

	// Nombre de traitements anti-monocotyledon 
	int get_n_traitements_monocot (parcelle p) {
		int resultat <- 0;
		resultat <- p.nb_traitements_monocot;
		return resultat;
	}
	
	// Nombre de traitements anti-monocotyledon 
	int get_n_traitements_dicot (parcelle p) {
		int resultat <- 0;
		resultat <- p.nb_traitements_dicot;
		return resultat;
	}
	
	// Nombre de traitements autres 
	int get_n_traitements_autres (parcelle p) {
		int resultat <- 0;
		resultat <- p.nb_traitements_autres;
		return resultat;
	}
	
	// Quand a ont été fait les traitements dans le cycle de la culture ?
	string get_herbicide_timing (parcelle current_parc) {
		string resultat <- current_parc.herbicide_timing;
		return resultat;
	}
	
	// Diversité (nombre) cultures dans un rayon de 1 km autour de chaque parcelle
	list<string> get_cultures_1km (parcelle current_parc) {
		list<string> liste_cultures_1km;

		loop p1km over: current_parc.parcelles_1km {
			if (p1km.cultureParcelle != nil)  {
				string nomIbio <- map_especeMAELIA_especeIBIO[p1km.cultureParcelle.monModelDeCulture.espece];
				liste_cultures_1km <+ nomIbio;
			}
		}
		
		liste_cultures_1km <- remove_duplicates(liste_cultures_1km);
//		write "nb cult -> " + length(liste_cultures_1km);
		return liste_cultures_1km;
	}
	
	// Remplissage de la map de cultures 1km par parcelle au 1er mai
	reflex getCultures1kmParParcelle when: ((first(dateCourante).mois = 5 ) and (first(dateCourante).jour = 1))   {
		loop p over: listeParcelles {
			map_parcelles_cultures_1km[p] <- get_cultures_1km(p);
		}
	}
	
	// Diversité de cultures dans =  la rotation d'une parcelle (nombre de cultures différentes)
	int get_nb_cultures_rotation (parcelle current_parc) {		
		int nb_cultures <- length(remove_duplicates(current_parc.rotationReelle tokenize "_"));
		// TODO Renaud 230124 Il faudrait peut-être attribuer la meilleure note possible aux prairies permanentes (leur mettre 99 par exemple)
		return nb_cultures;
	}
	
	// Nombre de coupes ou de fauche
	int get_n_coupes_fauches (parcelle p) {
		int resultat <- 0;
		resultat <- p.n_coupes_fauches;
		return resultat;
	}
	
	// Nombre de coupes ou de fauche
	int get_intensite_wsol (parcelle p) {
		float resultat <- 0.0;
		resultat <- p.intensite_travailSol; // Voir StrategieOT.gaml
		return int(resultat);
	}
	
	// ********************* RESULTATS PAR FEUILLE ********************* //
	
	// Matière organique
	string resultat_soilOM (parcelle current_parc) {
		string resultat;
		
		float MO_parc <- get_MO_parcelle(current_parc);
		
		if (MO_parc < 2) {
			resultat <- "Low";
		} else if (MO_parc >= 2 and MO_parc < 5) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		
//		write "MO = " + resultat;
		return resultat;
	}
	
	// Nombre de cultures dans la rotation
	string resultat_CropRotation (parcelle current_parc) {
		string resultat;
		
		int nb_cult_rotation_parc  <- get_nb_cultures_rotation(current_parc);
		
		if (nb_cult_rotation_parc < 3) {
			resultat <- "Low";
		} else if (nb_cult_rotation_parc >= 3 and nb_cult_rotation_parc < 6) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
//		write "n crops rotation = " + resultat;
		return resultat;
	}
	
	// Unités de N minéral
	string resultat_MineralNitrogen (parcelle current_parc) {
		string resultat;
		
		float N_mineral_units  <-  get_Nmin_apport_parcelle(current_parc);
		
		
		if (N_mineral_units < 50) {
			resultat <- "Low";
		} else if (N_mineral_units >= 50 and N_mineral_units < 150) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
//		write "N min = " + resultat;
		return resultat;
	}
	
	// Nombre de traitements pesticides appliqués
	string resultat_Pesticide (parcelle current_parc) {
		string resultat;
		
		int nb_pesticides  <- get_n_traitements_pesticide(parcelleAqYield(current_parc));
		
		if (nb_pesticides < 3) {
			resultat <- "Low";
		} else if (nb_pesticides >= 3 and nb_pesticides < 6) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		//write "pesti = " + resultat;
		return resultat;
	}
	
	// Intensité du travail du sol (tillage intensity)
	string resultat_TillageIntensity (parcelle current_parc) { // TODO 150224 faire en fnction de l'outil et pas de la prof wsol
		string resultat;
		
		int profWsol  <- get_intensite_wsol(current_parc);
		
		if (profWsol < 5) { // Direct sowing
			resultat <- "Low";
		} else if (profWsol >= 5 and profWsol < 12) { // Non inversion tillage
			resultat <- "Medium";
		} else { // ploughing
			resultat <- "High";
		}
//		write "tillage = " + resultat;
		return resultat;
	}
	
	// Land cover diversity (nombre d'habitats semi-naturels différents)
	string resultat_LandCoverDiversity (parcelle current_parc) {
		string resultat;
		
		int n_habitats_SN <- current_parc.IBIO_parc_LCD;
		
		if (n_habitats_SN < 2) {
			resultat <- "Low";
		} else if (n_habitats_SN = 2) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Part d'habitat semi-naurel dans un rayon de 1 km autour de la parcelle (%)
	string resultat_PercentageSemiNaturalLandCover (parcelle current_parc) {
		string resultat;
		
		float part_habitats_SN <- current_parc.IBIO_parc_HSN;
		
		if (part_habitats_SN < 1) {
			resultat <- "Low";
		} else if (part_habitats_SN >= 1 and part_habitats_SN < 10) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Connectivité de la parcelle à des habitats semi-naturel (%)
	string resultat_Configuration (parcelle current_parc) {
		string resultat;
		
		float part_habitats_SN  <- current_parc.IBIO_parc_CONN;
		
		if (part_habitats_SN < 25) {
			resultat <- "Low";
		} else if (part_habitats_SN >= 25 and part_habitats_SN < 75) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Surface de la parcelle (ha)
	string resultat_FieldSize (parcelle current_parc) {
		string resultat;
		
		float surface  <- current_parc.surface / 10000; // surface en ha
		
		if (surface < 2) {
			resultat <- "High";
		} else if (surface >= 2 and surface < 10) {
			resultat <- "Medium";
		} else {
			resultat <- "Low";
		}
		return resultat;
	}
	
	// Nombre de cultures différentes (espèces) dans un rayon de 1 km autour de la parcelle (voir fichier correspondance_especesMAELIA_especesIBIO.csv)
	string resultat_CropDiversity (parcelle current_parc) {
		string resultat;
		
		if (map_parcelles_cultures_1km[current_parc] = nil) {
			resultat <- "Medium";
//			write "n crops 1 km init = 3";
		} else {
			int n_crops_1km  <- length(map_parcelles_cultures_1km[current_parc]);
			
			if (n_crops_1km < 3) {
				resultat <- "Low";
			} else if (n_crops_1km >= 3 and n_crops_1km < 6) {
				resultat <- "Medium";
			} else {
				resultat <- "High";
			}
//			write "n crops 1 km = " + n_crops_1km;
		}
		
		return resultat;
	}
	
	// Nombre de traitements anti monocotiledon
	string resultat_AntimonocotHerbicideQuantity (parcelle current_parc) {
		string resultat;
		
		int n_traitements  <- get_n_traitements_monocot(current_parc); // TODO 090224 Renaud -> update de la valeur pas encore fait dans strategiePhyto et strategiePhytoMultiples
		
		if (n_traitements < 1) {
			resultat <- "Low";
		} else if (n_traitements >= 1 and n_traitements < 2) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Nombre de traitements anti dicotiledon
	string resultat_AntidicotHerbicideQuantity (parcelle current_parc) {
		string resultat;
		
		int n_traitements  <- get_n_traitements_dicot(current_parc); // TODO 090224 Renaud -> update de la valeur pas encore fait dans strategiePhyto et strategiePhytoMultiples
		
		if (n_traitements < 1) {
			resultat <- "Low";
		} else if (n_traitements = 1) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Moment d'application de l'herbicide / des hebicides
	string resultat_HerbicideTiming (parcelle current_parc) {
		string resultat <- "No herbicide"; // "No herbicide" "Both or pre-emergence" "Post-emergence"
		resultat <- get_herbicide_timing(current_parc);
		return resultat;
	}
	
	// Nombre de traitements autres pesticides
	string resultat_OtherPesticide (parcelle current_parc) {
		string resultat;
		
		int n_traitements  <- get_n_traitements_autres(current_parc); // TODO 090224 Renaud -> update de la valeur pas encore fait dans strategiePhyto et strategiePhytoMultiples
		
		if (n_traitements < 1) {
			resultat <- "Low";
		} else if (n_traitements = 1) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Nombre de traitements insecticides
	string resultat_Insecticide (parcelle current_parc) {
		string resultat;
		
		int n_traitements  <- get_n_traitements_insecticide(current_parc); // TODO 090224 Renaud -> update de la valeur pas encore fait dans strategiePhyto et strategiePhytoMultiples
		
		if (n_traitements < 1) {
			resultat <- "Low";
		} else if (n_traitements = 1) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	// Nombre de fauches et de récoltes
	string resultat_Mowing (parcelle current_parc) {
		string resultat;
		
		int n_coupes  <- get_n_coupes_fauches(current_parc);
		
		if (n_coupes < 2) {
			resultat <- "Low";
		} else if (n_coupes = 2) {
			resultat <- "Medium";
		} else {
			resultat <- "High";
		}
		return resultat;
	}
	
	
	// ********************* RESULTATS PAR BRANCHE ********************* //
	
	// Fonction parcourant un tableau DEXI
	string resultat_branche (list regles, list notes, map map_dexi) {
		map<string, string> finder;
		loop i from:0 to:length(regles)-1 {
			finder[regles[i]] <- notes[i];
		}
		
		return map_dexi[finder];
	}



	// --- Biodiversity ---------------
	string resultat_Biodiversity (parcelle current_parc) {		
		list<string> regles <- ["Microorganisms", "Vegetation", "Invertebrates", "Vertebrates"];
		list<string> notes <- [resultat_Microorganisms(current_parc), resultat_Vegetation(current_parc), resultat_Invertebrates(current_parc), resultat_Vertebrates(current_parc)];
//		write "resultat_Biodiversity = " + resultat_branche(regles, notes, Biodiversity);
		return resultat_branche(regles, notes, Biodiversity);
	}



	// --- Microorganisms ---------------
	string resultat_Microorganisms (parcelle current_parc) {		
		list<string> regles <- ["Anthropogenic pressures Microorganisms","Trophic ressources Microorganisms"];
		list<string> notes <- [resultat_AnthropogenicPressuresMicroorganisms(current_parc), resultat_TrophicRessourcesMicroorganisms(current_parc)];
		return resultat_branche(regles, notes, Microorganisms);
	}

	string resultat_TrophicRessourcesMicroorganisms (parcelle current_parc) {		
		list<string> regles <- ["Soil OM","Crop rotation"];
		list<string> notes <- [resultat_soilOM(current_parc), resultat_CropRotation(current_parc)];
		return resultat_branche(regles, notes, Trophic_ressources_Microorganisms);
	}
	
	string resultat_ChemicalInputs (parcelle current_parc) {		
		list<string> regles <- ["Mineral nitrogen","Pesticide"];
		list<string> notes <- [resultat_MineralNitrogen(current_parc), resultat_Pesticide(current_parc)];
		return resultat_branche(regles, notes, Chemical_input);
	}
	
	string resultat_AnthropogenicPressuresMicroorganisms (parcelle current_parc) {		
		list<string> regles <- ["Tillage intensity","Chemical input"];
		list<string> notes <- [resultat_TillageIntensity(current_parc), resultat_ChemicalInputs(current_parc)];
		return resultat_branche(regles, notes, Anthropogenic_pressures_Microorganisms);
	}
	
	

	// --- Vegetation ---------------
	string resultat_Composition (parcelle current_parc) {		
		list<string> regles <- ["Land cover diversity","Percentage Semi natural land cover"];
		list<string> notes <- [resultat_LandCoverDiversity(current_parc), resultat_PercentageSemiNaturalLandCover(current_parc)];
		return resultat_branche(regles, notes, Composition);
	}

	string resultat_SemiNaturalLandCover (parcelle current_parc) {		
		list<string> regles <- ["Composition","Configuration (Connectivity)"];
		list<string> notes <- [resultat_Composition(current_parc), resultat_Configuration(current_parc)];
		return resultat_branche(regles, notes, Semi_natural_land_cover);
	}
	
	string resultat_LandscapeSimplification (parcelle current_parc) {		
		list<string> regles <- ["Semi natural land cover","Field size", "Crop diversity"];
		list<string> notes <- [resultat_SemiNaturalLandCover(current_parc), resultat_FieldSize(current_parc), resultat_CropDiversity(current_parc)];
//		write "resultat_LandscapeSimplification = " + resultat_branche(regles, notes, Landscape_simplification);
		return resultat_branche(regles, notes, Landscape_simplification);
	}
	
	string resultat_MonocotAbundance (parcelle current_parc) {		
		list<string> regles <- ["Antimonocot herbicide quantity","Tillage intensity"];
		list<string> notes <- [resultat_AntimonocotHerbicideQuantity(current_parc), resultat_TillageIntensity(current_parc)];
		return resultat_branche(regles, notes, Monocot_abundance);
	}
	
	string resultat_DicotAbundance (parcelle current_parc) {		
		list<string> regles <- ["Antidicot herbicide quantity","Tillage intensity"];
		list<string> notes <- [resultat_AntidicotHerbicideQuantity(current_parc), resultat_TillageIntensity(current_parc)];
		return resultat_branche(regles, notes, Dicot_abundance);
	}
	
	string resultat_WeedAbundance (parcelle current_parc) {		
		list<string> regles <- ["Monocot abundance","Dicot abundance"];
		list<string> notes <- [resultat_MonocotAbundance(current_parc), resultat_DicotAbundance(current_parc)];
		return resultat_branche(regles, notes, Weed_abundance);
	}
	
	string resultat_DicotDiversity (parcelle current_parc) {		
		list<string> regles <- ["Crop rotation","Herbicide timing","Mineral nitrogen"];
		list<string> notes <- [resultat_CropRotation(current_parc), resultat_HerbicideTiming(current_parc), resultat_MineralNitrogen(current_parc)];
		return resultat_branche(regles, notes, Dicot_diversity);
	}
	
	string resultat_Weeds (parcelle current_parc) {		
		list<string> regles <- ["Weed abundance","Dicot diversity"];
		list<string> notes <- [resultat_WeedAbundance(current_parc), resultat_DicotDiversity(current_parc)];
		return resultat_branche(regles, notes, Weeds);
	}
	
	string resultat_Vegetation (parcelle current_parc) {		
		list<string> regles <- ["Landscape simplification","Weeds"];
		list<string> notes <- [resultat_LandscapeSimplification(current_parc), resultat_Weeds(current_parc)];
		return resultat_branche(regles, notes, Vegetation);
	}



	// --- Invertebrates ---------------
	string resultat_PesticideSoilInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Insecticide","Other"];
		list<string> notes <- [resultat_Insecticide(current_parc), resultat_OtherPesticide(current_parc)];
//		write "resultat_PesticideSoilInvertebrates = " + resultat_branche(regles, notes, Pesticide_Soil_Invertebrates);

		return resultat_branche(regles, notes, Pesticide_Soil_Invertebrates);
	}

	string resultat_AnthropogenicPressuresSoilInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Tillage intensity","Pesticide Invertebrates"];
		list<string> notes <- [resultat_TillageIntensity(current_parc), resultat_PesticideSoilInvertebrates(current_parc)];
//		write "resultat_AnthropogenicPressuresSoilInvertebrates = " + resultat_branche(regles, notes, Anthropogenic_pressures_Soil_invertebrates);

		return resultat_branche(regles, notes, Anthropogenic_pressures_Soil_invertebrates);
	}
	
	string resultat_TrophicRessourcesSoilInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Microorganisms","Vegetation"];
		list<string> notes <- [resultat_Microorganisms(current_parc), resultat_Vegetation(current_parc)];
//		write "resultat_TrophicRessourcesSoilInvertebrates = " + resultat_branche(regles, notes, Trophic_ressources_Soil_invertebrates);
		
		return resultat_branche(regles, notes, Trophic_ressources_Soil_invertebrates);
	}

	string resultat_SoilInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Anthropogenic pressures Soil invertebrates","Trophic ressources Soil invertebrates"];
		list<string> notes <- [resultat_AnthropogenicPressuresSoilInvertebrates(current_parc), resultat_TrophicRessourcesSoilInvertebrates(current_parc)];
//		write "resultat_SoilInvertebrates = " + resultat_branche(regles, notes, Soil_invertebrates);

		return resultat_branche(regles, notes, Soil_invertebrates);
	}

	string resultat_PesticideFlyingInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Insecticide","Other"];
		list<string> notes <- [resultat_Insecticide(current_parc), resultat_OtherPesticide(current_parc)];
//		write "resultat_PesticideFlyingInvertebrates = " + resultat_branche(regles, notes, Pesticide_Flying_Invertebrates);

		return resultat_branche(regles, notes, Pesticide_Flying_Invertebrates);
	}
	
	string resultat_AnthropogenicPressuresFlyingInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Pesticide Invertebrates","Landscape simplification"];
		list<string> notes <- [resultat_PesticideFlyingInvertebrates(current_parc), resultat_LandscapeSimplification(current_parc)];
//		write "resultat_AnthropogenicPressuresFlyingInvertebrates = " + resultat_branche(regles, notes, Anthropogenic_pressures_Flying_invertebrates);

		return resultat_branche(regles, notes, Anthropogenic_pressures_Flying_invertebrates);
	}

	string resultat_TrophicRessourcesFlyingInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Vegetation"];
		list<string> notes <- [resultat_Vegetation(current_parc)];
//		write "resultat_TrophicRessourcesFlyingInvertebrates = " + resultat_branche(regles, notes, Trophic_ressources_Flying_invertebrates);

		return resultat_branche(regles, notes, Trophic_ressources_Flying_invertebrates);
	}

	string resultat_FlyingInvertebrates (parcelle current_parc) {		
		list<string> regles <- ["Anthropogenic pressures Flying invertebrates","Trophic ressources Flying invertebrates"];
		list<string> notes <- [resultat_AnthropogenicPressuresFlyingInvertebrates(current_parc), resultat_TrophicRessourcesFlyingInvertebrates(current_parc)];
//		write "resultat_FlyingInvertebrates = " + resultat_branche(regles, notes, Flying_invertebrates);

		return resultat_branche(regles, notes, Flying_invertebrates);
	}

	string resultat_Invertebrates (parcelle current_parc) {		
		list<string> regles <- ["Soil invertebrates","Flying invertebrates"];
		list<string> notes <- [resultat_SoilInvertebrates(current_parc), resultat_FlyingInvertebrates(current_parc)];
//		write "resultat_Invertebrates = " + resultat_branche(regles, notes, Invertebrates);

		return resultat_branche(regles, notes, Invertebrates);
	}



	// --- Vertebrates ---------------
	string resultat_MachineryUse (parcelle current_parc) {		
		list<string> regles <- ["Tillage intensity","Mowing"];
		list<string> notes <- [resultat_TillageIntensity(current_parc), resultat_Mowing(current_parc)];
//		write "resultat_MachineryUse = " + resultat_branche(regles, notes, Machinery_use);

		return resultat_branche(regles, notes, Machinery_use);
	}
	
	string resultat_AnthropogenicPressuresVertebrates (parcelle current_parc) {		
		list<string> regles <- ["Pesticide","Machinery use", "Landscape simplification"];
		list<string> notes <- [resultat_Pesticide(current_parc), resultat_MachineryUse(current_parc), resultat_LandscapeSimplification(current_parc)];
//		write "resultat_AnthropogenicPressuresVertebrates = " + resultat_branche(regles, notes, Anthropogenic_pressures_Vertebrates);

		return resultat_branche(regles, notes, Anthropogenic_pressures_Vertebrates);
	}
	
	string resultat_TrophicRessourcesVertebrates (parcelle current_parc) {		
		list<string> regles <- ["Vegetation", "Invertebrates"];
		list<string> notes <- [resultat_Vegetation(current_parc), resultat_Invertebrates(current_parc)];
//		write "resultat_TrophicRessourcesVertebrates = " + resultat_branche(regles, notes, Trophic_ressources_Vertebrates);
		return resultat_branche(regles, notes, Trophic_ressources_Vertebrates);
	}

	string resultat_Vertebrates (parcelle current_parc) {		
		list<string> regles <- ["Anthropogenic pressures Vertebrates", "Trophic ressources Vertebrates"];
		list<string> notes <- [resultat_AnthropogenicPressuresVertebrates(current_parc), resultat_TrophicRessourcesVertebrates(current_parc)];
//		write "resultat_Vertebrates = " + resultat_branche(regles, notes, Vertebrates);
		return resultat_branche(regles, notes, Vertebrates);
	}
	


	// ********************* ECRITURE DES RESULTATS ********************* //
	 /*
	* @Overwrite
	*/
	
	action debug_ibio (list<string> regles, list<string> notes) {
		string resultat;
		loop i from: 0 to: length(regles) {
			if (notes[i] = nil) {
				write "Problème de calcul pour la règles '" + regles[i] + "'";
			}
		}
	}
	
	reflex enregistrement_valeurs_ibio when: (first(dateCourante).mois = 6 and first(dateCourante).jour = 15) {
		ask listeParcelles {
			// Enregistrement par parcelle pour écriture au 31/12
			ibio_biodiversity <- myself.resultat_Biodiversity(self);
			ibio_microorganisms <- myself.resultat_Microorganisms(self);
			ibio_vegetation <- myself.resultat_Vegetation(self);
			ibio_invertebrates <- myself.resultat_Invertebrates(self);
			ibio_vertebrates <- myself.resultat_Vertebrates(self);	
		}
		
	}
	
	reflex remise_a_zero_valeurs_ibio when: (first(dateCourante).mois = 8 and first(dateCourante).jour = 15) {
		ask listeParcelles {
			// Remise à 0 des variables cumulées // A penser pour map_parcelles_cultures_1km --> il faut remettre la variable à 0 ici une fois qu'elle a été écrite
			nb_traitements_total <- 0;
			herbicide_timing <- "No herbicide";
			nb_traitements_insecticides <- 0;
			nb_traitements_autres <- 0;
			nb_traitements_monocot <- 0;
			nb_traitements_dicot <- 0;
			
			//write "intensite_travailSol = " + intensite_travailSol; // TODO 150424

			intensite_travailSol <- 0.0;
			iBio_QNapport_min <- 0.0;
			n_coupes_fauches <- 0;
			
			self.diversite_cultures <- 0;
		}
		
	}

	
	string initialisationFinAnnuel {
		nomFichierFinAnnuel <- cheminRelatifDuDossierDeSortieDeSimulation +'/resultats_iBIO'+ nomDeLaSimulation + '.csv';  
		// Ligne titre
		string data <- '' + detailSimulation;
		
		// Ajout du nom de chaque parcelle à la ligne de titre
		string idParcelles;
		loop p over: listeParcelles {
			if (empty(idParcelles)) {
				idParcelles <- p.idParcelle;
			} else {
				idParcelles <- idParcelles + ";" + p.idParcelle;
			}
		}
		data <- data + "\nidParcelles" + idParcelles;
		
		return data;
	}
		

	 list<string> ecritureFinAnnuelle {
	 	
//		loop pp over: listeParcelles {
//			write map_parcelles_cultures_1km[pp];
//		}
	 	list<string> data <- [string("\n" + first(dateCourante).annee)];
		// Construction de la string à écire
		loop p over: listeParcelles {
			// Assemblage des indicateurs par taxon pour la parcelle
			string valeur_par_taxon_parcelle;
			valeur_par_taxon_parcelle <- p.ibio_biodiversity;
			// Ecriture finale journalière par parcelle
			data <+ ";" + valeur_par_taxon_parcelle;
		}
		
		return data;
	}
}
