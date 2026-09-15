import ParameterTextInput from "./ParameterTextInput";
import SourcedValue from "./SourcedValue";
import TagInput from "./TagInput";
import { toText } from "../../../utils/parameters";

/** Le contrôle de saisie d'un paramètre, choisi sur ce que le catalogue en dit.
 *
 *  Quatre cas, du plus contraint au plus libre : un booléen, une liste fermée,
 *  une valeur qui désigne quelque chose dans un fichier du projet, une saisie
 *  libre. Rien n'est câblé sur un nom de paramètre MAELIA.
 */
export default function ParameterControl({ spec, value, onChange }) {
  if (spec.type === "BOOL") {
    return (
      <label className="switch">
        <input
          id={spec.name}
          type="checkbox"
          checked={Boolean(value)}
          onChange={(event) => onChange(event.target.checked)}
        />
        <span>{value ? "Activé" : "Désactivé"}</span>
      </label>
    );
  }

  if (spec.allowed_values.length > 0) {
    return (
      <select id={spec.name} value={toText(value)} onChange={(e) => onChange(e.target.value)}>
        {spec.allowed_values.map((allowed) => (
          <option key={allowed} value={allowed}>{allowed}</option>
        ))}
      </select>
    );
  }

  // La valeur désigne une entité d'un fichier du projet : on la choisit dedans.
  if (spec.options_from) {
    return <SourcedValue spec={spec} value={value} onChange={onChange} />;
  }

  if (spec.type === "LIST") {
    return (
      <TagInput
        id={spec.name}
        values={(Array.isArray(value) ? value : []).filter(Boolean)}
        onChange={onChange}
      />
    );
  }

  return <ParameterTextInput spec={spec} value={value} onChange={onChange} />;
}
