/** Identité du projet, en lecture. La modification tient en deux champs :
 *  elle passe par une modale plutôt que d'occuper l'écran en permanence. */
export default function IdentityFacts({ project }) {
  return (
    <dl className="facts">
      <dt>Nom</dt>
      <dd>{project.name}</dd>
      <dt>Territoire</dt>
      <dd><code>{project.territory}</code></dd>
      <dt>Description</dt>
      <dd className="muted">{project.description || "—"}</dd>
    </dl>
  );
}
