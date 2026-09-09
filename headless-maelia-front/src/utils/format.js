/** Formatage d'affichage. Aucune règle métier ici. */

export function formatBytes(bytes) {
  return `${(bytes / 1024).toFixed(1)} ko`;
}

/** Durée d'une exécution : écoulée si elle tourne encore, totale sinon. */
export function formatDuration(run) {
  if (!run?.started_at) return "—";
  const fin = run.ended_at ?? Date.now() / 1000;
  return `${Math.round(fin - run.started_at)} s`;
}
