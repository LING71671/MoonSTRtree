# MoonSTRtree 形式化技术规格说明书 (Specification)

[English](../en/SPEC.md) | [中文说明](./SPEC.md)

本文档定义 MoonSTRtree 空间索引引擎的形式化数学基础、算法不变式、连续内存布局与质量验收规范。

---

## 1. 形式化数学基础

### 1.1 连续坐标空间
全部几何对象存在于连续二维欧几里得空间 $\mathbb{R}^2$ 中，坐标使用 IEEE 754 双精度浮点数（`Double`）表示。

### 1.2 轴对齐包围盒 (AABB)
包围盒 $R$ 定义为笛卡尔闭区间积：
$$R = [x_{\min}, x_{\max}] \times [y_{\min}, y_{\max}]$$
严格遵守坐标有序不变式：
$$x_{\min} \le x_{\max} \quad \text{且} \quad y_{\min} \le y_{\max}$$

对于任意非归一化输入四元组 $(x_1, y_1, x_2, y_2)$，归一化计算公式为：
$$x_{\min} = \min(x_1, x_2), \quad x_{\max} = \max(x_1, x_2)$$
$$y_{\min} = \min(y_1, y_2), \quad y_{\max} = \max(y_1, y_2)$$

### 1.3 核心几何谓词

#### 1.3.1 相交判定 (Intersection)
两包围盒 $A$ 与 $B$ 相交（$A \cap B \ne \emptyset$）当且仅当两轴投影区间均有重叠：
$$\text{intersects}(A, B) \iff \neg (A.x_{\max} < B.x_{\min} \lor A.x_{\min} > B.x_{\max} \lor A.y_{\max} < B.y_{\min} \lor A.y_{\min} > B.y_{\max})$$

#### 1.3.2 点包含判定 (Point Containment)
点 $p = (x, y)$ 位于包围盒 $B$ 内部或边界（$p \in B$）当且仅当：
$$\text{contains\_point}(B, x, y) \iff B.x_{\min} \le x \le B.x_{\max} \land B.y_{\min} \le y \le B.y_{\max}$$

#### 1.3.3 最小外包矩形并集 (MBR Union)
包络 $A$ 与 $B$ 的最小外包矩形计算公式为：
$$\text{union}(A, B) = [\min(A.x_{\min}, B.x_{\min}), \max(A.x_{\max}, B.x_{\max})] \times [\min(A.y_{\min}, B.y_{\min}), \max(A.y_{\max}, B.y_{\max})]$$

---

## 2. Sort-Tile-Recursive (STR) 算法形式化

给定 $N$ 个空间图元及节点最大容量 $M \ge 2$：

1. **叶子节点（页面）总数**：
   $$P = \left\lceil \frac{N}{M} \right\rceil$$
2. **垂直切片总数**：
   $$S = \left\lceil \sqrt{P} \right\rceil$$
3. **每个切片包含的页面数**：
   $$P_{\text{slice}} = \left\lceil \frac{P}{S} \right\rceil$$
4. **切片容量阈值**：
   $$C_{\text{slice}} = P_{\text{slice}} \times M$$
5. **横向切片划分**：
   按几何中心 X 坐标排序：
   $$\text{center}_x = \frac{x_{\min} + x_{\max}}{2.0}$$
   将全部图元划分为 $S$ 个连续垂直切片，各切片规模上限为 $C_{\text{slice}}$。
6. **纵向块打包**：
   在每个垂直切片内部，按几何中心 Y 坐标排序：
   $$\text{center}_y = \frac{y_{\min} + y_{\max}}{2.0}$$
   每连续 $M$ 个图元聚合为一个父节点，其 MBR 为子节点的几何并集。
7. **自底向上收敛**：
   将生成的父节点作为新输入集合，重复上述 1–6 步，直至生成唯一样根节点。

---

## 3. 连续内存与扁平数组存储

为规避离散指针寻址开销、提高 CPU 数据缓存命中率并消除 WebAssembly 运行时的垃圾回收抖动：

### 3.1 基础坐标扁平数组
- `boxes_min_x: Array[Double]` — 各节点 X 轴下界。
- `boxes_min_y: Array[Double]` — 各节点 Y 轴下界。
- `boxes_max_x: Array[Double]` — 各节点 X 轴上界。
- `boxes_max_y: Array[Double]` — 各节点 Y 轴上界。

### 3.2 CSR 拓扑邻接索引数组
- `child_offset: Array[Int]` — 节点 $i$ 在子节点列表中的起始偏移。
- `child_count: Array[Int]` — 节点 $i$ 的子节点数量（叶子项为 0）。
- `child_indices: Array[Int]` — 子节点拓扑索引连续紧凑数组。
- `item_ids: Array[Int]` — 用户关联的对象整数标识（内部节点标记为 -1）。

