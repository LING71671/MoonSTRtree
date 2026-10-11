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

  touches(other) {
    if (!this.intersects(other)) return false;
    const overlapX = this.minX < other.maxX && this.maxX > other.minX;
    const overlapY = this.minY < other.maxY && this.maxY > other.minY;
    return !(overlapX && overlapY);
  }

  covers(other) {
    return (
      this.minX <= other.minX &&
      this.maxX >= other.maxX &&
      this.minY <= other.minY &&
      this.maxY >= other.maxY
    );
  }

  coveredBy(other) {
    return other.covers(this);
  }

  contains(other) {
    if (!this.covers(other)) return false;
    const overlapX = this.minX < other.maxX && this.maxX > other.minX;
    const overlapY = this.minY < other.maxY && this.maxY > other.minY;
    return overlapX && overlapY;
  }

  within(other) {
    return other.contains(this);
  }

  equalsExact(other) {
    return (
      this.minX === other.minX &&
      this.minY === other.minY &&
      this.maxX === other.maxX &&
      this.maxY === other.maxY
    );
  }

  disjoint(other) {
    return !this.intersects(other);
  }

  overlaps(other) {
    const overlapX = this.minX < other.maxX && this.maxX > other.minX;
    const overlapY = this.minY < other.maxY && this.maxY > other.minY;
    return overlapX && overlapY && !this.covers(other) && !other.covers(this);
  }

  evaluatePredicate(other, predicate) {
    switch (predicate) {
      case 'intersects':
      case SpatialPredicate.INTERSECTS:
        return this.intersects(other);
      case 'contains':
      case SpatialPredicate.CONTAINS:
        return this.contains(other);
      case 'within':
      case SpatialPredicate.WITHIN:
        return this.within(other);
      case 'touches':
      case SpatialPredicate.TOUCHES:
        return this.touches(other);
      case 'overlaps':
      case SpatialPredicate.OVERLAPS:
        return this.overlaps(other);
      case 'disjoint':
      case SpatialPredicate.DISJOINT:
        return this.disjoint(other);
      case 'equals':
      case SpatialPredicate.EQUALS:
        return this.equalsExact(other);
      case 'covers':
      case SpatialPredicate.COVERS:
        return this.covers(other);
      case 'covered_by':
      case SpatialPredicate.COVERED_BY:
        return this.coveredBy(other);
      default:
        return this.intersects(other);
    }
  }

  relate(other) {
    const overlapX = this.minX < other.maxX && this.maxX > other.minX;
    const overlapY = this.minY < other.maxY && this.maxY > other.minY;

    const c0 = overlapX && overlapY ? '2' : 'F';

    const bInIa =
      (other.minX > this.minX && other.minX < this.maxX && overlapY) ||
      (other.maxX > this.minX && other.maxX < this.maxX && overlapY) ||
      (other.minY > this.minY && other.minY < this.maxY && overlapX) ||
      (other.maxY > this.minY && other.maxY < this.maxY && overlapX);
    const c1 = bInIa ? '1' : 'F';

    const c2 = other.covers(this) ? 'F' : '2';

    const aInIb =
      (this.minX > other.minX && this.minX < other.maxX && overlapY) ||
      (this.maxX > other.minX && this.maxX < other.maxX && overlapY) ||
      (this.minY > other.minY && this.minY < other.maxY && overlapX) ||
      (this.maxY > other.minY && this.maxY < other.maxY && overlapX);
    const c3 = aInIb ? '1' : 'F';

    const share1D =
      ((this.minX === other.minX ||
        this.minX === other.maxX ||
        this.maxX === other.minX ||
        this.maxX === other.maxX) &&
        overlapY) ||
      ((this.minY === other.minY ||
        this.minY === other.maxY ||
        this.maxY === other.minY ||
        this.maxY === other.maxY) &&
        overlapX);

    const c4 = share1D ? '1' : this.intersects(other) ? '0' : 'F';

    const aStrictlyInIb =
      other.minX < this.minX &&
      other.maxX > this.maxX &&
      other.minY < this.minY &&
      other.maxY > this.maxY;
    const c5 = this.equalsExact(other) || aStrictlyInIb ? 'F' : '1';

    const c6 = this.covers(other) ? 'F' : '2';

    const bStrictlyInIa =
      this.minX < other.minX &&
      this.maxX > other.maxX &&
      this.minY < other.minY &&
      this.maxY > other.maxY;
    const c7 = this.equalsExact(other) || bStrictlyInIa ? 'F' : '1';

    const c8 = '2';

    return `${c0}${c1}${c2}${c3}${c4}${c5}${c6}${c7}${c8}`;
  }
}

export const SpatialPredicate = Object.freeze({
  INTERSECTS: 'intersects',
  CONTAINS: 'contains',
  WITHIN: 'within',
  TOUCHES: 'touches',
  OVERLAPS: 'overlaps',
  DISJOINT: 'disjoint',
  EQUALS: 'equals',
  COVERS: 'covers',
  COVERED_BY: 'covered_by',
});

