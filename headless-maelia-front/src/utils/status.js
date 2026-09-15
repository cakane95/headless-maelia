/** Libellés français des statuts renvoyés par l'API (qui, elle, est en anglais). */
const RUN_LABELS = {
  PENDING: "En attente",
  RUNNING: "En cours",
  FINISHED: "Terminé",
  FAILED: "Échec",
  CANCELLED: "Annulé",
};

export function runLabel(status) {
  return RUN_LABELS[status] ?? status;
}

/** Un run occupe-t-il encore le moteur ? Sert au rafraîchissement adaptatif. */
export const ACTIVE_RUN_STATUSES = ["PENDING", "RUNNING"];

/** Libellés français des états d'un fichier d'entrée. */
const FILE_LABELS = {
  MISSING: "Absent",
  DRAFT: "Brouillon",
  VALID: "Valide",
  INVALID: "Invalide",
};

export function fileStatusLabel(status) {
  return FILE_LABELS[status] ?? status;
}

/** Libellés français des modules du modèle.
 *
 *  Le nom vient du catalogue, c'est-à-dire du dossier que MAELIA lit
 *  (`modeleAgricole`). Le traduire est une affaire d'affichage : un module
 *  inconnu garde son nom plutôt que de disparaître.
 */
const MODULE_LABELS = {
  modeleAgricole: "Modèle agricole",
  modeleCommun: "Commun",
  modeleHydrographique: "Modèle hydrographique",
  modeleNormatif: "Modèle normatif",
  modeleElevage: "Modèle élevage",
  modeleFiliere: "Modèle filière",
};

export function moduleLabel(name) {
  return MODULE_LABELS[name] ?? name;
}
