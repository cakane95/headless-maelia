import Card from "../components/Card";
import PageHeader from "../components/PageHeader";

/** Écran d'attente d'une rubrique prévue mais non implémentée : on annonce ce qui
 *  viendra plutôt que de laisser un lien mort. */
export default function Placeholder({ title, lede, items = [] }) {
  return (
    <>
      <PageHeader title={title} lede={lede} />
      <Card title="À implémenter">
        <ul className="todo">
          {items.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </Card>
    </>
  );
}
