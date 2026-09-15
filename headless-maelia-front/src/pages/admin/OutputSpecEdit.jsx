import { useState } from "react";
import { Link, useNavigate, useParams } from "react-router";

import { catalogApi } from "../../api";
import AsyncBoundary from "../../components/AsyncBoundary";
import Card from "../../components/Card";
import ConfirmDialog from "../../components/ConfirmDialog";
import PageHeader from "../../components/PageHeader";
import { useAsync } from "../../hooks/useAsync";
import OutputSpecForm from "./components/OutputSpecForm";

/** Décrire une sortie du modèle : ses fichiers, et ce qui la déclenche.
 *
 *  L'identifiant ne se modifie pas : c'est l'interrupteur que le GAML nomme,
 *  et c'est lui qui fait le lien avec le scénario.
 */
export default function OutputSpecEdit() {
  const { specId } = useParams();
  const navigate = useNavigate();
  const catalogue = "/admin/catalogue/sorties";
  const [doomed, setDoomed] = useState(false);

  const spec = useAsync(() => catalogApi.output(specId), [specId]);
  const parameters = useAsync(catalogApi.parameters);

  async function submit(payload) {
    await catalogApi.saveOutput(specId, payload);
    navigate(catalogue);
  }

  const edited = spec.data?.origin === "USER";

  return (
    <>
      <p className="muted">
        <Link to={catalogue}>← Sorties du modèle</Link>
      </p>
      <div className="page-head">
        <div>
          <PageHeader
            title={specId}
            lede={spec.data?.gaml_source ? `Écrite par ${spec.data.gaml_source}` : undefined}
          />
        </div>
        <div className="setup__action">
          {edited && (
            <button
              type="button"
              className="ghost"
              onClick={async () => {
                await catalogApi.restoreOutput(specId);
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
            title={edited ? undefined : "Une sortie écrite par le modèle ne se supprime pas."}
            onClick={() => setDoomed(true)}
          >
            Supprimer
          </button>
        </div>
      </div>

      <AsyncBoundary error={spec.error ?? parameters.error} loading={spec.loading || parameters.loading}>
        {spec.data?.unreachable?.length > 0 && (
          <Card title="Hors de portée d'un scénario">
            <p className="muted">
              Le launcher n'expose pas {spec.data.unreachable.map((nom) => (
                <code key={nom}>{nom} </code>
              ))}
              : aucun scénario ne peut agir dessus. Pour rendre cette sortie
              accessible, il faut que <code>launcherBase.gaml</code> déclare ces
              variables — c'est une modification du modèle, pas du catalogue.
            </p>
          </Card>
        )}
        {spec.data && !spec.data.exact && (
          <Card title="Condition partielle">
            <p className="muted">
              La garde du modèle porte un terme que le langage de conditions ne
              sait pas exprimer ; il a été écarté. La prédiction est donc plus
              permissive que le modèle : cette sortie est annoncée comme
              <em> possible</em>, jamais comme certaine.
            </p>
          </Card>
        )}

        {spec.data && (
          <OutputSpecForm
            spec={spec.data}
            parameters={parameters.data ?? []}
            onSubmit={submit}
            onCancel={() => navigate(catalogue)}
          />
        )}
      </AsyncBoundary>

      {doomed && (
        <ConfirmDialog
          title="Supprimer cette sortie"
          message={`${specId} ne sera plus annoncée dans les scénarios ni expliquée dans les résultats.`}
          onConfirm={async () => {
            await catalogApi.deleteOutput(specId);
            navigate(catalogue);
          }}
          onClose={() => setDoomed(false)}
        />
      )}
    </>
  );
}
