import StatusBadge from "./StatusBadge";
import { fileStatusLabel } from "../utils/status";

/** État d'un fichier d'entrée dans un projet. */
export default function FileStatusBadge({ status }) {
  return <StatusBadge status={status} label={fileStatusLabel(status)} />;
}
