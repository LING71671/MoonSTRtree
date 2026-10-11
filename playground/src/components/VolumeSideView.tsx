import { useEffect, useRef } from "react";
import type { VolumeDimension, VolumeQuery } from "../engine/volume-protocol";

export function VolumeSideView({ coordinates, dimension, hits, query, label }: {
  coordinates: Float64Array | null; dimension: VolumeDimension; hits: number[]; query: VolumeQuery; label: string;
}) {
  const canvas = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const element = canvas.current!;
    const render = () => {
      const context = element.getContext("2d")!;
      const { width, height } = element.getBoundingClientRect(), dpr = devicePixelRatio || 1;
      element.width = Math.round(width * dpr); element.height = Math.round(height * dpr);
      context.setTransform(dpr, 0, 0, dpr, 0, 0);
      context.clearRect(0, 0, width, height);
      const sx = width / 1000, sz = height / 1000;
      const stride = dimension * 2;
      if (coordinates) {
        context.strokeStyle = "#777777"; context.globalAlpha = 0.35;
        context.beginPath();
        for (let i = 0; i < coordinates.length; i += stride) context.rect(coordinates[i] * sx, (1000 - coordinates[i + dimension + 2]) * sz,
          Math.max(1, (coordinates[i + dimension] - coordinates[i]) * sx), Math.max(1, (coordinates[i + dimension + 2] - coordinates[i + 2]) * sz));
        context.stroke(); context.globalAlpha = 0.85; context.fillStyle = "#ffffff"; context.beginPath();
        for (const id of hits) {
          const i = id * stride;
          context.rect(coordinates[i] * sx, (1000 - coordinates[i + dimension + 2]) * sz,
            Math.max(1, (coordinates[i + dimension] - coordinates[i]) * sx), Math.max(1, (coordinates[i + dimension + 2] - coordinates[i + 2]) * sz));
        }
        context.fill(); context.globalAlpha = 1;
      }
      context.strokeStyle = "#ffffff"; context.lineWidth = 2;
      context.strokeRect(Math.min(query.bounds[0], query.bounds[2]) * sx, (1000 - query.height[1]) * sz,
        Math.abs(query.bounds[2] - query.bounds[0]) * sx, (query.height[1] - query.height[0]) * sz);
    };
    const observer = new ResizeObserver(render); observer.observe(element); render();
    return () => observer.disconnect();
  }, [coordinates, dimension, hits, query]);
  return <canvas ref={canvas} role="img" aria-label={label} className="volume-side-canvas" />;
}
