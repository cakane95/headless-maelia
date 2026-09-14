import { useEffect, useState } from "react";

import { resultApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import Card from "../../../components/Card";
import { useAsync } from "../../../hooks/useAsync";
import { useChart } from "../../../hooks/useChart";
import ChartBuilder from "./ChartBuilder";
import ChartSuggestions from "./ChartSuggestions";
import ChartView from "./ChartView";
import OutputPreview from "./OutputPreview";

/** Exploration d'un fichier de sortie : lectures proposées, personnalisation,
 *  tracé, et aperçu des lignes qui l'alimentent. */
export default function OutputExplorer({ projectId, runIds, fileName }) {
  const [config, setConfig] = useState(null);
  const [tuning, setTuning] = useState(false);
  const profile = useAsync(
    () => resultApi.profile(runIds[0], fileName),
    [runIds[0], fileName],
  );

  // Le fichier s'ouvre sur la première lecture proposée : un graphique vide
  // n'apprendrait rien de ce que la simulation a produit.
  useEffect(() => {
    const first = profile.data?.suggestions?.[0];
    setConfig(first ? { title: first.title, chart: first.chart, query: first.query } : null);
    setTuning(false);
  }, [profile.data]);

  const chart = useChart(projectId, runIds, fileName, config?.query);
  const columns = profile.data?.columns ?? [];

  return (
    <AsyncBoundary error={profile.error} loading={profile.loading}>
      <Card title={fileName}>
        <p className="muted muted--first">
          {profile.data?.row_count} lignes · {columns.length} colonnes
          {runIds.length > 1 && ` · ${runIds.length} runs comparés`}
        </p>

        <ChartSuggestions
          suggestions={profile.data?.suggestions ?? []}
          activeTitle={config?.title}
          onPick={(s) => setConfig({ title: s.title, chart: s.chart, query: s.query })}
        />

        {config && (
          <>
            <p>
              <button type="button" className="ghost" onClick={() => setTuning((t) => !t)}>
                {tuning ? "Masquer les réglages" : "Personnaliser le graphique"}
              </button>
            </p>

            {tuning && (
              <ChartBuilder
                columns={columns}
                chart={config.chart}
                query={config.query}
                onChart={(type) => setConfig({ ...config, chart: type, title: null })}
                onQuery={(query) => setConfig({ ...config, query, title: null })}
              />
            )}

            <AsyncBoundary error={chart.error} loading={chart.loading}>
              <ChartView type={config.chart} rows={chart.data?.rows} keys={chart.data?.keys} />
            </AsyncBoundary>

            {chart.data?.truncated && (
              <p className="muted">Axe tronqué : seules les premières valeurs sont tracées.</p>
            )}
          </>
        )}
      </Card>

      <OutputPreview runId={runIds[0]} fileName={fileName} />
    </AsyncBoundary>
  );
}
