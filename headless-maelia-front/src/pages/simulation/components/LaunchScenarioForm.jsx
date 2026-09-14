import { useState } from "react";

import EmptyState from "../../../components/EmptyState";
import Field from "../../../components/Field";

/** Choix du scénario à exécuter. Le reste — paramètres, versions de données —
 *  est déjà porté par le scénario : le lancement ne rouvre pas ces décisions. */
export default function LaunchScenarioForm({ scenarios, onLaunch, onCancel }) {
  const [scenarioId, setScenarioId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const selected = scenarioId || scenarios[0]?.id || "";

  if (scenarios.length === 0) {
    return <EmptyState>Créez d'abord un scénario : il porte les paramètres du run.</EmptyState>;
  }

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onLaunch({ scenario_id: selected });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Field label="Scénario">
        <select value={selected} onChange={(e) => setScenarioId(e.target.value)}>
          {scenarios.map((scenario) => (
            <option key={scenario.id} value={scenario.id}>{scenario.name}</option>
          ))}
        </select>
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
