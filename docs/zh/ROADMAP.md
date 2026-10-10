# MoonSTRtree 项目技术路线图与研发全景 (Technical Roadmap)

[English](../en/ROADMAP.md) | [中文说明](./ROADMAP.md)

本文档规范 MoonSTRtree 空间索引引擎从原型设计、算法核心落地、形式化验证、性能基准到跨平台生态的完整技术路线图。包含各阶段的数学原理、数据结构、性能量化目标与交付物定义。

---

## 1. 核心技术指标与设计原则

MoonSTRtree 旨在为 MoonBit 生态提供具备工业级吞吐与微秒级响应的紧凑型静态 2D 空间索引，严格遵守以下指标约束：

1. **查询零堆内存分配 (Zero GC Allocation)**：遍历过程严格在预分配连续整数栈上执行，检索核心循环分配堆内存精确为 0 字节。
2. **紧凑连续内存存储 (Packed Layout)**：多层包围盒与拓扑关系打平为一维原生连续数组，每个索引图元的全树均摊内存开销 $\le 44$ 字节。
3. **构建吞吐指标**：在 Native 平台达到 $\ge 500,000$ 图元/秒；在 Wasm32 平台达到 $\ge 200,000$ 图元/秒。
4. **单次检索延迟指标**：在 $10^5$ 规模图元数据集上，选择率为 $0.1\%$ 的窗口范围检索延迟 $\le 1.5\,\mu\text{s}$，点包含检测延迟 $\le 0.5\,\mu\text{s}$。
5. **绝对结果等价性**：任意规模、任意分布下的查询结果与 $O(N)$ 暴力线性扫描保持 100% 同构（无漏查、无多查）。

---

## 2. 研发阶段规划与技术交付物

### 第一阶段：代数几何基元与浮点区间算术 (v0.1.0) — [已完成]

- **数学模型与数据结构**：
  - 连续欧几里得空间二维 AABB 结构：`Rect { min_x: Double, min_y: Double, max_x: Double, max_y: Double }`。
  - 自动坐标归一化机制：在输入反转坐标（`min > max`）时自动纠正，保障全生命周期不变式。
- **空间拓扑谓词实现**：
  - 精确闭区间相交判定：$\neg(A.x_{\max} < B.x_{\min} \lor A.x_{\min} > B.x_{\max} \lor A.y_{\max} < B.y_{\min} \lor A.y_{\min} > B.y_{\max})$。
  - 边界闭区间点包含与矩形包含判定。
  - 最小外包矩形（MBR）几何并集算子。
- **测试验收基线**：
  - 覆盖零面积退化点、共线退化线段、负数坐标系与大跨度坐标边界。
  - 几何操作自反性、对称性与传递性属性验证。

---

### 第二阶段：STR 双向切片拓扑与连续内存打包 (v0.2.0) — [已完成]

- **Sort-Tile-Recursive 批量构建算法形式化**：
  - 纯整数切片算术：计算目标叶子页数 $P = \lceil N/M \rceil$、垂直切片数 $S = \lceil \sqrt{P} \rceil$、单切片页数 $P_{\text{slice}} = \lceil P/S \rceil$ 及切片容量 $C_{\text{slice}} = P_{\text{slice}} \times M$。
  - 双轴分层贪心排序：全局几何中心 X 坐标排序划分垂直切片；切片内部局部几何中心 Y 坐标二次排序。
  - 自底向上递归层级收敛：叶子层节点按容量 $M$ 连续打包，以父节点集合作为新输入递归收敛至唯一样根节点，树高严格受控为 $H = \lceil \log_M P \rceil + 1$。
- **紧凑扁平数组布局 (Flat Arrays & CSR)**：
  - 坐标基础数组：`boxes_min_x/y/max_x/max_y : Array[Double]`。
  - 拓扑邻接压缩稀疏行（CSR）：`child_offset : Array[Int]`、`child_count : Array[Int]`、`child_indices : Array[Int]`。
  - 叶子对象标识映射：`item_ids : Array[Int]`（叶子项映射原始 ID，分支节点固定为 -1）。
- **迭代栈深度优先遍历剪枝引擎**：
  - 消除函数递归调用栈开销，最大栈深上界为 $H \times M$。
  - 非相交子树空间即刻剪枝，命中分支连续推栈。

---

### 第三阶段：结构诊断、顶层门面与暴力对拍验证 (v0.3.0) — [已完成]

- **空间拓扑质量与诊断度量衡 (`src/stats`)**：
  - 平均节点填充率：$\eta = \frac{N}{P \times M} \times 100\%$。
  - 空间重叠率因子：父级节点间 MBR 相交面积比率分析。
  - 树结构不变式校验器：递归验证根到叶各级包围盒严格包含所有子级包围盒。
