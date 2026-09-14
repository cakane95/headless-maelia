import { useCallback, useEffect, useState } from "react";

import { datasetApi } from "../api";

/**
 * Brouillon éditable d'un fichier d'entrée.
 *
 *  Le brouillon est mutable ; publier le fige. Ce hook garde l'état local,
 *  signale les modifications non enregistrées, et évite d'écraser une édition
 *  en cours quand le chargement initial arrive.
 */
export function useDraft(datasetId) {
  const [rows, setRows] = useState(null);
  const [dirty, setDirty] = useState(false);
  const [busy, setBusy] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    datasetApi
      .draft(datasetId)
      .then((loaded) => !cancelled && setRows(loaded))
      .catch((err) => !cancelled && setError(err.message));
    return () => {
      cancelled = true;
    };
  }, [datasetId]);

  const edit = useCallback((next) => {
    setRows(next);
    setDirty(true);
  }, []);

  const run = useCallback(async (action, fn) => {
    setBusy(action);
    setError(null);
    try {
      return await fn();
    } catch (err) {
      setError(err.message);
      return null;
    } finally {
      setBusy(null);
    }
  }, []);

  const save = useCallback(
    (current) =>
      run("save", async () => {
        await datasetApi.saveDraft(datasetId, current);
        setDirty(false);
      }),
    [datasetId, run],
  );

  const publish = useCallback(
    (current, label) =>
      run("publish", async () => {
        // Publier sans enregistrer perdrait les dernières modifications.
        if (dirty) await datasetApi.saveDraft(datasetId, current);
        const result = await datasetApi.publish(datasetId, { label: label || undefined });
        setDirty(false);
        return result;
      }),
    [datasetId, dirty, run],
  );

  return { rows, edit, dirty, busy, error, save, publish };
}
