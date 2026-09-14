import { useNavigate, useParams } from "react-router";

import { scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ScenariosTable from "./components/ScenariosTable";

/** Scénarios d'un projet : ce qui rend une exécution différente.
 *
 *  L'édition a son propre écran : un scénario épingle potentiellement des
 *  dizaines de fichiers, ce n'est pas un formulaire de modale.
 */
export default function Scenarios() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const base = `/simulation/projets/${projectId}/scenarios`;
  const { data: scenarios, error, loading } = useAsync(
    () => scenarioApi.listForProject(projectId), [projectId],
  );

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Scénarios"
            lede="Écarts aux valeurs par défaut du modèle, et versions de données épinglées."
          />
        </div>
        <button type="button" onClick={() => navigate(`${base}/nouveau`)}>
          Nouveau scénario
        </button>
      </div>

      <Card>
        <AsyncBoundary error={error} loading={loading}>
          <ScenariosTable
            scenarios={scenarios ?? []}
            onSelect={(id) => navigate(`${base}/${id}`)}
          />
        </AsyncBoundary>
      </Card>
    </>
  );
}
