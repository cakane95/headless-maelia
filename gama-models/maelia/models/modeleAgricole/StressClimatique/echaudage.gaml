/**
* Name: echaudage
* Prise en compte de l'effet du echaudage sur le rendement 
* Author: Renaud Misslin
* Tags: 
*/


model echaudage



global {
	
	// Est-ce que le jour courant est un jour échaudant ? (utilisée dans une action de cultureAqYield.gaml)
	bool isJourEchaudant (float cumulDegresJour, float gddRemplissage, float gddMaturite, float tempJ, float tempMaxCulture) {
		bool result <- false;
		// Est-ce qu'on est dans la période durant laquelle la plante est sensible à l'échaudage ?
		if (cumulDegresJour >= gddRemplissage and cumulDegresJour < gddMaturite) {
			// Est-ce que la température du jour est trop élevée ?
			if (tempJ > tempMaxCulture) {
				result <- true;
			}
		}
		return result;
	}
}

