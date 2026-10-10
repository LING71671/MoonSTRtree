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
### 1.7 `tree.query_knn_with_distance`

执行分支限界（Branch-and-Bound）K 最近邻空间检索，同时返回按升序排序的对象 ID 与精确平方欧几里得距离。

```moonbit
pub fn query_knn_with_distance(self : StrTree, x : Double, y : Double, k : Int) -> Array[(Int, Double)]
```

- **参数**：
  - `x : Double`, `y : Double` — 查询目标点。
  - `k : Int` — 请求检索的最大最近邻数量（若 $k \le 0$，返回空数组）。
- **返回值**：`Array[(Int, Double)]` — 按到目标点的欧几里得距离升序排列的 `(item_id, squared_distance)` 二元组列表。
- **优势**：避免调用方二次计算距离，在优先队列剪枝遍历期间直接输出精确平方距离度量。

---

### 1.8 `tree.query_knn_with_predicate`

执行带用户过滤谓词的分支限界（Branch-and-Bound）K 最近邻空间检索。

```moonbit
pub fn query_knn_with_predicate(self : StrTree, x : Double, y : Double, k : Int, predicate : (Int) -> Bool) -> Array[Int]
```

- **参数**：
  - `x : Double`, `y : Double` — 查询目标点。
  - `k : Int` — 请求检索的最大最近邻数量。
  - `predicate : (Int) -> Bool` — 对象 ID 过滤判定谓词。
- **返回值**：`Array[Int]` — 满足谓词且按欧几里得距离升序排列的前 $k$ 个对象 ID 列表。

---

### 1.9 `tree.query_knn_with_predicate_and_distance`

执行带用户过滤谓词的分支限界 K 最近邻检索，同时返回对象 ID 与对应平方距离。

```moonbit
pub fn query_knn_with_predicate_and_distance(self : StrTree, x : Double, y : Double, k : Int, predicate : (Int) -> Bool) -> Array[(Int, Double)]
```

- **参数**：
  - `x : Double`, `y : Double` — 查询目标点；`k : Int` — 最大数量；`predicate : (Int) -> Bool` — 过滤函数。
- **返回值**：`Array[(Int, Double)]` — 满足谓词且按欧氏距离升序排列的 `(item_id, squared_distance)` 列表。

---

### 1.10 `tree.query_segment`

执行二维线段/光线投射相交检索（Ray-Casting Traversal）。

```moonbit
pub fn query_segment(self : StrTree, x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Array[Int]
```

- **参数**：`(x1, y1)` 至 `(x2, y2)` — 目标线段两端点坐标。
- **返回值**：`Array[Int]` — 凡包围盒与该线段相交的对象 ID 列表。
- **数学基础**：内部基于 Liang-Barsky 参数化区间裁剪算法进行精确求交。

---

### 1.11 `tree.spatial_join`

执行双树同步分层空间连接（Dual-Tree Spatial Join）。

```moonbit
pub fn spatial_join(self : StrTree, other : StrTree) -> Array[(Int, Int)]
```

- **参数**：`other : StrTree` — 第二棵 STR 索引树。
- **返回值**：`Array[(Int, Int)]` — 所有包围盒存在重叠相交的元组对 `(id_a, id_b)`。
- **优化**：双树同步深度优先遍历，非重叠分支子树即刻剪枝，避免 $O(N_A \times N_B)$ 笛卡尔积开销。

---

### 1.12 `tree.query_count`

在紧凑空间索引上执行零结果堆分配的相交图元计数检索。

```moonbit
pub fn query_count(self : StrTree, search_window : Rect) -> Int
```

- **参数**：`search_window : Rect` — 查询窗口矩形。
- **返回值**：`Int` — 与查询窗口相交的图元总数。
- **优势**：不分配任何 ID 结果数组，仅在栈遍历中累计计数，实现纯零 GC 统计。

---

### 1.13 `tree.query_point_count`

在紧凑空间索引上执行零结果堆分配的点包含图元计数检索。

```moonbit
pub fn query_point_count(self : StrTree, x : Double, y : Double) -> Int
```

- **参数**：`x : Double`, `y : Double` — 目标点坐标。
- **返回值**：`Int` — 包含目标点的图元总数。

---

### 1.14 `tree.query_first`

返回首个与查询窗口相交且满足谓词过滤条件的对象 ID。

```moonbit
pub fn query_first(self : StrTree, search_window : Rect, predicate : (Int) -> Bool) -> Int?
```

- **参数**：
  - `search_window : Rect` — 查询窗口矩形。
  - `predicate : (Int) -> Bool` — 对象 ID 过滤函数。
- **返回值**：`Int?` — 满足条件的首个对象 ID，若无匹配项则返回 `None`。
- **优化**：一旦找到满足条件的对象即刻提前中断遍历，平均检索延迟极低。

---

### 1.15 `tree.query_with_predicate`

在紧凑空间索引上执行带用户谓词过滤的范围检索。

```moonbit
pub fn query_with_predicate(self : StrTree, search_window : Rect, predicate : (Int) -> Bool) -> Array[Int]
```

- **参数**：
  - `search_window : Rect` — 查询窗口矩形。
  - `predicate : (Int) -> Bool` — 对象 ID 过滤函数。