export function matchesDe9imPattern(matrix, pattern) {
  if (!matrix || !pattern || matrix.length !== 9 || pattern.length !== 9) return false;
  for (let i = 0; i < 9; i++) {
    const p = pattern[i];
    const m = matrix[i];
    if (p === '*') continue;
    if (p === 'T') {
      if (m !== '0' && m !== '1' && m !== '2') return false;
      continue;
    }
    if (p === 'F') {
      if (m !== 'F') return false;
      continue;
    }
    if (p !== m) return false;
  }
  return true;
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

  intersectsSegment(x1, y1, z1, x2, y2, z2) {
    const segMinX = Math.min(x1, x2);
    const segMaxX = Math.max(x1, x2);
    const segMinY = Math.min(y1, y2);
    const segMaxY = Math.max(y1, y2);
    const segMinZ = Math.min(z1, z2);
    const segMaxZ = Math.max(z1, z2);

    if (
      segMaxX < this.minX || segMinX > this.maxX ||
      segMaxY < this.minY || segMinY > this.maxY ||
      segMaxZ < this.minZ || segMinZ > this.maxZ
    ) return false;

    if (this.containsPoint(x1, y1, z1) || this.containsPoint(x2, y2, z2)) return true;

    const dx = x2 - x1;
    const dy = y2 - y1;
    const dz = z2 - z1;

    let tMin = 0.0;
    let tMax = 1.0;

    if (dx === 0.0) {
      if (x1 < this.minX || x1 > this.maxX) return false;
    } else {
      let t1 = (this.minX - x1) / dx;
      let t2 = (this.maxX - x1) / dx;
      if (t1 > t2) [t1, t2] = [t2, t1];
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      if (tMin > tMax) return false;
    }

    if (dy === 0.0) {
      if (y1 < this.minY || y1 > this.maxY) return false;
    } else {
      let t1 = (this.minY - y1) / dy;
      let t2 = (this.maxY - y1) / dy;
      if (t1 > t2) [t1, t2] = [t2, t1];
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      if (tMin > tMax) return false;
    }

    if (dz === 0.0) {
      if (z1 < this.minZ || z1 > this.maxZ) return false;
    } else {
      let t1 = (this.minZ - z1) / dz;
      let t2 = (this.maxZ - z1) / dz;
      if (t1 > t2) [t1, t2] = [t2, t1];
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
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

  querySpatialPredicate(rect, predicate) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;

    if (predicate === 'disjoint' || predicate === SpatialPredicate.DISJOINT) {
      const results = [];
      const stack = [root];
      while (stack.length > 0) {
        const curr = stack.pop();
        const count = this.childCount[curr];
        if (count === 0) {
          const id = this.itemIds[curr];
          if (id >= 0) {
            const leafRect = new Rect(
              this.boxesMinX[curr],
              this.boxesMinY[curr],
              this.boxesMaxX[curr],
              this.boxesMaxY[curr]
            );
            if (rect.evaluatePredicate(leafRect, predicate)) {
              results.push(id);
            }
          }
        } else {
          const offset = this.childOffset[curr];
          for (let i = 0; i < count; i++) {
            stack.push(this.childIndices[offset + i]);
          }
        }
      }
      return results;
    }

    if (
      rect.maxX < this.boxesMinX[root] ||
      rect.minX > this.boxesMaxX[root] ||
      rect.maxY < this.boxesMinY[root] ||
      rect.minY > this.boxesMaxY[root]
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
        if (id >= 0) {
          const leafRect = new Rect(
            this.boxesMinX[curr],
            this.boxesMinY[curr],
            this.boxesMaxX[curr],
            this.boxesMaxY[curr]
          );
          if (rect.evaluatePredicate(leafRect, predicate)) {
            results.push(id);
          }
        }
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < count; i++) {
          const child = this.childIndices[offset + i];
          if (
            !(
              rect.maxX < this.boxesMinX[child] ||
              rect.minX > this.boxesMaxX[child] ||
              rect.maxY < this.boxesMinY[child] ||
              rect.minY > this.boxesMaxY[child]
            )
          ) {
            stack.push(child);
          }
        }
      }
    }
    return results;
  }

  spatialJoinPredicate(other, predicate = SpatialPredicate.INTERSECTS) {
    if (
      this.rootIndex < 0 ||
      this.numItems === 0 ||
      other.rootIndex < 0 ||
      other.numItems === 0
    ) {
      return [];
    }

    const results = [];
    const stackA = [this.rootIndex];
    const stackB = [other.rootIndex];

    while (stackA.length > 0) {
      const currA = stackA.pop();
      const currB = stackB.pop();

      const disjointNodes =
        this.boxesMaxX[currA] < other.boxesMinX[currB] ||
        this.boxesMinX[currA] > other.boxesMaxX[currB] ||
        this.boxesMaxY[currA] < other.boxesMinY[currB] ||
        this.boxesMinY[currA] > other.boxesMaxY[currB];
      if (disjointNodes) continue;

      const countA = this.childCount[currA];
      const countB = other.childCount[currB];

      if (countA === 0 && countB === 0) {
        const idA = this.itemIds[currA];
        const idB = other.itemIds[currB];
        if (idA >= 0 && idB >= 0) {
          const rectA = new Rect(
            this.boxesMinX[currA],
            this.boxesMinY[currA],
            this.boxesMaxX[currA],
            this.boxesMaxY[currA]
          );
          const rectB = new Rect(
            other.boxesMinX[currB],
            other.boxesMinY[currB],
            other.boxesMaxX[currB],
            other.boxesMaxY[currB]
          );
          if (rectA.evaluatePredicate(rectB, predicate)) {
            results.push([idA, idB]);
          }
        }
      } else if (countA === 0) {
        const offsetB = other.childOffset[currB];
        for (let i = 0; i < countB; i++) {
          stackA.push(currA);
          stackB.push(other.childIndices[offsetB + i]);
        }
      } else if (countB === 0) {
        const offsetA = this.childOffset[currA];
        for (let i = 0; i < countA; i++) {
          stackA.push(this.childIndices[offsetA + i]);
          stackB.push(currB);
        }
      } else {
        const areaA =
          (this.boxesMaxX[currA] - this.boxesMinX[currA]) *
          (this.boxesMaxY[currA] - this.boxesMinY[currA]);
        const areaB =
          (other.boxesMaxX[currB] - other.boxesMinX[currB]) *
          (other.boxesMaxY[currB] - other.boxesMinY[currB]);
        if (areaA >= areaB) {
          const offsetA = this.childOffset[currA];
          for (let i = 0; i < countA; i++) {
            stackA.push(this.childIndices[offsetA + i]);
            stackB.push(currB);
          }
        } else {
          const offsetB = other.childOffset[currB];
          for (let i = 0; i < countB; i++) {
            stackA.push(currA);
            stackB.push(other.childIndices[offsetB + i]);
          }
        }
      }
    }
    return results;
  }

  spatialJoin(other) {
    return this.spatialJoinPredicate(other, SpatialPredicate.INTERSECTS);
  }

  dbscan(eps, minPts = 1) {
    if (this.rootIndex < 0 || this.numItems === 0) {
      return { labels: [], numClusters: 0, numNoise: 0, clusterSizes: [] };
    }
    const minPtsClamped = Math.max(1, minPts);
    const epsSq = eps * eps;

    const leafIds = [];
    const centersX = [];
    const centersY = [];
    let maxId = 0;

    for (let i = 0; i < this.boxesMinX.length; i++) {
      if (this.childCount[i] === 0 && this.itemIds[i] >= 0) {
        const id = this.itemIds[i];
        leafIds.push(id);
        centersX.push((this.boxesMinX[i] + this.boxesMaxX[i]) * 0.5);
        centersY.push((this.boxesMinY[i] + this.boxesMaxY[i]) * 0.5);
        if (id > maxId) maxId = id;
      }
    }

    const n = leafIds.length;
    if (n === 0) {
      return { labels: [], numClusters: 0, numNoise: 0, clusterSizes: [] };
    }

    const idToIdx = new Map();
    for (let i = 0; i < n; i++) {
      idToIdx.set(leafIds[i], i);
    }

    const labels = new Int32Array(n).fill(-2);
    let currentCluster = 0;

    for (let i = 0; i < n; i++) {
      if (labels[i] !== -2) continue;

      const cx = centersX[i];
      const cy = centersY[i];
      const candIds = this.queryCircle(cx, cy, eps);
      const coreNeighbors = [];

      for (let k = 0; k < candIds.length; k++) {
        const idx = idToIdx.get(candIds[k]);
        if (idx !== undefined) {
          const dx = cx - centersX[idx];
          const dy = cy - centersY[idx];
          if (dx * dx + dy * dy <= epsSq) {
            coreNeighbors.push(idx);
          }
        }
      }

      if (coreNeighbors.length < minPtsClamped) {
        labels[i] = -1;
      } else {
        labels[i] = currentCluster;
        const queue = [];
        for (let k = 0; k < coreNeighbors.length; k++) {
          if (coreNeighbors[k] !== i) queue.push(coreNeighbors[k]);
        }

        let head = 0;
        while (head < queue.length) {
          const qIdx = queue[head++];
          if (labels[qIdx] === -1) {
            labels[qIdx] = currentCluster;
          }
          if (labels[qIdx] !== -2) continue;

          labels[qIdx] = currentCluster;
          const qCx = centersX[qIdx];
          const qCy = centersY[qIdx];
          const qCandIds = this.queryCircle(qCx, qCy, eps);
          const qCoreNeighbors = [];

          for (let k = 0; k < qCandIds.length; k++) {
            const idx = idToIdx.get(qCandIds[k]);
            if (idx !== undefined) {
              const dx = qCx - centersX[idx];
              const dy = qCy - centersY[idx];
              if (dx * dx + dy * dy <= epsSq) {
                qCoreNeighbors.push(idx);
              }
            }
          }

          if (qCoreNeighbors.length >= minPtsClamped) {
            for (let k = 0; k < qCoreNeighbors.length; k++) {
              const nIdx = qCoreNeighbors[k];
              if (labels[nIdx] === -2 || labels[nIdx] === -1) {
                queue.push(nIdx);
              }
            }
          }
        }
        currentCluster++;
      }
    }

    const numClusters = currentCluster;
    let numNoise = 0;
    const clusterSizes = new Array(numClusters).fill(0);
    const labelsById = new Array(maxId + 1).fill(-1);

    for (let i = 0; i < n; i++) {
      const lbl = labels[i];
      const id = leafIds[i];
      labelsById[id] = lbl;
      if (lbl < 0) {
        numNoise++;
      } else {
        clusterSizes[lbl]++;
      }
    }

    return {
      labels: labelsById,
      numClusters,
      numNoise,
      clusterSizes,
    };
  }

  aggregateGrid(cellWidth, cellHeight, hotspotThreshold = 1) {
    if (this.rootIndex < 0 || this.numItems === 0 || cellWidth <= 0 || cellHeight <= 0) {
      return {
        cells: [],
        totalCells: 0,
        maxDensity: 0,
        avgDensity: 0.0,
        hotspotCells: [],
      };
    }

    const threshold = Math.max(1, hotspotThreshold);
    const map = new Map();

    for (let i = 0; i < this.boxesMinX.length; i++) {
      if (this.childCount[i] === 0 && this.itemIds[i] >= 0) {
        const cx = (this.boxesMinX[i] + this.boxesMaxX[i]) * 0.5;
        const cy = (this.boxesMinY[i] + this.boxesMaxY[i]) * 0.5;
        const col = Math.floor(cx / cellWidth);
        const row = Math.floor(cy / cellHeight);
        const key = `${col},${row}`;
        const entry = map.get(key);
        if (entry) {
          entry.count++;
        } else {
          map.set(key, { col, row, count: 1 });
        }
      }
    }

    const cells = [];
    let maxDensity = 0;
    let sumCount = 0;
    const hotspots = [];

    for (const val of map.values()) {
      const minX = val.col * cellWidth;
      const minY = val.row * cellHeight;
      const cell = {
        col: val.col,
        row: val.row,
        count: val.count,
        bounds: new Rect(minX, minY, minX + cellWidth, minY + cellHeight),
      };
      cells.push(cell);
      if (val.count > maxDensity) maxDensity = val.count;
      sumCount += val.count;
      if (val.count >= threshold) hotspots.push(cell);
    }

    hotspots.sort((a, b) => b.count - a.count);
    const totalCells = cells.length;
    const avgDensity = totalCells > 0 ? sumCount / totalCells : 0.0;

    return {
      cells,
      totalCells,
      maxDensity,
      avgDensity,
      hotspotCells: hotspots,
    };
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

  queryPointCount(x, y, z) {
    if (this.rootIndex < 0 || this.numItems === 0) return 0;
    const root = this.rootIndex;
    if (
      x < this.boxesMinX[root] || x > this.boxesMaxX[root] ||
      y < this.boxesMinY[root] || y > this.boxesMaxY[root] ||
      z < this.boxesMinZ[root] || z > this.boxesMaxZ[root]
    ) return 0;

    let count = 0;
    const stack = [root];
    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        if (this.itemIds[curr] >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
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
    return count;
  }

  querySphereCount(cx, cy, cz, radius) {
    if (this.rootIndex < 0 || this.numItems === 0 || radius < 0.0) return 0;
    const rSq = radius * radius;
    const root = this.rootIndex;
    const rDx = cx < this.boxesMinX[root] ? this.boxesMinX[root] - cx : cx > this.boxesMaxX[root] ? cx - this.boxesMaxX[root] : 0.0;
    const rDy = cy < this.boxesMinY[root] ? this.boxesMinY[root] - cy : cy > this.boxesMaxY[root] ? cy - this.boxesMaxY[root] : 0.0;
    const rDz = cz < this.boxesMinZ[root] ? this.boxesMinZ[root] - cz : cz > this.boxesMaxZ[root] ? cz - this.boxesMaxZ[root] : 0.0;
    if (rDx * rDx + rDy * rDy + rDz * rDz > rSq) return 0;

    let count = 0;
    const stack = [root];
    while (stack.length > 0) {
      const curr = stack.pop();
      const cCount = this.childCount[curr];
      if (cCount === 0) {
        if (this.itemIds[curr] >= 0) count++;
      } else {
        const offset = this.childOffset[curr];
        for (let i = 0; i < cCount; i++) {
          const ch = this.childIndices[offset + i];
          const dx = cx < this.boxesMinX[ch] ? this.boxesMinX[ch] - cx : cx > this.boxesMaxX[ch] ? cx - this.boxesMaxX[ch] : 0.0;
          const dy = cy < this.boxesMinY[ch] ? this.boxesMinY[ch] - cy : cy > this.boxesMaxY[ch] ? cy - this.boxesMaxY[ch] : 0.0;
          const dz = cz < this.boxesMinZ[ch] ? this.boxesMinZ[ch] - cz : cz > this.boxesMaxZ[ch] ? cz - this.boxesMaxZ[ch] : 0.0;
          if (dx * dx + dy * dy + dz * dz <= rSq) stack.push(ch);
        }
      }
    }
    return count;
  }

  querySegment(x1, y1, z1, x2, y2, z2) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    const rootBox = new Box3D(
      this.boxesMinX[root], this.boxesMinY[root], this.boxesMinZ[root],
      this.boxesMaxX[root], this.boxesMaxY[root], this.boxesMaxZ[root]
    );
    if (!rootBox.intersectsSegment(x1, y1, z1, x2, y2, z2)) return [];

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
          const chBox = new Box3D(
            this.boxesMinX[ch], this.boxesMinY[ch], this.boxesMinZ[ch],
            this.boxesMaxX[ch], this.boxesMaxY[ch], this.boxesMaxZ[ch]
          );
          if (chBox.intersectsSegment(x1, y1, z1, x2, y2, z2)) {
            stack.push(ch);
          }
        }
      }
    }
    return results;
  }

  queryKNN(x, y, z, k) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const dz = z < this.boxesMinZ[root] ? this.boxesMinZ[root] - z : z > this.boxesMaxZ[root] ? z - this.boxesMaxZ[root] : 0;
    const rootDist = dx * dx + dy * dy + dz * dz;

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
          const cdz = z < this.boxesMinZ[child] ? this.boxesMinZ[child] - z : z > this.boxesMaxZ[child] ? z - this.boxesMaxZ[child] : 0;
          const childDist = cdx * cdx + cdy * cdy + cdz * cdz;
          if (candidates.length < k || childDist < candidates[candidates.length - 1].dist) {
            heap.push({ dist: childDist, node: child });
          }
        }
      }
    }

    return candidates.map(c => c.id);
  }

  queryKNNWithDistance(x, y, z, k) {
    if (k <= 0 || this.rootIndex < 0 || this.numItems === 0) return [];

    const root = this.rootIndex;
    const dx = x < this.boxesMinX[root] ? this.boxesMinX[root] - x : x > this.boxesMaxX[root] ? x - this.boxesMaxX[root] : 0;
    const dy = y < this.boxesMinY[root] ? this.boxesMinY[root] - y : y > this.boxesMaxY[root] ? y - this.boxesMaxY[root] : 0;
    const dz = z < this.boxesMinZ[root] ? this.boxesMinZ[root] - z : z > this.boxesMaxZ[root] ? z - this.boxesMaxZ[root] : 0;
    const rootDist = dx * dx + dy * dy + dz * dz;

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
          const cdz = z < this.boxesMinZ[child] ? this.boxesMinZ[child] - z : z > this.boxesMaxZ[child] ? z - this.boxesMaxZ[child] : 0;
          const childDist = cdx * cdx + cdy * cdy + cdz * cdz;
          if (candidates.length < k || childDist < candidates[candidates.length - 1].dist) {
            heap.push({ dist: childDist, node: child });
          }
        }
      }
    }

    return candidates.map(c => [c.id, c.dist]);
  }

  queryFirst(box, predicate) {
    if (this.rootIndex < 0 || this.numItems === 0) return null;
    const root = this.rootIndex;
    if (
      box.maxX < this.boxesMinX[root] || box.minX > this.boxesMaxX[root] ||
      box.maxY < this.boxesMinY[root] || box.minY > this.boxesMaxY[root] ||
      box.maxZ < this.boxesMinZ[root] || box.minZ > this.boxesMaxZ[root]
    ) return null;

    const stack = [root];
    while (stack.length > 0) {
      const curr = stack.pop();
      const count = this.childCount[curr];
      if (count === 0) {
        const id = this.itemIds[curr];
        if (id >= 0 && (!predicate || predicate(id))) return id;
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
    return null;
  }

  queryWithPredicate(box, predicate) {
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
        if (id >= 0 && (!predicate || predicate(id))) results.push(id);
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

  spatialJoin(other) {
    if (this.rootIndex < 0 || other.rootIndex < 0 || this.numItems === 0 || other.numItems === 0) return [];

    const rootA = this.rootIndex;
    const rootB = other.rootIndex;

    const intersect = (u, v) => !(
      this.boxesMaxX[u] < other.boxesMinX[v] || this.boxesMinX[u] > other.boxesMaxX[v] ||
      this.boxesMaxY[u] < other.boxesMinY[v] || this.boxesMinY[u] > other.boxesMaxY[v] ||
      this.boxesMaxZ[u] < other.boxesMinZ[v] || this.boxesMinZ[u] > other.boxesMaxZ[v]
    );

    if (!intersect(rootA, rootB)) return [];

    const results = [];
    const stackA = [rootA];
    const stackB = [rootB];

    while (stackA.length > 0) {
      const currA = stackA.pop();
      const currB = stackB.pop();

      const countA = this.childCount[currA];
      const countB = other.childCount[currB];

      if (countA === 0 && countB === 0) {
        const idA = this.itemIds[currA];
        const idB = other.itemIds[currB];
        if (idA >= 0 && idB >= 0) results.push([idA, idB]);
      } else if (countA === 0) {
        const offsetB = other.childOffset[currB];
        for (let j = 0; j < countB; j++) {
          const chB = other.childIndices[offsetB + j];
          if (intersect(currA, chB)) {
            stackA.push(currA);
            stackB.push(chB);
          }
        }
      } else if (countB === 0) {
        const offsetA = this.childOffset[currA];
        for (let i = 0; i < countA; i++) {
          const chA = this.childIndices[offsetA + i];
          if (intersect(chA, currB)) {
            stackA.push(chA);
            stackB.push(currB);
          }
        }
      } else {
        const offsetA = this.childOffset[currA];
        const offsetB = other.childOffset[currB];
        for (let i = 0; i < countA; i++) {
          const chA = this.childIndices[offsetA + i];
          for (let j = 0; j < countB; j++) {
            const chB = other.childIndices[offsetB + j];
            if (intersect(chA, chB)) {
              stackA.push(chA);
              stackB.push(chB);
            }
          }
        }
      }
    }
    return results;
  }

  toFlatBuffers() {
    return {
      boxesMinX: new Float64Array(this.boxesMinX),
      boxesMinY: new Float64Array(this.boxesMinY),
      boxesMinZ: new Float64Array(this.boxesMinZ),
      boxesMaxX: new Float64Array(this.boxesMaxX),
      boxesMaxY: new Float64Array(this.boxesMaxY),
      boxesMaxZ: new Float64Array(this.boxesMaxZ),
      childOffset: new Int32Array(this.childOffset),
      childCount: new Int32Array(this.childCount),
      childIndices: new Int32Array(this.childIndices),
      itemIds: new Int32Array(this.itemIds),
      nodeLevels: new Int32Array(this.nodeLevels),
      numItems: this.numItems,
      numNodes: this.numNodes,
      height: this.height,
      nodeCapacity: this.nodeCapacity,
      rootIndex: this.rootIndex,
    };
  }

  static fromFlatBuffers(buffers) {
    const tree = new StrTree3D(buffers.nodeCapacity);
    tree.boxesMinX = new Float64Array(buffers.boxesMinX);
    tree.boxesMinY = new Float64Array(buffers.boxesMinY);
    tree.boxesMinZ = new Float64Array(buffers.boxesMinZ);
    tree.boxesMaxX = new Float64Array(buffers.boxesMaxX);
    tree.boxesMaxY = new Float64Array(buffers.boxesMaxY);
    tree.boxesMaxZ = new Float64Array(buffers.boxesMaxZ);
    tree.childOffset = new Int32Array(buffers.childOffset);
    tree.childCount = new Int32Array(buffers.childCount);
    tree.childIndices = new Int32Array(buffers.childIndices);
    tree.itemIds = new Int32Array(buffers.itemIds);
    tree.nodeLevels = new Int32Array(buffers.nodeLevels);
    tree.numItems = buffers.numItems;
    tree.numNodes = buffers.numNodes;
    tree.height = buffers.height;
    tree.nodeCapacity = buffers.nodeCapacity;
    tree.rootIndex = buffers.rootIndex;
    return tree;
  }

  dbscan(eps, minPts = 1) {
    if (this.rootIndex < 0 || this.numItems === 0) {
      return { labels: [], numClusters: 0, numNoise: 0, clusterSizes: [] };
    }
    const minPtsClamped = Math.max(1, minPts);
    const epsSq = eps * eps;

    const leafIds = [];
    const centersX = [];
    const centersY = [];
    const centersZ = [];
    let maxId = 0;

    for (let i = 0; i < this.boxesMinX.length; i++) {
      if (this.childCount[i] === 0 && this.itemIds[i] >= 0) {
        const id = this.itemIds[i];
        leafIds.push(id);
        centersX.push((this.boxesMinX[i] + this.boxesMaxX[i]) * 0.5);
        centersY.push((this.boxesMinY[i] + this.boxesMaxY[i]) * 0.5);
        centersZ.push((this.boxesMinZ[i] + this.boxesMaxZ[i]) * 0.5);
        if (id > maxId) maxId = id;
      }
    }

    const n = leafIds.length;
    if (n === 0) {
      return { labels: [], numClusters: 0, numNoise: 0, clusterSizes: [] };
    }

    const idToIdx = new Map();
    for (let i = 0; i < n; i++) {
      idToIdx.set(leafIds[i], i);
    }

    const labels = new Int32Array(n).fill(-2);
    let currentCluster = 0;

    for (let i = 0; i < n; i++) {
      if (labels[i] !== -2) continue;

      const cx = centersX[i];
      const cy = centersY[i];
      const cz = centersZ[i];
      const candIds = this.querySphere(cx, cy, cz, eps);
      const coreNeighbors = [];

      for (let k = 0; k < candIds.length; k++) {
        const idx = idToIdx.get(candIds[k]);
        if (idx !== undefined) {
          const dx = cx - centersX[idx];
          const dy = cy - centersY[idx];
          const dz = cz - centersZ[idx];
          if (dx * dx + dy * dy + dz * dz <= epsSq) {
            coreNeighbors.push(idx);
          }
        }
      }

      if (coreNeighbors.length < minPtsClamped) {
        labels[i] = -1;
      } else {
        labels[i] = currentCluster;
        const queue = [];
        for (let k = 0; k < coreNeighbors.length; k++) {
          if (coreNeighbors[k] !== i) queue.push(coreNeighbors[k]);
        }

        let head = 0;
        while (head < queue.length) {
          const qIdx = queue[head++];
          if (labels[qIdx] === -1) {
            labels[qIdx] = currentCluster;
          }
          if (labels[qIdx] !== -2) continue;

          labels[qIdx] = currentCluster;
          const qCx = centersX[qIdx];
          const qCy = centersY[qIdx];
          const qCz = centersZ[qIdx];
          const qCandIds = this.querySphere(qCx, qCy, qCz, eps);
          const qCoreNeighbors = [];

          for (let k = 0; k < qCandIds.length; k++) {
            const idx = idToIdx.get(qCandIds[k]);
            if (idx !== undefined) {
              const dx = qCx - centersX[idx];
              const dy = qCy - centersY[idx];
              const dz = qCz - centersZ[idx];
              if (dx * dx + dy * dy + dz * dz <= epsSq) {
                qCoreNeighbors.push(idx);
              }
            }
          }

          if (qCoreNeighbors.length >= minPtsClamped) {
            for (let k = 0; k < qCoreNeighbors.length; k++) {
              const nIdx = qCoreNeighbors[k];
              if (labels[nIdx] === -2 || labels[nIdx] === -1) {
                queue.push(nIdx);
              }
            }
          }
        }
        currentCluster++;
      }
    }

    const numClusters = currentCluster;
    let numNoise = 0;
    const clusterSizes = new Array(numClusters).fill(0);
    const labelsById = new Array(maxId + 1).fill(-1);

    for (let i = 0; i < n; i++) {
      const lbl = labels[i];
      const id = leafIds[i];
      labelsById[id] = lbl;
      if (lbl < 0) {
        numNoise++;
      } else {
        clusterSizes[lbl]++;
      }
    }

    return {
      labels: labelsById,
      numClusters,
      numNoise,
      clusterSizes,
    };
  }
}

export class Triangle3D {
  constructor(p0x, p0y, p0z, p1x, p1y, p1z, p2x, p2y, p2z) {
    this.p0x = p0x;
    this.p0y = p0y;
    this.p0z = p0z;
    this.p1x = p1x;
    this.p1y = p1y;
    this.p1z = p1z;
    this.p2x = p2x;
    this.p2y = p2y;
    this.p2z = p2z;
  }

  toBox() {
    const minX = Math.min(this.p0x, this.p1x, this.p2x);
    const minY = Math.min(this.p0y, this.p1y, this.p2y);
    const minZ = Math.min(this.p0z, this.p1z, this.p2z);
    const maxX = Math.max(this.p0x, this.p1x, this.p2x);
    const maxY = Math.max(this.p0y, this.p1y, this.p2y);
    const maxZ = Math.max(this.p0z, this.p1z, this.p2z);
    return new Box3D(minX, minY, minZ, maxX, maxY, maxZ);
  }

  centroid() {
    return [
      (this.p0x + this.p1x + this.p2x) / 3.0,
      (this.p0y + this.p1y + this.p2y) / 3.0,
      (this.p0z + this.p1z + this.p2z) / 3.0,
    ];
  }

  normal() {
    const e1x = this.p1x - this.p0x;
    const e1y = this.p1y - this.p0y;
    const e1z = this.p1z - this.p0z;
    const e2x = this.p2x - this.p0x;
    const e2y = this.p2y - this.p0y;
    const e2z = this.p2z - this.p0z;
    const nx = e1y * e2z - e1z * e2y;
    const ny = e1z * e2x - e1x * e2z;
    const nz = e1x * e2y - e1y * e2x;
    const lenSq = nx * nx + ny * ny + nz * nz;
    if (lenSq < 1e-18) return [0.0, 0.0, 1.0];
    const len = Math.sqrt(lenSq);
    return [nx / len, ny / len, nz / len];
  }

  area() {
    const e1x = this.p1x - this.p0x;
    const e1y = this.p1y - this.p0y;
    const e1z = this.p1z - this.p0z;
    const e2x = this.p2x - this.p0x;
    const e2y = this.p2y - this.p0y;
    const e2z = this.p2z - this.p0z;
    const nx = e1y * e2z - e1z * e2y;
    const ny = e1z * e2x - e1x * e2z;
    const nz = e1x * e2y - e1y * e2x;
    return 0.5 * Math.sqrt(nx * nx + ny * ny + nz * nz);
  }

  rayIntersection(ox, oy, oz, dx, dy, dz) {
    const e1x = this.p1x - this.p0x;
    const e1y = this.p1y - this.p0y;
    const e1z = this.p1z - this.p0z;
    const e2x = this.p2x - this.p0x;
    const e2y = this.p2y - this.p0y;
    const e2z = this.p2z - this.p0z;

    const px = dy * e2z - dz * e2y;
    const py = dz * e2x - dx * e2z;
    const pz = dx * e2y - dy * e2x;

    const det = e1x * px + e1y * py + e1z * pz;
    if (det > -1e-12 && det < 1e-12) return null;
    const invDet = 1.0 / det;

    const tx = ox - this.p0x;
    const ty = oy - this.p0y;
    const tz = oz - this.p0z;

    const u = (tx * px + ty * py + tz * pz) * invDet;
    if (u < 0.0 || u > 1.0) return null;

    const qx = ty * e1z - tz * e1y;
    const qy = tz * e1x - tx * e1z;
    const qz = tx * e1y - ty * e1x;

    const v = (dx * qx + dy * qy + dz * qz) * invDet;
    if (v < 0.0 || u + v > 1.0) return null;

    const t = (e2x * qx + e2y * qy + e2z * qz) * invDet;
    return t >= 0.0 ? t : null;
  }

  intersectsSegment(x1, y1, z1, x2, y2, z2) {
    const dx = x2 - x1;
    const dy = y2 - y1;
    const dz = z2 - z1;
    const t = this.rayIntersection(x1, y1, z1, dx, dy, dz);
    return t !== null && t >= 0.0 && t <= 1.0;
  }
}

export class StrMeshTree3D {
  constructor(triangles, nodeCapacity = 16) {
    this.triangles = triangles ? [...triangles] : [];
    const items = this.triangles.map((tri, i) => ({ box: tri.toBox(), id: i }));
    this.tree = StrTree3D.build(items, nodeCapacity);
  }

  static build(triangles, nodeCapacity = 16) {
    return new StrMeshTree3D(triangles, nodeCapacity);
  }

  numTriangles() {
    return this.triangles.length;
  }

  getTriangle(id) {
    return this.triangles[id];
  }

  queryBox(box) {
    return this.tree.query(box);
  }

  querySegment(x1, y1, z1, x2, y2, z2) {
    const candidates = this.tree.querySegment(x1, y1, z1, x2, y2, z2);
    const results = [];
    for (const id of candidates) {
      if (this.triangles[id].intersectsSegment(x1, y1, z1, x2, y2, z2)) {
        results.push(id);
      }
    }
    return results;
  }

  queryFirstRayHit(ox, oy, oz, dx, dy, dz, maxDistance = 1000000.0) {
    const targetX = ox + dx * maxDistance;
    const targetY = oy + dy * maxDistance;
    const targetZ = oz + dz * maxDistance;
    const candidates = this.tree.querySegment(ox, oy, oz, targetX, targetY, targetZ);

    let closestId = null;
    let minT = maxDistance;

    for (const id of candidates) {
      const tri = this.triangles[id];
      const t = tri.rayIntersection(ox, oy, oz, dx, dy, dz);
      if (t !== null && t <= minT) {
        minT = t;
        closestId = id;
      }
    }

    return closestId !== null ? { id: closestId, t: minT } : null;
  }

  queryAllRayHits(ox, oy, oz, dx, dy, dz, maxDistance = 1000000.0) {
    const targetX = ox + dx * maxDistance;
    const targetY = oy + dy * maxDistance;
    const targetZ = oz + dz * maxDistance;
    const candidates = this.tree.querySegment(ox, oy, oz, targetX, targetY, targetZ);

    const hits = [];
    for (const id of candidates) {
      const tri = this.triangles[id];
      const t = tri.rayIntersection(ox, oy, oz, dx, dy, dz);
      if (t !== null && t <= maxDistance) {
        hits.push({ id, t });
      }
    }
    hits.sort((a, b) => a.t - b.t);
    return hits;
  }
}

export class Box4D {
  constructor(minX, minY, minZ, minT, maxX, maxY, maxZ, maxT) {
    this.minX = Math.min(minX, maxX);
    this.minY = Math.min(minY, maxY);
    this.minZ = Math.min(minZ, maxZ);
    this.minT = Math.min(minT, maxT);
    this.maxX = Math.max(minX, maxX);
    this.maxY = Math.max(minY, maxY);
    this.maxZ = Math.max(minZ, maxZ);
    this.maxT = Math.max(minT, maxT);
  }

  static fromPoint(x, y, z, t) {
    return new Box4D(x, y, z, t, x, y, z, t);
  }

  intersects(other) {
    return !(
      this.maxX < other.minX ||
      this.minX > other.maxX ||
      this.maxY < other.minY ||
      this.minY > other.maxY ||
      this.maxZ < other.minZ ||
      this.minZ > other.maxZ ||
      this.maxT < other.minT ||
      this.minT > other.maxT
    );
  }

  containsPoint(x, y, z, t) {
    return (
      this.minX <= x &&
      x <= this.maxX &&
      this.minY <= y &&
      y <= this.maxY &&
      this.minZ <= z &&
      z <= this.maxZ &&
      this.minT <= t &&
      t <= this.maxT
    );
  }

  containsBox(other) {
    return (
      this.minX <= other.minX &&
      other.maxX <= this.maxX &&
      this.minY <= other.minY &&
      other.maxY <= this.maxY &&
      this.minZ <= other.minZ &&
      other.maxZ <= this.maxZ &&
      this.minT <= other.minT &&
      other.maxT <= this.maxT
    );
  }

  union(other) {
    return new Box4D(
      Math.min(this.minX, other.minX),
      Math.min(this.minY, other.minY),
      Math.min(this.minZ, other.minZ),
      Math.min(this.minT, other.minT),
      Math.max(this.maxX, other.maxX),
      Math.max(this.maxY, other.maxY),
      Math.max(this.maxZ, other.maxZ),
      Math.max(this.maxT, other.maxT)
    );
  }

  intersection(other) {
    if (!this.intersects(other)) return null;
    return new Box4D(
      Math.max(this.minX, other.minX),
      Math.max(this.minY, other.minY),
      Math.max(this.minZ, other.minZ),
      Math.max(this.minT, other.minT),
      Math.min(this.maxX, other.maxX),
      Math.min(this.maxY, other.maxY),
      Math.min(this.maxZ, other.maxZ),
      Math.min(this.maxT, other.maxT)
    );
  }

  hyperVolume() {
    return (
      (this.maxX - this.minX) *
      (this.maxY - this.minY) *
      (this.maxZ - this.minZ) *
      (this.maxT - this.minT)
    );
  }

  toBox3D() {
    return new Box3D(this.minX, this.minY, this.minZ, this.maxX, this.maxY, this.maxZ);
  }

  expand(dx, dy, dz, dt) {
    return new Box4D(
      this.minX - dx,
      this.minY - dy,
      this.minZ - dz,
      this.minT - dt,
      this.maxX + dx,
      this.maxY + dy,
      this.maxZ + dz,
      this.maxT + dt
    );
  }

  intersectsAtTime(other, t) {
    if (t < this.minT || t > this.maxT || t < other.minT || t > other.maxT) return false;
    return this.toBox3D().intersects(other.toBox3D());
  }
}

export class StrTree4D {
  constructor(nodeCapacity = 16) {
    this.nodeCapacity = Math.max(2, nodeCapacity);
    this.boxesMinX = [];
    this.boxesMinY = [];
    this.boxesMinZ = [];
    this.boxesMinT = [];
    this.boxesMaxX = [];
    this.boxesMaxY = [];
    this.boxesMaxZ = [];
    this.boxesMaxT = [];
    this.childOffset = [];
    this.childCount = [];
    this.childIndices = [];
    this.itemIds = [];
    this.nodeLevels = [];
    this.numItems = 0;
    this.numNodes = 0;
    this.height = 0;
    this.rootIndex = -1;
  }

  static build(items, nodeCapacity = 16) {
    const tree = new StrTree4D(nodeCapacity);
    if (!items || items.length === 0) return tree;

    const cap = tree.nodeCapacity;
    let allNodes = items.map((it, i) => ({
      minX: it.box.minX,
      minY: it.box.minY,
      minZ: it.box.minZ,
      minT: it.box.minT,
      maxX: it.box.maxX,
      maxY: it.box.maxY,
      maxZ: it.box.maxZ,
      maxT: it.box.maxT,
      itemId: it.id !== undefined ? it.id : i,
      children: [],
    }));

    let currentLevelIndices = allNodes.map((_, i) => i);
    let height = 1;

    while (currentLevelIndices.length > 1) {
      const n = currentLevelIndices.length;
      const parentLevelIndices = [];
      const pPages = Math.ceil(n / cap);
      const sx = Math.max(1, Math.ceil(Math.pow(pPages, 0.25)));

      const levelNodes = currentLevelIndices.map(idx => allNodes[idx]);
      levelNodes.sort((a, b) => ((a.minX + a.maxX) * 0.5) - ((b.minX + b.maxX) * 0.5));

      const sliceXSize = Math.ceil(n / sx);
      for (let xStart = 0; xStart < n; xStart += sliceXSize) {
        const xSlice = levelNodes.slice(xStart, xStart + sliceXSize);
        const nx = xSlice.length;
        const px = Math.ceil(nx / cap);
        const sy = Math.max(1, Math.ceil(Math.cbrt(px)));

        xSlice.sort((a, b) => ((a.minY + a.maxY) * 0.5) - ((b.minY + b.maxY) * 0.5));
        const sliceYSize = Math.ceil(nx / sy);
        for (let yStart = 0; yStart < nx; yStart += sliceYSize) {
          const ySlice = xSlice.slice(yStart, yStart + sliceYSize);
          const nxy = ySlice.length;
          const pxy = Math.ceil(nxy / cap);
          const sz = Math.max(1, Math.ceil(Math.sqrt(pxy)));

          ySlice.sort((a, b) => ((a.minZ + a.maxZ) * 0.5) - ((b.minZ + b.maxZ) * 0.5));
          const sliceZSize = Math.ceil(nxy / sz);
          for (let zStart = 0; zStart < nxy; zStart += sliceZSize) {
            const zSlice = ySlice.slice(zStart, zStart + sliceZSize);
            zSlice.sort((a, b) => ((a.minT + a.maxT) * 0.5) - ((b.minT + b.maxT) * 0.5));

            for (let tStart = 0; tStart < zSlice.length; tStart += cap) {
              const chunk = zSlice.slice(tStart, tStart + cap);
              let minX = chunk[0].minX, minY = chunk[0].minY, minZ = chunk[0].minZ, minT = chunk[0].minT;
              let maxX = chunk[0].maxX, maxY = chunk[0].maxY, maxZ = chunk[0].maxZ, maxT = chunk[0].maxT;
              const chIndices = [];

              for (const ch of chunk) {
                minX = Math.min(minX, ch.minX);
                minY = Math.min(minY, ch.minY);
                minZ = Math.min(minZ, ch.minZ);
                minT = Math.min(minT, ch.minT);
                maxX = Math.max(maxX, ch.maxX);
                maxY = Math.max(maxY, ch.maxY);
                maxZ = Math.max(maxZ, ch.maxZ);
                maxT = Math.max(maxT, ch.maxT);
                chIndices.push(allNodes.indexOf(ch));
              }

              const parentIdx = allNodes.length;
              allNodes.push({
                minX, minY, minZ, minT, maxX, maxY, maxZ, maxT,
                itemId: -1,
                children: chIndices,
              });
              parentLevelIndices.push(parentIdx);
            }
          }
        }
      }

      currentLevelIndices = parentLevelIndices;
      height++;
    }

    const totalNodes = allNodes.length;
    tree.numItems = items.length;
    tree.numNodes = totalNodes;
    tree.height = height;
    tree.rootIndex = currentLevelIndices[0];

    tree.boxesMinX = new Float64Array(totalNodes);
    tree.boxesMinY = new Float64Array(totalNodes);
    tree.boxesMinZ = new Float64Array(totalNodes);
    tree.boxesMinT = new Float64Array(totalNodes);
    tree.boxesMaxX = new Float64Array(totalNodes);
    tree.boxesMaxY = new Float64Array(totalNodes);
    tree.boxesMaxZ = new Float64Array(totalNodes);
    tree.boxesMaxT = new Float64Array(totalNodes);
    tree.childOffset = new Int32Array(totalNodes);
    tree.childCount = new Int32Array(totalNodes);
    tree.itemIds = new Int32Array(totalNodes);
    tree.nodeLevels = new Int32Array(totalNodes);

    const chList = [];
    for (let i = 0; i < totalNodes; i++) {
      const n = allNodes[i];
      tree.boxesMinX[i] = n.minX;
      tree.boxesMinY[i] = n.minY;
      tree.boxesMinZ[i] = n.minZ;
      tree.boxesMinT[i] = n.minT;
      tree.boxesMaxX[i] = n.maxX;
      tree.boxesMaxY[i] = n.maxY;
      tree.boxesMaxZ[i] = n.maxZ;
      tree.boxesMaxT[i] = n.maxT;
      tree.itemIds[i] = n.itemId;
      tree.childOffset[i] = chList.length;
      tree.childCount[i] = n.children.length;
      for (const c of n.children) chList.push(c);
    }
    tree.childIndices = new Int32Array(chList);
    return tree;
  }

  query(box) {
    if (this.rootIndex < 0 || this.numItems === 0) return [];
    const root = this.rootIndex;
    if (
      box.maxX < this.boxesMinX[root] ||
      box.minX > this.boxesMaxX[root] ||
      box.maxY < this.boxesMinY[root] ||
      box.minY > this.boxesMaxY[root] ||
      box.maxZ < this.boxesMinZ[root] ||
      box.minZ > this.boxesMaxZ[root] ||
      box.maxT < this.boxesMinT[root] ||
      box.minT > this.boxesMaxT[root]
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
          const ch = this.childIndices[offset + i];
          if (
            !(
              box.maxX < this.boxesMinX[ch] ||
              box.minX > this.boxesMaxX[ch] ||
              box.maxY < this.boxesMinY[ch] ||
              box.minY > this.boxesMaxY[ch] ||
              box.maxZ < this.boxesMinZ[ch] ||
              box.minZ > this.boxesMaxZ[ch] ||
              box.maxT < this.boxesMinT[ch] ||
              box.minT > this.boxesMaxT[ch]
            )
          ) {
            stack.push(ch);
          }
        }
      }
    }
    return results;
  }

  queryPoint(x, y, z, t) {
    return this.query(Box4D.fromPoint(x, y, z, t));
  }

  queryCount(box) {
    return this.query(box).length;
  }

  queryTimeSlice(t, box3D) {
    return this.query(new Box4D(box3D.minX, box3D.minY, box3D.minZ, t, box3D.maxX, box3D.maxY, box3D.maxZ, t));
  }
}

