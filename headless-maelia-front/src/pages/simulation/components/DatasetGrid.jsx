import { useState } from "react";

import TransposedGrid from "./TransposedGrid";

/** Grille d'édition d'un fichier tabulaire.
 *
 *  Deux rendus pour un même modèle de données : un fichier transposé
 *  (`FIELDS_AS_ROWS`) place les champs en lignes et une entité par colonne.
 *  Les lignes restent des objets `{champ: valeur}` dans les deux cas — c'est le
 *  backend qui sait les réécrire dans la forme physique du fichier d'origine.
 */
export default function DatasetGrid({ fields, rows, transposed, onChange }) {
  const [focus, setFocus] = useState(null);

  function setCell(index, field, value) {
    onChange(rows.map((row, i) => (i === index ? { ...row, [field]: value } : row)));
  }

  function addRow() {
    onChange([...rows, Object.fromEntries(fields.map((f) => [f.name, ""]))]);
  }

  function removeRow(index) {
    onChange(rows.filter((_, i) => i !== index));
  }

  const cell = (index, field) => (
    <input
      className="cell-input"
      value={rows[index]?.[field.name] ?? ""}
      onChange={(e) => setCell(index, field.name, e.target.value)}
      onFocus={() => setFocus(`${index}-${field.name}`)}
      onBlur={() => setFocus(null)}
      aria-label={`${field.name} ligne ${index + 1}`}
      data-focused={focus === `${index}-${field.name}` || undefined}
    />
  );

  if (transposed) {
    return (
      <>
        <TransposedGrid fields={fields} rows={rows} cell={cell} />
        <GridActions onAdd={addRow} label="Ajouter une entité" />
      </>
    );
  }

  return (
    <>
      <div className="grid-scroll">
        <table>
          <thead>
            <tr>
              <th>#</th>
              {fields.map((f) => <th key={f.position}>{f.name}</th>)}
              <th />
            </tr>
          </thead>
          <tbody>
            {rows.map((_, index) => (
              <tr key={index}>
                <td className="muted">{index + 1}</td>
                {fields.map((f) => <td key={f.position}>{cell(index, f)}</td>)}
                <td>
                  <button type="button" className="ghost" onClick={() => removeRow(index)}
                          aria-label={`Supprimer la ligne ${index + 1}`}>×</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <GridActions onAdd={addRow} label="Ajouter une ligne" />
    </>
  );
}

function GridActions({ onAdd, label }) {
  return (
    <p>
      <button type="button" className="ghost" onClick={onAdd}>{label}</button>
    </p>
  );
}
