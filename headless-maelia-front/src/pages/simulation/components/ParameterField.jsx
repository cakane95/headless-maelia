import { toLabel } from "../../../utils/parameters";
import ParameterControl from "./ParameterControl";

/** Un paramètre du launcher : son contrôle, son défaut, son retour arrière.
 *
 *  La valeur par défaut reste affichée même quand le paramètre est modifié :
 *  c'est elle qui donne son sens à l'écart, et c'est elle que « Rétablir »
 *  remet — un scénario ne stocke que ses écarts.
 */
export default function ParameterField({ spec, value, modified, activation, onChange, onReset }) {
  // Sans réponse du backend, on laisse modifiable : verrouiller un champ sur un
  // silence serait pire que de laisser saisir.
  const inactif = activation ? activation.enabled === false : false;
  const classes = ["param"];
  if (modified) classes.push("param--modified");
  if (inactif) classes.push("param--inactive");

  return (
    <div className={classes.join(" ")}>
      <div className="param__head">
        <label className="param__name" htmlFor={spec.name}>{spec.label}</label>
        {modified && (
          <button type="button" className="link" onClick={onReset}>Rétablir</button>
        )}
      </div>

      <fieldset disabled={inactif}>
        <ParameterControl
          spec={spec}
          value={modified ? value : spec.default}
          onChange={onChange}
        />
      </fieldset>

      {inactif ? (
        <small className="hint hint--locked">Sans effet : {activation.because}</small>
      ) : (
        <small className="hint">Défaut : {toLabel(spec.default)}</small>
      )}
      {inactif && modified && (
        <small className="hint hint--warn">Un écart est enregistré ici, il ne s'applique pas.</small>
      )}
    </div>
  );
}
