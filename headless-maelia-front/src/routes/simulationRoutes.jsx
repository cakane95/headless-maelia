import { Route } from "react-router";

import SimulationLayout from "../layouts/SimulationLayout";
import Placeholder from "../pages/Placeholder";
import DatasetDetail from "../pages/simulation/DatasetDetail";
import ProjectData from "../pages/simulation/ProjectData";
import ProjectRuns from "../pages/simulation/ProjectRuns";
import Projects from "../pages/simulation/Projects";
import Scenarios from "../pages/simulation/Scenarios";
import * as attente from "../pages/simulation/placeholders";

/** Espace SIMULATION : exploiter un modèle sur un territoire.
 *
 *  Les écrans d'un projet vivent sous /simulation/projets/:projectId — le projet
 *  est le contexte de tout ce qui suit (données, scénarios, exécutions). */
export const simulationRoutes = (
  <Route path="simulation" element={<SimulationLayout />}>
    <Route index element={<Projects />} />
    <Route path="projets/:projectId/donnees" element={<ProjectData />} />
    <Route path="projets/:projectId/donnees/:datasetId" element={<DatasetDetail />} />
    <Route path="projets/:projectId/scenarios" element={<Scenarios />} />
    <Route path="projets/:projectId/simulations" element={<ProjectRuns />} />
    <Route path="projets/:projectId" element={<ProjectData />} />
    <Route path="resultats" element={<Placeholder {...attente.resultats} />} />
  </Route>
);
