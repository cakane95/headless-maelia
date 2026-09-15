import { useState } from "react";

import Modal from "../../../components/Modal";
import { resultApi } from "../../../api";

/** Enregistrer le graphique courant sous un nom.
 *
 *  La lecture appartient au **projet**, pas à l'exécution sur laquelle elle a
 *  été construite : une figure de rapport est faite pour être redessinée sur la
 *  simulation suivante.
 */
export default function SaveView({ projectId, fileName, chart, query, suggestedName, onSaved }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await resultApi.saveView(projectId, { name: name.trim(), file_name: fileName, chart, query });
      setOpen(false);
      onSaved?.();
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <button
        type="button"
        className="ghost"
        onClick={() => {
          setName(suggestedName ?? "");
          setOpen(true);
        }}
      >
        Enregistrer
      </button>

      {open && (
        <Modal title="Enregistrer cette lecture" onClose={() => setOpen(false)}>
          <form onSubmit={submit}>
            <p className="muted muted--first">
              Elle pourra être rejouée sur n'importe quelle exécution de ce projet.
            </p>
            <label>
              <span>Nom</span>
              <input
                value={name}
                onChange={(event) => setName(event.target.value)}
                placeholder="Rendement par année"
                autoFocus
                required
              />
              <small className="hint">Un nom déjà utilisé remplace la lecture existante.</small>
            </label>
            <p className="form-actions">
              <button disabled={busy || !name.trim()}>
                {busy ? "Enregistrement…" : "Enregistrer"}
              </button>
              <button type="button" className="ghost" onClick={() => setOpen(false)}>
                Annuler
              </button>
            </p>
            {error && <p className="error">{error}</p>}
          </form>
        </Modal>
      )}
    </>
  );
}
