import { useState } from "react";

import { useExpectedFiles } from "../../../hooks/useExpectedFiles";
import ModuleToggle from "./ModuleToggle";
import { CHOICES, MODULES } from "./modelingModules";

/** Réglages qui déterminent quels fichiers d'entrée sont attendus.
 *
 *  On n'expose que les leviers d'activation : ce sont eux qui font varier la
 *  liste des fichiers. Les 142 paramètres du launcher relèvent du scénario, pas
 *  de la configuration du projet.
 */
export default function ModelingConfigForm({ config, onSubmit }) {
  const [draft, setDraft] = useState(config ?? {});
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const expected = useExpectedFiles(draft);

  const dirty = JSON.stringify(draft) !== JSON.stringify(config ?? {});

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit(draft);
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  const set = (key, value) => setDraft((current) => ({ ...current, [key]: value }));

  return (
    <form onSubmit={submit}>
      <div className="modules">
        {MODULES.map(([key, label, description]) => (
          <ModuleToggle
            key={key}
            label={label}
            description={description}
            checked={Boolean(draft[key])}
            onChange={(value) => set(key, value)}
          />
        ))}
      </div>

      <div className="choices">
        {CHOICES.filter(([, , , requires]) => draft[requires]).map(([key, label, options]) => (
          <label key={key}>
            <span>{label}</span>
            <select value={draft[key] ?? options[0]} onChange={(e) => set(key, e.target.value)}>
              {options.map((option) => <option key={option} value={option}>{option}</option>)}
            </select>
          </label>
        ))}
      </div>

      <p className="setup__consequence">
        {expected === null
          ? "Calcul des fichiers attendus…"
          : <>Cette configuration attend <b>{expected}</b> fichiers d'entrée.</>}
      </p>

      <p className="form-actions">
        <button disabled={busy || !dirty}>
          {busy ? "Enregistrement…" : dirty ? "Enregistrer la configuration" : "Configuration à jour"}
        </button>
      </p>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
