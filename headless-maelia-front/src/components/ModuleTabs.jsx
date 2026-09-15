import { moduleLabel } from "../utils/status";

/** Onglets par module, avec une pastille de comptage.
 *
 *  Chaque écran décide de ce que la pastille dit — l'avancement des données
 *  d'un projet, le nombre de types de fichiers au catalogue. Le composant ne
 *  l'interprète pas : deux sens différents sous la même forme induiraient en
 *  erreur.
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
          {tab.badge && <span className="tab__count">{tab.badge}</span>}
        </button>
      ))}
    </div>
  );
}
