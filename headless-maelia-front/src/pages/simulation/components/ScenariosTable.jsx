import EmptyState from "../../../components/EmptyState";

/** Scénarios d'un projet. Purement présentationnel. */
export default function ScenariosTable({ scenarios, onSelect }) {
  if (scenarios.length === 0) {
    return <EmptyState>Aucun scénario pour l'instant. Créez-en un pour lancer une simulation.</EmptyState>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Paramètres modifiés</th>
          <th>Versions épinglées</th>
        </tr>
      </thead>
      <tbody>
        {scenarios.map((scenario) => (
          <tr key={scenario.id} className="clickable" onClick={() => onSelect(scenario.id)}>
            <td>{scenario.name}</td>
            <td className="muted">
              {Object.entries(scenario.parameter_values)
                .map(([name, value]) => `${name}=${value}`)
                .join(", ") || "—"}
            </td>
            <td className="muted">{Object.keys(scenario.dataset_pins).length || "aucune"}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
