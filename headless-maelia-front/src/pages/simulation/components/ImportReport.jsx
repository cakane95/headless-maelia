import { Link } from "react-router";

import StatGroup from "../../../components/StatGroup";

const LABELS = {
  IMPORTED: "Importé",
  INVALID: "À corriger",
  IGNORED: "Non reconnu",
  ERROR: "Refusé",
};

/** Sort de chaque entrée de l'archive. */
export default function ImportReport({ report, projectId }) {
  const problems = report.entries.filter((e) => e.outcome !== "IMPORTED");

  return (
    <div className="report">
      <StatGroup
        items={[
          { label: "Analysés", value: report.analysed },
          { label: "Importés", value: report.imported },
          { label: "À corriger", value: report.invalid },
          { label: "Non reconnus", value: report.ignored },
          { label: "Refusés", value: report.errors },
        ]}
      />

      {problems.length === 0 ? (
        <p className="muted">Toutes les entrées ont été importées et validées.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Fichier(s)</th>
              <th>Sort</th>
              <th>Détail</th>
            </tr>
          </thead>
          <tbody>
            {problems.map((entry, index) => (
              <tr key={`${entry.data_spec_id ?? "?"}-${index}`}>
                <td className="muted">{entry.file_names.join(", ")}</td>
                <td>
                  <span className={`badge ${entry.outcome === "INVALID" ? "DRAFT" : ""}`}>
                    {LABELS[entry.outcome] ?? entry.outcome}
                  </span>
                </td>
                <td className="muted">
                  {entry.message
                    ?? (entry.issues
                      ? <Link to={`/simulation/projets/${projectId}/donnees/${entry.dataset_id}`}>
                          {entry.issues} problème(s) de validation
                        </Link>
                      : "—")}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