---

## 4. 查询剪枝与性能保证

### 4.1 迭代栈遍历机制
- 查询遍历全过程不使用函数递归调用。
- 维护固定深度的整数栈保存待访问节点索引。
- 仅当内部节点的 MBR 与查询窗口相交时，才将其子节点推入栈中；不相交子树整棵剪枝。

### 4.2 零堆分配约束 (Zero-GC)
- 遍历核心循环严禁产生任何动态对象分配。

### 4.3 分支限界 K 最近邻检索 (k-NN Search & Distance Metrics)
- **MinDist 下界度量**：对任意点 $p = (x, y)$ 与节点 AABB $R$，计算最小欧几里得距离下界：
  $$\text{MinDist}(p, R)^2 = \Delta x^2 + \Delta y^2$$
  其中 $\Delta x = \max(R.x_{\min} - x, 0, x - R.x_{\max})$，$\Delta y = \max(R.y_{\min} - y, 0, y - R.y_{\max})$。
- **优先队列剪枝**：维护扁平二叉最小堆存储候选节点；当且仅当堆顶节点的 $\text{MinDist}$ 大于已收集 $k$ 个候选的最差距离时，可即刻提前终止遍历。
- **精确距离度量输出**：`query_knn_with_distance` 在剪枝过程中无额外开销直接返回单调递增的 `(item_id, squared_distance)` 二元组，避免外部重复计算。
- **谓词联动过滤**：`query_knn_with_predicate` 与 `query_knn_with_predicate_and_distance` 仅将通过谓词判定的叶子图元入选候选集，维持剪枝上界有效性的同时规避全量检索后的二次过滤。

### 4.4 参数化光线/线段投射检索 (Ray-Casting)
- **Liang-Barsky 区间求交**：线段参数化表示为 $P(t) = P_1 + t(P_2 - P_1), t \in [0, 1]$。
- **无递归轴向裁剪**：在 $X$ 与 $Y$ 方向分别计算进出参数 $[t_1, t_2]$，若 $t_{\min} > t_{\max}$ 则提前剪除整棵子树。

### 4.5 双树分层空间连接 (Dual-Tree Spatial Join)
- **同步深度优先遍历**：维护待判定节点对栈 $[(u_A, v_B)]$。
- **双向子树剪枝**：若 $\text{intersects}(\text{MBR}(u_A), \text{MBR}(v_B)) = \text{false}$，立即剪去整组分支，以次二次方复杂度替代 $O(N_A \times N_B)$ 全量遍历。

### 4.6 原生扁平数组序列化 (FlatBuffers)
- **无拷贝快照**：将坐标四元组、CSR 偏移与图元 ID 数组直接序列化为连续原生内存缓冲区，支持毫秒级持久化与 Wasm 跨边界共享。

### 4.7 矩形拓扑交并与几何度量 (Rect Metrics & IoU)
- **子矩形相交区间**：若两矩形相交，交集矩形为 $[\max(x_{\min 1}, x_{\min 2}), \max(y_{\min 1}, y_{\min 2})] \times [\min(x_{\max 1}, x_{\max 2}), \min(y_{\max 1}, y_{\max 2})]$。
- **交并比度量 (IoU)**：$\text{IoU}(R_1, R_2) = \frac{\text{Area}(R_1 \cap R_2)}{\text{Area}(R_1) + \text{Area}(R_2) - \text{Area}(R_1 \cap R_2)}$，取值归一化至 $[0.0, 1.0]$。
- **矩形间最小距离**：沿分离轴计算欧氏投影间距 $\Delta x^2 + \Delta y^2$ 开方，相交时直接返回 0.0。
- **自适应边界外扩 (Expand)**：支持四向等距动态缓冲带扩展与收缩运算。

### 4.8 零堆分配空间计数与短路谓词检索 (Zero-Allocation Counting & Early Exit)
- **零结果堆分配统计**：`query_count` 与 `query_point_count` 仅维护局部整型计数器累加叶子相交数，全程不分配任何 `Array[Int]` 堆内存，实现纯零 GC 统计。
- **即时早停谓词检索**：`query_first` 结合用户闭包判定，在发现首个符合条件的叶子项时即刻短路返回 `Some(id)` 并终止遍历，平均时延大幅降低。
- **谓词过滤检索**：`query_with_predicate` 支持在空间树遍历期同步完成业务逻辑初筛。

