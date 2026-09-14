import EmptyState from "./EmptyState";
import { formatBytes } from "../utils/format";

/** Fichiers produits par une exécution. Purement présentationnel. */
export default function ArtifactsTable({ artifacts = [], outputDir }) {
  if (artifacts.length === 0) {
    return <EmptyState>Aucun fichier de sortie.</EmptyState>;
  }

  return (
    <>
      {outputDir && (
        <p className="muted muted--first">
          <code>{outputDir}</code>
        </p>
      )}
      <table>
        <thead>
          <tr>
            <th>Fichier</th>
            <th>Taille</th>
          </tr>
        </thead>
        <tbody>
          {artifacts.map((artifact) => (
            <tr key={artifact.path ?? artifact.name}>
              <td><code>{artifact.name}</code></td>
              <td className="muted">{formatBytes(artifact.size)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
