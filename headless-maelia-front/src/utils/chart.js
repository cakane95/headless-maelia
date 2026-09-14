/** Mise en forme des séries pour l'affichage. Aucune règle métier ici :
 *  l'agrégation est faite par le backend, on ne fait que rassembler. */

/** Ordre de l'axe : numérique quand il peut l'être, alphabétique sinon. */
function compare(a, b) {
  const x = Number(a);
  const y = Number(b);
  const numeric = !Number.isNaN(x) && !Number.isNaN(y);
  return numeric ? x - y : String(a).localeCompare(String(b));
}

/** Fusionne les séries de plusieurs runs en un seul jeu de points.
 *
 *  À plusieurs runs, chaque série est préfixée par le libellé du run : c'est ce
 *  qui rend la comparaison de deux scénarios lisible sur un même graphique.
 */
export function mergeRuns(entries) {
  const prefixed = entries.length > 1;
  const byX = new Map();
  const keys = [];

  for (const { label, series } of entries) {
    const rename = (key) => (prefixed ? `${label} · ${key}` : key);
    for (const key of series.keys) keys.push(rename(key));
    for (const row of series.rows) {
      const point = byX.get(row.x) ?? { x: row.x };
      for (const key of series.keys) point[rename(key)] = row[key];
      byX.set(row.x, point);
    }
  }

  return {
    keys,
    rows: [...byX.values()].sort((a, b) => compare(a.x, b.x)),
    truncated: entries.some((e) => e.series.truncated),
  };
}
