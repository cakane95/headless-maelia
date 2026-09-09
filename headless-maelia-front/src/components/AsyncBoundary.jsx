/** Rend les trois états d'un chargement, pour ne pas les réécrire dans chaque écran. */
export default function AsyncBoundary({ error, loading, pending = "Chargement…", children }) {
  if (error) return <p className="error">{error}</p>;
  if (loading) return <p className="muted">{pending}</p>;
  return children;
}
