import ParameterField from "./ParameterField";

/** Une section du launcher, repliée par défaut.
 *
 *  Quinze sections pour 142 paramètres : tout déplier d'un coup ne serait pas
 *  une liste, ce serait un mur. Une section qui porte un écart s'ouvre d'office.
 */
export default function ParameterGroup({ group, specs, values, onSet, onReset, open }) {
  const modified = specs.filter((spec) => spec.name in values).length;

  return (
    <details className="group" open={open || modified > 0}>
      <summary className="group__head">
        <span className="group__title">{group}</span>
        <span className="group__count">{specs.length}</span>
        {modified > 0 && <em className="group__badge">{modified} modifié{modified > 1 ? "s" : ""}</em>}
      </summary>

      <div className="params">
        {specs.map((spec) => (
          <ParameterField
            key={spec.name}
            spec={spec}
            value={values[spec.name]}
            modified={spec.name in values}
            onChange={(value) => onSet(spec, value)}
            onReset={() => onReset(spec)}
          />
        ))}
      </div>
    </details>
  );
}
