import EmptyState from "../../../components/EmptyState";

const TYPES = ["STRING", "INT", "FLOAT", "BOOL", "DATE"];

/** Les colonnes d'un fichier tabulaire.
 *
 *  La position n'est pas saisie : elle est l'ordre des lignes. C'est elle qui
 *  identifie un champ — un fichier transposé répète légitimement un libellé —
 *  et la laisser modifier à la main invitait à deux champs au même rang.
 */
export default function FieldSpecEditor({ fields, onChange }) {
  const update = (index, patch) =>
    onChange(fields.map((field, i) => (i === index ? { ...field, ...patch } : field)));

  const move = (index, step) => {
    const next = [...fields];
    const [moved] = next.splice(index, 1);
    next.splice(index + step, 0, moved);
    onChange(next.map((field, position) => ({ ...field, position })));
  };

  const remove = (index) =>
    onChange(
      fields.filter((_, i) => i !== index).map((field, position) => ({ ...field, position })),
    );

  const add = () =>
    onChange([
      ...fields,
      { name: "", label: null, type: "STRING", required: false, unit: null,
        allowed_values: [], references_data_spec: null, position: fields.length },
    ]);

  return (
    <>
      {fields.length === 0 ? (
        <EmptyState>Aucun champ décrit. Un fichier sans champ ne peut pas être validé.</EmptyState>
      ) : (
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Nom</th>
              <th>Type</th>
              <th>Requis</th>
              <th>Unité</th>
              <th>Valeurs admises</th>
              <th className="cell--actions" />
            </tr>
          </thead>
          <tbody>
            {fields.map((field, index) => (
              <tr key={index}>
                <td className="muted">{index}</td>
                <td>
                  <input
                    className="cell-input"
                    value={field.name}
                    aria-label={`Nom du champ ${index}`}
                    onChange={(event) => update(index, { name: event.target.value })}
                  />
                </td>
                <td>
                  <select
                    value={field.type}
                    aria-label={`Type du champ ${index}`}
                    onChange={(event) => update(index, { type: event.target.value })}
                  >
                    {TYPES.map((type) => <option key={type} value={type}>{type}</option>)}
                  </select>
                </td>
                <td>
                  <input
                    type="checkbox"
                    checked={Boolean(field.required)}
                    aria-label={`Champ ${index} requis`}
                    onChange={(event) => update(index, { required: event.target.checked })}
                  />
                </td>
                <td>
                  <input
                    className="cell-input"
                    value={field.unit ?? ""}
                    aria-label={`Unité du champ ${index}`}
                    onChange={(event) => update(index, { unit: event.target.value || null })}
                  />
                </td>
                <td>
                  <input
                    className="cell-input"
                    value={(field.allowed_values ?? []).join(", ")}
                    placeholder="valeurs séparées par des virgules"
                    aria-label={`Valeurs admises du champ ${index}`}
                    onChange={(event) =>
                      update(index, {
                        allowed_values: event.target.value
                          .split(",").map((v) => v.trim()).filter(Boolean),
                      })
                    }
                  />
                </td>
                <td className="cell--actions">
                  <button type="button" className="ghost" disabled={index === 0}
                          aria-label="Monter" onClick={() => move(index, -1)}>↑</button>
                  <button type="button" className="ghost" disabled={index === fields.length - 1}
                          aria-label="Descendre" onClick={() => move(index, 1)}>↓</button>
                  <button type="button" className="ghost" aria-label="Supprimer"
                          onClick={() => remove(index)}>×</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <p>
        <button type="button" className="ghost" onClick={add}>Ajouter un champ</button>
      </p>
    </>
  );
}
