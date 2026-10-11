import type { Measurement } from "../domain/types";
import { useLocale } from "../i18n/LocaleProvider";

export function BenchmarkLedger({ rows }: { rows: Measurement[] }) {
  const { copy: t, number } = useLocale();
  const name = (value: string) =>
    value === "Linear scan" ? t.linearScan : value;
  const timed = rows.filter((row) => row.valid && row.medianMs !== null);
  const fastest = timed.length
    ? [...timed].sort((a, b) => a.medianMs! - b.medianMs!)[0]
    : null;
  return (
    <aside className="ledger" aria-label={t.ledgerLabel}>
      <div className="ledger-heading">
        <h2>{t.ledgerTitle}</h2>
        <p>{t.ledgerDescription}</p>
      </div>
      <div className="ledger-columns">
        <span>{t.indexPath}</span>
        <span>{t.queryTime}</span>
      </div>
      {rows.map((row) => (
        <div
          className={`ledger-row ${row.name === "MoonSTRtree" ? "moon-row" : ""}`}
          key={row.name}
        >
          <div className="flex items-baseline justify-between gap-3">
            <h3>{name(row.name)}</h3>
            <strong className="measurement">
              {row.medianMs === null ? "—" : row.medianMs.toFixed(4)}
            </strong>
          </div>
          <p className="query-path">{t.paths[row.path] ?? row.path}</p>
          <div className="row-detail">
            <span>
              {row.supported
                ? row.hits === null
                  ? t.checkingRow
                  : t.hitCount(number(row.hits))
                : t.notIncluded}
            </span>
            <span className={row.valid === false ? "invalid" : ""}>
              {row.valid === null ? "—" : row.valid ? t.matches : t.mismatch}
            </span>
          </div>
          <p className="build-time">
            {t.ingest(row.buildMs.toFixed(2))}
            {row.name === "Linear scan" ? ` · ${t.noIndex}` : ""}
          </p>
        </div>
      ))}
      {!rows.length && <p className="empty-ledger">{t.buildingPaths}</p>}
      <p className="measurement-note" aria-live="polite">
        {fastest ? t.fastest(name(fastest.name)) : t.beforeMeasurement}
      </p>
    </aside>
  );
}
