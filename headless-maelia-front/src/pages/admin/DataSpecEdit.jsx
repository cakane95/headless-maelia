import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import ConfirmDialog from "../../components/ConfirmDialog";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import DataSpecActions from "./components/DataSpecActions";
import DataSpecForm from "./components/DataSpecForm";
import NewSpecId from "./components/NewSpecId";

/** Décrire un type de fichier d'entrée.
 *
 *  Le formulaire couvre l'emplacement, la lecture, l'applicabilité et les
 *  champs : trop long pour une modale, il lui faut sa page.
 */
export default function DataSpecEdit() {
  const { specId } = useParams();
  const navigate = useNavigate();
  const catalog = "/admin/catalogue/entrees";
  const [doomed, setDoomed] = useState(false);
  const [newId, setNewId] = useState("");

  const existing = useAsync(
    () => (specId ? catalogApi.dataspec(specId) : Promise.resolve(false)),
    [specId],
  );

  async function submit(payload) {
    const id = specId ?? newId.trim();
    if (!id) throw new Error("un identifiant est nécessaire");
    await catalogApi.saveSpec(id, payload);
    navigate(catalog);
  }

  return (
    <>
      <p className="muted">
        <Link to={catalog}>← Catalogue des entrées</Link>
      </p>
      <div className="page-head">
        <div>
          <PageHeader
            title={specId ?? "Nouveau type de fichier"}
            lede="Ce que la plateforme réclamera aux projets, et comment elle lira le fichier."
          />
        </div>
        {existing.data && (
          <DataSpecActions
            spec={existing.data}
            onRestore={async () => {
              await catalogApi.restoreSpec(specId);
              existing.reload();
            }}
            onDelete={() => setDoomed(true)}
          />
        )}
      </div>

      <AsyncBoundary error={existing.error} loading={existing.loading}>
        {!specId && <NewSpecId value={newId} onChange={setNewId} />}
        <DataSpecForm
          spec={existing.data || null}
          onSubmit={submit}
          onCancel={() => navigate(catalog)}
        />
      </AsyncBoundary>

      {doomed && (
        <ConfirmDialog
          title="Supprimer ce type de fichier"
          message={`${specId} ne sera plus réclamé aux projets. Les fichiers déjà chargés restent.`}
          onConfirm={async () => {
            await catalogApi.deleteSpec(specId);
            navigate(catalog);
          }}
          onClose={() => setDoomed(false)}
        />
      )}
    </>
  );
}
