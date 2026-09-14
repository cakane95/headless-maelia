/** Rendu d'un fichier transposé : un champ par ligne, une entité par colonne.
 *
 *  `cell` est fourni par DatasetGrid, qui reste seul à connaître l'édition ;
 *  ce composant ne fait que placer les cellules.
 */
export default function TransposedGrid({ fields, rows, cell }) {
  return (
    <>
      <p className="muted muted--first">
        Fichier transposé : une ligne par champ, une colonne par entité.
      </p>
      <div className="grid-scroll">
        <table>
          <thead>
            <tr>
              <th>Champ</th>
              {rows.map((_, index) => <th key={index}>#{index + 1}</th>)}
            </tr>
          </thead>
          <tbody>
            {fields.map((field) => (
              <tr key={field.position}>
                <td className="cell--label">{field.name}</td>
                {rows.map((_, index) => <td key={index}>{cell(index, field)}</td>)}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
