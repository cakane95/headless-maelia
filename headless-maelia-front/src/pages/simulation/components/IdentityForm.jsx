import { useState } from "react";

import { projectApi } from "../../../api";
import Field from "../../../components/Field";

/** Nom et description d'un projet — les deux seules choses qu'il porte en
 *  propre. Les données viennent des téléversements, la configuration a son
 *  bloc, le reste n'est pas une décision de l'utilisateur. */
export default function IdentityForm({ project, onSaved, onCancel }) {
  const [name, setName] = useState(project.name);
  const [description, setDescription] = useState(project.description ?? "");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await projectApi.update(project.id, { name, description });
      onSaved();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Field label="Nom">
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </Field>
      <Field label="Description">
        <input value={description} onChange={(e) => setDescription(e.target.value)} />
      </Field>
      <p>
        <button disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>{" "}
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
