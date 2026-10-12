import { useEffect, useRef, useState } from "react";
import type { Dataset } from "../domain/types";
import { coalescedTask } from "../engine/coalesced-task";
import type { VolumeDimension, VolumeQuery, VolumeRequest, VolumeResponse } from "../engine/volume-protocol";

type Answer = Extract<VolumeResponse, { type: "queried" }>;
type Data = { dimension: VolumeDimension; count: number; dataset: Dataset; coordinates: Float64Array };

export function useVolumeExperiment(dimension: VolumeDimension, count: number, query: VolumeQuery, attempt: number) {
  const [data, setData] = useState<Data | null>(null);
  const [answer, setAnswer] = useState<Answer | null>(null);
  const [error, setError] = useState<string | null>(null);
  const worker = useRef<Worker | null>(null);
  const requestId = useRef(0);
  const currentQuery = useRef(query);
  currentQuery.current = query;
  const queue = useRef<ReturnType<typeof coalescedTask<{ query: VolumeQuery; id: number }>> | null>(null);
  useEffect(() => {
    const instance = new Worker(new URL("../engine/volume.worker.ts", import.meta.url), { type: "module" });
    worker.current = instance;
    ++requestId.current;
    setData(null); setAnswer(null); setError(null);
    queue.current = coalescedTask(value => {
      if (worker.current === instance) instance.postMessage({ type: "query", ...value } satisfies VolumeRequest);
    }, 60);
    instance.onerror = () => {
      if (worker.current === instance) setError("The volume engine worker could not start.");
    };
    instance.onmessage = ({ data: response }: MessageEvent<VolumeResponse>) => {
      if (worker.current !== instance) return;
      if (response.type === "error") {
        if (response.id === undefined || response.id === requestId.current) setError(response.message);
      } else if (response.type === "built") {
        setData({ dimension, count, dataset: { coordinates: response.projection, boxes: response.boxes, stats: response.stats, measurements: [] }, coordinates: response.coordinates });
      } else if (response.id === requestId.current && response.query.bounds.every((value, index) => value === currentQuery.current.bounds[index])
        && response.query.height.every((value, index) => value === currentQuery.current.height[index]) && response.query.time === currentQuery.current.time) setAnswer(response);
    };
    instance.postMessage({ type: "build", dimension, count, seed: 42 } satisfies VolumeRequest);
    return () => {
      queue.current?.cancel();
      instance.onmessage = null; instance.onerror = null;
      instance.terminate();
      if (worker.current === instance) worker.current = null;
    };
  }, [dimension, count, attempt]);
  useEffect(() => {
    setAnswer(null);
    if (data?.dimension === dimension && data.count === count) queue.current?.push({ query, id: ++requestId.current });
  }, [data, dimension, count, query]);
  const currentData = data?.dimension === dimension && data.count === count ? data : null;
  const currentAnswer = currentData && answer?.query.bounds.every((value, index) => value === query.bounds[index])
    && answer.query.height.every((value, index) => value === query.height[index]) && answer.query.time === query.time ? answer : null;
  return { data: currentData, answer: currentAnswer, error };
}
