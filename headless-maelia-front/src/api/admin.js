import { request } from "./client";

/** Endpoints du domaine ADMINISTRATION. */
export const adminApi = {
  models: () => request("/api/v1/admin/models"),
  runs: () => request("/api/v1/admin/runs"),
  run: (id) => request(`/api/v1/admin/runs/${id}`),
  launch: (payload) =>
    request("/api/v1/admin/runs", { method: "POST", body: JSON.stringify(payload) }),
  cancel: (id) => request(`/api/v1/admin/runs/${id}/cancel`, { method: "POST" }),
};
