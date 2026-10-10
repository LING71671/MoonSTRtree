<p align="center">
  <img src="banner.jpg" alt="MoonSTRtree: 针对 MoonBit 的高性能紧凑型二维空间索引库" width="960" />
</p>

<p align="center">
  <img alt="版本 0.1.0" src="https://img.shields.io/badge/版本-0.1.0-334155?style=flat-square" />
  <img alt="核心算法 STR" src="https://img.shields.io/badge/算法-STR_批量打包-334155?style=flat-square" />
  <img alt="目标平台 WASM JS Native" src="https://img.shields.io/badge/目标平台-WASM_%7C_JS_%7C_Native-334155?style=flat-square" />
  <a href="../LICENSE"><img alt="协议 Apache 2.0" src="https://img.shields.io/badge/协议-Apache_2.0-334155?style=flat-square" /></a>
  <img alt="MoonBit 2026 黑客松" src="https://img.shields.io/badge/MoonBit-2026_Hackathon-000000?style=flat-square" />
</p>

<p align="center">
  专为 MoonBit 生态设计的高性能紧凑型静态二维空间索引库，核心采用 Sort-Tile-Recursive（STR）批量构建算法。
</p>

<p align="center">
  <a href="../README.md"><strong>English Version</strong></a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="API_SPECIFICATION_zh.md">接口规范</a> ·
  <a href="ARCHITECTURE_zh.md">架构设计</a> ·
  <a href="PRODUCT_zh.md">产品规格</a>
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

---

## 设计哲学与技术原则

1. **真实 STR 批量打包，非动态 R 树**：针对只读批量检索场景，STR 启发式算法通过一次性空间排序与切片构建最优拓扑，消除动态逐条插入导致的节点频繁分裂与填充率低下的问题。
2. **扁平连续数组，非散列对象图**：所有节点坐标与索引均在扁平连续数组中紧凑排布。查询使用固定深度整数迭代栈，杜绝深层递归调用栈溢出风险与垃圾回收开销。
3. **明确非目标**：MoonSTRtree 是专注于二维矩形空间相交的高性能基础算法库。本项目不是全功能 GIS 空间数据库、坐标投影转换库、动态 R*-树或三维图形引擎。

---

## 文档与技术索引

| 文档名称 | 对应英文文档 | 说明 |
| :--- | :--- | :--- |
| [架构设计](ARCHITECTURE_zh.md) | [ARCHITECTURE.md](ARCHITECTURE.md) | STR 切片数学原理、扁平连续数组布局与查询剪枝实现 |
| [接口规范](API_SPECIFICATION_zh.md) | [API_SPECIFICATION.md](API_SPECIFICATION.md) | 几何基元、树结构、公共方法与复杂度保证 |
| [产品规格](PRODUCT_zh.md) | [PRODUCT.md](PRODUCT.md) | 功能范围、测试基准标准与非目标说明 |

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

基于 [Apache License, Version 2.0](../LICENSE) 开源发布。
