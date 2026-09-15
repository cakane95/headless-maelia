import { formatBytes } from "../../../utils/format";

const KINDS = { TABLE: "Tableaux", TEXT: "Texte", BINARY: "Autres fichiers" };

/** Ce qu'on regarde : quel fichier de sortie, et avec quoi le comparer.
 *
 *  Collée sous le bandeau, et réduite au strict nécessaire : l'exécution est
 *  déjà choisie — on est entré par elle — donc tout l'espace restant va au
 *  graphique.
 */
export default function ResultsToolbar({ files, fileName, onFile, comparison }) {
  const groups = Object.keys(KINDS).filter((kind) => files.some((f) => f.kind === kind));

  return (
    <div className="toolbar toolbar--slim">
      <div className="toolbar__group toolbar__group--tight">
        <span className="toolbar__label" id="fichier-sortie">Fichier de sortie</span>
        <select
          aria-labelledby="fichier-sortie"
          value={fileName ?? ""}
          onChange={(event) => onFile(event.target.value)}
        >
          {groups.map((kind) => (
            <optgroup key={kind} label={KINDS[kind]}>
              {files
                .filter((file) => file.kind === kind)
                .map((file) => (
                  <option key={file.name} value={file.name}>
                    {file.name} — {formatBytes(file.size)}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </div>

      {comparison && <div className="toolbar__aside">{comparison}</div>}
    </div>
  );
}
