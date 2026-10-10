import { Rect, StrTree, generateDataset } from './strtree.js';

// DOM Elements
const canvas = document.getElementById('viewportCanvas');
const ctx = canvas.getContext('2d');
const distributionSelect = document.getElementById('distributionSelect');
const countSelect = document.getElementById('countSelect');
const capacitySelect = document.getElementById('capacitySelect');
const rebuildBtn = document.getElementById('rebuildBtn');
const modeBtns = document.querySelectorAll('.mode-btn');
const modeHint = document.getElementById('modeHint');
const toggleLeaves = document.getElementById('toggleLeaves');
const toggleL1 = document.getElementById('toggleL1');
const toggleL2 = document.getElementById('toggleL2');
const toggleRoot = document.getElementById('toggleRoot');
const metricTreeTime = document.getElementById('metricTreeTime');
const metricLinearTime = document.getElementById('metricLinearTime');
const metricHits = document.getElementById('metricHits');
const speedupBadge = document.getElementById('speedupBadge');
const metricHeight = document.getElementById('metricHeight');
const metricFill = document.getElementById('metricFill');
const metricMemory = document.getElementById('metricMemory');
const fpsCounter = document.getElementById('fpsCounter');
const coordDisplay = document.getElementById('coordDisplay');
const resetViewBtn = document.getElementById('resetViewBtn');

// State
let items = [];
let tree = null;
let currentMode = 'range'; // 'range' | 'point' | 'knn' | 'segment'
let currentHits = new Set();
let hitDetails = [];

// Viewport Transform (Pan & Zoom)
let scale = 1.0;
let panX = 40;
let panY = 40;
let isPanning = false;
let isDrawing = false;
let dragStartX = 0;
let dragStartY = 0;
let dragCurrentX = 0;
let dragCurrentY = 0;
let mouseWorldX = 0;
let mouseWorldY = 0;

// Coordinate Transforms
function screenToWorld(sx, sy) {
  return {
    x: (sx - panX) / scale,
    y: (sy - panY) / scale,
  };
}

function worldToScreen(wx, wy) {
  return {
    x: wx * scale + panX,
    y: wy * scale + panY,
  };
}

function resizeCanvas() {
  const rect = canvas.getBoundingClientRect();
  const dpr = window.devicePixelRatio || 1;
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  render();
}

window.addEventListener('resize', resizeCanvas);

function resetView() {
  const rect = canvas.getBoundingClientRect();
  scale = Math.min((rect.width - 80) / 1000, (rect.height - 80) / 1000);
  panX = (rect.width - 1000 * scale) * 0.5;
  panY = (rect.height - 1000 * scale) * 0.5;
  render();
}

resetViewBtn.addEventListener('click', resetView);

// Dataset Rebuilding
function buildIndex() {
  const dist = distributionSelect.value;
  const count = parseInt(countSelect.value, 10);
  const cap = parseInt(capacitySelect.value, 10);

  items = generateDataset(dist, count, 1000, 1000);
  const t0 = performance.now();
  tree = StrTree.build(items, cap);
  const tBuild = performance.now() - t0;

  metricHeight.textContent = `${tree.height}`;
  metricMemory.textContent = `${Math.round((tree.numNodes * 48) / 1024)} KB`;

  // Theoretical fill factor
  const P = Math.ceil(tree.numItems / tree.nodeCapacity);
  const fill = (tree.numItems / (P * tree.nodeCapacity)) * 100;
  metricFill.textContent = `${fill.toFixed(1)}%`;

  runCurrentQuery();
  render();
}

rebuildBtn.addEventListener('click', buildIndex);
distributionSelect.addEventListener('change', buildIndex);
countSelect.addEventListener('change', buildIndex);
capacitySelect.addEventListener('change', buildIndex);

