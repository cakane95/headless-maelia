import { API_URL, request } from "./client";

const json = (method, body) => ({ method, body: JSON.stringify(body) });
const file = (name) => encodeURIComponent(name);

/** Sorties d'exécution : fichiers produits, profil des colonnes, séries à tracer. */
export const resultApi = {
  outputs: (runId) => request(`/api/v1/runs/${runId}/outputs`),
  // Les fichiers du run, confrontés à ce que ses réglages demandaient : un
  // fichier absent se distingue alors d'un fichier jamais demandé.
  review: (runId) => request(`/api/v1/runs/${runId}/output-review`),
  profile: (runId, name) => request(`/api/v1/runs/${runId}/outputs/${file(name)}/profile`),
  preview: (runId, name, limit = 50) =>
    request(`/api/v1/runs/${runId}/outputs/${file(name)}/preview?limit=${limit}`),
  text: (runId, name) => request(`/api/v1/runs/${runId}/outputs/${file(name)}/text`),
  series: (runId, name, query) =>
    request(`/api/v1/runs/${runId}/outputs/${file(name)}/series`, json("POST", query)),
  comparison: (projectId, payload) =>
    request(`/api/v1/projects/${projectId}/output-comparison`, json("POST", payload)),
  // Lectures enregistrées : une configuration de graphique, rejouable sur
  // n'importe quelle exécution du projet.
  views: (projectId) => request(`/api/v1/projects/${projectId}/output-views`),
  saveView: (projectId, payload) =>
    request(`/api/v1/projects/${projectId}/output-views`, json("POST", payload)),
  deleteView: (viewId) =>
    request(`/api/v1/output-views/${viewId}`, { method: "DELETE" }),

  // Téléchargement : le navigateur suit le lien lui-même, sans passer par fetch.
  downloadUrl: (runId, name) =>
    `${API_URL}/api/v1/runs/${runId}/outputs/${file(name)}/download`,
};
