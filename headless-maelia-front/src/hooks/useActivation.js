import { useEffect, useState } from "react";

import { catalogApi } from "../api";

/** Quels paramètres sont actifs, compte tenu des écarts saisis.
 *
 *  La règle vit au backend — un paramètre commandé par un autre n'a aucun effet
 *  tant que celui-ci est éteint. La réévaluer ici ferait deux évaluateurs, donc
 *  deux comportements le jour où l'un des deux change.
 *
 *  Les frappes successives retombent : on n'interroge qu'une fois la main levée.
 */
export function useActivation(values) {
  const [states, setStates] = useState({});
  const signature = JSON.stringify(values ?? {});

  useEffect(() => {
    let cancelled = false;
    const timer = setTimeout(() => {
      catalogApi
        .activation(JSON.parse(signature))
        .then((list) => {
          if (cancelled) return;
          setStates(Object.fromEntries(list.map((state) => [state.name, state])));
        })
        .catch(() => {
          // Sans réponse, tout reste modifiable : verrouiller un champ sur un
          // échec réseau serait pire que de laisser saisir.
          if (!cancelled) setStates({});
        });
    }, 300);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [signature]);

  return states;
}
