/** Message affiché à la place d'une liste vide. */
export default function EmptyState({ children }) {
  return <p className="empty">{children}</p>;
}
