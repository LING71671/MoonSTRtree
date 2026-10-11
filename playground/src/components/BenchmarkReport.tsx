import { useEffect, useId, useMemo, useRef, useState, type ReactNode } from "react";
import { useLocale } from "../i18n/LocaleProvider";
import { ALL_FILTERS, BENCHMARK_PROVIDERS, constructionSummary, pairedSummary, querySummary, selectCases, type AggregateRow, type BenchmarkFilters, type CompactReport } from "../domain/benchmark";
import type { Distribution, Mode } from "../domain/types";
import metadata from "../.generated/metadata.json";
import { repository } from "./ProjectEvidence";
import "./benchmark-report.css";

const root = `${import.meta.env.BASE_URL}benchmarks/`;
const ratio = (value: number | null) => value === null ? "—" : `${value < 0.1 ? value.toPrecision(2) : value.toFixed(2)}×`;
const milliseconds = (value: number | null) => value === null ? "—" : value.toFixed(value < 0.01 ? 6 : 4);
async function loadReport(signal: AbortSignal): Promise<CompactReport> {
  const manifestResponse = await fetch(`${root}latest.json`, { signal });
  if (!manifestResponse.ok) throw new Error(`Benchmark manifest: HTTP ${manifestResponse.status}`);
  const manifest = await manifestResponse.json();
  if (manifest.schemaVersion !== 1 || !/^[\w.-]+\.json$/.test(manifest.file)) throw new Error("Unsupported benchmark manifest");
  const response = await fetch(root + manifest.file, { signal });
  if (!response.ok) throw new Error(`Benchmark report: HTTP ${response.status}`);
  const bytes = await response.arrayBuffer();
  const digest = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)), byte => byte.toString(16).padStart(2, "0")).join("");
  if (digest !== manifest.sha256) throw new Error("Benchmark report checksum does not match its manifest");
  const report = JSON.parse(new TextDecoder().decode(bytes)) as CompactReport;
  if (report.schemaVersion !== 1 || report.header.schemaVersion !== 2 || report.cases.length !== report.header.expectedCases || report.completion.completed !== report.header.expectedCases || !/^[\w.-]+\.ndjson\.gz$/.test(report.artifact.rawFile)) throw new Error("Incomplete or unsupported benchmark report");
  return report;
}

function BenchmarkTable({ title, children, note }: { title: string; children: ReactNode; note?: string }) {
  const titleId = useId();
  return <div className="benchmark-table-block"><h3 id={titleId}>{title}</h3>
    <div className="benchmark-table-wrap" tabIndex={0} role="region" aria-labelledby={titleId}>
      <table><caption className="sr-only">{title}</caption>{children}</table>
    </div>{note && <p>{note}</p>}
  </div>;
}

