import Card from "../../../components/Card";
import Field from "../../../components/Field";
import { fromText, toText } from "../../../utils/parameters";

const TYPES = ["BOOL", "INT", "FLOAT", "STRING", "LIST", "EXPRESSION"];

/** Ce qu'un paramètre accepte : son type, son défaut, ses valeurs admises, et
 *  le fichier où lire celles-ci quand elles viennent des données du projet. */
export default function ParameterValueFields({ draft, set }) {
  return (
    <Card title="Valeur">
      <Field label="Type">
        <select value={draft.type} onChange={(e) => set("type", e.target.value)}>
          {TYPES.map((type) => <option key={type} value={type}>{type}</option>)}
        </select>
      </Field>

      <Field label="Valeur par défaut" hint="Celle du launcher : un scénario n'enregistre que les écarts.">
        {draft.type === "BOOL" ? (
          <label className="switch">
            <input
              type="checkbox"
              checked={Boolean(draft.default)}
              onChange={(e) => set("default", e.target.checked)}
            />
            <span>{draft.default ? "Activé" : "Désactivé"}</span>
          </label>
        ) : (
          <input
            value={toText(draft.default)}
            onChange={(e) => set("default", fromText(draft.type, e.target.value))}
          />
        )}
      </Field>

      <Field label="Valeurs admises" hint="Vide : saisie libre. Sinon, une liste déroulante.">
        <input
          value={(draft.allowed_values ?? []).join(", ")}
          onChange={(e) =>
            set("allowed_values", e.target.value.split(",").map((v) => v.trim()).filter(Boolean))}
        />
      </Field>

      <Field
        label="Valeurs lues dans un fichier"
        hint="« identifiant de fichier#champ » : les identifiants viennent des données du projet."
      >
        <input
          value={draft.options_from ?? ""}
          placeholder="agri.agriculteurs.exploitations#ID_EXPL"
          onChange={(e) => set("options_from", e.target.value)}
        />
      </Field>
    </Card>
  );
}
