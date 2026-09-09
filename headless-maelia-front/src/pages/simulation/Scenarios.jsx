import { useState } from "react";
import { useParams } from "react-router";

import { datasetApi, scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import EmptyState from "../../components/EmptyState";
import PageHeader from "../../components/PageHeader";
import ProjectTabs from "./components/ProjectTabs";
import { useAsync } from "../../hooks/useAsync";
import ScenarioForm from "./components/ScenarioForm";

/** Scénarios d'un projet : ce qui rend une exécution différente. */
export default function Scenarios() {
  const { projectId } = useParams();
  const [version, setVersion] = useState(0);
  const datasets = useAsync(() => datasetApi.listForProject(projectId), [projectId]);
  const scenarios = useAsync(
    () => scenarioApi.listForProject(projectId), [projectId, version],
  );

  async function create(payload) {
    await scenarioApi.create(projectId, payload);
    setVersion((v) => v + 1);
  }

  return (
    <>
      <ProjectTabs projectId={projectId} />
      <PageHeader
        title="Scénarios"
        lede="Écarts aux valeurs par défaut du modèle, et versions de données épinglées."
      />

      <Card title="Nouveau scénario">
        <AsyncBoundary error={datasets.error} loading={datasets.loading}>
          <ScenarioForm datasets={datasets.data ?? []} onSubmit={create} />
        </AsyncBoundary>
      </Card>

      <Card title="Scénarios">
        <AsyncBoundary error={scenarios.error} loading={scenarios.loading}>
          {scenarios.data?.length === 0 ? (
            <EmptyState>Aucun scénario pour l'instant.</EmptyState>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Paramètres modifiés</th>
                  <th>Versions épinglées</th>
                </tr>
              </thead>
              <tbody>
                {scenarios.data?.map((scenario) => (
                  <tr key={scenario.id}>
                    <td>{scenario.name}</td>
                    <td className="muted">
                      {Object.entries(scenario.parameter_values)
                        .map(([k, v]) => `${k}=${v}`)
                        .join(", ") || "—"}
                    </td>
                    <td className="muted">
                      {Object.keys(scenario.dataset_pins).length || "aucune"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </AsyncBoundary>
      </Card>
    </>
  );
}
