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
