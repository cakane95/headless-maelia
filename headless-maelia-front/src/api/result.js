import { API_URL, request } from "./client";

const json = (method, body) => ({ method, body: JSON.stringify(body) });
const file = (name) => encodeURIComponent(name);

/** Sorties d'exécution : fichiers produits, profil des colonnes, séries à tracer. */
export const resultApi = {
  outputs: (runId) => request(`/api/v1/runs/${runId}/outputs`),
  profile: (runId, name) => request(`/api/v1/runs/${runId}/outputs/${file(name)}/profile`),
  preview: (runId, name, limit = 50) =>
    request(`/api/v1/runs/${runId}/outputs/${file(name)}/preview?limit=${limit}`),
  text: (runId, name) => request(`/api/v1/runs/${runId}/outputs/${file(name)}/text`),
  series: (runId, name, query) =>
    request(`/api/v1/runs/${runId}/outputs/${file(name)}/series`, json("POST", query)),
  comparison: (projectId, payload) =>
    request(`/api/v1/projects/${projectId}/output-comparison`, json("POST", payload)),
  // Téléchargement : le navigateur suit le lien lui-même, sans passer par fetch.
  downloadUrl: (runId, name) =>
    `${API_URL}/api/v1/runs/${runId}/outputs/${file(name)}/download`,
};