// Queries
function runCurrentQuery() {
  if (!tree) return;

  let hits = [];
  let linearTimeMs = 0;
  let treeTimeMs = 0;

  if (currentMode === 'range') {
    const minX = Math.min(dragStartX, dragCurrentX);
    const maxX = Math.max(dragStartX, dragCurrentX);
    const minY = Math.min(dragStartY, dragCurrentY);
    const maxY = Math.max(dragStartY, dragCurrentY);
    const queryRect = new Rect(minX, minY, maxX, maxY);

    // Benchmark STR Tree
    const t0 = performance.now();
    for (let r = 0; r < 5; r++) {
      hits = tree.query(queryRect);
    }
    treeTimeMs = (performance.now() - t0) / 5;

    // Benchmark Linear Scan
    const tL0 = performance.now();
    for (let r = 0; r < 5; r++) {
      const linHits = [];
      for (let i = 0; i < items.length; i++) {
        if (items[i].rect.intersects(queryRect)) linHits.push(items[i].id);
      }
    }
    linearTimeMs = (performance.now() - tL0) / 5;
  } else if (currentMode === 'point') {
    const t0 = performance.now();
    for (let r = 0; r < 10; r++) {
      hits = tree.queryPoint(mouseWorldX, mouseWorldY);
    }
    treeTimeMs = (performance.now() - t0) / 10;

    const tL0 = performance.now();
    for (let r = 0; r < 10; r++) {
      const linHits = [];
      for (let i = 0; i < items.length; i++) {
        if (items[i].rect.containsPoint(mouseWorldX, mouseWorldY)) linHits.push(items[i].id);
      }
    }
    linearTimeMs = (performance.now() - tL0) / 10;
  } else if (currentMode === 'knn') {
    const k = 10;
    const t0 = performance.now();
    for (let r = 0; r < 5; r++) {
      hits = tree.queryKNN(mouseWorldX, mouseWorldY, k);
    }
    treeTimeMs = (performance.now() - t0) / 5;

    const tL0 = performance.now();
    for (let r = 0; r < 5; r++) {
      const dists = [];
      for (let i = 0; i < items.length; i++) {
        dists.push({ dist: items[i].rect.distanceSquaredToPoint(mouseWorldX, mouseWorldY), id: items[i].id });
      }
      dists.sort((a, b) => a.dist - b.dist);
      const linHits = dists.slice(0, k).map(d => d.id);
    }
    linearTimeMs = (performance.now() - tL0) / 5;
  } else if (currentMode === 'segment') {
    const t0 = performance.now();
    for (let r = 0; r < 5; r++) {
      hits = tree.querySegment(dragStartX, dragStartY, dragCurrentX, dragCurrentY);
    }
    treeTimeMs = (performance.now() - t0) / 5;

    const tL0 = performance.now();
    for (let r = 0; r < 5; r++) {
      const linHits = [];
      for (let i = 0; i < items.length; i++) {
        if (items[i].rect.intersectsSegment(dragStartX, dragStartY, dragCurrentX, dragCurrentY)) linHits.push(items[i].id);
      }
    }
    linearTimeMs = (performance.now() - tL0) / 5;
  }

  currentHits = new Set(hits);
  metricHits.textContent = `${hits.length} items`;
  metricTreeTime.textContent = `${Math.max(0.001, treeTimeMs).toFixed(3)} ms`;
  metricLinearTime.textContent = `${Math.max(0.001, linearTimeMs).toFixed(3)} ms`;

  const speedup = Math.max(1, linearTimeMs / Math.max(0.0001, treeTimeMs));
  speedupBadge.textContent = `${speedup.toFixed(1)}× FASTER`;
}

// Mode Selection
modeBtns.forEach(btn => {
  btn.addEventListener('click', () => {
    modeBtns.forEach(b => {
      b.className = 'mode-btn py-1.5 px-2 rounded border border-slate-800 bg-slate-900/60 text-slate-400 hover:text-slate-200 text-left';
    });
    btn.className = 'mode-btn py-1.5 px-2 rounded border bg-slate-800/90 border-cyan-500 text-cyan-300 font-medium text-left';
    currentMode = btn.dataset.mode;

    if (currentMode === 'range') {
      modeHint.textContent = 'Click and drag on the canvas to draw a spatial query box.';
    } else if (currentMode === 'point') {
      modeHint.textContent = 'Hover your cursor across the canvas to perform point containment checks.';
    } else if (currentMode === 'knn') {
      modeHint.textContent = 'Hover or click anywhere to find the 10 closest bounding boxes via MinDist branch-and-bound.';
    } else if (currentMode === 'segment') {
      modeHint.textContent = 'Click and drag a line segment across the canvas for ray-casting collision pruning.';
    }

    runCurrentQuery();
    render();
  });
});

[toggleLeaves, toggleL1, toggleL2, toggleRoot].forEach(cb => {
  cb.addEventListener('change', render);
});

