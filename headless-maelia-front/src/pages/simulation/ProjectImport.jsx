import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";

import { datasetApi } from "../../api";
import PageHeader from "../../components/PageHeader";
import ArchiveDropZone from "./components/ArchiveDropZone";
import ImportReport from "./components/ImportReport";
import SetupSection from "./components/SetupSection";

/** Import d'une archive de données d'entrée, sur son propre écran.
 *
 *  L'import a sa page parce qu'il a un avant et un après : ce qu'on dépose, et
 *  le compte rendu, fichier par fichier. Coincé dans un bloc de la page
 *  d'initialisation, ce compte rendu passait sous la ligne de flottaison.
 */
export default function ProjectImport() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const setup = `/simulation/projets/${projectId}/initialisation`;
  const [report, setReport] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function send(file) {
    if (!file) return;
    setBusy(true);
    setError(null);
    setReport(null);
    try {
      setReport(await datasetApi.importArchive(projectId, file, "Initialisation"));
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <p className="muted">
        <Link to={setup}>← Initialisation</Link>
      </p>
      <PageHeader
        title="Importer des données"
        lede="Une archive, autant de fichiers d'entrée reconnus par leur nom."
      />

      {report ? (
        <SetupSection
          title="Compte rendu"
          lede={`${report.imported} fichier(s) importé(s) sur ${report.analysed} analysé(s).`}
          action={
            <>
              <button type="button" className="ghost" onClick={() => setReport(null)}>
                Importer une autre archive
              </button>{" "}
              <button type="button" onClick={() => navigate(setup)}>Terminer</button>
            </>
          }
        >
          <ImportReport report={report} projectId={projectId} />
        </SetupSection>
      ) : (
        <SetupSection
          title="Votre archive"
          lede="Chaque fichier est apparié au catalogue par son nom, importé puis validé."
        >
          <ArchiveDropZone busy={busy} onFile={send} />
          {error && <p className="error">{error}</p>}

          <ul className="notes">
            <li>L'arborescence de l'archive est ignorée : zippez comme vous voulez.</li>
            <li>Un shapefile voyage complet : <code>.shp</code>, <code>.shx</code>, <code>.dbf</code>, <code>.prj</code>.</li>
            <li>Un fichier en échec n'interrompt pas les autres — le compte rendu le nomme.</li>
            <li>Un fichier déjà présent devient une nouvelle version, l'ancienne est conservée.</li>
          </ul>
        </SetupSection>
      )}
    </>
  );
}
