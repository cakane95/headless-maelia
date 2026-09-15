import { lazy } from "react";
import { Route } from "react-router";

import ProjectLayout from "../layouts/ProjectLayout";
import SimulationShell from "../layouts/SimulationShell";
import RunDetail from "../pages/RunDetail";
import DatasetDetail from "../pages/simulation/DatasetDetail";
import DatasetEdit from "../pages/simulation/DatasetEdit";
import ProjectData from "../pages/simulation/ProjectData";
import ProjectImport from "../pages/simulation/ProjectImport";
import ProjectRuns from "../pages/simulation/ProjectRuns";
import ProjectSetup from "../pages/simulation/ProjectSetup";
import Projects from "../pages/simulation/Projects";
import ScenarioEdit from "../pages/simulation/ScenarioEdit";
import Scenarios from "../pages/simulation/Scenarios";

// Les résultats embarquent la bibliothèque de graphiques (~400 ko) : la charger
// à la demande garde le reste de l'application léger.
const RunResults = lazy(() => import("../pages/simulation/RunResults"));

/** Espace SIMULATION : exploiter un modèle sur un territoire.
 *
 *  Deux cadres volontairement distincts : la liste des projets occupe toute la
 *  largeur, sans barre latérale ; chaque projet reçoit la sienne, porteuse de
 *  ses propres rubriques — données, scénarios, simulations, résultats. */
export const simulationRoutes = (
  <Route path="simulation">
    <Route element={<SimulationShell />}>
      <Route index element={<Projects />} />
    </Route>
    <Route path="projets/:projectId" element={<ProjectLayout />}>
      <Route index element={<ProjectSetup />} />
      <Route path="initialisation" element={<ProjectSetup />} />
      <Route path="import" element={<ProjectImport />} />
      <Route path="donnees" element={<ProjectData />} />
      <Route path="donnees/:datasetId" element={<DatasetDetail />} />
      <Route path="donnees/:datasetId/edition" element={<DatasetEdit />} />
      <Route path="scenarios" element={<Scenarios />} />
      <Route path="scenarios/nouveau" element={<ScenarioEdit />} />
      <Route path="scenarios/:scenarioId" element={<ScenarioEdit />} />
      <Route path="simulations" element={<ProjectRuns />} />
      <Route path="simulations/:runId" element={<RunDetail />} />
      <Route path="simulations/:runId/resultats" element={<RunResults />} />
    </Route>
  </Route>
);
