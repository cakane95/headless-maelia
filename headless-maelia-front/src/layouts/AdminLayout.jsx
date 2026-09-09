import { Outlet } from "react-router";

import Sidebar from "../components/Sidebar";
import { adminNav } from "../routes/navigation";

/** Espace ADMINISTRATION : décrire et valider les modèles. */
export default function AdminLayout() {
  return (
    <>
      <Sidebar sections={adminNav} />
      <main className="content">
        <Outlet />
      </main>
    </>
  );
}
