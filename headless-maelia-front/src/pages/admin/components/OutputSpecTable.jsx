import EmptyState from "../../../components/EmptyState";
import { granularityLabel } from "../../../utils/outputs";

/** Sorties du modèle. Purement présentationnel.
 *
 *  La colonne « Commandée par » porte l'essentiel : c'est elle qui répond à
 *  « que dois-je activer pour obtenir ce fichier ? ».
 */
export default function OutputSpecTable({ specs, onSelect }) {
  if (!specs.length) return <EmptyState>Aucune sortie ne correspond.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>Sortie</th>
          <th>Fichiers</th>
          <th>Pas de temps</th>
          <th>Commandée par</th>
          <th>État</th>
        </tr>
      </thead>
      <tbody>
        {specs.map((spec) => (
          <tr key={spec.id} className="clickable" onClick={() => onSelect(spec.id)}>
            <td>
              <code>{spec.id}</code>
              {spec.description && <em className="row__note">{spec.description}</em>}
            </td>
            <td className="muted">
              {spec.files.map((f) => (
                <div key={f.name}>{f.name}</div>
              ))}
            </td>
            <td className="muted">
              {[...new Set(spec.files.map((f) => granularityLabel(f.granularity)))].join(" · ")}
            </td>
            <td className="muted cell--default" title={spec.produced_if ?? ""}>
              {spec.flag ? <code>{spec.flag}</code> : "—"}
            </td>
            <td>
              {spec.unreachable.length > 0 ? (
                <span
                  className="badge INVALID"
                  title={`Le launcher n'expose pas : ${spec.unreachable.join(", ")}`}
                >
                  Hors de portée
                </span>
              ) : !spec.exact ? (
                <span className="badge DRAFT" title={spec.guard_source ?? ""}>
                  Condition partielle
                </span>
              ) : (
                <span className={spec.origin === "USER" ? "badge DRAFT" : "badge"}>
                  {spec.origin === "USER" ? "Modifiée" : "Modèle"}
                </span>
              )}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
