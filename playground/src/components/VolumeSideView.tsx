import { memo, useRef } from "react";
import { useCanvasFrame } from "../hooks/useCanvasFrame";
import type { VolumeDimension, VolumeQuery } from "../engine/volume-protocol";

export const VolumeSideView = memo(function VolumeSideView({ coordinates, dimension, hits, query, label }: {
  coordinates: Float64Array | null; dimension: VolumeDimension; hits: number[]; query: VolumeQuery; label: string;
}) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const background = useRef<{ canvas: HTMLCanvasElement; coordinates: Float64Array | null; dimension: VolumeDimension; width: number; height: number; dpr: number } | null>(null);
  useCanvasFrame(canvas, (context, { width, height, pixelWidth, pixelHeight, dpr }) => {
    const sx = width / 1000, sz = height / 1000, stride = dimension * 2;
    let cached = background.current;
    if (!cached || cached.coordinates !== coordinates || cached.dimension !== dimension || cached.width !== pixelWidth || cached.height !== pixelHeight || cached.dpr !== dpr) {
      const layer = document.createElement("canvas");
      layer.width = pixelWidth; layer.height = pixelHeight;
      const base = layer.getContext("2d")!;
      base.setTransform(dpr, 0, 0, dpr, 0, 0);
      if (coordinates) {
        base.strokeStyle = "#777777"; base.globalAlpha = 0.35;
        base.beginPath();
        for (let i = 0; i < coordinates.length; i += stride) base.rect(coordinates[i] * sx, (1000 - coordinates[i + dimension + 2]) * sz,
          Math.max(1, (coordinates[i + dimension] - coordinates[i]) * sx), Math.max(1, (coordinates[i + dimension + 2] - coordinates[i + 2]) * sz));
        base.stroke();
      }
      cached = { canvas: layer, coordinates, dimension, width: pixelWidth, height: pixelHeight, dpr };
      background.current = cached;
    }
    context.drawImage(cached.canvas, 0, 0, width, height);
    if (coordinates) {
      context.globalAlpha = 0.85; context.fillStyle = "#ffffff"; context.beginPath();
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
  });
  return <canvas ref={canvas} role="img" aria-label={label} className="volume-side-canvas" />;
});
