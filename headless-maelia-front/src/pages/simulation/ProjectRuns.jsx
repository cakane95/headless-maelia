import { useState } from "react";
import { useNavigate, useParams } from "react-router";

import { projectRunApi, scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Modal from "../../components/Modal";
import PageHeader from "../../components/PageHeader";
import RunsTable from "../../components/RunsTable";
import { useAsync } from "../../hooks/useAsync";
import LaunchScenarioForm from "./components/LaunchScenarioForm";

/** Exécutions d'un projet, lancées à travers un scénario. */
export default function ProjectRuns() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const [launching, setLaunching] = useState(false);

  const scenarios = useAsync(() => scenarioApi.listForProject(projectId), [projectId]);
  const runs = useAsync(() => projectRunApi.list(projectId), [projectId]);

  async function launch(payload) {
    const run = await projectRunApi.launch(projectId, payload);
    navigate(`/simulation/projets/${projectId}/simulations/${run.id}`);
  }

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Simulations"
            lede="Le lancement fige les paramètres et les versions de données : le résultat reste reproductible."
          />
        </div>
        <button type="button" onClick={() => setLaunching(true)}>Lancer une simulation</button>
      </div>

      <Card title="Historique">
        <AsyncBoundary error={runs.error} loading={runs.loading}>
          <RunsTable
            runs={runs.data ?? []}
            onSelect={(id) => navigate(`/simulation/projets/${projectId}/simulations/${id}`)}
          />
        </AsyncBoundary>
      </Card>

      {launching && (
        <Modal title="Lancer une simulation" onClose={() => setLaunching(false)}>
          <AsyncBoundary error={scenarios.error} loading={scenarios.loading}>
            <LaunchScenarioForm
              scenarios={scenarios.data ?? []}
              onLaunch={launch}
              onCancel={() => setLaunching(false)}
            />
          </AsyncBoundary>
        </Modal>
      )}
    </>
  );
}
