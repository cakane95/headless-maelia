import { useRef, useState } from "react";

import { datasetApi } from "../../../api";
import ImportReport from "./ImportReport";

/** Initialisation en masse : une archive ZIP de fichiers d'entrée.
 *
 *  Chaque fichier est apparié au catalogue par son nom ; les fichiers d'un
 *  shapefile sont regroupés avec leur `.shp`. L'arborescence de l'archive est
 *  ignorée — chacun zippe son dossier comme il l'entend.
 */
export default function ArchiveUpload({ projectId, onImported }) {
  const input = useRef(null);
  const [report, setReport] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  async function send(file) {
    if (!file) return;
    setBusy(true);
    setError(null);
    setReport(null);
    try {
      const result = await datasetApi.importArchive(projectId, file, "Initialisation");
      setReport(result);
      onImported?.();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
      if (input.current) input.current.value = "";
    }
  }

  return (
    <>
      <p className="muted muted--first">
        Déposez une archive <strong>.zip</strong> de vos fichiers d'entrée (CSV et
        shapefiles <code>.shp/.shx/.dbf</code>). Chaque fichier est reconnu par son
        nom, importé puis validé. Un fichier en échec n'interrompt pas les autres.
      </p>

      <input
        ref={input}
        type="file"
        accept=".zip"
        hidden
        onChange={(e) => send(e.target.files?.[0])}
      />
      <button type="button" onClick={() => input.current?.click()} disabled={busy}>
        {busy ? "Import en cours…" : "Importer une archive ZIP"}
      </button>

      {error && <p className="error">{error}</p>}
      {report && <ImportReport report={report} projectId={projectId} />}
    </>
  );
}
