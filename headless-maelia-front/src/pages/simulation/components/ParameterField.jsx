import { toLabel } from "../../../utils/parameters";
import ParameterControl from "./ParameterControl";

/** Un paramètre du launcher : son contrôle, son défaut, son retour arrière.
 *
 *  La valeur par défaut reste affichée même quand le paramètre est modifié :
 *  c'est elle qui donne son sens à l'écart, et c'est elle que « Rétablir »
 *  remet — un scénario ne stocke que ses écarts.
 */
export default function ParameterField({ spec, value, modified, onChange, onReset }) {
  return (
    <div className={modified ? "param param--modified" : "param"}>
      <div className="param__head">
        <label className="param__name" htmlFor={spec.name}>{spec.label}</label>
        {modified && (
          <button type="button" className="link" onClick={onReset}>Rétablir</button>
        )}
      </div>

      <ParameterControl
        spec={spec}
        value={modified ? value : spec.default}
        onChange={onChange}
      />

      <small className="hint">Défaut : {toLabel(spec.default)}</small>
    </div>
  );
}
