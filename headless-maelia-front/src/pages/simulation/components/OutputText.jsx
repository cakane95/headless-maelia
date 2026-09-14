import { resultApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import Card from "../../../components/Card";
import { useAsync } from "../../../hooks/useAsync";

/** Fichier de sortie non tabulaire : paramètres de la simulation, durée.
 *  Il se lit tel quel — le mettre en forme en inventerait la structure. */
export default function OutputText({ runId, fileName }) {
  const { data, error, loading } = useAsync(
    () => resultApi.text(runId, fileName),
    [runId, fileName],
  );

  return (
    <Card title={fileName}>
      <AsyncBoundary error={error} loading={loading}>
        <pre className="console console--plain">{data?.content}</pre>
      </AsyncBoundary>
      <p>
        <a href={resultApi.downloadUrl(runId, fileName)} download>Télécharger le fichier</a>
      </p>
    </Card>
  );
}
