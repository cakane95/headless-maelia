import { request } from "./client";

/** Santé de la plateforme. */
export const healthApi = {
  dependencies: () => request("/api/v1/health/dependencies"),
};
