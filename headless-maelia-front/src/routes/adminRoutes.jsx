import { Route } from "react-router";

import AdminLayout from "../layouts/AdminLayout";
import Dashboard from "../pages/admin/Dashboard";
import DataSpecEdit from "../pages/admin/DataSpecEdit";
import InputCatalog from "../pages/admin/InputCatalog";
import Models from "../pages/admin/Models";
import OutputCatalog from "../pages/admin/OutputCatalog";
import OutputSpecEdit from "../pages/admin/OutputSpecEdit";
import ParameterCatalog from "../pages/admin/ParameterCatalog";
import ParameterSpecEdit from "../pages/admin/ParameterSpecEdit";
import RunDetail from "../pages/RunDetail";
import TestBench from "../pages/admin/TestBench";

/** Espace ADMINISTRATION : décrire et valider les modèles. */
export const adminRoutes = (
  <Route path="admin" element={<AdminLayout />}>
    <Route index element={<Dashboard />} />
    <Route path="modeles" element={<Models />} />
    <Route path="banc-essai" element={<TestBench />} />
    <Route path="banc-essai/:runId" element={<RunDetail />} />
    <Route path="catalogue/entrees" element={<InputCatalog />} />
    <Route path="catalogue/entrees/nouveau" element={<DataSpecEdit />} />
    <Route path="catalogue/entrees/:specId" element={<DataSpecEdit />} />
    <Route path="catalogue/parametres" element={<ParameterCatalog />} />
    <Route path="catalogue/parametres/:name" element={<ParameterSpecEdit />} />
    <Route path="catalogue/sorties" element={<OutputCatalog />} />
    <Route path="catalogue/sorties/:specId" element={<OutputSpecEdit />} />
  </Route>
);
