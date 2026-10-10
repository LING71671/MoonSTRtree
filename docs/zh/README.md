<p align="center">
  <img src="../banner.jpg" alt="MoonSTRtree: 针对 MoonBit 的高性能紧凑型二维空间索引库" width="960" />
</p>

<p align="center">
  <img alt="版本 0.1.0" src="https://img.shields.io/badge/版本-0.1.0-334155?style=flat-square" />
  <img alt="核心算法 STR" src="https://img.shields.io/badge/算法-STR_批量打包-334155?style=flat-square" />
  <img alt="目标平台 WASM JS Native" src="https://img.shields.io/badge/目标平台-WASM_%7C_JS_%7C_Native-334155?style=flat-square" />
  <a href="../../LICENSE"><img alt="协议 Apache 2.0" src="https://img.shields.io/badge/协议-Apache_2.0-334155?style=flat-square" /></a>
  <img alt="MoonBit 2026 黑客松" src="https://img.shields.io/badge/MoonBit-2026_Hackathon-000000?style=flat-square" />
</p>

<p align="center">
  专为 MoonBit 生态设计的高性能紧凑型静态二维空间索引库，核心采用 Sort-Tile-Recursive（STR）批量构建算法。
</p>

<p align="center">
  <a href="../../README.md"><strong>English Version</strong></a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="SPEC.md">技术规范</a> ·
  <a href="ROADMAP.md">路线图</a> ·
  <a href="API_SPECIFICATION.md">接口规范</a> ·
  <a href="ARCHITECTURE.md">架构设计</a>
</p>

---

## 概述

MoonSTRtree 是专为 MoonBit 生态设计的静态二维空间索引库。核心采用 **Sort-Tile-Recursive（STR）** 批量构建算法，将大量空间包围盒组织为紧凑、高效的分层空间索引。

当应用需要在数万至数十万个空间对象（碰撞盒、视口图元、地理要素）中检索某一矩形区域内的对象时，暴力线性扫描面临 O(N) 的沉重开销。MoonSTRtree 将数据一次性打包为连续扁平数组，通过空间剪枝跳过不相交子树，以极小的内存占用实现 O(log_M N) 毫秒级范围查询。

## 核心特性

- **真实 STR 批量打包**：沿 X 轴排序切片、切片内沿 Y 轴排序分组，空间节点利用率达到 100%，外包矩形重叠极小。
- **连续扁平内存布局**：多层节点存储于连续基础类型数组中，消除散列指针与堆分配，杜绝 GC 抖动，原生优化 WASM、JS 与 Native。
- **高效范围与点查询**：支持高精度 AABB 矩形相交检索与点包含判定，查询过程基于固定容量迭代栈，避免深层递归溢出。
- **全场景边界安全**：严格处理空数据集、重复矩形、退化点线、负坐标及极端输入，结果与全量暴力扫描严格一致。
- **只读并发安全**：构建后保持只读不可变，确定性构建保证相同输入产生完全一致的索引结构。


---

## 选择你的接入方式

**核心算法库** — 直接作为 MoonBit 模块引入，供 2D 物理碰撞检测、视口图元拣选与空间数据管线调用。

**WebAssembly 画布演练场** — 编译为 WebAssembly 嵌入浏览器交互页面，支持鼠标实时拖拽查询视口、高亮相交图元并可视化分层 MBR 边界。

**CLI 命令行与基准评测** — 快速对空间索引执行构建耗时与查询延迟 Benchmark，涵盖 1k、10k 与 100k 规模下的均匀、聚集与退化分布。

```powershell
# 运行内置 CLI 演示程序
moon run cmd/main

# 启动 WebAssembly / Canvas 交互式演练场
cd playground
pnpm dev
```

---

## 快速开始

### 1. 声明依赖

在项目 `moon.mod` 中声明：

```moonbit
import {
  "LING71671/moon_strtree" @lib,
}
```

### 2. 构造空间包围盒

```moonbit
// Rect::new 自动归一化坐标 (min_x, min_y, max_x, max_y)
let items : Array[(@moon_strtree.Rect, Int)] = [
  (@moon_strtree.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
  (@moon_strtree.Rect::new(5.0, 5.0, 15.0, 15.0), 102),
  (@moon_strtree.Rect::new(100.0, 100.0, 110.0, 110.0), 103),
]
```

### 3. 批量构建 STR 空间索引

```moonbit
// 指定节点容量批量构建 STR 紧凑树 (默认容量 M = 16)
let tree = @moon_strtree.StrTree::build(items, node_capacity=16)
```

