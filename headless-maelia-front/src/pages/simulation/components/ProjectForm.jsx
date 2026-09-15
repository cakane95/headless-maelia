import { useState } from "react";

import Field from "../../../components/Field";

/** Création d'un projet : un nom, et c'est tout ce qui est demandé.
 *
 *  Le territoire n'apparaît plus : le projet démarre sur le jeu de référence et
 *  ses propres fichiers viennent s'y superposer. En faire un choix à la
 *  création revenait à demander une décision avant d'avoir de quoi la prendre.
 */
export default function ProjectForm({ onSubmit, onCancel }) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setFailure(null);
    try {
      await onSubmit({ name, description: description || undefined });
    } catch (error) {
      setFailure(error.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit}>
      <Field label="Nom">
        <input
          value={name}
          onChange={(event) => setName(event.target.value)}
          placeholder="Bassin de la Garonne"
          autoFocus
          required
        />
      </Field>

      <Field
        label="Description (optionnelle)"
        hint="Ce que ce projet cherche à étudier."
      >
        <input value={description} onChange={(event) => setDescription(event.target.value)} />
      </Field>

      <p className="form-actions">
        <button disabled={busy || !name}>
          {busy ? "Création…" : "Créer le projet"}
        </button>
        {onCancel && (
          <button type="button" className="ghost" onClick={onCancel} disabled={busy}>
            Annuler
          </button>
        )}
      </p>
      {failure && <p className="error">{failure}</p>}
    </form>
  );
}
