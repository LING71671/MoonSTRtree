# MoonBit 空间索引直接对照

[English](README.md) | [中文](README.zh.md)

该独立模块用同一套 MoonBit 工具链，将当前本地 MoonSTRtree 与固定 `totto2727/geo@0.1.3` 编译成同一份 JavaScript 发布产物。`moon.work` 从仓库解析 MoonSTRtree，没有使用较旧注册表版本。主库不依赖 geo，`/playground/` 不进入注册表发布包。

使用 moonc 0.10.18 或更新版本、Node、Bun 和 pnpm，在 `playground` 执行：

```powershell
moon update
pnpm benchmark:data
pnpm benchmark:geo --profile=diagnostic --output=.bench/reports/geo-diagnostic-new.ndjson
pnpm benchmark:geo --profile=standard --output=.bench/reports/geo-standard-new.ndjson
pnpm benchmark:geo:publish --input=.bench/reports/geo-standard-new.ndjson --output=../docs/evidence/geo-standard-new.json
```

每次使用新文件名。发布工具拒绝缺失矩阵、重复场景、不正确中位数、未固定的公开数据和为未支持项编造的分数；重新生成输入与查询，核对几何哈希及实际查询参数，保存全部原始观察的 gzip 副本。

## 测量协议

- 双方容量都是 16，与 geo 固定的最大节点条目数一致。标准配置声明 4,640 场景：十种合成分布与两种极端分布的 1,000／10,000／100,000 对象、种子 0／42／2026，两份公开数据的三个种子，以及空树和单对象。每份输入使用已有 38 种查询及新增两个边界接触查询。诊断配置为 640 场景，不作为最终成绩。
- 构建包含从相同扁平坐标输入到各库自身数据结构的适配，一次预热与九轮轮换样本。查询均使用自行返回结果数组的常规接口，没有让 MoonSTRtree 复用结果缓冲区而强迫对方分配新结果。
- 标准查询预热 16 次，轮换测量九批，各实现校准至约五毫秒批次。协议与网站四实现基准分别记录；单次慢查询可以超过批次目标。
- geo 在 k=1 时调用专用 `query_nearest`，其他 k 调用原生 `nearest_neighbors`。计时前后核对完整、有序平方距离序列，等距编号允许不同；其他查询核对全部编号集合，拒绝重复或越界编号。k 不大于零和超过输入数量的原生行为由集成测试检查，不用无需返回近邻的请求抬高速度分数。
- 线段查询测量 MoonSTRtree，对本桥接中的 geo 明确保留为未支持且不计分。速度比只使用共同有效场景，所有选中／未支持／错误数量及更慢场景均保留。每份输入的构建只计一次，不按查询重复计权。

## 结果范围

明确覆盖相同包围盒、嵌套包围盒、全命中、零命中、接触边界、空树和等距近邻。这不证明零分配、零 GC、固定耗时或内存上界。公开经纬度按平面角度处理，不解释为地表距离。

这是二维 JavaScript 直接对照，不代表 Native、Wasm、三维／四维或内存性能。不同算法和接口约定分别说明，不据此宣称普遍领先。网站原四实现完整报告继续保留独立源码快照。

注册表依赖声明采用 MIT 许可证，版权为 2026 totto2727。下载包中的许可证随本地依赖保留。仓库不内置或分发该依赖源码及编译后的对照产物；单独分发产物时应保留依赖声明。
