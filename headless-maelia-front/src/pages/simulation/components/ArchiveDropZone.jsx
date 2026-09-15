import { useRef, useState } from "react";

/** Dépôt d'une archive : glisser-déposer, ou clic.
 *
 *  Le glisser-déposer n'est pas un ornement ici : l'archive sort d'un
 *  gestionnaire de fichiers, la traîner est le geste naturel. Le clic reste
 *  disponible — et c'est lui que suit le clavier.
 */
export default function ArchiveDropZone({ busy, onFile }) {
  const input = useRef(null);
  const [over, setOver] = useState(false);

  function drop(event) {
    event.preventDefault();
    setOver(false);
    const file = event.dataTransfer.files?.[0];
    if (file) onFile(file);
  }

  return (
    <div
      className={over ? "dropzone dropzone--over" : "dropzone"}
      onDragOver={(event) => {
        event.preventDefault();
        setOver(true);
      }}
      onDragLeave={() => setOver(false)}
      onDrop={drop}
    >
      <input
        ref={input}
        type="file"
        accept=".zip"
        hidden
        onChange={(event) => onFile(event.target.files?.[0])}
      />

      <p className="dropzone__icon" aria-hidden="true">↓</p>
      <p className="dropzone__title">
        {busy ? "Import en cours…" : "Déposez votre archive ici"}
      </p>
      <p className="dropzone__hint">Archive .zip · CSV et shapefiles</p>
      <button type="button" onClick={() => input.current?.click()} disabled={busy}>
        Choisir un fichier
      </button>
    </div>
  );
}
