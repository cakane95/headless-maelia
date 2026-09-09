import { useEffect, useState } from "react";

/**
 * Charge une ressource une fois et expose le triplet (données, erreur, chargement).
 * Évite de réécrire le même useEffect dans chaque écran — et d'en oublier le nettoyage.
 */
export function useAsync(loader, deps = []) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

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
  }, deps);

  return { data, error, loading: data === null && error === null };
}
