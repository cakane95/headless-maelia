import { useEffect, useState } from "react";

import { fromText, sameValue, toText } from "../../../utils/parameters";

const MODES = { INT: "numeric", FLOAT: "decimal" };

/** Saisie libre, avec son propre texte.
 *
 *  Indispensable pour les nombres : sans texte local, « 1.5 » serait réécrit en
 *  « 1 » dès la frappe du point, et le chiffre décimal deviendrait insaisissable.
 */
export default function ParameterTextInput({ spec, value, onChange }) {
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
