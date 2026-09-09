/** Titre et accroche d'un écran. */
export default function PageHeader({ title, lede }) {
  return (
    <>
      <h1>{title}</h1>
      {lede && <p className="lede">{lede}</p>}
    </>
  );
}