// Canvas Mouse Events
canvas.addEventListener('mousedown', e => {
  const rect = canvas.getBoundingClientRect();
  const sx = e.clientX - rect.left;
  const sy = e.clientY - rect.top;

  if (e.button === 1 || e.shiftKey) {
    // Middle click or shift: Pan
    isPanning = true;
    dragStartX = sx;
    dragStartY = sy;
  } else if (e.button === 0) {
    // Left click: Drawing query
    isDrawing = true;
    const w = screenToWorld(sx, sy);
    dragStartX = w.x;
    dragStartY = w.y;
    dragCurrentX = w.x;
    dragCurrentY = w.y;
    runCurrentQuery();
    render();
  }
});

canvas.addEventListener('mousemove', e => {
  const rect = canvas.getBoundingClientRect();
  const sx = e.clientX - rect.left;
  const sy = e.clientY - rect.top;
  const w = screenToWorld(sx, sy);
  mouseWorldX = w.x;
  mouseWorldY = w.y;
  coordDisplay.textContent = `X: ${w.x.toFixed(1)}, Y: ${w.y.toFixed(1)}`;

  if (isPanning) {
    panX += sx - dragStartX;
    panY += sy - dragStartY;
    dragStartX = sx;
    dragStartY = sy;
    render();
  } else if (isDrawing) {
    dragCurrentX = w.x;
    dragCurrentY = w.y;
    runCurrentQuery();
    render();
  } else if (currentMode === 'point' || currentMode === 'knn') {
    runCurrentQuery();
    render();
  }
});

window.addEventListener('mouseup', () => {
  isPanning = false;
  isDrawing = false;
  render();
});

canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const rect = canvas.getBoundingClientRect();
  const sx = e.clientX - rect.left;
  const sy = e.clientY - rect.top;

  const zoomFactor = e.deltaY < 0 ? 1.15 : 0.87;
  const newScale = Math.min(10.0, Math.max(0.05, scale * zoomFactor));

  // Zoom centered on cursor
  panX = sx - (sx - panX) * (newScale / scale);
  panY = sy - (sy - panY) * (newScale / scale);
  scale = newScale;

  render();
}, { passive: false });

// Rendering
let lastFpsTime = performance.now();
let frameCount = 0;

