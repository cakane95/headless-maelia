import { Outlet } from "react-router";

import Sidebar from "../components/Sidebar";
import { simulationNav } from "../routes/navigation";

/** Espace SIMULATION : exploiter un modèle sur un territoire. */
export default function SimulationLayout() {
  return (
    <>
      <Sidebar sections={simulationNav} />
      <main className="content">
        <Outlet />
      </main>
    </>
  );
}
