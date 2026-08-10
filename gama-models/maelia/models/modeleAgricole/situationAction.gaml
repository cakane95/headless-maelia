/**
* Name: situationAction
* Décrit les agents situationAction qui représentent un ensemble unique de critères de spatialisation (culture x précédent x sol x type d'exploitation x matériel d'irrigation) 
* Author: rmisslin
* Tags: 
*/


model situationAction

/* Insert your model definition here */

import "../modeleCommun/donneesGlobales.gaml"
import "../modeleHydrographique/zoneHydrographique.gaml"

global {
	
}

species situationAction {
	// Critères de spatialisation
	especeCultivee espece_situation;
	especeCultivee precedent_situation;
	string sol_situation;
	string typeExploitation_situation;
	materielIrrigation materieIrrigation_situation;
	
	// Variables appartenant à cet ensemble de criètres
	map<int, list<float>> annees_rendements; // Annee::[rendement1, rendement2, ...]
	map<int, list<float>> annees_Nmin; // Annee::[NminCumul1, NminCumul2, ...]
}