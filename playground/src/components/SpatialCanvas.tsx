import { useEffect, useRef } from "react";
import type { Dataset, Query } from "../domain/types";
import { boundsAt } from "../engine/geometry";
import { useLocale } from "../i18n/LocaleProvider";

type Props = {
  dataset: Dataset | null;
  hits: number[];
  audit: number[];
  query: Query;
  onQuery: (query: Query) => void;
  depth: number;
  showItems: boolean;
  label?: string;
};

export function SpatialCanvas({
  dataset,
  hits,
  audit,
  query,
  onQuery,
  depth,
  showItems,
  label,
}: Props) {
  const { copy: t } = useLocale();
  const canvas = useRef<HTMLCanvasElement>(null);
  const pointer = useRef<[number, number] | null>(null);
  const frame = useRef(0);
  const pending = useRef<Query | null>(null);
  const committed = useRef(query);
  const background = useRef<{ canvas: HTMLCanvasElement; dataset: Dataset | null; items: boolean; width: number; height: number; dpr: number } | null>(null);
  committed.current = query;

  useEffect(() => {
    const element = canvas.current!;
    const context = element.getContext("2d")!;
    const render = () => {
      const { width, height } = element.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      const pixelWidth = Math.round(width * dpr), pixelHeight = Math.round(height * dpr);
      // A queued resize can run after detachment or while the surface is hidden.
      // Wait for a measurable box rather than drawing a zero-sized canvas.
      if (pixelWidth === 0 || pixelHeight === 0) return;
      if (element.width !== pixelWidth) element.width = pixelWidth;
      if (element.height !== pixelHeight) element.height = pixelHeight;
      context.setTransform(dpr, 0, 0, dpr, 0, 0);
      context.clearRect(0, 0, width, height);
      const sx = width / 1000,
        sy = height / 1000;
      let cached = background.current;
      if (!cached || cached.dataset !== dataset || cached.items !== showItems || cached.width !== pixelWidth || cached.height !== pixelHeight || cached.dpr !== dpr) {
        const layer = document.createElement("canvas");
        layer.width = pixelWidth;
        layer.height = pixelHeight;
        const base = layer.getContext("2d")!;
        base.setTransform(dpr, 0, 0, dpr, 0, 0);
        base.strokeStyle = "#2b2b2b";
        base.lineWidth = 1;
      for (let value = 0; value <= 1000; value += 100) {
        base.beginPath();
        base.moveTo(value * sx, 0);
        base.lineTo(value * sx, height);
        base.stroke();
        base.beginPath();
        base.moveTo(0, value * sy);
        base.lineTo(width, value * sy);
        base.stroke();
      }
        if (dataset && showItems) {
          base.strokeStyle = "#909090";
          base.globalAlpha = dataset.stats[0] >= 100000 ? 0.23 : 0.43;
          base.beginPath();
          for (let i = 0; i < dataset.coordinates.length; i += 4) {
            const data = dataset.coordinates;
            base.rect(
              data[i] * sx,
              data[i + 1] * sy,
              Math.max(0.8, (data[i + 2] - data[i]) * sx),
              Math.max(0.8, (data[i + 3] - data[i + 1]) * sy),
            );
          }
          base.stroke();
        }
        cached = { canvas: layer, dataset, items: showItems, width: pixelWidth, height: pixelHeight, dpr };
        background.current = cached;
      }
      context.drawImage(cached.canvas, 0, 0, width, height);
      if (dataset) {
        if (depth >= 0 && query.mode === "range") {
          for (let i = 0; i < audit.length; i += 6) {
            if (audit[i + 4] !== depth) continue;
            const retained = audit[i + 5] === 1;
            context.strokeStyle = retained ? "#f0f0f0" : "#a8a8a8";
            context.lineWidth = retained ? 2 : 1;
            context.setLineDash(retained ? [] : [5, 5]);
            context.strokeRect(
              audit[i] * sx,
              audit[i + 1] * sy,
              (audit[i + 2] - audit[i]) * sx,
              (audit[i + 3] - audit[i + 1]) * sy,
            );
          }
          context.setLineDash([]);
          context.lineWidth = 1;
        }
        if (depth >= 0) {
          context.strokeStyle = "#b2b2b2";
          context.globalAlpha = 0.55;
          context.beginPath();
          for (let i = 0; i < dataset.boxes.length; i += 5) {
            const b = dataset.boxes;
            if (b[i + 4] !== depth) continue;
            context.rect(
              b[i] * sx,
              b[i + 1] * sy,
              (b[i + 2] - b[i]) * sx,
              (b[i + 3] - b[i + 1]) * sy,
            );
          }
          context.stroke();
          context.globalAlpha = 1;
        }
        context.fillStyle = "#dddddd";
        context.globalAlpha = dataset.stats[0] >= 100000 ? 0.65 : 0.85;
        context.beginPath();
        for (const id of hits) {
          const [minX, minY, maxX, maxY] = boundsAt(dataset.coordinates, id);
          context.rect(
            minX * sx,
            minY * sy,
            Math.max(1.5, (maxX - minX) * sx),
            Math.max(1.5, (maxY - minY) * sy),
          );
        }
        context.fill();
        context.globalAlpha = 1;
      }
      const [x1, y1, x2, y2] = query.bounds;
      context.strokeStyle = "#ffffff";
      context.fillStyle = "#ffffff";
      context.lineWidth = 2;
      if (query.mode === "range") {
        const x = Math.min(x1, x2) * sx,
          y = Math.min(y1, y2) * sy;
        const w = Math.abs(x2 - x1) * sx,
          h = Math.abs(y2 - y1) * sy;
        context.globalAlpha = 0.1;
        context.fillRect(x, y, w, h);
        context.globalAlpha = 1;
        context.strokeRect(x, y, w, h);
        for (const [cx, cy] of [
          [x, y],
          [x + w, y],
          [x, y + h],
          [x + w, y + h],
        ])
          context.fillRect(cx - 3, cy - 3, 6, 6);
      } else if (query.mode === "segment") {
        context.beginPath();
        context.moveTo(x1 * sx, y1 * sy);
        context.lineTo(x2 * sx, y2 * sy);
        context.stroke();
        context.fillRect(x1 * sx - 3, y1 * sy - 3, 6, 6);
        context.fillRect(x2 * sx - 3, y2 * sy - 3, 6, 6);
      } else {
        if (query.mode === "circle") {
          context.beginPath();
          context.ellipse(
            x1 * sx,
            y1 * sy,
            query.radius * sx,
            query.radius * sy,
            0,
            0,
            Math.PI * 2,
          );
          context.stroke();
        }
        context.beginPath();
        context.moveTo(x1 * sx - 10, y1 * sy);
        context.lineTo(x1 * sx + 10, y1 * sy);
        context.moveTo(x1 * sx, y1 * sy - 10);
        context.lineTo(x1 * sx, y1 * sy + 10);
        context.stroke();
      }
    };
    const observer = new ResizeObserver(render);
    observer.observe(element);
    render();
    return () => observer.disconnect();
  }, [dataset, hits, audit, query, depth, showItems]);

  useEffect(() => () => cancelAnimationFrame(frame.current), []);
  const location = (event: React.PointerEvent): [number, number] => {
    const bounds = canvas.current!.getBoundingClientRect();
    return [
      Math.max(
        0,
        Math.min(1000, ((event.clientX - bounds.left) * 1000) / bounds.width),
      ),
      Math.max(
        0,
        Math.min(1000, ((event.clientY - bounds.top) * 1000) / bounds.height),
      ),
    ];
  };
  const update = (next: Query) => {
    pending.current = next;
    if (frame.current) return;
    frame.current = requestAnimationFrame(() => {
      frame.current = 0;
      if (pending.current) {
        onQuery(pending.current);
        pending.current = null;
      }
    });
  };
  const move = (event: React.PointerEvent<HTMLCanvasElement>) => {
    if (!pointer.current) return;
    const [x, y] = location(event);
    const [startX, startY] = pointer.current;
    const next = committed.current;
    update({
      ...next,
      bounds: ["point", "knn", "circle"].includes(next.mode)
        ? [x, y, x, y]
        : [startX, startY, x, y],
    });
  };
  return (
    <canvas
      ref={canvas}
      tabIndex={0}
      className="spatial-canvas"
        aria-label={label ?? t.canvasLabel}
      onPointerDown={(event) => {
        event.currentTarget.focus();
        event.currentTarget.setPointerCapture(event.pointerId);
        pointer.current = location(event);
        move(event);
      }}
      onPointerMove={move}
      onPointerUp={(event) => {
        move(event);
        pointer.current = null;
      }}
      onPointerCancel={() => {
        pointer.current = null;
      }}
      onKeyDown={(event) => {
        const step = event.shiftKey ? 40 : 10;
        const delta: Record<string, [number, number]> = {
          ArrowLeft: [-step, 0],
          ArrowRight: [step, 0],
          ArrowUp: [0, -step],
          ArrowDown: [0, step],
        };
        if (!delta[event.key]) return;
        event.preventDefault();
        const [dx, dy] = delta[event.key];
        const [x1, y1, x2, y2] = query.bounds;
        const shiftX = Math.max(
          -Math.min(x1, x2),
          Math.min(dx, 1000 - Math.max(x1, x2)),
        );
        const shiftY = Math.max(
          -Math.min(y1, y2),
          Math.min(dy, 1000 - Math.max(y1, y2)),
        );
        onQuery({
          ...query,
          bounds: [x1 + shiftX, y1 + shiftY, x2 + shiftX, y2 + shiftY],
        });
      }}
    >
      {t.canvasFallback}
    </canvas>
  );
}
