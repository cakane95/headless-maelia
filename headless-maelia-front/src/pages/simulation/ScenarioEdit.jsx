import { Link, useNavigate, useParams } from "react-router";

import { catalogApi, scenarioApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ScenarioForm from "./components/ScenarioForm";

/** Création et modification d'un scénario, sur un écran dédié.
 *
 *  Le formulaire couvre les 142 paramètres modifiables du launcher : trop long
 *  pour une modale, il lui faut la place d'une page.
 */
export default function ScenarioEdit() {
  const { projectId, scenarioId } = useParams();
  const navigate = useNavigate();
  const list = `/simulation/projets/${projectId}/scenarios`;

  const parameters = useAsync(catalogApi.parameters);
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
        lede="Seuls les écarts sont enregistrés : un paramètre laissé tel quel suivra le modèle."
      />

      <AsyncBoundary
        error={parameters.error ?? existing.error}
        loading={parameters.loading || existing.loading}
      >
        <ScenarioForm
          specs={parameters.data ?? []}
          scenario={existing.data || null}
          onSubmit={submit}
          onCancel={() => navigate(list)}
        />
      </AsyncBoundary>
    </>
  );
}
