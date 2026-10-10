# MoonSTRtree 接口规范

[English](../en/API_SPECIFICATION.md) | [中文说明](./API_SPECIFICATION.md)

本文定义 MoonSTRtree 的公共 API 契约、输入输出类型、不变式与异常边界。

---

## 1. 顶层公共 API

所有公共接口均在根包模块 `LING71671/moon_strtree` 导出。

### 1.1 `Rect::new`

在连续二维空间中构造轴对齐包围矩形（AABB）。

```moonbit
pub fn Rect::new(min_x : Double, min_y : Double, max_x : Double, max_y : Double) -> Rect
```

- **参数**：
  - `min_x : Double` — X 轴下界。
  - `min_y : Double` — Y 轴下界。
  - `max_x : Double` — X 轴上界。
  - `max_y : Double` — Y 轴上界。
- **不变式保证**：
  - 自动归一化坐标：若 `min_x > max_x`，自动交换；若 `min_y > max_y`，自动交换。
  - 严格支持负数坐标与零面积退化边界。

---

### 1.2 `Rect::from_point`

构造以 `(x, y)` 为中心的零面积退化点矩形。

```moonbit
pub fn Rect::from_point(x : Double, y : Double) -> Rect
```

- **参数**：`x : Double`, `y : Double` — 点坐标。
- **返回值**：`Rect`，满足 `min_x == max_x == x` 且 `min_y == max_y == y`。

---

### 1.3 `StrTree::build`

基于 Sort-Tile-Recursive（STR）算法批量打包构建紧凑 R 树。

```moonbit
pub fn StrTree::build(items : Array[(Rect, Int)], node_capacity~ : Int = 16) -> StrTree
```

- **参数**：
  - `items : Array[(Rect, Int)]` — 矩形与对象整数 ID 构成的元组数组。
  - `node_capacity : Int` — 节点最大容量（默认：16，必须 $\ge 2$）。
- **不变式保证**：
  - 确定性纯函数式构建。
  - 优雅处理空输入数组，直接生成合法空树而不 panic。
  - 所有层级节点扁平化打包为内部连续原生数组。

---

### 1.4 `tree.query`

在紧凑空间索引上执行轴对齐范围相交检索。

```moonbit
pub fn query(self : StrTree, search_window : Rect) -> Array[Int]
```

- **参数**：`search_window : Rect` — 查询窗口矩形。
- **返回值**：`Array[Int]` — 所有包围盒与查询窗口相交的对象 ID 列表。
- **复杂度**：平均时间复杂度为 $O(\log_M N)$。

---

### 1.5 `tree.query_point`

在紧凑空间索引上执行点包含判定检索。

```moonbit
pub fn query_point(self : StrTree, x : Double, y : Double) -> Array[Int]
```

- **参数**：`x : Double`, `y : Double` — 目标点坐标。
- **返回值**：`Array[Int]` — 所有包围盒包含该点的对象 ID 列表。

---

### 1.6 `tree.query_knn`

执行分支限界（Branch-and-Bound）K 最近邻空间检索。

```moonbit
pub fn query_knn(self : StrTree, x : Double, y : Double, k : Int) -> Array[Int]
```

- **参数**：
  - `x : Double`, `y : Double` — 查询目标点。
  - `k : Int` — 请求检索的最大最近邻数量（若 $k \le 0$，返回空数组）。
- **返回值**：`Array[Int]` — 按到目标点的欧几里得距离升序排列的对象 ID 列表。
- **剪枝机制**：利用节点 AABB 的 MinDist 下界与扁平二叉最小堆执行优先队列剪枝。

---

### 1.7 `tree.query_segment`

执行二维线段/光线投射相交检索（Ray-Casting Traversal）。

```moonbit
pub fn query_segment(self : StrTree, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Array[Int]
```

- **参数**：`(x1, y1)` 至 `(x2, y2)` — 目标线段两端点坐标。
- **返回值**：`Array[Int]` — 凡包围盒与该线段相交的对象 ID 列表。
- **数学基础**：内部基于 Liang-Barsky 参数化区间裁剪算法进行精确求交。

