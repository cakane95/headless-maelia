import { useState } from "react";

import ConfirmDialog from "./ConfirmDialog";

/** Arrêter une exécution en cours.
 *
 *  L'arrêt n'est pas instantané : l'état passe en base, le worker le voit entre
 *  deux messages de GAMA et envoie alors `stop` sur sa session ouverte. Quelques
 *  secondes s'écoulent — la confirmation le dit, plutôt que de laisser croire à
 *  un clic sans effet.
 */
export default function StopRun({ run, onStop }) {
  const [asking, setAsking] = useState(false);

  if (run.status !== "PENDING" && run.status !== "RUNNING") return null;

  return (
    <>
      <button type="button" className="ghost" onClick={() => setAsking(true)}>
        Arrêter
      </button>

      {asking && (
        <ConfirmDialog
          title="Arrêter cette exécution"
          message={
            "La simulation s'interrompra dans les secondes qui viennent. " +
            "Aucun fichier de sortie ne sera écrit : le modèle ne les produit " +
            "qu'en fin de période simulée."
          }
          confirmLabel="Arrêter"
          onConfirm={() => onStop(run.id)}
          onClose={() => setAsking(false)}
        />
      )}
    </>
  );
}
