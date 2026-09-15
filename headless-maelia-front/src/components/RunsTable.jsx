import EmptyState from "./EmptyState";
import StatusBadge from "./StatusBadge";
import { formatDuration } from "../utils/format";
import { runLabel } from "../utils/status";

/** Historique des exécutions. Purement présentationnel.
 *
 *  `onResults` est optionnel : le banc d'essai n'a pas de projet, donc pas
 *  d'écran de résultats à ouvrir.
 */
export default function RunsTable({ runs, onSelect, onResults }) {
  if (runs.length === 0) return <EmptyState>Aucun run pour l'instant.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>Libellé</th>
          <th>Statut</th>
          <th>Progression</th>
          <th>Durée</th>
          <th>Sorties</th>
          {onResults && <th className="cell--actions" />}
        </tr>
      </thead>
      <tbody>
        {runs.map((run) => (
          <tr key={run.id} className="clickable" onClick={() => onSelect(run.id)}>
            <td>{run.label}</td>
            <td>
              <StatusBadge status={run.status} label={runLabel(run.status)} />
            </td>
            <td className="muted">{run.current_date ?? "—"}</td>
            <td className="muted">{formatDuration(run)}</td>
            <td className="muted">{run.artifacts?.length ?? 0}</td>
            {onResults && (
              <td className="cell--actions" onClick={(event) => event.stopPropagation()}>
                {run.status === "FINISHED" && (
                  <button type="button" className="ghost" onClick={() => onResults(run.id)}>
                    Résultats
                  </button>
                )}
              </td>
            )}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
