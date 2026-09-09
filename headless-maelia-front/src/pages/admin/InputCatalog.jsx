import { useState } from "react";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import Field from "../../components/Field";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import DataSpecTable from "./components/DataSpecTable";

const MODULES = ["", "modeleAgricole", "modeleCommun", "modeleHydrographique", "modeleNormatif"];

/** Catalogue des fichiers d'entrée attendus par le modèle. */
export default function InputCatalog() {
  const [module, setModule] = useState("");
  const { data: specs, error, loading } = useAsync(
    () => catalogApi.dataspecs(module || undefined), [module],
  );

  return (
    <>
      <PageHeader
        title="Catalogue des entrées"
        lede="Ce que le modèle lit. Extrait du code GAML : ajouter un fichier ne demande pas de déployer."
      />

      <Card title="Filtre">
        <Field label="Module">
          <select value={module} onChange={(e) => setModule(e.target.value)}>
            {MODULES.map((m) => (
              <option key={m || "all"} value={m}>{m || "Tous les modules"}</option>
            ))}
          </select>
        </Field>
      </Card>

      <Card title={specs ? `${specs.length} type(s) de fichier` : "Types de fichier"}>
        <AsyncBoundary error={error} loading={loading}>
          <DataSpecTable specs={specs ?? []} />
        </AsyncBoundary>
      </Card>
    </>
  );
}
