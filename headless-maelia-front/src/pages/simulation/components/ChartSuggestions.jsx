/** Lectures proposées par la plateforme pour ce fichier.
 *
 *  Un fichier de sortie arrive sans configuration et personne n'en écrira une à
 *  la main : le backend déduit ces graphiques de la forme du tableau. Ils
 *  servent de point de départ, l'utilisateur ajuste ensuite.
 */
export default function ChartSuggestions({ suggestions, activeTitle, onPick }) {
  if (suggestions.length === 0) return null;

  return (
    <div className="chips">
      {suggestions.map((suggestion) => (
        <button
          key={suggestion.title}
          type="button"
          className={suggestion.title === activeTitle ? "chip chip--active" : "chip"}
          title={suggestion.reason}
          onClick={() => onPick(suggestion)}
        >
          {suggestion.title}
        </button>
      ))}
    </div>
  );
}
