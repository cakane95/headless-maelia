import { NavLink } from "react-router";

/** Navigation interne à un projet.
 *
 *  Ces rubriques n'ont pas de sens hors d'un projet : elles ne peuvent pas vivre
 *  dans la barre latérale, qui ignore le projet courant.
 */
export default function ProjectTabs({ projectId }) {
  const base = `/simulation/projets/${projectId}`;
  return (
    <nav className="tabs">
      <NavLink to={`${base}/donnees`}>Données d'entrée</NavLink>
      <NavLink to={`${base}/scenarios`}>Scénarios</NavLink>
      <NavLink to={`${base}/simulations`}>Simulations</NavLink>
    </nav>
  );
}
