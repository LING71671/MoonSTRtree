# 接口参考

[English](../en/API_SPECIFICATION.md) | [中文](API_SPECIFICATION.md)

在 `moon.pkg` 导入 `LING71671/moon_strtree`。根包转导出调用者接口，索引适配位于 `src/api`，规范几何类型从 `src/core/geometry` 转导出。[接口定义](../../src/api/pkg.generated.mbti)及[几何定义](../../src/core/geometry/pkg.generated.mbti)提供签名；本页说明行为和边界，避免重复维护所有声明。

## 几何与构建

| 接口 | 约定 |
| --- | --- |
| `Rect::new`、`Box3D::new`、`Box4D::new` | 各维度反向边界会归一化，区间闭合 |
| `StrTree::build(items, node_capacity=16)` | 静态二维 `(Rect, Int)` 索引，容量最小为 2 |
| `StrTree::build_coordinates` | 连续的 `[minX,minY,maxX,maxY]` 记录，长度须为 4 的倍数；边界归一化，编号为输入位置 |
| `StrTree3D::build`、`StrTree4D::build` | 三维与四维时空索引 |
| `stats()` | 数量、树高、分支槽填充率与数值载荷估算 |

输入坐标须有限，ID 须非负。普通查询保留重复 ID；ID 是业务标识而非输入位置。极端尺度仍受浮点溢出和精度限制。支持空输入、退化点/线/盒。除显式复用接口外，结果数组由本次调用独立持有。

## 查询

| 方法 | 维度 | 行为 |
| --- | --- | --- |
| `query`、`query_point`、`query_count` | 二维/三维/四维 | 包围盒范围、点、计数，包含接触边界 |
| `query_point_count`、`query_first`、`query_with_predicate` | 二维/三维 | 点计数、首个过滤命中、全部过滤命中 |
| `query_circle` / `query_sphere` 及计数 | 二维/三维 | 圆/球与包围盒相交，负半径无命中 |
| `query_knn` 及带距离/过滤变体 | 二维/三维 | 到包围盒最小距离的前 k 个候选；返回距离时是平方距离 |
| `query_segment` | 二维/三维 | 有限线段与包围盒相交，不是无限射线 |
| `spatial_join` | 二维/三维 | 所有相交叶 ID 对；自连接含自身和对称项 |
| 空间谓词查询与连接 | 二维 | 对矩形求命名谓词，不是任意多边形的完整 DE-9IM |
| `query_time_slice` | 四维 | 三维空间盒限制到一个时刻 |

输出不保证顺序，等距近邻不保证固定选择。k <= 0 时为空，k 超过对象数时返回全部允许对象。过滤拒绝的对象不占 k。计数不分配结果数组，但仍分配遍历栈。

## 缓冲复用与恢复

`StrTree::query_into(window, results, scratch)` 每次先清空两个数组，包括空树与不相交情况。数组必须彼此独立且由本次查询独占；并发查询不能共用临时空间。复用减少数组创建，但容量增长仍可能分配；规范几何别名不再创建每次查询的适配对象。

`to_flat_buffers` 与 `from_flat_buffers` 复制数组，后者用于可信数据；二维可能验证拓扑以恢复布局提示，但不代表验证了有限坐标或父子包围关系。这里的缓冲类型不是第三方 FlatBuffers 二进制协议。

二维/三维的 `from_flat_buffers_checked` 校验长度、偏移、子节点索引、容量、连通无环根、对象数、树高、有限坐标和父子包围关系；损坏数据返回 `None`。三维还检查节点总数与层级数组长度。二维 `validate_integrity` 可不复制地检查现有原始存储。

## 分析

DBSCAN 聚类包围盒中心，min_pts 最小为 1，-1 表示噪声。旧 `dbscan` 的标签数组以用户 ID 索引；稀疏 ID 可造成巨大分配，重复 ID 无法独立表达多个标签。

`dbscan_compact` 提供 `CompactClusterResult`：`item_ids`、`labels` 按存储顺序逐项对应，另含簇数量、噪声数量和簇大小。结果空间 O(N)，适合稀疏或重复 ID。重建后的簇编号不保证稳定。

网格聚合按中心坐标分箱，支持负坐标；非正单元宽高返回空摘要。围栏监视保存各实体状态，按矩形相交或点包含输出进入、离开、停留事件。

## 扩展边界

| 扩展 | 说明 |
| --- | --- |
| `StrMeshTree3D` | 三角形包围盒粗筛后，线段/射线方法执行三角形精确判断 |
| `StrPolygonIndex` | 窗口与计数为外包矩形候选，多边形裁剪独立执行 |
| `TrajectoryWindowIndex` | 以轨迹段空间/时间外包盒筛选候选段或轨迹 ID |
| 轨迹简化与压缩 | 二维 Douglas-Peucker、同步时空误差简化、流式终点刷新 |
| 相似度 | 离散 DTW 与 Frechet，DTW 可限制窗口 |

全部参数次序和几何辅助方法见[生成接口](../../src/api/pkg.generated.mbti)。业务要求精确相交时，应在包围盒候选之上执行精确几何判断。
