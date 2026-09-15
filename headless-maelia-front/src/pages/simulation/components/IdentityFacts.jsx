/** Identité du projet, en lecture. La modification tient en deux champs :
 *  elle passe par une modale plutôt que d'occuper l'écran en permanence.
 *
 *  Pas de territoire ici : le projet démarre sur le jeu de référence, ses
 *  propres fichiers s'y superposent. Ce n'est pas une décision qu'on prend.
 */
export default function IdentityFacts({ project }) {
  return (
    <dl className="facts">
      <dt>Nom</dt>
      <dd>{project.name}</dd>
      <dt>Description</dt>
      <dd className="muted">{project.description || "—"}</dd>
    </dl>
  );
}