export class GeofenceEvent {
  static Enter(itemId, fenceId) {
    return { type: 'Enter', itemId, fenceId, toString: () => `Enter(${itemId}, ${fenceId})` };
  }
  static Exit(itemId, fenceId) {
    return { type: 'Exit', itemId, fenceId, toString: () => `Exit(${itemId}, ${fenceId})` };
  }
  static Stay(itemId, fenceId) {
    return { type: 'Stay', itemId, fenceId, toString: () => `Stay(${itemId}, ${fenceId})` };
  }
}

export class GeofenceMonitor {
  constructor(fences, nodeCapacity = 16) {
    this.fenceTree = StrTree.build(fences, nodeCapacity);
    this.tracked = new Map();
  }

  updateRect(itemId, rect) {
    const current = new Set(this.fenceTree.query(rect));
    return this._computeTransitions(itemId, current);
  }

  updatePoint(itemId, x, y) {
    const current = new Set(this.fenceTree.queryPoint(x, y));
    return this._computeTransitions(itemId, current);
  }

  _computeTransitions(itemId, current) {
    const prev = this.tracked.get(itemId) || new Set();
    const events = [];

    for (const fid of current) {
      if (prev.has(fid)) {
        events.push(GeofenceEvent.Stay(itemId, fid));
      } else {
        events.push(GeofenceEvent.Enter(itemId, fid));
      }
    }

    for (const fid of prev) {
      if (!current.has(fid)) {
        events.push(GeofenceEvent.Exit(itemId, fid));
      }
    }

    this.tracked.set(itemId, current);
    return events;
  }

