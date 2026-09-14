import { useEffect, useState } from "react";
import { NavLink, useLocation } from "react-router";

/**
 * Barre latérale des deux espaces. Sous 1024 px elle devient un tiroir :
 * l'application vise le poste de travail, mais doit rester utilisable en mobilité.
 */
export default function Sidebar({ sections, backTo }) {
  const [open, setOpen] = useState(false);
  const { pathname } = useLocation();

  // Referme le tiroir après navigation : sinon il masque l'écran demandé.
  useEffect(() => setOpen(false), [pathname]);

  return (
    <>
      <button
        type="button"
        className="drawer-toggle"
        aria-label="Ouvrir la navigation"
        aria-expanded={open}
        onClick={() => setOpen(true)}
      >
        <span aria-hidden="true">☰</span>
      </button>

      {open && <div className="drawer-overlay" onClick={() => setOpen(false)} />}

      <aside className={`sidebar${open ? " sidebar--open" : ""}`}>
        {backTo && (
          <NavLink to={backTo} end className="sidebar__back">
            ← Tous les projets
          </NavLink>
        )}
        {sections.map((section) => (
          <div className="sidebar__group" key={section.title}>
            <h2>{section.title}</h2>
            <nav>
              {section.links.map((link) => (
                <NavLink key={link.to} to={link.to} end={link.end}>
                  {link.label}
                </NavLink>
              ))}
            </nav>
          </div>
        ))}
      </aside>
    </>
  );
}
