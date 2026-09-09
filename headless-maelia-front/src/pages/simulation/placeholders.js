/** Contenu des écrans d'attente de l'espace Simulation. */

export const projets = {
  title: "Mes projets",
  lede: "Exploiter un modèle sur un territoire.",
  items: [
    "Créer un projet et sa configuration de modélisation",
    "Suivi de complétude des données d'entrée",
  ],
};

export const donnees = {
  title: "Données d'entrée",
  lede: "Téléverser, saisir et versionner les données du projet.",
  items: [
    "Upload CSV / ZIP / shapefiles, validés contre le catalogue",
    "Saisie en ligne et versionnage des modifications",
    "Matérialisation des includes au lancement d'un run",
  ],
};

export const scenarios = {
  title: "Scénarios",
  lede: "Composer les écarts aux valeurs par défaut du modèle.",
  items: ["CRUD des scénarios", "Validation contre le catalogue de paramètres"],
};

export const simulations = {
  title: "Simulations",
  lede: "Lancer et suivre les runs d'un projet.",
  items: [
    "Réutilise le pilotage worker validé sur le banc d'essai",
    "Version des données figée à chaque run",
  ],
};

export const resultats = {
  title: "Résultats",
  lede: "Consulter et exporter les sorties.",
  items: ["Séries temporelles et agrégats", "Export des artefacts"],
};
