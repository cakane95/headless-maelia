import { Route } from "react-router";

import AdminLayout from "../layouts/AdminLayout";
import Placeholder from "../pages/Placeholder";
import Dashboard from "../pages/admin/Dashboard";
import InputCatalog from "../pages/admin/InputCatalog";
import Models from "../pages/admin/Models";
import RunDetail from "../pages/admin/RunDetail";
import TestBench from "../pages/admin/TestBench";
import * as attente from "../pages/admin/placeholders";

/** Espace ADMINISTRATION : décrire et valider les modèles. */
export const adminRoutes = (
  <Route path="admin" element={<AdminLayout />}>
    <Route index element={<Dashboard />} />
    <Route path="modeles" element={<Models />} />
    <Route path="banc-essai" element={<TestBench />} />
    <Route path="banc-essai/:runId" element={<RunDetail />} />
    <Route path="catalogue/entrees" element={<InputCatalog />} />
    <Route path="catalogue/parametres" element={<Placeholder {...attente.catalogueParametres} />} />
    <Route path="catalogue/sorties" element={<Placeholder {...attente.catalogueSorties} />} />
  </Route>
);