  removeItem(itemId) {
    const prev = this.tracked.get(itemId);
    if (!prev) return [];
    const events = [];
    for (const fid of prev) {
      events.push(GeofenceEvent.Exit(itemId, fid));
    }
    this.tracked.delete(itemId);
    return events;
  }

  activeFences(itemId) {
    const s = this.tracked.get(itemId);
    return s ? Array.from(s) : [];
  }

  isInFence(itemId, fenceId) {
    const s = this.tracked.get(itemId);
    return s ? s.has(fenceId) : false;
  }

  trackedCount() {
    return this.tracked.size;
  }

  clear() {
    this.tracked.clear();
  }
}

export class TrajectoryPoint {
  constructor(x, y, t, trackId) {
    this.x = x;
    this.y = y;
    this.t = t;
    this.trackId = trackId;
  }
}

export class TrajectorySegment {
  constructor(p0X, p0Y, p0T, p1X, p1Y, p1T, trackId, segmentId) {
    this.p0X = p0X;
    this.p0Y = p0Y;
    this.p0T = p0T;
    this.p1X = p1X;
    this.p1Y = p1Y;
    this.p1T = p1T;
    this.trackId = trackId;
    this.segmentId = segmentId;
  }

  boundingRect() {
    return new Rect(
      Math.min(this.p0X, this.p1X),
      Math.min(this.p0Y, this.p1Y),
      Math.max(this.p0X, this.p1X),
      Math.max(this.p0Y, this.p1Y)
    );
  }

