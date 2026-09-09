/** Point d'entrée unique du réseau : rien d'autre dans l'application n'appelle
 *  `fetch` ni n'ouvre de WebSocket. */
export { adminApi } from "./admin";
export { catalogApi } from "./catalog";
export { healthApi } from "./health";
export { subscribeRun } from "./realtime";
export { datasetApi, projectApi, projectRunApi, scenarioApi } from "./simulation";
