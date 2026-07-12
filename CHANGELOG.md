# 更新记录

本项目遵循语义化版本。0.3.x 保持根包常用入口和既有示例兼容。

## 0.3.1

- 将模块版本、公共 `version()` 接口、版本测试和安装示例同步为 `0.3.1`。
- 润色 README 的项目定位、跨语言能力对照、适用场景与确定性重放边界。
- 保持 `0.3.x` 公共 API 兼容，不改变既有 facade 和示例入口。

## 0.3.0

- 新增封闭的五类事件：`Message`、`Task`、`Timer`、`StateTransition`、`ExternalCall`。
- 新增 `EventStream` 的稳定排序、digest、snapshot/restore 和同 seed replay。
- 新增延迟、丢弃、重复、同 tick 乱序与失败注入策略，以及统一失败证据。
- 消息可靠性与任务编排成为旗舰模型；HTTP 记录重放调整为 `ExternalCall` 兼容适配示例。
- 保留原有根包 facade、`RecordedHttpTransport` 和 examples，不需要破坏性迁移。

从 0.2.x 升级时无需删除旧 API。新代码建议从根包的 `event_stream()`、事件类型构造函数和 `event_mutation_policy()` 开始；仅在需要进阶类型时直接导入 `core`、`models` 或 `reports`。