function PerformancePlot({ rows, title, description }: { rows: AggregateRow[]; title: string; description: string }) {
  const { copy: t } = useLocale();
  const titleId = useId(), captionId = useId();
  const scores = rows.flatMap(row => row.score === null ? [] : [row.score]);
  const minPower = Math.min(-1, Math.floor(Math.log10(Math.min(1, ...scores))));
  const maxPower = Math.max(1, Math.ceil(Math.log10(Math.max(1, ...scores))));
  const position = (value: number) => 8 + (Math.log10(value) - minPower) / (maxPower - minPower) * 84;
  const baseline = position(1);
  const stride = Math.max(1, Math.ceil((maxPower - minPower) / 4));
  const tickPowers = [...new Set([minPower, maxPower, 0, ...Array.from({ length: Math.floor((maxPower - minPower) / stride) + 1 }, (_, index) => minPower + index * stride)])].sort((a, b) => a - b);
  const ticks = tickPowers.map(power => 10 ** power);
  return <figure className="benchmark-plot" aria-labelledby={titleId} aria-describedby={captionId}>
    <figcaption><h3 id={titleId}>{title}</h3><p id={captionId}>{description}</p></figcaption>
    <div className="benchmark-plot-body">
      {rows.map((row, index) => <div className="benchmark-plot-row" key={row.name}>
        <span className={index === 0 ? "benchmark-primary-name" : ""}>{row.name === "Linear scan" ? t.linearScan : row.name}</span>
        <div className="benchmark-track" role="img" aria-label={`${row.name === "Linear scan" ? t.linearScan : row.name}: ${ratio(row.score)}`}>
        <svg viewBox="0 0 100 10" preserveAspectRatio="none" aria-hidden="true">
          {ticks.map(tick => <line key={tick} x1={position(tick)} x2={position(tick)} y1="0" y2="10" className={tick === 1 ? "benchmark-baseline" : "benchmark-gridline"} />)}
          {row.score !== null && <>
            <line x1={baseline} x2={position(row.score)} y1="5" y2="5" className={`benchmark-trace benchmark-trace-${index}`} />
          </>}
        </svg>{row.score !== null && <span style={{ left: `${position(row.score)}%` }} className={index === 0 ? "benchmark-marker-primary" : "benchmark-marker"} />}</div>
        <strong>{ratio(row.score)}</strong>
      </div>)}
      <div className="benchmark-plot-row benchmark-axis" aria-hidden="true"><span />
        <div>{ticks.map(tick => <span key={tick} style={{ left: `${position(tick)}%` }}>{ratio(tick)}</span>)}</div><span />
      </div>
    </div>
  </figure>;
}

