// MoonSTRtree - Exact Sort-Tile-Recursive Engine (JavaScript Mirror of MoonBit Implementation)

export class Rect {
  constructor(minX, minY, maxX, maxY) {
    this.minX = Math.min(minX, maxX);
    this.minY = Math.min(minY, maxY);
    this.maxX = Math.max(minX, maxX);
    this.maxY = Math.max(minY, maxY);
  }

  intersects(other) {
    return !(
      this.maxX < other.minX ||
      this.minX > other.maxX ||
      this.maxY < other.minY ||
      this.minY > other.maxY
    );
  }

  containsPoint(x, y) {
    return this.minX <= x && x <= this.maxX && this.minY <= y && y <= this.maxY;
  }

  distanceSquaredToPoint(x, y) {
    const dx = x < this.minX ? this.minX - x : x > this.maxX ? x - this.maxX : 0.0;
    const dy = y < this.minY ? this.minY - y : y > this.maxY ? y - this.maxY : 0.0;
    return dx * dx + dy * dy;
  }

  intersectsSegment(x1, y1, x2, y2) {
    const sMinX = Math.min(x1, x2);
    const sMaxX = Math.max(x1, x2);
    const sMinY = Math.min(y1, y2);
    const sMaxY = Math.max(y1, y2);

    if (sMaxX < this.minX || sMinX > this.maxX || sMaxY < this.minY || sMinY > this.maxY) {
      return false;
    }
    if (this.containsPoint(x1, y1) || this.containsPoint(x2, y2)) {
      return true;
    }

    const dx = x2 - x1;
    const dy = y2 - y1;
    let tMin = 0.0;
    let tMax = 1.0;

    if (dx === 0.0) {
      if (x1 < this.minX || x1 > this.maxX) return false;
    } else {
      let t1 = (this.minX - x1) / dx;
      let t2 = (this.maxX - x1) / dx;
      if (t1 > t2) [t1, t2] = [t2, t1];
      tMin = Math.max(tMin, t1);
      tMax = Math.min(tMax, t2);
      if (tMin > tMax) return false;
    }

    if (dy === 0.0) {
      if (y1 < this.minY || y1 > this.maxY) return false;
    } else {
      let t1 = (this.minY - y1) / dy;
      let t2 = (this.maxY - y1) / dy;
      if (t1 > t2) [t1, t2] = [t2, t1];
      tMin = Math.max(tMin, t1);
      tMax = Math.min(tMax, t2);
      if (tMin > tMax) return false;
    }

    return tMin <= tMax;
  }
}

export class StrTree {
  constructor(capacity = 16) {
    this.nodeCapacity = Math.max(2, capacity);
    this.numItems = 0;
    this.numNodes = 0;
    this.height = 0;
    this.rootIndex = -1;

    // Packed contiguous flat arrays
    this.boxesMinX = new Float64Array(0);
    this.boxesMinY = new Float64Array(0);
    this.boxesMaxX = new Float64Array(0);
    this.boxesMaxY = new Float64Array(0);
    this.childOffset = new Int32Array(0);
    this.childCount = new Int32Array(0);
    this.childIndices = new Int32Array(0);
    this.itemIds = new Int32Array(0);
    this.nodeLevels = new Int32Array(0); // for visualizer level mapping
  }

