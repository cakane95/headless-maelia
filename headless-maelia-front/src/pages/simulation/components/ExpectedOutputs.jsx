import { useState } from "react";

import Card from "../../../components/Card";
import EmptyState from "../../../components/EmptyState";
import Modal from "../../../components/Modal";
import { productionLabel } from "../../../utils/outputs";

/** Ce que le scénario écrira, et ce qu'il faudrait activer pour le reste.
 *
 *  MAELIA n'écrit rien par défaut. Sans cette annonce, on découvre à la fin
 *  d'un run d'une heure que le fichier attendu n'a jamais été demandé.
 */
export default function ExpectedOutputs({ expectations }) {
  const [browsing, setBrowsing] = useState(false);

  const produites = expectations.filter((entry) => entry.production === "PRODUCED");
  const possibles = expectations.filter((entry) => entry.production === "UNCERTAIN");
  const fichiers = [...produites, ...possibles].flatMap((entry) => entry.files);

  return (
    <Card
      title="Ce que ce scénario produira"
      lede="Le modèle n'écrit que ce qu'on lui demande : chaque sortie a son interrupteur."
      action={
        <button type="button" className="ghost" onClick={() => setBrowsing(true)}>
          Voir toutes les sorties
        </button>
      }
    >
      {fichiers.length === 0 ? (
        <EmptyState>
          Aucun fichier ne serait écrit. Activez une sortie dans les paramètres.
        </EmptyState>
      ) : (
        <>
          <p className="muted">
            {fichiers.length} fichier{fichiers.length > 1 ? "s" : ""} sur{" "}
            {expectations.length} sorties recensées.
          </p>
          <ul className="chips">
            {fichiers.map((name) => (
              <li key={name} className="chip">
                {name}
              </li>
            ))}
          </ul>
          {possibles.length > 0 && (
            <p className="muted">
              {possibles.length} sortie{possibles.length > 1 ? "s" : ""} dépend
              {possibles.length > 1 ? "ent" : ""} d'une condition interne au modèle : elle
              {possibles.length > 1 ? "s" : ""} peu{possibles.length > 1 ? "vent" : "t"} manquer.
            </p>
          )}
        </>
      )}

      {browsing && (
        <Modal title="Sorties du modèle" onClose={() => setBrowsing(false)} wide>
          <OutputInventory expectations={expectations} />
        </Modal>
      )}
    </Card>
  );
}

/** L'inventaire complet, avec le levier de chaque sortie éteinte. */
function OutputInventory({ expectations }) {
  const [query, setQuery] = useState("");
  const needle = query.trim().toLowerCase();
  const shown = expectations.filter(
    (entry) =>
      !needle ||
      `${entry.id} ${entry.label} ${entry.theme} ${entry.files.join(" ")}`
        .toLowerCase()
        .includes(needle),
  );

  return (
    <>
      <div className="filters">
        <input
          type="search"
          className="filters__search"
          value={query}
          placeholder="Rechercher une sortie ou un fichier…"
          aria-label="Rechercher une sortie"
          onChange={(event) => setQuery(event.target.value)}
        />
        <span className="filters__count">
          {shown.length} sortie{shown.length > 1 ? "s" : ""}
        </span>
      </div>

      <table>
        <thead>
          <tr>
            <th>Sortie</th>
            <th>Fichiers</th>
            <th>État</th>
            <th>À activer</th>
          </tr>
        </thead>
        <tbody>
          {shown.map((entry) => {
            const etat = productionLabel(entry.production);
            return (
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
                <td>
                  <span className={etat.tone ? `badge ${etat.tone}` : "badge"}>{etat.label}</span>
                </td>
                <td className="muted">
                  {entry.blocking.length > 0
                    ? entry.blocking.map((name) => <code key={name}>{name} </code>)
                    : "—"}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </>
  );
}
