import { useNavigate } from "react-router";

import { adminApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import { useRunsPolling } from "../../hooks/useRunsPolling";
import LaunchForm from "./components/LaunchForm";
import RunsTable from "./components/RunsTable";

/** Banc d'essai : valider un modèle sur GAMA headless avant de l'ouvrir aux projets. */
export default function TestBench() {
  const navigate = useNavigate();
  const { data: models, error, loading } = useAsync(adminApi.models);
  const { runs } = useRunsPolling();

  async function launch(payload) {
    const run = await adminApi.launch(payload);
    navigate(`/admin/banc-essai/${run.id}`);
  }

  return (
    <>
      <PageHeader
        title="Banc d'essai"
        lede="Exécuter un modèle sur GAMA headless et suivre le run en direct."
      />

      <Card title="Lancer une simulation">
        <AsyncBoundary error={error} loading={loading}>
          <LaunchForm models={models ?? []} onLaunch={launch} />
        </AsyncBoundary>
      </Card>

      <Card title="Historique">
        <RunsTable runs={runs} onSelect={(id) => navigate(`/admin/banc-essai/${id}`)} />
      </Card>
    </>
  );
}
