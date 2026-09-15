import { useState } from "react";

import Card from "../../../components/Card";
import Field from "../../../components/Field";
import FieldSpecEditor from "./FieldSpecEditor";

const KINDS = ["CSV", "SHAPEFILE", "IMAGE", "TEXT"];
const ORIENTATIONS = [
  ["FIELDS_AS_COLUMNS", "Champs en colonnes (habituel)"],
  ["FIELDS_AS_ROWS", "Champs en lignes (transposé)"],
];

const EMPTY = {
  label: "", module: "modeleAgricole", kind: "CSV", relative_dir: "",
  file_name: "", file_name_pattern: "", orientation: "FIELDS_AS_COLUMNS",
  delimiter: ";", has_header: true, matrix_value_start_index: null,
  required: true, required_if: "", depends_on: [], fields: [],
};

/** Décrire un type de fichier d'entrée : où il est, comment il se lit, ce
 *  qu'il contient. La validation fait autorité côté backend — ici on saisit. */
export default function DataSpecForm({ spec, onSubmit, onCancel }) {
  const [draft, setDraft] = useState({ ...EMPTY, ...(spec ?? {}) });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const set = (key, value) => setDraft((current) => ({ ...current, [key]: value }));
  const tabular = draft.kind === "CSV" || draft.kind === "TEXT";

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({
        ...draft,
        // Nom et motif sont exclusifs : le backend le refuse, autant ne pas
        // envoyer la chaîne vide que le formulaire laisse derrière lui.
        file_name: draft.file_name || null,
        file_name_pattern: draft.file_name_pattern || null,
        required_if: draft.required_if || null,
        orientation: tabular ? draft.orientation : null,
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
        <Field label="Libellé">
          <input value={draft.label} onChange={(e) => set("label", e.target.value)} required />
        </Field>
        <Field label="Module" hint="Le dossier de premier niveau sous includes/.">
          <input value={draft.module} onChange={(e) => set("module", e.target.value)} required />
        </Field>
        <Field label="Nature">
          <select value={draft.kind} onChange={(e) => set("kind", e.target.value)}>
            {KINDS.map((kind) => <option key={kind} value={kind}>{kind}</option>)}
          </select>
        </Field>
      </Card>

      <Card title="Emplacement">
        <Field label="Répertoire" hint="Chemin relatif au territoire, sans barre initiale.">
          <input value={draft.relative_dir} onChange={(e) => set("relative_dir", e.target.value)}
                 placeholder="modeleAgricole/culture" required />
        </Field>
        <Field label="Nom du fichier" hint="Laisser vide pour une famille de fichiers.">
          <input value={draft.file_name ?? ""} onChange={(e) => set("file_name", e.target.value)} />
        </Field>
        <Field label="Motif" hint="Expression régulière, pour une famille : prixVentes.+\.csv">
          <input value={draft.file_name_pattern ?? ""}
                 onChange={(e) => set("file_name_pattern", e.target.value)} />
        </Field>
      </Card>

      {tabular && (
        <Card title="Lecture">
          <Field label="Orientation">
            <select value={draft.orientation ?? "FIELDS_AS_COLUMNS"}
                    onChange={(e) => set("orientation", e.target.value)}>
              {ORIENTATIONS.map(([value, text]) => (
                <option key={value} value={value}>{text}</option>
              ))}
            </select>
          </Field>
          <Field label="Séparateur">
            <input value={draft.delimiter} onChange={(e) => set("delimiter", e.target.value)} />
          </Field>
          <Field
            label="Colonnes méta avant les valeurs"
            hint="Fichier transposé seulement : nombre de colonnes entre le nom du champ et la première valeur."
          >
            <input type="number" min="0" value={draft.matrix_value_start_index ?? ""}
                   onChange={(e) =>
                     set("matrix_value_start_index",
                         e.target.value === "" ? null : Number(e.target.value))} />
          </Field>
        </Card>
      )}

      <Card title="Applicabilité">
        <Field
          label="Condition"
          hint="Vide : toujours attendu. Forme « param == valeur », plusieurs conditions liées par &&."
        >
          <input value={draft.required_if ?? ""}
                 onChange={(e) => set("required_if", e.target.value)}
                 placeholder="executerModeleHydrographique == true" />
        </Field>
        <Field label="Dépend de" hint="Identifiants d'autres fichiers, séparés par des virgules.">
          <input
            value={(draft.depends_on ?? []).join(", ")}
            onChange={(e) =>
              set("depends_on", e.target.value.split(",").map((v) => v.trim()).filter(Boolean))}
          />
        </Field>
      </Card>

      <Card title={`Champs (${(draft.fields ?? []).length})`}>
        <FieldSpecEditor fields={draft.fields ?? []} onChange={(fields) => set("fields", fields)} />
      </Card>

      <div className="form-actions form-actions--sticky">
        <button disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>
        <button type="button" className="ghost" onClick={onCancel} disabled={busy}>Annuler</button>
        {error && <span className="error">{error}</span>}
      </div>
    </form>
  );
}
