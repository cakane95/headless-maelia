/** Une étape de l'initialisation : un titre, une phrase, une action, un contenu.
 *
 *  Section plutôt que carte : les trois étapes se lisent à la suite, séparées
 *  par du blanc plutôt que par des bordures. Une bordure par bloc, sur une page
 *  qui en compte trois, fabrique du bruit sans rien hiérarchiser.
 */
export default function SetupSection({ title, lede, action, children }) {
  return (
    <section className="setup">
      <header className="setup__head">
        <div>
          <h2 className="setup__title">{title}</h2>
          {lede && <p className="setup__lede">{lede}</p>}
        </div>
        {action && <div className="setup__action">{action}</div>}
      </header>
      <div className="setup__body">{children}</div>
    </section>
  );
}
