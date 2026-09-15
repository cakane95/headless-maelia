import { useState } from "react";
import { useNavigate } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import ModuleTabs from "../../components/ModuleTabs";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ParameterSpecTable from "./components/ParameterSpecTable";

/** Catalogue des paramètres de scénario.
 *
 *  Le launcher est la référence : une variable qu'il ne déclare pas ne peut pas
 *  être surchargée dans un `load`, donc ne peut pas faire partie d'un scénario.
 *  Ce catalogue dit lesquelles existent, leur type, et ce qui les commande.
 */
export default function ParameterCatalog() {
  const navigate = useNavigate();
  const [group, setGroup] = useState("all");
  const [query, setQuery] = useState("");
  const { data: specs, error, loading } = useAsync(catalogApi.parameters);

  const all = specs ?? [];
  const shown = all.filter(
    (spec) =>
      (group === "all" || spec.group === group) &&
      `${spec.name} ${spec.label} ${spec.group}`.toLowerCase()
        .includes(query.trim().toLowerCase()),
  );

  return (
    <>
      <PageHeader
        title="Paramètres de scénario"
        lede="Les variables que le launcher expose. Un scénario n'en enregistre que les écarts."
      />

      <Card>
        <AsyncBoundary error={error} loading={loading}>
          <ModuleTabs tabs={buildTabs(all)} active={group} onSelect={setGroup} />

          <div className="filters">
            <input
              type="search"
              className="filters__search"
              value={query}
              placeholder="Rechercher un paramètre…"
              aria-label="Rechercher un paramètre"
              onChange={(event) => setQuery(event.target.value)}
            />
            <span className="filters__count">
              {shown.length} paramètre{shown.length > 1 ? "s" : ""}
            </span>
          </div>

          <ParameterSpecTable
            specs={shown}
            onSelect={(name) =>
              navigate(`/admin/catalogue/parametres/${encodeURIComponent(name)}`)
            }
          />
        </AsyncBoundary>
      </Card>
    </>
  );
}

/** Un onglet par section du launcher, avec le nombre de paramètres. */
function buildTabs(specs) {
  const sections = [...new Set(specs.map((spec) => spec.group))].sort();
  return [
    { id: "all", badge: String(specs.length) },
    ...sections.map((id) => ({
      id,
      badge: String(specs.filter((spec) => spec.group === id).length),
    })),
  ];
}
