import { useState } from "react";
import { useNavigate } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ModuleTabs from "../../components/ModuleTabs";
import DataSpecTable from "./components/DataSpecTable";

/** Catalogue des fichiers d'entrée attendus par le modèle.
 *
 *  Il fait autorité : c'est lui qui décide ce qu'un projet doit fournir et
 *  comment chaque fichier est lu. Le modifier engage donc toute la plateforme.
 */
export default function InputCatalog() {
  const navigate = useNavigate();
  const [module, setModule] = useState("all");
  const [query, setQuery] = useState("");
  const { data: specs, error, loading } = useAsync(catalogApi.dataspecs);

  const all = specs ?? [];
  const tabs = buildTabs(all);
  const shown = all.filter(
    (spec) =>
      (module === "all" || spec.module === module) &&
      `${spec.label} ${spec.id} ${spec.relative_dir}`.toLowerCase()
        .includes(query.trim().toLowerCase()),
  );

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Catalogue des entrées"
            lede="Ce que le modèle lit. Extrait du code GAML : ajouter un fichier ne demande pas de déployer."
          />
        </div>
        <button type="button" onClick={() => navigate("/admin/catalogue/entrees/nouveau")}>
          Nouveau type de fichier
        </button>
      </div>

      <Card>
        <AsyncBoundary error={error} loading={loading}>
          <ModuleTabs tabs={tabs} active={module} onSelect={setModule} />

          <div className="filters">
            <input
              type="search"
              className="filters__search"
              value={query}
              placeholder="Rechercher un fichier…"
              aria-label="Rechercher un fichier"
              onChange={(event) => setQuery(event.target.value)}
            />
            <span className="filters__count">
              {shown.length} type{shown.length > 1 ? "s" : ""} de fichier
            </span>
          </div>

          <DataSpecTable
            specs={shown}
            onSelect={(id) =>
              navigate(`/admin/catalogue/entrees/${encodeURIComponent(id)}`)
            }
          />
        </AsyncBoundary>
      </Card>
    </>
  );
}

/** Un onglet par module, avec le nombre de types de fichiers qu'il décrit. */
function buildTabs(specs) {
  const modules = [...new Set(specs.map((spec) => spec.module))].sort();
  return [
    { id: "all", badge: String(specs.length) },
    ...modules.map((id) => ({
      id,
      badge: String(specs.filter((spec) => spec.module === id).length),
    })),
  ];
}
