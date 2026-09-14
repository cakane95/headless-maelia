/** Mise en forme des séries pour l'affichage. Aucune règle métier ici :
 *  l'agrégation est faite par le backend, on ne fait que rassembler. */

const AGGREGATES = {
  MEAN: "Moyenne",
  SUM: "Somme",
  MIN: "Minimum",
  MAX: "Maximum",
  COUNT: "Nombre de lignes",
};

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

/** Nom lisible d'une colonne, unité comprise. */
export function columnLabel(columns, name) {
  const column = columns.find((c) => c.name === name);
  if (!column) return name;
  return column.unit ? `${column.label} (${column.unit})` : column.label;
}

/** Ce que le graphique montre, en une phrase.
 *
 *  Sans elle, rien ne dit si l'on regarde une somme ou une moyenne — deux
 *  lectures très différentes d'un même fichier.
 */
export function describeChart(query, columns, runCount = 1) {
  const name = (column) => columnLabel(columns, column);
  const how = AGGREGATES[query.aggregate] ?? query.aggregate;

  let text =
    query.aggregate === "COUNT"
      ? `Nombre de lignes par ${name(query.x)}`
      : `${how} de ${query.measures.map(name).join(", ")} par ${name(query.x)}`;

  if (query.series_by) text += `, réparti par ${name(query.series_by)}`;

  const filters = Object.entries(query.filters ?? {}).filter(([, values]) => values.length > 0);
  if (filters.length > 0) {
    text += ` — ${filters.map(([c, values]) => `${name(c)} : ${values.join(", ")}`).join(" · ")}`;
  }
  if (runCount > 1) text += ` · ${runCount} exécutions superposées`;

  return text;
}

/** Points agrégés au format CSV, séparateur `;` comme les fichiers du modèle. */
export function toCsv(rows, keys, axis) {
  const lines = [[axis, ...keys].join(";")];
  for (const row of rows) lines.push([row.x, ...keys.map((k) => row[k] ?? "")].join(";"));
  return lines.join("\n");
}

/** Déclenche le téléchargement d'un texte, sans passer par le serveur. */
export function download(text, fileName) {
  const url = URL.createObjectURL(new Blob([text], { type: "text/csv;charset=utf-8" }));
  const link = Object.assign(document.createElement("a"), { href: url, download: fileName });
  link.click();
  URL.revokeObjectURL(url);
}
