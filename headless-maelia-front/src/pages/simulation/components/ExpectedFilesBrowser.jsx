import { useMemo, useState } from "react";

import { fileStatusLabel } from "../../../utils/status";
import ExpectedFiles from "./ExpectedFiles";
import ModuleTabs from "../../../components/ModuleTabs";

const STATUSES = ["MISSING", "DRAFT", "INVALID", "VALID"];

/** Les fichiers attendus, par module, filtrables.
 *
 *  Quarante et un fichiers sur deux modules — soixante-cinq avec
 *  l'hydrographique : une seule table demandait de parcourir l'écran pour
 *  répondre à « qu'est-ce qu'il me manque, au juste ? ».
 */
export default function ExpectedFilesBrowser({ completion, datasetsBySpec, projectId }) {
  const [active, setActive] = useState("all");
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("");

  const entries = completion.entries;
  const tabs = useMemo(() => buildTabs(completion), [completion]);

  const shown = entries.filter(
    (entry) =>
      (active === "all" || entry.module === active) &&
      (!status || entry.status === status) &&
      entry.label.toLowerCase().includes(query.trim().toLowerCase()),
  );

  return (
    <>
      <ModuleTabs tabs={tabs} active={active} onSelect={setActive} />

      <div className="filters">
        <input
          type="search"
          className="filters__search"
          value={query}
          placeholder="Rechercher un fichier…"
          aria-label="Rechercher un fichier"
          onChange={(event) => setQuery(event.target.value)}
        />
        <select
          value={status}
          aria-label="Filtrer par état"
          onChange={(event) => setStatus(event.target.value)}
        >
          <option value="">Tous les états</option>
          {STATUSES.map((value) => (
            <option key={value} value={value}>{fileStatusLabel(value)}</option>
          ))}
        </select>
        <span className="filters__count">
          {shown.length} fichier{shown.length > 1 ? "s" : ""}
        </span>
      </div>

      <ExpectedFiles entries={shown} datasetsBySpec={datasetsBySpec} projectId={projectId} />
    </>
  );
}

/** Un onglet par module, plus « Tous ».
 *
 *  Les comptes viennent tous du backend : les recalculer ici les ferait diverger
 *  de la carte Avancement, qui ne compte que les fichiers requis et valides.
 */
function buildTabs(completion) {
  const badge = ({ supplied, expected }) => `${supplied}/${expected}`;
  return [
    { id: "all", badge: badge(completion) },
    ...Object.entries(completion.by_module ?? {}).map(([id, counts]) => ({
      id,
      badge: badge(counts),
    })),
  ];
}
