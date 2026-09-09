/** Rangée de chiffres clés. `items` : [{ label, value }] */
export default function StatGroup({ items }) {
  return (
    <div className="row">
      {items.map(({ label, value }) => (
        <div className="stat" key={label}>
          <b>{value}</b>
          <span>{label}</span>
        </div>
      ))}
    </div>
  );
}
