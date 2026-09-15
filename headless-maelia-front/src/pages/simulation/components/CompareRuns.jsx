import { useState } from "react";

import Modal from "../../../components/Modal";
import { formatDuration } from "../../../utils/format";

/** Superposer d'autres exécutions au graphique courant.
 *
 *  C'est la lecture qui donne son sens au gel des versions — comparer deux
 *  scénarios — mais ce n'est pas le geste de départ : on arrive ici pour lire
 *  UNE exécution. D'où un bouton, et non une liste posée en haut de l'écran.
 */
export default function CompareRuns({ runs, selected, onChange }) {
  const [open, setOpen] = useState(false);
  const [picked, setPicked] = useState(selected);

  if (runs.length === 0) return null;

  function toggle(id) {
    setPicked(picked.includes(id) ? picked.filter((run) => run !== id) : [...picked, id]);
  }

  function confirm() {
    onChange(picked);
    setOpen(false);
  }

  return (
    <>
      <button
        type="button"
        className={selected.length > 0 ? "ghost ghost--on" : "ghost"}
        onClick={() => {
          setPicked(selected);
          setOpen(true);
        }}
      >
        {selected.length > 0 ? `Comparé à ${selected.length}` : "Comparer"}
      </button>

      {open && (
        <Modal title="Comparer avec d'autres exécutions" onClose={() => setOpen(false)}>
          <p className="muted muted--first">
            La même configuration de graphique est rejouée sur chacune, et superposée.
          </p>

          <ul className="options">
            {runs.map((run) => (
              <li key={run.id}>
                <label className="switch">
                  <input
                    type="checkbox"
                    checked={picked.includes(run.id)}
                    onChange={() => toggle(run.id)}
                  />
                  <span>
                    {run.label}
                    <em className="row__note">
                      {run.current_date ?? "—"} · {formatDuration(run)}
                    </em>
                  </span>
                </label>
              </li>
            ))}
          </ul>

          <p className="form-actions">
            <button type="button" onClick={confirm}>Appliquer</button>
            <button type="button" className="ghost" onClick={() => setOpen(false)}>
              Annuler
            </button>
          </p>
        </Modal>
      )}
    </>
  );
}
