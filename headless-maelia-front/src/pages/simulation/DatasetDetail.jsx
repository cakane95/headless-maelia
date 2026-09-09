import { Link, useParams } from "react-router";

import { datasetApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import VersionsTable from "./components/VersionsTable";

/** Historique des versions d'un fichier d'entrée. */
export default function DatasetDetail() {
  const { projectId, datasetId } = useParams();
  const { data: dataset, error, loading } = useAsync(
    () => datasetApi.get(datasetId), [datasetId],
  );

  return (
    <AsyncBoundary error={error} loading={loading}>
      {dataset && (
        <>
          <p className="muted">
            <Link to={`/simulation/projets/${projectId}/donnees`}>← Données d'entrée</Link>
          </p>
          <PageHeader
            title={dataset.instance_key ?? dataset.data_spec_id}
            lede={`${dataset.versions.length} version(s) — la dernière valide sert de défaut aux scénarios.`}
          />

          <Card title="Versions">
            <VersionsTable
              versions={dataset.versions}
              currentVersionId={dataset.current_version_id}
            />
          </Card>
        </>
      )}
    </AsyncBoundary>
  );
}
