import { formatBytes, formatDuration } from "../../../utils/format";

const KINDS = { TABLE: "Tableaux", TEXT: "Texte", BINARY: "Autres fichiers" };

/** Ce qu'on regarde : quelles exécutions, quel fichier.
 *
 *  En barre plutôt qu'en tableaux : le graphique doit rester à l'écran pendant
 *  qu'on change de fichier ou qu'on ajoute un run à la comparaison.
 */
export default function ResultsToolbar({ runs, selectedIds, onToggleRun, files, fileName, onFile }) {
  const groups = Object.keys(KINDS).filter((kind) => files.some((f) => f.kind === kind));

  return (
    <div className="toolbar">
      <div className="toolbar__group">
        <span className="toolbar__label">
          Exécutions
          {selectedIds.length > 1 && <em> — {selectedIds.length} superposées</em>}
        </span>
        <div className="chips">
          {runs.map((run) => (
            <button
              key={run.id}
              type="button"
              className={selectedIds.includes(run.id) ? "chip chip--active" : "chip"}
              aria-pressed={selectedIds.includes(run.id)}
              title={`${run.current_date ?? "—"} · ${formatDuration(run)}`}
              onClick={() => onToggleRun(run.id)}
            >
              {run.label}
            </button>
          ))}
        </div>
        <span className="toolbar__hint">Cochez-en plusieurs pour les comparer.</span>
      </div>

      <div className="toolbar__group toolbar__group--tight">
        <span className="toolbar__label" id="fichier-sortie">Fichier</span>
        <select
          aria-labelledby="fichier-sortie"
          value={fileName ?? ""}
          onChange={(event) => onFile(event.target.value)}
        >
          {groups.map((kind) => (
            <optgroup key={kind} label={KINDS[kind]}>
              {files
                .filter((f) => f.kind === kind)
                .map((f) => (
                  <option key={f.name} value={f.name}>
                    {f.name} — {formatBytes(f.size)}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </div>
    </div>
  );
}
