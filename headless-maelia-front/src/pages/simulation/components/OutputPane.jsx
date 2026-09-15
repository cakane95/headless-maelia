import { resultApi } from "../../../api";
import Card from "../../../components/Card";
import EmptyState from "../../../components/EmptyState";
import OutputExplorer from "./OutputExplorer";
import OutputText from "./OutputText";

/** Le fichier choisi, lu selon ce qu'il est.
 *
 *  Un binaire n'est pas une impasse : il se télécharge. Dire « illisible » sans
 *  proposer le fichier laisserait l'utilisateur sans recours.
 */
export default function OutputPane({ projectId, runIds, file, view, onSaved }) {
  if (!file) {
    return (
      <Card>
        <EmptyState>Cette exécution n'a produit aucun fichier.</EmptyState>
      </Card>
    );
  }

  if (file.kind === "TABLE") {
    return (
      <OutputExplorer
        projectId={projectId}
        runIds={runIds}
        fileName={file.name}
        view={view}
        onSaved={onSaved}
      />
    );
  }
  if (file.kind === "TEXT") {
    return <OutputText runId={runIds[0]} fileName={file.name} />;
  }

  return (
    <Card title={file.name}>
      <p className="muted muted--first">Ce fichier ne se lit pas dans le navigateur.</p>
      <p>
        <a href={resultApi.downloadUrl(runIds[0], file.name)} download>
          Télécharger le fichier
        </a>
      </p>
    </Card>
  );
}
