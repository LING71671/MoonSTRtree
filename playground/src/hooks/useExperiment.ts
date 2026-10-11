import { useEffect, useRef, useState } from "react";
import type {
  Comparison,
  Config,
  Dataset,
  Measurement,
  Query,
} from "../domain/types";
import type { Request, Response } from "../engine/protocol";

export function useExperiment(config: Config, query: Query) {
  const worker = useRef<Worker | null>(null);
  const ready = useRef(false);
  const requestId = useRef(0);
  const currentQuery = useRef(query);
  currentQuery.current = query;
  const [dataset, setDataset] = useState<Dataset | null>(null);
  const [hits, setHits] = useState<number[]>([]);
  const [audit, setAudit] = useState<number[]>([]);
  const [rows, setRows] = useState<Measurement[]>([]);
  const [comparison, setComparison] = useState<Comparison | null>(null);
  const [measuring, setMeasuring] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const send = (request: Request) => worker.current?.postMessage(request);

  useEffect(() => {
    const instance = new Worker(
      new URL("../engine/worker.ts", import.meta.url),
      { type: "module" },
    );
    worker.current = instance;
    ready.current = false;
    setDataset(null);
    setComparison(null);
    setHits([]);
    setAudit([]);
    setRows([]);
    setError(null);
    setMeasuring(false);
    instance.onerror = () => {
      setError(
        "The engine worker could not start. Rebuild the index to retry.",
      );
      setMeasuring(false);
    };
    instance.onmessage = ({ data }: MessageEvent<Response>) => {
      if (data.type === "error") {
        setError(data.message);
        setMeasuring(false);
        return;
      }
      if (data.type === "built") {
        ready.current = true;
        setDataset(data.dataset);
        setRows(data.dataset.measurements);
        instance.postMessage({
          type: "query",
          query: currentQuery.current,
          id: ++requestId.current,
        } satisfies Request);
      } else if (data.id === requestId.current) {
        if (data.type === "queried") {
          setHits(data.hits);
          setAudit(data.audit);
          setRows(data.rows);
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
      instance.terminate();
      if (worker.current === instance) worker.current = null;
    };
  }, [config, attempt]);

  useEffect(() => {
    setComparison(null);
    setMeasuring(false);
    setProgress(0);
    if (ready.current) {
      setRows([]);
      setHits([]);
      setAudit([]);
      send({ type: "query", query, id: ++requestId.current });
    }
  }, [query]);

  const measure = () => {
    if (!ready.current) return;
    setMeasuring(true);
    setProgress(0);
    setComparison(null);
    send({ type: "measure", query, id: ++requestId.current });
  };
  return {
    dataset,
    hits,
    audit,
    rows,
    comparison,
    measuring,
    progress,
    error,
    measure,
    retry: () => setAttempt((value) => value + 1),
  };
}
