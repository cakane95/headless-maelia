// Statuts connus : chacun a sa classe dans styles/components.css. Un statut
// inattendu s'affiche sans couleur plutôt que de casser la mise en page.
// Les valeurs viennent du backend, en anglais.
const KNOWN = new Set([
  "PENDING", "RUNNING", "FINISHED", "FAILED", "CANCELLED",
  "MISSING", "DRAFT", "VALID", "INVALID",
  "up", "down",
]);

export default function StatusBadge({ status, label }) {
  return (
    <span className={`badge ${KNOWN.has(status) ? status : ""}`}>{label ?? status}</span>
  );
}
