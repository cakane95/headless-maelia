import EmptyState from "../../../components/EmptyState";

/** Projets existants. Purement présentationnel. */
export default function ProjectsTable({ projects, onSelect }) {
  if (projects.length === 0) {
    return <EmptyState>Aucun projet pour l'instant. Créez-en un pour commencer.</EmptyState>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Territoire</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
        {projects.map((project) => (
          <tr key={project.id} className="clickable" onClick={() => onSelect(project.id)}>
            <td>{project.name}</td>
            <td><code>{project.territory}</code></td>
            <td className="muted">{project.description || "—"}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
