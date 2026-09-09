import { useState } from "react";
import { useNavigate, useParams } from "react-router";

import { projectRunApi, scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Field from "../../components/Field";
import PageHeader from "../../components/PageHeader";
import ProjectTabs from "./components/ProjectTabs";
import { useAsync } from "../../hooks/useAsync";
import RunsTable from "../admin/components/RunsTable";

/** Exécutions d'un projet, lancées à travers un scénario. */
export default function ProjectRuns() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const [tick, setTick] = useState(0);
  const [scenarioId, setScenarioId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const scenarios = useAsync(() => scenarioApi.listForProject(projectId), [projectId]);
  const runs = useAsync(() => projectRunApi.list(projectId), [projectId, tick]);

  const selected = scenarioId || scenarios.data?.[0]?.id || "";

  async function launch(event) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await projectRunApi.launch(projectId, { scenario_id: selected });
      setTick((t) => t + 1);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <ProjectTabs projectId={projectId} />
      <PageHeader
        title="Simulations"
        lede="Le lancement fige les paramètres et les versions de données : le résultat reste reproductible."
      />

      <Card title="Lancer une simulation">
        <AsyncBoundary error={scenarios.error} loading={scenarios.loading}>
          <form onSubmit={launch}>
            <Field label="Scénario">
              <select value={selected} onChange={(e) => setScenarioId(e.target.value)}>
                {scenarios.data?.map((s) => (
                  <option key={s.id} value={s.id}>{s.name}</option>
                ))}
              </select>
            </Field>
            <button disabled={busy || !selected}>{busy ? "Lancement…" : "Lancer"}</button>
            {error && <p className="error">{error}</p>}
          </form>
        </AsyncBoundary>
      </Card>

      <Card title="Historique">
        <AsyncBoundary error={runs.error} loading={runs.loading}>
          <RunsTable
            runs={runs.data ?? []}
            onSelect={(id) => navigate(`/admin/banc-essai/${id}`)}
          />
        </AsyncBoundary>
      </Card>
    </>
  );
}
