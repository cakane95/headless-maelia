import { useState } from "react";

import Field from "../../../components/Field";

/** Réglages qui déterminent quels fichiers d'entrée sont attendus.
 *
 *  On n'expose que les leviers d'activation : ce sont eux qui font varier la
 *  liste des fichiers. Les 148 paramètres du launcher relèvent du scénario, pas
 *  de la configuration du projet.
 */
const SWITCHES = [
  ["executerModeleAgricole", "Modèle agricole"],
  ["executerModeleHydrographique", "Modèle hydrographique"],
  ["executerModeleNormatif", "Modèle normatif"],
  ["executerModeleElevage", "Modèle élevage"],
  ["avecIlotsHorsZone", "Îlots hors zone"],
  ["executerBarrage", "Barrages"],
];

const CHOICES = [
  ["nomChoixModeleHydrographique", "Modèle hydrographique", ["SWAT", "Simple"]],
  ["nomChoixAssolement", "Assolement", ["Donnees", "FonctionsDeCroyances"]],
  ["nomChoixModeleCroissancePrairie", "Croissance prairie", ["HerbSimNC", "HerbSim", "AqYield"]],
];

export default function ModelingConfigForm({ config, onSubmit }) {
  const [draft, setDraft] = useState(config ?? {});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const [saved, setSaved] = useState(false);

  function set(key, value) {
    setSaved(false);
    setDraft((current) => ({ ...current, [key]: value }));
  }

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit(draft);
      setSaved(true);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <p className="muted muted--first">
        Activer un module rend ses fichiers d'entrée obligatoires.
      </p>

      {SWITCHES.map(([key, label]) => (
        <label className="switch" key={key}>
          <input
            type="checkbox"
            checked={Boolean(draft[key])}
            onChange={(e) => set(key, e.target.checked)}
          />
          <span>{label}</span>
        </label>
      ))}

      {CHOICES.map(([key, label, options]) => (
        <Field label={label} key={key}>
          <select value={draft[key] ?? options[0]} onChange={(e) => set(key, e.target.value)}>
            {options.map((o) => <option key={o} value={o}>{o}</option>)}
          </select>
        </Field>
      ))}

      <button disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer la configuration"}</button>
      {saved && <span className="muted"> Configuration enregistrée.</span>}
      {error && <p className="error">{error}</p>}
    </form>
  );
}
