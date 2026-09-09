import EmptyState from "../../../components/EmptyState";

/** Types de fichiers d'entrée. Le motif remplace le nom pour les familles
 *  à nom dynamique (`2018.csv`, `prixVentesSC1.csv`). */
export default function DataSpecTable({ specs }) {
  if (!specs.length) return <EmptyState>Aucun type de fichier.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>Emplacement</th>
          <th>Type</th>
          <th>Champs</th>
          <th>Condition</th>
        </tr>
      </thead>
      <tbody>
        {specs.map((spec) => (
          <tr key={spec.id}>
            <td>
              {spec.file_name ?? <code>{spec.file_name_pattern}</code>}
              {spec.multi_instance && <span className="muted"> (multi)</span>}
            </td>
            <td className="muted"><code>{spec.relative_dir}</code></td>
            <td className="muted">
              {spec.kind}
              {spec.orientation === "FIELDS_AS_ROWS" && " · transposé"}
            </td>
            <td className="muted">{spec.fields.length || "—"}</td>
            <td className="muted">{spec.required_if ?? "toujours"}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
