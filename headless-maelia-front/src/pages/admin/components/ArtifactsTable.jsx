import { formatBytes } from "../../../utils/format";

/** Fichiers produits par une exécution. */
export default function ArtifactsTable({ artifacts, outputDir }) {
  return (
    <>
      <p className="muted muted--first">
        <code>{outputDir}</code>
      </p>
      <table>
        <thead>
          <tr>
            <th>Fichier</th>
            <th>Taille</th>
          </tr>
        </thead>
        <tbody>
          {artifacts.map((artifact) => (
            <tr key={artifact.name}>
              <td>{artifact.name}</td>
              <td className="muted">{formatBytes(artifact.size)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}
