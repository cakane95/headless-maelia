import { request, upload } from "./client";

const json = (method, body) => ({ method, body: JSON.stringify(body) });

/** Projets, données, scénarios et exécutions — domaine SIMULATION. */
export const projectApi = {
  list: () => request("/api/v1/projects"),
  update: (id, payload) => request(`/api/v1/projects/${id}`, json("PUT", payload)),
  remove: (id) => request(`/api/v1/projects/${id}`, { method: "DELETE" }),
  get: (id) => request(`/api/v1/projects/${id}`),
  create: (payload) => request("/api/v1/projects", json("POST", payload)),
  territories: () => request("/api/v1/territories"),
  defaultConfiguration: () => request("/api/v1/default-configuration"),
  configure: (id, config) =>
    request(`/api/v1/projects/${id}/modeling-configuration`, json("PUT", config)),
  completion: (id) => request(`/api/v1/projects/${id}/completion`),
};

export const datasetApi = {
  importArchive: (projectId, file, label) => {
    const form = new FormData();
    form.append("file", file);
    if (label) form.append("label", label);
    return upload(`/api/v1/projects/${projectId}/datasets/import-archive`, form);
  },
  uploadVersion: (projectId, dataSpecId, files, extra = {}) => {
    const form = new FormData();
    for (const file of files) form.append("files", file);
    for (const [k, v] of Object.entries(extra)) if (v) form.append(k, v);
    return upload(`/api/v1/projects/${projectId}/datasets/${dataSpecId}/versions`, form);
  },
  listForProject: (projectId) => request(`/api/v1/projects/${projectId}/datasets`),
  get: (id) => request(`/api/v1/datasets/${id}`),
  records: (id, version) => request(`/api/v1/datasets/${id}/versions/${version}/records`),
  issues: (id, version) => request(`/api/v1/datasets/${id}/versions/${version}/issues`),
  draft: (id) => request(`/api/v1/datasets/${id}/draft`),
  saveDraft: (id, rows) => request(`/api/v1/datasets/${id}/draft`, json("PUT", { rows })),
  publish: (id, payload) =>
    request(`/api/v1/datasets/${id}/draft/publish`, json("POST", payload)),
};

export const scenarioApi = {
  listForProject: (projectId) => request(`/api/v1/projects/${projectId}/scenarios`),
  get: (id) => request(`/api/v1/scenarios/${id}`),
  create: (projectId, payload) =>
    request(`/api/v1/projects/${projectId}/scenarios`, json("POST", payload)),
  update: (id, payload) => request(`/api/v1/scenarios/${id}`, json("PUT", payload)),
  remove: (id) => request(`/api/v1/scenarios/${id}`, { method: "DELETE" }),
  gamaParameters: (id) => request(`/api/v1/scenarios/${id}/gama-parameters`),
};

export const projectRunApi = {
  list: (projectId) => request(`/api/v1/projects/${projectId}/runs`),
  launch: (projectId, payload) =>
    request(`/api/v1/projects/${projectId}/runs`, json("POST", payload)),
};
