import EmptyState from "../../../components/EmptyState";
import { formatBytes } from "../../../utils/format";

const KINDS = { TABLE: "Tableau", TEXT: "Texte", BINARY: "Binaire" };

/** Fichiers produits par un run. Seuls les tableaux se tracent — les autres se
 *  lisent ou se téléchargent, et le dire évite de cliquer pour rien. */
export default function OutputFiles({ files, selected, onSelect }) {
  if (files.length === 0) {
    return <EmptyState>Ce run n'a produit aucun fichier.</EmptyState>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>Nature</th>
          <th>Taille</th>
        </tr>
      </thead>
      <tbody>
        {files.map((file) => (
          <tr
            key={file.name}
            className={file.name === selected ? "clickable selected" : "clickable"}
            onClick={() => onSelect(file.name)}
          >
            <td><code>{file.name}</code></td>
            <td className="muted">{KINDS[file.kind] ?? file.kind}</td>
            <td className="muted">{formatBytes(file.size)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
