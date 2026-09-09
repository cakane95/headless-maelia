import { useEffect, useState } from "react";

import { adminApi, subscribeRun } from "../api";

const MAX_LIGNES = 400;

/**
 * Suivi d'une exécution : instantané REST d'abord, puis flux WebSocket.
 *
 * L'instantané évite l'écran vide quand on arrive en cours de route ; le plafond
 * de lignes évite de garder en mémoire les milliers de lignes d'un run long.
 */
export function useRunStream(runId) {
  const [run, setRun] = useState(null);
  const [logs, setLogs] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;

    adminApi
      .run(runId)
      .then((data) => {
        if (cancelled) return;
        setRun(data);
        setLogs(data.logs ?? []);
      })
      .catch((err) => !cancelled && setError(err.message));

    const unsubscribe = subscribeRun(runId, (event) => {
      if (event.kind === "log") {
        setLogs((lignes) => [...lignes.slice(-(MAX_LIGNES - 1)), event.line]);
        setRun((etat) =>
          etat ? { ...etat, current_date: event.current_date ?? etat.current_date } : etat,
        );
      } else {
        setRun((etat) => ({ ...etat, ...event.run }));
      }
    });

    return () => {
      cancelled = true;
      unsubscribe();
    };
  }, [runId]);

  return { run, logs, error };
}