  minT() {
    return Math.min(this.p0T, this.p1T);
  }

  maxT() {
    return Math.max(this.p0T, this.p1T);
  }

  duration() {
    return Math.abs(this.p1T - this.p0T);
  }

  length() {
    const dx = this.p1X - this.p0X;
    const dy = this.p1Y - this.p0Y;
    return Math.hypot(dx, dy);
  }

  speed() {
    const dur = this.duration();
    return dur <= 1e-9 ? 0.0 : this.length() / dur;
  }

  interpolatePosition(t) {
    const tStart = this.minT();
    const tEnd = this.maxT();
    if (t < tStart || t > tEnd) return null;
    const span = this.p1T - this.p0T;
    if (Math.abs(span) <= 1e-9) return [this.p0X, this.p0Y];
    const alpha = (t - this.p0T) / span;
    return [
      this.p0X + alpha * (this.p1X - this.p0X),
      this.p0Y + alpha * (this.p1Y - this.p0Y)
    ];
  }
}

export class TrajectoryWindowIndex {
  constructor(tree, segments) {
    this.tree = tree;
    this.segments = segments;
  }

  static build(segments, nodeCapacity = 16) {
    const items = segments.map((s, idx) => ({
      rect: s.boundingRect(),
      id: idx
    }));
    const tree = StrTree.build(items, nodeCapacity);
    return new TrajectoryWindowIndex(tree, segments);
  }

