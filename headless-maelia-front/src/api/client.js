/** Socle réseau : URLs de base et enveloppe fetch. Aucun endpoint ici. */

export const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";
export const WS_URL = import.meta.env.VITE_WS_URL ?? "ws://localhost:8000";

/** Lève sur tout statut non-2xx, en remontant le `detail` RFC 7807 du backend. */
export async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(body.detail ? JSON.stringify(body.detail) : `HTTP ${response.status}`);
  }

  return response.json();
}
