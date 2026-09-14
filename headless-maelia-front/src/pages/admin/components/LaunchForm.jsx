import { useState } from "react";

import Field from "../../../components/Field";

/** Formulaire de lancement. Ne connaît ni le réseau ni la navigation : il remonte
 *  la demande à la page, qui décide quoi en faire. */
export default function LaunchForm({ models, onLaunch, onCancel }) {
  const [modelId, setModelId] = useState("");
  const [label, setLabel] = useState("");
  const [years, setYears] = useState(1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const selected = modelId || models[0]?.id || "";

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onLaunch({
        model_id: selected,
        label: label || undefined,
        // Écart aux valeurs par défaut du launcher, au format gama-server.
        parameters: [{ type: "int", name: "nbAnneesSimulation", value: Number(years) }],
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Field label="Modèle">
        <select value={selected} onChange={(e) => setModelId(e.target.value)}>
          {models.map((model) => (
            <option key={model.id} value={model.id}>{model.name}</option>
          ))}
        </select>
      </Field>

      <Field label="Libellé (optionnel)">
        <input value={label} onChange={(e) => setLabel(e.target.value)}
               placeholder="Run de validation" />
      </Field>

      <Field label="Nombre d'années simulées">
        <input type="number" min="1" max="10" value={years}
               onChange={(e) => setYears(e.target.value)} />
      </Field>

      <p>
        <button disabled={busy || !selected}>{busy ? "Lancement…" : "Lancer"}</button>{" "}
        {onCancel && (
          <button type="button" className="ghost" onClick={onCancel} disabled={busy}>
            Annuler
          </button>
        )}
      </p>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
