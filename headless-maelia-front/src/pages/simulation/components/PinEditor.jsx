/** Épinglage des versions.
 *
 *  On n'épingle que ce qui doit varier : un fichier laissé sur « dernière
 *  version valide » suit les corrections, ce qui est presque toujours voulu.
 */
export default function PinEditor({ datasets, pins, onChange }) {
  if (!datasets?.length) return <p className="muted">Aucun jeu de données dans ce projet.</p>;

  function update(datasetId, versionId) {
    const next = { ...pins };
    if (versionId) next[datasetId] = versionId;
    else delete next[datasetId];
    onChange(next);
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Fichier</th>
          <th>Version utilisée</th>
        </tr>
      </thead>
      <tbody>
        {datasets.map((dataset) => (
          <tr key={dataset.id}>
            <td>{dataset.instance_key ?? dataset.data_spec_id}</td>
            <td>
              <select
                value={pins[dataset.id] ?? ""}
                onChange={(e) => update(dataset.id, e.target.value)}
              >
                <option value="">Dernière version valide</option>
                {dataset.versions.map((v) => (
                  <option key={v.id} value={v.id}>
                    v{v.number}{v.label ? ` — ${v.label}` : ""}
                  </option>
                ))}
              </select>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
