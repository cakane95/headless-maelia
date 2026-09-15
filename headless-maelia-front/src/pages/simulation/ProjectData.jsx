import { useParams } from "react-router";

import { datasetApi, projectApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import ProgressBar from "../../components/ProgressBar";
import { useAsync } from "../../hooks/useAsync";
import CompletionByModule from "./components/CompletionByModule";
import ExpectedFilesBrowser from "./components/ExpectedFilesBrowser";

/** Données d'entrée d'un projet : ce qui est attendu, ce qui est fourni. */
export default function ProjectData() {
  const { projectId } = useParams();
  const project = useAsync(() => projectApi.get(projectId), [projectId]);
  const completion = useAsync(() => projectApi.completion(projectId), [projectId]);
  const datasets = useAsync(() => datasetApi.listForProject(projectId), [projectId]);

  const bySpec = Object.fromEntries(
    (datasets.data ?? []).map((d) => [d.data_spec_id, d]),
  );

  return (
    <>
      <PageHeader
        title="Données d'entrée"
        lede={
          project.data
            ? `${project.data.name} — ce que la configuration attend, ce qui est fourni.`
            : "Fichiers attendus par la configuration de modélisation."
        }
      />

      <AsyncBoundary error={completion.error} loading={completion.loading}>
        {completion.data && (
          <>
            <Card title="Avancement">
              <ProgressBar ratio={completion.data.ratio} label="Entrées obligatoires" />
              <p className="muted">
                {completion.data.supplied} fichier(s) obligatoire(s) valide(s) sur{" "}
                {completion.data.expected}. Un fichier facultatif manquant ne bloque
                pas le lancement : le modèle continue sans lui.
              </p>
              <CompletionByModule byModule={completion.data.by_module} />
            </Card>

            <Card title="Fichiers attendus">
              <AsyncBoundary error={datasets.error} loading={datasets.loading}>
                <ExpectedFilesBrowser
                  completion={completion.data}
                  datasetsBySpec={bySpec}
                  projectId={projectId}
                />
              </AsyncBoundary>
            </Card>
          </>
        )}
      </AsyncBoundary>
    </>
  );
}
