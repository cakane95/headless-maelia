import { useEffect, useState } from "react";
import { useParams } from "react-router";

import { projectRunApi, resultApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import FinishedRuns from "./components/FinishedRuns";
import OutputExplorer from "./components/OutputExplorer";
import OutputFiles from "./components/OutputFiles";
import OutputText from "./components/OutputText";

/** Résultats du projet : les sorties de ses exécutions terminées.
 *
 *  Plusieurs runs peuvent être cochés : la même configuration de graphique est
 *  alors rejouée sur chacun et superposée. C'est la lecture qui donne son sens
 *  au gel des versions de données — comparer deux scénarios.
 */
export default function ProjectResults() {
  const { projectId } = useParams();
  const [runIds, setRunIds] = useState([]);
  const [fileName, setFileName] = useState(null);

  const runs = useAsync(() => projectRunApi.list(projectId), [projectId]);
  const finished = (runs.data ?? []).filter((run) => run.status === "FINISHED");
  const selected = runIds.length > 0 ? runIds : finished.slice(0, 1).map((run) => run.id);

  const files = useAsync(
    () => (selected[0] ? resultApi.outputs(selected[0]) : Promise.resolve([])),
    [selected[0]],
  );

  // Les fichiers changent avec le run : on ouvre le premier qui se trace.
  useEffect(() => {
    const list = files.data ?? [];
    const first = list.find((f) => f.kind === "TABLE") ?? list[0];
    setFileName((current) => (list.some((f) => f.name === current) ? current : first?.name ?? null));
  }, [files.data]);

  const current = (files.data ?? []).find((f) => f.name === fileName);

  return (
    <>
      <PageHeader
        title="Résultats"
        lede="Les sorties d'un run restent attachées à la résolution figée qui les a produites."
      />

      <Card title="Exécutions terminées">
        <AsyncBoundary error={runs.error} loading={runs.loading}>
          <FinishedRuns runs={finished} selectedIds={selected} onToggle={setRunIds} />
        </AsyncBoundary>
      </Card>

      {selected.length > 0 && (
        <Card title="Fichiers de sortie">
          <AsyncBoundary error={files.error} loading={files.loading}>
            <OutputFiles files={files.data ?? []} selected={fileName} onSelect={setFileName} />
          </AsyncBoundary>
        </Card>
      )}

      {current?.kind === "TABLE" && (
        <OutputExplorer projectId={projectId} runIds={selected} fileName={current.name} />
      )}
      {current?.kind === "TEXT" && <OutputText runId={selected[0]} fileName={current.name} />}
    </>
  );
}
