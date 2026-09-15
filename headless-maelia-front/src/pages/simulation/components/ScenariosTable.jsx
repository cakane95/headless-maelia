import EmptyState from "../../../components/EmptyState";
import { summarise } from "../../../utils/parameters";

/** Scénarios d'un projet. Purement présentationnel.
 *
 *  La colonne des écarts dit ce qui distingue ce scénario des autres — c'est la
 *  seule information qui compte quand on en compare cinq.
 */
export default function ScenariosTable({ scenarios, onOpen, onDuplicate, onDelete }) {
  if (scenarios.length === 0) {
    return (
      <EmptyState>Aucun scénario pour l'instant. Créez-en un pour lancer une simulation.</EmptyState>
    );
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Écarts au modèle</th>
          <th className="cell--actions" />
        </tr>
      </thead>
      <tbody>
        {scenarios.map((scenario) => (
          <tr key={scenario.id} className="clickable" onClick={() => onOpen(scenario.id)}>
            <td>
              {scenario.name}
              {scenario.description && <em className="row__note">{scenario.description}</em>}
            </td>
            <td className="muted">{summarise(scenario.parameter_values)}</td>
            <td className="cell--actions" onClick={(event) => event.stopPropagation()}>
              <button type="button" className="ghost" onClick={() => onDuplicate(scenario)}>
                Dupliquer
              </button>{" "}
              <button type="button" className="ghost" onClick={() => onDelete(scenario)}>
                Supprimer
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
