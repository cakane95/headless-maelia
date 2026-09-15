/** Ce que le graphique montre, et quoi en faire.
 *
 *  La phrase de résumé n'est pas décorative : sans elle, rien ne distingue une
 *  somme d'une moyenne, ni ne rappelle quel filtre est actif.
 */
export default function ChartHead({ summary, tuning, exportable, onTune, onExport, save }) {
  return (
    <div className="chart-head">
      <p className="chart-head__summary">{summary}</p>
      <span className="chart-head__actions">
        <button
          type="button"
          className={tuning ? "ghost ghost--on" : "ghost"}
          aria-expanded={tuning}
          onClick={onTune}
        >
          Réglages
        </button>
        <button type="button" className="ghost" disabled={!exportable} onClick={onExport}>
          Exporter
        </button>
        {save}
      </span>
    </div>
  );
}
