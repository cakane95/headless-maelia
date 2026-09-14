import { useEffect, useState } from "react";

import { resultApi } from "../api";
import { mergeRuns } from "../utils/chart";

const IDLE = { data: null, error: null, loading: false };

/** Données d'un graphique, pour un run ou pour plusieurs.
 *
 *  Un seul run : la série vient du run. Plusieurs : le backend rejoue la même
 *  requête sur chacun et le hook superpose les résultats — c'est la comparaison
 *  de scénarios, et elle ne change rien à la configuration du graphique.
 */
export function useChart(projectId, runIds, fileName, query) {
  const [state, setState] = useState(IDLE);
  const signature = JSON.stringify([runIds, fileName, query]);

  useEffect(() => {
    if (!fileName || !query?.x || runIds.length === 0) {
      setState(IDLE);
      return undefined;
    }

    let cancelled = false;
    setState({ data: null, error: null, loading: true });

    const request =
      runIds.length === 1
        ? resultApi
            .series(runIds[0], fileName, query)
            .then((series) => [{ label: "", series }])
        : resultApi
            .comparison(projectId, { file_name: fileName, run_ids: runIds, query })
            .then((entries) => entries.map((e) => ({ label: e.label, series: e.series })));

    request
      .then((entries) => {
        if (!cancelled) setState({ data: mergeRuns(entries), error: null, loading: false });
      })
      .catch((error) => {
        if (!cancelled) setState({ data: null, error: error.message, loading: false });
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projectId, signature]);

  return state;
}