### 4. 矩形范围相交检索

```moonbit
let search_window = @moon_strtree.Rect::new(2.0, 2.0, 6.0, 6.0)
let matches : Array[Int] = tree.query(search_window)
// matches == [101, 102]
```

### 5. 点包含判定与结构诊断

```moonbit
// 点查询
let point_matches : Array[Int] = tree.query_point(1.0, 1.0)
// point_matches == [101]

// 结构指标诊断
let stats = tree.stats()
println("树高: \{stats.height}, 总节点数: \{stats.num_nodes}")
```

### 6. 分支限界 K 最近邻检索 (k-NN)

```moonbit nocheck
// 基于 MinDist 优先队列快速检索距离目标点最近的 2 个图元
let knn_items : Array[Int] = tree.query_knn(0.0, 0.0, 2)
// knn_items == [101, 102]
```

### 7. 光线投射与线段相交 (Ray-Casting)

```moonbit nocheck
// 检索与线段 (x1, y1) -> (x2, y2) 相交的所有包围盒
let ray_hits : Array[Int] = tree.query_segment(0.0, 0.0, 12.0, 12.0)
```

### 8. 双树分层空间连接 (Spatial Join)

```moonbit nocheck
// 同步深度优先遍历两棵 STR 空间树，查找重叠相交图元对
let overlapping_pairs : Array[(Int, Int)] = tree_a.spatial_join(tree_b)
```

### 9. FlatBuffers 连续原生数组序列化

```moonbit nocheck
// 导出底层连续原生数组，支持零拷贝持久化或跨 Wasm 内存边界恢复
let buffers = tree.to_flat_buffers()
let reloaded_tree = @moon_strtree.StrTree::from_flat_buffers(buffers)
```

### 10. 三维空间索引与体元检索 (`StrTree3D`)

```moonbit
// 从 (Box3D, ID) 元组批量构建三维紧凑 STR 空间索引
let items_3d : Array[(@moon_strtree.Box3D, Int)] = [
  (@moon_strtree.Box3D::new(0.0, 0.0, 0.0, 10.0, 10.0, 10.0), 1),
  (@moon_strtree.Box3D::new(15.0, 15.0, 15.0, 25.0, 25.0, 25.0), 2),
]
let tree_3d = @moon_strtree.StrTree3D::build(items_3d, node_capacity=16)

// 三维包围盒与球体相交检索
let box_hits = tree_3d.query(@moon_strtree.Box3D::new(5.0, 5.0, 5.0, 12.0, 12.0, 12.0))
let sphere_hits = tree_3d.query_sphere(0.0, 0.0, 0.0, 15.0)

// 三维 k-NN 与空间光线求交
let knn_3d = tree_3d.query_knn(0.0, 0.0, 0.0, 5)
let ray_hits_3d = tree_3d.query_segment(0.0, 0.0, 0.0, 20.0, 20.0, 20.0)

// 三维双树空间连接与 FlatBuffers3D 序列化
let pairs_3d = tree_3d.spatial_join(tree_3d)
let buffers_3d = tree_3d.to_flat_buffers()
let reloaded_3d = @moon_strtree.StrTree3D::from_flat_buffers(buffers_3d)
```

### 11. 三维三角面片与网格空间索引 (`StrMeshTree3D`)

```moonbit
// 构造三维三角面片并批量打包进入层次网格空间索引
let tri_a = @moon_strtree.Triangle3D::new(
  0.0, 0.0, 5.0, 10.0, 0.0, 5.0, 0.0, 10.0, 5.0,
)
let mesh = @moon_strtree.StrMeshTree3D::build([tri_a], node_capacity=16)

// 两阶段加速光线投射求交（首个命中面片及距离参数 t）
let closest_hit = mesh.query_first_ray_hit(2.0, 2.0, 0.0, 0.0, 0.0, 1.0)
```

### 12. 四维时空超包围体与连续轨迹索引 (`StrTree4D`)

