import { useState } from "react";
import { useNavigate } from "react-router";

import { adminApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Modal from "../../components/Modal";
import PageHeader from "../../components/PageHeader";
import RunsTable from "../../components/RunsTable";
import { useAsync } from "../../hooks/useAsync";
import { useRunsPolling } from "../../hooks/useRunsPolling";
import LaunchForm from "./components/LaunchForm";

/** Banc d'essai : valider un modèle sur GAMA headless avant de l'ouvrir aux projets. */
export default function TestBench() {
  const navigate = useNavigate();
  const [launching, setLaunching] = useState(false);
  const { data: models, error, loading } = useAsync(adminApi.models);
  const { runs } = useRunsPolling();

  async function launch(payload) {
    const run = await adminApi.launch(payload);
    navigate(`/admin/banc-essai/${run.id}`);
  }

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Banc d'essai"
            lede="Exécuter un modèle sur GAMA headless et suivre le run en direct."
          />
        </div>
        <button type="button" onClick={() => setLaunching(true)}>Lancer une simulation</button>
      </div>

      <Card title="Historique">
        <RunsTable
          runs={runs}
          onSelect={(id) => navigate(`/admin/banc-essai/${id}`)}
          onStop={adminApi.cancel}
        />
      </Card>

      {launching && (
        <Modal title="Lancer une simulation" onClose={() => setLaunching(false)}>
          <AsyncBoundary error={error} loading={loading}>
            <LaunchForm
              models={models ?? []}
              onLaunch={launch}
              onCancel={() => setLaunching(false)}
            />
          </AsyncBoundary>
        </Modal>
      )}
    </>
  );
}
