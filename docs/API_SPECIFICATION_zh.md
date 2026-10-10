# MoonSTRtree 接口规范

[English](./API_SPECIFICATION.md) | [中文说明](./API_SPECIFICATION_zh.md)

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

### 1.6 `tree.stats`

计算并返回树结构诊断统计指标。

```moonbit
pub fn stats(self : StrTree) -> TreeStats
```

- **返回值**：`TreeStats` — 包含树高、总节点数、元素数与容量等指标。

---

## 2. 核心数据类型

### 2.1 `Rect`

```moonbit
pub struct Rect {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
} derive(Eq, Show)
```

#### 成员方法
- `intersects(self : Rect, other : Rect) -> Bool` — 判断当前矩形是否与目标矩形相交或边缘接触。
- `contains_point(self : Rect, x : Double, y : Double) -> Bool` — 闭区间点包含判定。
- `union(self : Rect, other : Rect) -> Rect` — 计算两矩形的最小外包矩形。
- `center_x(self : Rect) -> Double` — 中心点 X 坐标 `(min_x + max_x) / 2.0`。
- `center_y(self : Rect) -> Double` — 中心点 Y 坐标 `(min_y + max_y) / 2.0`。
- `is_valid(self : Rect) -> Bool` — 校验坐标是否均为有限数值（非 NaN、非无穷大）。

---

### 2.2 `StrTree`

```moonbit
pub struct StrTree {
  node_capacity : Int
  num_items : Int
  // 内部连续多层扁平缓存
}
```

---

### 2.3 `TreeStats`

```moonbit
pub struct TreeStats {
  num_items : Int
  num_nodes : Int
  height : Int
  node_capacity : Int
  fill_factor : Double
} derive(Eq, Show)
```
