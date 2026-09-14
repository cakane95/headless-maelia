import { useState } from "react";

import Card from "../../../components/Card";
import Field from "../../../components/Field";

/** Publication du brouillon en version immuable. */
export default function PublishCard({ dirty, busy, error, onSave, onPublish }) {
  const [label, setLabel] = useState("");
  const [published, setPublished] = useState(null);

  async function publish() {
    const result = await onPublish(label);
    if (result) {
      setLabel("");
      setPublished(result);
    }
  }

  return (
    <Card title="Publier une version">
      <p className="muted muted--first">
        La publication fige le contenu. Les versions déjà publiées ne changent
        pas : un scénario qui en épingle une garde exactement ce fichier.
      </p>

      <Field label="Libellé" hint="Par exemple « ITK bas intrants ».">
        <input value={label} onChange={(e) => setLabel(e.target.value)} />
      </Field>

      <p>
        <button type="button" className="ghost" onClick={onSave} disabled={!dirty || busy}>
          {busy === "save" ? "Enregistrement…" : "Enregistrer le brouillon"}
        </button>{" "}
        <button type="button" onClick={publish} disabled={Boolean(busy)}>
          {busy === "publish" ? "Publication…" : "Publier une version"}
        </button>
        {dirty && <span className="muted"> Modifications non enregistrées.</span>}
      </p>

      {error && <p className="error">{error}</p>}
      {published && (
        <p className={published.issues.length ? "error" : "muted"}>
          Version v{published.version.number} publiée
          {published.issues.length
            ? ` — ${published.issues.length} problème(s), elle est marquée invalide.`
            : " et validée."}
        </p>
      )}
    </Card>
  );
}
