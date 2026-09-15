import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";

import { projectRunApi, resultApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import EmptyState from "../../components/EmptyState";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import CompareRuns from "./components/CompareRuns";
import OutputPane from "./components/OutputPane";
import ResultsToolbar from "./components/ResultsToolbar";

/** Résultats d'une exécution.
 *
 *  On y entre depuis l'exécution elle-même : l'écran n'a donc pas à demander
 *  laquelle, et toute la place va au graphique. Comparer avec d'autres runs
 *  reste possible, mais c'est un geste explicite, pas le chemin par défaut.
 */
export default function RunResults() {
  const { projectId, runId } = useParams();
  const [compared, setCompared] = useState([]);
  const [fileName, setFileName] = useState(null);

  const runs = useAsync(() => projectRunApi.list(projectId), [projectId]);
  const files = useAsync(() => resultApi.outputs(runId), [runId]);
  const runIds = [runId, ...compared];

  // Les fichiers changent avec l'exécution : on ouvre le premier qui se trace.
  useEffect(() => {
    const list = files.data ?? [];
    const first = list.find((f) => f.kind === "TABLE") ?? list[0];
    setFileName((current) => (list.some((f) => f.name === current) ? current : first?.name ?? null));
  }, [files.data]);

  const finished = (runs.data ?? []).filter((run) => run.status === "FINISHED");
  const current = finished.find((run) => run.id === runId);

  return (
    <>
      <p className="muted">
        <Link to={`/simulation/projets/${projectId}/simulations`}>← Simulations</Link>
      </p>
      <PageHeader
        title={current?.label ? `Résultats — ${current.label}` : "Résultats"}
        lede="Les sorties restent attachées à la résolution figée qui les a produites."
      />

      <AsyncBoundary error={files.error} loading={files.loading}>
        {(files.data ?? []).length === 0 ? (
          <Card>
            <EmptyState>Cette exécution n'a produit aucun fichier.</EmptyState>
          </Card>
        ) : (
          <>
            <ResultsToolbar
              files={files.data ?? []}
              fileName={fileName}
              onFile={setFileName}
              comparison={
                <CompareRuns
                  runs={finished.filter((run) => run.id !== runId)}
                  selected={compared}
                  onChange={setCompared}
                />
              }
            />
            <OutputPane
              projectId={projectId}
              runIds={runIds}
              file={(files.data ?? []).find((f) => f.name === fileName)}
            />
          </>
        )}
      </AsyncBoundary>
    </>
  );
}
