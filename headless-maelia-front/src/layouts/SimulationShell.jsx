import { Outlet } from "react-router";

/** Espace SIMULATION hors projet : la liste des projets occupe toute la largeur.
 *
 *  Pas de barre latérale ici — les rubriques (données, scénarios, résultats)
 *  n'ont de sens qu'à l'intérieur d'un projet, et une barre grisée avant d'en
 *  avoir choisi un n'apprendrait rien.
 */
export default function SimulationShell() {
  return (
    <main className="content">
      <Outlet />
    </main>
  );
}
