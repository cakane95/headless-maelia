import { useState } from "react";
import { useNavigate } from "react-router";

import { projectApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Modal from "../../components/Modal";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ProjectForm from "./components/ProjectForm";
import ProjectsTable from "./components/ProjectsTable";

/** Liste des projets — porte d'entrée de l'espace Simulation.
 *
 *  Écran sans barre latérale : tant qu'aucun projet n'est choisi, les rubriques
 *  (données, scénarios, résultats) n'auraient pas de contexte.
 */
export default function Projects() {
  const navigate = useNavigate();
  const [creating, setCreating] = useState(false);
  const { data: projects, error, loading } = useAsync(projectApi.list);

  const open = (id) => navigate(`/simulation/projets/${id}/initialisation`);

  async function create(payload) {
    // Un projet neuf s'ouvre sur son initialisation : c'est l'étape suivante.
    open((await projectApi.create(payload)).id);
  }

  return (
    <>
      <div className="page-head">
        <div>
          <PageHeader
            title="Mes projets"
            lede="Un projet, c'est un territoire et une configuration de modélisation."
          />
        </div>
        <button type="button" onClick={() => setCreating(true)}>Nouveau projet</button>
      </div>

      <Card>
        <AsyncBoundary error={error} loading={loading}>
          <ProjectsTable projects={projects ?? []} onSelect={open} />
        </AsyncBoundary>
      </Card>

      {creating && (
        <Modal title="Nouveau projet" onClose={() => setCreating(false)}>
          <ProjectForm onSubmit={create} onCancel={() => setCreating(false)} />
        </Modal>
      )}
    </>
  );
}
