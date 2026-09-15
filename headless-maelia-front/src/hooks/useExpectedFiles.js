import { useEffect, useState } from "react";

import { catalogApi } from "../api";

/** Nombre de fichiers attendus par une configuration, calculé par le backend.
 *
 *  Le front n'évalue pas les conditions d'applicabilité : elles vivent dans le
 *  catalogue. On les lui demande, en laissant retomber les clics successifs.
 */
export function useExpectedFiles(draft) {
  const [count, setCount] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setCount(null);
    const timer = setTimeout(() => {
      catalogApi
        .applicable(draft)
        .then((specs) => !cancelled && setCount(specs.length))
        .catch(() => !cancelled && setCount(null));
    }, 350);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [JSON.stringify(draft)]);

  return count;
}
