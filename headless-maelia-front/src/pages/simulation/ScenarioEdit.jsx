import { Link, useNavigate, useParams } from "react-router";

import { datasetApi, scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ScenarioForm from "./components/ScenarioForm";

/** Création et modification d'un scénario, sur un écran dédié.
 *
 *  Le formulaire porte l'épinglage de chaque fichier du projet : trop long pour
 *  une modale, il lui faut la place d'une page.
 */
export default function ScenarioEdit() {
  const { projectId, scenarioId } = useParams();
  const navigate = useNavigate();
  const list = `/simulation/projets/${projectId}/scenarios`;

  const datasets = useAsync(() => datasetApi.listForProject(projectId), [projectId]);
  const existing = useAsync(
    () => (scenarioId ? scenarioApi.get(scenarioId) : Promise.resolve(false)),
    [scenarioId],
  );

  async function submit(payload) {
    if (scenarioId) await scenarioApi.update(scenarioId, payload);
    else await scenarioApi.create(projectId, payload);
    navigate(list);
  }

  return (
    <>
      <p className="muted">
        <Link to={list}>← Scénarios</Link>
      </p>
      <PageHeader
        title={scenarioId ? "Modifier le scénario" : "Nouveau scénario"}
        lede="Seuls les écarts voyagent : un fichier laissé libre suit sa dernière version valide."
      />

      <Card>
        <AsyncBoundary
          error={datasets.error ?? existing.error}
          loading={datasets.loading || existing.loading}
        >
          <ScenarioForm
            datasets={datasets.data ?? []}
            scenario={existing.data || null}
            onSubmit={submit}
            onCancel={() => navigate(list)}
          />
        </AsyncBoundary>
      </Card>
    </>
  );
}
