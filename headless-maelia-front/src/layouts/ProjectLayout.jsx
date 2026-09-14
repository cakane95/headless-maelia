import { Outlet, useParams } from "react-router";

import Sidebar from "../components/Sidebar";
import { projectApi } from "../api";
import { useAsync } from "../hooks/useAsync";
import { projectNav } from "../routes/navigation";

/** Un projet choisi : la barre latérale porte ses rubriques.
 *
 *  Chaque projet a ses propres données, scénarios et résultats : la navigation
 *  est donc contextuelle, elle transporte l'identifiant du projet.
 */
export default function ProjectLayout() {
  const { projectId } = useParams();
  const { data: project } = useAsync(() => projectApi.get(projectId), [projectId]);

  return (
    <>
      <Sidebar sections={projectNav(projectId, project?.name)} backTo="/simulation" />
      <main className="content">
        <Outlet />
      </main>
    </>
  );
}
