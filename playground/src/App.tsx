import { useState } from "react";
import { useLocale } from "./i18n/LocaleProvider";
import { ProjectEvidence, repository } from "./components/ProjectEvidence";
import { BenchmarkLedger } from "./components/BenchmarkLedger";
import { SpatialCanvas } from "./components/SpatialCanvas";
import { VolumeExperiment } from "./components/VolumeExperiment";
import { useExperiment } from "./hooks/useExperiment";
import {
  DEFAULT_CONFIG,
  DEFAULT_QUERY,
  DISTRIBUTIONS,
  type Config,
  type Mode,
  type Query,
} from "./domain/types";

export default function App() {
  const { copy: t, locale, setLocale, number } = useLocale();
  const modes = (Object.keys(t.modes) as Mode[]).map((value) => ({
    value,
    ...t.modes[value],
  }));
  const [draft, setDraft] = useState<Config>(DEFAULT_CONFIG);
  const [config, setConfig] = useState<Config>(DEFAULT_CONFIG);
  const [query, setQuery] = useState<Query>(DEFAULT_QUERY);
  const [depth, setDepth] = useState(1);
  const [showItems, setShowItems] = useState(true);
  const experiment = useExperiment(config, query);
  const { dataset, comparison, rows, hits, audit, measuring, progress, error } =
    experiment;
  const changed = JSON.stringify(draft) !== JSON.stringify(config);
  const valid =
    rows.length > 0 &&
    rows.every((row) => !row.supported || row.valid === true);
  const mode = modes.find((item) => item.value === query.mode)!;
  const distribution = t.distributions[config.distribution];
  function exportResults() {
    if (!comparison) return;
    const report = {
      config,
      ...comparison,
      environment: {
        userAgent: navigator.userAgent,
        hardwareConcurrency: navigator.hardwareConcurrency,
      },
      scope:
        "Browser JS target; single dataset and query; not a universal ranking",
    };
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(report, null, 2)], { type: "application/json" }),
    );
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `moon-strtree-${config.seed}-${query.mode}.json`;
    anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  return (
    <div className="app-shell">
      <header className="site-header">
        <a href="#main" className="brand">
          MoonSTRtree<span>{t.brandDescription}</span>
        </a>
        <nav aria-label={t.navigation}>
          <a href="#evidence">{t.exploreDifference}</a>
          <a
            href={`${repository}/blob/main/docs/${locale}/ARCHITECTURE.md`}
            target="_blank"
            rel="noreferrer"
          >
            {t.architecture}
          </a>
          <a href={repository} target="_blank" rel="noreferrer">
            {t.source}
          </a>
          <div className="language-switch" role="group" aria-label={t.language}>
            <button
              type="button"
              aria-pressed={locale === "zh"}
              onClick={() => setLocale("zh")}
              lang="zh-CN"
            >
              中文
            </button>
            <button
              type="button"
              aria-pressed={locale === "en"}
              onClick={() => setLocale("en")}
              lang="en"
            >
              EN
            </button>
          </div>
        </nav>
      </header>
      <main id="main">
        <section className="intro">
          <div>
            <h1>{t.title}</h1>
            <p>{t.introduction}</p>
          </div>
          <div className="intro-note">
            <span className="status-dot" />
            {t.runtime}
            <span>{t.runtimeScope}</span>
          </div>
        </section>
        <section className="experiment" aria-label={t.experiment}>
          <form
            className="dataset-controls"
            onSubmit={(event) => {
              event.preventDefault();
              changed ? setConfig({ ...draft }) : experiment.retry();
            }}
          >
            <label>
              {t.objects}
              <select
                value={draft.count}
                onChange={(event) =>
                  setDraft({ ...draft, count: Number(event.target.value) })
                }
              >
                <option value="1000">1,000</option>
                <option value="10000">10,000</option>
                <option value="100000">100,000</option>
              </select>
            </label>
            <label>
              {t.distribution}
              <select
                value={draft.distribution}
                onChange={(event) =>
                  setDraft({
                    ...draft,
                    distribution: event.target.value as Config["distribution"],
                  })
                }
              >
                {DISTRIBUTIONS.map((item) => (
                  <option key={item.value} value={item.value}>
                    {t.distributions[item.value].label}
                  </option>
                ))}
              </select>
            </label>
            <label>
              {t.capacity}
              <select
                value={draft.capacity}
                onChange={(event) =>
                  setDraft({ ...draft, capacity: Number(event.target.value) })
                }
              >
                {[4, 8, 16, 32, 64].map((value) => (
                  <option key={value}>{value}</option>
                ))}
              </select>
            </label>
            <label>
              {t.seed}
              <input
                type="number"
                min="0"
                max="4294967295"
                required
                value={draft.seed}
                onChange={(event) =>
                  setDraft({ ...draft, seed: Number(event.target.value) })
                }
              />
            </label>
            <button className="secondary-button" type="submit">
              {changed ? t.apply : t.rebuild}
            </button>
            <button
              type="button"
              className="primary-button"
              disabled={!dataset || !valid || measuring || changed}
              onClick={experiment.measure}
            >
              {measuring ? t.measuring(Math.round(progress * 100)) : t.measure}
            </button>
            <span className="dataset-status">
              {dataset
                ? t.dataStatus(number(config.count), config.seed)
                : t.building}
              {changed ? ` · ${t.pending}` : ""}
            </span>
          </form>
          {error && (
            <div className="error-state" role="alert">
              <div>
                <p>{t.engineError}</p>
                <details>
                  <summary>{t.errorDetails}</summary>
                  <p>{error}</p>
                </details>
              </div>
              <button onClick={experiment.retry}>{t.retry}</button>
            </div>
          )}
          <div className="workbench">
            <div className="field">
              <div className="query-tabs" aria-label={t.geometry}>
                {modes.map((item) => (
                  <button
                    key={item.value}
                    aria-pressed={query.mode === item.value}
                    onClick={() => setQuery({ ...query, mode: item.value })}
                  >
                    {item.label}
                  </button>
                ))}
              </div>
              <div className="canvas-wrap">
                <SpatialCanvas
                  dataset={dataset}
                  hits={hits}
                  audit={audit}
                  query={query}
                  onQuery={setQuery}
                  depth={depth}
                  showItems={showItems}
                />
                <div className="axis-label axis-top">{t.units}</div>
                <div className="canvas-caption">
                  <span className="query-swatch" />
                  {t.queryLabel(mode.label)}
                  <span className="node-swatch" />
                  {query.mode === "range" ? t.retained : t.nodes}
                  {query.mode === "range" && (
                    <>
                      <span className="rejected-swatch" />
                      {t.rejected}
                    </>
                  )}
                </div>
                {!dataset && !error && (
                  <div className="loading-overlay" role="status">
                    {t.packing}
                  </div>
                )}
              </div>
              <div className="field-controls">
                <label>
                  {t.reveal}
                  <select
                    value={depth}
                    onChange={(event) => setDepth(Number(event.target.value))}
                  >
                    <option value="-1">{t.hide}</option>
                    {Array.from(
                      { length: Math.max(1, (dataset?.stats[2] ?? 2) - 1) },
                      (_, i) => (
                        <option key={i} value={i}>
                          {i === 0 ? t.root : t.depth(i)}
                        </option>
                      ),
                    )}
                  </select>
                </label>
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={showItems}
                    onChange={(event) => setShowItems(event.target.checked)}
                  />
                  {t.showObjects}
                </label>
                {query.mode === "knn" && (
                  <label>
                    {t.neighbors}
                    <input
                      type="number"
                      min="1"
                      max="1000"
                      value={query.k}
                      onChange={(event) =>
                        setQuery({
                          ...query,
                          k: Math.max(
                            1,
                            Math.min(1000, Number(event.target.value)),
                          ),
                        })
                      }
                    />
                  </label>
                )}
                {query.mode === "circle" && (
                  <label>
                    {t.radius}
                    <input
                      type="range"
                      min="5"
                      max="500"
                      value={query.radius}
                      onChange={(event) =>
                        setQuery({
                          ...query,
                          radius: Number(event.target.value),
                        })
                      }
                    />
                    <output>{query.radius}</output>
                  </label>
                )}
              </div>
              <div className="field-summary">
                <p>
                  {mode.hint} <span>{t.keyboardHint}</span>
                </p>
                <output aria-live="polite">
                  {dataset
                    ? `${t.hitCount(number(hits.length))} · ${valid ? t.agree : t.checking}`
                    : t.preparing}
                </output>
              </div>
            </div>
            <BenchmarkLedger rows={rows} />
          </div>
          <div className="experiment-footer">
            <p className="audit-summary">
              {query.mode === "range"
                ? t.audit(
                    audit.filter(
                      (_, i) =>
                        i % 6 === 5 && audit[i - 1] === depth && audit[i] === 1,
                    ).length,
                    audit.filter(
                      (_, i) =>
                        i % 6 === 5 && audit[i - 1] === depth && audit[i] === 0,
                    ).length,
                  )
                : t.topologyOnly}
            </p>
            <p>
              {distribution.note}{" "}
              {dataset && (
                <span>
                  {t.treeStats(
                    number(dataset.stats[1]),
                    dataset.stats[2],
                    (dataset.stats[3] * 100).toFixed(1),
                  )}
                </span>
              )}
            </p>
            <button
              className="text-button"
              disabled={!comparison}
              onClick={exportResults}
            >
              {t.export}
            </button>
          </div>
        </section>
        <VolumeExperiment />
        <ProjectEvidence />
      </main>
      <footer className="site-footer">
        <span>MoonSTRtree</span>
        <p>{t.footer}</p>
        <a href={repository} target="_blank" rel="noreferrer">
          {t.exploreSource}
        </a>
      </footer>
    </div>
  );
}
