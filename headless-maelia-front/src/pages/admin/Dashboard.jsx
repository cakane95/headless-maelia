import { healthApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import PageHeader from "../../components/PageHeader";
import StatusBadge from "../../components/StatusBadge";
import { useAsync } from "../../hooks/useAsync";

/** État de la plateforme et de ses dépendances. */
export default function Dashboard() {
  const { data: health, error, loading } = useAsync(healthApi.dependencies);

  return (
    <>
      <PageHeader title="Tableau de bord" lede="État de la plateforme et de ses dépendances." />

      <Card title="Dépendances">
        <AsyncBoundary error={error} loading={loading} pending="Vérification…">
          <table>
            <tbody>
              {health?.checks.map((check) => (
                <tr key={check.name}>
                  <td className="cell--name">{check.name}</td>
                  <td className="cell--status">
                    <StatusBadge status={check.status} />
                  </td>
                  <td className="muted">{check.detail}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </AsyncBoundary>
      </Card>
    </>
  );
}
