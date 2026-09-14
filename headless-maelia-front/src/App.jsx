import { Suspense } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router";

import AppShell from "./layouts/AppShell";
import { adminRoutes } from "./routes/adminRoutes";
import { simulationRoutes } from "./routes/simulationRoutes";

/**
 * Carte du site. Deux espaces, deux layouts :
 *   /admin      — décrire et valider les modèles
 *   /simulation — exploiter un modèle sur un territoire
 *
 * Le détail de chaque espace vit dans routes/ : ce fichier doit rester lisible
 * d'un coup d'œil.
 *
 * Le Suspense couvre les écrans chargés à la demande (routes/simulationRoutes).
 */
export default function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<p className="muted content">Chargement…</p>}>
        <Routes>
          <Route element={<AppShell />}>
            <Route index element={<Navigate to="/admin" replace />} />
            {adminRoutes}
            {simulationRoutes}
          </Route>
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
