import { useCallback, useEffect, useState } from "react";

/**
 * Charge une ressource et expose le triplet (données, erreur, chargement).
 * Évite de réécrire le même useEffect dans chaque écran — et d'en oublier le nettoyage.
 *
 * `reload()` relance le chargement : utile après une écriture, pour que l'écran
 * reflète l'état réel du serveur plutôt qu'une supposition locale.
 */
export function useAsync(loader, deps = []) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    let cancelled = false;

    loader()
      .then((result) => !cancelled && setData(result))
      .catch((err) => !cancelled && setError(err.message));

    // Empêche d'écrire dans un composant démonté.
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, tick]);

  const reload = useCallback(() => setTick((t) => t + 1), []);

  return { data, error, loading: data === null && error === null, reload };
}
