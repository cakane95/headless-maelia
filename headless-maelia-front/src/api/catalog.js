import { request } from "./client";

/** Catalogue des entrées et des paramètres — domaine ADMINISTRATION. */
export const catalogApi = {
  dataspecs: (module) =>
    request(`/api/v1/dataspecs${module ? `?module=${encodeURIComponent(module)}` : ""}`),
  dataspec: (id) => request(`/api/v1/dataspecs/${encodeURIComponent(id)}`),
  graph: () => request("/api/v1/dataspecs/graph"),
  parameters: () => request("/api/v1/parameters"),
  parameter: (name) => request(`/api/v1/parameters/${encodeURIComponent(name)}`),
  // Quels paramètres sont actifs pour ces écarts. La règle est évaluée par le
  // backend : le front grise, il ne décide pas.
  activation: (values) =>
    request("/api/v1/parameters/activation", {
      method: "POST",
      body: JSON.stringify(values ?? {}),
    }),
  saveParameter: (name, payload) =>
    request(`/api/v1/admin/parameters/${encodeURIComponent(name)}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    }),
  deleteParameter: (name) =>
    request(`/api/v1/admin/parameters/${encodeURIComponent(name)}`, { method: "DELETE" }),
  restoreParameter: (name) =>
    request(`/api/v1/admin/parameters/${encodeURIComponent(name)}/restore`, { method: "POST" }),
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

  // Sorties du modèle : ce qu'il peut écrire, et sous quelles conditions.
  outputs: (module) =>
    request(`/api/v1/outputs${module ? `?module=${encodeURIComponent(module)}` : ""}`),
  output: (id) => request(`/api/v1/outputs/${encodeURIComponent(id)}`),
  // Ce qu'un scénario portant ces écarts produirait. La condition est évaluée
  // par le backend : le front affiche, il ne décide pas.
  expectedOutputs: (values) =>
    request("/api/v1/outputs/expected", {
      method: "POST",
      body: JSON.stringify({ values: values ?? {} }),
    }),
  saveOutput: (id, payload) =>
    request(`/api/v1/admin/outputs/${encodeURIComponent(id)}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    }),
  deleteOutput: (id) =>
    request(`/api/v1/admin/outputs/${encodeURIComponent(id)}`, { method: "DELETE" }),
  restoreOutput: (id) =>
    request(`/api/v1/admin/outputs/${encodeURIComponent(id)}/restore`, { method: "POST" }),

  // Fichiers attendus par une configuration de modélisation donnée.
  applicable: (config) =>
    request("/api/v1/dataspecs/applicable", {
      method: "POST",
      body: JSON.stringify(config ?? {}),
    }),
};
