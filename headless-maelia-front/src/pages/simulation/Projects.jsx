import { useState } from "react";
import { useNavigate } from "react-router";

import { projectApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import EmptyState from "../../components/EmptyState";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ProjectForm from "./components/ProjectForm";

/** Projets du territoire : point d'entrée de l'espace Simulation. */
export default function Projects() {
  const navigate = useNavigate();
  const [version, setVersion] = useState(0);
  const { data: projects, error, loading } = useAsync(projectApi.list, [version]);

  async function create(payload) {
    const project = await projectApi.create(payload);
    setVersion((v) => v + 1);
    navigate(`/simulation/projets/${project.id}`);
  }

  return (
    <>
      <PageHeader
        title="Mes projets"
        lede="Un projet, c'est un territoire et une configuration de modélisation."
      />

      <Card title="Nouveau projet">
        <ProjectForm onSubmit={create} />
      </Card>

      <Card title="Projets">
        <AsyncBoundary error={error} loading={loading}>
          {projects?.length === 0 ? (
            <EmptyState>Aucun projet pour l'instant.</EmptyState>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Nom</th>
                  <th>Territoire</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
                {projects?.map((project) => (
                  <tr
                    key={project.id}
                    className="clickable"
                    onClick={() => navigate(`/simulation/projets/${project.id}`)}
                  >
                    <td>{project.name}</td>
                    <td>
                      <code>{project.territory}</code>
                    </td>
                    <td className="muted">{project.description ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </AsyncBoundary>
      </Card>
    </>
  );
}
