import { useEffect, useRef } from "react";

/** Console défilante, ancrée en bas au fil des lignes. */
export default function ConsoleView({ lines, empty = "En attente…" }) {
  const conteneur = useRef(null);

  useEffect(() => {
    const noeud = conteneur.current;
    if (noeud) noeud.scrollTop = noeud.scrollHeight;
  }, [lines]);

  return (
    <div className="console" ref={conteneur}>
      {lines.length === 0
        ? empty
        : lines.map((ligne, index) => (
            <div key={index} className={ligne.startsWith("[plateforme]") ? "platform" : undefined}>
              {ligne}
            </div>
          ))}
    </div>
  );
}