### 4.9 圆形/距离半径空间相交检索 (Circle Range Query)
- **欧氏平方距离剪枝**：针对圆心 $(c_x, c_y)$ 与半径 $R$，各节点 MBR 计算到圆心的最小投影平方距离 $\Delta x^2 + \Delta y^2$；若大于 $R^2$ 则整棵子树剪枝，免去昂贵的浮点开方运算。
- **零分配半径计数**：`query_circle_count` 在地理围栏探测与缓冲区邻域统计中提供零 GC 高性能计数。

### 4.10 三维空间包围盒拓扑算子 (3D AABB Box3D)
- **三轴正交分离轴判定**：在 $X, Y, Z$ 三个正交轴上执行分离轴区间判定，仅当三轴均有重叠投影时判定相交。
- **体积与表面积几何度量**：$\text{Volume} = \Delta x \times \Delta y \times \Delta z$，$\text{SurfaceArea} = 2(\Delta x \Delta y + \Delta y \Delta z + \Delta z \Delta x)$。
- **三维点到盒距离度量**：三轴独立投影计算 $\Delta x^2 + \Delta y^2 + \Delta z^2$，支持体元聚类与 3D 点云空间划分。
- **3D 盒间距离与交并比 (IoU)**：沿分离轴正交投影计算三维欧式间距；通过体积比率快速求解 3D 碰撞重叠率。
- **球盒相交检测 (Sphere-Box Collision)**：利用点到盒平方距离度量，以无开方代价完成 $R^2$ 几何相交判定。

### 4.11 三维 Sort-Tile-Recursive 连续数组索引 (3D STRtree)
- **三向递归切片构建**：计算叶子页数 $P = \lceil N / M \rceil$，立方根切片划分垂直厚板 $S_x = \lceil P^{1/3} \rceil$，板内平方根切片划分纵列 $S_y = \lceil \sqrt{P_x} \rceil$，列内按 Z 轴排序连续打包。
- **三维连续打平布局**：采用六元组基础坐标数组 `boxes_min_x/y/z` 与 `boxes_max_x/y/z`，结合压缩稀疏行 CSR 拓扑存储，保障 $O(N)$ 零冗余缓存友好性。
- **多模式三维空间遍历**：支持 3D AABB 包围盒范围相交检索 (`query`)、零堆分配相交计数 (`query_count`)、三维空间点包含 (`query_point`) 及球体距离相交检索 (`query_sphere`)。

### 4.12 三维 K 最近邻与参数化光线投射 (3D k-NN & Ray-Casting)
- **三维分支定界 k-NN**：利用扁平二叉最小堆与点到包围盒三维欧氏平方距离，维护有序候选集，当待访问节点距离超过第 $k$ 个候选的最远距离时实施全局子树剪枝。支持排序距离输出 (`query_knn_with_distance`) 及谓词过滤 (`query_knn_with_predicate`)。
- **三维 Liang-Barsky 光线参数裁剪**：在 $X, Y, Z$ 三个正交轴上独立计算参数区间 $[t_{\min}, t_{\max}]$，判定空间线段与包围盒是否相交 (`query_segment`)，支持视线遮挡检测与体元拾取。
- **零分配三维计数**：`query_point_count` 与 `query_sphere_count` 提供无垃圾回收开销的三维图元统计。

### 4.13 三维双树空间连接与原生序列化 (3D Spatial Join & FlatBuffers3D)
- **同步深度优先双树遍历**：`spatial_join` 采用双栈同步深度优先剪枝，在两棵树的各层节点 MBR 相交时推入候选子节点对，以次二次方复杂度高效捕获三维相交几何元组对。
- **早停短路与闭包谓词**：`query_first` 提供首个相交图元的快速返回；`query_with_predicate` 支持遍历期间即时过滤业务逻辑。
- **连续原生内存快照**：`FlatBuffers3D` 完整持久化 6 个坐标数组及 CSR 邻接表，支持多进程及 Wasm 间零拷贝快速还原。

### 4.14 三维三角面片几何与网格空间索引 (3D Triangle & Mesh Indexing)
- **Möller–Trumbore 精确相交**：在重心坐标系下求解线性方程组 $\mathbf{O} + t \mathbf{D} = (1 - u - v)\mathbf{V}_0 + u \mathbf{V}_1 + v \mathbf{V}_2$，在 $O(1)$ 时间内判定空间射线与三角面片的交点，支持背面双向判定与退化面截断。
- **两阶段层次网格加速管线**：`StrMeshTree3D` 将复杂网格所有面片的紧外包 AABB 打包进入 `StrTree3D`。空间查询（包围盒、线段、光线）首先在层次包围盒树中实施对数级粗筛剪枝，再对剩余候选面片执行 Möller–Trumbore 精确求交，实现高精高效的光线追踪与穿透判定。

