import { useState } from "react";

import Card from "../../../components/Card";
import Field from "../../../components/Field";
import ParameterEditor from "./ParameterEditor";

/** Un scénario : une identité, et des écarts aux valeurs par défaut du modèle.
 *
 *  `scenario` absent : création. Présent : modification de ce scénario.
 */
export default function ScenarioForm({ specs, scenario, onSubmit, onCancel }) {
  const [name, setName] = useState(scenario?.name ?? "");
  const [description, setDescription] = useState(scenario?.description ?? "");
  const [values, setValues] = useState(scenario?.parameter_values ?? {});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({ name, description: description || null, parameter_values: values });
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Card title="Identité">
        <Field label="Nom">
          <input
            value={name}
            onChange={(event) => setName(event.target.value)}
            placeholder="Rotation bas intrants"
            required
          />
        </Field>
        <Field label="Description (optionnelle)" hint="Ce que ce scénario cherche à montrer.">
          <input value={description} onChange={(event) => setDescription(event.target.value)} />
        </Field>
      </Card>

      <Card title="Paramètres du modèle">
        <ParameterEditor specs={specs} values={values} onChange={setValues} />
      </Card>

      <div className="form-actions form-actions--sticky">
        <button disabled={busy || !name}>
          {busy ? "Enregistrement…" : scenario ? "Enregistrer" : "Créer le scénario"}
        </button>{" "}
        {onCancel && (
          <button type="button" className="ghost" onClick={onCancel} disabled={busy}>
            Annuler
          </button>
        )}
        {error && <span className="error">{error}</span>}
      </div>
    </form>
  );
}
