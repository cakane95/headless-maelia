/** Ce qu'on peut faire d'une spec selon son origine.
 *
 *  Une spec de référence décrit un fichier que le modèle lit réellement : elle
 *  ne se supprime pas. Une spec modifiée à la main ne reçoit plus les mises à
 *  jour du catalogue livré — d'où le retour en arrière.
 */
export default function DataSpecActions({ spec, onRestore, onDelete }) {
  const edited = spec.origin === "USER";

  return (
    <div className="setup__action">
      {edited && (
        <button type="button" className="ghost" onClick={onRestore}>
          Rétablir la référence
        </button>
      )}{" "}
      <button
        type="button"
        className="ghost"
        disabled={!edited}
        title={edited ? undefined : "Une spec de référence ne se supprime pas."}
        onClick={onDelete}
      >
        Supprimer
      </button>
    </div>
  );
}