  static segmentsFromPoints(points) {
    const segments = [];
    let segCounter = 0;
    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i];
      const p1 = points[i + 1];
      if (p0.trackId === p1.trackId) {
        segments.push(new TrajectorySegment(
          p0.x, p0.y, p0.t,
          p1.x, p1.y, p1.t,
          p0.trackId,
          segCounter++
        ));
      }
    }
    return segments;
  }

  queryWindow(spatialWindow, tMin, tMax) {
    const candidates = this.tree.query(spatialWindow);
    const matched = [];
    for (const idx of candidates) {
      if (idx >= 0 && idx < this.segments.length) {
        const seg = this.segments[idx];
        const segStart = seg.minT();
        const segEnd = seg.maxT();
        const overlapStart = Math.max(segStart, tMin);
        const overlapEnd = Math.min(segEnd, tMax);
        if (overlapStart <= overlapEnd) {
          matched.push(seg.segmentId);
        }
      }
    }
    return matched;
  }

  queryTracksInWindow(spatialWindow, tMin, tMax) {
    const candidates = this.tree.query(spatialWindow);
    const matchedTracks = new Set();
    for (const idx of candidates) {
      if (idx >= 0 && idx < this.segments.length) {
        const seg = this.segments[idx];
        const segStart = seg.minT();
        const segEnd = seg.maxT();
        const overlapStart = Math.max(segStart, tMin);
        const overlapEnd = Math.min(segEnd, tMax);
        if (overlapStart <= overlapEnd) {
          matchedTracks.add(seg.trackId);
        }
      }
    }
    return Array.from(matchedTracks);
  }

  numSegments() {
    return this.segments.length;
  }
}

