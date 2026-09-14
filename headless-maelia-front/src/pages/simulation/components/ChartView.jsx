import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Scatter,
  ScatterChart,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import EmptyState from "../../../components/EmptyState";
import { useChartPalette } from "../../../hooks/useChartPalette";

const CONTAINERS = {
  LINE: LineChart,
  BAR: BarChart,
  STACKED_BAR: BarChart,
  AREA: AreaChart,
  SCATTER: ScatterChart,
};

/** Rendu d'une série. Le type de graphique est une donnée, pas une branche de
 *  code appelante : le module de personnalisation le change à chaud. */
export default function ChartView({ type = "LINE", rows, keys, height = 320 }) {
  const palette = useChartPalette();

  if (!rows?.length || !keys?.length) {
    return <EmptyState>Aucun point à tracer pour cette configuration.</EmptyState>;
  }

  const Container = CONTAINERS[type] ?? LineChart;
  const axis = { stroke: palette.axis, fontSize: 11 };

  return (
    <div className="chart">
      <ResponsiveContainer width="100%" height={height}>
        <Container data={rows} margin={{ top: 8, right: 16, bottom: 4, left: 0 }}>
          <CartesianGrid stroke={palette.grid} strokeDasharray="3 3" vertical={false} />
          <XAxis dataKey="x" {...axis} tickMargin={8} minTickGap={16} />
          <YAxis {...axis} width={64} tickFormatter={format} />
          <Tooltip
            contentStyle={{ fontSize: 12 }}
            formatter={(value) => format(value)}
            labelFormatter={(value) => `${value}`}
          />
          {keys.length > 1 && <Legend wrapperStyle={{ fontSize: 11 }} />}
          {keys.map((key, index) => renderSeries(type, key, palette.series[index % 8]))}
        </Container>
      </ResponsiveContainer>
    </div>
  );
}

/** Milliers abrégés, décimales bornées : les sorties MAELIA vont de 0,02 à 6e5. */
function format(value) {
  if (typeof value !== "number") return value;
  if (Math.abs(value) >= 10000) return `${(value / 1000).toFixed(1)}k`;
  return Math.abs(value) >= 100 ? value.toFixed(0) : value.toFixed(2);
}

function renderSeries(type, key, color) {
  if (type === "BAR" || type === "STACKED_BAR") {
    return (
      <Bar
        key={key}
        dataKey={key}
        fill={color}
        stackId={type === "STACKED_BAR" ? "stack" : undefined}
      />
    );
  }
  if (type === "AREA") {
    return (
      <Area key={key} type="monotone" dataKey={key} stroke={color} fill={color} fillOpacity={0.2} />
    );
  }
  if (type === "SCATTER") {
    return <Scatter key={key} dataKey={key} fill={color} />;
  }
  return <Line key={key} type="monotone" dataKey={key} stroke={color} dot={false} strokeWidth={2} />;
}