- **顶层公共 API 门面 (`moon_strtree`)**：
  - 根包导出统一类型别名与无状态方法：`Rect`、`StrTree`、`TreeStats`。
  - 规范对外构造签名：`StrTree::build(items : Array[(Rect, Int)], node_capacity~ : Int = 16) -> StrTree`。
  - 规范查询接口：`query(self : StrTree, search_window : Rect) -> Array[Int]` 与 `query_point(self : StrTree, x : Double, y : Double) -> Array[Int]`。
- **全量差分对拍与模糊测试 (Fuzzing Suite)**：
  - 自动化生成 1,000 至 10,000 个随机矩形与随机查询窗口。
  - 与 $O(N)$ 线性全表扫描执行差分对拍，验证检索结果 ID 集合 100% 一致。

---

### 第四阶段：极端空间分布基准评测与 CLI 工具 (v0.4.0) — [已完成]

- **五类基准空间分布生成器**：
  1. 均匀随机分布（Uniform Distribution）：全域均匀散布。
  2. 高斯聚类分布（Clustered Gaussian）：多密集热点空间聚集。
  3. 对角线共线分布（Diagonal Degenerate）：最差切片划分场景。
  4. 同心嵌套分布（Nested Concentric）：极端深度嵌套包围盒。
  5. 网格规则平铺（Regular Grid Tile）：标准 GIS 瓦片特征。
- **性能基准评估体系 (`benchmarks/`)**：
  - 测算 $10^3, 10^4, 10^5, 10^6$ 数据量下的构建耗时（ms）与吞吐量（items/sec）。
  - 测算不同选择率（0.01%、0.1%、1%、10%）下的单次检索耗时分布（P50、P95、P99）。
- **命令行诊断套件 (`cmd/main`)**：
  - 提供数据加载、树深度直方图分析与基准耗时终端表格输出。

---

### 第五阶段：WebAssembly 交互式可视化演练场 (v0.5.0) — [已完成]

- **Wasm 渲染管线**：
  - 编译为原生 WebAssembly 模块，通过轻量级 JS 桥接 HTML5 Canvas。
  - 内存无拷贝传递视口包围盒与查询结果集。
- **交互功能**：
  - 实时绘制全树分层 MBR 轮廓线（根据节点层级映射差异化色彩与透明度）。
  - 支持鼠标拖拽动态查询矩形，毫秒级高亮碰撞图元并实时显示吞吐帧率（60 FPS）。

---

### 第六阶段：高维空间扩展与复杂拓扑算子 (v1.0.0+) — [进行中]

- **K 最近邻检索 (k-NN Query) — [已完成]**：
  - 基于欧几里得距离与 MinDist 优先队列分支限界检索，支持快速查找距离目标点最近的 $k$ 个图元。
- **K 最近邻带距离度量检索 (k-NN with Distances) — [已完成]**：
  - 实现 `query_knn_with_distance`，结合分支限界优先队列同时返回按升序排列的 `(item_id, squared_distance)` 结果对，免除二次距离运算。
- **K 最近邻谓词过滤检索 (k-NN with Predicate) — [已完成]**：
  - 实现 `query_knn_with_predicate` 与 `query_knn_with_predicate_and_distance`，在分支限界遍历期同步过滤业务谓词。
- **线段光线投射检索 (Ray-Casting) — [已完成]**：
  - 基于 Liang-Barsky 轴向裁剪算法，实现线段遍历与相交图元筛选。
- **双树空间连接 (Spatial Join) — [已完成]**：
  - 基于两棵 STR 空间树的同步深度优先遍历，实现大规模几何集合之间的高性能批量相交碰撞粗检。
- **高级矩形拓扑与几何度量 (Rect Topology & Metrics) — [已完成]**：
  - 支持矩形交集 (`intersection`)、四向边界缓冲扩展 (`expand`)、两矩形欧式间距 (`distance_to_rect`) 及交并比 (`iou`) 运算。
- **零分配空间计数与短路谓词检索 (Zero-Alloc Counting & Predicates) — [已完成]**：
  - 支持零堆分配图元计数 (`query_count`, `query_point_count`) 与提前终止首项检索 (`query_first`) 及闭包过滤 (`query_with_predicate`)。
- **圆形与距离半径范围检索 (Circle Range Query) — [已完成]**：
  - 基于欧氏平方距离几何剪枝，实现圆形范围相交过滤 (`query_circle`) 及零分配半径计数 (`query_circle_count`)。
- **三维空间包围盒基础图元与算子 (3D AABB Box3D) — [已完成]**：
  - 实现三维包围盒 `Box3D`，支持体积、表面积、三向正交分离轴相交、三维点包含、并集、六向缓冲外扩、盒间距离、体积交并比 (`iou`) 与球盒相交判定 (`intersects_sphere`)。
