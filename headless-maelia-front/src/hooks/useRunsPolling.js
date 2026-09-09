import { useEffect, useState } from "react";

import { adminApi } from "../api";
import { ACTIVE_RUN_STATUSES } from "../utils/status";
const INTERVAL_ACTIF = 3000;
const INTERVAL_REPOS = 15000;

/**
 * Historique des exécutions, rafraîchi vite tant que quelque chose bouge,
 * lentement sinon — plutôt qu'à cadence fixe « au cas où ».
 */
export function useRunsPolling() {
  const [runs, setRuns] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    let timer;
    let cancelled = false;

    const tick = () =>
      adminApi
        .runs()
        .then((list) => {
          if (cancelled) return;
          setRuns(list);
          const actif = list.some((run) => ACTIVE_RUN_STATUSES.includes(run.status));
          timer = setTimeout(tick, actif ? INTERVAL_ACTIF : INTERVAL_REPOS);
        })
        .catch((err) => !cancelled && setError(err.message));

    tick();

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, []);

  return { runs, error };
}
