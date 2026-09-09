/** Contenu des écrans d'attente de l'espace Administration.
 *  Séparé des routes : App.jsx doit rester une carte du site lisible. */

export const catalogueEntrees = {
  title: "Catalogue des entrées",
  lede: "Décrire les fichiers attendus par le modèle.",
  items: [
    "CRUD des types de fichiers : nom, orientation CSV, délimiteur",
    "Champs, types, valeurs autorisées, caractère obligatoire",
    "Dépendances entre fichiers et graphe de génération",
    "Reprise des 71 types de la version Java",
  ],
};

export const catalogueParametres = {
  title: "Paramètres de scénario",
  lede: "Décrire les paramètres exposés par le launcher GAML.",
  items: [
    "CRUD des paramètres : nom GAML, type, défaut, groupe",
    "Valeurs autorisées et conditions de visibilité",
    "Paramètres pilotés par le système (non modifiables)",
    "Reprise des 142 paramètres extraits de launcherBase.gaml",
  ],
};

export const catalogueSorties = {
  title: "Catalogue des sorties",
  lede: "Décrire les fichiers et séries produits par le modèle.",
  items: [
    "CRUD des fichiers de sortie et de leur format de lecture",
    "Séries à extraire, agrégations, unités",
    "Restitution : graphiques et exports",
  ],
};
