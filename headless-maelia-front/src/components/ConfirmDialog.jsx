import { useState } from "react";

import Modal from "./Modal";

/** Confirmation d'une action irréversible.
 *
 *  L'action reste à l'écran pendant qu'elle s'exécute : fermer la fenêtre avant
 *  la réponse du serveur laisserait l'utilisateur sans savoir ce qui s'est passé.
 */
export default function ConfirmDialog({
  title,
  message,
  confirmLabel = "Supprimer",
  onConfirm,
  onClose,
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function run() {
    setBusy(true);
    setError(null);
    try {
      await onConfirm();
      onClose();
    } catch (failure) {
      setError(failure.message);
      setBusy(false);
    }
  }

  return (
    <Modal title={title} onClose={onClose}>
      <p>{message}</p>
      <p>
        <button type="button" className="danger" onClick={run} disabled={busy}>
          {busy ? "En cours…" : confirmLabel}
        </button>{" "}
        <button type="button" className="ghost" onClick={onClose} disabled={busy}>
          Annuler
        </button>
      </p>
      {error && <p className="error">{error}</p>}
    </Modal>
  );
}
