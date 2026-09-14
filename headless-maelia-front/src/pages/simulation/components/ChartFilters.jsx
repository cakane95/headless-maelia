import Field from "../../../components/Field";

// Au-delà, la liste déroulante devient une corvée — et le backend ne renvoie de
// toute façon qu'un échantillon des valeurs d'une colonne très variée.
const MAX_VALUES = 40;

/** Restreindre le graphique à une parcelle, une culture, un itinéraire.
 *
 *  Les valeurs proposées viennent du profil du fichier : la plateforme ne
 *  connaît aucune valeur MAELIA, elle affiche ce que le fichier contient.
 */
export default function ChartFilters({ columns, filters, onChange }) {
  const filterable = columns.filter(
    (c) => c.role !== "MEASURE" && c.values.length > 1 && c.values.length <= MAX_VALUES,
  );
  if (filterable.length === 0) return null;

  function pick(column, value) {
    const next = { ...filters };
    if (value) next[column] = [value];
    else delete next[column];
    onChange(next);
  }

  return (
    <>
      {filterable.map((column) => (
        <Field
          key={column.name}
          label={column.label}
          hint={
            column.distinct > column.values.length
              ? `${column.values.length} valeurs sur ${column.distinct}`
              : undefined
          }
        >
          <select
            value={filters[column.name]?.[0] ?? ""}
            onChange={(event) => pick(column.name, event.target.value)}
          >
            <option value="">Toutes les valeurs</option>
            {column.values.map((value) => (
              <option key={value} value={value}>{value}</option>
            ))}
          </select>
        </Field>
      ))}
    </>
  );
}
