import { useEffect, useRef } from "react";

/** Fenêtre modale.
 *
 *  Ferme sur Échap et sur le fond, met le focus dedans à l'ouverture et le rend
 *  à l'élément qui l'a déclenchée à la fermeture — sans quoi la navigation au
 *  clavier repart du haut de la page.
 */
export default function Modal({ title, onClose, children, wide = false }) {
  const panel = useRef(null);
  const opener = useRef(null);

  useEffect(() => {
    opener.current = document.activeElement;
    panel.current?.focus();

    const onKey = (event) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);

    // Le fond ne doit pas défiler pendant que la modale est ouverte.
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = previous;
      opener.current?.focus?.();
    };
  }, [onClose]);

  return (
    <div className="modal-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div
        className={wide ? "modal modal--wide" : "modal"}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        ref={panel}
      >
        <header className="modal__head">
          <h2>{title}</h2>
          <button type="button" className="ghost" onClick={onClose} aria-label="Fermer">
            ×
          </button>
        </header>
        <div className="modal__body">{children}</div>
      </div>
    </div>
  );
}
