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

  intersection(other) {
    if (!this.intersects(other)) return null;
    return new Rect(
      Math.max(this.minX, other.minX),
      Math.max(this.minY, other.minY),
      Math.min(this.maxX, other.maxX),
      Math.min(this.maxY, other.maxY)
    );
  }

  expand(delta) {
    return new Rect(
      this.minX - delta,
      this.minY - delta,
      this.maxX + delta,
      this.maxY + delta
    );
  }

  distanceSquaredToRect(other) {
    if (this.intersects(other)) return 0.0;
    const dx = this.maxX < other.minX ? other.minX - this.maxX : this.minX > other.maxX ? this.minX - other.maxX : 0.0;
    const dy = this.maxY < other.minY ? other.minY - this.maxY : this.minY > other.maxY ? this.minY - other.maxY : 0.0;
    return dx * dx + dy * dy;
  }

  distanceToRect(other) {
    return Math.sqrt(this.distanceSquaredToRect(other));
  }

  iou(other) {
    const inter = this.intersection(other);
    if (!inter) return 0.0;
    const areaA = (this.maxX - this.minX) * (this.maxY - this.minY);
    const areaB = (other.maxX - other.minX) * (other.maxY - other.minY);
    const interArea = (inter.maxX - inter.minX) * (inter.maxY - inter.minY);
    const unionArea = areaA + areaB - interArea;
    return unionArea <= 0.0 ? 0.0 : interArea / unionArea;
  }

  intersectsCircle(cx, cy, radius) {
    if (radius < 0.0) return false;
    return this.distanceSquaredToPoint(cx, cy) <= radius * radius;
  }
}

export class Box3D {
  constructor(minX, minY, minZ, maxX, maxY, maxZ) {
    this.minX = Math.min(minX, maxX);
    this.minY = Math.min(minY, maxY);
    this.minZ = Math.min(minZ, maxZ);
    this.maxX = Math.max(minX, maxX);
    this.maxY = Math.max(minY, maxY);
    this.maxZ = Math.max(minZ, maxZ);
  }

  intersects(other) {
    return !(
      this.maxX < other.minX ||
      this.minX > other.maxX ||
      this.maxY < other.minY ||
      this.minY > other.maxY ||
      this.maxZ < other.minZ ||
      this.minZ > other.maxZ
    );
  }

  containsPoint(x, y, z) {
    return (
      this.minX <= x &&
      x <= this.maxX &&
      this.minY <= y &&
      y <= this.maxY &&
      this.minZ <= z &&
      z <= this.maxZ
    );
  }

  containsBox(other) {
    return (
      this.minX <= other.minX &&
      other.maxX <= this.maxX &&
      this.minY <= other.minY &&
      other.maxY <= this.maxY &&
      this.minZ <= other.minZ &&
      other.maxZ <= this.maxZ
    );
  }

  union(other) {
    return new Box3D(
      Math.min(this.minX, other.minX),
      Math.min(this.minY, other.minY),
      Math.min(this.minZ, other.minZ),
      Math.max(this.maxX, other.maxX),
      Math.max(this.maxY, other.maxY),
      Math.max(this.maxZ, other.maxZ)
    );
  }

  intersection(other) {
    if (!this.intersects(other)) return null;
    return new Box3D(
      Math.max(this.minX, other.minX),
      Math.max(this.minY, other.minY),
      Math.max(this.minZ, other.minZ),
      Math.min(this.maxX, other.maxX),
      Math.min(this.maxY, other.maxY),
      Math.min(this.maxZ, other.maxZ)
    );
  }

  volume() {
    return (this.maxX - this.minX) * (this.maxY - this.minY) * (this.maxZ - this.minZ);
  }

  surfaceArea() {
    const dx = this.maxX - this.minX;
    const dy = this.maxY - this.minY;
    const dz = this.maxZ - this.minZ;
    return 2.0 * (dx * dy + dy * dz + dz * dx);
  }

  centerX() {
    return (this.minX + this.maxX) / 2.0;
  }

  centerY() {
    return (this.minY + this.maxY) / 2.0;
  }

  centerZ() {
    return (this.minZ + this.maxZ) / 2.0;
  }

