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

在 playground 中运行 `pnpm benchmark:data` 获取固定版本公开输入，再运行 `pnpm benchmark --profile=diagnostic`。standard 与 exhaustive 覆盖更多组合，诊断轮必须标明是初步结果。
