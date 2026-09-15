/** Filtrage des paramètres : recherche, écarts seulement, remise à zéro.
 *
 *  Avec 142 paramètres, la recherche n'est pas un confort : sans elle, trouver
 *  `nbAnneesSimulation` demande de déplier quinze sections.
 */
export default function ParameterBar({
  query,
  onQuery,
  onlyModified,
  onOnlyModified,
  count,
  onResetAll,
}) {
  return (
    <div className="params-bar">
      <input
        type="search"
        className="params-bar__search"
        value={query}
        placeholder="Rechercher un paramètre…"
        aria-label="Rechercher un paramètre"
        onChange={(event) => onQuery(event.target.value)}
      />
      <label className="switch">
        <input
          type="checkbox"
          checked={onlyModified}
          onChange={(event) => onOnlyModified(event.target.checked)}
        />
        <span>Écarts seulement</span>
      </label>
      <span className="params-bar__count">
        {count === 0 ? "aucun écart" : `${count} écart${count > 1 ? "s" : ""}`}
      </span>
      {count > 0 && (
        <button type="button" className="ghost" onClick={onResetAll}>
          Tout rétablir
        </button>
      )}
    </div>
  );
}
