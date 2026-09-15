import EmptyState from "../../../components/EmptyState";
import FileStatusBadge from "../../../components/FileStatusBadge";

/** Les fichiers reçus pour un même type d'entrée.
 *
 *  La clé d'instance est ce qui les distingue : une année, un scénario
 *  climatique (`rcp8.5/2019.csv`). Elle vient du nom et du chemin du fichier
 *  dans l'archive, pas d'une saisie.
 */
export default function FamilyInstances({ instances, onOpen }) {
  if (instances.length === 0) {
    return <EmptyState>Aucun fichier reçu pour ce type d'entrée.</EmptyState>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>État</th>
          <th>Versions</th>
          <th className="cell--actions" />
        </tr>
      </thead>
      <tbody>
        {instances.map((instance) => {
          const courante = instance.versions?.find((v) => v.id === instance.current_version_id);
          return (
            <tr key={instance.id} className="clickable" onClick={() => onOpen(instance.id)}>
              <td><code>{instance.instance_key}</code></td>
              <td>
                <FileStatusBadge status={courante ? courante.status : "MISSING"} />
              </td>
              <td className="muted">{instance.versions?.length ?? 0}</td>
              <td className="cell--actions muted">Ouvrir →</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
