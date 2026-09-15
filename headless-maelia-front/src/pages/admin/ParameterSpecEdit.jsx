import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import ConfirmDialog from "../../components/ConfirmDialog";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import ParameterSpecForm from "./components/ParameterSpecForm";

/** Décrire un paramètre de scénario : son type, son défaut, ce qui le commande.
 *
 *  Le nom ne se modifie pas : c'est celui que le launcher déclare, et c'est lui
 *  qui voyage dans le `load` envoyé à GAMA.
 */
export default function ParameterSpecEdit() {
  const { name } = useParams();
  const navigate = useNavigate();
  const catalogue = "/admin/catalogue/parametres";
  const [doomed, setDoomed] = useState(false);

  const spec = useAsync(() => catalogApi.parameter(name), [name]);
  const tous = useAsync(catalogApi.parameters);

  async function submit(payload) {
    await catalogApi.saveParameter(name, payload);
    navigate(catalogue);
  }

  const edited = spec.data?.origin === "USER";

  return (
    <>
      <p className="muted">
        <Link to={catalogue}>← Paramètres de scénario</Link>
      </p>
      <div className="page-head">
        <div>
          <PageHeader
            title={name}
            lede={spec.data?.label !== name ? spec.data?.label : "Variable exposée par le launcher."}
          />
        </div>
        <div className="setup__action">
          {edited && (
            <button
              type="button"
              className="ghost"
              onClick={async () => {
                await catalogApi.restoreParameter(name);
                spec.reload();
              }}
            >
              Rétablir la référence
            </button>
          )}{" "}
          <button
            type="button"
            className="ghost"
            disabled={!edited}
            title={edited ? undefined : "Un paramètre du launcher ne se supprime pas."}
            onClick={() => setDoomed(true)}
          >
            Supprimer
          </button>
        </div>
      </div>

      <AsyncBoundary error={spec.error ?? tous.error} loading={spec.loading || tous.loading}>
        {spec.data && (
          <ParameterSpecForm
            spec={spec.data}
            parameters={tous.data ?? []}
            onSubmit={submit}
            onCancel={() => navigate(catalogue)}
          />
        )}
      </AsyncBoundary>

      {doomed && (
        <ConfirmDialog
          title="Supprimer ce paramètre"
          message={`${name} ne sera plus proposé dans les scénarios. Les scénarios qui le fixent garderont leur valeur, sans effet.`}
          onConfirm={async () => {
            await catalogApi.deleteParameter(name);
            navigate(catalogue);
          }}
          onClose={() => setDoomed(false)}
        />
      )}
    </>
  );
}
