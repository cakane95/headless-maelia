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

/** Rubriques d'un projet. Elles transportent son identifiant : chaque projet a
 *  ses propres données, scénarios et résultats. */
export function projectNav(projectId, projectName) {
  const base = `/simulation/projets/${projectId}`;
  return [
    {
      title: projectName || "Projet",
      links: [
        { to: `${base}/initialisation`, label: "Initialisation" },
        { to: `${base}/donnees`, label: "Données d'entrée" },
        { to: `${base}/scenarios`, label: "Scénarios" },
        { to: `${base}/simulations`, label: "Simulations" },
        { to: `${base}/resultats`, label: "Résultats" },
      ],
    },
  ];
}
