import { useState } from "react";
import { useNavigate } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import ModuleTabs from "../../components/ModuleTabs";
import PageHeader from "../../components/PageHeader";
import StatGroup from "../../components/StatGroup";
import { useAsync } from "../../hooks/useAsync";
import { countFiles, matchesOutput, themeTabs } from "../../utils/outputs";
import OutputSpecTable from "./components/OutputSpecTable";

/** Catalogue des sorties du modèle.
 *
 *  MAELIA n'écrit rien par défaut : chaque sortie est derrière un interrupteur,
 *  imbriqué dans les gardes des modules dont elle dépend. Ce catalogue porte ce
 *  lien — sans lui, un scénario ne sait pas ce qu'il produira et un fichier
 *  absent ne s'explique pas.
 *
 *  Il est engendré depuis le GAML ; l'administrateur corrige à la marge.
 */
export default function OutputCatalog() {
  const navigate = useNavigate();
  const [theme, setTheme] = useState("all");
  const [query, setQuery] = useState("");
  const { data: specs, error, loading } = useAsync(catalogApi.outputs);

  const all = specs ?? [];
  const shown = all.filter(
    (spec) => (theme === "all" || spec.theme === theme) && matchesOutput(spec, query),
  );
  const horsPortee = all.filter((spec) => spec.unreachable.length > 0).length;

  return (
    <>
      <PageHeader
        title="Sorties du modèle"
        lede="Ce que le modèle peut écrire, et ce qu'il faut activer pour l'obtenir."
      />

      <AsyncBoundary error={error} loading={loading}>
        {all.length > 0 && (
          <Card>
            <StatGroup
              items={[
                { label: "sorties recensées", value: all.length },
                { label: "fichiers produits", value: countFiles(all) },
                // Le launcher n'expose pas leur interrupteur : aucun scénario
                // ne peut les activer, et c'est le seul travail de fond qui
                // reste à faire sur ce catalogue.
                { label: "hors de portée d'un scénario", value: horsPortee },
              ]}
            />
          </Card>
        )}

        <Card>
          <ModuleTabs tabs={themeTabs(all)} active={theme} onSelect={setTheme} />

          <div className="filters">
            <input
              type="search"
              className="filters__search"
              value={query}
              placeholder="Rechercher une sortie ou un fichier…"
              aria-label="Rechercher une sortie"
              onChange={(event) => setQuery(event.target.value)}
            />
            <span className="filters__count">
              {shown.length} sortie{shown.length > 1 ? "s" : ""}
            </span>
          </div>

          <OutputSpecTable
            specs={shown}
            onSelect={(id) => navigate(`/admin/catalogue/sorties/${encodeURIComponent(id)}`)}
          />
        </Card>
      </AsyncBoundary>
    </>
  );
}