- **返回值**：`Array[Int]` — 与窗口相交且满足谓词的对象 ID 列表。

---

### 1.16 `tree.query_circle`

执行圆形/半径范围相交空间检索（Circle Range Query）。

```moonbit
pub fn query_circle(self : StrTree, cx : Double, cy : Double, radius : Double) -> Array[Int]
```

- **参数**：
  - `cx : Double`, `cy : Double` — 圆心坐标。
  - `radius : Double` — 搜索半径（若为负数直接返回空数组）。
- **返回值**：`Array[Int]` — 所有包围盒与该圆相交或包含于圆内的对象 ID 列表。
- **剪枝机制**：节点 AABB 平方距离剪枝，完全不相交的整棵子树立即剪去。

---

### 1.17 `tree.query_circle_count`

执行零结果堆分配的圆形/半径相交图元计数检索。

```moonbit
pub fn query_circle_count(self : StrTree, cx : Double, cy : Double, radius : Double) -> Int
```

- **参数**：`cx : Double`, `cy : Double` — 圆心坐标；`radius : Double` — 搜索半径。
- **返回值**：`Int` — 与圆相交的对象总数，全过程零堆内存分配。

---

### 1.18 `tree.to_flat_buffers` & `StrTree::from_flat_buffers`

扁平原生数组导出与无拷贝反序列化重建。

```moonbit
pub fn to_flat_buffers(self : StrTree) -> FlatBuffers
pub fn StrTree::from_flat_buffers(buffers : FlatBuffers) -> StrTree
```

- **特性**：提供底层原生连续数组的快速快照与还原，便于持久化或跨 Wasm 内存边界传递。

---

### 1.19 `tree.stats`

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
- `intersects_circle(self : Rect, cx : Double, cy : Double, radius : Double) -> Bool` — 圆形相交判定。
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

### 2.2 `Box3D`

三维空间轴对齐包围盒（3D AABB）。

```moonbit
pub struct Box3D {
  min_x : Double
  min_y : Double
  min_z : Double
  max_x : Double
  max_y : Double
  max_z : Double
} derive(Eq, Debug, Default)
```

#### 成员方法
- `Box3D::new(min_x, min_y, min_z, max_x, max_y, max_z) -> Box3D` — 构造三维归一化包围盒。
- `Box3D::from_point(x, y, z) -> Box3D` — 构造以点为中心的退化零体积包围盒。
- `intersects(self : Box3D, other : Box3D) -> Bool` — 判断两 3D 包围盒是否相交或接触。
- `contains_point(self : Box3D, x : Double, y : Double, z : Double) -> Bool` — 判定三维点是否位于包围盒内。
- `contains_box(self : Box3D, other : Box3D) -> Bool` — 判定是否完全包含目标 3D 包围盒。
- `union(self : Box3D, other : Box3D) -> Box3D` — 计算并集最小外包盒（MBB）。
- `intersection(self : Box3D, other : Box3D) -> Option[Box3D]` — 计算相交子包围盒（若不相交则返回 None）。
- `volume(self : Box3D) -> Double` — 计算体积 $\Delta x \times \Delta y \times \Delta z$。
- `surface_area(self : Box3D) -> Double` — 计算表面积 $2(\Delta x \Delta y + \Delta y \Delta z + \Delta z \Delta x)$。
- `center_x(self : Box3D) -> Double`, `center_y(self : Box3D) -> Double`, `center_z(self : Box3D) -> Double` — 几何中心坐标。
- `expand(self : Box3D, delta : Double) -> Box3D` — 六向等距外扩。
- `distance_squared_to_point(self : Box3D, x : Double, y : Double, z : Double) -> Double` — 点到 3D 盒平方距离。
- `distance_to_box(self : Box3D, other : Box3D) -> Double` — 两 3D 包围盒间最小欧几里得距离（相交时为 0.0）。
- `iou(self : Box3D, other : Box3D) -> Double` — 计算三维体积交并比（Intersection over Union），取值在 $[0.0, 1.0]$。
- `intersects_sphere(self : Box3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Bool` — 判断 3D 包围盒是否与空间球体相交或包含球体。

---

### 2.3 `TreeStats`

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

### 2.4 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // 连续原生打平数组切片
} derive(Eq, Debug, Default)
```

---

## 3. 合成空间分布生成器

根包提供标准合成数据分布生成器，用于基准对拍与压力测试：

1. `generate_uniform(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 全域均匀随机分布。
2. `generate_clustered(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 多聚类高斯分布。
3. `generate_diagonal(rng : Rng, count : Int, ...) -> Array[(Rect, Int)]` — 对角线退化共线分布。
4. `generate_concentric(count : Int, ...) -> Array[(Rect, Int)]` — 同心嵌套矩形分布。
5. `generate_grid(rows : Int, cols : Int, ...) -> Array[(Rect, Int)]` — 正则网格 GIS 瓦片分布。
6. `generate_boxes_3d_uniform(rng : Rng, count : Int, ...) -> Array[(Box3D, Int)]` — 三维全域均匀随机包围盒分布。
7. `generate_boxes_3d_clustered(rng : Rng, count : Int, ...) -> Array[(Box3D, Int)]` — 三维多聚类高斯包围盒分布。

