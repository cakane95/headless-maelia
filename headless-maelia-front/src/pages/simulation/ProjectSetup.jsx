import { useState } from "react";
import { useNavigate, useParams } from "react-router";

import { projectApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Modal from "../../components/Modal";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import DataSummary from "./components/DataSummary";
import IdentityFacts from "./components/IdentityFacts";
import IdentityForm from "./components/IdentityForm";
import ModelingConfigForm from "./components/ModelingConfigForm";
import SetupSection from "./components/SetupSection";

/** Initialisation d'un projet : identité, configuration, données de départ.
 *
 *  L'ordre suit celui du travail réel : la configuration décide des fichiers
 *  attendus, l'import les fournit. L'import a sa propre page — il produit un
 *  compte rendu qui mérite mieux qu'un bloc en bas d'écran.
 */
export default function ProjectSetup() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const [editing, setEditing] = useState(false);
  const { data: project, error, loading, reload } = useAsync(
    () => projectApi.get(projectId), [projectId],
  );

  return (
    <>
      <PageHeader
        title="Initialisation"
        lede="Décrire le projet, activer les modules, puis charger les données."
      />

      <AsyncBoundary error={error} loading={loading}>
        {project && (
          <>
            <SetupSection
              title="Le projet"
              lede="Le territoire ne change pas : il détermine quelles données sont lues."
              action={
                <button type="button" className="ghost" onClick={() => setEditing(true)}>
                  Modifier
                </button>
              }
            >
              <IdentityFacts project={project} />
            </SetupSection>

            <SetupSection
              title="Configuration de modélisation"
              lede="Activer un module rend ses fichiers d'entrée obligatoires."
            >
              <ModelingConfigForm
                config={project.modeling_config}
                onSubmit={async (config) => {
                  await projectApi.configure(projectId, config);
                  reload();
                }}
              />
            </SetupSection>

            <SetupSection
              title="Données de départ"
              lede="Ce que le projet contient, au regard de ce que la configuration attend."
              action={
                <button
                  type="button"
                  onClick={() => navigate(`/simulation/projets/${projectId}/import`)}
                >
                  Importer des données
                </button>
              }
            >
              <DataSummary projectId={projectId} />
            </SetupSection>

            {editing && (
              <Modal title="Modifier le projet" onClose={() => setEditing(false)}>
                <IdentityForm
                  project={project}
                  onSaved={() => {
                    setEditing(false);
                    reload();
                  }}
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
