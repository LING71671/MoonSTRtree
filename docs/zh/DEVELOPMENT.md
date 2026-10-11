# 开发指南

[English](../en/DEVELOPMENT.md) | [中文](DEVELOPMENT.md)

## 构建检查

从仓库根目录运行 `just verify`。没有 just 时逐项执行：

```powershell
moon info
moon fmt
moon check
moon test --target wasm
moon test --target wasm-gc
moon test --target js
```

`moon info` 更新生成接口；迁移类型或新增方法后应检查接口差异，不能手改 `.mbti`。`moon fmt` 统一格式。此次重构保留根包名称，但改变类型归属与内部导入路径。

## Windows Native

Windows Native 需要兼容 MSVC 的编译器和 Windows SDK，不能以 MinGW 替代。进入具有 C++ 头文件和库路径的 Visual Studio 开发者 PowerShell，再执行 `moon test --target native`。

本机较新的 Visual Studio 工具集缺少 include 目录；验证在进程内使用既有 BuildTools 14.44 头文件与库。未更改系统环境或安装 SDK。若提示缺少 `vcruntime.h`，先检查实际选中的工具集，详情见[验证记录](VALIDATION.md)。

## 按职责修改

| 修改内容 | 位置 |
| --- | --- |
| 公开适配 | `src/api/` |
| 几何与谓词 | `src/core/geometry/` |
| STR 排序与整数算术 | `src/core/packing/` |
| 存储、遍历、近邻、连接 | `src/core/index/` 对应文件 |
| 围栏、多边形、轨迹 | `src/extensions/` 对应包 |
| 公开兼容性回归 | `tests/api/` |

依赖向下，根文件只转导出公开名称。保留 `///|` 分块。修复问题时添加旧实现会失败的测试；数值运算覆盖极大/极小尺度、空输入与闭合边界。公开回归从根包导入，包内白盒测试检查存储不变量。十万条固定数据与多种容量的结果会与完整线性扫描比较；测试通过只证明已测情况。

## 演示与诊断

```powershell
cd playground
pnpm install
pnpm dev
pnpm test
pnpm build
```

`pnpm engine` 编译仅支持 JS 的 `src/bridge/browser` 包，把导出与编译器信息复制到忽略的 `src/.generated`。开发和构建命令都会运行这一步。`pnpm test` 通过 Bun 执行真实适配器集成测试；浏览器操作验证使用 Playwright。界面、Worker、数据生成、参考几何和竞品适配器分别组织在 `playground/src`。查询变化会使旧测量失效；配置修改需要显式重建。

`moon run cmd/main` 输出诊断样例，不收集计时。浏览器比较使用真实 MoonBit 编译代码及真实竞品，同一有种子的输入、预热、重复测量与完整结果验证。声称性能优势前，应导出原始测量与环境信息。

## 网站语言

完整网站文案分别位于 `playground/src/i18n/en.ts` 和 `zh.ts`，中文词典通过 TypeScript 类型约束与英文结构一致。`LocaleProvider` 负责默认中文、本地保存、文档语言/标题/描述及数字格式。查询和实测状态独立于语言，切换不会重建实验。实现名称与导出 JSON 字段保持稳定，界面查询方式和状态会翻译。英文自托管 Barlow Condensed 与 Manrope，中文自托管 Noto Sans SC。

## 文档维护

中英文分别成文件并互链。`README.md` 是模块入口，`PRODUCT.md` 保存产品事实；架构说明依赖与所有权，API 说明行为，验证记录保存实测证据，路线图仅列未来工作。不要把目标延迟、载荷估算或计划能力当作测量结论。

## 编译器要求

使用 moonc 0.10.14 或更高版本，以 `moonc -v` 核对。网页构建脚本强制检查最低版本。根目录可放置被 Git 忽略的 `.moon-toolchain.json`，内容为 `{ "home": "<独立 SDK 根目录>" }`，也可设置 MOON_HOME；CI 直接使用 PATH 中安装的 SDK。实测导出保留编译器版本和源代码 SHA-256。

## 扩展 Benchmark

以下命令在 `playground` 中执行。每轮使用新的输出文件名，测量器拒绝覆盖已有证据。

```powershell
pnpm benchmark:data
pnpm benchmark --profile=standard --output=.bench/reports/standard.ndjson
pnpm benchmark:publish --input=.bench/reports/standard.ndjson --output=public/benchmarks/standard.json
```

标准矩阵包含 10,944 个场景：十类合成分布、1,000／10,000／100,000 对象，加上全部有效机场和跑道记录；组合容量 4／16／64、种子 0／42／2026 和 38 种查询。诊断配置含 456 个短场景，exhaustive 增加规模、种子与容量。`--datasets=public`、`synthetic` 或逗号分隔的数据集编号可选择子集，选择条件明确写入报告。

独立构建适配器允许轮换构建顺序，单个实现失败不会阻断其他实现。预热构建一次后保存九次构建样本。标准查询预热 64 次，校准目标三毫秒批次，测量九批并轮换顺序；计时前后均与完整参考核对。错误、结果不一致和未支持场景保留在报告中。头记录包含编译器、核心与测量器 SHA-256、源码提交、Node/V8 和设备信息；尾记录确认完成，或明确记录中断。

发布器先核对原始中位数、唯一场景编号和完整声明矩阵，再生成精简 JSON、SHA-256 清单及完整 NDJSON 的 gzip 副本。查询分数使用四套实现均正确的共同场景并等权计算，构建按输入／容量／种子去重计数；错误和未支持记录仍计入覆盖分母。5% 耗时比区间便于分类，不表示统计显著性。网页接近该区域时加载静态报告并核对哈希，切换语言保留筛选。测量时应避开其他重负载，保留计时限制说明。

## GitHub Pages

Pages 工作流构建通过 CI 的确切 main 提交并发布 `playground/dist`，Vite 使用适配仓库路径的相对资源地址。将 Pages 发布源设为 GitHub Actions；部署需要 `github-pages` 环境和对应权限。网站构建不重新下载 Benchmark 输入，展示提交的实测快照。CI 不在共享运行器上重新生成性能分数。
