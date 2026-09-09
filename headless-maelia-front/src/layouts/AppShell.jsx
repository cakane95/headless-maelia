import { NavLink, Outlet } from "react-router";

import ThemeToggle from "../components/ThemeToggle";

/**
 * Chrome commun aux deux espaces. Seul élément partagé : la bascule
 * Administration / Simulation, et le sélecteur de thème.
 */
export default function AppShell() {
  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand">
          headless<span>MAELIA</span>
        </div>
        <nav className="spaces">
          <NavLink to="/admin">Administration</NavLink>
          <NavLink to="/simulation">Simulation</NavLink>
        </nav>
        <ThemeToggle />
      </header>
      <div className="body">
        <Outlet />
      </div>
    </div>
  );
}
