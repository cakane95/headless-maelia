import Field from "../../../components/Field";
import ChartFilters from "./ChartFilters";
import MeasurePicker from "./MeasurePicker";

const CHARTS = [
  ["LINE", "Courbe"],
  ["BAR", "Barres"],
  ["STACKED_BAR", "Barres empilées"],
  ["AREA", "Aire"],
  ["SCATTER", "Nuage de points"],
];

const AGGREGATES = [
  ["MEAN", "Moyenne"],
  ["SUM", "Somme"],
  ["MIN", "Minimum"],
  ["MAX", "Maximum"],
  ["COUNT", "Nombre de lignes"],
];

/** Personnalisation d'un graphique : axe, mesures, répartition, agrégat.
 *
 *  Les colonnes proposées viennent du profil du fichier : la plateforme ne
 *  connaît aucun nom de colonne MAELIA, elle lit ce que le fichier contient.
 */
export default function ChartBuilder({ columns, chart, query, onChart, onQuery }) {
  const dimensions = columns.filter((c) => c.role !== "MEASURE");
  const measures = columns.filter((c) => c.role === "MEASURE");
  const label = (column) => (column.unit ? `${column.label} (${column.unit})` : column.label);
  const set = (patch) => onQuery({ ...query, ...patch });

  return (
    <div className="builder">
      <Field label="Type">
        <select value={chart} onChange={(e) => onChart(e.target.value)}>
          {CHARTS.map(([value, text]) => <option key={value} value={value}>{text}</option>)}
        </select>
      </Field>

      <Field label="Axe horizontal">
        <select value={query.x} onChange={(e) => set({ x: e.target.value })}>
          {dimensions.map((c) => (
            <option key={c.name} value={c.name}>{label(c)} ({c.distinct})</option>
          ))}
        </select>
      </Field>

      <Field label="Agrégat" hint="Plusieurs lignes partagent une même valeur d'axe.">
        <select value={query.aggregate} onChange={(e) => set({ aggregate: e.target.value })}>
          {AGGREGATES.map(([value, text]) => <option key={value} value={value}>{text}</option>)}
        </select>
      </Field>

      <Field label="Répartir par" hint="Une série par valeur, au-delà de 8 c'est illisible.">
        <select value={query.series_by ?? ""} onChange={(e) => set({ series_by: e.target.value || null })}>
          <option value="">Aucune répartition</option>
          {dimensions
            .filter((c) => c.name !== query.x && c.distinct <= 12)
            .map((c) => <option key={c.name} value={c.name}>{label(c)}</option>)}
        </select>
      </Field>

      <ChartFilters
        columns={columns}
        filters={query.filters ?? {}}
        onChange={(filters) => set({ filters })}
      />

      <MeasurePicker
        measures={measures}
        selected={query.measures}
        onChange={(next) => set({ measures: next })}
      />
    </div>
  );
}
