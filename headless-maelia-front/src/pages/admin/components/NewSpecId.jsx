import Card from "../../../components/Card";
import Field from "../../../components/Field";

/** L'identifiant d'une spec, saisi une seule fois.
 *
 *  Il ne change plus ensuite : c'est lui que portent les datasets des projets,
 *  les dépendances et les sources de valeurs des paramètres.
 */
export default function NewSpecId({ value, onChange }) {
  return (
    <Card title="Identifiant">
      <Field
        label="Identifiant"
        hint="Stable et définitif : agri.culture.reglesDeDecisions."
      >
        <input
          value={value}
          onChange={(event) => onChange(event.target.value)}
          placeholder="agri.culture.monFichier"
          required
        />
      </Field>
    </Card>
  );
}
