import { request } from "./client";

/** Catalogue des entrées et des paramètres — domaine ADMINISTRATION. */
export const catalogApi = {
  dataspecs: (module) =>
    request(`/api/v1/dataspecs${module ? `?module=${encodeURIComponent(module)}` : ""}`),
  dataspec: (id) => request(`/api/v1/dataspecs/${encodeURIComponent(id)}`),
  graph: () => request("/api/v1/dataspecs/graph"),
  parameters: () => request("/api/v1/parameters"),
  // Écriture — administration. Toute modification bascule la spec en USER : le
  // catalogue de référence ne l'écrasera plus.
  saveSpec: (id, payload) =>
    request(`/api/v1/admin/dataspecs/${encodeURIComponent(id)}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    }),
  deleteSpec: (id) =>
    request(`/api/v1/admin/dataspecs/${encodeURIComponent(id)}`, { method: "DELETE" }),
  restoreSpec: (id) =>
    request(`/api/v1/admin/dataspecs/${encodeURIComponent(id)}/restore`, { method: "POST" }),

  // Fichiers attendus par une configuration de modélisation donnée.
  applicable: (config) =>
    request("/api/v1/dataspecs/applicable", {
      method: "POST",
      body: JSON.stringify(config ?? {}),
    }),
};
