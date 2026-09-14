import { Link, useParams } from "react-router";

import { catalogApi, datasetApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import VersionsActions from "./components/VersionsActions";
import VersionsTable from "./components/VersionsTable";

/** Historique des versions d'un fichier d'entrée.
 *
 *  La nature du fichier (tabulaire ou binaire) vient du catalogue, pas du
 *  dataset : c'est le catalogue qui décrit ce que le modèle attend.
 */
export default function DatasetDetail() {
  const { projectId, datasetId } = useParams();
  const dataset = useAsync(() => datasetApi.get(datasetId), [datasetId]);
  const spec = useAsync(
    () => (dataset.data ? catalogApi.dataspec(dataset.data.data_spec_id) : Promise.resolve(null)),
    [dataset.data?.data_spec_id],
  );

  const tabular = spec.data?.kind === "CSV";

  return (
    <AsyncBoundary
      error={dataset.error || spec.error}
      loading={dataset.loading || spec.loading}
    >
      {dataset.data && spec.data && (
        <>
          <p className="muted">
            <Link to={`/simulation/projets/${projectId}/donnees`}>← Données d'entrée</Link>
          </p>
          <PageHeader
            title={dataset.data.instance_key ?? spec.data.label}
            lede={`${spec.data.relative_dir} — ${dataset.data.versions.length} version(s). La dernière valide sert de défaut aux scénarios.`}
          />

          <Card title="Actions">
            <VersionsActions
              projectId={projectId}
              datasetId={datasetId}
              tabular={tabular}
            />
          </Card>

          <Card title="Versions">
            <VersionsTable
              versions={dataset.data.versions}
              currentVersionId={dataset.data.current_version_id}
            />
          </Card>
        </>
      )}
    </AsyncBoundary>
  );
}
