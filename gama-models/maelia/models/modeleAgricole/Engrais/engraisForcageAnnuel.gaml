/**
* Name: digestatSolideForcage
*  
* Author: hadelattre // RM 040425 Forcage des engrais à partir d'un fichier d'entrée (formation dev 03/2025, proposition d'Hadrien et Elsa)
* Tags: 
*/


model EngraisForcageAnnuel

species EngraisForcageAnnuel {
	string chemin_donnees;
	map<int,map<string,float>> composition; // {anne: {fraction: quantité}}
	init {
		file fichier_donnees <- csv_file(chemin_donnees, ";", true);
		matrix matrice_donnees <- matrix(fichier_donnees.contents);
		loop row over: rows_list(matrice_donnees) {
			string fraction <- row[0];
			float quantite <- float(row[1]);
			int annee <- int(row[2]);
			if composition[annee] = nil {
				composition[annee] <- [fraction::quantite];
			} else {
				composition[annee][fraction] <- quantite;
			}	
		}
		write(composition);
	}
}