import { useEffect, useState } from "react";

import { resultApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import Card from "../../../components/Card";
import { useAsync } from "../../../hooks/useAsync";
import { useChart } from "../../../hooks/useChart";
import { describeChart, download, toCsv } from "../../../utils/chart";
import ChartBuilder from "./ChartBuilder";
import ChartHead from "./ChartHead";
import ChartSuggestions from "./ChartSuggestions";
import ChartView from "./ChartView";
import OutputPreview from "./OutputPreview";

/** Exploration d'un fichier de sortie.
 *
 *  Le tracé passe avant ses réglages : on arrive sur un graphique lisible, on
 *  l'ajuste ensuite — et les réglages s'ouvrent **sous** lui pour qu'il reste
 *  visible pendant qu'on les change.
 */
export default function OutputExplorer({ projectId, runIds, fileName }) {
  const [config, setConfig] = useState(null);
  const [tuning, setTuning] = useState(false);
  const profile = useAsync(() => resultApi.profile(runIds[0], fileName), [runIds[0], fileName]);

  // Le fichier s'ouvre sur la première lecture proposée : un graphique vide
  // n'apprendrait rien de ce que la simulation a produit.
  useEffect(() => {
    const first = profile.data?.suggestions?.[0];
    setConfig(first ? { title: first.title, chart: first.chart, query: first.query } : null);
  }, [profile.data]);

  const chart = useChart(projectId, runIds, fileName, config?.query);
  const columns = profile.data?.columns ?? [];
  // Un réglage manuel n'est plus l'une des lectures proposées : le titre tombe.
  const tune = (patch) => setConfig({ ...config, ...patch, title: null });

  return (
    <AsyncBoundary error={profile.error} loading={profile.loading}>
      <Card>
        <ChartSuggestions
          suggestions={profile.data?.suggestions ?? []}
          activeTitle={config?.title}
          onPick={(s) => setConfig({ title: s.title, chart: s.chart, query: s.query })}
        />

        {config && (
          <>
            <ChartHead
              summary={describeChart(config.query, columns, runIds.length)}
              tuning={tuning}
              exportable={chart.data?.rows?.length > 0}
              onTune={() => setTuning((open) => !open)}
              onExport={() => exportCsv(chart.data, config.query, fileName)}
            />

            <div className="chart-slot">
              <AsyncBoundary error={chart.error} loading={chart.loading} pending="Calcul…">
                <ChartView type={config.chart} rows={chart.data?.rows} keys={chart.data?.keys} />
              </AsyncBoundary>
            </div>

            {chart.data?.truncated && (
              <p className="muted">Axe tronqué : seules les premières valeurs sont tracées.</p>
            )}

            {tuning && (
              <ChartBuilder
                columns={columns}
                chart={config.chart}
                query={config.query}
                onChart={(type) => tune({ chart: type })}
                onQuery={(query) => tune({ query })}
              />
            )}
          </>
        )}

        <p className="muted">
          {fileName} · {profile.data?.row_count} lignes · {columns.length} colonnes
        </p>
      </Card>

      <OutputPreview runId={runIds[0]} fileName={fileName} />
    </AsyncBoundary>
  );
}

/** Les points tracés, pas le fichier entier : c'est le tableau qu'on commente. */
function exportCsv(data, query, fileName) {
  const base = fileName.replace(/\.[^.]+$/, "");
  download(toCsv(data.rows, data.keys, query.x), `${base}-graphique.csv`);
}
