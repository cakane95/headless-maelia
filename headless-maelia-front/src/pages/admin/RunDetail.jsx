import { Link, useParams } from "react-router";

import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import ConsoleView from "../../components/ConsoleView";
import PageHeader from "../../components/PageHeader";
import { useRunStream } from "../../hooks/useRunStream";
import ArtifactsTable from "./components/ArtifactsTable";
import RunSummary from "./components/RunSummary";

/** Suivi d'une exécution : état, console GAMA en direct, artefacts produits. */
export default function RunDetail() {
  const { runId } = useParams();
  const { run, logs, error } = useRunStream(runId);

  return (
    <AsyncBoundary error={error} loading={!run}>
      {run && (
        <>
          <p className="muted">
            <Link to="/admin/banc-essai">← Banc d'essai</Link>
          </p>
          <PageHeader title={run.label} lede={`${run.experiment} — ${run.id}`} />

          <Card>
            <RunSummary run={run} />
          </Card>

          <Card title="Console GAMA">
            <ConsoleView lines={logs} empty="En attente du worker…" />
          </Card>

          {run.artifacts?.length > 0 && (
            <Card title="Sorties">
              <ArtifactsTable artifacts={run.artifacts} outputDir={run.output_dir} />
            </Card>
          )}
        </>
      )}
    </AsyncBoundary>
  );
}
