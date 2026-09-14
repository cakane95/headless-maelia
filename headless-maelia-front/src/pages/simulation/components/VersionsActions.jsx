import { Link } from "react-router";

/** Actions disponibles sur un fichier d'entrée. */
export default function VersionsActions({ projectId, datasetId, tabular }) {
  if (!tabular) {
    return (
      <p className="muted">
        Fichier binaire : une nouvelle version se crée par téléversement, pas par édition.
      </p>
    );
  }
  return (
    <p>
      <Link className="button-link" to={`/simulation/projets/${projectId}/donnees/${datasetId}/edition`}>
        Modifier le contenu
      </Link>
    </p>
  );
}
