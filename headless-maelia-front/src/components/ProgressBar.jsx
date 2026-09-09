/** Barre d'avancement. `ratio` entre 0 et 1. */
export default function ProgressBar({ ratio, label }) {
  const percent = Math.round((ratio ?? 0) * 100);
  return (
    <div className="progress" role="progressbar" aria-valuenow={percent}
         aria-valuemin={0} aria-valuemax={100} aria-label={label}>
      <div className="progress__fill" style={{ width: `${percent}%` }} />
      <span className="progress__label">{percent} %</span>
    </div>
  );
}
