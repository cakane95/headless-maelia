import StatGroup from "./StatGroup";
import StatusBadge from "./StatusBadge";
import { formatDuration } from "../utils/format";
import { runLabel } from "../utils/status";

/** Chiffres clés d'une exécution. */
export default function RunSummary({ run }) {
  return (
    <>
      <StatGroup
        items={[
          { label: "Statut", value: <StatusBadge status={run.status} label={runLabel(run.status)} /> },
          { label: "Date simulée", value: run.current_date ?? "—" },
          { label: "Cycle", value: run.cycle ?? "—" },
          { label: "Durée", value: formatDuration(run) },
          { label: "Fichiers produits", value: run.artifacts?.length ?? 0 },
        ]}
      />
      {run.error && <p className="error error--last">{run.error}</p>}
    </>
  );
}
