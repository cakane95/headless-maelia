import { useState } from "react";

import Card from "../../../components/Card";
import Modal from "../../../components/Modal";

/** Pourquoi tel fichier est là, et pourquoi tel autre ne l'est pas.
 *
 *  Sans ce croisement, un fichier absent ne se distingue pas d'un fichier
 *  jamais demandé — et l'on cherche dans le modèle une panne qui n'existe pas.
 *  Replié par défaut : quand tout est conforme, il n'y a rien à lire.
 */
export default function OutputReview({ review }) {
  const [browsing, setBrowsing] = useState(false);
  if (!review) return null;

  const { produced, missing, undeclared, available } = review;
  const conforme = missing.length === 0 && undeclared.length === 0;

  return (
    <Card
      title="Sorties de cette exécution"
      lede={
        conforme
          ? `${produced.length} fichier${produced.length > 1 ? "s" : ""} — conforme à ce que le scénario demandait.`
          : "Des écarts entre ce qui était demandé et ce qui a été écrit."
      }
      action={
        available.length > 0 && (
          <button type="button" className="ghost" onClick={() => setBrowsing(true)}>
            {available.length} sortie{available.length > 1 ? "s" : ""} non demandée
            {available.length > 1 ? "s" : ""}
          </button>
        )
      }
    >
      {missing.length > 0 && (
        <Alert tone="INVALID" title="Demandés, mais absents">
          <p className="muted">
            Le scénario activait ces sorties et le run ne les a pas écrites. La cause est
            dans le modèle ou dans les données d'entrée, pas dans les réglages.
          </p>
          <ul className="chips">
            {missing.map((name) => (
              <li key={name} className="chip">
                {name}
              </li>
            ))}
          </ul>
        </Alert>
      )}

      {undeclared.length > 0 && (
        <Alert tone="DRAFT" title="Écrits sans être au catalogue">
          <p className="muted">
            Le modèle a produit ces fichiers sans que le catalogue les connaisse. Ils
            sont exploitables ici, mais aucun scénario ne peut les annoncer :
            à recenser côté administration.
          </p>
          <ul className="chips">
            {undeclared.map((name) => (
              <li key={name} className="chip">
                {name}
              </li>
            ))}
          </ul>
        </Alert>
      )}

      {browsing && (
        <Modal title="Sorties non demandées" onClose={() => setBrowsing(false)} wide>
          <p className="muted">
            Pour obtenir ces fichiers, reprenez le scénario et activez les paramètres
            indiqués, puis relancez.
          </p>
          <table>
            <thead>
              <tr>
                <th>Sortie</th>
                <th>Fichiers</th>
                <th>À activer</th>
              </tr>
            </thead>
            <tbody>
              {available.map((entry) => (
                <tr key={entry.id}>
                  <td>
                    <code>{entry.id}</code>
                    <em className="row__note">{entry.theme}</em>
                  </td>
                  <td className="muted">
                    {entry.files.map((name) => (
                      <div key={name}>{name}</div>
                    ))}
                  </td>
                  <td className="muted">
                    {entry.blocking.map((name) => (
                      <code key={name}>{name} </code>
                    ))}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Modal>
      )}
    </Card>
  );
}

function Alert({ tone, title, children }) {
  return (
    <div className="notice">
      <span className={`badge ${tone}`}>{title}</span>
      {children}
    </div>
  );
}
