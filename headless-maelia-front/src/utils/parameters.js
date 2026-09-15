/** Lecture et écriture des valeurs de paramètres.
 *
 *  Le typage fait autorité côté backend (catalogue + validation) : ici on ne
 *  fait que présenter une valeur et reconvertir une saisie.
 */

/** Égalité de deux valeurs de paramètre, listes comprises. */
export function sameValue(a, b) {
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
}

/** Texte affiché dans un contrôle. */
export function toText(value) {
  if (value === null || value === undefined) return "";
  return Array.isArray(value) ? value.join(", ") : String(value);
}

/** Valeur typée à partir d'une saisie, selon le type déclaré par le catalogue. */
export function fromText(type, text) {
  if (type === "LIST") {
    return text.split(",").map((part) => part.trim()).filter(Boolean);
  }
  if (type === "INT" || type === "FLOAT") {
    const number = type === "INT" ? parseInt(text, 10) : parseFloat(text);
    // Saisie en cours (« - », « 1. ») : on ne remonte rien plutôt qu'un NaN.
    return Number.isNaN(number) ? null : number;
  }
  return text;
}

/** Valeur lisible par un humain : un booléen n'est pas « true ». */
export function toLabel(value) {
  if (typeof value === "boolean") return value ? "oui" : "non";
  if (Array.isArray(value)) return value.length > 0 ? value.join(", ") : "liste vide";
  return value === "" ? "vide" : String(value);
}

/** Valeur par défaut résumée pour une cellule de tableau.
 *
 *  `listAgriASuivre` en compte 165 : les afficher obligeait à faire défiler la
 *  table de côté pour atteindre les colonnes suivantes. Le compte suffit à
 *  situer le paramètre ; le détail s'obtient en l'ouvrant.
 */
export function summariseDefault(value, limit = 40) {
  if (Array.isArray(value)) {
    return value.length === 0 ? "liste vide" : `${value.length} valeur${value.length > 1 ? "s" : ""}`;
  }
  const texte = toLabel(value);
  return texte.length > limit ? `${texte.slice(0, limit)}…` : texte;
}

const plain = (text) =>
  (text ?? "").normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase();

/** Un paramètre répond-il à la recherche ? Nom, libellé et section. */
export function matches(spec, query) {
  if (!query.trim()) return true;
  const needle = plain(query);
  return [spec.name, spec.label, spec.group].some((value) => plain(value).includes(needle));
}

/** Les écarts d'un scénario, en une ligne lisible. */
export function summarise(values, limit = 3) {
  const entries = Object.entries(values ?? {});
  if (entries.length === 0) return "valeurs par défaut du modèle";

  const head = entries
    .slice(0, limit)
    .map(([name, value]) => `${name} = ${toLabel(value)}`)
    .join(" · ");
  return entries.length > limit ? `${head} · +${entries.length - limit}` : head;
}
