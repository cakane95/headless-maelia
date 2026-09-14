import Card from "../../../components/Card";

/** Identité du projet, en lecture. La modification tient en deux champs :
 *  elle passe par une modale plutôt que d'occuper l'écran en permanence. */
export default function IdentityCard({ project, onEdit }) {
  return (
    <Card title="Identité">
      <dl className="facts">
        <dt>Nom</dt>
        <dd>{project.name}</dd>
        <dt>Territoire</dt>
        <dd><code>{project.territory}</code></dd>
        <dt>Description</dt>
        <dd className="muted">{project.description || "—"}</dd>
      </dl>
      <p>
        <button type="button" className="ghost" onClick={onEdit}>Modifier</button>
      </p>
    </Card>
  );
}