  static build(items, capacity = 16) {
    const tree = new StrTree(capacity);
    if (!items || items.length === 0) return tree;

    tree.numItems = items.length;
    const M = tree.nodeCapacity;

    // Temporary building structures
    let currentLevel = items.map((it, idx) => ({
      minX: it.rect.minX,
      minY: it.rect.minY,
      maxX: it.rect.maxX,
      maxY: it.rect.maxY,
      id: it.id,
      children: null,
      level: 0,
    }));

    const allLevels = [currentLevel];

    while (currentLevel.length > 1) {
      const nextLevel = [];
      const N = currentLevel.length;
      const P = Math.ceil(N / M);
      const S = Math.ceil(Math.sqrt(P));
      const Pslice = Math.ceil(P / S);
      const Cslice = Pslice * M;

      // Sort by center X
      currentLevel.sort((a, b) => {
        const cxA = (a.minX + a.maxX) * 0.5;
        const cxB = (b.minX + b.maxX) * 0.5;
        return cxA - cxB;
      });

      // Divide into vertical slices
      for (let s = 0; s < S; s++) {
        const start = s * Cslice;
        if (start >= N) break;
        const end = Math.min(start + Cslice, N);
        const slice = currentLevel.slice(start, end);

        // Sort slice by center Y
        slice.sort((a, b) => {
          const cyA = (a.minY + a.maxY) * 0.5;
          const cyB = (b.minY + b.maxY) * 0.5;
          return cyA - cyB;
        });

        // Group into nodes of capacity M
        for (let i = 0; i < slice.length; i += M) {
          const group = slice.slice(i, Math.min(i + M, slice.length));
          let minX = group[0].minX;
          let minY = group[0].minY;
          let maxX = group[0].maxX;
          let maxY = group[0].maxY;

          for (let g = 1; g < group.length; g++) {
            minX = Math.min(minX, group[g].minX);
            minY = Math.min(minY, group[g].minY);
            maxX = Math.max(maxX, group[g].maxX);
            maxY = Math.max(maxY, group[g].maxY);
          }

          nextLevel.push({
            minX,
            minY,
            maxX,
            maxY,
            id: -1,
            children: group,
            level: allLevels.length,
          });
        }
      }

      allLevels.push(nextLevel);
      currentLevel = nextLevel;
    }

    tree.height = allLevels.length;

    // Flatten into contiguous arrays in breadth-first index order
    let totalNodes = 0;
    for (const lvl of allLevels) totalNodes += lvl.length;
    tree.numNodes = totalNodes;

    tree.boxesMinX = new Float64Array(totalNodes);
    tree.boxesMinY = new Float64Array(totalNodes);
    tree.boxesMaxX = new Float64Array(totalNodes);
    tree.boxesMaxY = new Float64Array(totalNodes);
    tree.childOffset = new Int32Array(totalNodes);
    tree.childCount = new Int32Array(totalNodes);
    tree.itemIds = new Int32Array(totalNodes);
    tree.nodeLevels = new Int32Array(totalNodes);

    let childIndicesList = [];
    let nodeIndex = 0;

    // Assign node IDs level by level from root (top) to leaves (bottom)
    const reversedLevels = [...allLevels].reverse();
    for (const lvl of reversedLevels) {
      for (const node of lvl) {
        node._index = nodeIndex++;
      }
    }

    for (const lvl of reversedLevels) {
      for (const node of lvl) {
        const idx = node._index;
        tree.boxesMinX[idx] = node.minX;
        tree.boxesMinY[idx] = node.minY;
        tree.boxesMaxX[idx] = node.maxX;
        tree.boxesMaxY[idx] = node.maxY;
        tree.itemIds[idx] = node.id;
        tree.nodeLevels[idx] = node.level;

        if (node.children && node.children.length > 0) {
          tree.childOffset[idx] = childIndicesList.length;
          tree.childCount[idx] = node.children.length;
          for (const ch of node.children) {
            childIndicesList.push(ch._index);
          }
        } else {
          tree.childOffset[idx] = 0;
          tree.childCount[idx] = 0;
        }
      }
    }

    tree.rootIndex = 0;
    tree.childIndices = new Int32Array(childIndicesList);
    return tree;
  }

  query(win) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    if (
      win.maxX < this.boxesMinX[root] ||
      win.minX > this.boxesMaxX[root] ||
      win.maxY < this.boxesMinY[root] ||
      win.minY > this.boxesMaxY[root]
    ) {
      return [];
    }

