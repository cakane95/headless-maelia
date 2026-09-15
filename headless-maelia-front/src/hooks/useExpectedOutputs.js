import { useEffect, useState } from "react";

import { catalogApi } from "../api";

/** Ce qu'un scénario portant ces écarts produirait comme fichiers.
 *
 *  Même contrat que `useActivation` : la condition est évaluée au backend, où
 *  elle est écrite une fois. Le front affiche le verdict, il ne le recalcule
 *  pas — deux évaluateurs, c'est deux réponses le jour où la forme change.
 *
 *  Les frappes successives retombent : on n'interroge qu'une fois la main levée.
 */
export function useExpectedOutputs(values) {
  const [expectations, setExpectations] = useState([]);
  const signature = JSON.stringify(values ?? {});

  useEffect(() => {
    let cancelled = false;
    const timer = setTimeout(() => {
      catalogApi
        .expectedOutputs(JSON.parse(signature))
        .then((list) => {
          if (!cancelled) setExpectations(list);
        })
        .catch(() => {
          // Sans réponse, on n'annonce rien plutôt qu'une liste fausse.
          if (!cancelled) setExpectations([]);
        });
    }, 300);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [signature]);

  return expectations;
}
