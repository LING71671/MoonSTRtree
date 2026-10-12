import { useEffect, useRef, useState } from "react";
import type { Comparison, Config, Dataset, Measurement, Query } from "../domain/types";
import type { Request, Response } from "../engine/protocol";

// Queries stay immediate; timing waits until the visitor pauses interaction.
const SETTLE_MS = 350;

export function useExperiment(config: Config, query: Query) {
  const worker = useRef<Worker | null>(null);
  const ready = useRef(false);
  const requestId = useRef(0);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const builtConfig = useRef<Config | null>(null);
  const answeredQuery = useRef<Query | null>(null);
  const currentQuery = useRef(query);
  currentQuery.current = query;
  const [dataset, setDataset] = useState<Dataset | null>(null);
  const [hits, setHits] = useState<number[]>([]);
  const [audit, setAudit] = useState<number[]>([]);
  const [rows, setRows] = useState<Measurement[]>([]);
  const [comparison, setComparison] = useState<Comparison | null>(null);
  const [measuring, setMeasuring] = useState(false);
  const [waiting, setWaiting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);

  const cancelTimer = () => {
    if (timer.current !== null) clearTimeout(timer.current);
    timer.current = null;
  };
  const startMeasurement = (instance: Worker, measuredQuery: Query, id: number) => {
    cancelTimer();
    setWaiting(false);
    setMeasuring(true);
    setProgress(0);
    setComparison(null);
    setRows(value => value.map(row => ({ ...row, samples: [], medianMs: null })));
    instance.postMessage({ type: "measure", query: measuredQuery, id } satisfies Request);
  };

  useEffect(() => {
    cancelTimer();
    const instance = new Worker(new URL("../engine/worker.ts", import.meta.url), { type: "module" });
    worker.current = instance;
    ready.current = false;
    builtConfig.current = null;
    answeredQuery.current = null;
    ++requestId.current;
    setDataset(null);
    setComparison(null);
    setHits([]);
    setAudit([]);
    setRows([]);
    setError(null);
    setMeasuring(false);
    setWaiting(false);
    setProgress(0);
    instance.onerror = () => {
      if (worker.current !== instance) return;
      cancelTimer();
      setError("The engine worker could not start. Rebuild the index to retry.");
      setMeasuring(false);
      setWaiting(false);
    };
    instance.onmessage = ({ data }: MessageEvent<Response>) => {
      if (worker.current !== instance) return;
      if (data.type === "error") {
        if (data.id !== undefined && data.id !== requestId.current) return;
        cancelTimer();
        setError(data.message);
        setMeasuring(false);
        setWaiting(false);
        return;
      }
      if (data.type === "built") {
        ready.current = true;
        builtConfig.current = config;
        setDataset(data.dataset);
      } else if (data.id === requestId.current) {
        if (data.type === "queried") {
          answeredQuery.current = currentQuery.current;
          setHits(data.hits);
          setAudit(data.audit);
          setRows(data.rows);
          if (data.rows.every(row => !row.supported || row.valid === true)) {
            setWaiting(true);
            const queried = currentQuery.current, id = data.id;
            cancelTimer();
            timer.current = setTimeout(() => {
              if (worker.current === instance && requestId.current === id && currentQuery.current === queried)
                startMeasurement(instance, queried, id);
            }, SETTLE_MS);
          }
        }
        if (data.type === "progress") setProgress(data.completed / data.total);
        if (data.type === "measured") {
          setComparison(data.comparison);
          setRows(data.comparison.rows);
          setMeasuring(false);
        }
      }
    };
    instance.postMessage({ type: "build", config } satisfies Request);
    return () => {
      cancelTimer();
      instance.onmessage = null;
      instance.onerror = null;
      instance.terminate();
      if (worker.current === instance) worker.current = null;
    };
  }, [config, attempt]);

  useEffect(() => {
    cancelTimer();
    setComparison(null);
    setMeasuring(false);
    setWaiting(false);
    setProgress(0);
    answeredQuery.current = null;
    if (ready.current && builtConfig.current === config) {
      setRows([]);
      setHits([]);
      setAudit([]);
      const id = ++requestId.current;
      worker.current?.postMessage({ type: "cancel", id } satisfies Request);
      // Coalesce pointer updates instead of queuing exhaustive scans every frame.
      const queryTimer = setTimeout(() => {
        worker.current?.postMessage({ type: "query", query, id } satisfies Request);
      }, 60);
      return () => clearTimeout(queryTimer);
    }
  }, [query, dataset, config]);

  const currentData = builtConfig.current === config;
  const currentAnswer = currentData && answeredQuery.current === query;
  return {
    dataset: currentData ? dataset : null,
    hits: currentAnswer ? hits : [],
    audit: currentAnswer ? audit : [],
    rows: currentAnswer ? rows : [],
    comparison: currentAnswer ? comparison : null,
    measuring: currentAnswer && measuring,
    waiting: currentAnswer && waiting,
    progress,
    error,
    measure: () => {
      if (worker.current && ready.current && currentAnswer)
        startMeasurement(worker.current, query, ++requestId.current);
    },
    retry: () => setAttempt(value => value + 1),
  };
}
