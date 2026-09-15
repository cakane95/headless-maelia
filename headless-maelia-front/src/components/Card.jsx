/** Bloc de contenu titré.
 *
 *  `lede` dit à quoi sert le bloc, `action` porte le bouton qui le prolonge —
 *  les deux vivent dans l'en-tête pour que le contenu reste le contenu.
 */
export default function Card({ title, lede, action, children }) {
  return (
    <section className="card">
      {(title || action) && (
        <div className="card__head">
          <div>
            {title && <h3>{title}</h3>}
            {lede && <p className="card__lede">{lede}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}
