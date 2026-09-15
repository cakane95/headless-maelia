import { Link } from "react-router";

import { projectApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import ProgressBar from "../../../components/ProgressBar";
import { useAsync } from "../../../hooks/useAsync";

/** Où en sont les données du projet, en trois chiffres.
 *
 *  Le détail fichier par fichier vit dans « Données d'entrée » : ici on ne dit
 *  que ce qui décide de la suite — reste-t-il quelque chose à charger ?
 */
export default function DataSummary({ projectId }) {
  const { data, error, loading } = useAsync(
    () => projectApi.completion(projectId),
    [projectId],
  );

  return (
    <AsyncBoundary error={error} loading={loading}>
      {data && (
        <>
          <ProgressBar ratio={data.ratio} label="Entrées obligatoires" />
          <p className="muted">
            {data.supplied} fichier(s) obligatoire(s) valide(s) sur {data.expected}.{" "}
            <Link to={`/simulation/projets/${projectId}/donnees`}>Voir le détail</Link>
          </p>
        </>
      )}
    </AsyncBoundary>
  );
}
