/** Un module de modélisation : ce qu'il active, en une phrase.
 *
 *  Le libellé seul ne disait pas ce qu'on gagnait — ni ce qu'on devrait
 *  fournir en retour. Activer un module rend ses fichiers obligatoires.
 */
export default function ModuleToggle({ label, description, checked, onChange }) {
  return (
    <label className={checked ? "module module--on" : "module"}>
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span className="module__text">
        <b>{label}</b>
        <small>{description}</small>
      </span>
    </label>
  );
}
