import { Link, useParams } from "react-router";

import ArtifactsTable from "../components/ArtifactsTable";
import AsyncBoundary from "../components/AsyncBoundary";
import Card from "../components/Card";
import ConsoleView from "../components/ConsoleView";
import PageHeader from "../components/PageHeader";
import RunSummary from "../components/RunSummary";
import { useRunStream } from "../hooks/useRunStream";

/** Suivi d'une exécution : état, console GAMA en direct, artefacts produits.
 *
 *  Le même écran sert les deux espaces : un run lancé depuis un projet y
 *  revient, un run du banc d'essai revient au banc d'essai.
 */
export default function RunDetail() {
  const { runId, projectId } = useParams();
  const { run, logs, error } = useRunStream(runId);

  const back = projectId
    ? { to: `/simulation/projets/${projectId}/simulations`, label: "Simulations" }
    : { to: "/admin/banc-essai", label: "Banc d'essai" };

  return (
    <AsyncBoundary error={error} loading={!run}>
      {run && (
        <>
          <p className="muted">
            <Link to={back.to}>← {back.label}</Link>
          </p>
          <div className="page-head">
            <div>
              <PageHeader title={run.label} lede={`${run.experiment} — ${run.id}`} />
            </div>
            {/* Les résultats s'ouvrent depuis l'exécution : c'est d'ici qu'on
                sait qu'il y a quelque chose à lire. Le banc d'essai n'a pas de
                projet, donc pas d'écran de résultats. */}
            {projectId && run.status === "FINISHED" && (
              <Link className="button-link" to={`${back.to}/${runId}/resultats`}>
                Voir les résultats
              </Link>
            )}
          </div>

          <Card>
            <RunSummary run={run} />
          </Card>

          <Card title="Console GAMA">
            <ConsoleView lines={logs} empty="En attente du worker…" />
          </Card>

          <Card title="Sorties">
            <ArtifactsTable artifacts={run.artifacts} outputDir={run.output_dir} />
          </Card>
        </>
      )}
    </AsyncBoundary>
  );
}