- **三维空间合成分布生成器 (3D Synthetic Generators) — [已完成]**：
  - 实现三维均匀随机包围盒 (`generate_boxes_3d_uniform`) 与三维多聚类高斯包围盒 (`generate_boxes_3d_clustered`) 分布生成器。
- **三维 STR 空间索引构建与遍历 (3D STRtree Bulk-Loading) — [已完成]**：
  - 将双向切片算法推广为 3D 三向递归切片（$S_x = \lceil P^{1/3} \rceil$、$S_y = \lceil \sqrt{P_x} \rceil$），实现 `StrTree3D` 紧凑连续原生数组打包构建、包围盒相交检索 (`query`)、零分配计数 (`query_count`)、三维点包含 (`query_point`) 及球体范围检索 (`query_sphere`)。
- **三维空间 K 最近邻与光线相交检索 (3D k-NN & Ray-Tracing) — [已完成]**：
  - 将分支限界（MinDist 优先队列与堆剪枝）与 Liang-Barsky 轴向参数裁剪推广至三维欧几里得空间，支持空间体元与光线相交检索 (`query_segment`)、3D k-NN 检索 (`query_knn`, `query_knn_with_distance`)、带谓词过滤检索 (`query_knn_with_predicate`) 以及零堆分配计数 (`query_point_count`, `query_sphere_count`)。
- **三维双树空间连接与原生持久化序列化 (3D Dual-Tree Spatial Join & FlatBuffers3D) — [已完成]**：
  - 将双树同步深度优先遍历推广至三维体元层次包围盒（`StrTree3D::spatial_join`），实现早停检索（`query_first`）、带谓词过滤（`query_with_predicate`）与 3D 扁平原生数组序列化快照（`FlatBuffers3D`）。
- **三维三角面片几何与网格空间索引 (3D Triangle & Mesh Indexing) — [已完成]**：
  - 实现连续三维三角面片基元 `Triangle3D`、法向与重心计算、欧氏面积、Möller–Trumbore 精确光线求交与线段穿透测试。
  - 构建三角网格空间索引 `StrMeshTree3D`，支持包围盒筛选、线段穿透多边形判定、首个光线命中点加速与多交点按距离排序遍历。
- **高维多模态几何与时空四维包围体扩展 (4D Spatiotemporal Bounds & StrTree4D) — [已完成]**：
  - 实现四维时空轴对齐超包围体 `Box4D`、四维超体积度量、四向缓冲外扩、瞬时相交判定与四维时空点包含。
  - 实现四向递归级联切片批量构建索引 `StrTree4D`，支持四维范围检索、零分配超体积计数与瞬时时间切片剖面截面检索 (`query_time_slice`)。
- **自适应空间连接与高阶拓扑谓词管线 (Adaptive Spatial Joins & DE-9IM) — [已完成]**：
  - 实现维度扩展九交模型（Dimensionally Extended 9-Intersection Model, DE-9IM）拓扑矩阵生成（`Rect::relate`）与通配符模式匹配（`matches_de9im_pattern`）。
  - 支持 OGC 标准命名的 9 种空间拓扑谓词（`Intersects`, `Contains`, `Within`, `Touches`, `Overlaps`, `Disjoint`, `Equals`, `Covers`, `CoveredBy`）。
  - 实现基于拓扑谓词剪枝的条件索引检索（`StrTree::query_spatial_predicate`）与自适应双树层次空间连接（`StrTree::spatial_join_predicate`）。
- **多源异构空间几何聚合与流式热力分析 (Spatial Clustering & Streaming Hotspots) — [已完成]**：
  - 实现基于空间树圆形/球体剪枝加速的 2D 与 3D DBSCAN 密度聚类算法（`StrTree::dbscan`, `StrTree3D::dbscan`），将时间复杂度从 $O(N^2)$ 降低至 $O(N \log N)$。
  - 实现等距二维空间网格热力图聚合分析与热点单元格识别排序（`StrTree::aggregate_grid`），输出包含峰值密度与均值指标的 `GridDensitySummary`。
- **地理围栏流式事件监听与滑动窗口轨迹检索 (Geofencing & Trajectory Window Index) — [已完成]**：
  - 实现基于空间索引的移动实体地理围栏状态转移监听器 `GeofenceMonitor`，支持离散状态机转换追踪（`Enter`, `Exit`, `Stay`）与实体注销事件派发。
  - 实现时空动态航迹线段与时空滑动窗口索引 `TrajectoryWindowIndex`，支持线段时长/速度/瞬时插值、时空范围滑动过滤（`query_window`）与穿越轨迹识别（`query_tracks_in_window`）。
- **动态时空航迹拓扑压缩与道格拉斯-普克滤波 (Trajectory Simplification & Compression) — [规划中]**：
  - 探索空间航迹自适应道格拉斯-普克（Douglas-Peucker）拓扑无损简化、时空误差容限边界与流式采样压缩。





