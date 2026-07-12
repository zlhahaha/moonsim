# 类型化事件流 API

大多数用户只需 `import { "zlhahaha/moonsim" }`。根包导出常用事件流、模型、invariant 与报告接口；`core`、`models`、`reports` 是进阶入口。

## 五种稳定事件

`EventKind` 是封闭枚举：`Message`、`Task`、`Timer`、`StateTransition`、`ExternalCall`。它们分别表达消息事实、任务生命周期、时间触发、状态转移与外部交互记录。Queue、数据库、MQ 等适配器可以映射到这些稳定语义，并直接复用排序、变异、digest、invariant 与 replay。

`EventRecord` 保留稳定的 `id`、`correlation_id`、`source`、`target`、`label`、`tick`、`priority` 和 `parent_id`，以及用于证据的 `payload`、`dropped`、`failed`。

字段约定：`id` 在单个流内唯一且递增；`tick` 必须非负；`parent_id=0` 表示没有父事件，否则父事件必须存在且不能晚于子事件。`correlation_id` 连接同一业务过程，`source` 和 `target` 描述逻辑端点，`label` 承载适配器定义的动作名称。稳定排序键为 `(tick, priority, id)`。

## EventStream

- `event_stream()` / `EventStream::new()`：创建流。
- `record()` / `append()`：追加事件，自动分配稳定 id。
- `ordered()`：按 `(tick, priority, id)` 得到确定顺序。
- `digest()`：计算稳定摘要。
- `snapshot()` / `restore()`：保存和恢复输入状态。
- `replay(policy)`：按固定 seed 执行变异并返回 `EventReplayResult`。

## 变异与失败证据

`event_mutation_policy` 支持可控延迟、丢弃、重复、同 tick 乱序和失败注入，百分比会被规范到 0..100，所有随机选择都由 seed 决定。

`EventReplayResult` 包含 seed、digest、有序事件与 scheduled/dropped/duplicated/failed 计数。`EventFailureCase` 额外保存失败 invariant 名称、源事件和策略；`replay()` 使用相同输入与 seed 重现证据。

框架内置 invariant 检查事件 id、非负 tick 和父事件先于子事件。诸如“最终分类一次”“依赖未完成不可执行”“终态不可回退”属于业务规则，应由模型基于事件证据检查。

## 兼容模型

`MessageBus::event_stream()`、`TimerPlan::event_stream()`、`StateMachine::event_stream()`、`WorkflowResult::event_stream()`、Queue 结果与 HTTP recording 都可映射到通用流。现有 facade API 保留；HTTP API 是 `ExternalCall` 适配示例，而非项目中心。

0.3.x 稳定承诺覆盖五种 `EventKind`、事件标识/关联/因果字段、排序规则和根包构造入口。未来适配器可以新增 label、payload 约定和上层模型，同时继续复用稳定核心，无需为每种基础设施改动事件枚举。
