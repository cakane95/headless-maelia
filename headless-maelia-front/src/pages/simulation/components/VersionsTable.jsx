import EmptyState from "../../../components/EmptyState";
import StatusBadge from "../../../components/StatusBadge";
import { fileStatusLabel } from "../../../utils/status";

const SOURCES = { UPLOAD: "Téléversement", EDIT: "Édition" };

/** Versions immuables d'un fichier. La courante est celle que suivent les
 *  scénarios qui n'épinglent rien. */
export default function VersionsTable({ versions, currentVersionId }) {
  if (!versions?.length) return <EmptyState>Aucune version publiée.</EmptyState>;

  return (
    <table>
      <thead>
        <tr>
          <th>N°</th>
          <th>Libellé</th>
          <th>Origine</th>
          <th>État</th>
          <th>Fichiers</th>
          <th>Courante</th>
        </tr>
      </thead>
      <tbody>
        {versions.map((version) => (
          <tr key={version.id}>
            <td>v{version.number}</td>
            <td>{version.label ?? "—"}</td>
            <td className="muted">{SOURCES[version.source] ?? version.source}</td>
            <td><StatusBadge status={version.status} label={fileStatusLabel(version.status)} /></td>
            <td className="muted">{version.files?.length ?? 0}</td>
            <td>{version.id === currentVersionId ? "✓" : ""}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
