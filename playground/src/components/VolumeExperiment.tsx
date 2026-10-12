import { memo, useCallback, useId, useMemo, useState } from "react";
import type { Query } from "../domain/types";
import { useLocale } from "../i18n/LocaleProvider";
import { VOLUME_QUERY, projectionQuery, type VolumeDimension, type VolumeQuery } from "../engine/volume-protocol";
import { useVolumeExperiment } from "../hooks/useVolumeExperiment";
import metadata from "../.generated/metadata.json";
import { SpatialCanvas } from "./SpatialCanvas";
import { VolumeSideView } from "./VolumeSideView";

const EMPTY: number[] = [];
export const VolumeExperiment = memo(function VolumeExperiment() {
  const { copy: t, number } = useLocale();
  const controlId = useId();
  const [dimension, setDimension] = useState<VolumeDimension>(3);
  const [count, setCount] = useState(1000);
  const [query, setQuery] = useState<VolumeQuery>(VOLUME_QUERY);
  const [attempt, setAttempt] = useState(0);
  const { data, answer, error } = useVolumeExperiment(dimension, count, query, attempt);
  const projected = useMemo(() => projectionQuery(query), [query.bounds]);
  const updateBounds = useCallback((value: Query) => setQuery(previous => ({ ...previous, bounds: value.bounds })), []);

  function download() {
    if (!answer || !data) return;
    const stride = dimension * 2;
    const report = { dimension, seed: 42, count, capacity: 16, query: answer.query, valid: answer.valid,
      hits: answer.hits, matchedBounds: answer.hits.map(id => Array.from(data.coordinates.subarray(id * stride, (id + 1) * stride))),
      metadata, coordinateUnits: "synthetic dimensionless units", generator: "playground/src/engine/volume.worker.ts" };
    const url = URL.createObjectURL(new Blob([JSON.stringify(report, null, 2)], { type: "application/json" }));
    const anchor = document.createElement("a"); anchor.href = url; anchor.download = `moon-strtree-${dimension}d-query.json`; anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  return <section className="volume-experiment" aria-labelledby="volume-title">
    <div className="section-intro"><h2 id="volume-title">{t.volumeTitle}</h2><p>{t.volumeDescription}</p></div>
    <div className="volume-controls">
      <div role="group" aria-label={t.volumeDimension} className="query-tabs">
        {([3, 4] as const).map(value => <button type="button" key={value} aria-pressed={dimension === value} onClick={() => setDimension(value)}>{value}D</button>)}
      </div>
      <label>{t.objects}<select value={count} onChange={event => setCount(Number(event.target.value))}>
        {[1000, 10000].map(value => <option key={value} value={value}>{number(value)}</option>)}
      </select></label>
      <label htmlFor={`${controlId}-height-start`}>{t.volumeHeightStart} <output>{query.height[0]}</output><input id={`${controlId}-height-start`} type="range" min="0" max={query.height[1]} value={query.height[0]} onChange={event => setQuery(previous => ({ ...previous, height: [Number(event.target.value), previous.height[1]] }))} /></label>
      <label htmlFor={`${controlId}-height-end`}>{t.volumeHeightEnd} <output>{query.height[1]}</output><input id={`${controlId}-height-end`} type="range" min={query.height[0]} max="1000" value={query.height[1]} onChange={event => setQuery(previous => ({ ...previous, height: [previous.height[0], Number(event.target.value)] }))} /></label>
      {dimension === 4 && <label htmlFor={`${controlId}-time`}>{t.volumeTime} <output>{query.time}</output><input id={`${controlId}-time`} type="range" min="0" max="1000" value={query.time} onChange={event => setQuery(previous => ({ ...previous, time: Number(event.target.value) }))} /></label>}
    </div>
    <p className="volume-scope">{t.volumeScope(dimension, number(count))}</p>
    {error ? <div role="alert"><p>{t.engineError}</p><button type="button" onClick={() => setAttempt(value => value + 1)}>{t.retry}</button><details><summary>{t.errorDetails}</summary>{error}</details></div> : <>
      <div className="volume-views">
        <div><h3>{t.volumeTopTitle}</h3><SpatialCanvas dataset={data?.dataset ?? null} hits={answer?.hits ?? EMPTY} audit={EMPTY} query={projected}
          onQuery={updateBounds} depth={-1} showItems label={t.volumeTopLabel} /></div>
        <div><h3>{t.volumeSideTitle}</h3><VolumeSideView coordinates={data?.coordinates ?? null} dimension={dimension} hits={answer?.hits ?? EMPTY} query={query} label={t.volumeSideLabel} /></div>
      </div>
      <div className="volume-result-strip"><p role="status">{!data ? t.building : !answer ? t.checkingRow : t.volumeResult(number(answer.hits.length), answer.valid)}</p>
        <button type="button" onClick={download} disabled={!answer?.valid}>{t.volumeExport}</button></div>
      {answer && data && <>
        <p className="volume-scope">{t.volumePreview(answer.hits.length)}</p>
        <div className="volume-result-table"><table><thead><tr><th>ID</th><th>{t.volumeHeightStart}</th><th>{t.volumeHeightEnd}</th>{dimension === 4 && <><th>{t.volumeTimeStart}</th><th>{t.volumeTimeEnd}</th></>}</tr></thead>
          <tbody>{answer.hits.slice(0, 10).map(id => { const p = id * dimension * 2; return <tr key={id}><td>{id}</td><td>{data.coordinates[p + 2].toFixed(1)}</td><td>{data.coordinates[p + dimension + 2].toFixed(1)}</td>{dimension === 4 && <><td>{data.coordinates[p + 3].toFixed(1)}</td><td>{data.coordinates[p + 7].toFixed(1)}</td></>}</tr>; })}</tbody></table></div>
      </>}
    </>}
  </section>;
});
