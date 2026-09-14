import { useState } from "react";

import { projectApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import Field from "../../../components/Field";
import { useAsync } from "../../../hooks/useAsync";

/** Création d'un projet. Le territoire vient du volume partagé, pas d'une saisie. */
export default function ProjectForm({ onSubmit, onCancel }) {
  const { data: territories, error, loading } = useAsync(projectApi.territories);
  const [name, setName] = useState("");
  const [territory, setTerritory] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState(null);

  const selected = territory || territories?.[0] || "";

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setFailure(null);
    try {
      await onSubmit({ name, territory: selected, description: description || undefined });
      setName("");
      setDescription("");
    } catch (err) {
      setFailure(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <AsyncBoundary error={error} loading={loading}>
      <form onSubmit={submit}>
        <Field label="Nom">
          <input value={name} onChange={(e) => setName(e.target.value)}
                 placeholder="Bassin de la Garonne" required />
        </Field>

        <Field label="Territoire" hint="Jeux de données livrés avec le modèle.">
          <select value={selected} onChange={(e) => setTerritory(e.target.value)}>
            {territories?.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </Field>

        <Field label="Description (optionnelle)">
          <input value={description} onChange={(e) => setDescription(e.target.value)} />
        </Field>

        <p>
          <button disabled={busy || !name || !selected}>
            {busy ? "Création…" : "Créer le projet"}
          </button>{" "}
          {onCancel && (
            <button type="button" className="ghost" onClick={onCancel} disabled={busy}>
              Annuler
            </button>
          )}
        </p>
        {failure && <p className="error">{failure}</p>}
      </form>
    </AsyncBoundary>
  );
}
