import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";

import { catalogApi, datasetApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import FamilyInstances from "./components/FamilyInstances";

/** Les fichiers d'une même famille : une série climatique, un jeu de prix.
 *
 *  Certains types d'entrée n'ont pas un fichier mais plusieurs — un par année,
 *  un par scénario. Ils partagent la même description et la même validation ;
 *  seul leur nom les distingue. D'où cet écran intermédiaire : la liste des
 *  fichiers reçus pour ce type, et l'entrée dans chacun.
 */
export default function DatasetFamily() {
  const { projectId, specId } = useParams();
  const navigate = useNavigate();
  const [query, setQuery] = useState("");

  const spec = useAsync(() => catalogApi.dataspec(specId), [specId]);
  const datasets = useAsync(() => datasetApi.listForProject(projectId), [projectId]);

  const famille = (datasets.data ?? []).filter((d) => d.data_spec_id === specId);
  const shown = famille.filter((d) =>
    (d.instance_key ?? "").toLowerCase().includes(query.trim().toLowerCase()),
  );

  return (
    <>
      <p className="muted">
        <Link to={`/simulation/projets/${projectId}/donnees`}>← Données d'entrée</Link>
      </p>

      <AsyncBoundary error={spec.error ?? datasets.error} loading={spec.loading || datasets.loading}>
        <PageHeader
          title={spec.data?.label ?? specId}
          lede={
            spec.data
              ? `${famille.length} fichier(s) reçu(s) · ${spec.data.relative_dir}/${spec.data.file_name_pattern ?? ""}`
              : undefined
          }
        />

        <Card>
          <div className="filters">
            <input
              type="search"
              className="filters__search"
              value={query}
              placeholder="Rechercher un fichier…"
              aria-label="Rechercher un fichier de la famille"
              onChange={(event) => setQuery(event.target.value)}
            />
            <span className="filters__count">
              {shown.length} sur {famille.length}
            </span>
          </div>

          <FamilyInstances
            instances={shown}
            onOpen={(id) => navigate(`/simulation/projets/${projectId}/donnees/${id}`)}
          />
        </Card>
      </AsyncBoundary>
    </>
  );
}
