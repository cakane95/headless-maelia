import { useState } from "react";

import Field from "../../../components/Field";
import PinEditor from "./PinEditor";

/** Création d'un scénario : écarts de paramètres et versions épinglées. */
export default function ScenarioForm({ datasets, onSubmit }) {
  const [name, setName] = useState("");
  const [years, setYears] = useState(1);
  const [pins, setPins] = useState({});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({
        name,
        // Seuls les écarts voyagent : un paramètre non fourni garde le défaut
        // du launcher, ce qui rend le scénario robuste aux montées de version.
        parameter_values: { nbAnneesSimulation: Number(years) },
        dataset_pins: pins,
      });
      setName("");
      setPins({});
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
        <button disabled={busy || !name}>{busy ? "Création…" : "Créer le scénario"}</button>
      </p>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
