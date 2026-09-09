import { request } from "./client";

/** Catalogue des entrées et des paramètres — domaine ADMINISTRATION. */
export const catalogApi = {
  dataspecs: (module) =>
    request(`/api/v1/dataspecs${module ? `?module=${encodeURIComponent(module)}` : ""}`),
  dataspec: (id) => request(`/api/v1/dataspecs/${encodeURIComponent(id)}`),
  graph: () => request("/api/v1/dataspecs/graph"),
  parameters: () => request("/api/v1/parameters"),
};