function render() {
  const rect = canvas.getBoundingClientRect();
  ctx.clearRect(0, 0, rect.width, rect.height);

  // Background grid
  ctx.save();
  ctx.fillStyle = '#0a0c10';
  ctx.fillRect(0, 0, rect.width, rect.height);

  // Draw 1000x1000 world bounds boundary
  const p0 = worldToScreen(0, 0);
  const p1 = worldToScreen(1000, 1000);
  ctx.fillStyle = '#10131a';
  ctx.fillRect(p0.x, p0.y, p1.x - p0.x, p1.y - p0.y);
  ctx.strokeStyle = '#1e2430';
  ctx.lineWidth = 1;
  ctx.strokeRect(p0.x, p0.y, p1.x - p0.x, p1.y - p0.y);

  if (!tree) {
    ctx.restore();
    return;
  }

  // Draw Internal MBR Layers
  if (toggleRoot.checked && tree.rootIndex >= 0) {
    const rx0 = worldToScreen(tree.boxesMinX[tree.rootIndex], tree.boxesMinY[tree.rootIndex]);
    const rx1 = worldToScreen(tree.boxesMaxX[tree.rootIndex], tree.boxesMaxY[tree.rootIndex]);
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 2;
    ctx.strokeRect(rx0.x, rx0.y, rx1.x - rx0.x, rx1.y - rx0.y);
  }

  if (toggleL2.checked) {
    ctx.strokeStyle = 'rgba(192, 132, 252, 0.45)'; // Purple for Level 2
    ctx.lineWidth = 1.5;
    for (let i = 0; i < tree.numNodes; i++) {
      if (tree.nodeLevels[i] === tree.height - 2 && i !== tree.rootIndex) {
        const pA = worldToScreen(tree.boxesMinX[i], tree.boxesMinY[i]);
        const pB = worldToScreen(tree.boxesMaxX[i], tree.boxesMaxY[i]);
        ctx.strokeRect(pA.x, pA.y, pB.x - pA.x, pB.y - pA.y);
      }
    }
  }

  if (toggleL1.checked) {
    ctx.strokeStyle = 'rgba(56, 189, 248, 0.35)'; // Cyan for Level 1 parents
    ctx.lineWidth = 1;
    for (let i = 0; i < tree.numNodes; i++) {
      if (tree.nodeLevels[i] === 1) {
        const pA = worldToScreen(tree.boxesMinX[i], tree.boxesMinY[i]);
        const pB = worldToScreen(tree.boxesMaxX[i], tree.boxesMaxY[i]);
        ctx.strokeRect(pA.x, pA.y, pB.x - pA.x, pB.y - pA.y);
      }
    }
  }

  // Draw Leaf Rectangles
  if (toggleLeaves.checked) {
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      const isHit = currentHits.has(it.id);
      const pA = worldToScreen(it.rect.minX, it.rect.minY);
      const pB = worldToScreen(it.rect.maxX, it.rect.maxY);
      const w = pB.x - pA.x;
      const h = pB.y - pA.y;

      if (isHit) {
        ctx.fillStyle = 'rgba(245, 158, 11, 0.45)'; // Amber hit fill
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 2;
        ctx.fillRect(pA.x, pA.y, w, h);
        ctx.strokeRect(pA.x, pA.y, w, h);
      } else {
        ctx.fillStyle = 'rgba(71, 85, 105, 0.15)';
        ctx.strokeStyle = '#334155';
        ctx.lineWidth = 0.8;
        ctx.fillRect(pA.x, pA.y, w, h);
        ctx.strokeRect(pA.x, pA.y, w, h);
      }
    }
  }

  // Draw Active Query Shape Overlays
  if (currentMode === 'range') {
    const minX = Math.min(dragStartX, dragCurrentX);
    const maxX = Math.max(dragStartX, dragCurrentX);
    const minY = Math.min(dragStartY, dragCurrentY);
    const maxY = Math.max(dragStartY, dragCurrentY);
    const s0 = worldToScreen(minX, minY);
    const s1 = worldToScreen(maxX, maxY);
    const qw = s1.x - s0.x;
    const qh = s1.y - s0.y;

    ctx.fillStyle = 'rgba(6, 182, 212, 0.15)';
    ctx.strokeStyle = '#06b6d4';
    ctx.lineWidth = 2;
    ctx.setLineDash([4, 4]);
    ctx.fillRect(s0.x, s0.y, qw, qh);
    ctx.strokeRect(s0.x, s0.y, qw, qh);
    ctx.setLineDash([]);
  } else if (currentMode === 'point') {
    const sp = worldToScreen(mouseWorldX, mouseWorldY);
    ctx.fillStyle = '#38bdf8';
    ctx.beginPath();
    ctx.arc(sp.x, sp.y, 5, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1.5;
    ctx.stroke();
  } else if (currentMode === 'knn') {
    const sp = worldToScreen(mouseWorldX, mouseWorldY);
    ctx.fillStyle = '#f43f5e';
    ctx.beginPath();
    ctx.arc(sp.x, sp.y, 6, 0, Math.PI * 2);
    ctx.fill();

    // Draw lines to hits
    ctx.strokeStyle = 'rgba(244, 63, 94, 0.7)';
    ctx.lineWidth = 1.5;
    ctx.setLineDash([3, 3]);
    for (const id of currentHits) {
      const it = items[id];
      if (it) {
        const cx = (it.rect.minX + it.rect.maxX) * 0.5;
        const cy = (it.rect.minY + it.rect.maxY) * 0.5;
        const targetScreen = worldToScreen(cx, cy);
        ctx.beginPath();
        ctx.moveTo(sp.x, sp.y);
        ctx.lineTo(targetScreen.x, targetScreen.y);
        ctx.stroke();
      }
    }
    ctx.setLineDash([]);
  } else if (currentMode === 'segment') {
    const pA = worldToScreen(dragStartX, dragStartY);
    const pB = worldToScreen(dragCurrentX, dragCurrentY);
    ctx.strokeStyle = '#22d3ee';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(pA.x, pA.y);
    ctx.lineTo(pB.x, pB.y);
    ctx.stroke();

    ctx.fillStyle = '#ffffff';
    ctx.beginPath();
    ctx.arc(pA.x, pA.y, 4, 0, Math.PI * 2);
    ctx.arc(pB.x, pB.y, 4, 0, Math.PI * 2);
    ctx.fill();
  }

  ctx.restore();

  // FPS Calculation
  frameCount++;
  const now = performance.now();
  if (now - lastFpsTime >= 500) {
    const fps = Math.round((frameCount * 1000) / (now - lastFpsTime));
    fpsCounter.textContent = `${fps} FPS`;
    frameCount = 0;
    lastFpsTime = now;
  }
}

// Initial Launch
resizeCanvas();
resetView();
buildIndex();

// Default query box in center
dragStartX = 250;
dragStartY = 250;
dragCurrentX = 750;
dragCurrentY = 750;
runCurrentQuery();
render();