    const results = [];
    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) results.push(id);
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < count; i++) {
          const child = this.childIndices[offset + i];
          if (
            !(
              win.maxX < this.boxesMinX[child] ||
              win.minX > this.boxesMaxX[child] ||
              win.maxY < this.boxesMinY[child] ||
              win.minY > this.boxesMaxY[child]
            )
          ) {
            stack.push(child);
          }
        }
      }
    }
    return results;
  }

  queryPoint(x, y) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    if (
      x < this.boxesMinX[root] ||
      x > this.boxesMaxX[root] ||
      y < this.boxesMinY[root] ||
      y > this.boxesMaxY[root]
    ) {
      return [];
    }

    const results = [];
    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) results.push(id);
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < count; i++) {
          const child = this.childIndices[offset + i];
          if (
            x >= this.boxesMinX[child] &&
            x <= this.boxesMaxX[child] &&
            y >= this.boxesMinY[child] &&
            y <= this.boxesMaxY[child]
          ) {
            stack.push(child);
          }
        }
      }
    }
    return results;
  }

  queryKNN(x, y, k) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const rootDist = dx * dx + dy * dy;

    const heap = [{ dist: rootDist, node: root }];
    const candidates = []; // sorted by dist

    while (heap.length > 0) {
      // Pop min
      heap.sort((a, b) => a.dist - b.dist);
      const { dist: nodeDist, node: curr } = heap.shift();

      if (candidates.length >= k && nodeDist >= candidates[k - 1].dist) {
        break;
      }

      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) {
          candidates.push({ dist: nodeDist, id });
          candidates.sort((a, b) => a.dist - b.dist);
          if (candidates.length > k) candidates.pop();
        }
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < count; i++) {
          const child = this.childIndices[offset + i];
          const cdx = x < this.boxesMinX[child] ? this.boxesMinX[child] - x : x > this.boxesMaxX[child] ? x - this.boxesMaxX[child] : 0;
          const cdy = y < this.boxesMinY[child] ? this.boxesMinY[child] - y : y > this.boxesMaxY[child] ? y - this.boxesMaxY[child] : 0;
          const childDist = cdx * cdx + cdy * cdy;
          if (candidates.length < k || childDist < candidates[candidates.length - 1].dist) {
            heap.push({ dist: childDist, node: child });
          }
        }
      }
    }

    return candidates.map(c => c.id);
  }

  querySegment(x1, y1, x2, y2) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    const rootRect = new Rect(this.boxesMinX[root], this.boxesMinY[root], this.boxesMaxX[root], this.boxesMaxY[root]);
    if (!rootRect.intersectsSegment(x1, y1, x2, y2)) return [];

    const results = [];
    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) results.push(id);
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < count; i++) {
          const child = this.childIndices[offset + i];
          const cRect = new Rect(this.boxesMinX[child], this.boxesMinY[child], this.boxesMaxX[child], this.boxesMaxY[child]);
          if (cRect.intersectsSegment(x1, y1, x2, y2)) {
            stack.push(child);
          }
        }
      }
    }
    return results;
  }
}

// 5 Benchmark Spatial Generators
export function generateDataset(type, count, width = 1000, height = 1000) {
  const items = [];
  let seed = 12345;
  const rand = () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };

  switch (type) {
    case 'uniform':
      for (let i = 0; i < count; i++) {
        const x = rand() * (width - 30);
        const y = rand() * (height - 30);
        const w = 4 + rand() * 26;
        const h = 4 + rand() * 26;
        items.push({ rect: new Rect(x, y, x + w, y + h), id: i });
      }
      break;

    case 'clustered': {
      const numClusters = 6;
      const centers = [];
      for (let c = 0; c < numClusters; c++) {
        centers.push({ x: 100 + rand() * (width - 200), y: 100 + rand() * (height - 200) });
      }
      for (let i = 0; i < count; i++) {
        const c = centers[i % numClusters];
        const angle = rand() * Math.PI * 2;
        const radius = rand() * 90;
        const x = Math.max(0, Math.min(width - 25, c.x + Math.cos(angle) * radius));
        const y = Math.max(0, Math.min(height - 25, c.y + Math.sin(angle) * radius));
        const w = 4 + rand() * 20;
        const h = 4 + rand() * 20;
        items.push({ rect: new Rect(x, y, x + w, y + h), id: i });
      }
      break;
    }

    case 'diagonal':
      for (let i = 0; i < count; i++) {
        const t = (i / count) * (width - 30);
        const x = t + (rand() * 10 - 5);
        const y = t + (rand() * 10 - 5);
        const w = 5 + rand() * 15;
        const h = 5 + rand() * 15;
        items.push({ rect: new Rect(x, y, x + w, y + h), id: i });
      }
      break;

    case 'concentric': {
      const cx = width * 0.5;
      const cy = height * 0.5;
      const step = (Math.min(width, height) * 0.45) / count;
      for (let i = 0; i < count; i++) {
        const r = (i + 1) * step;
        items.push({ rect: new Rect(cx - r, cy - r, cx + r, cy + r), id: i });
      }
      break;
    }

    case 'grid': {
      const side = Math.ceil(Math.sqrt(count));
      const cellW = (width - 40) / side;
      const cellH = (height - 40) / side;
      let id = 0;
      for (let r = 0; r < side && id < count; r++) {
        for (let c = 0; c < side && id < count; c++) {
          const x = 20 + c * cellW + 1;
          const y = 20 + r * cellH + 1;
          items.push({ rect: new Rect(x, y, x + cellW - 2, y + cellH - 2), id: id++ });
        }
      }
      break;
    }
  }

  return items;
}
