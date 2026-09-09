import { useCallback, useEffect, useState } from "react";

const CLE = "maelia-theme";
export const THEMES = ["system", "light", "dark"];

/** Thème effectivement appliqué quand la préférence est « système ». */
function resoudre(preference) {
  if (preference !== "system") return preference;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function lire() {
  try {
    const stocke = localStorage.getItem(CLE);
    return THEMES.includes(stocke) ? stocke : "system";
  } catch {
    // Navigation privée ou stockage bloqué : on retombe sur la préférence système.
    return "system";
  }
}

/**
 * Préférence de thème : « système », clair ou sombre.
 *
 * La préférence est résolue en JS et posée en `data-theme` sur <html> — le CSS
 * n'a donc qu'un seul bloc sombre, au lieu d'un duplicata media query + attribut.
 */
export function useTheme() {
  const [preference, setPreference] = useState(lire);

  useEffect(() => {
    const appliquer = () => {
      document.documentElement.dataset.theme = resoudre(preference);
    };
    appliquer();

    try {
      localStorage.setItem(CLE, preference);
    } catch {
      // Préférence non persistée : sans gravité, elle vaut pour la session.
    }

    // En mode « système », suivre les changements de thème de l'OS à chaud.
    if (preference !== "system") return undefined;
    const media = window.matchMedia("(prefers-color-scheme: dark)");
    media.addEventListener("change", appliquer);
    return () => media.removeEventListener("change", appliquer);
  }, [preference]);

  const suivant = useCallback(() => {
    setPreference((actuel) => THEMES[(THEMES.indexOf(actuel) + 1) % THEMES.length]);
  }, []);

  return { preference, setPreference, suivant };
}
