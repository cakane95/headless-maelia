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
          <th>Attendu</th>
          <th>Module</th>
          <th>État</th>
          <th>Fichiers</th>
          <th className="cell--actions" />
        </tr>
      </thead>
      <tbody>
        {entries.map((entry) => {
          const dataset = datasetsBySpec?.[entry.data_spec_id];
          // Une famille mene a la liste de ses fichiers ; un fichier unique
          // mene directement a ses versions.
          const cible = entry.multi_instance
            ? `/simulation/projets/${projectId}/donnees/famille/${encodeURIComponent(entry.data_spec_id)}`
            : dataset && `/simulation/projets/${projectId}/donnees/${dataset.id}`;
          return (
            <tr
              key={entry.data_spec_id}
              className={cible ? "clickable" : undefined}
              onClick={cible ? () => navigate(cible) : undefined}
            >
              <td>{entry.label}</td>
              <td>
                {/* Obligatoire : le modèle s'arrête sans lui. Facultatif : il
                    continue, avec moins de détail. */}
                <span className={entry.required ? "badge INVALID" : "badge"}>
                  {entry.required ? "Obligatoire" : "Facultatif"}
                </span>
              </td>
              <td className="muted">{moduleLabel(entry.module)}</td>
              <td><FileStatusBadge status={entry.status} /></td>
              <td className="muted">
                {entry.multi_instance
                  ? `${entry.instances} fichier${entry.instances > 1 ? "s" : ""}`
                  : `${dataset?.versions?.length ?? 0} version${(dataset?.versions?.length ?? 0) > 1 ? "s" : ""}`}
              </td>
              <td className="cell--actions muted">{cible ? "Ouvrir →" : ""}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