```moonbit
// 构造四维时空超长方体 (x, y, z, t) 并批量打包四维空间索引
let moving_box = @moon_strtree.Box4D::new(
  0.0, 0.0, 0.0, 0.0, 10.0, 10.0, 10.0, 5.0,
)
let tree_4d = @moon_strtree.StrTree4D::build([(moving_box, 1)], node_capacity=16)

// 瞬时时间断面截面检索 (时间 t=2.5 时处于三维目标区域的所有对象)
let time_hits = tree_4d.query_time_slice(
  2.5,
  @moon_strtree.Box3D::new(0.0, 0.0, 0.0, 10.0, 10.0, 10.0),
)

// 13. DE-9IM 拓扑相交矩阵与谓词空间连接
let r_a = @moon_strtree.Rect::new(0.0, 0.0, 10.0, 10.0)
let r_b = @moon_strtree.Rect::new(10.0, 0.0, 20.0, 10.0)
let de9im_matrix = r_a.relate(r_b) // "FF2F11212" (边相贴接触)

// 拓扑谓词条件检索 (如 Touches, Overlaps, Contains 等)
let touch_matches = tree.query_spatial_predicate(
  r_b,
  @moon_strtree.SpatialPredicate::Touches,
)

// 双树自适应拓扑空间连接
let join_pairs = tree.spatial_join_predicate(
  tree,
  @moon_strtree.SpatialPredicate::Overlaps,
)

// 14. 空间索引加速 DBSCAN 聚类与网格热点聚合
let clusters = tree.dbscan(eps=15.0, min_pts=2)
let grid_summary = tree.aggregate_grid(10.0, 10.0)

// 15. 流式地理围栏监听与时空轨迹滑动窗口
let geofence_monitor = @moon_strtree.GeofenceMonitor::new([
  (@moon_strtree.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
])
let events = geofence_monitor.update_point(42, 5.0, 5.0)

let waypoints = [
  @moon_strtree.TrajectoryPoint::new(0.0, 0.0, 0.0, 1),
  @moon_strtree.TrajectoryPoint::new(10.0, 10.0, 10.0, 1),
]
let segments = @moon_strtree.TrajectoryWindowIndex::segments_from_points(waypoints)
let traj_index = @moon_strtree.TrajectoryWindowIndex::build(segments)
let active_tracks = traj_index.query_tracks_in_window(
  @moon_strtree.Rect::new(0.0, 0.0, 5.0, 5.0),
  0.0,
  5.0,
)
```




---

## 设计哲学与技术原则

1. **真实 STR 批量打包，非动态 R 树**：针对只读批量检索场景，STR 启发式算法通过一次性空间排序与切片构建最优拓扑，消除动态逐条插入导致的节点频繁分裂与填充率低下的问题。
2. **扁平连续数组，非散列对象图**：所有节点坐标与索引均在扁平连续数组中紧凑排布。查询使用固定深度整数迭代栈，杜绝深层递归调用栈溢出风险与垃圾回收开销。
3. **明确非目标**：MoonSTRtree 是专注于二维矩形空间相交的高性能基础算法库。本项目不是全功能 GIS 空间数据库、坐标投影转换库、动态 R*-树或三维图形引擎。

---

## 文档与技术索引

| 文档名称 | 对应英文文档 | 说明 |
| :--- | :--- | :--- |
| [形式化技术规范](SPEC.md) | [SPEC.md](../en/SPEC.md) | 几何数学模型、STR 算法形式化与复杂度上界 |
| [项目路线图](ROADMAP.md) | [ROADMAP.md](../en/ROADMAP.md) | 阶段里程碑交付、测试验收标准与演进规划 |
| [架构设计](ARCHITECTURE.md) | [ARCHITECTURE.md](../en/ARCHITECTURE.md) | STR 切片数学原理、扁平连续数组布局与查询剪枝实现 |
| [接口规范](API_SPECIFICATION.md) | [API_SPECIFICATION.md](../en/API_SPECIFICATION.md) | 几何基元、树结构、公共方法与复杂度保证 |
| [开发规范](DEVELOPMENT.md) | [DEVELOPMENT.md](../en/DEVELOPMENT.md) | 低耦合分层架构、零 GC 遍历约束与提交路线图 |
| [产品规格](PRODUCT.md) | [PRODUCT.md](../en/PRODUCT.md) | 功能范围、测试基准标准与非目标说明 |


---

<details>
<summary><strong>从源码构建与测试</strong></summary>

需要安装 MoonBit 编译器工具链 (`moon`)。

```powershell
# 语法与类型检查
moon check

# 运行单元测试与白盒测试
moon test

# 代码格式化
moon fmt

# 运行命令行演示
moon run cmd/main
```

所有核心算法均在纯 MoonBit 中实现，编译输出的 WebAssembly 无需外部运行时依赖。

</details>

---

## 开源协议

基于 [Apache License, Version 2.0](../../LICENSE) 开源发布。
