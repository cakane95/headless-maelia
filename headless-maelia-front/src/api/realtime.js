import { WS_URL } from "./client";

/**
 * Flux temps réel d'une exécution.
 * Renvoie la fonction de fermeture — à appeler dans le nettoyage de l'effet.
 */
export function subscribeRun(runId, onMessage) {
  const socket = new WebSocket(`${WS_URL}/ws/runs/${runId}`);
  socket.onmessage = (event) => onMessage(JSON.parse(event.data));
  return () => socket.close();
}
