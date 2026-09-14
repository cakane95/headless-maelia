import { Link, useParams } from "react-router";

import { catalogApi, datasetApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import { useDraft } from "../../hooks/useDraft";
import DatasetGrid from "./components/DatasetGrid";
import PublishCard from "./components/PublishCard";

/** Édition d'un fichier d'entrée, puis publication en nouvelle version. */
export default function DatasetEdit() {
  const { projectId, datasetId } = useParams();
  const dataset = useAsync(() => datasetApi.get(datasetId), [datasetId]);
  const spec = useAsync(
    () => (dataset.data ? catalogApi.dataspec(dataset.data.data_spec_id) : Promise.resolve(null)),
    [dataset.data?.data_spec_id],
  );
  const draft = useDraft(datasetId);

  const loading = dataset.loading || spec.loading || draft.rows === null;
  const error = dataset.error || spec.error;

  return (
    <>
      <p className="muted">
        <Link to={`/simulation/projets/${projectId}/donnees/${datasetId}`}>← Versions</Link>
      </p>

      <AsyncBoundary error={error} loading={loading}>
        {spec.data && draft.rows && (
          <>
            <PageHeader
              title={dataset.data.instance_key ?? spec.data.label}
              lede={`${draft.rows.length} ligne(s) — ${spec.data.fields.length} champ(s).`}
            />

            <Card title="Contenu">
              <DatasetGrid
                fields={spec.data.fields}
                rows={draft.rows}
                transposed={spec.data.orientation === "FIELDS_AS_ROWS"}
                onChange={draft.edit}
              />
            </Card>

            <PublishCard
              dirty={draft.dirty}
              busy={draft.busy}
              error={draft.error}
              onSave={() => draft.save(draft.rows)}
              onPublish={async (label) => {
                const result = await draft.publish(draft.rows, label);
                if (result) dataset.reload();
                return result;
              }}
            />
          </>
        )}
      </AsyncBoundary>
    </>
  );
}
