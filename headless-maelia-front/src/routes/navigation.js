/** Navigation des deux espaces, sous forme de données : les layouts n'ont plus
 *  qu'à la rendre, et ajouter une rubrique se fait en une ligne. */

export const adminNav = [
  {
    title: "Administration",
    links: [
      { to: "/admin", label: "Tableau de bord", end: true },
      { to: "/admin/modeles", label: "Modèles" },
      { to: "/admin/banc-essai", label: "Banc d'essai" },
    ],
  },
  {
    title: "Catalogues",
    links: [
      { to: "/admin/catalogue/entrees", label: "Entrées" },
      { to: "/admin/catalogue/parametres", label: "Paramètres scénario" },
      { to: "/admin/catalogue/sorties", label: "Sorties" },
    ],
  },
];

export const simulationNav = [
  {
    title: "Simulation",
    links: [
      { to: "/simulation", label: "Mes projets", end: true },
      { to: "/simulation/resultats", label: "Résultats" },
    ],
  },
];