---

### 1.8 `tree.spatial_join`

执行双树同步分层空间连接（Dual-Tree Spatial Join）。

```moonbit
pub fn spatial_join(self : StrTree, other : StrTree) -> Array[(Int, Int)]
```

- **参数**：`other : StrTree` — 第二棵 STR 索引树。
- **返回值**：`Array[(Int, Int)]` — 所有包围盒存在重叠相交的元组对 `(id_a, id_b)`。
- **优化**：双树同步深度优先遍历，非重叠分支子树即刻剪枝，避免 $O(N_A \times N_B)$ 笛卡尔积开销。

---

### 1.9 `tree.to_flat_buffers` & `StrTree::from_flat_buffers`

扁平原生数组导出与无拷贝反序列化重建。

```moonbit
pub fn to_flat_buffers(self : StrTree) -> FlatBuffers
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree
```

- **特性**：提供底层原生连续数组的快速快照与还原，便于持久化或跨 Wasm 内存边界传递。

---

### 1.10 `tree.stats`

计算并返回树结构诊断统计指标。

```moonbit
pub fn stats(self : StrTree) -> TreeStats
```

- **返回值**：`TreeStats` — 包含树高、总节点数、元素数、填充率、边缘数与内存估算字节数等。

---

## 2. 核心数据类型

### 2.1 `Rect`

```moonbit
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Debug, Default)
```

#### 成员方法
- `intersects(self : Rect, other : Rect) -> Bool` — 判断当前矩形是否与目标矩形相交或边缘接触。
- `contains_point(self : Rect, x : Double, y : Double) -> Bool` — 闭区间点包含判定。
- `contains_rect(self : Rect, other : Rect) -> Bool` — 矩形完全包含判定。
- `intersects_segment(self : Rect, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Bool` — 线段相交判定。
- `distance_to_point(self : Rect, x : Double, y : Double) -> Double` — 点到矩形欧几里得距离。
- `distance_squared_to_point(self : Rect, x : Double, y : Double) -> Double` — 点到矩形平方距离。
- `union(self : Rect, other : Rect) -> Rect` — 计算两矩形的最小外包矩形。
- `center_x(self : Rect) -> Double` — 中心点 X 坐标。
- `center_y(self : Rect) -> Double` — 中心点 Y 坐标。
- `width(self : Rect) -> Double` — 宽度。
- `height(self : Rect) -> Double` — 高度。
- `area(self : Rect) -> Double` — 面积。
- `intersection(self : Rect, other : Rect) -> Option[Rect]` — 计算两矩形相交形成的子矩形（若不相交则返回 None）。
- `expand(self : Rect, delta : Double) -> Rect` — 四向均匀外扩（若 delta 为负则收缩）矩形边界。
- `distance_to_rect(self : Rect, other : Rect) -> Double` — 两矩形间最小欧几里得距离（相交时为 0.0）。
- `distance_squared_to_rect(self : Rect, other : Rect) -> Double` — 两矩形间最小平方距离。
- `iou(self : Rect, other : Rect) -> Double` — 计算交并比（Intersection over Union），取值在 $[0.0, 1.0]$。

---

### 2.2 `TreeStats`

```moonbit
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
  leaf_nodes : Int
  branch_nodes : Int
  total_edges : Int
  estimated_memory_bytes : Int
} derive(Eq, Debug, Default)
```

---

### 2.3 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // 连续原生打平数组切片
} derive(Eq, Debug, Default)
```

---

## 3. 合成空间分布生成器

根包提供 5 类标准合成数据分布生成器，用于基准对拍与压力测试：

1. `generate_uniform(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 全域均匀随机分布。
2. `generate_clustered(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 多聚类高斯分布。
3. `generate_diagonal(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 对角线退化共线分布。
4. `generate_concentric(count : Int, ...) -> Array[(Rect, Int)]` — 同心嵌套矩形分布。
5. `generate_grid(rows : Int, cols : Int, ...) -> Array[(Rect, Int)]` — 正则网格 GIS 瓦片分布。

