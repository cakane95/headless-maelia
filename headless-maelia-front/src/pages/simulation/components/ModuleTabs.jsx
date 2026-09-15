import { moduleLabel } from "../../../utils/status";

/** Onglets des modules, avec l'avancement de chacun.
 *
 *  Le compte porté par l'onglet évite d'avoir à l'ouvrir pour savoir s'il reste
 *  quelque chose à charger : c'est la question qu'on se pose sur cet écran.
 */
export default function ModuleTabs({ tabs, active, onSelect }) {
  return (
    <div className="tabs" role="tablist">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          role="tab"
          aria-selected={tab.id === active}
          className={tab.id === active ? "tab tab--active" : "tab"}
          onClick={() => onSelect(tab.id)}
        >
          {tab.id === "all" ? "Tous" : moduleLabel(tab.id)}
          <span className="tab__count">{tab.supplied}/{tab.expected}</span>
        </button>
      ))}
    </div>
  );
}
