import { useEffect, useLayoutEffect, useRef, type RefObject } from "react";
import { prepareCanvas, type CanvasViewport } from "../rendering/canvas";

type Draw = (context: CanvasRenderingContext2D, viewport: CanvasViewport) => void;

// One observer per mounted canvas; resize and state changes share a single frame.
export function useCanvasFrame(canvas: RefObject<HTMLCanvasElement | null>, draw: Draw) {
  const latestDraw = useRef(draw);
  const schedule = useRef<(() => void) | null>(null);
  useLayoutEffect(() => {
    latestDraw.current = draw;
    schedule.current?.();
  });
  useEffect(() => {
    const element = canvas.current!;
    let frame = 0, active = true;
    const request = () => {
      if (!active || frame) return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        if (!active) return;
        const prepared = prepareCanvas(element);
        if (prepared) latestDraw.current(prepared.context, prepared.viewport);
      });
    };
    schedule.current = request;
    const observer = new ResizeObserver(request);
    observer.observe(element);
    request();
    return () => {
      active = false;
      cancelAnimationFrame(frame);
      observer.disconnect();
      schedule.current = null;
    };
  }, [canvas]);
}