export function BenchmarkReport() {
  const { copy: t, locale, number } = useLocale();
  const section = useRef<HTMLElement | null>(null), controlId = useId();
  const [visible, setVisible] = useState(false), [attempt, setAttempt] = useState(0);
  const [report, setReport] = useState<CompactReport | null>(null), [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<BenchmarkFilters>(ALL_FILTERS), [metric, setMetric] = useState<"query" | "build">("query");
  useEffect(() => {
    if (!section.current) return;
    if (!("IntersectionObserver" in window)) { setVisible(true); return; }
    const observer = new IntersectionObserver(entries => { if (entries.some(entry => entry.isIntersecting)) { setVisible(true); observer.disconnect(); } }, { rootMargin: "160px" });
    observer.observe(section.current);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    if (!visible) return;
    const controller = new AbortController();
    setError(null);
    loadReport(controller.signal).then(value => { if (!controller.signal.aborted) setReport(value); }).catch(reason => {
      if (!controller.signal.aborted) setError(reason instanceof Error ? reason.message : String(reason));
    });
    return () => controller.abort();
  }, [visible, attempt]);
  const selected = useMemo(() => selectCases(report?.cases ?? [], filters), [report, filters]);
  const queryRows = useMemo(() => querySummary(selected), [selected]);
  const buildRows = useMemo(() => constructionSummary(selected), [selected]);
  const pairs = useMemo(() => pairedSummary(selected), [selected]);
  const groups = useMemo(() => (["range", "point", "knn", "circle", "segment"] as const).map(mode => ({ mode, rows: querySummary(selected.filter(item => item.group === mode)) })), [selected]);
  const datasetName = (id: string) => id === "ourairports-airports" ? t.benchmarkAirports : id === "ourairports-runways" ? t.benchmarkRunways : t.distributions[id as Distribution]?.label ?? id;
  const label = (key: keyof BenchmarkFilters) => ({ dataset: t.distribution, kind: t.benchmarkDataKind, count: t.objects, capacity: t.capacity, seed: t.seed, group: t.geometry })[key];
  function filter(key: keyof BenchmarkFilters, value: string) {
    setFilters(previous => ({ ...previous, [key]: value, ...(key === "kind" ? { dataset: "all", count: "all" } : key === "dataset" ? { count: "all" } : {}) }));
  }
  const choices = (key: keyof BenchmarkFilters): [string, string][] => {
    if (key === "kind") return [["synthetic", t.benchmarkSynthetic], ["public", t.benchmarkPublic]];
    if (key === "group") return (Object.keys(t.modes) as Mode[]).map(mode => [mode, t.modes[mode].label]);
    const available = (report?.cases ?? []).filter(item => (filters.kind === "all" || item.kind === filters.kind) && (key === "dataset" || filters.dataset === "all" || item.dataset === filters.dataset));
    const values = [...new Set(available.map(item => item[key]))];
    if (key !== "dataset") values.sort((a, b) => Number(a) - Number(b));
    return values.map(value => [String(value), key === "dataset" ? datasetName(String(value)) : number(Number(value))]);
  };
  const displayed = metric === "query" ? queryRows : buildRows;
  return <section id="benchmark" className="benchmark-report" ref={section}>
    <div className="section-intro"><h2>{t.benchmarkTitle}</h2><p>{t.benchmarkDescription}</p></div>
    {!report ? <div className="benchmark-load">
      {error ? <><p role="alert">{t.benchmarkLoadError}</p><button type="button" onClick={() => setAttempt(value => value + 1)}>{t.benchmarkRetry}</button><details><summary>{t.errorDetails}</summary>{error}</details></> : <p role="status">{t.benchmarkLoading}</p>}
    </div> : <>
      <p className="benchmark-scope">{t.benchmarkScope(number(report.cases.length), number(report.datasets.length), report.header.profile, report.header.runtime.node)} {report.header.diagnostic && t.benchmarkDiagnostic}</p>
      <div className="benchmark-filters">
        {(["kind", "dataset", "count", "capacity", "seed", "group"] as const).map(key => <label htmlFor={`${controlId}-${key}`} key={key}>{label(key)}
          <select id={`${controlId}-${key}`} value={filters[key]} onChange={event => filter(key, event.target.value)}>
            <option value="all">{t.benchmarkAll}</option>{choices(key).map(([value, name]) => <option key={value} value={value}>{name}</option>)}
          </select></label>)}
        <button type="button" className="text-button" onClick={() => setFilters(ALL_FILTERS)}>{t.benchmarkReset}</button>
      </div>
      <div className="benchmark-reading">
        <p role="status">{t.benchmarkCoverage(number(selected.length), number(queryRows[0].eligible))}</p>
        <div role="group" aria-label={t.benchmarkMetric} className="query-tabs">
          <button type="button" aria-pressed={metric === "query"} onClick={() => setMetric("query")}>{t.benchmarkQuery}</button>
          <button type="button" aria-pressed={metric === "build"} onClick={() => setMetric("build")}>{t.benchmarkBuild}</button>
        </div>
      </div>
      {!selected.length ? <p className="benchmark-empty">{t.benchmarkNoCases}</p> : <>
        <PerformancePlot rows={displayed} title={metric === "query" ? t.benchmarkQueryTitle : t.benchmarkBuildTitle} description={metric === "query" ? t.benchmarkScoreDescription : t.benchmarkBuildDescription} />
        <BenchmarkTable title={t.benchmarkMeasurements}>
          <thead><tr><th scope="col">{t.indexPath}</th><th scope="col">{t.benchmarkRelative}</th><th scope="col">{t.benchmarkMedian}</th><th scope="col">{t.benchmarkEligible}</th><th scope="col">{t.benchmarkFailed}</th><th scope="col">{t.benchmarkUnsupported}</th></tr></thead>
          <tbody>{displayed.map(row => <tr key={row.name}><th scope="row">{row.name === "Linear scan" ? t.linearScan : row.name}</th><td>{ratio(row.score)}</td><td>{milliseconds(row.medianMs)}</td><td>{number(row.eligible)} / {number(row.total)}</td><td>{number(row.failed)}</td><td>{number(row.unsupported)}</td></tr>)}</tbody>
        </BenchmarkTable>
        {metric === "query" && <>
          <BenchmarkTable title={t.benchmarkByQuery}>
            <thead><tr><th scope="col">{t.geometry}</th>{BENCHMARK_PROVIDERS.map(name => <th key={name} scope="col">{name === "Linear scan" ? t.linearScan : name}</th>)}<th scope="col">{t.benchmarkEligible}</th></tr></thead>
            <tbody>{groups.map(({ mode, rows }) => <tr key={mode}><th scope="row">{t.modes[mode].label}</th>{rows.map(row => <td key={row.name}>{ratio(row.score)}</td>)}<td>{number(rows[0].eligible)} / {number(rows[0].total)}</td></tr>)}</tbody>
          </BenchmarkTable>
          <BenchmarkTable title={t.benchmarkPairedTitle} note={t.benchmarkPairDescription}>
            <thead><tr><th scope="col">{t.benchmarkAgainst}</th><th scope="col">{t.benchmarkFaster}</th><th scope="col">{t.benchmarkClose}</th><th scope="col">{t.benchmarkSlower}</th><th scope="col">{t.benchmarkEligible}</th><th scope="col">{t.benchmarkSpeedupRange}</th></tr></thead>
            <tbody>{pairs.map(row => <tr key={row.name}><th scope="row">{row.name === "Linear scan" ? t.linearScan : row.name}</th><td>{number(row.faster)}</td><td>{number(row.close)}</td><td>{number(row.slower)}</td><td>{number(row.eligible)} / {number(row.total)}</td><td>{ratio(row.p10)}–{ratio(row.p90)}</td></tr>)}</tbody>
          </BenchmarkTable>
        </>}
      </>}
      <details className="benchmark-method"><summary>{t.benchmarkMethod}</summary>
        <p>{t.benchmarkMethodDescription(report.header.parameters.warmups, report.header.parameters.batches, report.header.parameters.targetBatchMs)}</p>
        <p>{t.benchmarkWeighting}</p><p>{t.benchmarkPublicScope}</p><p>{t.benchmarkLimit}</p>
        <dl><dt>{t.benchmarkEnvironment}</dt><dd>{report.header.runtime.cpu} · {report.header.runtime.platform} · Node {report.header.runtime.node} · V8 {report.header.runtime.v8}</dd>
          <dt>{t.benchmarkCompiler}</dt><dd>{report.header.engine.compiler}</dd><dt>{t.benchmarkVersions}</dt><dd>{Object.entries(report.header.engine.versions).map(([name, version]) => `${name} ${version}`).join(" · ")}</dd>
          <dt>{t.benchmarkMeasuredAt}</dt><dd>{new Date(report.completion.finishedAt).toLocaleString(locale === "zh" ? "zh-CN" : "en-US")}</dd>
          <dt>{t.benchmarkSource}</dt><dd><a href={`${repository}/commit/${report.header.harness.commit}`} target="_blank" rel="noreferrer">{report.header.harness.commit.slice(0, 12)}</a>{report.header.harness.dirty && ` · ${t.benchmarkDirty}`}</dd>
          <dt>{t.benchmarkCoreHash}</dt><dd>{report.header.engine.sourceSha256}</dd><dt>{t.benchmarkHarnessHash}</dt><dd>{report.header.harness.sha256}</dd><dt>{t.benchmarkRawHash}</dt><dd>{report.artifact.rawSha256}</dd></dl>
        {metadata.sourceSha256 !== report.header.engine.sourceSha256 && <p>{t.benchmarkOtherSnapshot}</p>}
      </details>
      <div className="benchmark-downloads"><a href={root + report.artifact.rawFile} download>{t.benchmarkDownload}</a><a href={`${repository}/blob/main/docs/${locale}/DEVELOPMENT.md#${locale === "zh" ? "扩展-benchmark" : "expanded-benchmark"}`} target="_blank" rel="noreferrer">{t.benchmarkReproduce}</a></div>
    </>}
  </section>;
}