export function perpendicularDistance(px, py, x1, y1, x2, y2) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  const lenSq = dx * dx + dy * dy;
  if (lenSq <= 1e-12) {
    return Math.hypot(px - x1, py - y1);
  }
  const num = Math.abs(dy * px - dx * py + x2 * y1 - y2 * x1);
  return num / Math.sqrt(lenSq);
}

export function synchronizedEuclideanDistance(p, start, end) {
  const dt = end.t - start.t;
  if (Math.abs(dt) <= 1e-9) {
    return perpendicularDistance(p.x, p.y, start.x, start.y, end.x, end.y);
  }
  const alpha = (p.t - start.t) / dt;
  const syncX = start.x + alpha * (end.x - start.x);
  const syncY = start.y + alpha * (end.y - start.y);
  return Math.hypot(p.x - syncX, p.y - syncY);
}

export function simplifyTrajectory2D(points, epsilon) {
  const n = points.length;
  if (n <= 2) {
    return {
      points: [...points],
      originalCount: n,
      simplifiedCount: n,
      compressionRatio: 0.0,
      maxError: 0.0,
    };
  }

  const keep = new Array(n).fill(false);
  keep[0] = true;
  keep[n - 1] = true;

  function recurse(first, last) {
    if (last <= first + 1) return 0.0;
    let dMax = 0.0;
    let index = first;
    const pFirst = points[first];
    const pLast = points[last];
    for (let i = first + 1; i < last; i++) {
      const d = perpendicularDistance(points[i].x, points[i].y, pFirst.x, pFirst.y, pLast.x, pLast.y);
      if (d > dMax) {
        dMax = d;
        index = i;
      }
    }
    if (dMax > epsilon) {
      keep[index] = true;
      const leftErr = recurse(first, index);
      const rightErr = recurse(index, last);
      return Math.max(dMax, leftErr, rightErr);
    }
    return dMax;
  }

  const maxErr = recurse(0, n - 1);
  const decimated = points.filter((_, i) => keep[i]);
  const simplifiedCount = decimated.length;
  const ratio = (1.0 - simplifiedCount / n) * 100.0;

  return {
    points: decimated,
    originalCount: n,
    simplifiedCount,
    compressionRatio: ratio,
    maxError: maxErr,
  };
}

export function simplifyTrajectorySpatiotemporal(points, epsilon) {
  const n = points.length;
  if (n <= 2) {
    return {
      points: [...points],
      originalCount: n,
      simplifiedCount: n,
      compressionRatio: 0.0,
      maxError: 0.0,
    };
  }

  const keep = new Array(n).fill(false);
  keep[0] = true;
  keep[n - 1] = true;

  function recurse(first, last) {
    if (last <= first + 1) return 0.0;
    let dMax = 0.0;
    let index = first;
    const pFirst = points[first];
    const pLast = points[last];
    for (let i = first + 1; i < last; i++) {
      const d = synchronizedEuclideanDistance(points[i], pFirst, pLast);
      if (d > dMax) {
        dMax = d;
        index = i;
      }
    }
    if (dMax > epsilon) {
      keep[index] = true;
      const leftErr = recurse(first, index);
      const rightErr = recurse(index, last);
      return Math.max(dMax, leftErr, rightErr);
    }
    return dMax;
  }

  const maxErr = recurse(0, n - 1);
  const decimated = points.filter((_, i) => keep[i]);
  const simplifiedCount = decimated.length;
  const ratio = (1.0 - simplifiedCount / n) * 100.0;

  return {
    points: decimated,
    originalCount: n,
    simplifiedCount,
    compressionRatio: ratio,
    maxError: maxErr,
  };
}

export class StreamingTrajectoryCompressor {
  constructor(epsilon, useSed = false) {
    this.epsilon = epsilon;
    this.useSed = useSed;
    this.buffer = [];
    this.emitted = [];
    this.totalReceivedCount = 0;
  }

  push(pt) {
    this.totalReceivedCount++;
    if (this.buffer.length === 0) {
      this.buffer.push(pt);
      this.emitted.push(pt);
      return [pt];
    }
    if (this.buffer.length === 1) {
      this.buffer.push(pt);
      return [];
    }

    const anchor = this.buffer[0];
    let violated = false;
    for (let i = 1; i < this.buffer.length; i++) {
      const mid = this.buffer[i];
      const dist = this.useSed
        ? synchronizedEuclideanDistance(mid, anchor, pt)
        : perpendicularDistance(mid.x, mid.y, anchor.x, anchor.y, pt.x, pt.y);
      if (dist > this.epsilon) {
        violated = true;
        break;
      }
    }

    if (violated) {
      const prev = this.buffer[this.buffer.length - 1];
      this.emitted.push(prev);
      this.buffer = [prev, pt];
      return [prev];
    } else {
      this.buffer.push(pt);
      return [];
    }
  }

  finish() {
    if (this.buffer.length > 1) {
      const last = this.buffer[this.buffer.length - 1];
      const alreadyEmitted = this.emitted.length > 0 &&
        this.emitted[this.emitted.length - 1].x === last.x &&
        this.emitted[this.emitted.length - 1].y === last.y &&
        this.emitted[this.emitted.length - 1].t === last.t;
      if (!alreadyEmitted) {
        this.emitted.push(last);
      }
    }
    return [...this.emitted];
  }

  totalReceived() {
    return this.totalReceivedCount;
  }

  totalEmitted() {
    return this.emitted.length;
  }

  compressionRatio() {
    if (this.totalReceivedCount <= 0) return 0.0;
    return (1.0 - this.emitted.length / this.totalReceivedCount) * 100.0;
  }
}

export function trajectoryDtwDistance(a, b, window = -1) {
  const n = a.length;
  const m = b.length;
  if (n === 0 && m === 0) return 0.0;
  if (n === 0 || m === 0) return 1e30;

  const inf = 1e30;
  let prev = new Array(m).fill(inf);
  let curr = new Array(m).fill(inf);

  const wClamped = window < 0 ? m : window;

  for (let j = 0; j < m; j++) {
    if (Math.abs(0 - j) <= wClamped) {
      const d = Math.hypot(a[0].x - b[j].x, a[0].y - b[j].y);
      if (j === 0) {
        prev[0] = d;
      } else {
        prev[j] = prev[j - 1] + d;
      }
    }
  }

  for (let i = 1; i < n; i++) {
    for (let j = 0; j < m; j++) curr[j] = inf;

    for (let j = 0; j < m; j++) {
      if (Math.abs(i - j) <= wClamped) {
        const cost = Math.hypot(a[i].x - b[j].x, a[i].y - b[j].y);
        let minPrev = prev[j];

        if (j > 0) {
          if (curr[j - 1] < minPrev) minPrev = curr[j - 1];
          if (prev[j - 1] < minPrev) minPrev = prev[j - 1];
        }

        if (minPrev < inf) {
          curr[j] = cost + minPrev;
        }
      }
    }

    const tmp = prev;
    prev = curr;
    curr = tmp;
  }

  return prev[m - 1];
}

