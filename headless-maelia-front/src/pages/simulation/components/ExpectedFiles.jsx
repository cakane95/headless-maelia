import { useNavigate } from "react-router";

import EmptyState from "../../../components/EmptyState";
import FileStatusBadge from "../../../components/FileStatusBadge";
import { moduleLabel } from "../../../utils/status";

/** Fichiers attendus par la configuration, et leur état. */
export default function ExpectedFiles({ entries, datasetsBySpec, projectId }) {
  const navigate = useNavigate();
  if (!entries?.length) {
    return <EmptyState>Aucun fichier ne correspond à ce filtre.</EmptyState>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>Module</th>
          <th>État</th>
          <th>Versions</th>
          <th className="cell--actions" />
        </tr>
      </thead>
      <tbody>
        {entries.map((entry) => {
          const dataset = datasetsBySpec?.[entry.data_spec_id];
          return (
            <tr
              key={entry.data_spec_id}
              className={dataset ? "clickable" : undefined}
              onClick={
                dataset
                  ? () => navigate(`/simulation/projets/${projectId}/donnees/${dataset.id}`)
                  : undefined
              }
            >
              <td>{entry.label}</td>
              <td className="muted">{moduleLabel(entry.module)}</td>
              <td><FileStatusBadge status={entry.status} /></td>
              <td className="muted">{dataset?.versions?.length ?? 0}</td>
              <td className="cell--actions muted">{dataset ? "Ouvrir →" : ""}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
