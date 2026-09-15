import { useEffect, useState } from "react";

import { fromText, sameValue, toText } from "../../../utils/parameters";

/** Le contrôle de saisie d'un paramètre, choisi sur le type que le catalogue
 *  lui donne. Rien n'est câblé sur un nom de paramètre MAELIA. */
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

  return <TextControl spec={spec} value={value} onChange={onChange} />;
}

const MODES = { INT: "numeric", FLOAT: "decimal" };

/** Saisie libre, avec son propre texte.
 *
 *  Indispensable pour les nombres : sans texte local, « 1.5 » serait réécrit en
 *  « 1 » dès la frappe du point, et le chiffre décimal deviendrait insaisissable.
 */
function TextControl({ spec, value, onChange }) {
  const external = toText(value);
  const [text, setText] = useState(external);

  // La saisie ne suit la valeur que si elle ne la représente plus : c'est le cas
  // après « Rétablir », jamais pendant une frappe en cours.
  useEffect(() => {
    if (!sameValue(fromText(spec.type, text), value)) setText(external);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [external]);

  function type(next) {
    setText(next);
    onChange(fromText(spec.type, next));
  }

  const unreadable = MODES[spec.type] && text.trim() !== "" && fromText(spec.type, text) === null;

  return (
    <>
      <input
        id={spec.name}
        type="text"
        inputMode={MODES[spec.type]}
        value={text}
        placeholder={spec.type === "LIST" ? "valeurs séparées par des virgules" : undefined}
        onChange={(event) => type(event.target.value)}
      />
      {unreadable && <small className="hint hint--warn">Valeur non numérique : ignorée.</small>}
    </>
  );
}
