import EmptyState from "../../../components/EmptyState";
import StatusBadge from "../../../components/StatusBadge";
import { formatDuration } from "../../../utils/format";
import { runLabel } from "../../../utils/status";

/** Historique des exécutions. Purement présentationnel. */
export default function RunsTable({ runs, onSelect }) {
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
          </tr>
        ))}
      </tbody>
    </table>
  );
}
