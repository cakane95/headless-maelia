import { useEffect, useState } from "react";

const SLOTS = 8;
const FALLBACK = "#0e7c86";

/** Couleurs du thème courant, lues sur `<html>`.
 *
 *  Recharts pose ses couleurs en attributs SVG, où `var(--chart-1)` ne serait
 *  pas résolu : il faut donc leur passer des valeurs calculées.
 */
function read() {
  const style = getComputedStyle(document.documentElement);
  const value = (name) => style.getPropertyValue(name).trim();
  return {
    series: Array.from({ length: SLOTS }, (_, i) => value(`--chart-${i + 1}`) || FALLBACK),
    grid: value("--chart-grid") || "#e2e8f0",
    axis: value("--chart-axis") || "#64748b",
  };
}

/** Palette de graphique, resuivie au changement de thème.
 *
 *  Le thème est posé en `data-theme` sur `<html>` par useTheme : on observe cet
 *  attribut plutôt que de partager un état, ce qui marche quel que soit
 *  l'endroit d'où la bascule est actionnée.
 */
export function useChartPalette() {
  const [palette, setPalette] = useState(read);

  useEffect(() => {
    const observer = new MutationObserver(() => setPalette(read()));
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-theme"],
    });
    return () => observer.disconnect();
  }, []);

  return palette;
}
