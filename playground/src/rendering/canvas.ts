export type CanvasViewport = {
  width: number; height: number; pixelWidth: number; pixelHeight: number; dpr: number;
};

// Reassigning a canvas dimension destroys its backing store even at the same size.
export function prepareCanvas(element: HTMLCanvasElement, dpr = window.devicePixelRatio || 1): { context: CanvasRenderingContext2D; viewport: CanvasViewport } | null {
  const { width, height } = element.getBoundingClientRect();
  const pixelWidth = Math.round(width * dpr), pixelHeight = Math.round(height * dpr);
  if (pixelWidth < 1 || pixelHeight < 1) return null;
  if (element.width !== pixelWidth) element.width = pixelWidth;
  if (element.height !== pixelHeight) element.height = pixelHeight;
  const context = element.getContext("2d")!;
  context.setTransform(dpr, 0, 0, dpr, 0, 0);
  context.clearRect(0, 0, width, height);
  return { context, viewport: { width, height, pixelWidth, pixelHeight, dpr } };
}
