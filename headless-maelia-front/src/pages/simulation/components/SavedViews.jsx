/** Les lectures enregistrées du projet.
 *
 *  Une figure de rapport n'est pas à reconstruire à chaque exécution : c'est le
 *  même graphique sur de nouvelles données. Une lecture porte son fichier, donc
 *  la choisir peut aussi changer de fichier.
 */
export default function SavedViews({ views, active, onApply, onDelete }) {
  if (views.length === 0) return null;

  return (
    <div className="saved">
      <span className="toolbar__label">Lectures enregistrées</span>
      <div className="chips">
        {views.map((view) => (
          <span key={view.id} className={view.id === active ? "chip chip--active" : "chip"}>
            <button type="button" onClick={() => onApply(view)}>{view.name}</button>
            <button
              type="button"
              className="chip__remove"
              aria-label={`Supprimer ${view.name}`}
              onClick={() => onDelete(view)}
            >
              ×
            </button>
          </span>
        ))}
      </div>
    </div>
  );
}
