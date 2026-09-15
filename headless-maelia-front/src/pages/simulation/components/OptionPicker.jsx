import { useState } from "react";
import { useParams } from "react-router";

import { scenarioApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import EmptyState from "../../../components/EmptyState";
import Modal from "../../../components/Modal";
import { useAsync } from "../../../hooks/useAsync";

/** Choisir une ou plusieurs valeurs parmi celles que le projet contient.
 *
 *  Les valeurs sont lues dans les données du projet, pas saisies de mémoire :
 *  un identifiant de parcelle inventé ne se voit qu'au bout d'une simulation.
 *  Le chargement est différé à l'ouverture — inutile d'aller chercher 749
 *  identifiants pour un champ que personne ne touchera.
 */
export default function OptionPicker({ spec, selected, multiple, onChange, onClose }) {
  const { projectId } = useParams();
  const [query, setQuery] = useState("");
  const [picked, setPicked] = useState(selected);
  const { data, error, loading } = useAsync(
    () => scenarioApi.parameterOptions(projectId, spec.name),
    [projectId, spec.name],
  );

  const values = data?.values ?? [];
  const shown = values.filter((value) => value.toLowerCase().includes(query.toLowerCase()));

  function toggle(value) {
    if (!multiple) return setPicked([value]);
    setPicked(picked.includes(value) ? picked.filter((v) => v !== value) : [...picked, value]);
  }

  function confirm() {
    onChange(multiple ? picked : (picked[0] ?? ""));
    onClose();
  }

  return (
    <Modal title={spec.label} onClose={onClose}>
      <AsyncBoundary error={error} loading={loading}>
        {data?.available === false ? (
          <EmptyState>{data.message}</EmptyState>
        ) : (
          <>
            <p className="muted muted--first">
              {values.length} valeurs {data?.field ? "dans " : "issues de "}
              <code>{data?.field ?? data?.data_spec_id}</code> · {picked.length} retenue
              {picked.length > 1 ? "s" : ""}
              {data?.truncated && " · liste tronquée"}
            </p>

            <input
              type="search"
              value={query}
              placeholder="Filtrer…"
              aria-label="Filtrer les valeurs"
              onChange={(event) => setQuery(event.target.value)}
              // La modale s'ouvre à l'intérieur du formulaire du scénario :
              // sans cela, Entrée l'enregistrerait au lieu de filtrer.
              onKeyDown={(event) => event.key === "Enter" && event.preventDefault()}
            />

            {multiple && (
              <p className="options__bulk">
                <button type="button" className="link" onClick={() => setPicked(shown)}>
                  Tout sélectionner{query && " (filtre)"}
                </button>{" "}
                <button type="button" className="link" onClick={() => setPicked([])}>
                  Aucun
                </button>
              </p>
            )}

            <ul className="options">
              {shown.map((value) => (
                <li key={value}>
                  <label className="switch">
                    <input
                      type={multiple ? "checkbox" : "radio"}
                      name={spec.name}
                      checked={picked.includes(value)}
                      onChange={() => toggle(value)}
                    />
                    <span>{value}</span>
                  </label>
                </li>
              ))}
              {shown.length === 0 && <li className="muted">Aucune valeur ne correspond.</li>}
            </ul>
          </>
        )}
      </AsyncBoundary>

      <p className="form-actions">
        <button type="button" onClick={confirm} disabled={data?.available === false}>
          Valider
        </button>
        <button type="button" className="ghost" onClick={onClose}>Annuler</button>
      </p>
    </Modal>
  );
}
