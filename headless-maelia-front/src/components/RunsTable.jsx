import EmptyState from "./EmptyState";
import StatusBadge from "./StatusBadge";
import StopRun from "./StopRun";
import { formatDuration } from "../utils/format";
import { runLabel } from "../utils/status";

/** Historique des exécutions. Purement présentationnel.
 *
 *  `onResults` est optionnel : le banc d'essai n'a pas de projet, donc pas
 *  d'écran de résultats à ouvrir. `onStop` l'est aussi, mais la colonne
 *  d'actions apparaît dès que l'un des deux est fourni.
 */
export default function RunsTable({ runs, onSelect, onResults, onStop }) {
  const actions = Boolean(onResults || onStop);
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
          {actions && <th className="cell--actions" />}
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
            {actions && (
              <td className="cell--actions" onClick={(event) => event.stopPropagation()}>
                {onStop && <StopRun run={run} onStop={onStop} />}
                {onResults && run.status === "FINISHED" && (
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
