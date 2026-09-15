/** Les leviers de configuration d'un projet, sous forme de données.
 *
 *  On n'expose que ce qui fait varier la liste des fichiers attendus. Les 142
 *  paramètres du launcher relèvent du scénario, pas de la configuration.
 */
export const MODULES = [
  ["executerModeleAgricole", "Modèle agricole",
   "Assolements, itinéraires techniques, fertilisation, rendements."],
  ["executerModeleHydrographique", "Modèle hydrographique",
   "Bassins versants, débits, prélèvements et restrictions."],
  ["executerModeleNormatif", "Modèle normatif",
   "Règles de gestion et arrêtés de restriction."],
  ["executerModeleElevage", "Modèle élevage",
   "Troupeaux, pâturage et effluents."],
  ["avecIlotsHorsZone", "Îlots hors zone",
   "Prend en compte les parcelles situées hors du périmètre d'étude."],
  ["executerBarrage", "Barrages",
   "Retenues et lâchers, en complément du modèle hydrographique."],
];

// Un choix n'a de sens que si son module est actif : l'afficher sinon ferait
// croire qu'il change quelque chose.
export const CHOICES = [
  ["nomChoixModeleHydrographique", "Modèle hydrographique", ["SWAT", "Simple"],
   "executerModeleHydrographique"],
  ["nomChoixAssolement", "Origine de l'assolement", ["Donnees", "FonctionsDeCroyances"],
   "executerModeleAgricole"],
  ["nomChoixModeleCroissancePrairie", "Croissance des prairies",
   ["HerbSimNC", "HerbSim", "AqYield"], "executerModeleAgricole"],
];
