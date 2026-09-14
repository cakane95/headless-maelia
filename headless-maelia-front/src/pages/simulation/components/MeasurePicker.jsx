import Field from "../../../components/Field";

/** Choix des mesures tracées.
 *
 *  Un fichier de sortie MAELIA compte jusqu'à une trentaine de mesures : une
 *  liste de cases est plus lisible qu'un `select multiple`, et l'unité y est
 *  visible — comparer des mm à des kgN/ha n'a pas de sens.
 */
export default function MeasurePicker({ measures, selected, onChange }) {
  function toggle(name) {
    const next = selected.includes(name)
      ? selected.filter((m) => m !== name)
      : [...selected, name];
    // Un graphique sans mesure n'existe pas : la dernière ne se décoche pas.
    if (next.length > 0) onChange(next);
  }

  return (
    <Field label={`Mesures (${selected.length})`}>
      <div className="checks">
        {measures.map((measure) => (
          <label key={measure.name} className="check">
            <input
              type="checkbox"
              checked={selected.includes(measure.name)}
              onChange={() => toggle(measure.name)}
            />
            <span>
              {measure.label}
              {measure.unit && <em className="unit"> {measure.unit}</em>}
            </span>
          </label>
        ))}
      </div>
    </Field>
  );
}
