/** Socle réseau : URLs de base et enveloppe fetch. Aucun endpoint ici. */

export const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";
export const WS_URL = import.meta.env.VITE_WS_URL ?? "ws://localhost:8000";

/** Message lisible d'une réponse RFC 7807.
 *
 *  Les `issues` portent le champ fautif et la raison : les perdre obligerait
 *  l'utilisateur à deviner lequel des 142 paramètres a été refusé.
 */
function problem(body, status) {
  const detail = typeof body.detail === "string" ? body.detail : `HTTP ${status}`;
  const issues = (body.issues ?? []).map((issue) => `${issue.field} : ${issue.message}`);
  return issues.length > 0 ? `${detail} — ${issues.join(" · ")}` : detail;
}

/** Lève sur tout statut non-2xx, en remontant le `detail` RFC 7807 du backend. */
export async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  if (!response.ok) {
    throw new Error(problem(await response.json().catch(() => ({})), response.status));
  }

  return response.json();
}

/** Envoi multipart : le navigateur pose lui-même le Content-Type avec sa frontière.
 *  Le fixer à la main casserait l'analyse côté serveur. */
export async function upload(path, formData) {
  const response = await fetch(`${API_URL}${path}`, { method: "POST", body: formData });
  if (!response.ok) {
    throw new Error(problem(await response.json().catch(() => ({})), response.status));
  }
  return response.json();
}
