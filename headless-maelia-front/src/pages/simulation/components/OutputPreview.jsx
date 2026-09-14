import { useState } from "react";

import { resultApi } from "../../../api";
import AsyncBoundary from "../../../components/AsyncBoundary";
import Card from "../../../components/Card";
import { useAsync } from "../../../hooks/useAsync";

const ROWS = 30;

/** Premières lignes du fichier tracé. Repliée par défaut : elle sert à vérifier
 *  ce que le graphique agrège, pas à lire le fichier. */
export default function OutputPreview({ runId, fileName }) {
  const [open, setOpen] = useState(false);

  return (
    <Card title="Données brutes">
      <p>
        <button type="button" className="ghost" onClick={() => setOpen((o) => !o)}>
          {open ? "Masquer les lignes" : `Voir les ${ROWS} premières lignes`}
        </button>{" "}
        <a href={resultApi.downloadUrl(runId, fileName)} download>
          Télécharger le fichier
        </a>
      </p>
      {open && <PreviewTable runId={runId} fileName={fileName} />}
    </Card>
  );
}

function PreviewTable({ runId, fileName }) {
  const { data, error, loading } = useAsync(
    () => resultApi.preview(runId, fileName, ROWS),
    [runId, fileName],
  );

  return (
    <AsyncBoundary error={error} loading={loading}>
      <table>
        <thead>
          <tr>{data?.columns.map((name) => <th key={name}>{name}</th>)}</tr>
        </thead>
        <tbody>
          {data?.rows.map((row, index) => (
            <tr key={index}>
              {row.map((cell, column) => <td key={column}>{cell || "—"}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </AsyncBoundary>
  );
}
