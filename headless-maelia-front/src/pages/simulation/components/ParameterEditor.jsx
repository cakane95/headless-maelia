import { useState } from "react";

import EmptyState from "../../../components/EmptyState";
import { matches, sameValue } from "../../../utils/parameters";
import ParameterBar from "./ParameterBar";
import ParameterGroup from "./ParameterGroup";

/** Les paramètres du launcher, groupés par section.
 *
 *  Un scénario ne stocke que ses **écarts** : reposer la valeur par défaut
 *  retire l'écart au lieu de l'enregistrer. C'est ce qui rend un scénario
 *  robuste à une montée de version du modèle.
 */
export default function ParameterEditor({ specs, values, onChange }) {
  const [query, setQuery] = useState("");
  const [onlyModified, setOnlyModified] = useState(false);

  // Les paramètres pilotés par la plateforme (chemins, id de run) et les
  // expressions GAML ne sont pas offerts : les fixer n'aurait aucun effet.
  const editable = specs.filter((spec) => spec.editable && !spec.system);
  const visible = editable.filter(
    (spec) => matches(spec, query) && (!onlyModified || spec.name in values),
  );

  function set(spec, value) {
    const next = { ...values };
    if (value === null || sameValue(value, spec.default)) delete next[spec.name];
    else next[spec.name] = value;
    onChange(next);
  }

  function reset(spec) {
    const next = { ...values };
    delete next[spec.name];
    onChange(next);
  }

  return (
    <>
      <ParameterBar
        query={query}
        onQuery={setQuery}
        onlyModified={onlyModified}
        onOnlyModified={setOnlyModified}
        count={Object.keys(values).length}
        onResetAll={() => onChange({})}
      />

      {visible.length === 0 ? (
        <EmptyState>Aucun paramètre ne correspond.</EmptyState>
      ) : (
        Object.entries(groupBy(visible)).map(([group, groupSpecs]) => (
          <ParameterGroup
            key={group}
            group={group}
            specs={groupSpecs}
            values={values}
            onSet={set}
            onReset={reset}
            // Une recherche ou un filtre a déjà réduit la liste : on l'ouvre.
            // Au-delà, l'ouverture appartient à l'utilisateur.
            forceOpen={Boolean(query.trim()) || onlyModified}
          />
        ))
      )}
    </>
  );
}

function groupBy(specs) {
  return specs.reduce((groups, spec) => {
    (groups[spec.group] ??= []).push(spec);
    return groups;
  }, {});
}
