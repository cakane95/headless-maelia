import { useState } from "react";

/** Formulaire de lancement. Ne connaît ni le réseau ni la navigation : il remonte
 *  la demande à la page, qui décide quoi en faire. */
export default function LaunchForm({ models, onLaunch }) {
  const [modelId, setModelId] = useState("");
  const [label, setLabel] = useState("");
  const [annees, setAnnees] = useState(1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const modeleCourant = modelId || models[0]?.id || "";

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onLaunch({
        model_id: modeleCourant,
        label: label || undefined,
        // Écart aux valeurs par défaut du launcher, au format gama-server.
        parameters: [{ type: "int", name: "nbAnneesSimulation", value: Number(annees) }],
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <label>
        <span>Modèle</span>
        <select value={modeleCourant} onChange={(e) => setModelId(e.target.value)}>
          {models.map((model) => (
            <option key={model.id} value={model.id}>
              {model.name}
            </option>
          ))}
        </select>
      </label>

      <label>
        <span>Libellé (optionnel)</span>
        <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Run de validation" />
      </label>

      <label>
        <span>Nombre d'années simulées</span>
        <input type="number" min="1" max="10" value={annees} onChange={(e) => setAnnees(e.target.value)} />
      </label>

      <button disabled={busy || !modeleCourant}>{busy ? "Lancement…" : "Lancer"}</button>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
