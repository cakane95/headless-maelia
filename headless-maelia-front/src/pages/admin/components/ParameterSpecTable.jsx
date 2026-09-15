import EmptyState from "../../../components/EmptyState";
import { toLabel } from "../../../utils/parameters";

/** Paramètres de scénario. Purement présentationnel. */
export default function ParameterSpecTable({ specs, onSelect }) {
  if (!specs.length) return <EmptyState>Aucun paramètre ne correspond.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Type</th>
          <th>Défaut</th>
          <th>Commandé par</th>
          <th>Origine</th>
        </tr>
      </thead>
      <tbody>
        {specs.map((spec) => (
          <tr key={spec.name} className="clickable" onClick={() => onSelect(spec.name)}>
            <td>
              <code>{spec.name}</code>
              {spec.label !== spec.name && <em className="row__note">{spec.label}</em>}
            </td>
            <td className="muted">{spec.type}</td>
            <td className="muted">{toLabel(spec.default)}</td>
            <td className="muted">
              {/* Un paramètre commandé par un autre reste grisé tant que
                  celui-ci est éteint. */}
              {spec.enabled_if ? <code>{spec.enabled_if}</code> : "—"}
            </td>
            <td>
              {spec.system ? (
                <span className="badge INVALID">Plateforme</span>
              ) : (
                <span className={spec.origin === "USER" ? "badge DRAFT" : "badge"}>
                  {spec.origin === "USER" ? "Modifié" : "Launcher"}
                </span>
              )}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
