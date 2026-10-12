# MoonSTRtree

<p align="center"><img src="../banner.jpg" alt="MoonSTRtree 空间索引" width="960" /></p>

<p align="center"><a href="../../LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-555?style=flat-square" alt="Apache-2.0 许可证" /></a></p>

<p align="center">MoonBit 静态空间索引：STR 批量构建二维、三维、四维包围盒索引，并提供几何和轨迹扩展。</p>

<p align="center"><a href="../../README.md">English</a> | <a href="README.md">中文</a> | <a href="https://ling71671.github.io/MoonSTRtree/">在线演示</a> | <a href="#快速使用">快速使用</a> | <a href="API_SPECIFICATION.md">接口</a> | <a href="ARCHITECTURE.md">架构</a></p>

需要 **moonc 0.10.14 或更新版本**；请用 `moonc -v` 检查编译器版本。

## 快速使用

```powershell
git clone https://github.com/LING71671/MoonSTRtree.git
cd MoonSTRtree
moon check
moon run cmd/main --target js
```

以上命令直接验证当前源码检查点，无需等待注册表发布；可运行 CLI 使用同一包。应用配置模块依赖后，可在 `moon.pkg` 使用以下包别名：

```text
import {
  "LING71671/moon_strtree" @spatial,
}
```

```moonbit
let items = [
  (@spatial.Rect::new(0.0, 0.0, 10.0, 10.0), 101),
  (@spatial.Rect::new(20.0, 20.0, 30.0, 30.0), 102),
]
let tree = @spatial.StrTree::build(items, node_capacity=16)
let hits = tree.query(@spatial.Rect::new(5.0, 5.0, 15.0, 15.0))
```

命中包含 ID 101；接触边界也计为相交。ID 必须非负，坐标必须有限。树构建后只读，需要修改数据时重新构建。查询结果顺序及等距近邻的选择顺序不作保证。

## 能力与边界

| 领域 | 已实现 |
| --- | --- |
| 索引 | 二维、三维、四维 STR 构建、范围和点查询 |
| 二维/三维查询 | 计数、首个命中、过滤、近邻、圆/球、线段、空间连接 |
| 几何 | 包围盒空间谓词、三角网格射线查询、多边形计算与裁剪 |
| 分析 | 中心点 DBSCAN、网格密度、地理围栏事件 |
| 轨迹 | 时间窗口候选、简化、流式压缩、DTW、离散 Frechet 距离 |
| 存储 | 数组独立复制、二维/三维可选安全恢复 |

`query_into` 可复用调用者持有的结果和遍历缓冲区。计数查询不分配结果数组，但会分配遍历栈。存储导入/导出会复制数组，不是零拷贝协议，也不是二进制 FlatBuffers 格式。高重叠数据可能需要遍历全部对象，不保证始终对数复杂度。

## 开发与验证

```powershell
moon check
moon test
moon test --target js
moon test --target wasm-gc
moon info
moon fmt
moon run cmd/main
```

CLI 输出诊断样例，不测量基准耗时。浏览器演示的独立启动方式见[开发指南](DEVELOPMENT.md)。

实现分为 `src/api`、`src/core`、`src/extensions`、`src/support`；公开兼容性与回归测试位于 `tests/api`。根包入口继续提供原有 API，类型定义归属改为 `src/api`。直接导入旧内部路径的代码需要迁移。

[验证记录](VALIDATION.md)提供实际检查证据，[路线图](ROADMAP.md)区分已实现能力与后续工作。项目不声明始终快于竞品。

Apache-2.0，见 [LICENSE](../../LICENSE)。

## 开发者与 Agent 导航

| 文档 | 用途 |
| --- | --- |
| [架构](ARCHITECTURE.md) | 包依赖与源码职责 |
| [接口](API_SPECIFICATION.md) | 查询与存储行为 |
| [开发](DEVELOPMENT.md) | 命令与工具链配置 |
| [验证](VALIDATION.md) | 实际测试与原始测量 |
| [规范](SPEC.md) | 行为不变量 |

## 持续集成与许可证

[CI](../../.github/workflows/ci.yml)覆盖四个编译目标的检查、构建、测试以及 CLI 示例，并验证网页集成测试和生产构建。三维/四维区展示高度和时间片查询，完整结果可导出；它不冒充多维性能实测。展示页包含运行时依赖和字体许可声明，本检查点不处理 mooncakes 发布。

[双语在线演示](https://ling71671.github.io/MoonSTRtree/)运行真实二维／三维／四维查询，并展示完整 10,944 场景标准 Benchmark 和原始样本。查询、构建、覆盖范围及更慢场景均保留；当前结果不证明整体超过 Flatbush。[验证记录](VALIDATION.md)保留源码快照和部署检查。
