import { useState } from "react";
import { useParams } from "react-router";

import { projectApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Modal from "../../components/Modal";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ArchiveUpload from "./components/ArchiveUpload";
import IdentityCard from "./components/IdentityCard";
import IdentityForm from "./components/IdentityForm";
import ModelingConfigForm from "./components/ModelingConfigForm";

/** Initialisation d'un projet : identité, configuration, données de départ.
 *
 *  L'ordre des blocs suit celui du travail réel : la configuration décide des
 *  fichiers attendus, l'archive les fournit.
 */
export default function ProjectSetup() {
  const { projectId } = useParams();
  const [editing, setEditing] = useState(false);
  const { data: project, error, loading, reload } = useAsync(
    () => projectApi.get(projectId), [projectId],
  );

  function saved() {
    setEditing(false);
    reload();
  }

  return (
    <>
      <PageHeader
        title="Initialisation"
        lede="Décrire le projet, activer les modules, puis charger les données."
      />

      <AsyncBoundary error={error} loading={loading}>
        {project && (
          <>
            <IdentityCard project={project} onEdit={() => setEditing(true)} />

            <Card title="Configuration de modélisation">
              <ModelingConfigForm
                config={project.modeling_config}
                onSubmit={async (config) => {
                  await projectApi.configure(projectId, config);
                  reload();
                }}
              />
            </Card>

            <Card title="Données de départ">
              <ArchiveUpload projectId={projectId} onImported={reload} />
            </Card>

            {editing && (
              <Modal title="Modifier le projet" onClose={() => setEditing(false)}>
                <IdentityForm
                  project={project}
                  onSaved={saved}
                  onCancel={() => setEditing(false)}
                />
              </Modal>
            )}
          </>
        )}
      </AsyncBoundary>
    </>
  );
}
