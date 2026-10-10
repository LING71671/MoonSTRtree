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
