/** Lecture du catalogue des sorties.
 *
 *  Les règles font autorité côté backend : ici on ne fait que nommer ce qu'il
 *  renvoie, et regrouper pour l'affichage.
 */

const GRANULARITES = {
  DAILY: "journalier",
  YEAR_START: "début d'année",
  YEAR_END: "fin d'année",
  MONTHLY: "mensuel",
  FORTNIGHTLY: "bimensuel",
  UNKNOWN: "—",
};

export function granularityLabel(granularity) {
  return GRANULARITES[granularity] ?? "—";
}

const PRODUCTIONS = {
  PRODUCED: { label: "Produite", tone: "VALID" },
  ABSENT: { label: "Non demandée", tone: "" },
  UNCERTAIN: { label: "Peut-être", tone: "DRAFT" },
};

export function productionLabel(production) {
  return PRODUCTIONS[production] ?? PRODUCTIONS.ABSENT;
}

const plain = (text) =>
  (text ?? "").normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase();

/** Une sortie répond-elle à la recherche ? Identifiant, description, fichiers. */
export function matchesOutput(spec, query) {
  if (!query.trim()) return true;
  const needle = plain(query);
  const haystack = [spec.id, spec.label, spec.description, ...spec.files.map((f) => f.name)];
  return haystack.some((value) => plain(value).includes(needle));
}

/** Un onglet par thème, avec le nombre de sorties. */
export function themeTabs(specs) {
  const themes = [...new Set(specs.map((spec) => spec.theme))].sort();
  return [
    { id: "all", badge: String(specs.length) },
    ...themes.map((id) => ({
      id,
      badge: String(specs.filter((spec) => spec.theme === id).length),
    })),
  ];
}

/** Combien de fichiers ces sorties représentent. */
export function countFiles(specs) {
  return specs.reduce((total, spec) => total + spec.files.length, 0);
}
