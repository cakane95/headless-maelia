import { Link } from "react-router";

import Card from "../../../components/Card";

/** Fichiers que le projet détient mais que sa configuration n'attend pas.
 *
 *  Une archive de territoire en apporte : les séries climatiques simulées ne
 *  servent que si un scénario climatique est demandé. Les taire donnerait à
 *  croire qu'ils n'ont pas été importés — ils sont bien là, simplement inutiles
 *  en l'état.
 */
export default function UnexpectedData({ groups, projectId }) {
  if (groups.length === 0) return null;

  return (
    <Card title="Hors configuration actuelle">
      <p className="muted muted--first">
        Ces fichiers sont chargés mais la configuration de modélisation ne les
        réclame pas. Activer le module ou le réglage correspondant les remettra
        en jeu.
      </p>
      <table>
        <thead>
          <tr>
            <th>Type d'entrée</th>
            <th>Fichiers</th>
            <th className="cell--actions" />
          </tr>
        </thead>
        <tbody>
          {groups.map((group) => (
            <tr key={group.specId}>
              <td><code>{group.specId}</code></td>
              <td className="muted">{group.count}</td>
              <td className="cell--actions">
                <Link
                  to={
                    group.count > 1 || group.instance
                      ? `/simulation/projets/${projectId}/donnees/famille/${encodeURIComponent(group.specId)}`
                      : `/simulation/projets/${projectId}/donnees/${group.datasetId}`
                  }
                >
                  Ouvrir →
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Card>
  );
}