  expand(delta) {
    return new Box3D(
      this.minX - delta,
      this.minY - delta,
      this.minZ - delta,
      this.maxX + delta,
      this.maxY + delta,
      this.maxZ + delta
    );
  }

  distanceSquaredToPoint(x, y, z) {
    const dx = x < this.minX ? this.minX - x : x > this.maxX ? x - this.maxX : 0.0;
    const dy = y < this.minY ? this.minY - y : y > this.maxY ? y - this.maxY : 0.0;
    const dz = z < this.minZ ? this.minZ - z : z > this.maxZ ? z - this.maxZ : 0.0;
    return dx * dx + dy * dy + dz * dz;
  }

  distanceToBox(other) {
    if (this.intersects(other)) return 0.0;
    const dx = this.maxX < other.minX ? other.minX - this.maxX : other.maxX < this.minX ? this.minX - other.maxX : 0.0;
    const dy = this.maxY < other.minY ? other.minY - this.maxY : other.maxY < this.minY ? this.minY - other.maxY : 0.0;
    const dz = this.maxZ < other.minZ ? other.minZ - this.maxZ : other.maxZ < this.minZ ? this.minZ - other.maxZ : 0.0;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  iou(other) {
    const inter = this.intersection(other);
    if (!inter) return 0.0;
    const interVol = inter.volume();
    const unionVol = this.volume() + other.volume() - interVol;
    return unionVol <= 0.0 ? 0.0 : interVol / unionVol;
  }

  intersectsSphere(cx, cy, cz, radius) {
    if (radius < 0.0) return false;
    return this.distanceSquaredToPoint(cx, cy, cz) <= radius * radius;
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

  queryCount(win) {
    if (this.rootIndex < 0 || this.numItems === 0) return 0;
    const root = this.rootIndex;
    if (
      win.maxX < this.boxesMinX[root] ||
      win.minX > this.boxesMaxX[root] ||
      win.maxY < this.boxesMinY[root] ||
      win.minY > this.boxesMaxY[root]
    ) {
      return 0;
    }

    let count = 0;
    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
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
    return count;
  }

  queryPointCount(x, y) {
    if (this.rootIndex < 0 || this.numItems === 0) return 0;
    const root = this.rootIndex;
    if (
      x < this.boxesMinX[root] ||
      x > this.boxesMaxX[root] ||
      y < this.boxesMinY[root] ||
      y > this.boxesMaxY[root]
    ) {
      return 0;
    }

    let count = 0;
    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
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
    return count;
  }

  queryFirst(win, predicate) {
    if (this.rootIndex < 0 || this.numItems === 0) return null;
    const root = this.rootIndex;
    if (
      win.maxX < this.boxesMinX[root] ||
      win.minX > this.boxesMaxX[root] ||
      win.maxY < this.boxesMinY[root] ||
      win.minY > this.boxesMaxY[root]
    ) {
      return null;
    }

    const stack = [root];

    while (stack.length > 0) {
      const curr = stack.pop();
      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0 && predicate(id)) return id;
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
    return null;
  }

  queryCircle(cx, cy, radius) {
    if (this.rootIndex < 0 || this.numItems === 0 || radius < 0.0) return [];
    const root = this.rootIndex;
    const rSq = radius * radius;
    const rDx = cx < this.boxesMinX[root] ? this.boxesMinX[root] - cx : cx > this.boxesMaxX[root] ? cx - this.boxesMaxX[root] : 0.0;
    const rDy = cy < this.boxesMinY[root] ? this.boxesMinY[root] - cy : cy > this.boxesMaxY[root] ? cy - this.boxesMaxY[root] : 0.0;
    if (rDx * rDx + rDy * rDy > rSq) return [];

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
          const dx = cx < this.boxesMinX[child] ? this.boxesMinX[child] - cx : cx > this.boxesMaxX[child] ? cx - this.boxesMaxX[child] : 0.0;
          const dy = cy < this.boxesMinY[child] ? this.boxesMinY[child] - cy : cy > this.boxesMaxY[child] ? cy - this.boxesMaxY[child] : 0.0;
          if (dx * dx + dy * dy <= rSq) {
            stack.push(child);
          }
        }
      }
    }
    return results;
  }

  queryCircleCount(cx, cy, radius) {
    if (this.rootIndex < 0 || this.numItems === 0 || radius < 0.0) return 0;
    const root = this.rootIndex;
    const rSq = radius * radius;
    const rDx = cx < this.boxesMinX[root] ? this.boxesMinX[root] - cx : cx > this.boxesMaxX[root] ? cx - this.boxesMaxX[root] : 0.0;
    const rDy = cy < this.boxesMinY[root] ? this.boxesMinY[root] - cy : cy > this.boxesMaxY[root] ? cy - this.boxesMaxY[root] : 0.0;
    if (rDx * rDx + rDy * rDy > rSq) return 0;

    let count = 0;
    const stack = [root];
    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
          const child = this.childIndices[offset + i];
          const dx = cx < this.boxesMinX[child] ? this.boxesMinX[child] - cx : cx > this.boxesMaxX[child] ? cx - this.boxesMaxX[child] : 0.0;
          const dy = cy < this.boxesMinY[child] ? this.boxesMinY[child] - cy : cy > this.boxesMaxY[child] ? cy - this.boxesMaxY[child] : 0.0;
          if (dx * dx + dy * dy <= rSq) {
            stack.push(child);
          }
        }
      }
    }
    return count;
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

  queryKNNWithDistance(x, y, k) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const rootDist = dx * dx + dy * dy;

    const heap = [{ dist: rootDist, node: root }];
    const candidates = []; // sorted by dist

    while (heap.length > 0) {
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

    return candidates.map(c => [c.id, c.dist]);
  }

  queryKNNWithPredicate(x, y, k, predicate) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const rootDist = dx * dx + dy * dy;

    const heap = [{ dist: rootDist, node: root }];
    const candidates = [];

    while (heap.length > 0) {
      heap.sort((a, b) => a.dist - b.dist);
      const { dist: nodeDist, node: curr } = heap.shift();

      if (candidates.length >= k && nodeDist >= candidates[k - 1].dist) {
        break;
      }

      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0 && predicate(id)) {
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

  queryKNNWithPredicateAndDistance(x, y, k, predicate) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const rootDist = dx * dx + dy * dy;

    const heap = [{ dist: rootDist, node: root }];
    const candidates = [];

    while (heap.length > 0) {
      heap.sort((a, b) => a.dist - b.dist);
      const { dist: nodeDist, node: curr } = heap.shift();

      if (candidates.length >= k && nodeDist >= candidates[k - 1].dist) {
        break;
      }

      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0 && predicate(id)) {
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

    return candidates.map(c => [c.id, c.dist]);
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

export class StrTree3D {
  constructor(capacity = 16) {
    this.nodeCapacity = Math.max(2, capacity);
    this.numItems = 0;
    this.numNodes = 0;
    this.height = 0;
    this.rootIndex = -1;

    this.boxesMinX = new Float64Array(0);
    this.boxesMinY = new Float64Array(0);
    this.boxesMinZ = new Float64Array(0);
    this.boxesMaxX = new Float64Array(0);
    this.boxesMaxY = new Float64Array(0);
    this.boxesMaxZ = new Float64Array(0);
    this.childOffset = new Int32Array(0);
    this.childCount = new Int32Array(0);
    this.itemIds = new Int32Array(0);
    this.nodeLevels = new Int32Array(0);
    this.childIndices = new Int32Array(0);
  }

  static build(items, capacity = 16) {
    const tree = new StrTree3D(capacity);
    const n = items.length;
    tree.numItems = n;
    if (n === 0) return tree;

    const M = tree.nodeCapacity;

    const sortSubZ = (arr, start, end) => {
      const sub = arr.slice(start, end);
      sub.sort((a, b) => a.box.centerZ() - b.box.centerZ());
      for (let i = 0; i < sub.length; i++) arr[start + i] = sub[i];
    };

    const sortSubY = (arr, start, end) => {
      const sub = arr.slice(start, end);
      sub.sort((a, b) => a.box.centerY() - b.box.centerY());
      for (let i = 0; i < sub.length; i++) arr[start + i] = sub[i];
    };

    const sort3D = (arr) => {
      const len = arr.length;
      if (len <= M) return;
      const pages = Math.ceil(len / M);
      const slabs = Math.ceil(Math.cbrt(pages));
      const pagesPerSlab = Math.ceil(pages / slabs);
      const slabCap = pagesPerSlab * M;

      arr.sort((a, b) => a.box.centerX() - b.box.centerX());

      let slabStart = 0;
      while (slabStart < len) {
        const slabEnd = Math.min(len, slabStart + slabCap);
        const slabLen = slabEnd - slabStart;
        const slabPages = Math.ceil(slabLen / M);
        const cols = Math.ceil(Math.sqrt(slabPages));
        const pagesPerCol = Math.ceil(slabPages / cols);
        const colCap = pagesPerCol * M;

        sortSubY(arr, slabStart, slabEnd);

        let colStart = slabStart;
        while (colStart < slabEnd) {
          const colEnd = Math.min(slabEnd, colStart + colCap);
          sortSubZ(arr, colStart, colEnd);
          colStart = colEnd;
        }

        slabStart = slabEnd;
      }
    };

    const currentItems = items.map(it => ({ box: it.box, id: it.id, children: null, level: 0 }));
    sort3D(currentItems);

    const allLevels = [currentItems];
    let currentLevel = currentItems;

    while (currentLevel.length > 1) {
      if (currentLevel.length <= M) {
        let uBox = currentLevel[0].box;
        for (let i = 1; i < currentLevel.length; i++) uBox = uBox.union(currentLevel[i].box);
        const root = { box: uBox, id: -1, children: currentLevel, level: allLevels.length };
        allLevels.push([root]);
        break;
      }

      sort3D(currentLevel);
      const nextLevel = [];
      let start = 0;
      while (start < currentLevel.length) {
        const end = Math.min(currentLevel.length, start + M);
        const children = currentLevel.slice(start, end);
        let uBox = children[0].box;
        for (let i = 1; i < children.length; i++) uBox = uBox.union(children[i].box);
        nextLevel.push({ box: uBox, id: -1, children, level: allLevels.length });
        start = end;
      }
      allLevels.push(nextLevel);
      currentLevel = nextLevel;
    }

    tree.height = allLevels.length;
    let totalNodes = 0;
    for (const lvl of allLevels) totalNodes += lvl.length;
    tree.numNodes = totalNodes;

    tree.boxesMinX = new Float64Array(totalNodes);
    tree.boxesMinY = new Float64Array(totalNodes);
    tree.boxesMinZ = new Float64Array(totalNodes);
    tree.boxesMaxX = new Float64Array(totalNodes);
    tree.boxesMaxY = new Float64Array(totalNodes);
    tree.boxesMaxZ = new Float64Array(totalNodes);
    tree.childOffset = new Int32Array(totalNodes);
    tree.childCount = new Int32Array(totalNodes);
    tree.itemIds = new Int32Array(totalNodes);
    tree.nodeLevels = new Int32Array(totalNodes);

    let childIndicesList = [];
    let nodeIndex = 0;
    const reversedLevels = [...allLevels].reverse();
    for (const lvl of reversedLevels) {
      for (const node of lvl) node._index = nodeIndex++;
    }

    for (const lvl of reversedLevels) {
      for (const node of lvl) {
        const idx = node._index;
        tree.boxesMinX[idx] = node.box.minX;
        tree.boxesMinY[idx] = node.box.minY;
        tree.boxesMinZ[idx] = node.box.minZ;
        tree.boxesMaxX[idx] = node.box.maxX;
        tree.boxesMaxY[idx] = node.box.maxY;
        tree.boxesMaxZ[idx] = node.box.maxZ;
        tree.itemIds[idx] = node.id;
        tree.nodeLevels[idx] = node.level;

        if (node.children && node.children.length > 0) {
          tree.childOffset[idx] = childIndicesList.length;
          tree.childCount[idx] = node.children.length;
          for (const ch of node.children) childIndicesList.push(ch._index);
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

  query(box) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    if (
      box.maxX < this.boxesMinX[root] || box.minX > this.boxesMaxX[root] ||
      box.maxY < this.boxesMinY[root] || box.minY > this.boxesMaxY[root] ||
      box.maxZ < this.boxesMinZ[root] || box.minZ > this.boxesMaxZ[root]
    ) return [];

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
          const ch = this.childIndices[offset + i];
          if (!(
            box.maxX < this.boxesMinX[ch] || box.minX > this.boxesMaxX[ch] ||
            box.maxY < this.boxesMinY[ch] || box.minY > this.boxesMaxY[ch] ||
            box.maxZ < this.boxesMinZ[ch] || box.minZ > this.boxesMaxZ[ch]
          )) {
            stack.push(ch);
          }
        }
      }
    }
    return results;
  }

  queryCount(box) {
    if (this.rootIndex < 0 || this.numItems === 0) return 0;
    const root = this.rootIndex;
    if (
      box.maxX < this.boxesMinX[root] || box.minX > this.boxesMaxX[root] ||
      box.maxY < this.boxesMinY[root] || box.minY > this.boxesMaxY[root] ||
      box.maxZ < this.boxesMinZ[root] || box.minZ > this.boxesMaxZ[root]
    ) return 0;

    let count = 0;
    const stack = [root];
    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        const id = this.itemIds[curr];
        if (id >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
          const ch = this.childIndices[offset + i];
          if (!(
            box.maxX < this.boxesMinX[ch] || box.minX > this.boxesMaxX[ch] ||
            box.maxY < this.boxesMinY[ch] || box.minY > this.boxesMaxY[ch] ||
            box.maxZ < this.boxesMinZ[ch] || box.minZ > this.boxesMaxZ[ch]
          )) {
            stack.push(ch);
          }
        }
      }
    }
    return count;
  }

  queryPoint(x, y, z) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    if (
      x < this.boxesMinX[root] || x > this.boxesMaxX[root] ||
      y < this.boxesMinY[root] || y > this.boxesMaxY[root] ||
      z < this.boxesMinZ[root] || z > this.boxesMaxZ[root]
    ) return [];

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
          const ch = this.childIndices[offset + i];
          if (
            x >= this.boxesMinX[ch] && x <= this.boxesMaxX[ch] &&
            y >= this.boxesMinY[ch] && y <= this.boxesMaxY[ch] &&
            z >= this.boxesMinZ[ch] && z <= this.boxesMaxZ[ch]
          ) {
            stack.push(ch);
          }
        }
      }
    }
    return results;
  }

  querySphere(cx, cy, cz, radius) {
    if (this.rootIndex < 0 || this.numItems === 0 || radius < 0.0) return [];
    const rSq = radius * radius;
    const root = this.rootIndex;
    const rDx = cx < this.boxesMinX[root] ? this.boxesMinX[root] - cx : cx > this.boxesMaxX[root] ? cx - this.boxesMaxX[root] : 0.0;
    const rDy = cy < this.boxesMinY[root] ? this.boxesMinY[root] - cy : cy > this.boxesMaxY[root] ? cy - this.boxesMaxY[root] : 0.0;
    const rDz = cz < this.boxesMinZ[root] ? this.boxesMinZ[root] - cz : cz > this.boxesMaxZ[root] ? cz - this.boxesMaxZ[root] : 0.0;
    if (rDx * rDx + rDy * rDy + rDz * rDz > rSq) return [];

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
          const ch = this.childIndices[offset + i];
          const dx = cx < this.boxesMinX[ch] ? this.boxesMinX[ch] - cx : cx > this.boxesMaxX[ch] ? cx - this.boxesMaxX[ch] : 0.0;
          const dy = cy < this.boxesMinY[ch] ? this.boxesMinY[ch] - cy : cy > this.boxesMaxY[ch] ? cy - this.boxesMaxY[ch] : 0.0;
          const dz = cz < this.boxesMinZ[ch] ? this.boxesMinZ[ch] - cz : cz > this.boxesMaxZ[ch] ? cz - this.boxesMaxZ[ch] : 0.0;
          if (dx * dx + dy * dy + dz * dz <= rSq) stack.push(ch);
        }
      }
    }
    return results;
  }
}
