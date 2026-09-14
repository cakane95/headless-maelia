import EmptyState from "../../../components/EmptyState";
import { formatDuration } from "../../../utils/format";

/** Exécutions terminées d'un projet.
 *
 *  Cases à cocher plutôt que sélection simple : cocher deux runs superpose
 *  leurs courbes, ce qui est exactement la comparaison de scénarios.
 */
export default function FinishedRuns({ runs, selectedIds, onToggle }) {
  if (runs.length === 0) {
    return (
      <EmptyState>
        Aucune simulation terminée. Lancez-en une depuis la rubrique Simulations.
      </EmptyState>
    );
  }

  function toggle(id) {
    const next = selectedIds.includes(id)
      ? selectedIds.filter((run) => run !== id)
      : [...selectedIds, id];
    // Sans run coché il n'y a plus rien à afficher : le dernier reste.
    if (next.length > 0) onToggle(next);
  }

  return (
    <table>
      <thead>
        <tr>
          <th />
          <th>Libellé</th>
          <th>Date simulée</th>
          <th>Durée</th>
          <th>Fichiers</th>
        </tr>
      </thead>
      <tbody>
        {runs.map((run) => (
          <tr
            key={run.id}
            className={selectedIds.includes(run.id) ? "clickable selected" : "clickable"}
            onClick={() => toggle(run.id)}
          >
            <td>
              <input
                type="checkbox"
                checked={selectedIds.includes(run.id)}
                onChange={() => toggle(run.id)}
                onClick={(event) => event.stopPropagation()}
                aria-label={`Comparer ${run.label}`}
              />
            </td>
            <td>{run.label}</td>
            <td className="muted">{run.current_date ?? "—"}</td>
            <td className="muted">{formatDuration(run)}</td>
            <td className="muted">{run.artifacts?.length ?? 0}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
