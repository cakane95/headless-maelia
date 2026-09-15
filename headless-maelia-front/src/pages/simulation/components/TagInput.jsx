import { useState } from "react";

/** Liste libre : une valeur par étiquette, ajoutée à la validation.
 *
 *  Remplace la saisie « a, b, c » : on voit ce que contient la liste, on retire
 *  un élément au milieu sans recompter les virgules, et une valeur contenant un
 *  espace n'est plus ambiguë.
 */
export default function TagInput({ id, values, onChange, placeholder }) {
  const [draft, setDraft] = useState("");

  function add() {
    const value = draft.trim();
    if (value && !values.includes(value)) onChange([...values, value]);
    setDraft("");
  }

  function key(event) {
    if (event.key === "Enter" || event.key === ",") {
      // Sans cela, Entrée soumettrait le formulaire au lieu d'ajouter la valeur.
      event.preventDefault();
      add();
    } else if (event.key === "Backspace" && !draft && values.length > 0) {
      onChange(values.slice(0, -1));
    }
  }

  return (
    <>
      <div className="tags">
        {values.map((value) => (
          <span key={value} className="tag">
            {value}
            <button type="button" aria-label={`Retirer ${value}`}
                    onClick={() => onChange(values.filter((v) => v !== value))}>
              ×
            </button>
          </span>
        ))}
        {values.length === 0 && <span className="muted">Liste vide</span>}
      </div>

      <input
        id={id}
        type="text"
        value={draft}
        placeholder={placeholder ?? "Ajouter une valeur, puis Entrée"}
        onChange={(event) => setDraft(event.target.value)}
        onKeyDown={key}
        onBlur={add}
      />
    </>
  );
}
