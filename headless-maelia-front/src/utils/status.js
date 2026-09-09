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
