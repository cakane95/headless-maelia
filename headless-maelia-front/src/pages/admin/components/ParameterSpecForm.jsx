import { useState } from "react";

import Card from "../../../components/Card";
import Field from "../../../components/Field";
import ParameterValueFields from "./ParameterValueFields";

/** Décrire un paramètre : ce qu'il vaut, ce qu'il accepte, ce qui le commande.
 *
 *  La validation fait autorité côté backend — un défaut que son propre type
 *  refuse, une condition illisible ou circulaire sont rejetés là-bas.
 */
export default function ParameterSpecForm({ spec, parameters, onSubmit, onCancel }) {
  const [draft, setDraft] = useState(spec);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const set = (key, value) => setDraft((current) => ({ ...current, [key]: value }));
  const booleens = parameters.filter((p) => p.type === "BOOL" && p.name !== spec.name);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({
        label: draft.label,
        group: draft.group,
        type: draft.type,
        default: draft.default,
        allowed_values: draft.allowed_values ?? [],
        editable: draft.editable,
        options_from: draft.options_from || null,
        enabled_if: draft.enabled_if || null,
      });
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Card title="Identité">
        <Field label="Libellé" hint="Tel qu'il apparaît dans l'éditeur de scénario.">
          <input value={draft.label} onChange={(e) => set("label", e.target.value)} required />
        </Field>
        <Field label="Section" hint="La section du launcher qui le regroupe.">
          <input value={draft.group} onChange={(e) => set("group", e.target.value)} required />
        </Field>
      </Card>

      <ParameterValueFields draft={draft} set={set} />

      <Card title="Dépendance">
        <Field
          label="Actif seulement si"
          hint="Le paramètre est grisé tant que la condition est fausse : le fixer n'aurait aucun effet."
        >
          <select
            value={draft.enabled_if ?? ""}
            onChange={(e) => set("enabled_if", e.target.value)}
          >
            <option value="">Toujours actif</option>
            {booleens.map((p) => (
              <option key={p.name} value={`${p.name} == true`}>
                {p.name} est activé
              </option>
            ))}
            {draft.enabled_if && !booleens.some((p) => `${p.name} == true` === draft.enabled_if) && (
              <option value={draft.enabled_if}>{draft.enabled_if}</option>
            )}
          </select>
        </Field>
      </Card>

      <div className="form-actions form-actions--sticky">
        <button disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>
        <button type="button" className="ghost" onClick={onCancel} disabled={busy}>Annuler</button>
        {error && <span className="error">{error}</span>}
      </div>
    </form>
  );
}
