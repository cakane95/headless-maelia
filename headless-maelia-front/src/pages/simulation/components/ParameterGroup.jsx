import { useEffect, useState } from "react";

import ParameterField from "./ParameterField";

/** Une section du launcher, repliée par défaut.
 *
 *  Quinze sections pour 142 paramètres : tout déplier d'un coup ne serait pas
 *  une liste, ce serait un mur. Une section qui porte un écart s'ouvre d'office
 *  au premier rendu.
 */
export default function ParameterGroup({
  group, specs, values, activation, onSet, onReset, forceOpen,
}) {
  const modified = specs.filter((spec) => spec.name in values).length;
  const [open, setOpen] = useState(forceOpen || modified > 0);

  // L'ouverture appartient à l'utilisateur dès qu'il y a touché. La dériver du
  // nombre d'écarts à chaque rendu refermait la section quand on décochait le
  // dernier d'entre eux — il fallait la rouvrir pour continuer. Seuls la
  // recherche et le filtre la rouvrent, parce qu'ils changent ce qu'on regarde.
  useEffect(() => {
    setOpen(forceOpen || modified > 0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [forceOpen]);

  return (
    <details
      className="group"
      open={open}
      onToggle={(event) => setOpen(event.currentTarget.open)}
    >
      <summary className="group__head">
        <span className="group__title">{group}</span>
        <span className="group__count">{specs.length}</span>
        {modified > 0 && (
          <em className="group__badge">{modified} modifié{modified > 1 ? "s" : ""}</em>
        )}
      </summary>

      <div className="params">
        {specs.map((spec) => (
          <ParameterField
            key={spec.name}
            spec={spec}
            value={values[spec.name]}
            modified={spec.name in values}
            activation={activation?.[spec.name]}
            onChange={(value) => onSet(spec, value)}
            onReset={() => onReset(spec)}
          />
        ))}
      </div>
    </details>
  );
}