### 4.15 四维时空超包围体与连续轨迹索引 (4D Spatiotemporal Indexing)
- **4D 超包围体几何度量**：`Box4D` 定义四维时空超长方体，支持分离轴超体积相交、时空包含检测、超体积度量 $\prod \Delta x_i$ 与瞬时碰撞时间戳求交 (`intersects_at_time`)。
- **四向递归级联切片**：`StrTree4D` 依据 $S_x = \lceil P^{1/4} \rceil, S_y = \lceil P_x^{1/3} \rceil, S_z = \lceil \sqrt{P_{xy}} \rceil$ 进行四向空间排序与级联切片，将动态移动对象组织为连续数组索引，支持时间切片瞬时检索 (`query_time_slice`)。

### 4.16 DE-9IM 拓扑关系矩阵与自适应空间连接 (DE-9IM & Spatial Joins)
- **维度扩展九交模型 (DE-9IM)**：精确计算几何对象内部 ($I$)、边界 ($B$)、外部 ($E$) 之间的 9 单元交集维度矩阵，生成规范化 9 字符代码 (`Rect::relate`) 并支持通配符模式匹配 (`matches_de9im_pattern`)。
- **OGC 命名空间谓词**：直接高效求值 `Intersects`、`Contains`、`Within`、`Touches`、`Overlaps`、`Disjoint`、`Equals`、`Covers`、`CoveredBy`。
- **双树层次空间连接**：基于 R 树层级包围盒剪枝与自适应优先展开启发式策略，实现 $O(N \log N)$ 复杂度的跨图元集双树空间连接 (`spatial_join`, `spatial_join_predicate`)。

### 4.17 空间索引加速聚类与网格热力聚合 (Spatial Clustering & Grid Aggregation)
- **树剪枝加速 DBSCAN 聚类**：将 2D 矩形距离与 3D 球体剪枝结合，替代传统 DBSCAN 的暴力全距离扫描。基于 `query_circle` / `query_sphere` 将邻域检索开销从 $O(N)$ 降至对数阶 $O(\log N)$，实现大体量点云或图元的快速密度连通性聚类。
- **等距正交网格密度聚合**：`aggregate_grid` 将全域空间自适应离散化为规则等距网格单元，统计各单元几何落点频次、密度占比与峰值热点，支持按密度倒序识别核心空间聚集区域。

### 4.18 地理围栏流式状态监听与时空轨迹滑动窗口 (Geofencing & Trajectory Window Index)
- **空间索引加速地理围栏状态机**：利用紧凑空间树 `StrTree` 存储全域地理围栏多边形/包围盒。通过 `query_point` 或 `query` 在 $O(\log N)$ 时间内检测移动实体所处的全部候选围栏，与上一周期状态进行差分对比，派发 `Enter`、`Exit`、`Stay` 离散事件。
- **时空轨迹段双重约束检索**：`TrajectoryWindowIndex` 将移动轨迹划分为有向时空线段 $(p_0, p_1)$，空间上利用 R 树包围盒剪枝，时间上基于闭区间相交 $[seg.min\_t, seg.max\_t] \cap [t_{\min}, t_{\max}] \ne \emptyset$ 实施快速过滤，支持动态时间滑动窗口分析与航迹识别。

---



## 5. 复杂度与理论上界

| 指标维度 | 理论界限 |
| :--- | :--- |
| 批量构建时间复杂度 | $O(N \log N)$ |
| 内存存储空间复杂度 | $O(N)$ 紧凑连续空间 |
| 范围查询平均时间复杂度 | $O(\log_M N)$ |
| 范围查询最坏时间复杂度 | $O(N)$（所有图元全域重叠） |
| 查询阶段堆内存分配 | 严格 $0$ 字节 |
| 函数调用栈开销 | $O(1)$ 恒定 |

---

## 6. 退化边界与异常规约

- **空集合输入 ($N = 0$)**：构造合法空树，`num_items = 0`，`height = 0`，查询操作立即返回空数组。
- **单元素输入 ($N = 1$)**：生成具有单一根节点与单一叶子图元的有效树结构。
- **零面积图元**：零面积点矩形（$x_{\min} = x_{\max}, y_{\min} = y_{\max}$）与零宽度线段均作为闭区间正常索引。
- **非有限坐标**：通过 `Rect::is_valid` 过滤 NaN 与无穷大异常值。
