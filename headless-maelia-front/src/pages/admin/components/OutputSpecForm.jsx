import { Fragment, useState } from "react";

import Card from "../../../components/Card";
import Field from "../../../components/Field";
import TagInput from "../../simulation/components/TagInput";
import { granularityLabel } from "../../../utils/outputs";

/** Décrire une sortie : ce qu'elle écrit, et ce qui la déclenche.
 *
 *  La validation fait autorité côté backend — un fichier sans extension, une
 *  condition illisible y sont refusés.
 */
export default function OutputSpecForm({ spec, parameters, onSubmit, onCancel }) {
  const [draft, setDraft] = useState(spec);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const set = (key, value) => setDraft((current) => ({ ...current, [key]: value }));
  const booleens = parameters.filter((p) => p.type === "BOOL");

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({
        label: draft.label,
        theme: draft.theme,
        description: draft.description || null,
        flag: draft.flag || null,
        files: draft.files,
        produced_if: draft.produced_if || null,
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
        <Field label="Libellé" hint="Tel qu'il apparaît dans les écrans de résultats.">
          <input value={draft.label} onChange={(e) => set("label", e.target.value)} required />
        </Field>
        <Field label="Thème" hint="Le regroupement déclaré par le modèle.">
          <input value={draft.theme} onChange={(e) => set("theme", e.target.value)} required />
        </Field>
        <Field label="Description" hint="Ce que le fichier contient, en une phrase.">
          <textarea
            rows={2}
            value={draft.description ?? ""}
            onChange={(e) => set("description", e.target.value)}
          />
        </Field>
      </Card>

      <Card
        title="Fichiers produits"
        lede="Les noms que le modèle écrit dans le dossier de sortie du run."
      >
        <TagInput
          values={draft.files.map((f) => f.name)}
          placeholder="sorties_eau.csv"
          onChange={(noms) =>
            set(
              "files",
              noms.map((name) => ({
                name,
                granularity:
                  draft.files.find((f) => f.name === name)?.granularity ?? "UNKNOWN",
              })),
            )
          }
        />
        {draft.files.length > 0 && (
          <dl className="facts">
            {draft.files.map((f) => (
              <Fragment key={f.name}>
                <dt>{f.name}</dt>
                <dd>{granularityLabel(f.granularity)}</dd>
              </Fragment>
            ))}
          </dl>
        )}
      </Card>

      <Card
        title="Condition de production"
        lede="Le modèle n'écrit rien par défaut : c'est cette condition qui décide."
      >
        <Field label="Interrupteur" hint="Le paramètre qui commande cette sortie.">
          <select value={draft.flag ?? ""} onChange={(e) => set("flag", e.target.value)}>
            <option value="">Aucun — écrite sans drapeau dédié</option>
            {booleens.map((p) => (
              <option key={p.name} value={p.name}>
                {p.name}
              </option>
            ))}
            {draft.flag && !booleens.some((p) => p.name === draft.flag) && (
              <option value={draft.flag}>{draft.flag} (absent du launcher)</option>
            )}
          </select>
        </Field>
        <Field
          label="Produite si"
          hint="« paramètre == valeur », liées par && (et) ou || (ou). Sans parenthèses."
        >
          <input
            value={draft.produced_if ?? ""}
            placeholder="Toujours produite"
            onChange={(e) => set("produced_if", e.target.value)}
          />
        </Field>
        {spec.guard_source && (
          <Field
            label="Garde du modèle"
            hint="Le texte GAML dont la condition est traduite. Non modifiable : c'est la trace qui permet de la vérifier."
          >
            <code className="guard">{spec.guard_source}</code>
          </Field>
        )}
      </Card>

      <div className="form-actions form-actions--sticky">
        <button disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>
        <button type="button" className="ghost" onClick={onCancel} disabled={busy}>
          Annuler
        </button>
        {error && <span className="error">{error}</span>}
      </div>
    </form>
  );
}
