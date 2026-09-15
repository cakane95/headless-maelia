import { useState } from "react";

import OptionPicker from "./OptionPicker";

/** Valeur(s) désignant quelque chose qui vit dans un fichier du projet.
 *
 *  Affichée en étiquettes retirables plutôt qu'en texte : on voit d'un coup
 *  combien de parcelles sont suivies, et on en retire une sans rééditer une
 *  liste séparée par des virgules.
 */
export default function SourcedValue({ spec, value, onChange }) {
  const [picking, setPicking] = useState(false);
  const multiple = spec.type === "LIST";
  // Certains paramètres ont [''] pour défaut : une étiquette vide n'a pas de sens.
  const values = (multiple ? (value ?? []) : [value]).filter((v) => v !== "" && v != null);

  function remove(target) {
    onChange(multiple ? values.filter((v) => v !== target) : "");
  }

  return (
    <>
      <div className="tags">
        {values.map((current) => (
          <span key={current} className="tag">
            {current}
            <button
              type="button"
              aria-label={`Retirer ${current}`}
              onClick={() => remove(current)}
            >
              ×
            </button>
          </span>
        ))}
        {values.length === 0 && <span className="muted">Aucune valeur</span>}
      </div>

      <button type="button" className="ghost" onClick={() => setPicking(true)}>
        {multiple ? "Choisir dans le projet…" : "Choisir…"}
      </button>

      {picking && (
        <OptionPicker
          spec={spec}
          selected={values}
          multiple={multiple}
          onChange={onChange}
          onClose={() => setPicking(false)}
        />
      )}
    </>
  );
}
