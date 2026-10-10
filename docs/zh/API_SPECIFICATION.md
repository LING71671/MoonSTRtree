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
- `intersects_segment(self : Box3D, x1 : Double, y1 : Double, z1 : Double, x2 : Double, y2 : Double, z2 : Double) -> Bool` — 判断 3D 包围盒是否与空间线段相交（基于三维 Liang-Barsky 轴向参数裁剪）。

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

### 2.4 `TreeStats3D`

```moonbit
pub struct TreeStats3D {
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

### 2.5 `FlatBuffers`

```moonbit
pub struct FlatBuffers {
  // 连续原生打平数组切片
} derive(Eq, Debug, Default)
```

---

### 2.6 `FlatBuffers3D`

```moonbit
pub struct FlatBuffers3D {
  // 三维连续原生打平数组切片
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

---

## 4. 三维空间索引 (`StrTree3D`)

### 4.1 `StrTree3D::build`

从三维包围盒数组批量构建紧凑连续数组 3D STR 空间索引树。

```moonbit
pub fn StrTree3D::build(items : Array[(Box3D, Int)], node_capacity? : Int = 16) -> StrTree3D
```

- **参数**：`items : Array[(Box3D, Int)]` — 三维几何元组列表；`node_capacity` — 节点最大分支容量（默认 16）。
- **切片算法**：基于立方根切片 $S_x = \lceil P^{1/3} \rceil$、二次方根切片 $S_y = \lceil \sqrt{P_x} \rceil$ 以及 Z 轴紧密排序连续打包。

---

### 4.2 `tree3d.query`

三维包围盒范围检索（3D Box Range Query）。

```moonbit
pub fn query(self : StrTree3D, search_box : Box3D) -> Array[Int]
```

- **参数**：`search_box : Box3D` — 目标三维搜索空间。
- **返回值**：`Array[Int]` — 所有包围盒与该搜索空间相交的对象 ID 列表。

---

### 4.3 `tree3d.query_count`

零堆分配三维相交计数检索。

```moonbit
pub fn query_count(self : StrTree3D, search_box : Box3D) -> Int
```

- **返回值**：`Int` — 相交图元总数，全过程零堆内存分配。

---

### 4.4 `tree3d.query_point`

三维点包含检索。

```moonbit
pub fn query_point(self : StrTree3D, x : Double, y : Double, z : Double) -> Array[Int]
```

- **返回值**：`Array[Int]` — 包含空间点 `(x, y, z)` 的所有对象 ID 列表。

---

### 4.5 `tree3d.query_point_count`

三维点包含零堆分配计数检索。

```moonbit
pub fn query_point_count(self : StrTree3D, x : Double, y : Double, z : Double) -> Int
```

- **返回值**：`Int` — 包含空间点 `(x, y, z)` 的对象总数。

---

### 4.6 `tree3d.query_sphere`

三维球体相交检索（3D Sphere Query）。

```moonbit
pub fn query_sphere(self : StrTree3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Array[Int]
```

- **返回值**：`Array[Int]` — 所有与目标球体相交的对象 ID 列表，基于平方距离剪枝。

---

### 4.7 `tree3d.query_sphere_count`

三维球体相交零堆分配计数检索。

```moonbit
pub fn query_sphere_count(self : StrTree3D, cx : Double, cy : Double, cz : Double, radius : Double) -> Int
```

- **返回值**：`Int` — 与目标球体相交的对象总数。

---

### 4.8 `tree3d.query_knn`

三维空间 K 最近邻分支定界检索（3D k-NN Query）。

```moonbit
pub fn query_knn(self : StrTree3D, x : Double, y : Double, z : Double, k : Int) -> Array[Int]
```

- **参数**：`x, y, z : Double` — 查询目标点三维坐标；`k : Int` — 最近邻目标数量。
- **算法**：基于三维包围盒最小欧式距离与扁平二叉最小堆的分支定界剪枝，返回按与目标点距离升序排列的至多 $k$ 个对象 ID。

---

### 4.9 `tree3d.query_knn_with_distance`

三维空间带距离度量 K 最近邻检索。

```moonbit
pub fn query_knn_with_distance(self : StrTree3D, x : Double, y : Double, z : Double, k : Int) -> Array[(Int, Double)]
```

- **返回值**：`Array[(Int, Double)]` — 按升序排列的 `(item_id, squared_distance)` 元组列表。

---

### 4.10 `tree3d.query_knn_with_predicate` & `query_knn_with_predicate_and_distance`

带业务谓词过滤的三维 K 最近邻检索。

```moonbit
pub fn query_knn_with_predicate(self : StrTree3D, x : Double, y : Double, z : Double, k : Int, predicate : (Int) -> Bool) -> Array[Int]
pub fn query_knn_with_predicate_and_distance(self : StrTree3D, x : Double, y : Double, z : Double, k : Int, predicate : (Int) -> Bool) -> Array[(Int, Double)]
```

- **特性**：在叶节点遍历分支中就地判定闭包谓词，只有满足业务条件的对象才入选候选堆并参与限界剪枝。

---

### 4.11 `tree3d.query_segment`

三维线段 / 光线投射相交检索（3D Ray-Casting Query）。

```moonbit
pub fn query_segment(self : StrTree3D, x1 : Double, y1 : Double, z1 : Double, x2 : Double, y2 : Double, z2 : Double) -> Array[Int]
```

- **参数**：空间线段起点 `(x1, y1, z1)` 与终点 `(x2, y2, z2)`。
- **算法**：基于三维 Liang-Barsky 轴向参数裁剪，支持体元与空间光线的快速微秒级求交。

---

### 4.12 `tree3d.query_first`

三维空间相交早停检索（Early-Exit Query）。

```moonbit
pub fn query_first(self : StrTree3D, search_box : Box3D, predicate : (Int) -> Bool) -> Int?
```

- **参数**：`search_box : Box3D` — 查询空间；`predicate : (Int) -> Bool` — 对象过滤条件。
- **返回值**：`Int?` — 命中首个满足条件的图元 ID 即刻短路返回 `Some(id)`，无命中返回 `None`。

---

### 4.13 `tree3d.query_with_predicate`

带业务谓词过滤的三维空间范围检索。

```moonbit
pub fn query_with_predicate(self : StrTree3D, search_box : Box3D, predicate : (Int) -> Bool) -> Array[Int]
```

- **返回值**：`Array[Int]` — 与窗口相交且满足闭包判定的对象 ID 列表。

---

### 4.14 `tree3d.spatial_join`

双树三维分层空间连接（3D Dual-Tree Hierarchical Spatial Join）。

```moonbit
pub fn spatial_join(self : StrTree3D, other : StrTree3D) -> Array[(Int, Int)]
```

- **参数**：`other : StrTree3D` — 另一棵 3D 空间索引树。
- **返回值**：`Array[(Int, Int)]` — 所有叶子包围盒相交的对象对 `(id_a, id_b)`。
- **算法**：基于双栈同步深度优先遍历，双向子树剪枝，免除 $O(N_A \times N_B)$ 笛卡尔积开销。

---

### 4.15 `tree3d.to_flat_buffers` & `StrTree3D::from_flat_buffers`

三维扁平原生数组导出与无拷贝反序列化重建。

```moonbit
pub fn to_flat_buffers(self : StrTree3D) -> FlatBuffers3D
pub fn StrTree3D::from_flat_buffers(buffers : FlatBuffers3D) -> StrTree3D
```

- **特性**：导出 6 个原生坐标打平数组及 CSR 拓扑结构，支持微秒级零开销持久化与 Wasm 共享。

---

### 4.16 `tree3d.stats`

获取三维树结构诊断统计指标。

```moonbit
pub fn stats(self : StrTree3D) -> TreeStats3D
```

---

## 5. 三维三角面片与网格空间索引 (`Triangle3D` & `StrMeshTree3D`)

### 5.1 `Triangle3D` 几何基元

连续三维空间中的三角面片结构：

```moonbit
pub struct Triangle3D {
  p0_x : Double
  p0_y : Double
  p0_z : Double
  p1_x : Double
  p1_y : Double
  p1_z : Double
  p2_x : Double
  p2_y : Double
  p2_z : Double
} derive(Eq, Debug, Default)
```

- `Triangle3D::new(p0_x, p0_y, p0_z, p1_x, p1_y, p1_z, p2_x, p2_y, p2_z) -> Triangle3D`：构建三维三角面片。
- `tri.to_box() -> Box3D`：计算三角面片的紧外包三维 AABB 轴对齐包围盒。
- `tri.centroid() -> (Double, Double, Double)`：计算几何重心质心点。
- `tri.normal() -> (Double, Double, Double)`：计算单位法向量（退化面返回默认法向）。
- `tri.area() -> Double`：计算三角面片欧几里得表面积。
- `tri.ray_intersection(ox, oy, oz, dx, dy, dz) -> Double?`：基于 Möller–Trumbore 双向相交算法计算光线与面片交点距离 $t \ge 0$。
- `tri.intersects_segment(x1, y1, z1, x2, y2, z2) -> Bool`：检测有限空间线段与三角面片是否精确穿透相交。

---

### 5.2 `StrMeshTree3D` 三角网格空间索引

专为三维多边形网格渲染与碰撞检测设计的高性能层次包围盒空间索引：

```moonbit
pub struct StrMeshTree3D { ... }
```

- `StrMeshTree3D::build(triangles : Array[Triangle3D], node_capacity? : Int = 16) -> StrMeshTree3D`：从三维三角面片数组批量打包构建。
- `mesh.num_triangles() -> Int`：返回索引内的三角面片总数。
- `mesh.get_triangle(id : Int) -> Triangle3D`：根据索引编号获取面片几何基元。
- `mesh.query_box(search_box : Box3D) -> Array[Int]`：检索与三维包围盒相交的候选面片索引列表。
- `mesh.query_segment(x1, y1, z1, x2, y2, z2) -> Array[Int]`：两阶段穿透检索：先通过 AABB 快速粗筛，再经由 Möller–Trumbore 精确相交测试。
- `mesh.query_first_ray_hit(ox, oy, oz, dx, dy, dz, max_distance? : Double = 1000000.0) -> (Int, Double)?`：光线追踪求交加速，返回沿光线方向首个击中的面片 ID 与距离参数 $t$。
- `mesh.query_all_ray_hits(ox, oy, oz, dx, dy, dz, max_distance? : Double = 1000000.0) -> Array[(Int, Double)]`：返回沿光线穿透的所有三角面片 ID 与击中距离，按命中距离由近至远排序。

---

## 6. 四维时空超包围体与连续轨迹索引 (`Box4D` & `StrTree4D`)

### 6.1 `Box4D` 四维时空几何基元

连续四维 $(x, y, z, t)$ 空间中的轴对齐超包围体：

```moonbit
pub struct Box4D {
  min_x : Double
  min_y : Double
  min_z : Double
  min_t : Double
  max_x : Double
  max_y : Double
  max_z : Double
  max_t : Double
} derive(Eq, Debug, Default)
```

- `Box4D::new(min_x, min_y, min_z, min_t, max_x, max_y, max_z, max_t) -> Box4D`：规范化构造四维超长方体。
- `box4d.intersects(other : Box4D) -> Bool`：四轴分离轴超体积相交判定。
- `box4d.contains_point(x, y, z, t) -> Bool`：时空四维点包含检测。
- `box4d.contains_box(other : Box4D) -> Bool`：超包围体全包含检测。
- `box4d.union(other : Box4D) -> Box4D`：合并两四维超长方体的最小外包超包围体。
- `box4d.intersection(other : Box4D) -> Box4D?`：求解两四维超长方体的相交区域。
- `box4d.hyper_volume() -> Double`：计算四维超体积（$\Delta x \times \Delta y \times \Delta z \times \Delta t$）。
- `box4d.to_box3d() -> Box3D`：提取空间三维投影包围盒。
- `box4d.expand(dx, dy, dz, dt) -> Box4D`：四向缓冲外扩。
- `box4d.intersects_at_time(other : Box4D, t : Double) -> Bool`：判定两移动对象在特定时间戳 $t$ 是否发生空间碰撞。

---

### 6.2 `StrTree4D` 四向递归切片索引

专为移动实体连续轨迹、动态碰撞检测与时空传感器观测设计的四维空间索引：

```moonbit
pub struct StrTree4D { ... }
```

- `StrTree4D::build(items : Array[(Box4D, Int)], node_capacity? : Int = 16) -> StrTree4D`：四向递归级联切片批量构建（$S_x = \lceil P^{1/4} \rceil, S_y = \lceil P_x^{1/3} \rceil, S_z = \lceil \sqrt{P_{xy}} \rceil$）。
- `tree4d.query(search_box : Box4D) -> Array[Int]`：四维超立方体范围检索。
- `tree4d.query_point(x, y, z, t) -> Array[Int]`：四维时空坐标点包含检测。
- `tree4d.query_count(search_box : Box4D) -> Int`：零堆分配超包围体图元计数。
- `tree4d.query_time_slice(t : Double, box_3d : Box3D) -> Array[Int]`：瞬时时空剖面截面检索（检索在时间 $t$ 处于指定三维包围盒内的所有移动对象）。
- `tree4d.stats() -> TreeStats4D`：计算四维树结构诊断统计指标。

---

## 7. DE-9IM 拓扑关系矩阵与自适应空间连接 (`SpatialPredicate`, `relate` & `spatial_join_predicate`)

### 7.1 `SpatialPredicate` 命名的 OGC 拓扑谓词枚举

```moonbit
pub(all) enum SpatialPredicate {
  Intersects
  Contains
  Within
  Touches
  Overlaps
  Disjoint
  Equals
  Covers
  CoveredBy
} derive(Eq, Debug)
```

- `SpatialPredicate::from_string(name : String) -> SpatialPredicate?`：解析谓词字符串。
- `predicate.to_string() -> String`：输出谓词小写标准标识符。

### 7.2 `Rect` DE-9IM 矩阵与拓扑谓词求值

- `rect.touches(other : Rect) -> Bool`：相交但内部不重叠（边界相交、内部不相交）。
- `rect.covers(other : Rect) -> Bool`：完全覆盖对方几何所有点。
- `rect.covered_by(other : Rect) -> Bool`：被对方完全覆盖。
- `rect.contains(other : Rect) -> Bool`：包含对方且内部非空相交。
- `rect.within(other : Rect) -> Bool`：处于对方内部。
- `rect.equals_exact(other : Rect) -> Bool`：四界坐标完全精确等价。
- `rect.disjoint(other : Rect) -> Bool`：完全分离，无任何公共点。
- `rect.overlaps(other : Rect) -> Bool`：内部相交但互不包含。
- `rect.evaluate_predicate(other : Rect, predicate : SpatialPredicate) -> Bool`：动态求值命名空间谓词。
- `rect.relate(other : Rect) -> String`：生成 9 字符 DE-9IM 维度相交矩阵字符串（如 `"2FFF1FFF2"`, `"FF2FF1212"`, `"212101212"`）。
- `matches_de9im_pattern(matrix : String, pattern : String) -> Bool`：根据通配符模式（`*`, `T`, `F`, `0`, `1`, `2`）校验 DE-9IM 矩阵。

### 7.3 `StrTree` 谓词检索与双树层次空间连接

- `tree.query_spatial_predicate(rect : Rect, predicate : SpatialPredicate) -> Array[Int]`：基于命名拓扑谓词的条件检索。
- `tree.spatial_join(other : StrTree) -> Array[(Int, Int)]`：默认基于边界相交（`Intersects`）的双树层次化自适应空间连接。
- `tree.spatial_join_predicate(other : StrTree, predicate : SpatialPredicate) -> Array[(Int, Int)]`：基于指定 DE-9IM 谓词的双树层次化自适应剪枝连接。

---

## 8. 空间密度聚类与网格热力聚合 (`ClusterResult`, `GridCell` & `GridDensitySummary`)

### 8.1 空间索引加速的密度聚类 DBSCAN

利用空间索引圆形范围检索（`query_circle` / `query_sphere`）将传统 $O(N^2)$ DBSCAN 算法加速至 $O(N \log N)$：

```moonbit
pub struct ClusterResult {
  labels : Array[Int]
  num_clusters : Int
  num_noise : Int
  cluster_sizes : Array[Int]
} derive(Eq, Debug, Default)
```

- `tree.dbscan(eps : Double, min_pts : Int) -> ClusterResult`：基于二维连续空间欧氏距离与空间树剪枝执行 DBSCAN 聚类。
- `tree3d.dbscan(eps : Double, min_pts : Int) -> ClusterResult`：基于三维连续空间球体距离与 3D 空间树剪枝执行 DBSCAN 聚类。

### 8.2 空间网格密度热力图聚合 (`GridCell` & `GridDensitySummary`)

```moonbit
pub struct GridCell {
  col : Int
  row : Int
  count : Int
  bounds : Rect
} derive(Eq, Debug, Default)

pub struct GridDensitySummary {
  cells : Array[GridCell]
  total_cells : Int
  max_density : Int
  avg_density : Double
  hotspot_cells : Array[GridCell]
} derive(Eq, Debug, Default)
```

- `tree.aggregate_grid(cell_width : Double, cell_height : Double, hotspot_threshold? : Int = 1) -> GridDensitySummary`：按固定宽高等距网格统计空间实体分布，输出单元格分布直方图、峰值密度及热点区域。







