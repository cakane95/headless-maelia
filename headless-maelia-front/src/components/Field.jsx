/** Champ de formulaire étiqueté. Regroupe le libellé, l'aide et le contrôle. */
export default function Field({ label, hint, children }) {
  return (
    <label>
      <span>{label}</span>
      {children}
      {hint && <small className="hint">{hint}</small>}
    </label>
  );
}
