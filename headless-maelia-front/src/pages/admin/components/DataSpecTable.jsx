import EmptyState from "../../../components/EmptyState";
import { moduleLabel } from "../../../utils/status";

/** Types de fichiers d'entrée. Le motif remplace le nom pour les familles
 *  à nom dynamique (`2018.csv`, `prixVentesSC1.csv`). */
export default function DataSpecTable({ specs, onSelect }) {
  if (!specs.length) return <EmptyState>Aucun type de fichier ne correspond.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>Module</th>
          <th>Emplacement</th>
          <th>Lecture</th>
          <th>Champs</th>
          <th>Origine</th>
        </tr>
      </thead>
      <tbody>
        {specs.map((spec) => (
          <tr key={spec.id} className="clickable" onClick={() => onSelect(spec.id)}>
            <td>
              {spec.file_name ?? <code>{spec.file_name_pattern}</code>}
              {spec.multi_instance && <em className="row__note">famille de fichiers</em>}
            </td>
            <td className="muted">{moduleLabel(spec.module)}</td>
            <td className="muted"><code>{spec.relative_dir}</code></td>
            <td className="muted">
              {spec.kind}
              {spec.orientation === "FIELDS_AS_ROWS" && " · transposé"}
            </td>
            <td className="muted">{spec.fields.length || "—"}</td>
            <td>
              {/* Une spec USER a été modifiée à la main : le catalogue de
                  référence ne la met plus à jour. Ça doit se voir. */}
              <span className={spec.origin === "USER" ? "badge DRAFT" : "badge"}>
                {spec.origin === "USER" ? "Modifié" : "Référence"}
              </span>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
