import { useState } from "react";

import Field from "../../../components/Field";
import PinEditor from "./PinEditor";

/** Écarts de paramètres et versions épinglées d'un scénario.
 *
 *  `scenario` absent : création. Présent : modification de ce scénario.
 */
export default function ScenarioForm({ datasets, scenario, onSubmit, onCancel }) {
  const [name, setName] = useState(scenario?.name ?? "");
  const [years, setYears] = useState(scenario?.parameter_values?.nbAnneesSimulation ?? 1);
  const [pins, setPins] = useState(scenario?.dataset_pins ?? {});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      // Seuls les écarts voyagent : un paramètre non fourni garde le défaut du
      // launcher, ce qui rend le scénario robuste aux montées de version.
      await onSubmit({
        name,
        parameter_values: { nbAnneesSimulation: Number(years) },
        dataset_pins: pins,
      });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Field label="Nom">
        <input value={name} onChange={(e) => setName(e.target.value)}
               placeholder="ITK bas intrants" required />
      </Field>

      <Field label="Nombre d'années simulées">
        <input type="number" min="1" max="10" value={years}
               onChange={(e) => setYears(e.target.value)} />
      </Field>

      <p className="muted">Versions de données</p>
      <PinEditor datasets={datasets} pins={pins} onChange={setPins} />

      <p>
        <button disabled={busy || !name}>
          {busy ? "Enregistrement…" : scenario ? "Enregistrer" : "Créer le scénario"}
        </button>{" "}
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
