import { useEffect, useState } from "react";
import { useParams } from "react-router";

import { projectRunApi, resultApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import EmptyState from "../../components/EmptyState";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import OutputPane from "./components/OutputPane";
import ResultsToolbar from "./components/ResultsToolbar";

/** Résultats du projet : les sorties de ses exécutions terminées.
 *
 *  Le graphique occupe le haut de l'écran ; le choix des exécutions et du
 *  fichier tient dans une barre collante au-dessus. Cocher plusieurs exécutions
 *  rejoue la même configuration sur chacune et les superpose — c'est la lecture
 *  qui donne son sens au gel des versions de données.
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

  // Les fichiers changent avec l'exécution : on ouvre le premier qui se trace.
  useEffect(() => {
    const list = files.data ?? [];
    const first = list.find((f) => f.kind === "TABLE") ?? list[0];
    setFileName((current) => (list.some((f) => f.name === current) ? current : first?.name ?? null));
  }, [files.data]);

  // La dernière exécution cochée ne se décoche pas : il n'y aurait plus rien à lire.
  function toggleRun(id) {
    const next = selected.includes(id) ? selected.filter((run) => run !== id) : [...selected, id];
    if (next.length > 0) setRunIds(next);
  }

  return (
    <>
      <PageHeader
        title="Résultats"
        lede="Les sorties d'une exécution restent attachées à la résolution figée qui les a produites."
      />

      <AsyncBoundary error={runs.error ?? files.error} loading={runs.loading}>
        {finished.length === 0 ? (
          <Card>
            <EmptyState>
              Aucune simulation terminée. Lancez-en une depuis la rubrique Simulations.
            </EmptyState>
          </Card>
        ) : (
          <>
            <ResultsToolbar
              runs={finished}
              selectedIds={selected}
              onToggleRun={toggleRun}
              files={files.data ?? []}
              fileName={fileName}
              onFile={setFileName}
            />
            <OutputPane
              projectId={projectId}
              runIds={selected}
              file={(files.data ?? []).find((f) => f.name === fileName)}
            />
          </>
        )}
      </AsyncBoundary>
    </>
  );
}
