import { adminApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";

/** Launchers GAML exposés à la plateforme. */
export default function Models() {
  const { data: models, error, loading } = useAsync(adminApi.models);

  return (
    <>
      <PageHeader
        title="Modèles"
        lede="Seuls les launchers dépourvus de bloc output sont exécutables en headless."
      />

      <AsyncBoundary error={error} loading={loading}>
        {models?.map((model) => (
          <Card key={model.id} title={model.name}>
            <p className="muted muted--first">{model.description}</p>
            <table>
              <tbody>
                <tr>
                  <td className="cell--label">Expérience</td>
                  <td>
                    <code>{model.experiment}</code>
                  </td>
                </tr>
                <tr>
                  <td className="cell--label">Chemin</td>
                  <td className="muted">
                    <code>{model.path}</code>
                  </td>
                </tr>
              </tbody>
            </table>
          </Card>
        ))}
      </AsyncBoundary>
    </>
  );
}
