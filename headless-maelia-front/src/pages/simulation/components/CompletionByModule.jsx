import ProgressBar from "../../../components/ProgressBar";

/** Avancement des données, module par module. */
export default function CompletionByModule({ byModule }) {
  const modules = Object.entries(byModule ?? {});
  if (modules.length === 0) return null;

  return (
    <div>
      {modules.map(([name, { expected, supplied }]) => (
        <div className="module-row" key={name}>
          <span className="module-row__name">{name}</span>
          <span className="module-row__count">{supplied} / {expected}</span>
          <ProgressBar ratio={expected ? supplied / expected : 1} label={name} />
        </div>
      ))}
    </div>
  );
}
