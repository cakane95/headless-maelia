import { useState } from "react";
import { useNavigate, useParams } from "react-router";

import { scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import ConfirmDialog from "../../components/ConfirmDialog";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ScenariosTable from "./components/ScenariosTable";

/** Scénarios d'un projet : ce qui rend une exécution différente.
 *
 *  L'édition a son propre écran — 142 paramètres ne tiennent pas dans une
 *  modale. Ici on liste, on duplique, on supprime.
 */
export default function Scenarios() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const base = `/simulation/projets/${projectId}/scenarios`;
  const [doomed, setDoomed] = useState(null);
  const [failure, setFailure] = useState(null);
  const { data: scenarios, error, loading, reload } = useAsync(
    () => scenarioApi.listForProject(projectId),
    [projectId],
  );

  /** Repartir d'un scénario existant est le geste le plus courant : on compare
   *  deux variantes qui ne diffèrent que d'un paramètre. */
  async function duplicate(scenario) {
    try {
      const copy = await scenarioApi.create(projectId, {
        name: `${scenario.name} (copie)`,
        description: scenario.description,
        parameter_values: scenario.parameter_values,
        dataset_pins: scenario.dataset_pins,
      });
      navigate(`${base}/${copy.id}`);
    } catch (problem) {
      setFailure(problem.message);
    }
  }

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Scénarios"
            lede="Les écarts aux valeurs par défaut du modèle, et rien d'autre."
          />
        </div>
        <button type="button" onClick={() => navigate(`${base}/nouveau`)}>
          Nouveau scénario
        </button>
      </div>

      <Card>
        {failure && <p className="error">{failure}</p>}
        <AsyncBoundary error={error} loading={loading}>
          <ScenariosTable
            scenarios={scenarios ?? []}
            onOpen={(id) => navigate(`${base}/${id}`)}
            onDuplicate={duplicate}
            onDelete={setDoomed}
          />
        </AsyncBoundary>
      </Card>

      {doomed && (
        <ConfirmDialog
          title="Supprimer le scénario"
          message={`« ${doomed.name} » sera supprimé. Les exécutions déjà lancées gardent leurs résultats.`}
          onConfirm={async () => {
            await scenarioApi.remove(doomed.id);
            reload();
          }}
          onClose={() => setDoomed(null)}
        />
      )}
    </>
  );
}