export function trajectoryDtwNormalized(a, b, window = -1) {
  const d = trajectoryDtwDistance(a, b, window);
  const totalLen = a.length + b.length;
  return totalLen <= 0 ? 0.0 : d / totalLen;
}

export function trajectoryFrechetDistance(a, b) {
  const n = a.length;
  const m = b.length;
  if (n === 0 && m === 0) return 0.0;
  if (n === 0 || m === 0) return 1e30;

  let prev = new Array(m).fill(0.0);
  let curr = new Array(m).fill(0.0);

  prev[0] = Math.hypot(a[0].x - b[0].x, a[0].y - b[0].y);

  for (let j = 1; j < m; j++) {
    const d = Math.hypot(a[0].x - b[j].x, a[0].y - b[j].y);
    prev[j] = Math.max(d, prev[j - 1]);
  }

  for (let i = 1; i < n; i++) {
    const d0 = Math.hypot(a[i].x - b[0].x, a[i].y - b[0].y);
    curr[0] = Math.max(d0, prev[0]);

    for (let j = 1; j < m; j++) {
      const d = Math.hypot(a[i].x - b[j].x, a[i].y - b[j].y);
      let minPrev = prev[j];
      if (curr[j - 1] < minPrev) minPrev = curr[j - 1];
      if (prev[j - 1] < minPrev) minPrev = prev[j - 1];
      curr[j] = Math.max(d, minPrev);
    }

    const tmp = prev;
    prev = curr;
    curr = tmp;
  }

  return prev[m - 1];
}

export class Point2D {
  constructor(x = 0, y = 0) {
    this.x = x;
    this.y = y;
  }
  distanceTo(other) {
    return Math.hypot(this.x - other.x, this.y - other.y);
  }
}

export class Polygon2D {
  constructor(vertices = []) {
    this.vertices = vertices;
  }

  getOpenRing() {
    const vs = this.vertices;
    const n = vs.length;
    if (n > 1 && vs[0].x === vs[n - 1].x && vs[0].y === vs[n - 1].y) {
      return vs.slice(0, n - 1);
    }
    return vs;
  }

  area() {
    const ring = this.getOpenRing();
    const n = ring.length;
    if (n < 3) return 0.0;
    let sum = 0.0;
    for (let i = 0; i < n; i++) {
      const next = (i + 1) % n;
      sum += ring[i].x * ring[next].y - ring[next].x * ring[i].y;
    }
    return Math.abs(sum * 0.5);
  }

  perimeter() {
    const ring = this.getOpenRing();
    const n = ring.length;
    if (n < 2) return 0.0;
    let sum = 0.0;
    for (let i = 0; i < n; i++) {
      const next = (i + 1) % n;
      sum += Math.hypot(ring[i].x - ring[next].x, ring[i].y - ring[next].y);
    }
    return sum;
  }

  envelope() {
    const vs = this.vertices;
    if (vs.length === 0) return new Rect(0, 0, 0, 0);
    let minX = vs[0].x;
    let maxX = vs[0].x;
    let minY = vs[0].y;
    let maxY = vs[0].y;
    for (let i = 1; i < vs.length; i++) {
      const p = vs[i];
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return new Rect(minX, minY, maxX, maxY);
  }

  containsPoint(px, py) {
    const ring = this.getOpenRing();
    const n = ring.length;
    if (n < 3) return false;
    let inside = false;
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      const xi = ring[i].x;
      const yi = ring[i].y;
      const xj = ring[j].x;
      const yj = ring[j].y;
      const intersect =
        yi > py !== yj > py && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi;
      if (intersect) inside = !inside;
    }
    return inside;
  }

  centroid() {
    const ring = this.getOpenRing();
    const n = ring.length;
    if (n === 0) return new Point2D(0, 0);
    if (n === 1) return new Point2D(ring[0].x, ring[0].y);
    if (n === 2)
      return new Point2D(
        (ring[0].x + ring[1].x) * 0.5,
        (ring[0].y + ring[1].y) * 0.5
      );
    let signedArea = 0.0;
    let cx = 0.0;
    let cy = 0.0;
    for (let i = 0; i < n; i++) {
      const next = (i + 1) % n;
      const factor = ring[i].x * ring[next].y - ring[next].x * ring[i].y;
      signedArea += factor;
      cx += (ring[i].x + ring[next].x) * factor;
      cy += (ring[i].y + ring[next].y) * factor;
    }
    signedArea *= 0.5;
    if (Math.abs(signedArea) < 1e-12) {
      let sumX = 0;
      let sumY = 0;
      for (let i = 0; i < n; i++) {
        sumX += ring[i].x;
        sumY += ring[i].y;
      }
      return new Point2D(sumX / n, sumY / n);
    }
    const sixA = 6.0 * signedArea;
    return new Point2D(cx / sixA, cy / sixA);
  }

  clipRect(clipBox) {
    let current = this.getOpenRing();
    if (current.length < 3) return new Polygon2D([]);

    const clipStage = (input, isInside, computeIntersect) => {
      const out = [];
      const len = input.length;
      for (let i = 0; i < len; i++) {
        const p1 = input[i];
        const p2 = input[(i + 1) % len];
        const in1 = isInside(p1);
        const in2 = isInside(p2);
        if (in1 && in2) out.push(p2);
        else if (in1 && !in2) out.push(computeIntersect(p1, p2));
        else if (!in1 && in2) {
          out.push(computeIntersect(p1, p2));
          out.push(p2);
        }
      }
      return out;
    };

    // Left
    current = clipStage(
      current,
      p => p.x >= clipBox.minX,
      (p1, p2) => {
        const t = (clipBox.minX - p1.x) / (p2.x - p1.x);
        return new Point2D(clipBox.minX, p1.y + t * (p2.y - p1.y));
      }
    );
    if (current.length < 3) return new Polygon2D([]);

    // Right
    current = clipStage(
      current,
      p => p.x <= clipBox.maxX,
      (p1, p2) => {
        const t = (clipBox.maxX - p1.x) / (p2.x - p1.x);
        return new Point2D(clipBox.maxX, p1.y + t * (p2.y - p1.y));
      }
    );
    if (current.length < 3) return new Polygon2D([]);

    // Bottom
    current = clipStage(
      current,
      p => p.y >= clipBox.minY,
      (p1, p2) => {
        const t = (clipBox.minY - p1.y) / (p2.y - p1.y);
        return new Point2D(p1.x + t * (p2.x - p1.x), clipBox.minY);
      }
    );
    if (current.length < 3) return new Polygon2D([]);

    // Top
    current = clipStage(
      current,
      p => p.y <= clipBox.maxY,
      (p1, p2) => {
        const t = (clipBox.maxY - p1.y) / (p2.y - p1.y);
        return new Point2D(p1.x + t * (p2.x - p1.x), clipBox.maxY);
      }
    );

    return new Polygon2D(current);
  }
}

export class StrPolygonIndex {
  constructor(tree, polygons) {
    this.tree = tree;
    this.polygons = polygons;
  }

  static build(polygons, nodeCapacity = 16) {
    const items = polygons.map((poly, idx) => ({
      rect: poly.envelope(),
      id: idx,
    }));
    const tree = StrTree.build(items, nodeCapacity);
    return new StrPolygonIndex(tree, polygons);
  }

  totalPolygons() {
    return this.polygons.length;
  }

  envelope() {
    if (this.tree.rootIndex < 0 || this.tree.numItems === 0) {
      return new Rect(0, 0, 0, 0);
    }
    const r = this.tree.rootIndex;
    return new Rect(
      this.tree.boxesMinX[r],
      this.tree.boxesMinY[r],
      this.tree.boxesMaxX[r],
      this.tree.boxesMaxY[r]
    );
  }

  queryWindow(win) {
    return this.tree.query(win);
  }

  queryCount(win) {
    return this.tree.queryCount(win);
  }

  queryPolygons(win) {
    const ids = this.tree.query(win);
    return ids.map(id => this.polygons[id]);
  }

  queryClippedPolygons(win) {
    const ids = this.tree.query(win);
    const result = [];
    for (let i = 0; i < ids.length; i++) {
      const id = ids[i];
      if (id >= 0 && id < this.polygons.length) {
        const clipped = this.polygons[id].clipRect(win);
        if (clipped.vertices.length >= 3 && clipped.area() > 1e-12) {
          result.push(clipped);
        }
      }
    }
    return result;
  }
}





